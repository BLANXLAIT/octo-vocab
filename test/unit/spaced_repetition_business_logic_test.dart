// ignore_for_file: public_member_api_docs
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_vocab/features/review/review_screen.dart';

void main() {
  group('Spaced Repetition Business Logic Tests', () {
    group('Interval Calculation', () {
      test('calculates correct interval for "keep practicing"', () {
        const difficulty = ReviewDifficulty.keepPracticing;
        const expectedInterval = Duration(days: 1);

        // Create a dummy review screen to access the private method
        // In real implementation, we'd expose this as a pure function
        expect(
          SpacedRepetitionConfig.keepPracticingInterval,
          equals(expectedInterval),
        );
      });

      test('calculates correct interval for "got it"', () {
        const difficulty = ReviewDifficulty.gotIt;
        const expectedInterval = Duration(days: 7);

        expect(
          SpacedRepetitionConfig.gotItInterval,
          equals(expectedInterval),
        );
      });

      test('defines mastery threshold correctly', () {
        expect(
          SpacedRepetitionConfig.masteredThreshold,
          equals(const Duration(days: 30)),
        );
      });

      test('has reasonable minimum and maximum intervals', () {
        expect(
          SpacedRepetitionConfig.minimumInterval,
          equals(const Duration(hours: 4)),
        );
        expect(
          SpacedRepetitionConfig.maximumInterval,
          equals(const Duration(days: 180)),
        );
      });
    });

    group('Review Session Serialization', () {
      test('creates review session with correct data', () {
        final session = ReviewSession(
          wordId: 'amor',
          reviewDate: DateTime(2024, 1, 15),
          nextInterval: const Duration(days: 7),
          difficulty: ReviewDifficulty.gotIt,
        );

        expect(session.wordId, equals('amor'));
        expect(session.reviewDate, equals(DateTime(2024, 1, 15)));
        expect(session.nextInterval, equals(const Duration(days: 7)));
        expect(session.difficulty, equals(ReviewDifficulty.gotIt));
      });

      test('serializes review session to JSON correctly', () {
        final session = ReviewSession(
          wordId: 'vita',
          reviewDate: DateTime(2024, 1, 15, 10, 30),
          nextInterval: const Duration(days: 1),
          difficulty: ReviewDifficulty.keepPracticing,
        );

        final json = session.toJson();

        expect(json['wordId'], equals('vita'));
        expect(json['reviewDate'], equals('2024-01-15T10:30:00.000'));
        expect(json['nextInterval'], equals(86400000)); // 1 day in milliseconds
        expect(json['difficulty'], equals('keepPracticing'));
      });

      test('deserializes review session from JSON correctly', () {
        final json = {
          'wordId': 'terra',
          'reviewDate': '2024-01-15T14:45:00.000',
          'nextInterval': 604800000, // 7 days in milliseconds
          'difficulty': 'gotIt',
        };

        final session = ReviewSession.fromJson(json);

        expect(session.wordId, equals('terra'));
        expect(session.reviewDate, equals(DateTime(2024, 1, 15, 14, 45)));
        expect(session.nextInterval, equals(const Duration(days: 7)));
        expect(session.difficulty, equals(ReviewDifficulty.gotIt));
      });

      test('handles round-trip serialization correctly', () {
        final originalSession = ReviewSession(
          wordId: 'aqua',
          reviewDate: DateTime(2024, 1, 15, 16, 20, 30),
          nextInterval: const Duration(hours: 4),
          difficulty: ReviewDifficulty.keepPracticing,
        );

        final json = originalSession.toJson();
        final deserializedSession = ReviewSession.fromJson(json);

        expect(deserializedSession.wordId, equals(originalSession.wordId));
        expect(deserializedSession.reviewDate, equals(originalSession.reviewDate));
        expect(deserializedSession.nextInterval, equals(originalSession.nextInterval));
        expect(deserializedSession.difficulty, equals(originalSession.difficulty));
      });
    });

    group('Review Difficulty Enum', () {
      test('has correct enum values', () {
        expect(ReviewDifficulty.values.length, equals(2));
        expect(ReviewDifficulty.values, contains(ReviewDifficulty.keepPracticing));
        expect(ReviewDifficulty.values, contains(ReviewDifficulty.gotIt));
      });

      test('enum values have correct string representation', () {
        expect(ReviewDifficulty.keepPracticing.name, equals('keepPracticing'));
        expect(ReviewDifficulty.gotIt.name, equals('gotIt'));
      });
    });
  });
}