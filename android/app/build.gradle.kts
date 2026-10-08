import java.io.FileInputStream
import java.util.Base64
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Play requires new app submissions to target Android 16 (API 36) as of
// August 31, 2026 (https://support.google.com/googleplay/android-developer/answer/11926878).
// Pinned explicitly rather than trusting `flutter.compileSdkVersion`/
// `targetSdkVersion` to already satisfy it.
val playTargetSdk = 36

// Release signing must come from a real upload keystore — never the debug
// keys. `key.properties` is git-ignored and holds only a pointer to the
// actual keystore file (kept outside this repository) plus its passwords;
// see docs handed to the app owner for how to create both. Missing or
// incomplete release signing configuration must fail the build loudly
// instead of silently falling back to debug signing.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

fun requireKeystoreProperty(name: String): String {
    if (!hasKeystoreProperties) {
        throw GradleException(
            "Release build requires android/key.properties, which was not " +
                "found. Release builds must be signed with the THIRTY " +
                "upload key, not the debug key. See the upload-keystore " +
                "setup instructions before running a release build."
        )
    }
    return keystoreProperties.getProperty(name)
        ?: throw GradleException(
            "android/key.properties is missing required property '$name'. " +
                "Release builds must be signed with the THIRTY upload key."
        )
}

// Passwords are read from an environment variable first, so the owner can
// supply them for a single build in the current shell session only — never
// written to key.properties, never committed. Falls back to key.properties
// only if that file's placeholder has actually been replaced.
fun resolveSecret(envVarName: String, propertyName: String): String {
    val fromEnv = System.getenv(envVarName)
    if (!fromEnv.isNullOrBlank()) return fromEnv
    val fromFile = requireKeystoreProperty(propertyName)
    if (fromFile.startsWith("REPLACE_WITH_")) {
        throw GradleException(
            "Release signing secret '$propertyName' is still the placeholder " +
                "value in android/key.properties, and environment variable " +
                "'$envVarName' is not set. Set $envVarName in your current " +
                "shell session before building (see upload-keystore setup " +
                "instructions), or replace the placeholder in key.properties " +
                "yourself."
        )
    }
    return fromFile
}

// Whether this Gradle invocation was actually asked for a release-signed
// artifact — `assembleRelease`, `bundleRelease`, `installRelease`, etc. all
// contain "Release" in their task name; Flutter always invokes one of
// these specific task names for `flutter run`/`flutter build`, driven by
// `--debug`/`--release`, never a bare aggregate task like `assemble` that
// might pull a release task in transitively without saying so on the
// command line.
//
// This has to be checked here, synchronously against the raw task names
// Gradle was invoked with — not deferred to something like
// `gradle.taskGraph.whenReady`, which fires only once the full task graph
// is resolved: the Android Gradle Plugin reads `SigningConfig` properties
// during this module's own configuration, well before that point, and
// throws ("It is too late to set storeFilePath") if they're written any
// later.
val isReleaseTaskRequested = gradle.startParameter.taskNames.any {
    it.contains("Release", ignoreCase = true)
}

// Billing must be configured for release (RELEASE-HARDENING-1). At runtime
// missing RevenueCat values only ever fail closed — Premium stays
// unavailable, nothing is granted — which is safe but silent. So, like the
// signing check above, a release build fails here unless the build's
// dart-defines carry release-ready billing values, as judged by
// `RevenueCatConfig.releaseProblems` (lib/core/config/revenue_cat_config.dart)
// via `tool/verify_release_config.dart`. Debug and profile builds are
// unaffected.
//
// There is deliberately no bypass: a release build either carries valid
// billing configuration or is not built at all.
fun releaseDartDefines(): Map<String, String> {
    val encoded = project.findProperty("dart-defines")?.toString() ?: return emptyMap()
    return encoded.split(",").filter { it.isNotBlank() }.mapNotNull { entry ->
        val define = String(Base64.getDecoder().decode(entry), Charsets.UTF_8)
        val separator = define.indexOf('=')
        if (separator <= 0) null else define.substring(0, separator) to define.substring(separator + 1)
    }.toMap()
}

fun verifyReleaseBillingConfig() {
    val localProperties = Properties()
    rootProject.file("local.properties").takeIf { it.exists() }?.let { file ->
        FileInputStream(file).use { localProperties.load(it) }
    }
    val flutterSdk = localProperties.getProperty("flutter.sdk")
        ?: throw GradleException("android/local.properties has no flutter.sdk entry.")
    val dartName =
        if (System.getProperty("os.name").startsWith("Windows")) "dart.exe" else "dart"
    val dart = File(flutterSdk, "bin/cache/dart-sdk/bin/$dartName")
    val defines = releaseDartDefines()
    val process = ProcessBuilder(dart.absolutePath, "tool/verify_release_config.dart")
        .directory(rootProject.projectDir.parentFile)
        .redirectErrorStream(true)
        .apply {
            environment()["REVENUECAT_ANDROID_API_KEY"] =
                defines["REVENUECAT_ANDROID_API_KEY"] ?: ""
            environment()["REVENUECAT_ENTITLEMENT_ID"] =
                defines["REVENUECAT_ENTITLEMENT_ID"] ?: ""
        }
        .start()
    val report = process.inputStream.bufferedReader().readText().trim()
    if (process.waitFor() != 0) {
        throw GradleException(
            "THIRTY release build blocked: billing is not configured for " +
                "release.\n$report\nBuild with " +
                "--dart-define-from-file=config/revenuecat.local.json holding the " +
                "real RevenueCat values (see config/revenuecat.example.json)."
        )
    }
    logger.lifecycle(report)
}

if (isReleaseTaskRequested) {
    verifyReleaseBillingConfig()
}

android {
    namespace = "com.thirty.app.thirty"
    compileSdk = playTargetSdk
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications 22.x — it uses java.time
        // APIs under the hood for scheduled notifications and needs desugar
        // support to run on the app's minSdk (below Android 8/API 26).
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.thirty.app.thirty"
        minSdk = flutter.minSdkVersion
        targetSdk = playTargetSdk
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Resolving/validating the THIRTY upload signing secrets used
            // to run unconditionally here, which Gradle evaluates for
            // every invocation touching this module — `assembleDebug`
            // (and therefore plain `flutter run`) included, not just an
            // actual release build. That made a debug build hard-fail
            // whenever the release secrets weren't set, even though debug
            // signing never uses them (see `isReleaseTaskRequested`'s own
            // doc comment for why this is gated on it rather than left
            // unconditional, and why that check has to live where it does).
            //
            // When no release task was requested, this signing config is
            // simply left with no storeFile/passwords set — inert, since
            // `buildTypes.debug` never references it and no release
            // variant is being packaged in this invocation to read it.
            if (isReleaseTaskRequested) {
                storeFile = file(requireKeystoreProperty("storeFile"))
                storePassword = resolveSecret("THIRTY_KEYSTORE_PASSWORD", "storePassword")
                keyAlias = requireKeystoreProperty("keyAlias")
                keyPassword = resolveSecret("THIRTY_KEY_PASSWORD", "keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // No debug-signing fallback: a release build with no/incomplete
            // key.properties must fail the build (see requireKeystoreProperty),
            // not silently ship a debug-signed artifact.
            signingConfig = signingConfigs.getByName("release")
        }
        // `debug` is left untouched, so it keeps AGP's own automatic debug
        // signing config (the normal ~/.android/debug.keystore) — it never
        // reads from `signingConfigs.release` at all.
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Version pinned per flutter_local_notifications' own current Android
    // setup instructions (pub.dev) for its required core library desugaring.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
