// ignore_for_file: public_member_api_docs, directives_ordering

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/models/word.dart';
import 'package:flutter_saas_template/core/services/error_recovery_service.dart';
import 'package:flutter_saas_template/core/services/performance_monitor.dart';

/// Cached vocabulary data with metadata
class CachedVocabulary {
  const CachedVocabulary({
    required this.words,
    required this.loadTime,
    required this.cacheKey,
  });

  final List<Word> words;
  final DateTime loadTime;
  final String cacheKey;

  bool get isStale {
    const maxAge = Duration(hours: 1); // Cache for 1 hour
    return DateTime.now().difference(loadTime) > maxAge;
  }
}

/// High-performance vocabulary cache service with lazy loading
class VocabularyCacheService {
  VocabularyCacheService._();
  static final VocabularyCacheService _instance = VocabularyCacheService._();
  static VocabularyCacheService get instance => _instance;

  // LRU cache with maximum size to prevent memory issues
  final Map<String, CachedVocabulary> _cache = {};
  final List<String> _accessOrder = []; // For LRU eviction
  static const int _maxCacheSize = 10; // Max vocabulary sets in memory

  // Preloading queue for background loading
  final Set<String> _preloadQueue = {};
  bool _isPreloading = false;

  /// Generate cache key for vocabulary set
  String _generateCacheKey(
    AppLanguage language,
    VocabularyLevel level,
    String setName,
  ) {
    return '${language.name}_${level.code}_$setName';
  }

  /// Load vocabulary with smart caching and error recovery
  Future<List<Word>> loadVocabulary({
    required AppLanguage language,
    required VocabularyLevel level,
    required String setName,
    bool preload = false,
  }) async {
    final stopwatch = Stopwatch()..start();
    final cacheKey = _generateCacheKey(language, level, setName);

    try {
      // Check cache first
      final cached = _getCached(cacheKey);
      if (cached != null && !cached.isStale) {
        PerformanceMonitor.instance.recordCacheHit();
        _updateAccessOrder(cacheKey);
        stopwatch.stop();
        PerformanceMonitor.instance.recordLoadTime(stopwatch.elapsed);
        return cached.words;
      }

      PerformanceMonitor.instance.recordCacheMiss();

      // Load from assets with smart fallback handling
      List<Word> words;
      try {
        words = await _loadFromAssets(language, level, setName);
      } catch (e) {
        // Only use error recovery for genuine unexpected errors
        words =
            await ErrorRecoveryService.instance.handleError<List<Word>>(
              ErrorType.vocabularyLoadFailure,
              'Failed to load vocabulary: ${language.name} ${level.code} $setName',
              e,
              context: {
                'language': language.name,
                'level': level.code,
                'setName': setName,
                'cacheKey': cacheKey,
              },
              retryFunction: () => _loadFromAssets(language, level, setName),
              fallbackFunction: () =>
                  _getFallbackVocabulary(language, level, setName),
            ) ??
            [];
      }

      _cacheVocabulary(cacheKey, words);

      // Start preloading related sets in background
      if (!preload && words.isNotEmpty) {
        _schedulePreloading(language, level);
      }

      stopwatch.stop();
      PerformanceMonitor.instance.recordLoadTime(stopwatch.elapsed);
      return words;
    } catch (e) {
      stopwatch.stop();
      PerformanceMonitor.instance.recordLoadTime(stopwatch.elapsed);

      // Ultimate fallback using error recovery service
      return ErrorRecoveryService.instance.recoverVocabularyLoad(
        language: language,
        level: level,
        setName: setName,
        originalError: e,
      );
    }
  }

