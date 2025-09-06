// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/models/word.dart';
import 'package:flutter_saas_template/core/navigation/adaptive_scaffold.dart';
import 'package:flutter_saas_template/core/providers/study_config_providers.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';

/// Loads only words marked as difficult for focused review
final difficultWordsProvider = FutureProvider.autoDispose<List<Word>>((
  ref,
) async {
  final currentConfig = ref.watch(currentLanguageConfigProvider);

  // If no configuration is available, return empty list
  if (currentConfig == null || !currentConfig.isEnabled) {
    return <Word>[];
  }

  final lang = currentConfig.language;
  final level = currentConfig.level;

  // Load ALL vocabulary sets for the level
  final allWords = <Word>[];
  final vocabularySets = VocabularySets.getSetsForLevel(level);

  if (vocabularySets.isEmpty) {
    // Fallback to legacy format if no leveled sets available
    try {
      final path = vocabAssetPath(lang, 'grade8_set1.json');
      final jsonStr = await rootBundle.loadString(path);
      allWords.addAll(Word.listFromJsonString(jsonStr));
    } catch (e) {
      // If grade8_set1 doesn't exist, return empty list
      return <Word>[];
    }
  } else {
    // Load all vocabulary sets for this level
    for (final vocabSet in vocabularySets) {
      try {
        final path = vocabularySetAssetPath(lang, vocabSet);
        final jsonStr = await rootBundle.loadString(path);
        allWords.addAll(Word.listFromJsonString(jsonStr));
      } catch (e) {
        // Skip sets that don't exist for this language
        continue;
      }
    }
  }

  // Get difficult word IDs from local storage for the current language
  final dataService = await ref.read(localDataServiceProvider.future);
  final difficultWordIds = dataService.getDifficultWordsForLanguage(lang.name);

  // Filter to only include difficult words
  return allWords.where((word) => difficultWordIds.contains(word.id)).toList();
});

/// Card controller for review section
final reviewCardControllerProvider = Provider.autoDispose<CardSwiperController>(
  (ref) => CardSwiperController(),
);

