import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_state_manager.dart';

/// Simple error recovery service
class ErrorRecoveryService {
  static ErrorRecoveryService? _instance;
  static ErrorRecoveryService get instance =>
      _instance ??= ErrorRecoveryService._();

  ErrorRecoveryService._();

  final Map<String, int> _retryCounters = {};
  final Map<String, Timer> _retryTimers = {};

  static const int maxRetries = 3;
  static const Duration baseRetryDelay = Duration(seconds: 2);

  /// Handle error with automatic retry logic
  Future<T?> handleWithRetry<T>({
    required String operationKey,
    required Future<T> Function() operation,
    required void Function(String error) onError,
    VoidCallback? onMaxRetriesReached,
  }) async {
    try {
      final result = await operation();
      // Reset retry counter on success
      _retryCounters.remove(operationKey);
      AppStateManager.instance.clearError();
      return result;
    } catch (e) {
      return _handleRetry(
        operationKey: operationKey,
        operation: operation,
        onError: onError,
        onMaxRetriesReached: onMaxRetriesReached,
        error: e.toString(),
      );
    }
  }

  Future<T?> _handleRetry<T>({
    required String operationKey,
    required Future<T> Function() operation,
    required void Function(String error) onError,
    VoidCallback? onMaxRetriesReached,
    required String error,
  }) async {
    final currentRetries = _retryCounters[operationKey] ?? 0;

    if (currentRetries >= maxRetries) {
      onError('Operation failed after $maxRetries attempts: $error');
      onMaxRetriesReached?.call();
      AppStateManager.instance.setError('Operation failed: $error');
      return null;
    }

    _retryCounters[operationKey] = currentRetries + 1;
    final delay =
        Duration(seconds: baseRetryDelay.inSeconds * (currentRetries + 1));

    if (kDebugMode) {
      print(
          '🔄 Retrying $operationKey (attempt ${currentRetries + 1}/$maxRetries) in ${delay.inSeconds}s');
    }

    _retryTimers[operationKey] = Timer(delay, () async {
      await handleWithRetry(
        operationKey: operationKey,
        operation: operation,
        onError: onError,
        onMaxRetriesReached: onMaxRetriesReached,
      );
    });

    return null;
  }

  /// Cancel pending retries for an operation
  void cancelRetry(String operationKey) {
    _retryTimers[operationKey]?.cancel();
    _retryTimers.remove(operationKey);
    _retryCounters.remove(operationKey);
  }

  /// Reset all retry states
  void resetAllRetries() {
    for (final timer in _retryTimers.values) {
      timer.cancel();
    }
    _retryTimers.clear();
    _retryCounters.clear();
  }

  /// Check if operation is currently retrying
  bool isRetrying(String operationKey) {
    return _retryTimers.containsKey(operationKey);
  }

  void dispose() {
    resetAllRetries();
  }
}
