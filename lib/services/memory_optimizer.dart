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

  static const Duration MEMORY_CHECK_INTERVAL =
      Duration(minutes: 5); // Much less frequent
  static const int MEMORY_WARNING_THRESHOLD_MB = 300; // Increased threshold
  static const int MEMORY_CRITICAL_THRESHOLD_MB = 400; // Increased threshold

  /// Initialize memory monitoring - disabled aggressive monitoring
  Future<void> initialize() async {
    // Disable memory monitoring during image capture to prevent app restarts
    // _memoryMonitorTimer =
    //     Timer.periodic(MEMORY_CHECK_INTERVAL, (_) => _checkMemoryUsage());

    // Don't listen to lifecycle messages during image capture
    // SystemChannels.lifecycle.setMessageHandler(_handleLifecycleMessage);

    print(
        '🧠 MemoryOptimizer initialized (monitoring disabled for image capture compatibility)');
  }

  /// Handle app lifecycle changes for memory optimization - DISABLED
  // Future<String?> _handleLifecycleMessage(String? message) async {
  //   switch (message) {
  //     case 'AppLifecycleState.paused':
  //       await _optimizeMemoryOnPause();
  //       break;
  //     case 'AppLifecycleState.resumed':
  //       await _optimizeMemoryOnResume();
  //       break;
  //     case 'AppLifecycleState.detached':
  //       await _cleanupOnDetach();
  //       break;
  //   }
  //   return null;
  // }

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

  /// Force memory cleanup - made much less aggressive
  Future<void> forceCleanup() async {
    print('🧹 Starting gentle memory cleanup...');

    // Only clean up weak references, don't trigger aggressive cleanup
    _cleanupWeakReferences();

    // Don't trigger garbage collection during image processing
    // await _triggerGC();

    // Don't notify listeners during image capture to prevent app restart
    // for (final listener in _memoryPressureListeners) {
    //   try {
    //     listener();
    //   } catch (e) {
    //     print('Error in memory pressure listener: $e');
    //   }
    // }

    print('✅ Gentle memory cleanup completed');
  }

  /// Get memory statistics without triggering cleanup
  Map<String, dynamic> getMemoryStats() {
    return {
      'disposablesCount': _disposables.length,
      'memoryListenersCount': _memoryPressureListeners.length,
      'monitoringEnabled': _memoryMonitorTimer?.isActive ?? false,
    };
  }

  /// Check current memory usage - DISABLED
  // Future<void> _checkMemoryUsage() async {
  //   try {
  //     // This is a simplified memory check - in production you'd use more sophisticated methods
  //     final currentMemory = await _getCurrentMemoryUsageMB();
  //
  //     if (currentMemory > MEMORY_CRITICAL_THRESHOLD_MB) {
  //       print('🚨 Critical memory usage: ${currentMemory}MB');
  //       await forceCleanup();
  //     } else if (currentMemory > MEMORY_WARNING_THRESHOLD_MB) {
  //       print('⚠️ High memory usage: ${currentMemory}MB');
  //       await _gentleCleanup();
  //     }
  //   } catch (e) {
  //     print('Error checking memory usage: $e');
  //   }
  // }

  /// Get approximate memory usage (simplified implementation) - DISABLED
  // Future<double> _getCurrentMemoryUsageMB() async {
  //   return 100.0; // Placeholder value
  // }

  /// Gentle cleanup for memory pressure - DISABLED
  // Future<void> _gentleCleanup() async {
  //   _cleanupWeakReferences();
  //   final listenersToNotify = _memoryPressureListeners.take(3);
  //   for (final listener in listenersToNotify) {
  //     try {
  //       listener();
  //     } catch (e) {
  //       print('Error in gentle cleanup listener: $e');
  //     }
  //   }
  // }

  /// Cleanup when app is paused - DISABLED
  // Future<void> _optimizeMemoryOnPause() async {
  //   print('📱 App paused - optimizing memory...');
  //   _cleanupWeakReferences();
  //   await _triggerGC();
  //   for (final listener in _memoryPressureListeners) {
  //     try {
  //       listener();
  //     } catch (e) {
  //       print('Error in pause cleanup listener: $e');
  //     }
  //   }
  // }

  /// Optimize when app resumes - DISABLED
  // Future<void> _optimizeMemoryOnResume() async {
  //   print('📱 App resumed - performing light cleanup...');
  //   _cleanupWeakReferences();
  // }

  /// Cleanup when app is detached - DISABLED
  // Future<void> _cleanupOnDetach() async {
  //   print('📱 App detached - performing full cleanup...');
  //   await forceCleanup();
  //   dispose();
  // }

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

  /// Trigger garbage collection - DISABLED
  // Future<void> _triggerGC() async {
  //   if (kDebugMode) {
  //     await Future.delayed(const Duration(milliseconds: 10));
  //   }
  // }

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
