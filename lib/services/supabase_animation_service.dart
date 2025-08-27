import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '/services/error_service.dart';

// Data classes for animation handling
class AnimationMetadata {
  final String word;
  final int duration;
  final String category;

  AnimationMetadata({
    required this.word,
    required this.duration,
    required this.category,
  });
}

class AnimationData {
  final String? url;
  final AnimationMetadata metadata;

  AnimationData({required this.url, required this.metadata});
}

class SupabaseAnimationService {
  static final _client = Supabase.instance.client;
  static const String BUCKET_NAME = 'animations';

  // Enhanced caching system for ultra-fast performance
  static final Map<String, String> _urlCache = {};
  static final Map<String, AnimationMetadata> _metadataCache = {};
  static final Set<String> _preloadedWords = {};
  static final Map<String, AnimationData> _fullAnimationCache =
      {}; // New: Full animation data cache

  // Single fallback duration - no hardcoded words
  static const int DEFAULT_DURATION = 3500;

  // Dynamic core vocabulary size (will be determined by database)
  static const int CORE_VOCABULARY_LIMIT = 50;

  // Get single animation with metadata for smooth playback
  static Future<AnimationData?> getAnimationWithMetadata(String word) async {
    _dbg('fetch "$word"');

    try {
      // Check cache first for instant response
      if (_urlCache.containsKey(word) && _metadataCache.containsKey(word)) {
        _dbg('cache_hit "$word"');
        return AnimationData(
          url: _urlCache[word]!,
          metadata: _metadataCache[word]!,
        );
      }
      _dbg('cache_miss "$word"');

      // Query database for file path and metadata
      final response = await _client
          .from('animations')
          .select('word, file_path, duration_ms, category')
          .eq('word', word.toLowerCase())
          .single();

      if (response['file_path'] != null) {
        // Get public URL from storage - fix double path issue
        String filePath = response['file_path'];

        // Remove any duplicate bucket name from path
        if (filePath.startsWith('animations/')) {
          filePath = filePath.substring('animations/'.length);
        }

        final url = _client.storage.from(BUCKET_NAME).getPublicUrl(filePath);

        final metadata = AnimationMetadata(
          word: response['word'],
          duration: response['duration_ms'] ?? DEFAULT_DURATION,
          category: response['category'] ?? 'general',
        );

        // Cache both URL and metadata
        _urlCache[word] = url;
        _metadataCache[word] = metadata;

        // Update usage count (fire and forget)
        _updateUsageCount(word);

        return AnimationData(url: url, metadata: metadata);
      } else {
        _dbg('no_file "$word"');
      }
    } catch (e, st) {
      ErrorService.reportError(e, st);
      // Return fallback with default duration
      return AnimationData(
        url: null,
        metadata: AnimationMetadata(
          word: word,
          duration: DEFAULT_DURATION,
          category: 'unknown',
        ),
      );
    }
    _dbg('null_result "$word"');
    return null;
  }

  static Future<String?> getAnimationUrl(String word) async {
    final animationData = await getAnimationWithMetadata(word);
    return animationData?.url;
  }

