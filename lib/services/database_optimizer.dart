import 'dart:async';
import '../config/app_config.dart';
import '../services/performance_cache_manager.dart';
import '../services/app_state_manager.dart';

/// High-performance database optimization service
class DatabaseOptimizer {
  static DatabaseOptimizer? _instance;
  static DatabaseOptimizer get instance => _instance ??= DatabaseOptimizer._();

  DatabaseOptimizer._();

  // Query cache
  final Map<String, Timer> _cacheTimers = {};

  // Connection pool
  int _activeConnections = 0;
  final int _maxConnections = 10;

  // Write buffer for batch operations
  final Map<String, List<Map<String, dynamic>>> _writeBuffers = {};
  Timer? _flushTimer;

  static const Duration cacheDefaultTtl = Duration(minutes: 10);
  static const Duration flushInterval = Duration(seconds: 5);
  static const int batchSize = 100;

  /// Initialize database optimizations
  void initialize() {
    _startFlushTimer();
    print('💾 Database optimizer initialized');
  }

  /// Start periodic flush timer
  void _startFlushTimer() {
    _flushTimer = Timer.periodic(flushInterval, (_) {
      _flushWriteBuffers();
    });
  }

  /// Optimized database query with caching
  Future<T> optimizedQuery<T>({
    required String query,
    required Future<T> Function() dbQuery,
    Duration cacheTtl = cacheDefaultTtl,
    bool useCache = true,
    String? cacheKey,
    List<dynamic> params = const [],
  }) async {
    final key = cacheKey ?? _generateCacheKey(query, params);

    // Check cache first
    if (useCache) {
      final cache = PerformanceCacheManager.instance.getCache<String, T>(
        'db_query_cache',
        ttl: cacheTtl,
      );

      final cached = cache.get(key);
      if (cached != null) {
        AppConfig.secureLog('✅ DB cache hit: $key');
        return cached;
      }
    }

    // Execute query with connection management
    if (_activeConnections >= _maxConnections) {
      await _waitForConnection();
    }

    _activeConnections++;

    try {
      final result = await dbQuery();

      // Cache successful result
      if (useCache) {
        final cache = PerformanceCacheManager.instance.getCache<String, T>(
          'db_query_cache',
          ttl: cacheTtl,
        );
        cache.put(key, result);

        // Set cache expiry timer
        _setCacheTimer(key, cacheTtl);
      }

      AppConfig.secureLog('✅ DB query executed: $key');
      return result;
    } catch (e) {
      AppConfig.secureLog('❌ DB query failed: $key - $e');
      AppStateManager.instance
          .setError('Database query failed: ${e.toString()}');
      rethrow;
    } finally {
      _activeConnections--;
    }
  }

  /// Generate cache key for query
  String _generateCacheKey(String query, List<dynamic> params) {
    final paramStr = params.isEmpty ? '' : '_${params.join('_')}';
    return '${query.hashCode}$paramStr';
  }

