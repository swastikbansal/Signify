import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/app_state_manager.dart';

/// Simple error boundary widget that catches errors and provides recovery
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final String operationKey;

  const ErrorBoundary({
    super.key,
    required this.child,
    required this.operationKey,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool hasError = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _retry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return widget.child;
  }

  void _retry() {
    setState(() {
      hasError = false;
      errorMessage = null;
    });
    AppStateManager.instance.clearError();
  }

  @override
  void initState() {
    super.initState();
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
      setState(() {
        hasError = true;
        errorMessage = details.exception.toString();
      });
    };
  }
}
