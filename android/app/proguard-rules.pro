# Flutter and most Android plugins ship their own consumer rules.
# Keep this file minimal so R8 can aggressively shrink release builds.

# Firebase initializes from Android manifest-discovered components before
# Flutter code runs. If these classes are removed, the release app crashes
# on launch with ClassNotFoundException for FirebaseInitProvider.
-keep class com.google.firebase.provider.FirebaseInitProvider { *; }
-keep class com.google.firebase.components.ComponentDiscoveryService { *; }
-keep class com.google.firebase.components.ComponentRegistrar { *; }
-keep class com.google.firebase.**Registrar { *; }
-keep class io.flutter.plugins.firebase.core.FlutterFirebaseCoreRegistrar { *; }
-keep class io.flutter.plugins.firebase.auth.FlutterFirebaseAuthRegistrar { *; }
-keep class io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestoreRegistrar { *; }