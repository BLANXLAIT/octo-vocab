import 'package:octo_vocab/core/models/word_interaction.dart';

/// Centralized spaced repetition algorithm service
/// Implements timing-based word presentation using proven memory techniques
///
/// Based on simplified SM-2 algorithm with custom tuning for vocabulary learning
class SpacedRepetitionService {
  const SpacedRepetitionService();

  // Algorithm constants - can be tuned based on user performance data
  static const Duration firstSeenInterval = Duration(hours: 4);
  static const Duration flashcardUnknownInterval = Duration(hours: 2);
  static const Duration flashcardKnownShortInterval = Duration(days: 1);
  static const Duration flashcardKnownLongInterval = Duration(days: 7);
  static const Duration reviewKeepPracticingInterval = Duration(days: 1);
  static const Duration reviewGotItShortInterval = Duration(days: 7);
  static const Duration reviewGotItLongInterval = Duration(days: 14);
  static const Duration quizInterval = Duration(hours: 6);

  // Thresholds
  static const int knownThresholdForLongInterval = 2; // > 2 means 3+
  static const int gotItThresholdForLongInterval = 3; // > 3 means 4+
  static const int masteredReviewThreshold = 3;

  /// Calculate the next interval for a word based on interaction type
  /// and number of times encountered
  Duration calculateNextInterval(
    InteractionType interactionType, {
    required int timesEncountered,
  }) {
    switch (interactionType) {
      case InteractionType.firstSeen:
        return firstSeenInterval;

      case InteractionType.flashcardUnknown:
        return flashcardUnknownInterval;

      case InteractionType.flashcardKnown:
        // Exponential backoff: short interval for new words, long for familiar
        return timesEncountered > knownThresholdForLongInterval
            ? flashcardKnownLongInterval
            : flashcardKnownShortInterval;

      case InteractionType.reviewKeepPracticing:
        return reviewKeepPracticingInterval;

      case InteractionType.reviewGotIt:
        // Progressive spacing: longer intervals as mastery improves
        return timesEncountered > gotItThresholdForLongInterval
            ? reviewGotItLongInterval
            : reviewGotItShortInterval;

      case InteractionType.quiz:
        return quizInterval;
    }
  }

  /// Check if a word is available for presentation based on timing constraints
  /// Returns true if:
  /// - Word has never been seen (lastSeen is null)
  /// - Enough time has passed since last interaction (interval expired)
  bool isWordAvailableForPresentation({
    required DateTime? lastSeen,
    required Duration minimumInterval,
    DateTime? now,
  }) {
    if (lastSeen == null) return true;

    now ??= DateTime.now();
    final nextAvailableTime = lastSeen.add(minimumInterval);
    return now.isAfter(nextAvailableTime) ||
        now.isAtSameMomentAs(nextAvailableTime);
  }

  /// Determine if a word should be promoted to mastered status
  /// Requires 3+ successful reviews and word must be in reviewing status
  bool shouldPromoteToMastered({
    required int successfulReviewCount,
    required String? currentStatus,
  }) {
    return successfulReviewCount >= masteredReviewThreshold &&
        currentStatus == 'reviewing';
  }

  /// Get the next status for a word based on interaction type
  /// Implements the word progression pipeline:
  /// new → difficult → reviewing → mastered
  ///   or
  /// new → known (skip difficult words that user already knows)
  String getNextWordStatus(
    InteractionType interactionType, {
    required String? currentStatus,
    required int successfulReviewCount,
  }) {
    switch (interactionType) {
      case InteractionType.firstSeen:
        return currentStatus ?? 'new';

      case InteractionType.flashcardUnknown:
        return 'difficult';

      case InteractionType.flashcardKnown:
        return 'known';

      case InteractionType.reviewKeepPracticing:
        return 'difficult';

      case InteractionType.reviewGotIt:
        // Check if ready for mastery
        if (shouldPromoteToMastered(
          successfulReviewCount: successfulReviewCount + 1, // +1 for this review
          currentStatus: currentStatus,
        )) {
          return 'mastered';
        }
        return 'reviewing';

      case InteractionType.quiz:
        // Quiz interactions don't change status, just track timing
        return currentStatus ?? 'new';
    }
  }

  /// Filter a list of word IDs to only include those available for presentation
  /// based on their interaction history
  List<String> filterAvailableWords(
    List<String> wordIds,
    Map<String, WordInteraction> interactions, {
    DateTime? now,
  }) {
    now ??= DateTime.now();

    return wordIds.where((wordId) {
      final interaction = interactions[wordId];
      if (interaction == null) return true; // New words always available

      return isWordAvailableForPresentation(
        lastSeen: interaction.lastSeen,
        minimumInterval: interaction.minimumInterval,
        now: now,
      );
    }).toList();
  }
}