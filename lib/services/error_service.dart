import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Modern error handling service using Flutter's built-in error reporting
/// Replaces custom error boundary with industry-standard practices
class ErrorService {
  static ErrorService? _instance;
  static ErrorService get instance => _instance ??= ErrorService._();

  ErrorService._();

  /// Initialize error handling for the app
  void initialize() {
    // Set up Flutter's error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log the error in debug mode
      if (kDebugMode) {
        FlutterError.presentError(details);
      } else {
        // In release mode, report to crash analytics service
        _reportError(details.exception, details.stack);
      }
    };

    // Handle errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      _reportError(error, stack);
      return true;
    };
  }

  /// Report errors to analytics service
  void _reportError(Object error, StackTrace? stack) {
    // TODO: When Sentry/Crashlytics is added, report errors here
    if (kDebugMode) {
      debugPrint('Error: $error');
      debugPrint('Stack: $stack');
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
