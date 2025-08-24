import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:signify/config/app_config.dart';

/// Production-grade error handling service with Firebase Crashlytics integration
/// Provides comprehensive error reporting, user feedback, and debugging capabilities
class ErrorService {
  static ErrorService? _instance;
  static ErrorService get instance => _instance ??= ErrorService._();

  ErrorService._();

  /// Initialize error handling for the app
  void initialize() {
    try {
      // Only configure Crashlytics if Firebase is available
      _configureCrashlytics();
    } catch (e) {
      if (kDebugMode) {
        print('Warning: Could not initialize Crashlytics: $e');
      }
    }

    // Set up Flutter's error handling (both debug and release)
    FlutterError.onError = (FlutterErrorDetails details) {
      // In debug mode, show detailed error
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
      // Report to Crashlytics if available
      _reportFlutterError(details);
    };

    // Handle errors not caught by Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      _reportPlatformError(error, stack);
      return true;
    };

    // Set up isolate error handling for comprehensive coverage
    Isolate.current.addErrorListener(
      RawReceivePort((pair) async {
        final List<dynamic> errorAndStacktrace = pair;
        await _reportIsolateError(
          errorAndStacktrace.first,
          errorAndStacktrace.last,
        );
      }).sendPort,
    );
  }

  /// Configure Crashlytics safely
  void _configureCrashlytics() {
    FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(AppConfig.enableCrashReporting)
        .catchError((_) {});
  }

  /// Report Flutter errors safely
  void _reportFlutterError(FlutterErrorDetails details) {
    try {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } catch (_) {
      // Silently ignore if Crashlytics is not available
    }
  }

  /// Report platform errors safely
  void _reportPlatformError(Object error, StackTrace stack) {
    try {
      FirebaseCrashlytics.instance
          .recordError(error, stack, fatal: true)
          .catchError((_) {});
    } catch (_) {
      // Silently ignore if Crashlytics is not available
    }
  }

  /// Report isolate errors safely
  Future<void> _reportIsolateError(Object error, StackTrace stack) async {
    try {
      await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    } catch (_) {
      // Silently ignore if Crashlytics is not available
    }
  }

  /// Report errors to analytics service
  void _reportError(Object error, StackTrace? stack) {
    // Report non-fatal errors to Crashlytics for production monitoring
    FirebaseCrashlytics.instance
        .recordError(error, stack, fatal: false)
        .catchError((_) {});
  }

  /// Public method to report non-fatal errors
  static void reportError(Object error, [StackTrace? stack]) {
    instance._reportError(error, stack);
  }

  /// Handle caught exceptions with optional context
  static Future<void> recordException(
    Object exception,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
    bool fatal = false,
  }) async {
    try {
      // Add context as custom keys if provided
      if (context != null) {
        for (final entry in context.entries) {
          setCustomKey('context_${entry.key}', entry.value);
        }
      }

      await FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace,
        fatal: fatal,
        reason: reason,
      );
    } catch (_) {
      // Fail silently if Crashlytics is not available
    }
  }

  /// Lightweight breadcrumb logging to Crashlytics
  static Future<void> log(String message) async {
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (_) {
      // Fail silently if Crashlytics is not available
    }
  }

  /// Set custom key-value pairs for enhanced crash reports
  static void setCustomKey(String key, Object value) {
    try {
      FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (_) {
      // Fail silently if Crashlytics is not available
    }
  }

  /// Set user identifier for crash reports (use anonymized ID)
  static void setUserIdentifier(String identifier) {
    try {
      FirebaseCrashlytics.instance.setUserIdentifier(identifier);
    } catch (_) {
      // Fail silently if Crashlytics is not available
    }
  }

  /// Show user-friendly error dialog
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Custom error widget for better UX
  static Widget buildErrorWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Global error boundary widget
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(String error)? errorBuilder;

  const ErrorBoundary({super.key, required this.child, this.errorBuilder});

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(_error!) ??
          ErrorService.buildErrorWidget(_error!);
    }

    return ErrorCatcher(
      onError: (error) {
        setState(() {
          _error = error.toString();
        });
      },
      child: widget.child,
    );
  }
}

/// Error catching widget
class ErrorCatcher extends StatefulWidget {
  final Widget child;
  final Function(Object error) onError;

  const ErrorCatcher({super.key, required this.child, required this.onError});

  @override
  State<ErrorCatcher> createState() => _ErrorCatcherState();
}

class _ErrorCatcherState extends State<ErrorCatcher> {
  @override
  Widget build(BuildContext context) {
    try {
      return widget.child;
    } catch (error) {
      widget.onError(error);
      return ErrorService.buildErrorWidget(error.toString());
    }
  }
}