/// Current review card index
final currentReviewIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Whether the current review card is flipped
final isReviewCardFlippedProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final difficultWordsAsync = ref.watch(difficultWordsProvider);
    final currentIndex = ref.watch(currentReviewIndexProvider);
    final controller = ref.watch(reviewCardControllerProvider);

    return difficultWordsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Review'),
          automaticallyImplyLeading: false,
          actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(
          title: const Text('Review'),
          automaticallyImplyLeading: false,
          actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
        ),
        body: Center(child: Text('Failed to load difficult words: $e')),
      ),
      data: (difficultWords) {
        if (difficultWords.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Review'),
              automaticallyImplyLeading: false,
              actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
            ),
            body: _buildEmptyState(context, ref),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Review'),
            automaticallyImplyLeading: false,
            actions: [
              const LanguageSwitcherAction(),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text('${currentIndex + 1}/${difficultWords.length}'),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.psychology,
                        size: 18,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Difficult Words • ${difficultWords.length} to review',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: difficultWords.isNotEmpty
                      ? CardSwiper(
                          controller: controller,
                          cardsCount: difficultWords.length,
                          numberOfCardsDisplayed: 1,
                          onSwipe: (previousIndex, currentIndex, direction) {
                            // Handle swipe logic for difficult words
                            HapticFeedback.lightImpact();

                            // Get the word that was just swiped
                            final swipedWord = difficultWords[previousIndex];

                            // Track word mastery (async but don't block UI)
                            _trackWordMastery(
                              context,
                              ref,
                              swipedWord,
                              direction,
                            );

                            // Reset flip state for next card
                            ref
                                    .read(isReviewCardFlippedProvider.notifier)
                                    .state =
                                false;

                            // Update current index
                            if (currentIndex != null) {
                              ref
                                      .read(currentReviewIndexProvider.notifier)
                                      .state =
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
                                final word = difficultWords[index];
                                return ReviewFlashcardWidget(
                                  word: word,
                                  onTap: () {
                                    ref
                                        .read(
                                          isReviewCardFlippedProvider.notifier,
                                        )
                                        .state = !ref.read(
                                      isReviewCardFlippedProvider,
                                    );
                                  },
                                );
                              },
                        )
                      : const Center(child: Text('No cards to review')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, size: 64, color: Colors.green.shade400),
            const SizedBox(height: 24),
            Text(
              'No Difficult Words!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Great job! You have not marked any words as difficult yet.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Words you swipe left (Unknown) in Learn or get wrong in Quiz will appear here for focused practice.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                ref.read(navigationIndexProvider.notifier).state = 0;
              },
              icon: const Icon(Icons.school),
              label: const Text('Start Learning'),
            ),
          ],
        ),
      ),
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

  Future<void> _trackWordMastery(
    BuildContext context,
    WidgetRef ref,
    Word word,
    CardSwiperDirection direction,
  ) async {
    try {
      final dataService = await ref.read(localDataServiceProvider.future);
      final currentConfig = ref.read(currentLanguageConfigProvider);

      if (!context.mounted || currentConfig == null) return;

      final languageName = currentConfig.language.name;

      if (direction == CardSwiperDirection.right) {
        // Mastered - remove from difficult words for current language
        await dataService.markWordAsKnownForLanguage(word.id, languageName);
        if (!context.mounted) return;
        _showFeedbackSnackBar(context, 'Mastered! ✨', Colors.green);
        // Refresh the provider to update the list
        ref.invalidate(difficultWordsProvider);
      } else if (direction == CardSwiperDirection.left) {
        // Still difficult - keep in review
        _showFeedbackSnackBar(context, 'Still learning 📚', Colors.orange);
      }
    } catch (e) {
      // Silent fail - don't break the learning experience
      if (!context.mounted) return;

      if (direction == CardSwiperDirection.right) {
        _showFeedbackSnackBar(context, 'Mastered! ✨', Colors.green);
      } else if (direction == CardSwiperDirection.left) {
        _showFeedbackSnackBar(context, 'Still learning 📚', Colors.orange);
      }
    }
  }
}

/// A flashcard widget optimized for review sessions
class ReviewFlashcardWidget extends ConsumerWidget {
  const ReviewFlashcardWidget({
    required this.word,
    required this.onTap,
    super.key,
  });

  final Word word;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFlipped = ref.watch(isReviewCardFlippedProvider);
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
                colors: [
                  colorScheme.surface,
                  Colors.orange.shade50.withValues(alpha: 0.3),
                ],
              ),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Difficulty indicator
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.psychology,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Difficult Word',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (!isFlipped)
                    ..._buildFrontContent(theme)
                  else
                    ..._buildBackContent(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFrontContent(ThemeData theme) {
    return [
      Icon(Icons.translate, size: 48, color: Colors.orange.shade700),
      const SizedBox(height: 24),
      Text(
        word.latin,
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
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Tap to reveal meaning',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.orange.shade700,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
      const Spacer(),
      Row(
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
                'Still Learning',
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
                'Mastered',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildBackContent(ThemeData theme) {
    return [
      Icon(Icons.lightbulb, size: 48, color: Colors.orange.shade700),
      const SizedBox(height: 24),
      Text(
        word.english,
        style: theme.textTheme.displayMedium?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
      if (word.exampleLatin != null || word.exampleEnglish != null) ...[
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (word.exampleLatin != null)
                Text(
                  '"${word.exampleLatin}"',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.orange.shade800,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (word.exampleLatin != null && word.exampleEnglish != null)
                const SizedBox(height: 8),
              if (word.exampleEnglish != null)
                Text(
                  '— ${word.exampleEnglish}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ],
      const Spacer(),
      Row(
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
                'Still Learning',
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
                'Mastered',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.green.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    ];
  }
}
