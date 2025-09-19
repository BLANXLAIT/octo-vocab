// ignore_for_file: public_member_api_docs
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
import 'package:octo_vocab/features/review/review_screen.dart';

/// Learning queue provider - filters out known/mastered words and respects timing constraints
final learningQueueProvider = FutureProvider.autoDispose<List<VocabularyItem>>((
  ref,
) async {
  final vocabulary = await ref.watch(vocabularyProvider.future);
  final wordProgress = await ref.watch(wordProgressProvider.future);
  final dataService = await ref.watch(localDataServiceProvider.future);
  final currentPlugin = ref.watch(currentLanguagePluginProvider);

  debugPrint('📚 LEARNING DEBUG: Loading learning queue...');
  debugPrint('📚 LEARNING DEBUG: Total vocabulary items: ${vocabulary.length}');
  debugPrint(
    '📚 LEARNING DEBUG: Word progress entries: ${wordProgress.length}',
  );

  if (currentPlugin == null) {
    debugPrint(
      '📚 LEARNING DEBUG: No current language plugin, returning empty queue',
    );
    return [];
  }

  // Get timing-available words based on interaction history
  final allWordIds = vocabulary.map((item) => item.id).toList();
  final availableWordIds = dataService.getAvailableWords(allWordIds);

  debugPrint(
    '📚 LEARNING DEBUG: ${availableWordIds.length}/${allWordIds.length} words available based on timing constraints',
  );

  final learningQueue = <VocabularyItem>[];

  for (final item in vocabulary) {
    final progressKey = currentPlugin.getProgressKey(item.id);
    final status = wordProgress[progressKey];

    debugPrint(
      '📚 LEARNING DEBUG: Item "${item.term}" (${item.id}) -> key: "$progressKey" -> status: "$status"',
    );

    // Skip words that are already known or mastered
    if (status == 'known' || status == 'mastered') {
      debugPrint(
        '📚 LEARNING DEBUG: Skipping "${item.term}" - already learned (status: $status)',
      );
      continue;
    }

    // Check timing constraints - skip if word was seen too recently
    if (!availableWordIds.contains(item.id)) {
      debugPrint(
        '📚 LEARNING DEBUG: Skipping "${item.term}" - timing constraint not met',
      );
      continue;
    }

    // Include words that are new (no status), difficult, or reviewing
    // This gives users a chance to learn new words and re-practice difficult ones
    learningQueue.add(item);
  }

  // Shuffle for varied learning order
  learningQueue.shuffle();

  debugPrint(
    '📚 LEARNING DEBUG: Final learning queue contains ${learningQueue.length} words',
  );
  for (final item in learningQueue.take(5)) {
    // Show first 5 for brevity
    debugPrint('📚 LEARNING DEBUG: -> "${item.term}" will appear in Learn tab');
  }
  if (learningQueue.length > 5) {
    debugPrint(
      '📚 LEARNING DEBUG: ... and ${learningQueue.length - 5} more words',
    );
  }

  return learningQueue;
});

/// Card controller for programmatic control
final cardControllerProvider = Provider.autoDispose<CardSwiperController>(
  (ref) => CardSwiperController(),
);

/// Current flashcard index
final currentCardIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Whether the current card is flipped to show back
final isCardFlippedProvider = StateProvider.autoDispose<bool>((ref) => false);

