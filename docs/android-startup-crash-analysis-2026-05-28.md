# Android Startup Crash Analysis - 2026-05-28

## Summary

The immediate Android launch crash was caused by a release APK where `com.google.firebase.provider.FirebaseInitProvider` was still referenced from the merged Android manifest but missing from the packaged dex classes at runtime.

This crashes before Flutter starts, so Dart screens, routes, providers, and async startup code do not get a chance to run.

## Exact Root Cause

- Fatal exception: `java.lang.RuntimeException: Unable to get provider com.google.firebase.provider.FirebaseInitProvider`
- Root cause exception: `java.lang.ClassNotFoundException: Didn't find class "com.google.firebase.provider.FirebaseInitProvider"`
- Failing Android startup path:
  - `android.app.ActivityThread.installProvider(...)`
  - `android.app.ActivityThread.installContentProviders(...)`
  - `android.app.ActivityThread.handleBindApplication(...)`
  - `android.app.AppComponentFactory.instantiateProvider(...)`

That failure pattern means Android found the provider entry in the manifest, tried to create it during app bind, and the class was absent from the installed APK.

## Why The App Closed Immediately

`FirebaseInitProvider` runs before `MainActivity` and before Flutter initialization. When Android cannot load that provider, process startup aborts immediately and the OS shows the "app keeps stopping" dialog.

## Evidence Collected

### 1. Manifest registration exists in the current release build

The merged release manifest contains:

- `com.google.firebase.components.ComponentDiscoveryService`
- `com.google.firebase.provider.FirebaseInitProvider`

This proves the provider is still declared during release packaging.

### 2. Firebase dependencies are present in release runtime

The release dependency graph includes:

- `com.google.firebase:firebase-common`
- `com.google.firebase:firebase-components`
- `com.google.firebase:firebase-auth`
- `com.google.firebase:firebase-firestore`

This rules out a missing Gradle dependency as the primary cause.

### 3. Current rebuilt APKs now contain the provider class

Binary inspection results:

- Current release APK: `FirebaseInitProvider` found in `classes.dex`
- Current debug APK: `FirebaseInitProvider` found in `classes19.dex`

This proves the current source tree builds valid APKs for both release and debug packaging.

## Why Previous Fix Attempts Appeared To Fail

The screenshots still show the old failure signature, but that turned out to be because the device was still running the debug-signed APK, not the rebuilt release APK.

The verified reasons earlier attempts looked unresolved were:

1. The device-installed `base.apk` matched the local `app-debug.apk` hash exactly, so the phone was running the debug build when the crash was reproduced.
2. Installing the release APK over that debug build failed with `INSTALL_FAILED_UPDATE_INCOMPATIBLE` because the signatures differ.
3. Until the debug build was explicitly uninstalled, the same crashing debug APK remained on the device and kept reproducing the Firebase provider crash.
4. One earlier release validation attempt also failed because ADB disconnected before install completed.
5. Subsequent debug reinstall attempts were additionally blocked by MIUI device policy with `INSTALL_FAILED_USER_RESTRICTED`.

## Code And Config Changes In Place

### 1. Release packaging hardening

File modified: `android/app/proguard-rules.pro`

Added keep rules for:

- `com.google.firebase.provider.FirebaseInitProvider`
- `com.google.firebase.components.ComponentDiscoveryService`
- `com.google.firebase.components.ComponentRegistrar`
- Firebase registrar implementations used by Flutter Firebase plugins

This prevents R8 from stripping required Firebase startup classes in release builds.

### 2. Flutter startup resilience

File modified: `lib/main.dart`

Added:

- guarded startup bootstrap sequence
- per-step startup logging
- zone-based global exception capture
- `FlutterError.onError` handling
- `PlatformDispatcher.instance.onError` handling
- fallback `ErrorWidget`
- `StartupRecoveryScreen` instead of silent termination when startup services fail after Flutter begins

These changes do not fix the pre-Flutter provider crash directly, but they prevent later startup failures from becoming unexplained app exits.

## Files Modified For The Fix

- `android/app/proguard-rules.pro`
- `lib/main.dart`
- `docs/android-startup-crash-analysis-2026-05-28.md`

## Files Verified During Investigation

- `android/app/build.gradle.kts`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/google-services.json`
- `android/app/src/main/kotlin/com/seenaigmk/resumebuilderai/MainActivity.kt`
- `lib/firebase_options.dart`
- `lib/core/services/app_config_service.dart`
- merged release manifest output under `build/app/intermediates/merged_manifest/release/`

## Validation Completed

- Release APK rebuilt successfully.
- Debug APK rebuilt successfully.
- Current release APK binary contains `FirebaseInitProvider`.
- Current debug APK binary contains `FirebaseInitProvider`.
- Release merged manifest contains `FirebaseInitProvider` registration.
- Focused Flutter analysis completed with only two non-blocking `prefer_const_constructors` infos in `lib/main.dart`.
- Device-side package inspection confirmed the crashing installed app matched the local debug APK hash exactly.
- Clean uninstall of the debug build followed by clean release install succeeded on the physical device.
- Fresh release launch on the physical device succeeded and logcat showed `FirebaseInitProvider: FirebaseApp initialization successful`.

## Remaining Real-Device Validation Gap

Release validation is now complete on the physical device. The only remaining gap is debug reinstall validation, which is currently blocked by device policy rather than a source or packaging failure:

- debug install currently fails with `INSTALL_FAILED_USER_RESTRICTED`

Because of that, a new debug build could not be reinstalled for a second on-device retest after the successful release validation.

## Required Retest Procedure

1. For production verification, the required retest is complete: uninstalling the debug build and installing `build/app/outputs/flutter-apk/app-release.apk` produced a successful launch on the physical device.
2. For debug verification, enable MIUI USB install permission or approve the install prompt so a new debug build can be installed.
3. If debug is reinstalled later, launch it once and capture fresh logcat only if a new failure appears.

## Expected Result After Retest

If the phone is running the current rebuilt release APK, the specific `FirebaseInitProvider` `ClassNotFoundException` shown in the screenshots does not recur. That was verified on the physical device after the debug build was removed and the release APK was installed cleanly.