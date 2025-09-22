# Firebase Setup Guide for SMS OTP Authentication

This guide will help you set up Firebase Authentication for real SMS OTP delivery in your Resume Builder app.

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or "Add project"
3. Enter project name: `resume-builder-app` (or your preferred name)
4. Enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Add Android App to Firebase

1. In Firebase Console, click "Add app" and select Android
2. Fill in the details:
   - **Android package name**: `com.example.resume_builder_app` (from your android/app/build.gradle)
   - **App nickname**: Resume Builder App
   - **Debug signing certificate SHA-1**: (optional for now)
3. Click "Register app"
4. Download `google-services.json`
5. Place the file in `android/app/` directory

## Step 3: Configure Android

### Add Firebase SDK to Android

1. Open `android/build.gradle` (project-level)
2. Add this to dependencies section:

```gradle
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}
```

3. Open `android/app/build.gradle` (app-level)
4. Add at the top (after other plugins):

```gradle
plugins {
    id 'com.google.gms.google-services'
}
```

5. Add to dependencies section:

```gradle
dependencies {
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-auth'
}
```

## Step 4: Add iOS App to Firebase (if targeting iOS)

1. In Firebase Console, click "Add app" and select iOS
2. Fill in the details:
   - **iOS bundle ID**: `com.example.resumeBuilderApp` (from your ios/Runner/Info.plist)
   - **App nickname**: Resume Builder App
3. Download `GoogleService-Info.plist`
4. Open `ios/Runner.xcworkspace` in Xcode
5. Drag the `GoogleService-Info.plist` file into the Runner folder
6. Make sure "Copy items if needed" is checked

## Step 5: Enable Phone Authentication

1. In Firebase Console, go to "Authentication" > "Sign-in method"
2. Click on "Phone" provider
3. Enable it and click "Save"

## Step 6: Configure SHA Certificate (Required for SMS)

### For Debug (Development):

1. Run this command in your project root:

```bash
cd android
./gradlew signingReport
```

2. Copy the SHA1 from the debug keystore
3. In Firebase Console, go to Project Settings > Your Android App
4. Add the SHA1 fingerprint

### For Release (Production):

1. Generate your release keystore:

```bash
keytool -genkey -v -keystore ~/key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key
```

2. Get SHA1 from release keystore:

```bash
keytool -list -v -keystore ~/key.jks -alias key
```

3. Add release SHA1 to Firebase Console

## Step 7: Test Phone Numbers (Optional for Development)

For testing without sending real SMS:

1. In Firebase Console, go to Authentication > Settings
2. Scroll to "Phone authentication" section
3. Add test phone numbers with their verification codes:
   - Phone: +1 555-555-5555
   - Code: 123456

## Important Notes

⚠️ **SMS Costs**: Firebase charges for SMS messages. Check [Firebase Pricing](https://firebase.google.com/pricing)

🔒 **Security**: Never commit `google-services.json` or `GoogleService-Info.plist` to public repositories

📱 **Testing**: Use Firebase test phone numbers for development to avoid SMS costs

🌍 **International**: Ensure your phone number format includes country code (+1, +91, etc.)

## Next Steps

After completing this setup:

1. The app will automatically use Firebase for real SMS delivery
2. Test with your actual phone number
3. Monitor usage in Firebase Console

## Troubleshooting

- **SMS not received**: Check SHA1 certificate and phone number format
- **Build errors**: Ensure google-services.json is in correct location
- **iOS issues**: Verify GoogleService-Info.plist is properly added to Xcode project
