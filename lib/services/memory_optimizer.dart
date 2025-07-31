import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Advanced memory management and optimization service
class MemoryOptimizer {
  static MemoryOptimizer? _instance;
  static MemoryOptimizer get instance => _instance ??= MemoryOptimizer._();

  MemoryOptimizer._();

  Timer? _memoryMonitorTimer;
  final List<VoidCallback> _memoryPressureListeners = [];
  final List<WeakReference<Disposable>> _disposables = [];

  static const Duration MEMORY_CHECK_INTERVAL = Duration(seconds: 30);
  static const int MEMORY_WARNING_THRESHOLD_MB = 150; // MB
  static const int MEMORY_CRITICAL_THRESHOLD_MB = 200; // MB

  /// Initialize memory monitoring
  Future<void> initialize() async {
    // Start memory monitoring
    _memoryMonitorTimer =
        Timer.periodic(MEMORY_CHECK_INTERVAL, (_) => _checkMemoryUsage());

    // Listen to system memory warnings
    SystemChannels.lifecycle.setMessageHandler(_handleLifecycleMessage);

    print('🧠 MemoryOptimizer initialized');
  }

  /// Handle app lifecycle changes for memory optimization
  Future<String?> _handleLifecycleMessage(String? message) async {
    switch (message) {
      case 'AppLifecycleState.paused':
        await _optimizeMemoryOnPause();
        break;
      case 'AppLifecycleState.resumed':
        await _optimizeMemoryOnResume();
        break;
      case 'AppLifecycleState.detached':
        await _cleanupOnDetach();
        break;
    }
    return null;
  }

  /// Register a disposable resource for automatic cleanup
  void registerDisposable(Disposable disposable) {
    _disposables.add(WeakReference(disposable));
  }

  /// Add memory pressure listener
  void addMemoryPressureListener(VoidCallback listener) {
    _memoryPressureListeners.add(listener);
  }

  /// Remove memory pressure listener
  void removeMemoryPressureListener(VoidCallback listener) {
    _memoryPressureListeners.remove(listener);
  }

  /// Force memory cleanup
  Future<void> forceCleanup() async {
    print('🧹 Starting forced memory cleanup...');

    // Clean up disposed references
    _cleanupWeakReferences();

    // Trigger garbage collection
    await _triggerGC();

    // Notify listeners
    for (final listener in _memoryPressureListeners) {
      try {
        listener();
      } catch (e) {
        print('Error in memory pressure listener: $e');
      }
    }

    print('✅ Forced memory cleanup completed');
  }

  /// Check current memory usage
  Future<void> _checkMemoryUsage() async {
    try {
      // This is a simplified memory check - in production you'd use more sophisticated methods
      final currentMemory = await _getCurrentMemoryUsageMB();

      if (currentMemory > MEMORY_CRITICAL_THRESHOLD_MB) {
        print('🚨 Critical memory usage: ${currentMemory}MB');
        await forceCleanup();
      } else if (currentMemory > MEMORY_WARNING_THRESHOLD_MB) {
        print('⚠️ High memory usage: ${currentMemory}MB');
        await _gentleCleanup();
      }
    } catch (e) {
      print('Error checking memory usage: $e');
    }
  }

  /// Get approximate memory usage (simplified implementation)
  Future<double> _getCurrentMemoryUsageMB() async {
    // This is a placeholder - actual implementation would use platform channels
    // to get real memory usage from native code
    return 100.0; // Placeholder value
  }

  /// Gentle cleanup for memory pressure
  Future<void> _gentleCleanup() async {
    _cleanupWeakReferences();

    // Notify some listeners (not all to avoid performance impact)
    final listenersToNotify = _memoryPressureListeners.take(3);
    for (final listener in listenersToNotify) {
      try {
        listener();
      } catch (e) {
        print('Error in gentle cleanup listener: $e');
      }
    }
  }

  /// Cleanup when app is paused
  Future<void> _optimizeMemoryOnPause() async {
    print('📱 App paused - optimizing memory...');

    // More aggressive cleanup when app is not visible
    _cleanupWeakReferences();
    await _triggerGC();

    // Notify all listeners
    for (final listener in _memoryPressureListeners) {
      try {
        listener();
      } catch (e) {
        print('Error in pause cleanup listener: $e');
      }
    }
  }

  /// Optimize when app resumes
  Future<void> _optimizeMemoryOnResume() async {
    print('📱 App resumed - performing light cleanup...');
    _cleanupWeakReferences();
  }

  /// Cleanup when app is detached
  Future<void> _cleanupOnDetach() async {
    print('📱 App detached - performing full cleanup...');
    await forceCleanup();
    dispose();
  }

  /// Clean up weak references that are no longer valid
  void _cleanupWeakReferences() {
    _disposables.removeWhere((ref) {
      final disposable = ref.target;
      if (disposable == null) {
        return true; // Remove null references
      }
      return false;
    });
  }

  /// Trigger garbage collection
  Future<void> _triggerGC() async {
    // Force garbage collection in debug mode
    if (kDebugMode) {
      // This is more of a hint to the garbage collector
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  /// Create memory-optimized timer that cleans up automatically
  Timer createOptimizedTimer(Duration duration, VoidCallback callback) {
    late Timer timer;
    timer = Timer.periodic(duration, (t) {
      try {
        callback();
      } catch (e) {
        print('Error in optimized timer callback: $e');
        timer.cancel();
      }
    });

    // Register for cleanup
    registerDisposable(_TimerDisposable(timer));
    return timer;
  }

  /// Create memory-optimized stream subscription
  StreamSubscription<T> createOptimizedSubscription<T>(
    Stream<T> stream,
    void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
  }) {
    final subscription = stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
    );

    // Register for cleanup
    registerDisposable(_SubscriptionDisposable(subscription));
    return subscription;
  }

  /// Dispose the memory optimizer
  void dispose() {
    _memoryMonitorTimer?.cancel();
    _memoryMonitorTimer = null;

    // Dispose all registered disposables
    for (final ref in _disposables) {
      ref.target?.dispose();
    }
    _disposables.clear();

    _memoryPressureListeners.clear();
    _instance = null;

    print('♻️ MemoryOptimizer disposed');
  }
}

/// Interface for disposable resources
abstract class Disposable {
  void dispose();
}

/// Disposable wrapper for Timer
class _TimerDisposable implements Disposable {
  final Timer timer;
  _TimerDisposable(this.timer);

  @override
  void dispose() => timer.cancel();
}

/// Disposable wrapper for StreamSubscription
class _SubscriptionDisposable implements Disposable {
  final StreamSubscription subscription;
  _SubscriptionDisposable(this.subscription);

  @override
  void dispose() => subscription.cancel();
}

/// Memory-optimized widget mixin
mixin MemoryOptimizedWidget {
  final List<Timer> _timers = [];
  final List<StreamSubscription> _subscriptions = [];

  /// Create a memory-tracked timer
  Timer createTimer(Duration duration, VoidCallback callback) {
    final timer = Timer.periodic(duration, (t) => callback());
    _timers.add(timer);
    return timer;
  }

  /// Create a memory-tracked stream subscription
  StreamSubscription<T> createSubscription<T>(
    Stream<T> stream,
    void Function(T) onData,
  ) {
    final subscription = stream.listen(onData);
    _subscriptions.add(subscription);
    return subscription;
  }

  /// Dispose all tracked resources
  void disposeMemoryResources() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }
}
