# 🔑 API Keys & Configuration Setup Guide

## 🔥 Firebase Setup

### 1. Create Production Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project"
3. Project name: `resume-builder-prod` (or your choice)
4. Enable Google Analytics
5. Choose your Analytics account

### 2. Enable Required Services

#### Authentication

1. Go to Authentication > Sign-in method
2. Enable:
   - Email/Password
   - Google Sign-In
   - Facebook (optional)
3. Add your domain to authorized domains

#### Firestore Database

1. Go to Firestore Database
2. Create database in production mode
3. Choose location closest to your users
4. Set up security rules (see PRODUCTION_SETUP.md)

#### Analytics

1. Go to Analytics > Events
2. Enable enhanced measurement
3. Set up custom events for conversion tracking

#### Remote Config

1. Go to Remote Config
2. Add parameters for A/B testing:
   - `monthly_price` (default: "4.99")
   - `yearly_price` (default: "39.99")
   - `lifetime_price` (default: "49.99")
   - `show_premium_popup` (default: true)

### 3. Download Configuration Files

1. **Android**: Project Settings > Your apps > Download `google-services.json`
2. **iOS**: Project Settings > Your apps > Download `GoogleService-Info.plist`

## 📱 Google Play Console Configuration

### 1. Create Developer Account

1. Go to [Google Play Console](https://play.google.com/console/)
2. Pay $25 registration fee
3. Complete developer profile

### 2. Create App

1. Click "Create app"
2. App details:
   - **Name**: Resume Builder - CV Maker
   - **Default language**: English (US)
   - **App or game**: App
   - **Free or paid**: Free (with in-app purchases)

### 3. Set Up In-App Products

1. Go to Monetize > Products > In-app products
2. Create products:

```
Product ID: premium_monthly
Name: Monthly Premium
Description: Access all premium features for one month
Price: $4.99

Product ID: premium_yearly
Name: Yearly Premium
Description: Access all premium features for one year (save 58%)
Price: $39.99

Product ID: premium_lifetime
Name: Lifetime Premium
Description: Unlimited access to all premium features forever
Price: $49.99
```

### 4. App Signing

1. Go to Release > Setup > App signing
2. Choose "Use Play App Signing" (recommended)
3. Upload your upload certificate

## 🍎 Apple App Store Setup (iOS)

### 1. Apple Developer Program

1. Enroll in [Apple Developer Program](https://developer.apple.com/programs/) - $99/year
2. Complete enrollment process

### 2. App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Create new app:
   - **Name**: Resume Builder - CV Maker
   - **Bundle ID**: com.yourcompany.resumebuilder
   - **SKU**: resume-builder-001
   - **Primary Language**: English

### 3. In-App Purchases

1. Go to Features > In-App Purchases
2. Create products matching Android:
   - `premium_monthly` - $4.99
   - `premium_yearly` - $39.99
   - `premium_lifetime` - $49.99

## 📺 Google AdMob Configuration

### 1. Create AdMob Account

1. Go to [AdMob](https://apps.admob.com/)
2. Sign in with Google account
3. Add your app

### 2. Get App ID

1. Select your app
2. Copy the App ID (ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX)
3. Replace in `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX"/>
```

### 3. Create Ad Units

1. Create banner ad unit for main screens
2. Create interstitial ad for between actions
3. Create rewarded ad for premium features preview

### 4. Update Ad Unit IDs in Code

Update `lib/services/ads_service.dart`:

```dart
class AdsService {
  static const String _bannerAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _interstitialAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _rewardedAdUnitId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
}
```

## 🔐 Social Login Configuration

### Facebook Login

1. Go to [Facebook Developers](https://developers.facebook.com/)
2. Create new app
3. Add Facebook Login product
4. Get App ID and App Secret
5. Update `android/app/src/main/res/values/strings.xml`:

```xml
<string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
<string name="facebook_client_token">YOUR_CLIENT_TOKEN</string>
```

### Google Sign-In

1. In Firebase Console > Authentication > Sign-in method
2. Enable Google Sign-In
3. Download updated `google-services.json`
4. For iOS, add URL scheme to `ios/Runner/Info.plist`

## 📊 Analytics Configuration

### Firebase Analytics Custom Events

Update `lib/services/analytics_service.dart` with your tracking events:

```dart
// Purchase events
await FirebaseAnalytics.instance.logPurchase(
  currency: 'USD',
  value: 4.99,
  parameters: {
    'item_name': 'premium_monthly',
    'item_category': 'subscription',
  },
);

// Custom conversion events
await FirebaseAnalytics.instance.logEvent(
  name: 'premium_feature_attempt',
  parameters: {
    'feature_name': 'export_pdf',
    'user_type': 'free',
  },
);
```

### Google Analytics 4 (Optional)

1. Create GA4 property
2. Link with Firebase Analytics
3. Set up conversion goals

## 🔔 Push Notifications Setup

### Firebase Cloud Messaging

1. In Firebase Console > Cloud Messaging
2. Generate server key
3. For iOS: Upload APNs certificate or key

### Update FCM Configuration

```dart
// lib/services/notification_service.dart
class NotificationService {
  static const String _serverKey = 'YOUR_FCM_SERVER_KEY';

  Future<void> setupNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission
    NotificationSettings settings = await messaging.requestPermission();

    // Get FCM token
    String? token = await messaging.getToken();
    print("FCM Token: $token");
  }
}
```

## 🏗️ Build Configuration

### Update Version Numbers

In `pubspec.yaml`:

```yaml
version: 1.0.0+1 # Format: version+build_number
```

### Android Build Configuration

In `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.yourcompany.resumebuilder"  # Change this
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }

    signingConfigs {
        release {
            keyAlias 'upload'
            keyPassword 'your_key_password'
            storeFile file('upload-keystore.jks')
            storePassword 'your_store_password'
        }
    }
}
```

### Generate Upload Keystore (Android)

```bash
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

## ⚙️ Environment Variables

Create `lib/config/app_config.dart`:

```dart
class AppConfig {
  static const bool isProduction = true;
  static const String appName = 'Resume Builder';
  static const String packageName = 'com.yourcompany.resumebuilder';

  // Firebase
  static const String firebaseProjectId = 'resume-builder-prod';

  // AdMob
  static const String admobAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX';

  // Social Login
  static const String facebookAppId = 'YOUR_FACEBOOK_APP_ID';
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID';

  // API Endpoints
  static const String baseUrl = 'https://api.resumebuilder.com';

  // Support
  static const String supportEmail = 'support@resumebuilder.com';
  static const String privacyPolicyUrl = 'https://resumebuilder.com/privacy';
  static const String termsOfServiceUrl = 'https://resumebuilder.com/terms';
}
```

## 🔒 Security Checklist

- [ ] Replace all test API keys with production keys
- [ ] Enable App Check in Firebase
- [ ] Set up proper Firestore security rules
- [ ] Use HTTPS for all API endpoints
- [ ] Implement certificate pinning (advanced)
- [ ] Enable ProGuard/R8 code obfuscation
- [ ] Remove debug logging in production builds

## 📝 Legal Requirements

### Privacy Policy

Create privacy policy covering:

- Data collection and usage
- Firebase Analytics data
- AdMob advertising data
- User-generated content
- Data retention and deletion

### Terms of Service

Include:

- Subscription terms and cancellation policy
- User responsibilities
- Intellectual property rights
- Limitation of liability

---

## 🚀 Quick Setup Commands

Replace configuration files:

```bash
# Replace Firebase config files
cp path/to/production/google-services.json android/app/
cp path/to/production/GoogleService-Info.plist ios/Runner/

# Update dependencies
flutter pub get

# Test build
flutter build apk --debug

# Production build
flutter build apk --release
```

**Remember**: Never commit API keys or sensitive configuration to version control. Use environment variables or secure configuration management.
