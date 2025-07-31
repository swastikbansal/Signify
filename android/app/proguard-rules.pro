# Camera and media related
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Additional rules for common issues
-dontwarn org.checkerframework.**
-dontwarn javax.annotation.**

# Add project specific ProGuard rules here.

# Flutter and Dart specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep method channels
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler {
    *;
}

# Firebase and Google Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Keep Kotlin coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Keep camera related classes
-keep class androidx.camera.** { *; }

