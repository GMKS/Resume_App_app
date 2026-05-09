// ─────────────────────────────────────────────────────────
// STEP: Fill in your Firebase project config below.
//
// How to get these values:
//  1. Go to https://console.firebase.google.com
//  2. Open your project → Project Settings (gear icon)
//  3. Scroll to "Your apps" → Add app → Web (</>) 
//  4. Register app, then copy the firebaseConfig values below.
//  5. Enable Anonymous Auth:
//     Authentication → Sign-in method → Anonymous → Enable
//  6. Create Firestore database:
//     Firestore Database → Create database → Start in test mode
// ─────────────────────────────────────────────────────────

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  // ── Replace with your Firebase web config ──────────────────────────────────
  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyD9OFZaE-UxSDdwXKKxypXpb8c_o5O4WaE',
    appId:             '1:884039901207:web:a5d265c97dcdbe63f67c52',
    messagingSenderId: '884039901207',
    projectId:         'resumeapplatest',
    authDomain:        'resumeapplatest.firebaseapp.com',
    storageBucket:     'resumeapplatest.appspot.com', // fixed to .appspot.com
  );

  // ── Replace with your Firebase Android config (if needed) ─────────────────
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyCkVCab7a8ILrPHX2V6Ku914iq5i3q4gOU',
    appId:             '1:884039901207:android:1de65ec897aee7c9f67c52',
    messagingSenderId: '884039901207',
    projectId:         'resumeapplatest',
    storageBucket:     'resumeapplatest.firebasestorage.app',
  );

  // ── Replace with your Firebase iOS config (if needed) ─────────────────────
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'YOUR_IOS_API_KEY',
    appId:             'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId:         'YOUR_PROJECT_ID',
    storageBucket:     'YOUR_PROJECT_ID.appspot.com',
    iosClientId:       'YOUR_IOS_CLIENT_ID',
    iosBundleId:       'com.yourcompany.resumeBuilder',
  );
}
