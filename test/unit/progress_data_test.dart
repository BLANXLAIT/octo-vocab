// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, directives_ordering

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_saas_template/features/progress/progress_screen.dart';

void main() {
  group('ProgressData Tests', () {
    test('calculates mastery percentage correctly', () {
      final progress = ProgressData(
        totalWords: 100,
        masteredCount: 25,
        learningCount: 15,
        unstudiedCount: 60,
        difficultWordIds: {'word1', 'word2'},
        knownWordIds: {'word3', 'word4'},
      );

      expect(progress.masteryPercentage, equals(25.0));
      expect(progress.studiedPercentage, equals(40.0));
    });

    test('handles zero total words gracefully', () {
      final progress = ProgressData(
        totalWords: 0,
        masteredCount: 0,
        learningCount: 0,
        unstudiedCount: 0,
        difficultWordIds: <String>{},
        knownWordIds: <String>{},
      );

      expect(progress.masteryPercentage, equals(0.0));
      expect(progress.studiedPercentage, equals(0.0));
    });

    test('calculates percentages correctly with partial mastery', () {
      final progress = ProgressData(
        totalWords: 200,
        masteredCount: 50,
        learningCount: 30,
        unstudiedCount: 120,
        difficultWordIds: {'difficult1', 'difficult2', 'difficult3'},
        knownWordIds: {'known1', 'known2'},
      );

      expect(progress.masteryPercentage, equals(25.0));
      expect(progress.studiedPercentage, equals(40.0));
    });
  });
}
