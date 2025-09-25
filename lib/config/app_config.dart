class AppConfig {
  // Firebase Configuration - PRODUCTION MODE
  static const bool useFirebaseEmulator =
      false; // Set to false for production with Blaze plan
  static const bool enablePhoneAuth =
      true; // Enabled with Blaze plan and $300 credit

  // Emulator Configuration (for development only)
  static const String emulatorHost = '127.0.0.1';
  static const int authEmulatorPort = 9099;
  static const int firestoreEmulatorPort = 8080;
  static const int storageEmulatorPort = 9199;

  // Feature Flags - ENABLED FOR PRODUCTION
  static const bool enableCloudFeatures = true; // Enabled with Blaze plan
  static const bool enableAnalytics = true; // Enabled for production

  // Development Settings
  static const bool showDebugInfo = true;
  static const bool useTestCredentials = true;

  // Testing Configuration
  static const bool enableTestingMode =
      true; // Enable premium features for testing
  static const bool bypassPremiumRestrictions =
      true; // Bypass premium restrictions during testing
}
