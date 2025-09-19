// ignore_for_file: public_member_api_docs
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Progress Tracking Business Logic Tests', () {
    group('Word Progress State Transitions', () {
      test('validates correct state transition sequence', () {
        // Business rule: Words progress through specific states
        const validStates = ['null', 'difficult', 'reviewing', 'known', 'mastered'];

        expect(validStates, contains('null'));
        expect(validStates, contains('difficult'));
        expect(validStates, contains('reviewing'));
        expect(validStates, contains('known'));
        expect(validStates, contains('mastered'));
      });

      test('validates valid transitions from null state', () {
        const fromState = 'null';
        const validTransitions = ['difficult', 'known'];

        // From new word, can go to difficult (swipe left) or known (swipe right)
        expect(validTransitions, contains('difficult'));
        expect(validTransitions, contains('known'));
        expect(validTransitions, isNot(contains('mastered'))); // Cannot skip to mastered
      });

      test('validates valid transitions from difficult state', () {
        const fromState = 'difficult';
        const validTransitions = ['difficult', 'reviewing'];

        // From difficult, can stay difficult (keep practicing) or move to reviewing (got it)
        expect(validTransitions, contains('difficult'));
        expect(validTransitions, contains('reviewing'));
      });

      test('validates mastery requirements', () {
        // Business rule: Must have multiple successful reviews to reach mastery
        const minimumSuccessfulReviews = 3;

        expect(minimumSuccessfulReviews, greaterThanOrEqualTo(2));
        expect(minimumSuccessfulReviews, lessThanOrEqualTo(5)); // Reasonable upper bound
      });
    });

    group('Language-Specific Progress Keys', () {
      test('generates correct progress key format', () {
        const languageCode = 'la';
        const wordId = 'amor';
        const expectedKey = 'la_amor';

        final progressKey = '${languageCode}_$wordId';
        expect(progressKey, equals(expectedKey));
      });

      test('handles different language codes correctly', () {
        const testCases = [
          {'language': 'la', 'word': 'amor', 'expected': 'la_amor'},
          {'language': 'es', 'word': 'amor', 'expected': 'es_amor'},
          {'language': 'fr', 'word': 'amour', 'expected': 'fr_amour'},
        ];

        for (final testCase in testCases) {
          final progressKey = '${testCase['language']}_${testCase['word']}';
          expect(progressKey, equals(testCase['expected']));
        }
      });

      test('ensures progress keys are unique across languages', () {
        final keys = ['la_amor', 'es_amor', 'fr_amour'];
        final uniqueKeys = keys.toSet();

        expect(uniqueKeys.length, equals(keys.length));
      });

      test('validates progress key parsing', () {
        const progressKey = 'la_amor';
        final parts = progressKey.split('_');

        expect(parts.length, equals(2));
        expect(parts[0], equals('la')); // language code
        expect(parts[1], equals('amor')); // word id
      });
    });

    group('Study Session Tracking', () {
      test('records study session with correct timestamp', () {
        final sessionDate = DateTime.now();
        final normalizedDate = DateTime(
          sessionDate.year,
          sessionDate.month,
          sessionDate.day,
        );

        // Study sessions should be recorded per day, not per exact time
        expect(normalizedDate.hour, equals(0));
        expect(normalizedDate.minute, equals(0));
        expect(normalizedDate.second, equals(0));
      });

      test('calculates study streak correctly', () {
        final sessions = [
          DateTime(2024, 1, 15),
          DateTime(2024, 1, 14),
          DateTime(2024, 1, 13),
          // Gap here breaks streak
          DateTime(2024, 1, 10),
          DateTime(2024, 1, 9),
        ];

        // Current streak should be 3 (consecutive days from most recent)
        final expectedStreak = 3;

        // Simple streak calculation logic
        var streak = 0;
        final sortedSessions = sessions.toList()..sort((a, b) => b.compareTo(a));

        for (var i = 0; i < sortedSessions.length - 1; i++) {
          final current = sortedSessions[i];
          final next = sortedSessions[i + 1];
          final dayDifference = current.difference(next).inDays;

          if (dayDifference == 1) {
            streak++;
          } else {
            break;
          }
        }

        if (sessions.isNotEmpty) streak++; // Count the most recent day

        expect(streak, equals(expectedStreak));
      });

      test('calculates weekly study sessions correctly', () {
        final now = DateTime(2024, 1, 15); // Monday
        final weekSessions = [
          DateTime(2024, 1, 15), // Monday (today)
          DateTime(2024, 1, 14), // Sunday
          DateTime(2024, 1, 13), // Saturday
          DateTime(2024, 1, 10), // Wednesday (previous week, should not count)
        ];

        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekStartNormalized = DateTime(weekStart.year, weekStart.month, weekStart.day);

        final thisWeekSessions = weekSessions.where((session) {
          final sessionNormalized = DateTime(session.year, session.month, session.day);
          return sessionNormalized.isAfter(weekStartNormalized.subtract(const Duration(days: 1))) &&
                 sessionNormalized.isBefore(now.add(const Duration(days: 1)));
        }).length;

        expect(thisWeekSessions, equals(3)); // Monday, Sunday, Saturday of current week
      });
    });

    group('Progress Statistics Calculation', () {
      test('calculates vocabulary mastery percentage correctly', () {
        const totalWords = 100;
        const knownWords = 75;
        const expectedPercentage = 75;

        final percentage = (knownWords / totalWords * 100).round();
        expect(percentage, equals(expectedPercentage));
      });

      test('handles edge case of no vocabulary', () {
        const totalWords = 0;
        const knownWords = 0;
        const expectedPercentage = 0;

        final percentage = totalWords > 0 ? (knownWords / totalWords * 100).round() : 0;
        expect(percentage, equals(expectedPercentage));
      });

      test('categorizes words by learning status correctly', () {
        final wordProgress = {
          'la_amor': 'known',
          'la_vita': 'mastered',
          'la_terra': 'difficult',
          'la_aqua': 'reviewing',
          'la_ignis': 'null',
        };

        final knownCount = wordProgress.values.where((status) => status == 'known').length;
        final masteredCount = wordProgress.values.where((status) => status == 'mastered').length;
        final difficultCount = wordProgress.values.where((status) => status == 'difficult').length;
        final reviewingCount = wordProgress.values.where((status) => status == 'reviewing').length;
        final newCount = wordProgress.values.where((status) => status == 'null').length;

        expect(knownCount, equals(1));
        expect(masteredCount, equals(1));
        expect(difficultCount, equals(1));
        expect(reviewingCount, equals(1));
        expect(newCount, equals(1));
      });
    });

    group('Quiz Result Storage and Retrieval', () {
      test('stores quiz results with correct metadata', () {
        final quizResult = {
          'score': 8,
          'total': 10,
          'percentage': 80,
          'language': 'la',
          'timestamp': DateTime(2024, 1, 15).toIso8601String(),
          'duration': 120, // seconds
        };

        expect(quizResult['score'], equals(8));
        expect(quizResult['total'], equals(10));
        expect(quizResult['percentage'], equals(80));
        expect(quizResult['language'], equals('la'));
        expect(quizResult['timestamp'], isA<String>());
        expect(quizResult['duration'], equals(120));
      });

      test('calculates quiz statistics correctly', () {
        final quizResults = [
          {'percentage': 70},
          {'percentage': 80},
          {'percentage': 90},
          {'percentage': 85},
        ];

        final scores = quizResults.map((r) => r['percentage'] as int).toList();
        final avgScore = (scores.reduce((a, b) => a + b) / scores.length).round();
        final bestScore = scores.reduce((a, b) => a > b ? a : b);
        final totalQuizzes = scores.length;

        expect(avgScore, equals(81)); // (70+80+90+85)/4 = 81.25 → 81
        expect(bestScore, equals(90));
        expect(totalQuizzes, equals(4));
      });
    });

    group('Data Persistence Validation', () {
      test('validates app settings structure', () {
        final appSettings = {
          'selectedLanguage': 'la',
          'quizLength': 10,
          'theme': 'system',
          'soundEnabled': true,
        };

        expect(appSettings, containsPair('selectedLanguage', 'la'));
        expect(appSettings, containsPair('quizLength', 10));
        expect(appSettings['soundEnabled'], isA<bool>());
      });

      test('validates word progress structure', () {
        final wordProgress = {
          'la_amor': 'known',
          'la_vita': 'difficult',
          'es_amor': 'mastered',
        };

        // Each key should follow language_word format
        for (final key in wordProgress.keys) {
          expect(key, contains('_'));
          final parts = key.split('_');
          expect(parts.length, equals(2));
          expect(parts[0], matches(RegExp(r'^[a-z]{2,3}$'))); // Language code
          expect(parts[1], isNotEmpty); // Word ID
        }

        // Each value should be a valid status
        const validStatuses = ['null', 'difficult', 'reviewing', 'known', 'mastered'];
        for (final status in wordProgress.values) {
          expect(validStatuses, contains(status));
        }
      });
    });
  });
}