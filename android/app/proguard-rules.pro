# Keep smart_auth plugin classes and Google Play Services Auth API
-keep class fman.ge.smart_auth.** { *; }

# Don't warn about missing Google Play Services Auth API classes
-dontwarn com.google.android.gms.auth.api.credentials.Credential$Builder
-dontwarn com.google.android.gms.auth.api.credentials.Credential
-dontwarn com.google.android.gms.auth.api.credentials.CredentialPickerConfig$Builder
-dontwarn com.google.android.gms.auth.api.credentials.CredentialPickerConfig
-dontwarn com.google.android.gms.auth.api.credentials.CredentialRequest$Builder
-dontwarn com.google.android.gms.auth.api.credentials.CredentialRequest
-dontwarn com.google.android.gms.auth.api.credentials.CredentialRequestResponse
-dontwarn com.google.android.gms.auth.api.credentials.Credentials
-dontwarn com.google.android.gms.auth.api.credentials.CredentialsClient
-dontwarn com.google.android.gms.auth.api.credentials.HintRequest$Builder
-dontwarn com.google.android.gms.auth.api.credentials.HintRequest

# Keep Firebase classes
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep Google Mobile Ads classes
-keep class com.google.android.gms.ads.** { *; }
-dontwarn com.google.android.gms.ads.**

# === FLUTTER PERFORMANCE OPTIMIZATION ===
# Keep Flutter engine classes for faster startup
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Keep Flutter embedding classes
-keep class io.flutter.embedding.** { *; }

# Keep Google Play Core classes for dynamic delivery
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Suppress specific warnings for missing Google Play Core classes
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# === AGGRESSIVE OPTIMIZATION FOR STARTUP SPEED ===
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose
-allowaccessmodification
-mergeinterfacesaggressively

# Inline for better performance
-repackageclasses ''

# === REMOVE ALL DEBUG CODE FOR BETTER PERFORMANCE ===
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
    public static *** println(...);
}

# Remove debug prints
-assumenosideeffects class java.io.PrintStream {
    public void println(...);
    public void print(...);
}

# === APP-SPECIFIC OPTIMIZATIONS ===
# Keep HTTP classes for API communication
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**

# Keep SharedPreferences for faster settings access
-keep class android.content.SharedPreferences { *; }
-keep class android.content.SharedPreferences$Editor { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# === KOTLIN OPTIMIZATION ===
-dontwarn kotlin.**
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.unit
-dontwarn kotlin.jvm.internal.**

# === JSON SERIALIZATION ===
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }

# Keep line numbers for crash debugging
-keepattributes SourceFile,LineNumberTable