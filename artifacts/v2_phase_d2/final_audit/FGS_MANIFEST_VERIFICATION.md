# Foreground-service manifest verification (D2 closure pass, 2026-10-12)

## What was inspected

- **The release merge can't be produced on this machine.** `assembleRelease` and `processReleaseMainManifest` stop at configuration time: the RELEASE-HARDENING-1 billing gate in `android/app/build.gradle.kts` runs because `config/revenuecat.local.json` is absent.
  - That gate has no bypass by design, and none was added.
  - The release merged manifest under `build/` is from Sep 22 and predates `GuidanceService`, so it isn't evidence.
- **So the evidence is a profile APK built fresh from this commit:**
  - Built with `flutter build apk --profile` on 2026-10-12. SHA-1 `70139a16c3a6f4582e44c669a473bde3d4717ee6`.
  - Its packaged manifest was dumped with `aapt2 dump xmltree` and saved as `manifest/aapt2_xmltree_app-profile.txt`.
  - Its merged manifest is saved as `manifest/merged_profile_AndroidManifest.xml`.
- **Why profile equals release, element for element:**
  - Release has no source-set overlay of its own.
  - The profile overlay (`src/profile/AndroidManifest.xml`) adds only `INTERNET`, which the merger blame report shows RevenueCat's `purchases-10.19.1` AAR also contributes. Release therefore carries it too.
  - Library manifests do not vary by build type.
  - The billing gate decides only whether the build runs. It never changes the manifest.
- **Re-check required:** check the real release APK with `aapt2 dump xmltree <apk> --file AndroidManifest.xml` once `config/revenuecat.local.json` exists. This is the Phase E release-build proof.

## Effective configuration (packaged manifest)

```
uses-sdk minSdkVersion=24 targetSdkVersion=36

uses-permission android.permission.FOREGROUND_SERVICE                  (app main manifest :39)
uses-permission android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK   (app main manifest :40)
uses-permission android.permission.WAKE_LOCK

service com.thirty.app.thirty.GuidanceService
    android:exported=false
    android:stopWithTask=true
    android:foregroundServiceType=0x00000002   (= mediaPlayback, and only that)
```

| Check | Result |
|---|---|
| A foreground service is declared | **YES.** `GuidanceService`, the only component with a `foregroundServiceType` |
| `foregroundServiceType` includes `mediaPlayback` | **YES.** `0x2` is `mediaPlayback` alone |
| `FOREGROUND_SERVICE` is declared (API 28+) | **YES** |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` is declared (required at targetSdk 34+; the target is 36) | **YES** |
| The service's exported state is appropriate | **YES.** `exported=false`, started only by THIRTY itself (`startForegroundService` in `GuidanceService.kt`), with no intent filter |
| No unnecessary foreground-service types or permissions | **YES.** There is no other `FOREGROUND_SERVICE_*` permission, and the other two services are not foreground services: `TransportBackendDiscovery` and `JobInfoSchedulerService`, both `exported=false`, from Google datatransport |

The full permission set comes from the merger blame report: `BILLING`, `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `WAKE_LOCK`, `INTERNET`, `ACCESS_NETWORK_STATE` and `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. Nothing was missing, so no manifest change was made.

## Phase E requirement (recorded in the tracker, not performed)

The Play Console foreground-service declaration for `FOREGROUND_SERVICE_MEDIA_PLAYBACK` must be filed with:

- the use-case description;
- the required demonstration video: a voiced Circle continuing with the screen off and in another app, with its ongoing notification.
