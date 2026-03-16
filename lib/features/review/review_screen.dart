// ignore_for_file: public_member_api_docs
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:octo_vocab/core/language/language_plugin.dart';
import 'package:octo_vocab/core/language/models/vocabulary_item.dart';
import 'package:octo_vocab/core/language/widgets/language_selector.dart';
import 'package:octo_vocab/core/models/word_interaction.dart';
import 'package:octo_vocab/core/providers/language_providers.dart';
import 'package:octo_vocab/core/providers/progress_providers.dart';
import 'package:octo_vocab/core/providers/review_providers.dart';
import 'package:octo_vocab/core/providers/storage_providers.dart';
import 'package:octo_vocab/core/services/error_handler.dart';
import 'package:octo_vocab/core/widgets/error_view.dart';

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
      error: (e, st) {
        ErrorHandler.logError('Review Queue', e, st);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Review'),
            automaticallyImplyLeading: false,
            actions: const [LanguageSelectorAction(), SizedBox(width: 8)],
          ),
          body: ErrorView(
            message: ErrorHandler.getUserMessage(e),
            onRetry: () => ref.invalidate(reviewQueueProvider),
          ),
        );
      },
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
      final dataService = ref.read(localDataServiceProvider);
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
      final dataService = ref.read(localDataServiceProvider);
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
      final dataService = ref.read(localDataServiceProvider);

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
