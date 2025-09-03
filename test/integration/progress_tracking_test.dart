// ignore_for_file: directives_ordering

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_saas_template/core/models/word.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';

void main() {
  group('Progress Tracking Integration Tests', () {
    late LocalDataService dataService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dataService = await LocalDataService.create();
    });

    testWidgets('difficulty tracking workflow', (WidgetTester tester) async {
      // Test word for tracking
      final testWord = Word(
        id: 'test_word_1',
        latin: 'aqua',
        english: 'water',
        pos: 'noun',
      );

      // Test marking word as difficult
      await dataService.markWordAsDifficult(testWord.id);
      expect(dataService.isWordDifficult(testWord.id), isTrue);
      expect(dataService.isWordKnown(testWord.id), isFalse);

      // Test learning stats
      final stats = dataService.getLearningStats();
      expect(stats['difficult_count'], equals(1));
      expect(stats['known_count'], equals(0));
      expect(stats['total_studied'], equals(1));

      // Test marking word as known (should remove from difficult)
      await dataService.markWordAsKnown(testWord.id);
      expect(dataService.isWordDifficult(testWord.id), isFalse);
      expect(dataService.isWordKnown(testWord.id), isTrue);

      // Check updated stats
      final updatedStats = dataService.getLearningStats();
      expect(updatedStats['difficult_count'], equals(0));
      expect(updatedStats['known_count'], equals(1));
      expect(updatedStats['total_studied'], equals(1));
    });

    testWidgets('Review screen shows difficult words only', (
      WidgetTester tester,
    ) async {
      // Add some test words to difficult list
      await dataService.markWordAsDifficult('word1');
      await dataService.markWordAsDifficult('word2');
      await dataService.markWordAsKnown(
        'word3',
      ); // This should not appear in review

      final difficultWords = dataService.getDifficultWords();
      expect(difficultWords.length, equals(2));
      expect(difficultWords.contains('word1'), isTrue);
      expect(difficultWords.contains('word2'), isTrue);
      expect(difficultWords.contains('word3'), isFalse);
    });

    testWidgets('Data privacy and reset functionality', (
      WidgetTester tester,
    ) async {
      // Add some test data
      await dataService.markWordAsDifficult('word1');
      await dataService.markWordAsKnown('word2');
      await dataService.setSelectedLanguage('latin');

      // Verify data exists
      expect(dataService.getDifficultWords().isNotEmpty, isTrue);
      expect(dataService.getKnownWords().isNotEmpty, isTrue);
      expect(dataService.getSelectedLanguage(), equals('latin'));

      // Test complete data reset
      final resetResult = await dataService.resetAllData();
      expect(resetResult, isTrue);

      // Verify all data is cleared
      expect(dataService.getDifficultWords().isEmpty, isTrue);
      expect(dataService.getKnownWords().isEmpty, isTrue);
      expect(dataService.getSelectedLanguage(), isNull);

      final stats = dataService.getLearningStats();
      expect(stats['difficult_count'], equals(0));
      expect(stats['known_count'], equals(0));
      expect(stats['total_studied'], equals(0));
    });

    test('Privacy transparency - data export', () async {
      // Add test data
      await dataService.markWordAsDifficult('aqua');
      await dataService.markWordAsKnown('terra');
      await dataService.setSelectedLanguage('latin');

      // Test data export
      final exportData = dataService.exportUserData();
      expect(exportData.contains('Octo Vocab'), isTrue);
      expect(exportData.contains('privacy_note'), isTrue);
      expect(exportData.contains('This data never leaves your device'), isTrue);
      expect(exportData.contains('aqua'), isTrue);
      expect(exportData.contains('terra'), isTrue);
      expect(exportData.contains('latin'), isTrue);

      // Test getAllUserData
      final allData = dataService.getAllUserData();
      expect(allData['difficult_words'], contains('aqua'));
      expect(allData['known_words'], contains('terra'));
      expect(allData['selected_language'], equals('latin'));
      expect(allData['learning_stats'], isA<Map<String, int>>());
    });
  });
}
