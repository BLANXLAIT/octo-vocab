// ignore_for_file: public_member_api_docs
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_vocab/core/models/word_interaction.dart';

void main() {
  group('WordInteraction Tests', () {
    test('creates initial interaction correctly', () {
      final interaction = WordInteraction.initial('test_word');

      expect(interaction.wordId, 'test_word');
      expect(interaction.timesEncountered, 1);
      expect(interaction.minimumInterval, const Duration(hours: 4));
      expect(interaction.lastInteractionType, InteractionType.firstSeen);
    });

    test('calculates next interval based on interaction type', () {
      final interaction = WordInteraction.initial('test_word');

      // Test flashcard known interval
      final knownInterval = interaction.calculateNextInterval(InteractionType.flashcardKnown);
      expect(knownInterval, const Duration(days: 1)); // First encounter, short interval

      // Test flashcard unknown interval
      final unknownInterval = interaction.calculateNextInterval(InteractionType.flashcardUnknown);
      expect(unknownInterval, const Duration(hours: 2));

      // Test review got it interval
      final reviewGotItInterval = interaction.calculateNextInterval(InteractionType.reviewGotIt);
      expect(reviewGotItInterval, const Duration(days: 7)); // Early encounters, 7 days
    });

    test('creates new interaction with updated data', () {
      final initial = WordInteraction.initial('test_word');
      final timestamp = DateTime(2024, 1, 1, 12, 0);

      final updated = initial.withNewInteraction(InteractionType.flashcardKnown, timestamp);

      expect(updated.wordId, 'test_word');
      expect(updated.timesEncountered, 2); // Incremented
      expect(updated.lastSeen, timestamp);
      expect(updated.lastInteractionType, InteractionType.flashcardKnown);
      expect(updated.minimumInterval, const Duration(days: 1));
    });

    test('checks availability for presentation correctly', () {
      final now = DateTime(2024, 1, 1, 12, 0);
      final interaction = WordInteraction(
        wordId: 'test_word',
        lastSeen: now.subtract(const Duration(hours: 5)), // 5 hours ago
        timesEncountered: 1,
        minimumInterval: const Duration(hours: 4), // 4 hour minimum
        lastInteractionType: InteractionType.firstSeen,
      );

      // Should be available (5 hours > 4 hour minimum)
      expect(interaction.isAvailableForPresentation(now), isTrue);

      // Test with shorter interval
      final recentInteraction = WordInteraction(
        wordId: 'test_word',
        lastSeen: now.subtract(const Duration(hours: 2)), // 2 hours ago
        timesEncountered: 1,
        minimumInterval: const Duration(hours: 4), // 4 hour minimum
        lastInteractionType: InteractionType.firstSeen,
      );

      // Should not be available (2 hours < 4 hour minimum)
      expect(recentInteraction.isAvailableForPresentation(now), isFalse);
    });

    test('serializes and deserializes correctly', () {
      final timestamp = DateTime(2024, 1, 1, 12, 0);
      final reviewTimestamp = DateTime(2024, 1, 1, 10, 0);

      final original = WordInteraction(
        wordId: 'test_word',
        lastSeen: timestamp,
        lastReviewed: reviewTimestamp,
        timesEncountered: 3,
        minimumInterval: const Duration(days: 7),
        lastInteractionType: InteractionType.reviewGotIt,
      );

      final json = original.toJson();
      final deserialized = WordInteraction.fromJson(json);

      expect(deserialized.wordId, original.wordId);
      expect(deserialized.lastSeen, original.lastSeen);
      expect(deserialized.lastReviewed, original.lastReviewed);
      expect(deserialized.timesEncountered, original.timesEncountered);
      expect(deserialized.minimumInterval, original.minimumInterval);
      expect(deserialized.lastInteractionType, original.lastInteractionType);
    });

    test('handles multiple interactions with increasing intervals', () {
      var interaction = WordInteraction.initial('test_word');

      // First flashcard known
      interaction = interaction.withNewInteraction(InteractionType.flashcardKnown);
      expect(interaction.timesEncountered, 2);
      expect(interaction.minimumInterval, const Duration(days: 1));

      // Multiple successful reviews should increase interval
      interaction = interaction.withNewInteraction(InteractionType.reviewGotIt);
      expect(interaction.timesEncountered, 3);

      interaction = interaction.withNewInteraction(InteractionType.reviewGotIt);
      expect(interaction.timesEncountered, 4);
      // At this point we had 3 encounters when calculating, so still 7 days
      expect(interaction.minimumInterval, const Duration(days: 7));

      // One more to trigger the longer interval (now we have 4 when calculating)
      interaction = interaction.withNewInteraction(InteractionType.reviewGotIt);
      expect(interaction.timesEncountered, 5);
      expect(interaction.minimumInterval, const Duration(days: 14)); // Longer interval after 4+ encounters
    });

    test('tracks review-specific interactions', () {
      final interaction = WordInteraction.initial('test_word');
      final reviewTimestamp = DateTime(2024, 1, 1, 12, 0);

      // Non-review interaction shouldn't update lastReviewed
      final flashcardInteraction = interaction.withNewInteraction(
        InteractionType.flashcardKnown,
        reviewTimestamp,
      );
      expect(flashcardInteraction.lastReviewed, isNull);

      // Review interaction should update lastReviewed
      final reviewInteraction = interaction.withNewInteraction(
        InteractionType.reviewGotIt,
        reviewTimestamp,
      );
      expect(reviewInteraction.lastReviewed, reviewTimestamp);
    });
  });
}