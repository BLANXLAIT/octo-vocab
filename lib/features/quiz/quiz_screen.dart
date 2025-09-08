// ignore_for_file: public_member_api_docs
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_saas_template/core/language/language_registry.dart';
import 'package:flutter_saas_template/core/language/models/vocabulary_item.dart';
import 'package:flutter_saas_template/core/language/widgets/language_selector.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';
import 'package:flutter_saas_template/features/quiz/animated_quiz_option.dart';

/// Quiz state management
final currentQuestionIndexProvider = StateProvider.autoDispose<int>((ref) => 0);
final selectedAnswerProvider = StateProvider.autoDispose<int?>((ref) => null);
final isAnswerSubmittedProvider = StateProvider.autoDispose<bool>((ref) => false);
final quizResultsProvider = StateProvider.autoDispose<List<bool>>((ref) => []);

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabularyAsync = ref.watch(vocabularyProvider);
    final currentQuestionIndex = ref.watch(currentQuestionIndexProvider);
    final quizResults = ref.watch(quizResultsProvider);

    return vocabularyAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          automaticallyImplyLeading: false,
          actions: const [
            LanguageSelectorAction(),
            SizedBox(width: 8),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          automaticallyImplyLeading: false,
          actions: const [
            LanguageSelectorAction(),
            SizedBox(width: 8),
          ],
        ),
        body: Center(child: Text('Failed to load quiz: $e')),
      ),
      data: (vocabulary) {
        if (vocabulary.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Quiz'),
              automaticallyImplyLeading: false,
              actions: const [
                LanguageSelectorAction(),
                SizedBox(width: 8),
              ],
            ),
            body: const Center(child: Text('No vocabulary found for quiz')),
          );
        }

        // Show results if quiz is complete
        if (currentQuestionIndex >= vocabulary.length) {
          return _buildResultsScreen(context, ref, quizResults, vocabulary.length);
        }

        final currentItem = vocabulary[currentQuestionIndex];
        final wrongAnswers = _generateWrongAnswers(vocabulary, currentItem);
        final allAnswers = [currentItem.translation, ...wrongAnswers]..shuffle();
        final correctAnswerIndex = allAnswers.indexOf(currentItem.translation);

        return Scaffold(
          appBar: AppBar(
            title: Text('Quiz ${currentQuestionIndex + 1}/${vocabulary.length}'),
            automaticallyImplyLeading: false,
            actions: [
              const LanguageSelectorAction(),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: Text(
                    'Score: ${quizResults.where((r) => r).length}/${quizResults.length}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question Card
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Consumer(
                          builder: (context, ref, _) {
                            final currentPlugin = ref.watch(currentLanguagePluginProvider);
                            return Icon(
                              currentPlugin?.language.icon ?? Icons.quiz,
                              size: 48,
                              color: currentPlugin?.language.color ?? Theme.of(context).colorScheme.primary,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'What does this mean?',
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, _) {
                            final currentPlugin = ref.watch(currentLanguagePluginProvider);
                            return Text(
                              currentPlugin?.formatTerm(currentItem) ?? currentItem.term,
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: currentPlugin?.language.color ?? Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Answer Options
                Expanded(
                  child: ListView.builder(
                    itemCount: allAnswers.length,
                    itemBuilder: (context, index) {
                      final selectedAnswer = ref.watch(selectedAnswerProvider);
                      final isAnswerSubmitted = ref.watch(isAnswerSubmittedProvider);
                      
                      return AnimatedQuizOption(
                        option: allAnswers[index],
                        isSelected: selectedAnswer == index,
                        isCorrect: index == correctAnswerIndex,
                        showResult: isAnswerSubmitted,
                        onTap: () => _handleAnswerSelection(context, ref, index, correctAnswerIndex),
                        index: index,
                      );
                    },
                  ),
                ),
                // Next Button
                const SizedBox(height: 16),
                Consumer(
                  builder: (context, ref, _) {
                    final isAnswerSubmitted = ref.watch(isAnswerSubmittedProvider);
                    return ElevatedButton(
                      onPressed: isAnswerSubmitted
                          ? () => _handleNextQuestion(context, ref, vocabulary.length)
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        currentQuestionIndex == vocabulary.length - 1 ? 'Finish Quiz' : 'Next Question',
                        style: const TextStyle(fontSize: 16),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultsScreen(BuildContext context, WidgetRef ref, List<bool> results, int totalQuestions) {
    final correctAnswers = results.where((r) => r).length;
    final percentage = (correctAnswers / totalQuestions * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
        actions: const [
          LanguageSelectorAction(),
          SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      percentage >= 80 ? Icons.emoji_events : Icons.thumb_up,
                      size: 64,
                      color: percentage >= 80 ? Colors.amber : Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quiz Complete!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$correctAnswers / $totalQuestions',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '$percentage% Correct',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _getEncouragingMessage(percentage),
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => _resetQuiz(ref),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Take Quiz Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAnswerSelection(BuildContext context, WidgetRef ref, int selectedIndex, int correctIndex) {
    final isAnswerSubmitted = ref.read(isAnswerSubmittedProvider);
    if (isAnswerSubmitted) return;

    // Set selected answer and submit
    ref.read(selectedAnswerProvider.notifier).state = selectedIndex;
    ref.read(isAnswerSubmittedProvider.notifier).state = true;

    // Update results
    final isCorrect = selectedIndex == correctIndex;
    final currentResults = ref.read(quizResultsProvider);
    ref.read(quizResultsProvider.notifier).state = [...currentResults, isCorrect];

    // Haptic feedback
    HapticFeedback.selectionClick();

    // Save progress
    _saveQuizProgress(context, ref, isCorrect);
  }

  void _handleNextQuestion(BuildContext context, WidgetRef ref, int totalQuestions) {
    final currentIndex = ref.read(currentQuestionIndexProvider);
    
    if (currentIndex < totalQuestions - 1) {
      // Move to next question
      ref.read(currentQuestionIndexProvider.notifier).state = currentIndex + 1;
      ref.read(selectedAnswerProvider.notifier).state = null;
      ref.read(isAnswerSubmittedProvider.notifier).state = false;
    } else {
      // Quiz complete - move to results
      ref.read(currentQuestionIndexProvider.notifier).state = totalQuestions;
    }

    HapticFeedback.lightImpact();
  }

  void _resetQuiz(WidgetRef ref) {
    ref.read(currentQuestionIndexProvider.notifier).state = 0;
    ref.read(selectedAnswerProvider.notifier).state = null;
    ref.read(isAnswerSubmittedProvider.notifier).state = false;
    ref.read(quizResultsProvider.notifier).state = [];
  }

  Future<void> _saveQuizProgress(BuildContext context, WidgetRef ref, bool isCorrect) async {
    try {
      final dataService = await ref.read(localDataServiceProvider.future);
      await dataService.recordStudySession();
    } catch (e) {
      // Silent fail - don't break the quiz experience
    }
  }

  List<String> _generateWrongAnswers(List<VocabularyItem> allItems, VocabularyItem correctItem) {
    final wrongAnswers = allItems
        .where((item) => item.id != correctItem.id)
        .map((item) => item.translation)
        .toList();
    
    wrongAnswers.shuffle();
    return wrongAnswers.take(3).toList();
  }

  String _getEncouragingMessage(int percentage) {
    if (percentage >= 90) return 'Outstanding! You\'re mastering this language! 🏆';
    if (percentage >= 80) return 'Excellent work! Keep it up! 🌟';
    if (percentage >= 70) return 'Good job! You\'re making great progress! 👍';
    if (percentage >= 60) return 'Nice effort! Keep studying and you\'ll improve! 📚';
    return 'Don\'t give up! Practice makes perfect! 💪';
  }
}