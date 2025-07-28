# TensorFlow Lite ProGuard rules
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory** { *; }
-keep class org.tensorflow.lite.nnapi.** { *; }
-keep class org.tensorflow.lite.support.** { *; }

# Keep TensorFlow Lite model files
-keep class * extends org.tensorflow.lite.support.model.Model { *; }

# Keep classes for ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }

# Flutter and Dart specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Camera and media related
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# Additional rules for common issues
-dontwarn org.tensorflow.lite.gpu.**
-dontwarn org.tensorflow.lite.nnapi.**
-dontwarn org.checkerframework.**
-dontwarn javax.annotation.**

# Add project specific ProGuard rules here.

# Keep MediaPipe classes
-keep class com.google.mediapipe.** { *; }
-keep class org.tensorflow.lite.** { *; }
-keepclassmembers class * {
    @com.google.mediapipe.framework.annotations.* <methods>;
}

# Keep Flutter classes
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

# Keep Google Play Core classes
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep ML Kit classes
-keep class com.google.mlkit.** { *; }
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
-dontwarn com.google.mlkit.**

# Keep MediaPipe proto classes
-keep class com.google.mediapipe.proto.** { *; }
-dontwarn com.google.mediapipe.proto.**

# Keep javax.lang.model classes (annotation processing)
-keep class javax.lang.model.** { *; }
-dontwarn javax.lang.model.**

# Keep AutoValue generated classes
-keep class com.google.auto.value.** { *; }
-keep class autovalue.shaded.** { *; }
-dontwarn com.google.auto.value.**
-dontwarn autovalue.shaded.**

# Keep all enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep all classes with native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Firebase and Google Services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Specific rules for missing classes
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.mediapipe.proto.**
-dontwarn javax.lang.model.**
-dontwarn autovalue.shaded.**

# Keep Kotlin coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Keep annotation processors
-keep class com.google.auto.** { *; }
-dontwarn com.google.auto.**

# Add rules for your specific platform.
-dontwarn com.google.mediapipe.**
-keep class com.google.mediapipe.** { *; }
-keepclassmembers class com.google.mediapipe.** { *; }

# Keep MediaPipe native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep TensorFlow Lite classes
-keep class org.tensorflow.lite.** { *; }
-keepclassmembers class org.tensorflow.lite.** { *; }

# Keep camera related classes
-keep class androidx.camera.** { *; }