  // Enhanced batch processing for sentence-level optimization
  static Future<List<AnimationData>> getBatchAnimationsWithMetadata(
    List<String> words,
  ) async {
    _dbg('batch_start n=${words.length}');

    final results = <AnimationData>[];
    final uncachedWords = <String>[];

    // First pass: collect cached animations for instant response
    for (final word in words) {
      if (_fullAnimationCache.containsKey(word)) {
        results.add(_fullAnimationCache[word]!);
        _dbg('ultra_cache_hit "$word"');
      } else if (_urlCache.containsKey(word) &&
          _metadataCache.containsKey(word)) {
        final cachedAnimation = AnimationData(
          url: _urlCache[word]!,
          metadata: _metadataCache[word]!,
        );
        _fullAnimationCache[word] =
            cachedAnimation; // Cache for ultra-fast next access
        results.add(cachedAnimation);
        _dbg('batch_cache_hit "$word"');
      } else {
        // Placeholder for uncached words
        results.add(
          AnimationData(
            url: null,
            metadata: AnimationMetadata(
              word: word,
              duration: DEFAULT_DURATION,
              category: 'pending',
            ),
          ),
        );
        uncachedWords.add(word);
      }
    }

    _dbg(
      'batch_summary cached=${words.length - uncachedWords.length} fetch=${uncachedWords.length}',
    );

    // Second pass: fetch uncached words in batch
    if (uncachedWords.isNotEmpty) {
      try {
        _dbg('batch_api_fetch n=${uncachedWords.length}');

        final response = await _client
            .from('animations')
            .select('word, file_path, duration_ms, category')
            .inFilter(
              'word',
              uncachedWords.map((w) => w.toLowerCase()).toList(),
            );

        _dbg('batch_response n=${response.length}');

        final fetchedData = <String, AnimationData>{};

        for (final row in response) {
          final word = row['word'];
          final filePath = row['file_path'];

          final url = _client.storage.from(BUCKET_NAME).getPublicUrl(filePath);

          final metadata = AnimationMetadata(
            word: word,
            duration: row['duration_ms'] ?? DEFAULT_DURATION,
            category: row['category'] ?? 'general',
          );

          // Cache the results
          _urlCache[word] = url;
          _metadataCache[word] = metadata;

          fetchedData[word] = AnimationData(url: url, metadata: metadata);
        }

        _dbg('batch_cached n=${fetchedData.length}');

        // Update results with fetched data
        for (int i = 0; i < words.length; i++) {
          final word = words[i].toLowerCase();
          if (fetchedData.containsKey(word)) {
            results[i] = fetchedData[word]!;
            _dbg('batch_update "$word"');
          } else {
            _dbg('batch_missing "$word"');
          }
        }
      } catch (e, st) {
        ErrorService.reportError(e, st);
      }
    }
    _dbg('batch_complete n=${results.length}');
    return results;
  }

  // Legacy method for backward compatibility
  static Future<Map<String, String>> getBatchAnimations(
    List<String> words,
  ) async {
    final animationsData = await getBatchAnimationsWithMetadata(words);
    final Map<String, String> urls = {};

    for (int i = 0; i < words.length; i++) {
      if (i < animationsData.length && animationsData[i].url != null) {
        urls[words[i].toLowerCase()] = animationsData[i].url!;
      }
    }

    return urls;
  }

  // Preload core vocabulary for instant access - fully dynamic from database
  static Future<void> preloadCoreVocabulary() async {
    try {
      // Get most popular words from database dynamically
      final response = await _client
          .from('animations')
          .select('word')
          .order('usage_count', ascending: false)
          .limit(CORE_VOCABULARY_LIMIT);

      final coreWords = response
          .map<String>((row) => row['word'] as String)
          .toList();

      if (coreWords.isNotEmpty) {
        await getBatchAnimationsWithMetadata(coreWords);
        _preloadedWords.addAll(coreWords);
        _dbg('preloaded_core n=${coreWords.length}');
      } else {
        // Fallback: if no usage data, get any available words
        final fallbackResponse = await _client
            .from('animations')
            .select('word')
            .limit(20);

        final fallbackWords = fallbackResponse
            .map<String>((row) => row['word'] as String)
            .toList();

        if (fallbackWords.isNotEmpty) {
          await getBatchAnimationsWithMetadata(fallbackWords);
          _preloadedWords.addAll(fallbackWords);
          _dbg('preloaded_fallback n=${fallbackWords.length}');
        }
      }
    } catch (e, st) {
      ErrorService.reportError(e, st);
    }
  }

  // Smart preloading based on current word context - fully dynamic from database
  static Future<void> preloadRelatedWords(String currentWord) async {
    try {
      // Get words from same category as current word
      final categoryResponse = await _client
          .from('animations')
          .select('category')
          .eq('word', currentWord.toLowerCase())
          .maybeSingle();

      if (categoryResponse != null && categoryResponse['category'] != null) {
        final category = categoryResponse['category'];

        // Get other words from same category
        final relatedResponse = await _client
            .from('animations')
            .select('word')
            .eq('category', category)
            .neq('word', currentWord.toLowerCase())
            .limit(5);

        final relatedWords = relatedResponse
            .map<String>((row) => row['word'] as String)
            .toList();

        if (relatedWords.isNotEmpty) {
          // Preload in background without blocking current operation
          getBatchAnimationsWithMetadata(relatedWords);
          _dbg('preloaded_related n=${relatedWords.length} cat=$category');
        }
      }
    } catch (e) {
      // Ignore preload errors - not critical
    }
  }

