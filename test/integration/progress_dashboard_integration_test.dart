// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, directives_ordering

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_saas_template/core/services/local_data_service.dart';
import 'package:flutter_saas_template/features/progress/progress_screen.dart';

void main() {
  group('Progress Dashboard Integration Tests', () {
    late LocalDataService dataService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dataService = await LocalDataService.create();
    });

    test('dashboard reflects actual learning progress', () async {
      // Simulate learning session: mark some words as known, some as difficult
      await dataService.markWordAsKnown('aqua');
      await dataService.markWordAsKnown('terra');
      await dataService.markWordAsKnown('ignis');
      await dataService.markWordAsDifficult('aer');
      await dataService.markWordAsDifficult('caelum');

      // Get stats and verify they match expected values
      final stats = dataService.getLearningStats();
      expect(stats['known_count'], equals(3));
      expect(stats['difficult_count'], equals(2));
      expect(stats['total_studied'], equals(5));

      // Test progress data calculations
      final progress = ProgressData(
        totalWords: 100,
        masteredCount: stats['known_count'] ?? 0,
        learningCount: stats['difficult_count'] ?? 0,
        unstudiedCount: 100 - (stats['total_studied'] ?? 0),
        difficultWordIds: dataService.getDifficultWords(),
        knownWordIds: dataService.getKnownWords(),
      );

      // Verify calculations
      expect(progress.masteredCount, equals(3));
      expect(progress.learningCount, equals(2));
      expect(progress.unstudiedCount, equals(95));
      expect(progress.masteryPercentage, equals(3.0));
      expect(progress.studiedPercentage, equals(5.0));
      expect(progress.difficultWordIds.length, equals(2));
      expect(progress.knownWordIds.length, equals(3));
    });

    test(
      'dashboard updates correctly when words move between states',
      () async {
        // Start with a difficult word
        await dataService.markWordAsDifficult('complex_word');

        var stats = dataService.getLearningStats();
        expect(stats['difficult_count'], equals(1));
        expect(stats['known_count'], equals(0));

        // Master the word
        await dataService.markWordAsKnown('complex_word');

        stats = dataService.getLearningStats();
        expect(stats['difficult_count'], equals(0));
        expect(stats['known_count'], equals(1));
        expect(stats['total_studied'], equals(1));

        // Verify word moved from difficult to known
        expect(dataService.isWordDifficult('complex_word'), isFalse);
        expect(dataService.isWordKnown('complex_word'), isTrue);
      },
    );

    test('dashboard handles empty state correctly', () async {
      // No words studied yet
      final stats = dataService.getLearningStats();
      expect(stats['known_count'], equals(0));
      expect(stats['difficult_count'], equals(0));
      expect(stats['total_studied'], equals(0));

      final progress = ProgressData(
        totalWords: 50,
        masteredCount: 0,
        learningCount: 0,
        unstudiedCount: 50,
        difficultWordIds: <String>{},
        knownWordIds: <String>{},
      );

      expect(progress.masteryPercentage, equals(0.0));
      expect(progress.studiedPercentage, equals(0.0));
      expect(progress.unstudiedCount, equals(50));
    });

    test('dashboard calculations remain consistent after data reset', () async {
      // Add some learning data
      await dataService.markWordAsKnown('word1');
      await dataService.markWordAsDifficult('word2');

      var stats = dataService.getLearningStats();
      expect(stats['total_studied'], equals(2));

      // Reset all data
      await dataService.resetAllData();

      // Verify dashboard would show empty state
      stats = dataService.getLearningStats();
      expect(stats['known_count'], equals(0));
      expect(stats['difficult_count'], equals(0));
      expect(stats['total_studied'], equals(0));
      expect(dataService.getDifficultWords().isEmpty, isTrue);
      expect(dataService.getKnownWords().isEmpty, isTrue);
    });
  });
}
