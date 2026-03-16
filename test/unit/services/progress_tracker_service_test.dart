import 'package:flutter_test/flutter_test.dart';
import 'package:octo_vocab/core/services/progress_tracker_service.dart';

void main() {
  late ProgressTrackerService service;

  setUp(() {
    service = const ProgressTrackerService();
  });

  group('ProgressTrackerService', () {
    group('calculateStreak', () {
      test('returns 0 for empty session list', () {
        final streak = service.calculateStreak([]);

        expect(streak, 0);
      });

      test('returns 1 for only today', () {
        final today = DateTime.now();
        final todayNormalized = DateTime(today.year, today.month, today.day);

        final streak = service.calculateStreak([todayNormalized]);

        expect(streak, 1);
      });

      test('calculates consecutive days correctly', () {
        final today = DateTime.now();
        final sessions = List.generate(
          5,
          (i) => DateTime(today.year, today.month, today.day - i),
        );

        final streak = service.calculateStreak(sessions);

        expect(streak, 5);
      });

      test('returns 0 when latest session is more than 1 day old', () {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        final sessions = [
          DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day),
        ];

        final streak = service.calculateStreak(sessions);

        expect(streak, 0);
      });

      test('counts yesterday as valid streak', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final sessions = [
          DateTime(yesterday.year, yesterday.month, yesterday.day),
        ];

        final streak = service.calculateStreak(sessions);

        expect(streak, 1);
      });

      test('stops counting at gap in dates', () {
        final today = DateTime.now();
        final sessions = [
          DateTime(today.year, today.month, today.day),
          DateTime(today.year, today.month, today.day - 1),
          DateTime(today.year, today.month, today.day - 2),
          // Gap here
          DateTime(today.year, today.month, today.day - 5),
          DateTime(today.year, today.month, today.day - 6),
        ];

        final streak = service.calculateStreak(sessions);

        expect(streak, 3); // Only counts first 3 consecutive days
      });

      test('handles unsorted sessions', () {
        final today = DateTime.now();
        final sessions = [
          DateTime(today.year, today.month, today.day - 2),
          DateTime(today.year, today.month, today.day),
          DateTime(today.year, today.month, today.day - 1),
        ];

        final streak = service.calculateStreak(sessions);

        expect(streak, 3);
      });
    });

    group('getThisWeekSessionCount', () {
      test('returns 0 for empty sessions', () {
        final count = service.getThisWeekSessionCount([]);

        expect(count, 0);
      });

      test('counts sessions in current week', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final thisWeek = List.generate(
          now.weekday,
          (i) => DateTime(today.year, today.month, today.day - i),
        );

        final count = service.getThisWeekSessionCount(thisWeek);

        expect(count, now.weekday);
      });

      test('excludes sessions from last week', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final lastWeek = DateTime(today.year, today.month, today.day - 8);

        final sessions = [today, lastWeek];
        final count = service.getThisWeekSessionCount(sessions);

        expect(count, 1); // Only today
      });
    });

    group('calculateProgressPercentage', () {
      test('returns 0 when total is 0', () {
        final percentage = service.calculateProgressPercentage(
          completed: 0,
          total: 0,
        );

        expect(percentage, 0);
      });

      test('returns 100 when all completed', () {
        final percentage = service.calculateProgressPercentage(
          completed: 10,
          total: 10,
        );

        expect(percentage, 100);
      });

      test('calculates percentage correctly', () {
        final percentage = service.calculateProgressPercentage(
          completed: 7,
          total: 10,
        );

        expect(percentage, 70);
      });

      test('rounds to nearest integer', () {
        final percentage = service.calculateProgressPercentage(
          completed: 1,
          total: 3,
        );

        expect(percentage, 33); // 33.33... rounds to 33
      });

      test('handles completed > total gracefully', () {
        final percentage = service.calculateProgressPercentage(
          completed: 12,
          total: 10,
        );

        expect(percentage, 100); // Caps at 100
      });
    });

    group('getProgressStats', () {
      test('returns zero stats for empty progress', () {
        final stats = service.getProgressStats({}, totalWords: 100);

        expect(stats.knownWords, 0);
        expect(stats.difficultWords, 0);
        expect(stats.reviewingWords, 0);
        expect(stats.masteredWords, 0);
        expect(stats.unstudiedWords, 100);
      });

      test('categorizes word statuses correctly', () {
        final progress = {
          'word1': 'known',
          'word2': 'known',
          'word3': 'difficult',
          'word4': 'reviewing',
          'word5': 'mastered',
        };

        final stats = service.getProgressStats(progress, totalWords: 10);

        expect(stats.knownWords, 2);
        expect(stats.difficultWords, 1);
        expect(stats.reviewingWords, 1);
        expect(stats.masteredWords, 1);
        expect(stats.unstudiedWords, 5); // 10 - 5
      });

      test('ignores unknown statuses', () {
        final progress = {
          'word1': 'known',
          'word2': 'unknown_status',
          'word3': 'invalid',
        };

        final stats = service.getProgressStats(progress, totalWords: 10);

        expect(stats.knownWords, 1);
        expect(stats.unstudiedWords, 9); // Treats unknown statuses as unstudied
      });
    });

    group('isStreakActive', () {
      test('returns true when studied today', () {
        final today = DateTime.now();
        final sessions = [DateTime(today.year, today.month, today.day)];

        final isActive = service.isStreakActive(sessions);

        expect(isActive, isTrue);
      });

      test('returns true when studied yesterday', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final sessions = [
          DateTime(yesterday.year, yesterday.month, yesterday.day),
        ];

        final isActive = service.isStreakActive(sessions);

        expect(isActive, isTrue);
      });

      test('returns false when not studied in 2+ days', () {
        final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
        final sessions = [
          DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day),
        ];

        final isActive = service.isStreakActive(sessions);

        expect(isActive, isFalse);
      });

      test('returns false for empty sessions', () {
        final isActive = service.isStreakActive([]);

        expect(isActive, isFalse);
      });
    });
  });
}