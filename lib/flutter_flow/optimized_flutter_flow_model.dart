import 'dart:async';
import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_model.dart';
import '/services/memory_optimizer.dart';
import '/services/performance_cache_manager.dart';

/// Performance-optimized base class for FlutterFlow models
abstract class OptimizedFlutterFlowModel<W extends Widget>
    extends FlutterFlowModel<W> implements Disposable {
  // Performance tracking
  final Stopwatch _initStopwatch = Stopwatch();
  final List<Timer> _timers = [];
  final List<StreamSubscription> _subscriptions = [];

  // Cache for this model
  late final LRUCache<String, dynamic> _modelCache;

  @override
  void initState(BuildContext context) {
    _initStopwatch.start();

    // Initialize model-specific cache
    final modelName = runtimeType.toString();
    _modelCache = PerformanceCacheManager.instance.getCache<String, dynamic>(
      'model_$modelName',
      maxSize: 50,
      ttl: const Duration(minutes: 30),
    );

    // Register with memory optimizer
    MemoryOptimizer.instance.registerDisposable(this);

    // Call the abstract initState - subclasses must implement
    initStateOptimized(context);

    _initStopwatch.stop();
    if (_initStopwatch.elapsedMilliseconds > 100) {
      print(
          '⚠️ Slow model initialization: $modelName took ${_initStopwatch.elapsedMilliseconds}ms');
    }
  }

  /// Subclasses should override this instead of initState
  void initStateOptimized(BuildContext context);

  /// Create an optimized timer that's automatically cleaned up
  Timer createOptimizedTimer(Duration duration, VoidCallback callback) {
    final timer = Timer.periodic(duration, (_) {
      try {
        callback();
      } catch (e) {
        print('Error in optimized timer: $e');
      }
    });
    _timers.add(timer);
    return timer;
  }

  /// Create an optimized stream subscription that's automatically cleaned up
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
    _subscriptions.add(subscription);
    return subscription;
  }

  /// Cache a value with automatic expiry
  void cacheValue(String key, dynamic value, {Duration? ttl}) {
    _modelCache.put(key, value);
  }

  /// Get a cached value
  T? getCachedValue<T>(String key) {
    return _modelCache.get(key) as T?;
  }

  /// Check if a value is cached
  bool hasCachedValue(String key) {
    return _modelCache.containsKey(key);
  }

  /// Clear model cache
  void clearCache() {
    _modelCache.clear();
  }

  @override
  void dispose() {
    try {
      // Cancel all timers
      for (final timer in _timers) {
        timer.cancel();
      }
      _timers.clear();

      // Cancel all subscriptions
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();

      // Clear cache
      clearCache();

      // Call subclass dispose
      disposeOptimized();

      print('✅ OptimizedFlutterFlowModel $runtimeType disposed successfully');
    } catch (e) {
      print('⚠️ Error disposing OptimizedFlutterFlowModel: $e');
    }
  }

  /// Subclasses should override this instead of dispose
  void disposeOptimized();

  /// Measure performance of operations
  T measurePerformance<T>(String operationName, T Function() operation) {
    final stopwatch = Stopwatch()..start();
    try {
      final result = operation();
      stopwatch.stop();

      if (stopwatch.elapsedMilliseconds > 50) {
        print(
            '⚠️ Slow operation: $operationName in $runtimeType took ${stopwatch.elapsedMilliseconds}ms');
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      print('❌ Error in $operationName: $e');
      rethrow;
    }
  }

  /// Async version of performance measurement
  Future<T> measurePerformanceAsync<T>(
      String operationName, Future<T> Function() operation) async {
    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();

      if (stopwatch.elapsedMilliseconds > 100) {
        print(
            '⚠️ Slow async operation: $operationName in $runtimeType took ${stopwatch.elapsedMilliseconds}ms');
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      print('❌ Error in async $operationName: $e');
      rethrow;
    }
  }
}

/// Performance-optimized widget mixin
mixin OptimizedWidget<T extends StatefulWidget> on State<T> {
  final List<Timer> _optimizedTimers = [];
  final List<StreamSubscription> _optimizedSubscriptions = [];

  @override
  void initState() {
    super.initState();
    // Register with memory optimizer
    MemoryOptimizer.instance.registerDisposable(_WidgetDisposable(this));
  }

  /// Create a memory-tracked timer
  Timer createOptimizedTimer(Duration duration, VoidCallback callback) {
    final timer = Timer.periodic(duration, (_) {
      if (mounted) {
        try {
          callback();
        } catch (e) {
          print('Error in widget timer: $e');
        }
      }
    });
    _optimizedTimers.add(timer);
    return timer;
  }

  /// Create a memory-tracked stream subscription
  StreamSubscription<E> createOptimizedSubscription<E>(
    Stream<E> stream,
    void Function(E) onData,
  ) {
    final subscription = stream.listen((data) {
      if (mounted) {
        try {
          onData(data);
        } catch (e) {
          print('Error in widget subscription: $e');
        }
      }
    });
    _optimizedSubscriptions.add(subscription);
    return subscription;
  }

  /// Dispose all tracked resources
  void disposeOptimizedResources() {
    for (final timer in _optimizedTimers) {
      timer.cancel();
    }
    _optimizedTimers.clear();

    for (final subscription in _optimizedSubscriptions) {
      subscription.cancel();
    }
    _optimizedSubscriptions.clear();
  }

  @override
  void dispose() {
    disposeOptimizedResources();
    super.dispose();
  }
}

/// Disposable wrapper for widgets
class _WidgetDisposable implements Disposable {
  final State state;
  _WidgetDisposable(this.state);

  @override
  void dispose() {
    if (state is OptimizedWidget) {
      (state as OptimizedWidget).disposeOptimizedResources();
    }
  }
}
