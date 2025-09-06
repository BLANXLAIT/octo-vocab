import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/services/vocabulary_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VocabularyCacheService Tests', () {
    test('CachedVocabulary tracks staleness correctly', () {
      final now = DateTime.now();
      final fresh = CachedVocabulary(
        words: [],
        loadTime: now,
        cacheKey: 'test_key',
      );

      final stale = CachedVocabulary(
        words: [],
        loadTime: now.subtract(const Duration(hours: 2)),
        cacheKey: 'test_key',
      );

      expect(fresh.isStale, false);
      expect(stale.isStale, true);
    });

    group('Error Handling', () {
      test('handles missing vocabulary sets gracefully', () async {
        final cacheService = VocabularyCacheService.instance;

        // Try to load a vocabulary set that doesn't exist
        final words = await cacheService.loadVocabulary(
          language: AppLanguage.latin,
          level: VocabularyLevel.advanced,
          setName: 'nonexistent_set_xyz_123',
        );

        // Should return empty list or throw in a controlled way
        expect(words, isA<List<dynamic>>());
      });
    });

    group('Cache Management', () {
      test('provides cache statistics', () {
        final cacheService = VocabularyCacheService.instance;
        final stats = cacheService.getCacheStats();

        expect(stats, isA<Map<String, dynamic>>());
        expect(stats.containsKey('cached_sets'), true);
        expect(stats.containsKey('max_cache_size'), true);
        expect(stats.containsKey('preload_queue_size'), true);
        expect(stats.containsKey('is_preloading'), true);
        expect(stats.containsKey('cache_keys'), true);
      });

      test('clears cache successfully', () {
        final cacheService = VocabularyCacheService.instance;
        cacheService.clearCache();

        final stats = cacheService.getCacheStats();
        expect(stats['cached_sets'], equals(0));
        expect(stats['preload_queue_size'], equals(0));
        expect(stats['is_preloading'], equals(false));
        expect(stats['cache_keys'], isEmpty);
      });
    });
  });
}
