import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// High-performance LRU cache with automatic cleanup and memory management
class PerformanceCacheManager {
  static PerformanceCacheManager? _instance;
  static PerformanceCacheManager get instance =>
      _instance ??= PerformanceCacheManager._();

  PerformanceCacheManager._();

  // Multiple cache layers for different data types
  final Map<String, LRUCache> _caches = {};
  Timer? _cleanupTimer;

  static const int DEFAULT_MAX_SIZE = 100;
  static const Duration CLEANUP_INTERVAL = Duration(minutes: 5);
  static const Duration DEFAULT_TTL = Duration(hours: 1);

  /// Initialize the cache manager with automatic cleanup
  void initialize() {
    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(CLEANUP_INTERVAL, (_) => _performCleanup());
    print('🚀 PerformanceCacheManager initialized with automatic cleanup');
  }

  /// Get or create a cache for specific data type
  LRUCache<K, V> getCache<K, V>(
    String cacheKey, {
    int maxSize = DEFAULT_MAX_SIZE,
    Duration ttl = DEFAULT_TTL,
  }) {
    if (!_caches.containsKey(cacheKey)) {
      _caches[cacheKey] = LRUCache<K, V>(
        maxSize: maxSize,
        ttl: ttl,
        onEvict: (key, value) {
          if (kDebugMode) {
            print('🗑️ Cache evicted: $cacheKey -> $key');
          }
        },
      );
    }
    return _caches[cacheKey] as LRUCache<K, V>;
  }

  /// Clear all caches
  void clearAll() {
    for (final cache in _caches.values) {
      cache.clear();
    }
    print('🧹 All caches cleared');
  }

  /// Clear specific cache
  void clearCache(String cacheKey) {
    _caches[cacheKey]?.clear();
    print('🧹 Cache cleared: $cacheKey');
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    final stats = <String, dynamic>{};
    for (final entry in _caches.entries) {
      stats[entry.key] = {
        'size': entry.value.length,
        'maxSize': entry.value.maxSize,
        'hitRate': entry.value.hitRate,
      };
    }
    return stats;
  }

  /// Perform automatic cleanup
  void _performCleanup() {
    int totalCleaned = 0;
    for (final cache in _caches.values) {
      totalCleaned += cache.cleanup();
    }
    if (totalCleaned > 0) {
      print('🧹 Automatic cleanup removed $totalCleaned expired items');
    }
  }

  /// Dispose the cache manager
  void dispose() {
    _cleanupTimer?.cancel();
    clearAll();
    _caches.clear();
    _instance = null;
    print('♻️ PerformanceCacheManager disposed');
  }
}

/// High-performance LRU cache with TTL support
class LRUCache<K, V> {
  final int maxSize;
  final Duration ttl;
  final void Function(K key, V value)? onEvict;

  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();
  int _hits = 0;
  int _misses = 0;

  LRUCache({
    required this.maxSize,
    this.ttl = const Duration(hours: 1),
    this.onEvict,
  });

  /// Get value from cache
  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) {
      _misses++;
      return null;
    }

    // Check if expired
    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      onEvict?.call(key, entry.value);
      _misses++;
      return null;
    }

    // Move to end (most recently used)
    _cache.remove(key);
    _cache[key] = entry;
    _hits++;
    return entry.value;
  }

  /// Put value in cache
  void put(K key, V value) {
    // Remove if already exists
    _cache.remove(key);

    // Add new entry
    _cache[key] = _CacheEntry(
      value: value,
      expiry: DateTime.now().add(ttl),
    );

    // Evict oldest if over capacity
    while (_cache.length > maxSize) {
      final oldest = _cache.keys.first;
      final oldValue = _cache.remove(oldest);
      if (oldValue != null) {
        onEvict?.call(oldest, oldValue.value);
      }
    }
  }

  /// Check if key exists and is not expired
  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) return false;

    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      onEvict?.call(key, entry.value);
      return false;
    }

    return true;
  }

  /// Remove specific key
  V? remove(K key) {
    final entry = _cache.remove(key);
    if (entry != null) {
      onEvict?.call(key, entry.value);
      return entry.value;
    }
    return null;
  }

  /// Clear all entries
  void clear() {
    for (final entry in _cache.entries) {
      onEvict?.call(entry.key, entry.value.value);
    }
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  /// Cleanup expired entries
  int cleanup() {
    final now = DateTime.now();
    final toRemove = <K>[];

    for (final entry in _cache.entries) {
      if (now.isAfter(entry.value.expiry)) {
        toRemove.add(entry.key);
      }
    }

    for (final key in toRemove) {
      final entry = _cache.remove(key);
      if (entry != null) {
        onEvict?.call(key, entry.value);
      }
    }

    return toRemove.length;
  }

  /// Get cache statistics
  int get length => _cache.length;
  double get hitRate => (_hits + _misses) > 0 ? _hits / (_hits + _misses) : 0.0;
  bool get isEmpty => _cache.isEmpty;
  bool get isNotEmpty => _cache.isNotEmpty;
}

/// Cache entry with expiry time
class _CacheEntry<V> {
  final V value;
  final DateTime expiry;

  _CacheEntry({
    required this.value,
    required this.expiry,
  });
}
