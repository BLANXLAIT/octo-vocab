// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/word.dart';

/// Loads the seed Grade 8 Latin vocab set from assets.
final reviewVocabProvider = FutureProvider.autoDispose<List<Word>>((ref) async {
  final lang = ref.watch(appLanguageProvider);
  final path = vocabAssetPath(lang, 'grade8_set1.json');
  final jsonStr = await rootBundle.loadString(path);
  return Word.listFromJsonString(jsonStr);
});

/// Current index in the review session.
final reviewIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Whether the back (English) is showing.
final reviewShowBackProvider = StateProvider.autoDispose<bool>((ref) => false);

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(reviewVocabProvider);
    final index = ref.watch(reviewIndexProvider);
    final showBack = ref.watch(reviewShowBackProvider);

    return wordsAsync.when(
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
        body: Center(child: Text('Failed to load vocab: $e')),
      ),
      data: (words) {
        if (words.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Review'),
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
            title: const Text('Review'),
            automaticallyImplyLeading: false,
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
                          ref.read(reviewShowBackProvider.notifier).state =
                              !showBack,
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                      ),
                      icon: const Icon(Icons.replay),
                      label: const Text('Again'),
                      onPressed: () {
                        // Simple session-only SRS placeholder:
                        // Just advance; a future version will reschedule.
                        ref.read(reviewShowBackProvider.notifier).state = false;
                        ref.read(reviewIndexProvider.notifier).state =
                            index + 1;
                      },
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Good'),
                      onPressed: () {
                        ref.read(reviewShowBackProvider.notifier).state = false;
                        ref.read(reviewIndexProvider.notifier).state =
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