  /// Load vocabulary from assets
  Future<List<Word>> _loadFromAssets(
    AppLanguage language,
    VocabularyLevel level,
    String setName,
  ) async {
    String assetPath;

    // Handle legacy grade8_set1 format
    if (setName == 'grade8_set1') {
      // Try language root path first (for grade8_set1.json files)
      assetPath = 'assets/vocab/${language.name}/$setName.json';

      try {
        final jsonStr = await rootBundle.loadString(assetPath);
        return Word.listFromJsonString(jsonStr);
      } catch (e) {
        // Handle level-specific fallbacks for grade8_set1
        switch (level) {
          case VocabularyLevel.beginner:
            // Use set1_essentials for beginner
            assetPath =
                'assets/vocab/${language.name}/${level.code}/set1_essentials.json';
            try {
              final jsonStr = await rootBundle.loadString(assetPath);
              return Word.listFromJsonString(jsonStr);
            } catch (e2) {
              // If level-specific file doesn't exist, return empty list
              return [];
            }
          case VocabularyLevel.intermediate:
          case VocabularyLevel.advanced:
            // These levels don't have content yet, return empty list instead of failing
            return [];
        }
      }
    }

    // Handle modern leveled vocabulary sets
    // First try: assume setName is already a filename (with or without .json)
    final fileName = setName.endsWith('.json') ? setName : '$setName.json';
    assetPath = 'assets/vocab/${language.name}/${level.code}/$fileName';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      return Word.listFromJsonString(jsonStr);
    } catch (e) {
      // Second try: legacy root path
      assetPath = 'assets/vocab/${language.name}/$fileName';
      try {
        final jsonStr = await rootBundle.loadString(assetPath);
        return Word.listFromJsonString(jsonStr);
      } catch (e2) {
        rethrow;
      }
    }
  }

  /// Get cached vocabulary if available and not stale
  CachedVocabulary? _getCached(String cacheKey) {
    final cached = _cache[cacheKey];
    if (cached != null && cached.isStale) {
      _evictFromCache(cacheKey);
      return null;
    }
    return cached;
  }

  /// Cache vocabulary with LRU eviction
  void _cacheVocabulary(String cacheKey, List<Word> words) {
    // Evict oldest entries if cache is full
    while (_cache.length >= _maxCacheSize) {
      final oldestKey = _accessOrder.first;
      _evictFromCache(oldestKey);
    }

    _cache[cacheKey] = CachedVocabulary(
      words: words,
      loadTime: DateTime.now(),
      cacheKey: cacheKey,
    );
    _updateAccessOrder(cacheKey);
  }

  /// Update access order for LRU
  void _updateAccessOrder(String cacheKey) {
    _accessOrder.remove(cacheKey);
    _accessOrder.add(cacheKey);
  }

  /// Evict entry from cache
  void _evictFromCache(String cacheKey) {
    _cache.remove(cacheKey);
    _accessOrder.remove(cacheKey);
  }

  /// Schedule background preloading of related vocabulary sets
  void _schedulePreloading(AppLanguage language, VocabularyLevel level) {
    if (_isPreloading) return;

    // Preload adjacent difficulty levels
    const levels = VocabularyLevel.values;
    final currentIndex = levels.indexOf(level);

    // Add adjacent levels to preload queue
    if (currentIndex > 0) {
      final lowerLevel = levels[currentIndex - 1];
      _preloadQueue.add(_generateCacheKey(language, lowerLevel, 'grade8_set1'));
    }
    if (currentIndex < levels.length - 1) {
      final higherLevel = levels[currentIndex + 1];
      _preloadQueue.add(
        _generateCacheKey(language, higherLevel, 'grade8_set1'),
      );
    }

    _startPreloading();
  }

  /// Start background preloading
  Future<void> _startPreloading() async {
    if (_isPreloading || _preloadQueue.isEmpty) return;

    _isPreloading = true;

    while (_preloadQueue.isNotEmpty) {
      final cacheKey = _preloadQueue.first;
      _preloadQueue.remove(cacheKey);

      // Parse cache key to extract parameters
      final parts = cacheKey.split('_');
      if (parts.length >= 3) {
        final language = AppLanguage.values.firstWhere(
          (l) => l.name == parts[0],
          orElse: () => AppLanguage.latin,
        );
        final level = VocabularyLevel.values.firstWhere(
          (l) => l.code == parts[1],
          orElse: () => VocabularyLevel.beginner,
        );
        final setName = parts.sublist(2).join('_');

        try {
          await loadVocabulary(
            language: language,
            level: level,
            setName: setName,
            preload: true,
          );
        } catch (e) {
          // Ignore preload failures
        }
      }

      // Small delay to prevent blocking UI
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    _isPreloading = false;
  }

  /// Get fallback vocabulary when primary loading fails
  List<Word> _getFallbackVocabulary(
    AppLanguage language,
    VocabularyLevel level,
    String setName,
  ) {
    // Try to get from cache first (even if stale)
    final cacheKey = _generateCacheKey(language, level, setName);
    final staleCache = _cache[cacheKey];
    if (staleCache != null) {
      return staleCache.words;
    }

    // Return minimal emergency vocabulary
    switch (language) {
      case AppLanguage.latin:
        return [
          Word(
            id: 'fallback_latin_1',
            latin: 'sum',
            english: 'I am',
            pos: 'verb',
            exampleLatin: 'Sum discipulus.',
            exampleEnglish: 'I am a student.',
            tags: ['fallback', level.code],
          ),
          Word(
            id: 'fallback_latin_2',
            latin: 'est',
            english: 'is/he is/she is',
            pos: 'verb',
            exampleLatin: 'Marcus est discipulus.',
            exampleEnglish: 'Marcus is a student.',
            tags: ['fallback', level.code],
          ),
        ];

      case AppLanguage.spanish:
        return [
          Word(
            id: 'fallback_spanish_1',
            latin: 'soy', // Reusing latin field for consistency
            english: 'I am',
            pos: 'verb',
            exampleLatin: 'Soy estudiante.',
            exampleEnglish: 'I am a student.',
            tags: ['fallback', level.code],
          ),
          Word(
            id: 'fallback_spanish_2',
            latin: 'es',
            english: 'is/he is/she is',
            pos: 'verb',
            exampleLatin: 'María es estudiante.',
            exampleEnglish: 'María is a student.',
            tags: ['fallback', level.code],
          ),
        ];
    }
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_sets': _cache.length,
      'max_cache_size': _maxCacheSize,
      'preload_queue_size': _preloadQueue.length,
      'is_preloading': _isPreloading,
      'cache_keys': _cache.keys.toList(),
    };
  }

  /// Clear all cached data (useful for testing or memory pressure)
  void clearCache() {
    _cache.clear();
    _accessOrder.clear();
    _preloadQueue.clear();
    _isPreloading = false;
  }

  /// Warm up cache with commonly used vocabulary sets
  Future<void> warmUpCache(List<AppLanguage> activeLanguages) async {
    for (final language in activeLanguages) {
      try {
        await loadVocabulary(
          language: language,
          level: VocabularyLevel.beginner,
          setName: 'grade8_set1',
          preload: true,
        );
      } catch (e) {
        // Ignore warmup failures
      }
    }
  }
}

/// Provider for the vocabulary cache service
final vocabularyCacheServiceProvider = Provider<VocabularyCacheService>((ref) {
  return VocabularyCacheService.instance;
});

/// Provider for loading vocabulary with caching
final cachedVocabularyProvider =
    FutureProvider.family<List<Word>, VocabularyRequest>((ref, request) async {
      final cacheService = ref.watch(vocabularyCacheServiceProvider);
      return cacheService.loadVocabulary(
        language: request.language,
        level: request.level,
        setName: request.setName,
      );
    });

/// Request parameters for vocabulary loading
@immutable
class VocabularyRequest {
  const VocabularyRequest({
    required this.language,
    required this.level,
    required this.setName,
  });

  final AppLanguage language;
  final VocabularyLevel level;
  final String setName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyRequest &&
          runtimeType == other.runtimeType &&
          language == other.language &&
          level == other.level &&
          setName == other.setName;

  @override
  int get hashCode => Object.hash(language, level, setName);

  @override
  String toString() => 'VocabularyRequest($language, $level, $setName)';
}
