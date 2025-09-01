// ignore_for_file: public_member_api_docs
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/word.dart';

final quizVocabProvider = FutureProvider.autoDispose<List<Word>>((ref) async {
  final lang = ref.watch(appLanguageProvider);
  final path = vocabAssetPath(lang, 'grade8_set1.json');
  final jsonStr = await rootBundle.loadString(path);
  return Word.listFromJsonString(jsonStr);
});

final quizIndexProvider = StateProvider.autoDispose<int>((ref) => 0);
final selectedAnswerProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final showResultProvider = StateProvider.autoDispose<bool>((ref) => false);

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(quizVocabProvider);
    final index = ref.watch(quizIndexProvider);
    final selected = ref.watch(selectedAnswerProvider);
    final showResult = ref.watch(showResultProvider);

    return wordsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: Center(child: Text('Failed to load vocab: $e')),
      ),
      data: (words) {
        if (words.length < 4) {
          return Scaffold(
            appBar: AppBar(title: const Text('Quiz')),
            body: const Center(
              child: Text('Not enough words for a multiple-choice quiz.'),
            ),
          );
        }

        final i = index % words.length;
        final current = words[i];

        // Build 4 options: correct English + 3 distractors.
        final rng = Random(i); // stable order per index
        final pool = [...words]
          ..removeAt(i)
          ..shuffle(rng);
        final distractors = pool.take(3).map((w) => w.english).toList();
        final options = [...distractors, current.english]..shuffle(rng);

        final isCorrect = selected != null && selected == current.english;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Quiz'),
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
                const SizedBox(height: 8),
                Text(
                  'What is the English for:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  current.latin,
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: ListView.separated(
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final opt = options[idx];
                      final selectedThis = selected == opt;
                      Color? color;
                      if (showResult && selected != null) {
                        if (opt == current.english) color = Colors.green;
                        if (selectedThis && opt != current.english) {
                          color = Colors.red;
                        }
                      }
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: color ?? Colors.grey.shade300,
                          ),
                        ),
                        tileColor: color?.withValues(alpha: 0.08),
                        title: Text(opt),
                        onTap: showResult
                            ? null
                            : () =>
                                  ref
                                          .read(selectedAnswerProvider.notifier)
                                          .state =
                                      opt,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref.read(selectedAnswerProvider.notifier).state =
                              null;
                          ref.read(showResultProvider.notifier).state = false;
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: selected == null
                            ? null
                            : () =>
                                  ref.read(showResultProvider.notifier).state =
                                      true,
                        child: const Text('Check'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.navigate_next),
                  onPressed: showResult
                      ? () {
                          ref.read(quizIndexProvider.notifier).state =
                              index + 1;
                          ref.read(selectedAnswerProvider.notifier).state =
                              null;
                          ref.read(showResultProvider.notifier).state = false;
                        }
                      : null,
                  label: Text(
                    showResult
                        ? (isCorrect ? 'Next (Correct)' : 'Next (Incorrect)')
                        : 'Next',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