  static Future<void> _updateUsageCount(String word) async {
    try {
      await _client.rpc('increment_usage', params: {'word_param': word});
    } catch (e) {
      // Ignore analytics errors
    }
  }

  // Get popular words for preloading - enhanced with dynamic limits
  static Future<List<String>> getPopularWords({int limit = 20}) async {
    try {
      final response = await _client
          .from('animations')
          .select('word')
          .order('usage_count', ascending: false)
          .limit(limit);

      return response.map<String>((row) => row['word'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  // Get available words by category - for dynamic expansion
  static Future<List<String>> getWordsByCategory(
    String category, {
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('animations')
          .select('word')
          .eq('category', category)
          .order('usage_count', ascending: false)
          .limit(limit);

      return response.map<String>((row) => row['word'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  // Get all available categories - for dynamic discovery
  static Future<List<String>> getAvailableCategories() async {
    try {
      final response = await _client
          .from('animations')
          .select('category')
          .not('category', 'is', null);

      final categories = response
          .map<String>((row) => row['category'] as String)
          .toSet() // Remove duplicates
          .toList();

      return categories;
    } catch (e) {
      return [];
    }
  }

  // Search words by partial match - for dynamic word discovery
  static Future<List<String>> searchWords(
    String query, {
    int limit = 10,
  }) async {
    try {
      final response = await _client
          .from('animations')
          .select('word')
          .ilike('word', '%$query%')
          .order('usage_count', ascending: false)
          .limit(limit);

      return response.map<String>((row) => row['word'] as String).toList();
    } catch (e) {
      return [];
    }
  }

  // Get total word count - for progress tracking
  static Future<int> getTotalWordCount() async {
    try {
      final response = await _client.from('animations').select('word').count();

      return response.count;
    } catch (e) {
      return 0;
    }
  }

  // Clear cache - for testing and memory management
  static void clearCache() {
    _urlCache.clear();
    _metadataCache.clear();
    _preloadedWords.clear();
    _fullAnimationCache.clear(); // Clear full animation cache too
    _dbg('cache_cleared');
  }

  /// Ultra-fast batch preloading for seamless animation sequences
  static Future<void> ultraPreloadAnimations(List<String> words) async {
    try {
      _dbg('ultra_preload_start n=${words.length}');

      final uncachedWords = words
          .where((word) => !_fullAnimationCache.containsKey(word))
          .toList();

      if (uncachedWords.isNotEmpty) {
        // Batch fetch uncached animations
        final response = await _client
            .from('animations')
            .select('word, file_path, duration_ms, category')
            .inFilter(
              'word',
              uncachedWords.map((w) => w.toLowerCase()).toList(),
            );

        for (final row in response) {
          final word = row['word'];
          if (row['file_path'] != null) {
            String filePath = row['file_path'];
            if (filePath.startsWith('animations/')) {
              filePath = filePath.substring('animations/'.length);
            }

            final url = _client.storage
                .from(BUCKET_NAME)
                .getPublicUrl(filePath);
            final metadata = AnimationMetadata(
              word: row['word'],
              duration: row['duration_ms'] ?? DEFAULT_DURATION,
              category: row['category'] ?? 'general',
            );

            // Cache everything for ultra-fast access
            _urlCache[word] = url;
            _metadataCache[word] = metadata;
            _fullAnimationCache[word] = AnimationData(
              url: url,
              metadata: metadata,
            );

            _dbg('cached "$word" dur=${metadata.duration}');
          }
        }
      }

      _dbg('ultra_preload_done n=${words.length}');
    } catch (e, st) {
      ErrorService.reportError(e, st);
    }
  }
}

void _dbg(String msg) {
  if (kDebugMode) {
    // Use lightweight breadcrumb logging in debug only
    ErrorService.log('[anim] $msg');
  }
}
