// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/models/word.dart';
import 'package:flutter_saas_template/core/providers/study_config_providers.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';

/// Loads vocabulary based on current study configuration
final vocabSetProvider = FutureProvider.autoDispose<List<Word>>((ref) async {
  final currentConfig = ref.watch(currentLanguageConfigProvider);
  
  // If no configuration is available, return empty list
  if (currentConfig == null || !currentConfig.isEnabled) {
    return <Word>[];
  }

  final lang = currentConfig.language;
  final level = currentConfig.level;

  // Load ALL vocabulary sets for the selected level
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
  
  return allWords;
});

/// Card controller for programmatic control
final cardControllerProvider = Provider.autoDispose<CardSwiperController>((ref) => CardSwiperController());

/// Current flashcard index
final currentCardIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Whether the current card is flipped to show back
final isCardFlippedProvider = StateProvider.autoDispose<bool>((ref) => false);

class FlashcardsScreen extends ConsumerWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(vocabSetProvider);
    final currentIndex = ref.watch(currentCardIndexProvider);
    final controller = ref.watch(cardControllerProvider);

    return cardsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Learn'),
          automaticallyImplyLeading: false,
          actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(
          title: const Text('Learn'),
          automaticallyImplyLeading: false,
          actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
        ),
        body: Center(child: Text('Failed to load vocab: $e')),
      ),
      data: (words) {
        if (words.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Learn'),
              automaticallyImplyLeading: false,
              actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
            ),
            body: const Center(child: Text('No vocabulary found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Learn'),
            automaticallyImplyLeading: false,
            actions: [
              const LanguageSwitcherAction(),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(child: Text('${currentIndex + 1}/${words.length}')),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: CardSwiper(
              controller: controller,
              cardsCount: words.length,
              numberOfCardsDisplayed: 1,
              onSwipe: (previousIndex, currentIndex, direction) {
                // Handle swipe logic
                HapticFeedback.lightImpact();
                
                // Get the word that was just swiped
                final swipedWord = words[previousIndex];
                
                // Track word difficulty based on swipe direction (async but don't block UI)
                _trackWordDifficulty(context, ref, swipedWord, direction);
                
                // Reset flip state for next card
                ref.read(isCardFlippedProvider.notifier).state = false;
                
                // Update current index
                if (currentIndex != null) {
                  ref.read(currentCardIndexProvider.notifier).state = currentIndex;
                }
                
                return true;
              },
              cardBuilder: (context, index, horizontalThresholdPercentage, verticalThresholdPercentage) {
                final word = words[index];
                return FlashcardWidget(
                  word: word,
                  onTap: () {
                    ref.read(isCardFlippedProvider.notifier).state = !ref.read(isCardFlippedProvider);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showFeedbackSnackBar(BuildContext context, String message, Color color) {
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
    Word word,
    CardSwiperDirection direction,
  ) async {
    try {
      final dataService = await ref.read(localDataServiceProvider.future);
      final currentConfig = ref.read(currentLanguageConfigProvider);
      
      if (!context.mounted || currentConfig == null) return;
      
      final languageName = currentConfig.language.name;
      
      if (direction == CardSwiperDirection.right) {
        // Known - mark as known for current language
        await dataService.markWordAsKnownForLanguage(word.id, languageName);
        if (!context.mounted) return;
        _showFeedbackSnackBar(context, 'Known! ✅', Colors.green);
      } else if (direction == CardSwiperDirection.left) {
        // Unknown - mark as difficult for current language
        await dataService.markWordAsDifficultForLanguage(word.id, languageName);
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

/// A simplified flashcard widget for use with CardSwiper
class FlashcardWidget extends ConsumerWidget {
  const FlashcardWidget({
    required this.word,
    required this.onTap,
    super.key,
  });

  final Word word;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFlipped = ref.watch(isCardFlippedProvider);
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceContainerLow,
                ],
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
                  if (!isFlipped) ..._buildFrontContent(theme) else ..._buildBackContent(theme),
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
      Icon(
        Icons.translate,
        size: 48,
        color: theme.colorScheme.primary.withValues(alpha: 0.7),
      ),
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
      Row(
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
      ),
    ];
  }

  List<Widget> _buildBackContent(ThemeData theme) {
    return [
      Icon(
        Icons.lightbulb,
        size: 48,
        color: theme.colorScheme.secondary.withValues(alpha: 0.7),
      ),
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
            color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (word.exampleLatin != null)
                Text(
                  '"${word.exampleLatin}"',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
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
                    color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.8),
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
      ),
    ];
  }
}