class FlashcardsScreen extends ConsumerWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabularyAsync = ref.watch(learningQueueProvider);
    final currentIndex = ref.watch(currentCardIndexProvider);
    final controller = ref.watch(cardControllerProvider);

    return vocabularyAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Learn'),
          automaticallyImplyLeading: false,
          actions: const [LanguageSelectorAction(), SizedBox(width: 8)],
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(
          title: const Text('Learn'),
          automaticallyImplyLeading: false,
          actions: const [LanguageSelectorAction(), SizedBox(width: 8)],
        ),
        body: Center(child: Text('Failed to load vocabulary: $e')),
      ),
      data: (vocabulary) {
        if (vocabulary.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Learn'),
              automaticallyImplyLeading: false,
              actions: const [LanguageSelectorAction(), SizedBox(width: 8)],
            ),
            body: const Center(
              child: Text(
                'Great! You have learned all available words.\nCheck the Review tab to practice them.',
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Learn'),
            automaticallyImplyLeading: false,
            actions: [
              const LanguageSelectorAction(),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text('${currentIndex + 1}/${vocabulary.length}'),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CardSwiper(
              controller: controller,
              cardsCount: vocabulary.length,
              numberOfCardsDisplayed: 1,
              onSwipe: (previousIndex, currentIndex, direction) {
                // Handle swipe logic
                HapticFeedback.lightImpact();

                // Get the word that was just swiped
                final swipedItem = vocabulary[previousIndex];

                // Track word difficulty based on swipe direction
                _trackWordDifficulty(context, ref, swipedItem, direction);

                // Reset flip state for next card
                ref.read(isCardFlippedProvider.notifier).state = false;

                // Update current index
                if (currentIndex != null) {
                  ref.read(currentCardIndexProvider.notifier).state =
                      currentIndex;
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
                    final item = vocabulary[index];
                    return FlashcardWidget(
                      vocabularyItem: item,
                      onTap: () {
                        ref.read(isCardFlippedProvider.notifier).state = !ref
                            .read(isCardFlippedProvider);
                      },
                    );
                  },
            ),
          ),
        );
      },
    );
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

  Future<void> _trackWordDifficulty(
    BuildContext context,
    WidgetRef ref,
    VocabularyItem item,
    CardSwiperDirection direction,
  ) async {
    try {
      final dataService = await ref.read(localDataServiceProvider.future);
      final currentPlugin = ref.read(currentLanguagePluginProvider);

      if (!context.mounted || currentPlugin == null) return;

      final progressKey = currentPlugin.getProgressKey(item.id);
      final wordProgressMap = dataService.getWordProgress();

      if (direction == CardSwiperDirection.right) {
        // Known - mark as known and record interaction
        wordProgressMap[progressKey] = 'known';
        await dataService.setWordProgress(wordProgressMap);

        // Record word interaction for timing constraints
        await dataService.recordWordInteraction(item.id, InteractionType.flashcardKnown);

        // Invalidate providers so review screen updates immediately
        ref.invalidate(wordProgressProvider);
        ref.invalidate(reviewQueueProvider);
        ref.invalidate(learningQueueProvider); // Also invalidate learning queue

        if (!context.mounted) return;
        _showFeedbackSnackBar(context, 'Known! ✅', Colors.green);
      } else if (direction == CardSwiperDirection.left) {
        // Unknown - mark as difficult and record interaction
        wordProgressMap[progressKey] = 'difficult';
        await dataService.setWordProgress(wordProgressMap);

        // Record word interaction for timing constraints
        await dataService.recordWordInteraction(item.id, InteractionType.flashcardUnknown);

        // CRITICAL: Invalidate providers so review screen shows new difficult words immediately
        // This is the same fix we implemented for the reset functionality
        ref.invalidate(wordProgressProvider);
        ref.invalidate(reviewQueueProvider);
        ref.invalidate(learningQueueProvider); // Also invalidate learning queue

        if (!context.mounted) return;
        _showFeedbackSnackBar(context, 'Will review later! 📚', Colors.orange);
      }
    } catch (e) {
      // Silent fail - don't break the learning experience
      if (!context.mounted) return;

      if (direction == CardSwiperDirection.right) {
        _showFeedbackSnackBar(context, 'Known! ✅', Colors.green);
      } else if (direction == CardSwiperDirection.left) {
        _showFeedbackSnackBar(context, 'Will review later! 📚', Colors.orange);
      }
    }
  }
}

/// A flashcard widget that works with the new modular VocabularyItem
class FlashcardWidget extends ConsumerWidget {
  const FlashcardWidget({
    required this.vocabularyItem,
    required this.onTap,
    super.key,
  });

  final VocabularyItem vocabularyItem;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFlipped = ref.watch(isCardFlippedProvider);
    final currentPlugin = ref.watch(currentLanguagePluginProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (currentPlugin == null) {
      return const Center(child: Text('No language plugin available'));
    }

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
                colors: [colorScheme.surface, colorScheme.surfaceContainerLow],
              ),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
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
    if (plugin == null) {
      return [
        Icon(
          Icons.language,
          size: 48,
          color: theme.colorScheme.outline.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 24),
        Text(
          vocabularyItem.term,
          style: theme.textTheme.displayMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ];
    }

    return [
      Icon(
        plugin.language.icon,
        size: 48,
        color: plugin.language.color.withValues(alpha: 0.7),
      ),
      const SizedBox(height: 24),
      Text(
        plugin.formatTerm(vocabularyItem),
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
              color: Colors.red.withValues(alpha: 0.6),
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              'Unknown',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red.withValues(alpha: 0.6),
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
              'Known',
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
