# resume_builder

A new Flutter project.

## Android release build

The Android app is configured to shrink release builds with R8/resource shrinking,
limit bundled ABIs to `armeabi-v7a` and `arm64-v8a`, and use Flutter icon tree
shaking plus Dart obfuscation for release bundles.

Android builds in this repo are standardized on JDK 17. This is compatible with
the current toolchain in the project:

- Flutter 3.41.8
- Android Gradle Plugin 8.11.1
- Gradle 8.14
- Kotlin Android plugin 2.2.20
- Java/Kotlin compile target 17

Use the provided PowerShell helper to build the production bundle:

```powershell
./build_android_release.ps1
```

Use size analysis when you want a package-level breakdown for a single ABI:

```powershell
./build_android_release.ps1 -AnalyzeSize -Arm64Only
```

`-Arm64Only` is the smallest output, but it drops 32-bit Android support.

For APK builds, use the JDK-17-pinned helper so local `flutter build apk`
invocations do not drift to a different system JDK:

```powershell
./build_android_apk.ps1
./build_android_apk.ps1 -Release
```

### Gradle JDK pin (stability)

This project pins Gradle to JDK 17 in [android/gradle.properties](android/gradle.properties)
using `org.gradle.java.home`.

Why: some machines may default to a newer system Java (for example certain JDK 21 builds)
that can crash the Gradle daemon during Android builds.

If you move the project to another machine, verify the JDK path in
[android/gradle.properties](android/gradle.properties) exists locally and update it if needed.

For Flutter CLI and Android Studio builds, also point Flutter to the same JDK:

```powershell
flutter config --jdk-dir="C:\Users\GMK\AppData\Local\Programs\Microsoft\jdk-17"
```

If you use Android Studio, set `Gradle JDK` to the same JDK 17 installation.

There is no checked-in CI configuration in this repository right now. If CI is added later,
configure the runner to install and use JDK 17 before Android builds.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
