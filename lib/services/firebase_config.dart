import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseConfig {
  // Firebase configuration for different platforms
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCc2az430lE_cox_a7LxQQ0NRWEPmj1Kds',
    appId: '1:198483032831:android:0ef8a69160a08a5a8d6aca',
    messagingSenderId: '198483032831',
    projectId: 'resume-app-8ff9c',
    storageBucket: 'resume-app-8ff9c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY', // Get this from iOS GoogleService-Info.plist
    appId: 'YOUR_IOS_APP_ID', // Get this from iOS GoogleService-Info.plist
    messagingSenderId: '198483032831',
    projectId: 'resume-app-8ff9c',
    storageBucket: 'resume-app-8ff9c.firebasestorage.app',
    iosBundleId: 'com.example.resumeAppApp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY', // Get this from Firebase Console Web config
    appId: 'YOUR_WEB_APP_ID', // Get this from Firebase Console Web config
    messagingSenderId: '198483032831',
    projectId: 'resume-app-8ff9c',
    authDomain: 'resume-app-8ff9c.firebaseapp.com',
    storageBucket: 'resume-app-8ff9c.firebasestorage.app',
  );

  // Initialize Firebase based on platform
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return ios;
      default:
        return web;
    }
  }
}
