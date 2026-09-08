import java.io.FileInputStream
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
            storeFile = file(requireKeystoreProperty("storeFile"))
            storePassword = resolveSecret("THIRTY_KEYSTORE_PASSWORD", "storePassword")
            keyAlias = requireKeystoreProperty("keyAlias")
            keyPassword = resolveSecret("THIRTY_KEY_PASSWORD", "keyPassword")
        }
    }

    buildTypes {
        release {
            // No debug-signing fallback: a release build with no/incomplete
            // key.properties must fail the build (see requireKeystoreProperty),
            // not silently ship a debug-signed artifact.
            signingConfig = signingConfigs.getByName("release")
        }
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
