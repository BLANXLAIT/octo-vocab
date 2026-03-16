import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:octo_vocab/core/repositories/study_session_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSharedPreferences mockPrefs;
  late StudySessionRepository repository;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    repository = StudySessionRepository(mockPrefs);
  });

  group('StudySessionRepository', () {
    group('getStudySessions', () {
      test('returns empty list when no data stored', () {
        when(() => mockPrefs.getString(any())).thenReturn(null);

        final result = repository.getStudySessions();

        expect(result, isEmpty);
      });

      test('returns parsed study sessions', () {
        const jsonData = '["2024-01-01T00:00:00.000Z","2024-01-02T00:00:00.000Z"]';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final result = repository.getStudySessions();

        expect(result, hasLength(2));
        expect(result.first.year, 2024);
        expect(result.first.month, 1);
        expect(result.first.day, 1);
      });

      test('handles invalid date strings', () {
        const jsonData = '["2024-01-01T00:00:00.000Z","invalid","2024-01-03T00:00:00.000Z"]';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final result = repository.getStudySessions();

        expect(result, hasLength(2)); // Skips invalid date
      });

      test('handles corrupted JSON gracefully', () {
        when(() => mockPrefs.getString(any())).thenReturn('invalid json');

        final result = repository.getStudySessions();

        expect(result, isEmpty);
      });
    });

    group('recordStudySession', () {
      test('records new session for today', () async {
        when(() => mockPrefs.getString(any())).thenReturn('[]');
        when(() => mockPrefs.setString(any(), any()))
            .thenAnswer((_) async => true);

        final testDate = DateTime(2024, 1, 15, 10, 30);
        final result = await repository.recordStudySession(testDate);

        expect(result, isTrue);
        verify(() => mockPrefs.setString(any(), any())).called(1);
      });

      test('does not duplicate session for same day', () async {
        final today = DateTime(2024, 1, 15);
        final existingData = '["2024-01-15T00:00:00.000Z"]';

        when(() => mockPrefs.getString(any())).thenReturn(existingData);

        final testDate = DateTime(2024, 1, 15, 14, 30); // Later same day
        final result = await repository.recordStudySession(testDate);

        expect(result, isTrue);
        verifyNever(() => mockPrefs.setString(any(), any()));
      });

      test('adds session for new day', () async {
        const existingData = '["2024-01-14T00:00:00.000Z"]';
        when(() => mockPrefs.getString(any())).thenReturn(existingData);
        when(() => mockPrefs.setString(any(), any()))
            .thenAnswer((_) async => true);

        final testDate = DateTime(2024, 1, 15, 10, 0);
        final result = await repository.recordStudySession(testDate);

        expect(result, isTrue);
        final captured = verify(() => mockPrefs.setString(
              StudySessionRepository.storageKey,
              captureAny(),
            )).captured;

        final savedData = captured.first as String;
        expect(savedData, contains('2024-01-14'));
        expect(savedData, contains('2024-01-15'));
      });
    });

    group('hasStudiedToday', () {
      test('returns true when studied today', () {
        final today = DateTime.now();
        final todayIso = DateTime(today.year, today.month, today.day)
            .toIso8601String();
        final jsonData = '["$todayIso"]';

        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final result = repository.hasStudiedToday();

        expect(result, isTrue);
      });

      test('returns false when not studied today', () {
        const jsonData = '["2024-01-01T00:00:00.000Z"]';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final result = repository.hasStudiedToday();

        expect(result, isFalse);
      });

      test('returns false when no sessions', () {
        when(() => mockPrefs.getString(any())).thenReturn(null);

        final result = repository.hasStudiedToday();

        expect(result, isFalse);
      });
    });

    group('getCurrentStreak', () {
      test('calculates consecutive days correctly', () {
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final twoDaysAgo = today.subtract(const Duration(days: 2));

        final sessions = [
          DateTime(today.year, today.month, today.day),
          DateTime(yesterday.year, yesterday.month, yesterday.day),
          DateTime(twoDaysAgo.year, twoDaysAgo.month, twoDaysAgo.day),
        ];

        final jsonData = jsonEncode(
          sessions.map((d) => d.toIso8601String()).toList(),
        );

        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final streak = repository.getCurrentStreak();

        expect(streak, 3);
      });

      test('returns 0 when streak is broken', () {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        final sessions = [
          DateTime(threeDaysAgo.year, threeDaysAgo.month, threeDaysAgo.day),
        ];

        final jsonData = jsonEncode(
          sessions.map((d) => d.toIso8601String()).toList(),
        );

        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final streak = repository.getCurrentStreak();

        expect(streak, 0);
      });

      test('counts yesterday as valid streak start', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final sessions = [
          DateTime(yesterday.year, yesterday.month, yesterday.day),
        ];

        final jsonData = jsonEncode(
          sessions.map((d) => d.toIso8601String()).toList(),
        );

        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final streak = repository.getCurrentStreak();

        expect(streak, 1);
      });
    });

    group('getThisWeekSessions', () {
      test('counts sessions in current week', () {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        // Get a day that's definitely in this week (2 days ago if possible, otherwise today)
        final daysAgo = now.weekday >= 3 ? 2 : 0;
        final inThisWeek = today.subtract(Duration(days: daysAgo));
        final lastWeek = today.subtract(const Duration(days: 8));

        final sessions = [today, inThisWeek, lastWeek];
        final jsonData = jsonEncode(
          sessions.map((d) => d.toIso8601String()).toList(),
        );

        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final count = repository.getThisWeekSessions();

        // Should count today and inThisWeek, but not lastWeek
        expect(count, greaterThanOrEqualTo(1)); // At least today
        expect(count, lessThanOrEqualTo(2)); // At most today + inThisWeek
      });
    });

    group('clearAllSessions', () {
      test('removes all study sessions', () async {
        when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

        final result = await repository.clearAllSessions();

        expect(result, isTrue);
        verify(() => mockPrefs.remove(StudySessionRepository.storageKey))
            .called(1);
      });
    });
  });
}