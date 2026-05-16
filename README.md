# resume_builder

A new Flutter project.

## Android release build

The Android app is configured to shrink release builds with R8/resource shrinking,
limit bundled ABIs to `armeabi-v7a` and `arm64-v8a`, and use Flutter icon tree
shaking plus Dart obfuscation for release bundles.

Use the provided PowerShell helper to build the production bundle:

```powershell
./build_android_release.ps1
```

Before building for Play Store release, configure these values:

```powershell
$env:RAZORPAY_KEY_ID="rzp_live_..."
$env:PLAY_WEEKLY_PRODUCT_ID="resumix_ai_weekly"
$env:PLAY_MONTHLY_PRODUCT_ID="resumix_ai_monthly"
$env:PLAY_QUARTERLY_PRODUCT_ID="resumix_ai_quarterly"
$env:PLAY_YEARLY_PRODUCT_ID="resumix_ai_yearly"
$env:OTP_SEND_URL="https://your-backend.example.com/otp/send"
$env:OTP_VERIFY_URL="https://your-backend.example.com/otp/verify"
$env:ANDROID_KEYSTORE_FILE="C:\path\to\upload-keystore.jks"
$env:ANDROID_KEYSTORE_PASSWORD="..."
$env:ANDROID_KEY_ALIAS="upload"
$env:ANDROID_KEY_PASSWORD="..."
./build_android_release.ps1
```

Google Play subscriptions are separate from Razorpay. On Android Play Store
builds, subscription checkout uses Google Play Billing and requires matching
subscription product IDs in Play Console. Razorpay remains the fallback for
non-Android distributions.

You can configure OTP with either exact endpoint URLs or a shared base URL:

```powershell
$env:OTP_BASE_URL="https://your-project-ref.supabase.co/functions/v1"
```

When `OTP_SEND_URL` and `OTP_VERIFY_URL` are not passed, the app derives them
from `OTP_BASE_URL` as `/send-otp` and `/verify-otp`.

## Google Login And Internal Testing Access

The Android app already supports Google sign-in through Firebase Auth. For a
Play-installed build to let users sign in with Gmail successfully, keep these
items aligned:

1. In Firebase Console -> Authentication -> Sign-in method, enable Google.
2. In Firebase Console -> Project Settings -> Your Android app, register both
	the upload-key SHA fingerprints and the Play App Signing SHA fingerprints
	for package `com.seenaigmk.resumebuilderai`.
3. After changing fingerprints, download a fresh
	`android/app/google-services.json` from Firebase.

For Google Play internal testing access, the install itself is controlled by
Play Console, not by app code:

1. Add each tester Gmail address under Play Console -> Testing -> Internal
	testing -> Testers.
2. Share the internal-test opt-in link with those testers.
3. Testers must sign in to the Google Play Store on the device with the same
	Gmail address that was added to the tester list before opening the opt-in
	link and installing the app.
4. After installation, the user can sign in inside the app with Google using
	the Firebase-enabled account flow.

The app now reads Play product IDs from either `.env` or `--dart-define`, so
you can keep using `.env` during local testing and set the same values in your
release pipeline.

The app no longer supports client-side Twilio credentials. OTP must be handled
by your backend via `OTP_SEND_URL` and `OTP_VERIFY_URL`. For local debug-only
testing, you can temporarily set `OTP_DEBUG_CODE` in `.env`; release builds
ignore that value.

Supabase Edge Function scaffolding now exists under `supabase/functions/`.
See `supabase/functions/README.md` for local serve commands, secret setup, and
the exact function URLs to place in `OTP_SEND_URL` and `OTP_VERIFY_URL`.

You can also place the Android signing values in `android/key.properties` using
the standard keys `storeFile`, `storePassword`, `keyAlias`, and `keyPassword`.

Use size analysis when you want a package-level breakdown for a single ABI:

```powershell
./build_android_release.ps1 -AnalyzeSize -Arm64Only
```

`-AnalyzeSize` now skips `--obfuscate` and `--split-debug-info` automatically
because Flutter does not allow those flags together. The script prints the final
AAB size after each build so you can compare changes quickly.

`-Arm64Only` is the smallest output, but it drops 32-bit Android support.

## Verified AAB size notes

Measured on this codebase:

- Plain `flutter build appbundle --release`: about 59.4 MB
- Optimized `arm64` release build: about 22.7 MB

Use the helper script for repeatable release builds:

```powershell
./build_android_release.ps1
```

Use this when you explicitly want the smallest bundle and can accept dropping
32-bit Android devices:

```powershell
./build_android_release.ps1 -Arm64Only
```

The biggest safe code-level win currently applied is replacing a dynamic
`GoogleFonts.getFont(...)` lookup with explicit font-family mappings so unused
Google Fonts registry code can be tree-shaken from release builds.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
