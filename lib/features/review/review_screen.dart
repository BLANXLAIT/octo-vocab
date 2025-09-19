// ignore_for_file: public_member_api_docs
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:octo_vocab/core/language/language_plugin.dart';
import 'package:octo_vocab/core/language/language_registry.dart';
import 'package:octo_vocab/core/language/models/vocabulary_item.dart';
import 'package:octo_vocab/core/language/widgets/language_selector.dart';
import 'package:octo_vocab/core/models/word_interaction.dart';
import 'package:octo_vocab/core/services/local_data_service.dart';
import 'package:octo_vocab/features/progress/progress_screen.dart';

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
  final dataService = await ref.watch(localDataServiceProvider.future);
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

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewQueueAsync = ref.watch(reviewQueueProvider);
    final currentIndex = ref.watch(currentReviewIndexProvider);
    final controller = ref.watch(reviewCardControllerProvider);

    return reviewQueueAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Review'),
          automaticallyImplyLeading: false,
          actions: const [LanguageSelectorAction(), SizedBox(width: 8)],
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(
          title: const Text('Review'),
          automaticallyImplyLeading: false,
          actions: const [LanguageSelectorAction(), SizedBox(width: 8)],
        ),
        body: Center(child: Text('Failed to load review queue: $e')),
      ),
      data: (reviewQueue) {
        if (reviewQueue.isEmpty) {
          return _buildNoReviewScreen(context);
        }

        // Check if review session is complete
        if (currentIndex >= reviewQueue.length) {
          return _buildReviewCompleteScreen(context, ref, reviewQueue.length);
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Review ${currentIndex + 1}/${reviewQueue.length}'),
            automaticallyImplyLeading: false,
            actions: const [LanguageSelectorAction(), SizedBox(width: 8)],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CardSwiper(
              controller: controller,
              cardsCount: reviewQueue.length,
              numberOfCardsDisplayed: 1,
              allowedSwipeDirection: const AllowedSwipeDirection.only(
                left: true,
                right: true,
              ),
              onSwipe: (previousIndex, currentIndex, direction) {
                // Handle swipe logic
                HapticFeedback.lightImpact();

                final swipedItem = reviewQueue[previousIndex];
                _handleReviewSwipe(context, ref, swipedItem, direction);

                // Reset flip state for next card
                ref.read(isReviewCardFlippedProvider.notifier).state = false;

                // Update current index
                if (currentIndex != null) {
                  ref.read(currentReviewIndexProvider.notifier).state =
                      currentIndex;
                } else {
                  // Review session complete
                  ref.read(currentReviewIndexProvider.notifier).state =
                      reviewQueue.length;
                }

                return true;
              },
              cardBuilder:
                  (
                    context,
                    index,
                    horizontalThresholdPercentage,
                    verticalThresholdPercentage,
                  ) {
                    final item = reviewQueue[index];
                    return ReviewCardWidget(
                      vocabularyItem: item,
                      onTap: () {
                        ref.read(isReviewCardFlippedProvider.notifier).state =
                            !ref.read(isReviewCardFlippedProvider);
                      },
                    );
                  },
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoReviewScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        automaticallyImplyLeading: false,
        actions: const [LanguageSelectorAction(), SizedBox(width: 8)],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Colors.green[600],
              ),
              const SizedBox(height: 24),
              Text(
                'Great Work!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No words need review right now.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Words marked as difficult will appear here for spaced repetition review.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.tips_and_updates, color: Colors.amber[700]),
                      const SizedBox(height: 8),
                      const Text(
                        'How to get words to review:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Go to Learn mode and swipe left on words you find difficult\n'
                        '• Those words will appear here for spaced repetition review\n'
                        '• Review timing follows proven memory techniques',
                        textAlign: TextAlign.left,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewCompleteScreen(
    BuildContext context,
    WidgetRef ref,
    int reviewedCount,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Complete'),
        automaticallyImplyLeading: false,
        actions: const [LanguageSelectorAction(), SizedBox(width: 8)],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: 80, color: Colors.amber[600]),
              const SizedBox(height: 24),
              Text(
                'Review Session Complete!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You reviewed $reviewedCount words',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Your next review sessions are scheduled based on your performance.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async => _resetReview(ref),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Start New Review Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleReviewSwipe(
    BuildContext context,
    WidgetRef ref,
    VocabularyItem item,
    CardSwiperDirection direction,
  ) async {
    HapticFeedback.selectionClick();

    try {
      // Determine difficulty based on swipe direction
      final difficulty = direction == CardSwiperDirection.right
          ? ReviewDifficulty.gotIt
          : ReviewDifficulty.keepPracticing;

      // Calculate next review interval
      final nextInterval = _calculateNextInterval(difficulty);

      // Update word status based on swipe
      await _updateWordStatus(ref, item, difficulty);

      // Record word interaction for timing constraints
      final dataService = await ref.read(localDataServiceProvider.future);
      final interactionType = difficulty == ReviewDifficulty.gotIt
          ? InteractionType.reviewGotIt
          : InteractionType.reviewKeepPracticing;
      await dataService.recordWordInteraction(item.id, interactionType);

      // Save review session
      await _saveReviewSession(ref, item, difficulty, nextInterval);

      // Invalidate providers to refresh the review queue
      ref.invalidate(reviewQueueProvider);
      ref.invalidate(wordProgressProvider);

      // Show feedback
      if (!context.mounted) return;
      if (direction == CardSwiperDirection.right) {
        _showFeedbackSnackBar(context, 'Great job! ✅', Colors.green);
      } else {
        _showFeedbackSnackBar(context, 'Keep practicing! 📚', Colors.orange);
      }
    } catch (e) {
      // Silent fail with generic feedback
      if (!context.mounted) return;
      if (direction == CardSwiperDirection.right) {
        _showFeedbackSnackBar(context, 'Great job! ✅', Colors.green);
      } else {
        _showFeedbackSnackBar(context, 'Keep practicing! 📚', Colors.orange);
      }
    }
  }

  void _showFeedbackSnackBar(
    BuildContext context,
    String message,
    Color color,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Duration _calculateNextInterval(ReviewDifficulty difficulty) {
    switch (difficulty) {
      case ReviewDifficulty.keepPracticing:
        return SpacedRepetitionConfig.keepPracticingInterval; // 1 day
      case ReviewDifficulty.gotIt:
        return SpacedRepetitionConfig.gotItInterval; // 7 days
    }
  }

  Future<void> _updateWordStatus(
    WidgetRef ref,
    VocabularyItem item,
    ReviewDifficulty difficulty,
  ) async {
    try {
      final dataService = await ref.read(localDataServiceProvider.future);
      final currentPlugin = ref.read(currentLanguagePluginProvider);

      if (currentPlugin == null) return;

      final progressKey = currentPlugin.getProgressKey(item.id);
      final wordProgressMap = dataService.getWordProgress();

      if (difficulty == ReviewDifficulty.gotIt) {
        // Check if this word has had multiple successful reviews
        final reviewSessions = await ref.read(reviewSessionsProvider.future);
        final successfulReviews = reviewSessions
            .where(
              (session) =>
                  session.wordId == item.id &&
                  session.difficulty == ReviewDifficulty.gotIt,
            )
            .length;

        if (successfulReviews >= 2) {
          // Including this one = 3 total successful reviews
          // Mark as mastered after 3 successful reviews
          wordProgressMap[progressKey] = 'mastered';
        } else {
          // Mark as reviewing (scheduled for future review)
          wordProgressMap[progressKey] = 'reviewing';
        }
      } else {
        // Keep practicing - remains difficult for immediate review
        wordProgressMap[progressKey] = 'difficult';
      }

      await dataService.setWordProgress(wordProgressMap);
    } catch (e) {
      // Silent fail - don't break the review experience
    }
  }

  Future<void> _saveReviewSession(
    WidgetRef ref,
    VocabularyItem item,
    ReviewDifficulty difficulty,
    Duration nextInterval,
  ) async {
    try {
      final dataService = await ref.read(localDataServiceProvider.future);

      final session = ReviewSession(
        wordId: item.id,
        reviewDate: DateTime.now(),
        nextInterval: nextInterval,
        difficulty: difficulty,
      );

      // Save to quiz results with a specific key pattern
      final sessionKey =
          'review_${item.id}_${DateTime.now().millisecondsSinceEpoch}';
      await dataService.saveQuizResult(sessionKey, session.toJson());

      // Record study session
      await dataService.recordStudySession();
    } catch (e) {
      // Silent fail - don't break the review experience
    }
  }

  void _resetReview(WidgetRef ref) {
    ref.read(currentReviewIndexProvider.notifier).state = 0;
    ref.read(isReviewCardFlippedProvider.notifier).state = false;
    ref.invalidate(reviewQueueProvider);
  }
}

/// Review card widget specifically designed for spaced repetition
class ReviewCardWidget extends ConsumerWidget {
  const ReviewCardWidget({
    required this.vocabularyItem,
    required this.onTap,
    super.key,
  });

  final VocabularyItem vocabularyItem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFlipped = ref.watch(isReviewCardFlippedProvider);
    final currentPlugin = ref.watch(currentLanguagePluginProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        transitionBuilder: (child, animation) {
          final rotateAnimation = Tween<double>(
            begin: 0,
            end: 1,
          ).animate(animation);

          return AnimatedBuilder(
            animation: rotateAnimation,
            child: child,
            builder: (context, child) {
              final isShowingFront = rotateAnimation.value < 0.5;
              if (isShowingFront) {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(rotateAnimation.value * 3.14159),
                  child: child,
                );
              } else {
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY((1 - rotateAnimation.value) * 3.14159),
                  child: child,
                );
              }
            },
          );
        },
        child: Card(
          key: ValueKey(isFlipped ? 'back' : 'front'),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isFlipped
                    ? [
                        colorScheme.secondaryContainer,
                        colorScheme.secondaryContainer.withValues(alpha: 0.7),
                      ]
                    : [colorScheme.surface, colorScheme.surfaceContainerLow],
              ),
              border: Border.all(
                color: isFlipped
                    ? colorScheme.secondary.withValues(alpha: 0.3)
                    : colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isFlipped)
                    ..._buildFrontContent(theme, currentPlugin)
                  else
                    ..._buildBackContent(theme, currentPlugin),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFrontContent(ThemeData theme, LanguagePlugin? plugin) {
    return [
      Icon(
        Icons.psychology,
        size: 48,
        color: theme.colorScheme.primary.withValues(alpha: 0.7),
      ),
      const SizedBox(height: 24),
      Text(
        plugin?.formatTerm(vocabularyItem) ?? vocabularyItem.term,
        style: theme.textTheme.displayMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Tap to reveal meaning',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      const Spacer(),
      _buildSwipeInstructions(theme),
    ];
  }

  List<Widget> _buildBackContent(ThemeData theme, LanguagePlugin? plugin) {
    return [
      Icon(
        Icons.lightbulb,
        size: 48,
        color: theme.colorScheme.secondary.withValues(alpha: 0.7),
      ),
      const SizedBox(height: 24),
      Text(
        plugin?.formatTranslation(vocabularyItem) ?? vocabularyItem.translation,
        style: theme.textTheme.displayMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
      if (vocabularyItem.exampleTerm != null ||
          vocabularyItem.exampleTranslation != null) ...[
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            plugin?.formatExample(vocabularyItem) ??
                (vocabularyItem.exampleTerm != null &&
                        vocabularyItem.exampleTranslation != null
                    ? '${vocabularyItem.exampleTerm} — ${vocabularyItem.exampleTranslation}'
                    : ''),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
      const Spacer(),
      _buildSwipeInstructions(theme),
    ];
  }

  Widget _buildSwipeInstructions(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Icon(
              Icons.swipe_left,
              color: Colors.orange.withValues(alpha: 0.6),
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              'Keep practicing',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        Column(
          children: [
            Icon(
              Icons.swipe_right,
              color: Colors.green.withValues(alpha: 0.6),
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              'Got it!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.green.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
