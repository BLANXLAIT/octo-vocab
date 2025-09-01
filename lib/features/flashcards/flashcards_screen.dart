// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/word.dart';

/// Loads the seed Grade 8 Latin vocab set from assets.
final vocabSetProvider = FutureProvider.autoDispose<List<Word>>((ref) async {
  final lang = ref.watch(appLanguageProvider);
  final path = vocabAssetPath(lang, 'grade8_set1.json');
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
        appBar: AppBar(title: const Text('Flashcards')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: const Text('Flashcards')),
        body: Center(child: Text('Failed to load vocab: $e')),
      ),
      data: (words) {
        if (words.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Flashcards')),
            body: const Center(child: Text('No vocabulary found')),
          );
        }
        final i = index % words.length;
        final word = words[i];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Flashcards'),
            actions: [
              const LanguageSwitcherAction(),
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
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                showBack ? word.english : word.latin,
                                style: Theme.of(context).textTheme.displaySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              if (showBack &&
                                  (word.exampleLatin != null ||
                                      word.exampleEnglish != null))
                                Text(
                                  [
                                    if (word.exampleLatin != null)
                                      '“${word.exampleLatin}”',
                                    if (word.exampleEnglish != null)
                                      '— ${word.exampleEnglish}',
                                  ].join(' '),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                  textAlign: TextAlign.center,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.flip),
                      label: const Text('Flip'),
                      onPressed: () =>
                          ref.read(showBackProvider.notifier).state = !showBack,
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Unknown'),
                      onPressed: () {
                        ref.read(showBackProvider.notifier).state = false;
                        ref.read(flashcardIndexProvider.notifier).state =
                            index + 1;
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Known'),
                      onPressed: () {
                        ref.read(showBackProvider.notifier).state = false;
                        ref.read(flashcardIndexProvider.notifier).state =
                            index + 1;
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
