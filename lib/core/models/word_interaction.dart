// ignore_for_file: public_member_api_docs

/// Enhanced word interaction tracking for spaced repetition and timing-based learning
class WordInteraction {
  final String wordId;
  final DateTime lastSeen;
  final DateTime? lastReviewed;
  final int timesEncountered;
  final Duration minimumInterval;
  final InteractionType lastInteractionType;

  const WordInteraction({
    required this.wordId,
    required this.lastSeen,
    this.lastReviewed,
    required this.timesEncountered,
    required this.minimumInterval,
    required this.lastInteractionType,
  });

  /// Check if enough time has passed since last interaction
  bool isAvailableForPresentation([DateTime? now]) {
    now ??= DateTime.now();
    final nextAvailableTime = lastSeen.add(minimumInterval);
    return now.isAfter(nextAvailableTime);
  }

  /// Calculate next minimum interval based on interaction history
  Duration calculateNextInterval(InteractionType newInteractionType) {
    switch (newInteractionType) {
      case InteractionType.firstSeen:
        return const Duration(hours: 4); // First exposure, short interval
      case InteractionType.flashcardUnknown:
        return const Duration(hours: 2); // Quick retry for unknown words
      case InteractionType.flashcardKnown:
        return Duration(days: timesEncountered > 2 ? 7 : 1); // Longer for known words
      case InteractionType.reviewKeepPracticing:
        return const Duration(days: 1); // Standard review interval
      case InteractionType.reviewGotIt:
        return Duration(days: timesEncountered > 3 ? 14 : 7); // Exponential backoff
      case InteractionType.quiz:
        return const Duration(hours: 6); // Quiz exposure, medium interval
    }
  }

  /// Create new interaction record
  WordInteraction withNewInteraction(
    InteractionType type, [
    DateTime? timestamp,
  ]) {
    timestamp ??= DateTime.now();
    final newInterval = calculateNextInterval(type);

    return WordInteraction(
      wordId: wordId,
      lastSeen: timestamp,
      lastReviewed: type.isReviewType ? timestamp : lastReviewed,
      timesEncountered: timesEncountered + 1,
      minimumInterval: newInterval,
      lastInteractionType: type,
    );
  }

  Map<String, dynamic> toJson() => {
        'wordId': wordId,
        'lastSeen': lastSeen.toIso8601String(),
        'lastReviewed': lastReviewed?.toIso8601String(),
        'timesEncountered': timesEncountered,
        'minimumInterval': minimumInterval.inMilliseconds,
        'lastInteractionType': lastInteractionType.name,
      };

  factory WordInteraction.fromJson(Map<String, dynamic> json) =>
      WordInteraction(
        wordId: json['wordId'] as String,
        lastSeen: DateTime.parse(json['lastSeen'] as String),
        lastReviewed: json['lastReviewed'] != null
            ? DateTime.parse(json['lastReviewed'] as String)
            : null,
        timesEncountered: json['timesEncountered'] as int,
        minimumInterval: Duration(milliseconds: json['minimumInterval'] as int),
        lastInteractionType: InteractionType.values
            .byName(json['lastInteractionType'] as String),
      );

  /// Create initial interaction for new word
  factory WordInteraction.initial(String wordId) => WordInteraction(
        wordId: wordId,
        lastSeen: DateTime.now(),
        timesEncountered: 1,
        minimumInterval: const Duration(hours: 4),
        lastInteractionType: InteractionType.firstSeen,
      );
}

enum InteractionType {
  firstSeen,
  flashcardUnknown,
  flashcardKnown,
  reviewKeepPracticing,
  reviewGotIt,
  quiz;

  bool get isReviewType =>
      this == reviewKeepPracticing || this == reviewGotIt;
}