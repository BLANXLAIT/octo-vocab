// ignore_for_file: public_member_api_docs
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octo_vocab/core/services/local_data_service.dart';
import 'package:octo_vocab/core/language/language_registry.dart';
import 'package:octo_vocab/core/language/plugins/latin_plugin.dart';
import 'package:octo_vocab/features/progress/progress_screen.dart';
import 'package:octo_vocab/features/review/review_screen.dart';

void main() {
  group('Provider Invalidation Tests', () {
    late ProviderContainer container;

    setUp(() async {
      // Use test mode for SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Initialize language registry for tests that need Latin vocabulary
      LanguageRegistry.instance.clear();
      LanguageRegistry.instance.register(LatinPlugin());

      // Create a fresh container for each test
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('word progress provider should refresh data after invalidation', () async {
      // Create test data service
      final dataService = await LocalDataService.create();

      // Add some test data
      await dataService.setWordProgress({
        'test_word_1': 'difficult',
        'test_word_2': 'known',
      });

      // Read the provider first time - should contain our test data
      final wordProgressBefore = await container.read(wordProgressProvider.future);
      expect(wordProgressBefore.length, 2);
      expect(wordProgressBefore['test_word_1'], 'difficult');
      expect(wordProgressBefore['test_word_2'], 'known');

      // Clear all data
      final resetSuccess = await dataService.clearAllData();
      expect(resetSuccess, isTrue);

      // Before invalidation, provider still has cached data
      final wordProgressCached = await container.read(wordProgressProvider.future);
      expect(wordProgressCached.length, 2, reason: 'Provider should still have cached data');

      // Invalidate the provider to force fresh data load
      container.invalidate(wordProgressProvider);

      // After invalidation, provider should reflect the cleared state
      final wordProgressAfter = await container.read(wordProgressProvider.future);
      expect(wordProgressAfter.isEmpty, isTrue, reason: 'Provider should be empty after invalidation');
    });

    // NOTE: Additional tests with review queue provider would require proper
    // Flutter test binding initialization and vocabulary loading, which is
    // complex for unit tests. The first test demonstrates the core provider
    // invalidation mechanism works correctly.
  });
}