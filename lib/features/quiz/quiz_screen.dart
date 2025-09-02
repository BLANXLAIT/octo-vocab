// ignore_for_file: public_member_api_docs
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_saas_template/core/animations/celebration_overlay.dart';
import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/word.dart';
import 'package:flutter_saas_template/features/quiz/animated_quiz_option.dart';

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
final showCelebrationProvider = StateProvider.autoDispose<bool>((ref) => false);

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(quizVocabProvider);
    final index = ref.watch(quizIndexProvider);
    final selected = ref.watch(selectedAnswerProvider);
    final showResult = ref.watch(showResultProvider);
    final showCelebration = ref.watch(showCelebrationProvider);

    return wordsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          automaticallyImplyLeading: false,
          actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          automaticallyImplyLeading: false,
          actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
        ),
        body: Center(child: Text('Failed to load vocab: $e')),
      ),
      data: (words) {
        if (words.length < 4) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Quiz'),
              automaticallyImplyLeading: false,
              actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
            ),
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

        return CelebrationOverlay(
          isVisible: showCelebration,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Quiz'),
              automaticallyImplyLeading: false,
              actions: [
                const LanguageSwitcherAction(),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${i + 1}/${words.length}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Question section with enhanced styling
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'What is the English translation?',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.8),
                              ),
                        ),
                        const SizedBox(height: 16),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style:
                              Theme.of(
                                context,
                              ).textTheme.displaySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ) ??
                              const TextStyle(),
                          child: Text(
                            current.latin,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Answer options with animations
                  Expanded(
                    child: ListView.builder(
                      itemCount: options.length,
                      itemBuilder: (context, idx) {
                        final opt = options[idx];
                        final isSelected = selected == opt;
                        final isCorrect = opt == current.english;

                        return AnimatedQuizOption(
                          option: opt,
                          isSelected: isSelected,
                          isCorrect: isCorrect,
                          showResult: showResult,
                          index: idx,
                          onTap: () {
                            ref.read(selectedAnswerProvider.notifier).state =
                                opt;
                          },
                        );
                      },
                    ),
                  ),
                  // Flexible spacer to push buttons to bottom
                  const SizedBox(height: 8),
                  // Single row with all action buttons
                  Row(
                    children: [
                      // Clear button (smaller)
                      OutlinedButton(
                        onPressed: showResult
                            ? null
                            : () {
                                ref
                                        .read(selectedAnswerProvider.notifier)
                                        .state =
                                    null;
                                ref.read(showResultProvider.notifier).state =
                                    false;
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          minimumSize: const Size(60, 48),
                        ),
                        child: const Text('Clear'),
                      ),
                      const SizedBox(width: 12),
                      // Check Answer / Next Question button (takes remaining space)
                      Expanded(
                        child: FilledButton(
                          onPressed: selected == null && !showResult
                              ? null
                              : showResult
                                  ? () {
                                      // Next question
                                      ref.read(quizIndexProvider.notifier).state =
                                          index + 1;
                                      ref
                                              .read(selectedAnswerProvider.notifier)
                                              .state =
                                          null;
                                      ref.read(showResultProvider.notifier).state =
                                          false;
                                      ref
                                              .read(
                                                showCelebrationProvider.notifier,
                                              )
                                              .state =
                                          false;
                                    }
                                  : () {
                                      // Check answer
                                      ref.read(showResultProvider.notifier).state =
                                          true;
                                      // Show celebration if correct
                                      if (isCorrect) {
                                        ref
                                                .read(
                                                  showCelebrationProvider.notifier,
                                                )
                                                .state =
                                            true;
                                        Future.delayed(
                                          const Duration(seconds: 2),
                                          () {
                                            if (ref.context.mounted) {
                                              ref
                                                      .read(
                                                        showCelebrationProvider
                                                            .notifier,
                                                      )
                                                      .state =
                                                  false;
                                            }
                                          },
                                        );
                                      }
                                    },
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (showResult && isCorrect)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                  size: 20,
                                )
                              else if (showResult && !isCorrect)
                                const Icon(
                                  Icons.cancel,
                                  color: Colors.red,
                                  size: 20,
                                ),
                              if (showResult) const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  showResult
                                      ? (isCorrect
                                            ? 'Correct! Next Question'
                                            : 'Try Again - Next')
                                      : 'Check Answer',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (showResult) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.navigate_next, size: 20),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
