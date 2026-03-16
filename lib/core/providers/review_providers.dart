import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octo_vocab/core/language/models/vocabulary_item.dart';
import 'package:octo_vocab/core/providers/language_providers.dart';
import 'package:octo_vocab/core/providers/progress_providers.dart';
import 'package:octo_vocab/core/providers/storage_providers.dart';

// ignore_for_file: public_member_api_docs

/// Spaced repetition algorithm configuration
class SpacedRepetitionConfig {
  static const keepPracticingInterval = Duration(
    days: 1,
  ); // Swipe left - needs more practice
  static const gotItInterval = Duration(days: 7); // Swipe right - got it!
  static const masteredThreshold = Duration(
    days: 30,
  ); // After this, consider mastered
  static const minimumInterval = Duration(hours: 4); // Fallback minimum
  static const maximumInterval = Duration(days: 180); // Maximum interval
}

/// Review session tracking
class ReviewSession {
  final String wordId;
  final DateTime reviewDate;
  final Duration nextInterval;
  final ReviewDifficulty difficulty;

  const ReviewSession({
    required this.wordId,
    required this.reviewDate,
    required this.nextInterval,
    required this.difficulty,
  });

  Map<String, dynamic> toJson() => {
    'wordId': wordId,
    'reviewDate': reviewDate.toIso8601String(),
    'nextInterval': nextInterval.inMilliseconds,
    'difficulty': difficulty.name,
  };

  factory ReviewSession.fromJson(Map<String, dynamic> json) => ReviewSession(
    wordId: json['wordId'] as String,
    reviewDate: DateTime.parse(json['reviewDate'] as String),
    nextInterval: Duration(milliseconds: json['nextInterval'] as int),
    difficulty: ReviewDifficulty.values.byName(json['difficulty'] as String),
  );
}

enum ReviewDifficulty { keepPracticing, gotIt }

/// Providers for review functionality
final reviewSessionsProvider = FutureProvider.autoDispose<List<ReviewSession>>((ref) async {
  final dataService = ref.watch(localDataServiceProvider);
  final selectedLanguage = ref.watch(selectedLanguageProvider);
  final allQuizResults = dataService.getQuizResults();

  // Filter quiz results to only include current language review sessions
  final quizResults = <String, dynamic>{};
  for (final entry in allQuizResults.entries) {
    if (entry.key.startsWith('review_') && entry.key.contains('${selectedLanguage}_')) {
      quizResults[entry.key] = entry.value;
    }
  }

  final reviewSessions = <ReviewSession>[];
  for (final entry in quizResults.entries) {
    if (entry.key.startsWith('review_')) {
      try {
        final sessionData = entry.value as Map<String, dynamic>;
        reviewSessions.add(ReviewSession.fromJson(sessionData));
      } catch (e) {
        // Skip invalid entries
      }
    }
  }

  return reviewSessions;
});

final reviewQueueProvider = FutureProvider.autoDispose<List<VocabularyItem>>((ref) async {
  final vocabulary = await ref.watch(vocabularyProvider.future);
  final wordProgress = await ref.watch(wordProgressProvider.future);
  final reviewSessions = await ref.watch(reviewSessionsProvider.future);
  final currentPlugin = ref.watch(currentLanguagePluginProvider);


  if (currentPlugin == null) {
    debugPrint(
      '🔍 REVIEW DEBUG: No current language plugin, returning empty queue',
    );
    return [];
  }

  final now = DateTime.now();
  final reviewQueue = <VocabularyItem>[];

  for (final item in vocabulary) {
    final progressKey = currentPlugin.getProgressKey(item.id);
    final status = wordProgress[progressKey];

    debugPrint(
      '🔍 REVIEW DEBUG: Item "${item.term}" (${item.id}) -> key: "$progressKey" -> status: "$status"',
    );

    // Skip mastered words - they've graduated from the review system
    if (status == 'mastered') continue;

    // Include words marked as difficult (immediate review) or reviewing (scheduled review)
    if (status == 'difficult' || status == 'reviewing') {
      // Find the most recent review session for this word
      final lastReview = reviewSessions
          .where((session) => session.wordId == item.id)
          .fold<ReviewSession?>(null, (latest, session) {
            if (latest == null ||
                session.reviewDate.isAfter(latest.reviewDate)) {
              return session;
            }
            return latest;
          });

      if (status == 'difficult') {
        // Difficult words are always added to review queue
        // This includes words marked difficult in flashcards (first time)
        // and words still struggling after reviews
        reviewQueue.add(item);
        debugPrint('🔍 REVIEW DEBUG: Adding difficult word "${item.term}" to review queue');
      } else if (status == 'reviewing' && lastReview != null) {
        // Reviewing words are only added if their interval has passed
        final nextReviewTime = lastReview.reviewDate.add(
          lastReview.nextInterval,
        );
        if (now.isAfter(nextReviewTime)) {
          reviewQueue.add(item);
          debugPrint('🔍 REVIEW DEBUG: Adding reviewing word "${item.term}" to review queue (interval passed)');
        } else {
          debugPrint('🔍 REVIEW DEBUG: Skipping reviewing word "${item.term}" (interval not yet passed)');
        }
      }
    }
  }

  // Shuffle for varied review order
  reviewQueue.shuffle();

  debugPrint(
    '🔍 REVIEW DEBUG: Final review queue contains ${reviewQueue.length} words',
  );
  for (final item in reviewQueue) {
    debugPrint('🔍 REVIEW DEBUG: -> "${item.term}" will appear in Review tab');
  }

  return reviewQueue;
});

/// Current review state providers
final currentReviewIndexProvider = StateProvider.autoDispose<int>((ref) => 0);
final isReviewCardFlippedProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
final reviewCardControllerProvider = Provider.autoDispose<CardSwiperController>(
  (ref) => CardSwiperController(),
);