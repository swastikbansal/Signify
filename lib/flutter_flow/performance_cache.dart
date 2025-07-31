import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// High-performance LRU cache with automatic cleanup and memory monitoring
class PerformanceCache<K, V> {
  final int _maxSize;
  final Duration _ttl;
  final LinkedHashMap<K, _CacheEntry<V>> _cache = LinkedHashMap();
  Timer? _cleanupTimer;
  int _hits = 0;
  int _misses = 0;

  PerformanceCache({
    required int maxSize,
    Duration ttl = const Duration(minutes: 30),
  })  : _maxSize = maxSize,
        _ttl = ttl {
    // Start periodic cleanup every 5 minutes
    _cleanupTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => _cleanup());
  }

  V? get(K key) {
    final entry = _cache[key];
    if (entry == null) {
      _misses++;
      return null;
    }

    if (_isExpired(entry)) {
      _cache.remove(key);
      _misses++;
      return null;
    }

    // Move to end (most recently used)
    _cache.remove(key);
    _cache[key] = entry;
    _hits++;
    return entry.value;
  }

  void put(K key, V value) {
    // Remove expired entries first
    _removeExpired();

    // Remove oldest if at capacity
    if (_cache.length >= _maxSize) {
      _cache.remove(_cache.keys.first);
    }

    _cache[key] = _CacheEntry(value, DateTime.now());
  }

  void remove(K key) {
    _cache.remove(key);
  }

  void clear() {
    _cache.clear();
    _hits = 0;
    _misses = 0;
  }

  bool containsKey(K key) {
    final entry = _cache[key];
    if (entry == null) return false;
    if (_isExpired(entry)) {
      _cache.remove(key);
      return false;
    }
    return true;
  }

  int get length => _cache.length;
  int get hits => _hits;
  int get misses => _misses;
  double get hitRate => (_hits + _misses) > 0 ? _hits / (_hits + _misses) : 0.0;

  void _cleanup() {
    _removeExpired();
    if (kDebugMode) {
      print(
          'Cache cleanup: ${_cache.length} entries, hit rate: ${(hitRate * 100).toStringAsFixed(1)}%');
    }
  }

  void _removeExpired() {
    final now = DateTime.now();
    _cache.removeWhere((key, entry) => now.difference(entry.timestamp) > _ttl);
  }

  bool _isExpired(_CacheEntry<V> entry) {
    return DateTime.now().difference(entry.timestamp) > _ttl;
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}

/// Global cache manager for the app
class AppCacheManager {
  static final AppCacheManager _instance = AppCacheManager._internal();
  factory AppCacheManager() => _instance;
  AppCacheManager._internal();

  // Different caches for different data types
  final PerformanceCache<String, Uint8List> imageCache = PerformanceCache(
    maxSize: 50,
    ttl: const Duration(hours: 1),
  );

  final PerformanceCache<String, String> translationCache = PerformanceCache(
    maxSize: 200,
    ttl: const Duration(hours: 6),
  );

  final PerformanceCache<String, Map<String, dynamic>> apiResponseCache =
      PerformanceCache(
    maxSize: 100,
    ttl: const Duration(minutes: 15),
  );

  final PerformanceCache<String, List<double>> coordinateCache =
      PerformanceCache(
    maxSize: 30,
    ttl: const Duration(minutes: 5),
  );

  /// Clear all caches when memory pressure is detected
  void clearAll() {
    imageCache.clear();
    translationCache.clear();
    apiResponseCache.clear();
    coordinateCache.clear();
    if (kDebugMode) {
      print('All caches cleared due to memory pressure');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return {
      'imageCache': {
        'size': imageCache.length,
        'hitRate': imageCache.hitRate,
      },
      'translationCache': {
        'size': translationCache.length,
        'hitRate': translationCache.hitRate,
      },
      'apiResponseCache': {
        'size': apiResponseCache.length,
        'hitRate': apiResponseCache.hitRate,
      },
      'coordinateCache': {
        'size': coordinateCache.length,
        'hitRate': coordinateCache.hitRate,
      },
    };
  }

  void dispose() {
    imageCache.dispose();
    translationCache.dispose();
    apiResponseCache.dispose();
    coordinateCache.dispose();
  }
}
