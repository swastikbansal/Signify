# =============================================================================
# PRODUCTION-GRADE PROGUARD RULES FOR FLUTTER + FIREBASE
# Optimized for Performance, Security, and Stability
# =============================================================================

# =============================================================================
# CORE OPTIMIZATION SETTINGS
# =============================================================================
# Optimize for performance and size
-optimizationpasses 3
-allowaccessmodification
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose

# Advanced optimizations (exclude problematic ones)
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*,!method/removal/parameter,!method/propagation/parameter

# Package flattening for better obfuscation
-repackageclasses ''

# =============================================================================
# DEBUGGING AND STACK TRACE SUPPORT
# =============================================================================
# Essential for crash reporting and debugging
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
-keepattributes Signature,Exceptions,*Annotation*,InnerClasses,EnclosingMethod

# =============================================================================
# FLUTTER CORE FRAMEWORK
# =============================================================================
# Essential Flutter classes and method channels
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Method and Event Channels (critical for plugin communication)
-keep class * extends io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
-keep class * extends io.flutter.plugin.common.EventChannel$StreamHandler { *; }
-keep class * implements io.flutter.plugin.common.MessageCodec { *; }
-keep class * implements io.flutter.plugin.common.MethodCodec { *; }

# Dart VM service protocol
-keep class io.flutter.view.VsyncWaiter { *; }
-keep class io.flutter.view.AccessibilityBridge { *; }

# =============================================================================
# FIREBASE AND GOOGLE SERVICES (CONSOLIDATED & OPTIMIZED)
# =============================================================================
# Core Firebase classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.iid.** { *; }
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.analytics.** { *; }
-keep class com.google.firebase.crashlytics.** { *; }
-keep class com.google.firebase.auth.** { *; }
-keep class com.google.firebase.firestore.** { *; }
-keep class com.google.firebase.storage.** { *; }
-keep class com.google.firebase.remoteconfig.** { *; }
-keep class com.google.firebase.performance.** { *; }
-keep class com.google.firebase.functions.** { *; }
-keep class com.google.firebase.appcheck.** { *; }

# Google Play Services
-keep class com.google.android.gms.common.** { *; }
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.android.gms.tasks.** { *; }
-keep class com.google.android.gms.location.** { *; }
-keep class com.google.android.gms.maps.** { *; }

# ML Kit and Vision
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.vision.** { *; }
-keep class com.google.mlkit.vision.** { *; }

# =============================================================================
# KOTLIN AND COROUTINES
# =============================================================================
# Kotlin reflection and metadata
-keep class kotlin.Metadata { *; }
-keep class kotlin.reflect.** { *; }
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# Kotlin Coroutines (optimized)
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Kotlin serialization
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt

# =============================================================================
# ANDROID ARCHITECTURE COMPONENTS
# =============================================================================
# AndroidX and Support Libraries
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# Architecture Components
-keep class androidx.lifecycle.** { *; }
-keep class androidx.room.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.navigation.** { *; }

# Camera X
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**

# =============================================================================
# MEDIA AND CAMERA HANDLING
# =============================================================================
# Camera and media processing
-keep class android.hardware.camera2.** { *; }
-keep class android.media.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# =============================================================================
# NETWORKING AND JSON
# =============================================================================
# OkHttp and Retrofit (if used)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Gson (consolidated)
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# JSON and reflection
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# =============================================================================
# NATIVE METHODS AND JNI
# =============================================================================
# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# =============================================================================
# SERIALIZATION
# =============================================================================
# Serializable classes
-keep class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# =============================================================================
# ENUMS AND ANNOTATIONS
# =============================================================================
# Keep enum methods
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep annotations
-keep class * extends java.lang.annotation.Annotation { *; }

# =============================================================================
# SECURITY AND OBFUSCATION ENHANCEMENTS
# =============================================================================
# Remove debugging information
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# =============================================================================
# WARNING SUPPRESSIONS (CONSOLIDATED)
# =============================================================================
# Common warnings to suppress
-dontwarn org.checkerframework.**
-dontwarn javax.annotation.**
-dontwarn org.jetbrains.annotations.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn java.lang.instrument.ClassFileTransformer
-dontwarn sun.misc.SignalHandler
-dontwarn java.lang.invoke.StringConcatFactory

# Google Play Core
-dontwarn com.google.android.play.core.**

# Firebase specific warnings
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
-dontwarn com.google.mlkit.**

# =============================================================================
# FLUTTER-SPECIFIC OPTIMIZATIONS
# =============================================================================
# Flutter engine optimizations
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.android.** { *; }

# Platform views
-keep class io.flutter.plugin.platform.** { *; }

# Accessibility
-keep class io.flutter.view.AccessibilityBridge$** { *; }

# =============================================================================
# THIRD-PARTY LIBRARIES (ADD AS NEEDED)
# =============================================================================
# Add rules for other libraries you're using
# Example for popular libraries:

# Picasso (if used)
# -dontwarn com.squareup.picasso.**

# Glide (if used)
# -keep public class * implements com.bumptech.glide.module.GlideModule
# -keep public class * extends com.bumptech.glide.module.AppGlideModule

# =============================================================================
# END OF PROGUARD RULES
# =============================================================================
