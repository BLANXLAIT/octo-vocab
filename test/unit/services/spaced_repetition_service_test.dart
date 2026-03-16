import 'package:flutter_test/flutter_test.dart';
import 'package:octo_vocab/core/models/word_interaction.dart';
import 'package:octo_vocab/core/services/spaced_repetition_service.dart';

void main() {
  late SpacedRepetitionService service;

  setUp(() {
    service = const SpacedRepetitionService();
  });

  group('SpacedRepetitionService', () {
    group('calculateNextInterval', () {
      test('returns 4 hours for first seen words', () {
        final interval = service.calculateNextInterval(
          InteractionType.firstSeen,
          timesEncountered: 1,
        );

        expect(interval, const Duration(hours: 4));
      });

      test('returns 2 hours for unknown flashcard', () {
        final interval = service.calculateNextInterval(
          InteractionType.flashcardUnknown,
          timesEncountered: 2,
        );

        expect(interval, const Duration(hours: 2));
      });

      test('returns 1 day for known flashcard with few encounters', () {
        final interval = service.calculateNextInterval(
          InteractionType.flashcardKnown,
          timesEncountered: 2,
        );

        expect(interval, const Duration(days: 1));
      });

      test('returns 7 days for known flashcard with many encounters', () {
        final interval = service.calculateNextInterval(
          InteractionType.flashcardKnown,
          timesEncountered: 3,
        );

        expect(interval, const Duration(days: 7));
      });

      test('returns 1 day for review keep practicing', () {
        final interval = service.calculateNextInterval(
          InteractionType.reviewKeepPracticing,
          timesEncountered: 5,
        );

        expect(interval, const Duration(days: 1));
      });

      test('returns 7 days for review got it with few encounters', () {
        final interval = service.calculateNextInterval(
          InteractionType.reviewGotIt,
          timesEncountered: 3,
        );

        expect(interval, const Duration(days: 7));
      });

      test('returns 14 days for review got it with many encounters', () {
        final interval = service.calculateNextInterval(
          InteractionType.reviewGotIt,
          timesEncountered: 4,
        );

        expect(interval, const Duration(days: 14));
      });

      test('returns 6 hours for quiz interaction', () {
        final interval = service.calculateNextInterval(
          InteractionType.quiz,
          timesEncountered: 2,
        );

        expect(interval, const Duration(hours: 6));
      });
    });

    group('isWordAvailableForPresentation', () {
      test('returns true for words never seen', () {
        final available = service.isWordAvailableForPresentation(
          lastSeen: null,
          minimumInterval: const Duration(hours: 4),
        );

        expect(available, isTrue);
      });

      test('returns false when interval has not passed', () {
        final now = DateTime(2024, 1, 15, 10, 0);
        final lastSeen = DateTime(2024, 1, 15, 8, 0); // 2 hours ago

        final available = service.isWordAvailableForPresentation(
          lastSeen: lastSeen,
          minimumInterval: const Duration(hours: 4),
          now: now,
        );

        expect(available, isFalse);
      });

      test('returns true when interval has passed', () {
        final now = DateTime(2024, 1, 15, 10, 0);
        final lastSeen = DateTime(2024, 1, 15, 5, 0); // 5 hours ago

        final available = service.isWordAvailableForPresentation(
          lastSeen: lastSeen,
          minimumInterval: const Duration(hours: 4),
          now: now,
        );

        expect(available, isTrue);
      });

      test('returns true when interval exactly matches', () {
        final now = DateTime(2024, 1, 15, 10, 0);
        final lastSeen = DateTime(2024, 1, 15, 6, 0); // Exactly 4 hours ago

        final available = service.isWordAvailableForPresentation(
          lastSeen: lastSeen,
          minimumInterval: const Duration(hours: 4),
          now: now,
        );

        expect(available, isTrue);
      });
    });

    group('shouldPromoteToMastered', () {
      test('returns false with less than 3 successful reviews', () {
        final shouldPromote = service.shouldPromoteToMastered(
          successfulReviewCount: 2,
          currentStatus: 'reviewing',
        );

        expect(shouldPromote, isFalse);
      });

      test('returns true with 3 or more successful reviews', () {
        final shouldPromote = service.shouldPromoteToMastered(
          successfulReviewCount: 3,
          currentStatus: 'reviewing',
        );

        expect(shouldPromote, isTrue);
      });

      test('returns false if word is not in reviewing status', () {
        final shouldPromote = service.shouldPromoteToMastered(
          successfulReviewCount: 3,
          currentStatus: 'difficult',
        );

        expect(shouldPromote, isFalse);
      });

      test('returns false if word is already mastered', () {
        final shouldPromote = service.shouldPromoteToMastered(
          successfulReviewCount: 3,
          currentStatus: 'mastered',
        );

        expect(shouldPromote, isFalse);
      });
    });

    group('getNextWordStatus', () {
      test('marks flashcard unknown as difficult', () {
        final status = service.getNextWordStatus(
          InteractionType.flashcardUnknown,
          currentStatus: null,
          successfulReviewCount: 0,
        );

        expect(status, 'difficult');
      });

      test('marks flashcard known as known', () {
        final status = service.getNextWordStatus(
          InteractionType.flashcardKnown,
          currentStatus: null,
          successfulReviewCount: 0,
        );

        expect(status, 'known');
      });

      test('keeps review keep practicing as difficult', () {
        final status = service.getNextWordStatus(
          InteractionType.reviewKeepPracticing,
          currentStatus: 'difficult',
          successfulReviewCount: 0,
        );

        expect(status, 'difficult');
      });

      test('promotes review got it to reviewing', () {
        final status = service.getNextWordStatus(
          InteractionType.reviewGotIt,
          currentStatus: 'difficult',
          successfulReviewCount: 1,
        );

        expect(status, 'reviewing');
      });

      test('promotes to mastered after 3 successful reviews', () {
        final status = service.getNextWordStatus(
          InteractionType.reviewGotIt,
          currentStatus: 'reviewing',
          successfulReviewCount: 2, // This will be the 3rd
        );

        expect(status, 'mastered');
      });

      test('keeps known words as known', () {
        final status = service.getNextWordStatus(
          InteractionType.quiz,
          currentStatus: 'known',
          successfulReviewCount: 0,
        );

        expect(status, 'known');
      });
    });

    group('filterAvailableWords', () {
      test('returns all words when no interactions recorded', () {
        final wordIds = ['word1', 'word2', 'word3'];
        final interactions = <String, WordInteraction>{};

        final available = service.filterAvailableWords(
          wordIds,
          interactions,
        );

        expect(available, wordIds);
      });

      test('filters out words with recent interactions', () {
        final now = DateTime(2024, 1, 15, 10, 0);
        final wordIds = ['word1', 'word2', 'word3'];

        final interactions = {
          'word1': WordInteraction(
            wordId: 'word1',
            lastSeen: DateTime(2024, 1, 15, 8, 0), // 2 hours ago
            timesEncountered: 1,
            minimumInterval: const Duration(hours: 4),
            lastInteractionType: InteractionType.firstSeen,
          ),
          'word2': WordInteraction(
            wordId: 'word2',
            lastSeen: DateTime(2024, 1, 15, 5, 0), // 5 hours ago
            timesEncountered: 1,
            minimumInterval: const Duration(hours: 4),
            lastInteractionType: InteractionType.firstSeen,
          ),
        };

        final available = service.filterAvailableWords(
          wordIds,
          interactions,
          now: now,
        );

        expect(available, ['word2', 'word3']); // word1 is too recent
      });

      test('includes words with passed intervals', () {
        final now = DateTime(2024, 1, 15, 10, 0);
        final wordIds = ['word1', 'word2'];

        final interactions = {
          'word1': WordInteraction(
            wordId: 'word1',
            lastSeen: DateTime(2024, 1, 14, 10, 0), // 1 day ago
            timesEncountered: 2,
            minimumInterval: const Duration(hours: 12),
            lastInteractionType: InteractionType.flashcardKnown,
          ),
          'word2': WordInteraction(
            wordId: 'word2',
            lastSeen: DateTime(2024, 1, 15, 8, 30), // 1.5 hours ago
            timesEncountered: 1,
            minimumInterval: const Duration(hours: 1),
            lastInteractionType: InteractionType.quiz,
          ),
        };

        final available = service.filterAvailableWords(
          wordIds,
          interactions,
          now: now,
        );

        expect(available, ['word1', 'word2']); // Both available
      });
    });

    group('algorithm constants', () {
      test('config values match expected spaced repetition intervals', () {
        expect(
          SpacedRepetitionService.firstSeenInterval,
          const Duration(hours: 4),
        );
        expect(
          SpacedRepetitionService.flashcardUnknownInterval,
          const Duration(hours: 2),
        );
        expect(
          SpacedRepetitionService.flashcardKnownShortInterval,
          const Duration(days: 1),
        );
        expect(
          SpacedRepetitionService.flashcardKnownLongInterval,
          const Duration(days: 7),
        );
        expect(
          SpacedRepetitionService.reviewKeepPracticingInterval,
          const Duration(days: 1),
        );
        expect(
          SpacedRepetitionService.reviewGotItShortInterval,
          const Duration(days: 7),
        );
        expect(
          SpacedRepetitionService.reviewGotItLongInterval,
          const Duration(days: 14),
        );
        expect(
          SpacedRepetitionService.quizInterval,
          const Duration(hours: 6),
        );
      });
    });
  });
}