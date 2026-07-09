import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:signify/config/app_config.dart';

Future initFirebase() async {
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_WEB_API_KEY',
              defaultValue: ''),
          authDomain: String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN',
              defaultValue: ''),
          projectId: String.fromEnvironment('FIREBASE_WEB_PROJECT_ID',
              defaultValue: ''),
          storageBucket: String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET',
              defaultValue: ''),
          messagingSenderId: String.fromEnvironment('FIREBASE_WEB_MESSAGING_SENDER_ID',
              defaultValue: ''),
          appId: String.fromEnvironment('FIREBASE_WEB_APP_ID',
              defaultValue: ''),
          measurementId: String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID',
              defaultValue: ''),
        ),
      );
    } else {
      await Firebase.initializeApp();
    }


    // Activate App Check after Firebase initialization
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.appAttest,
        webProvider: kIsWeb
            ? ReCaptchaV3Provider(
                const String.fromEnvironment(
                  'RECAPTCHA_SITE_KEY',
                  defaultValue: '',
                ),
              )
            : null,
      );
      AppConfig.secureLog('🔐 App Check activated');
    } on PlatformException catch (e, s) {
      // App Check activation failures should be logged but are non-fatal
      AppConfig.secureLog('App Check activation failed: ${e.message}');
      await FirebaseCrashlytics.instance.recordError(
        e,
        s,
        reason: 'App Check activation failed',
        fatal: false,
      );
    }

    AppConfig.secureLog('✅ Firebase initialized successfully');
  } catch (error, stack) {
    AppConfig.secureLog('❌ Failed to initialize Firebase: $error');
    // Record as non-fatal so we still allow app to continue
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        fatal: false,
        reason: 'Firebase init failed',
      );
    } catch (_) {
      // Ignore if Crashlytics not available yet
    }
    // Continue app initialization even if Firebase fails
  }
}
