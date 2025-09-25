# Firebase Billing Setup Guide

## Issue Description

Your app is currently configured to use the Firebase project `resume-app-sms` (as shown in `firebase_options.dart`), but this project doesn't have billing enabled, which is causing the "Billing Not Enabled" error.

## Current Project Configuration

- **Project ID**: `resume-app-sms`
- **Storage Bucket**: `resume-app-sms.firebasestorage.app`
- **Project Number**: `42581559002`

## Required Actions

### 1. Enable Firebase Billing (Blaze Plan)

1. **Go to Firebase Console**:

   - Visit: https://console.firebase.google.com/
   - Select your project: `resume-app-sms`

2. **Upgrade to Blaze Plan**:

   - Click on "Upgrade" in the bottom left corner
   - Or go to: Settings → Usage and billing → Details & settings
   - Click "Modify plan"
   - Select "Blaze Plan (Pay as you go)"

3. **Set up Billing Account**:
   - Link a valid Google Cloud billing account
   - Set budget alerts to control costs
   - Review pricing: https://firebase.google.com/pricing

### 2. Enable Required Firebase Services

After enabling billing, ensure these services are enabled:

1. **Authentication**:

   - Go to Authentication → Sign-in method
   - Enable required providers (Email, Google, Facebook, etc.)

2. **Firestore Database**:

   - Go to Firestore Database
   - Create database in production mode
   - Set up security rules

3. **Storage**:

   - Go to Storage
   - Get started and set up security rules

4. **Cloud Functions** (if using):
   - Go to Functions
   - Enable Cloud Functions API

### 3. Security Rules Setup

**Firestore Rules** (Database → Rules):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own data only
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Resumes can be read/written by authenticated users for their own data
    match /resumes/{resumeId} {
      allow read, write: if request.auth != null &&
        request.auth.uid == resource.data.userId;
    }

    // Allow public read for app settings (if any)
    match /settings/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

**Storage Rules** (Storage → Rules):

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    match /resumes/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 4. Verify Configuration

After setting up billing and services, test the following:

1. **Authentication Test**:

   ```bash
   # In your Flutter app, test login
   flutter run
   # Try logging in with email/password
   ```

2. **Firestore Test**:

   - Try saving a resume
   - Check if data appears in Firebase Console

3. **Storage Test**:
   - Try uploading/downloading files
   - Check Storage usage in console

### 5. Cost Management

**Set Budget Alerts**:

1. Go to Google Cloud Console: https://console.cloud.google.com/
2. Navigate to Billing → Budgets & alerts
3. Create budget for your project
4. Set alert thresholds (e.g., $10, $25, $50)

**Monitor Usage**:

- Firebase Console → Usage and billing
- Check daily/monthly usage
- Review costs regularly

### 6. Alternative Solution (If Budget is a Concern)

If you want to avoid charges during development:

1. **Use Firebase Emulators**:

   ```bash
   npm install -g firebase-tools
   firebase login
   firebase init emulators
   firebase emulators:start
   ```

2. **Update app_config.dart**:
   ```dart
   class AppConfig {
     static const bool useFirebaseEmulator = true; // Change to true
     static const String emulatorHost = 'localhost';
     static const int authEmulatorPort = 9099;
     static const int firestoreEmulatorPort = 8080;
     static const int storageEmulatorPort = 9199;
     // ... rest of config
   }
   ```

### 7. Production Checklist

Before going live:

- [ ] Billing enabled and budget alerts set
- [ ] Security rules configured and tested
- [ ] Authentication providers configured
- [ ] App properly tested with real Firebase backend
- [ ] Analytics and Crashlytics enabled
- [ ] Performance monitoring configured

## Common Issues and Solutions

**Issue**: "Billing not enabled" error
**Solution**: Enable Blaze plan in Firebase Console

**Issue**: "Permission denied" errors
**Solution**: Check and update Firestore/Storage security rules

**Issue**: High costs
**Solution**: Set budget alerts and use Firebase emulators for development

**Issue**: Authentication not working
**Solution**: Verify OAuth providers are configured in Firebase Console

## Support Resources

- Firebase Documentation: https://firebase.google.com/docs
- Firebase Pricing: https://firebase.google.com/pricing
- Flutter Firebase Setup: https://firebase.flutter.dev/docs/overview
- Community Support: https://stackoverflow.com/questions/tagged/firebase

---

## Next Steps

1. **Immediate**: Enable billing on the `resume-app-sms` project
2. **Configure**: Set up security rules and authentication providers
3. **Test**: Verify all features work with billing enabled
4. **Monitor**: Set up budget alerts and usage monitoring
5. **Deploy**: Build and test APK with production Firebase configuration