  /// Wait for available connection
  Future<void> _waitForConnection() async {
    while (_activeConnections >= _maxConnections) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  /// Set cache expiry timer
  void _setCacheTimer(String key, Duration ttl) {
    _cacheTimers[key]?.cancel();
    _cacheTimers[key] = Timer(ttl, () {
      final cache = PerformanceCacheManager.instance
          .getCache<String, dynamic>('db_query_cache');
      cache.remove(key);
      _cacheTimers.remove(key);
    });
  }

  /// Buffered write operation
  Future<void> bufferedWrite({
    required String table,
    required Map<String, dynamic> data,
    bool forceFlush = false,
  }) async {
    _writeBuffers.putIfAbsent(table, () => []).add(data);

    if (forceFlush || _writeBuffers[table]!.length >= batchSize) {
      await _flushTable(table);
    }
  }

  /// Flush write buffers
  void _flushWriteBuffers() {
    for (final table in _writeBuffers.keys.toList()) {
      if (_writeBuffers[table]?.isNotEmpty == true) {
        _flushTable(table);
      }
    }
  }

  /// Flush specific table buffer
  Future<void> _flushTable(String table) async {
    final buffer = _writeBuffers[table];
    if (buffer == null || buffer.isEmpty) return;

    try {
      // Create a copy and clear buffer immediately
      final dataToFlush = List<Map<String, dynamic>>.from(buffer);
      buffer.clear();

      AppConfig.secureLog(
          '💾 Flushing ${dataToFlush.length} records to $table');

      // Implement actual batch write logic here
      await _performBatchWrite(table, dataToFlush);

      AppConfig.secureLog('✅ Flushed ${dataToFlush.length} records to $table');
    } catch (e) {
      AppConfig.secureLog('❌ Failed to flush $table: $e');
      AppStateManager.instance
          .setError('Database write failed: ${e.toString()}');
    }
  }

  /// Perform actual batch write operation
  Future<void> _performBatchWrite(
      String table, List<Map<String, dynamic>> data) async {
    // Implement actual database batch write logic here
    // This would use your specific database implementation
    await Future.delayed(const Duration(milliseconds: 10)); // Simulate write
  }

  /// Bulk insert optimization
  Future<void> bulkInsert({
    required String table,
    required List<Map<String, dynamic>> data,
    int chunkSize = 500,
  }) async {
    if (data.isEmpty) return;

    final chunks = <List<Map<String, dynamic>>>[];
    for (int i = 0; i < data.length; i += chunkSize) {
      chunks.add(data.sublist(
          i, i + chunkSize > data.length ? data.length : i + chunkSize));
    }

    for (int i = 0; i < chunks.length; i++) {
      try {
        await _performBatchWrite(table, chunks[i]);
        AppConfig.secureLog(
            '✅ Bulk insert chunk ${i + 1}/${chunks.length} completed');
      } catch (e) {
        AppConfig.secureLog('❌ Bulk insert chunk ${i + 1} failed: $e');
        throw Exception('Bulk insert failed at chunk ${i + 1}: $e');
      }
    }
  }

  /// Clear query cache
  void clearQueryCache([String? pattern]) {
    final cache = PerformanceCacheManager.instance
        .getCache<String, dynamic>('db_query_cache');

    if (pattern == null) {
      cache.clear();
      AppConfig.secureLog('🧹 All DB cache cleared');
    } else {
      // Clear specific pattern - implement pattern matching if needed
      cache.clear(); // Simplified for now
      AppConfig.secureLog('🧹 DB cache cleared for pattern: $pattern');
    }

    // Cancel all cache timers
    for (final timer in _cacheTimers.values) {
      timer.cancel();
    }
    _cacheTimers.clear();
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    final cache = PerformanceCacheManager.instance
        .getCache<String, dynamic>('db_query_cache');
    return {
      'cacheSize': cache.length,
      'activeConnections': _activeConnections,
      'maxConnections': _maxConnections,
      'bufferedWrites': _writeBuffers.values
          .fold<int>(0, (sum, buffer) => sum + buffer.length),
      'activeTimers': _cacheTimers.length,
    };
  }

  /// Dispose database optimizer
  void dispose() {
    _flushTimer?.cancel();
    _flushWriteBuffers(); // Final flush

    for (final timer in _cacheTimers.values) {
      timer.cancel();
    }

    _cacheTimers.clear();
    _writeBuffers.clear();
    _activeConnections = 0;

    print('💾 Database optimizer disposed');
  }
}

/// Database index optimizer
class IndexOptimizer {
  static IndexOptimizer? _instance;
  static IndexOptimizer get instance => _instance ??= IndexOptimizer._();

  IndexOptimizer._();

  // Query pattern analysis
  final Map<String, int> _queryPatterns = {};
  final Map<String, List<String>> _suggestedIndexes = {};

  /// Analyze query patterns for index suggestions
  void analyzeQuery(String query, List<String> columns) {
    final pattern = _extractPattern(query);
    _queryPatterns[pattern] = (_queryPatterns[pattern] ?? 0) + 1;

    // Suggest indexes for frequently used patterns
    if (_queryPatterns[pattern]! > 10) {
      _suggestedIndexes[pattern] = columns;
      AppConfig.secureLog(
          '💡 Index suggested for pattern: $pattern on columns: ${columns.join(', ')}');
    }
  }

  /// Extract query pattern
  String _extractPattern(String query) {
    // Simplified pattern extraction
    return query
        .replaceAll(RegExp(r'\b\d+\b'), '?')
        .replaceAll(RegExp(r"'[^']*'"), '?');
  }

  /// Get index suggestions
  Map<String, List<String>> getIndexSuggestions() {
    return Map.from(_suggestedIndexes);
  }

  /// Clear analysis data
  void clearAnalysis() {
    _queryPatterns.clear();
    _suggestedIndexes.clear();
  }
}
