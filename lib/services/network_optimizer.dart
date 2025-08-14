import 'dart:async';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../services/performance_cache_manager.dart';
import '../services/app_state_manager.dart';

/// High-performance network and API optimization service
class NetworkOptimizer {
  static NetworkOptimizer? _instance;
  static NetworkOptimizer get instance => _instance ??= NetworkOptimizer._();

  NetworkOptimizer._();

  // Request deduplication
  final Map<String, Future<dynamic>> _ongoingRequests = {};

  // Connection pool
  final Map<String, DateTime> _connectionPool = {};

  // Request batching
  final Map<String, List<dynamic>> _batchedRequests = {};
  Timer? _batchTimer;

  static const Duration batchDelay = Duration(milliseconds: 100);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const int maxRetries = 3;

  /// Initialize network optimizations
  void initialize() {
    _startBatchTimer();
    print('🌐 Network optimizer initialized');
  }

  /// Start batch processing timer
  void _startBatchTimer() {
    _batchTimer = Timer.periodic(batchDelay, (_) {
      _processBatchedRequests();
    });
  }

  /// Optimized API request with automatic retry and caching
  Future<T> optimizedRequest<T>({
    required String endpoint,
    required Future<T> Function() request,
    Duration cacheTtl = const Duration(minutes: 15),
    bool useCache = true,
    String? cacheKey,
  }) async {
    final key = cacheKey ?? endpoint;

    // Check cache first
    if (useCache) {
      final cache = PerformanceCacheManager.instance.getCache<String, T>(
        'api_cache',
        ttl: cacheTtl,
      );

      final cached = cache.get(key);
      if (cached != null) {
        AppConfig.secureLog('✅ API cache hit: $key');
        return cached;
      }
    }

    // Deduplicate ongoing requests
    if (_ongoingRequests.containsKey(key)) {
      AppConfig.secureLog('🔄 Deduplicating request: $key');
      return await _ongoingRequests[key] as T;
    }

    // Create request with retry logic
    final future = _requestWithRetry(request, key);
    _ongoingRequests[key] = future;

    try {
      final result = await future;

      // Cache successful result
      if (useCache) {
        final cache = PerformanceCacheManager.instance.getCache<String, T>(
          'api_cache',
          ttl: cacheTtl,
        );
        cache.put(key, result);
      }

      return result;
    } finally {
      _ongoingRequests.remove(key);
    }
  }

  /// Request with automatic retry logic
  Future<T> _requestWithRetry<T>(
    Future<T> Function() request,
    String key,
  ) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await request().timeout(connectionTimeout);
      } catch (e) {
        attempts++;
        AppConfig.secureLog(
            '⚠️ Request failed (attempt $attempts/$maxRetries): $key - $e');

        if (attempts >= maxRetries) {
          AppStateManager.instance
              .setError('Network request failed after $maxRetries attempts');
          rethrow;
        }

        // Exponential backoff
        await Future.delayed(Duration(milliseconds: 100 * attempts));
      }
    }

    throw Exception('Request failed after $maxRetries attempts');
  }

  /// Add request to batch
  void batchRequest(String batchKey, dynamic request) {
    _batchedRequests.putIfAbsent(batchKey, () => []).add(request);
  }

  /// Process batched requests
  void _processBatchedRequests() {
    if (_batchedRequests.isEmpty) return;

    for (final entry in _batchedRequests.entries) {
      final batchKey = entry.key;
      final requests = entry.value;

      if (requests.isNotEmpty) {
        AppConfig.secureLog(
            '📦 Processing batch: $batchKey (${requests.length} requests)');
        // Process batch - implement specific batch processing logic here
        requests.clear();
      }
    }
  }

  /// Preload critical resources
  Future<void> preloadCriticalResources(List<String> urls) async {
    final futures = urls.map((url) => optimizedRequest<dynamic>(
          endpoint: url,
          request: () async {
            // Implement actual request logic here
            return {};
          },
          cacheTtl: const Duration(hours: 1),
        ));

    try {
      await Future.wait(futures, eagerError: false);
      AppConfig.secureLog('✅ Critical resources preloaded');
    } catch (e) {
      AppConfig.secureLog('⚠️ Some resources failed to preload: $e');
    }
  }

  /// Clear network cache
  void clearCache() {
    final cache =
        PerformanceCacheManager.instance.getCache<String, dynamic>('api_cache');
    cache.clear();
    print('🧹 Network cache cleared');
  }

  /// Dispose network optimizer
  void dispose() {
    _batchTimer?.cancel();
    _ongoingRequests.clear();
    _batchedRequests.clear();
    _connectionPool.clear();
  }
}

/// Connection health monitor
class ConnectionHealthMonitor {
  static ConnectionHealthMonitor? _instance;
  static ConnectionHealthMonitor get instance =>
      _instance ??= ConnectionHealthMonitor._();

  ConnectionHealthMonitor._();

  final bool _isOnline = true;
  final List<VoidCallback> _listeners = [];
  Timer? _healthCheckTimer;

  /// Initialize connection monitoring
  void initialize() {
    _startHealthChecks();
    print('📡 Connection health monitor initialized');
  }

  /// Start periodic health checks
  void _startHealthChecks() {
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkConnection();
    });
  }

  /// Check connection health
  Future<void> _checkConnection() async {
    try {
      // Implement actual connection check
      final wasOnline = _isOnline;
      // _isOnline = await _performHealthCheck();

      if (wasOnline != _isOnline) {
        _notifyListeners();
        AppStateManager.instance.setOnlineStatus(_isOnline);
      }
    } catch (e) {
      AppConfig.secureLog('Connection health check failed: $e');
    }
  }

  /// Add connection status listener
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  /// Remove connection status listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// Notify all listeners
  void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        AppConfig.secureLog('Error in connection listener: $e');
      }
    }
  }

  /// Get current connection status
  bool get isOnline => _isOnline;

  /// Dispose connection monitor
  void dispose() {
    _healthCheckTimer?.cancel();
    _listeners.clear();
  }
}
