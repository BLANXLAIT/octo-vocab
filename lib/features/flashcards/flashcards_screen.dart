// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/language/vocabulary_selector.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/models/word.dart';
import 'package:flutter_saas_template/features/flashcards/animated_flashcard.dart';

/// Loads vocabulary based on current language and level selection
final vocabSetProvider = FutureProvider.autoDispose<List<Word>>((ref) async {
  final lang = ref.watch(appLanguageProvider);
  final level = ref.watch(vocabularyLevelProvider);

  // For now, use the first available set for the selected level
  final sets = VocabularySets.getSetsForLevel(level);
  if (sets.isEmpty) {
    // Fallback to legacy format if no leveled sets available
    final path = vocabAssetPath(lang, 'grade8_set1.json');
    final jsonStr = await rootBundle.loadString(path);
    return Word.listFromJsonString(jsonStr);
  }

  // Load the first set for the level
  final set = sets.first;
  final path = vocabularySetAssetPath(lang, set);
  final jsonStr = await rootBundle.loadString(path);
  return Word.listFromJsonString(jsonStr);
});

/// Current index in the flashcard session.
final flashcardIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Whether the back (English) is showing.
final showBackProvider = StateProvider.autoDispose<bool>((ref) => false);

class FlashcardsScreen extends ConsumerWidget {
  const FlashcardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(vocabSetProvider);
    final index = ref.watch(flashcardIndexProvider);
    final showBack = ref.watch(showBackProvider);

    return cardsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Learn'),
          automaticallyImplyLeading: false,
          actions: const [VocabularySelector(), SizedBox(width: 8)],
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(
          title: const Text('Learn'),
          automaticallyImplyLeading: false,
          actions: const [VocabularySelector(), SizedBox(width: 8)],
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
        final i = index % words.length;
        final word = words[i];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Learn'),
            automaticallyImplyLeading: false,
            actions: [
              const VocabularySelector(),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(child: Text('${i + 1}/${words.length}')),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 32),
                Expanded(
                  child: Center(
                    child: AnimatedFlashcard(
                      word: word,
                      showBack: showBack,
                      onFlip: () =>
                          ref.read(showBackProvider.notifier).state = !showBack,
                      onKnown: () {
                        ref.read(showBackProvider.notifier).state = false;
                        ref.read(flashcardIndexProvider.notifier).state =
                            index + 1;
                      },
                      onUnknown: () {
                        ref.read(showBackProvider.notifier).state = false;
                        ref.read(flashcardIndexProvider.notifier).state =
                            index + 1;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Enhanced action buttons with better styling
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FilledButton.tonal(
                      onPressed: () =>
                          ref.read(showBackProvider.notifier).state = !showBack,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.flip_to_back, size: 20),
                          const SizedBox(width: 8),
                          const Text('Flip Card'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () {
                        ref.read(showBackProvider.notifier).state = false;
                        ref.read(flashcardIndexProvider.notifier).state =
                            index + 1;
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.navigate_next, size: 20),
                          const SizedBox(width: 8),
                          const Text('Next Card'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
