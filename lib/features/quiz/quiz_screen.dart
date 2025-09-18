// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:octo_vocab/core/language/language_registry.dart';
import 'package:octo_vocab/core/language/models/vocabulary_item.dart';
import 'package:octo_vocab/core/language/widgets/language_selector.dart';
import 'package:octo_vocab/core/services/local_data_service.dart';
import 'package:octo_vocab/features/quiz/animated_quiz_option.dart';

/// Quiz length options
enum QuizLength {
  quick5(5, 'Quick (5)'),
  short10(10, 'Short (10)'),
  medium15(15, 'Medium (15)'),
  full(0, 'Full');

  const QuizLength(this.count, this.displayName);
  final int count; // 0 means all available questions
  final String displayName;
}

/// Quiz length setting provider
final quizLengthProvider = StateNotifierProvider<QuizLengthNotifier, QuizLength>((ref) {
  return QuizLengthNotifier(ref);
});

class QuizLengthNotifier extends StateNotifier<QuizLength> {
  QuizLengthNotifier(this._ref) : super(QuizLength.short10) {
    _loadSetting();
  }

  final Ref _ref;
  static const String _settingKey = 'quiz_length';

  Future<void> _loadSetting() async {
    try {
      final dataService = await _ref.read(localDataServiceProvider.future);
      final settings = dataService.getAppSettings();
      final savedLength = settings[_settingKey] as String?;
      
      if (savedLength != null) {
        final quizLength = QuizLength.values.firstWhere(
          (e) => e.name == savedLength,
          orElse: () => QuizLength.short10,
        );
        state = quizLength;
      }
    } catch (e) {
      // Default to short10 if loading fails
    }
  }

  Future<void> setQuizLength(QuizLength length) async {
    state = length;
    try {
      final dataService = await _ref.read(localDataServiceProvider.future);
      final settings = dataService.getAppSettings();
      settings[_settingKey] = length.name;
      await dataService.saveAppSettings(settings);
    } catch (e) {
      // Silent fail
    }
  }
}

/// Quiz state management
final currentQuestionIndexProvider = StateProvider.autoDispose<int>((ref) => 0);
final selectedAnswerProvider = StateProvider.autoDispose<int?>((ref) => null);
final isAnswerSubmittedProvider = StateProvider.autoDispose<bool>((ref) => false);
final quizResultsProvider = StateProvider.autoDispose<List<bool>>((ref) => []);

/// Provider that returns quiz vocabulary based on length setting
final quizVocabularyProvider = Provider.autoDispose<List<VocabularyItem>>((ref) {
  final vocabulary = ref.watch(vocabularyProvider);
  final quizLength = ref.watch(quizLengthProvider);
  
  return vocabulary.when(
    data: (vocab) {
      if (vocab.isEmpty) return [];
      
      // Shuffle the vocabulary for randomness
      final shuffledVocab = [...vocab]..shuffle();
      
      // Return limited list based on quiz length setting
      if (quizLength.count == 0) {
        // Full quiz - return all
        return shuffledVocab;
      } else {
        // Limited quiz - return up to the specified count
        return shuffledVocab.take(quizLength.count).toList();
      }
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider that generates shuffled answers once per question
final shuffledAnswersProvider = Provider.autoDispose<List<String>>((ref) {
  final vocabulary = ref.watch(quizVocabularyProvider); // Use limited quiz vocabulary
  final currentQuestionIndex = ref.watch(currentQuestionIndexProvider);
  
  if (vocabulary.isEmpty || currentQuestionIndex >= vocabulary.length) {
    return <String>[];
  }
  
  final currentItem = vocabulary[currentQuestionIndex];
  final wrongAnswers = vocabulary
      .where((item) => item.id != currentItem.id)
      .map((item) => item.translation)
      .toList()
    ..shuffle();
  
  final allAnswers = [currentItem.translation, ...wrongAnswers.take(3)]
    ..shuffle();
  
  return allAnswers;
});

/// Provider that gets the correct answer index for the current question
final correctAnswerIndexProvider = Provider.autoDispose<int>((ref) {
  final vocabulary = ref.watch(quizVocabularyProvider); // Use limited quiz vocabulary
  final currentQuestionIndex = ref.watch(currentQuestionIndexProvider);
  final shuffledAnswers = ref.watch(shuffledAnswersProvider);
  
  if (vocabulary.isEmpty || currentQuestionIndex >= vocabulary.length || shuffledAnswers.isEmpty) {
    return -1;
  }
  
  final currentItem = vocabulary[currentQuestionIndex];
  return shuffledAnswers.indexOf(currentItem.translation);
});

class QuizScreen extends ConsumerWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabulary = ref.watch(quizVocabularyProvider); // Use limited quiz vocabulary
    final currentQuestionIndex = ref.watch(currentQuestionIndexProvider);
    final quizResults = ref.watch(quizResultsProvider);

    if (vocabulary.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          automaticallyImplyLeading: false,
          actions: [
            _buildQuizLengthSelector(context, ref),
            const SizedBox(width: 8),
            const LanguageSelectorAction(),
            const SizedBox(width: 8),
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
    final allAnswers = ref.watch(shuffledAnswersProvider);
    final correctAnswerIndex = ref.watch(correctAnswerIndexProvider);

    // Handle empty answers (shouldn't happen, but defensive programming)
    if (allAnswers.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Quiz'),
          automaticallyImplyLeading: false,
          actions: [
            _buildQuizLengthSelector(context, ref),
            const SizedBox(width: 8),
            const LanguageSelectorAction(),
            const SizedBox(width: 8),
          ],
        ),
        body: const Center(child: Text('Error loading quiz question')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Quiz ${currentQuestionIndex + 1}/${vocabulary.length}'),
        automaticallyImplyLeading: false,
        actions: [
          _buildQuizLengthSelector(context, ref),
          const SizedBox(width: 8),
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
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
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
                const SizedBox(height: 24),
                Consumer(
                  builder: (context, ref, _) {
                    final isAnswerSubmitted = ref.watch(isAnswerSubmittedProvider);
                    return ElevatedButton(
                      onPressed: isAnswerSubmitted
                          ? () {
                              final quizVocab = ref.read(quizVocabularyProvider);
                              _handleNextQuestion(context, ref, quizVocab.length);
                            }
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
  }

  Widget _buildResultsScreen(BuildContext context, WidgetRef ref, List<bool> results, int totalQuestions) {
    final correctAnswers = results.where((r) => r).length;
    final percentage = (correctAnswers / totalQuestions * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
        actions: [
          _buildQuizLengthSelector(context, ref),
          const SizedBox(width: 8),
          const LanguageSelectorAction(),
          const SizedBox(width: 8),
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
      // Quiz complete - move to results and save final results
      ref.read(currentQuestionIndexProvider.notifier).state = totalQuestions;
      _saveCompletedQuizResults(context, ref, totalQuestions);
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

  Future<void> _saveCompletedQuizResults(BuildContext context, WidgetRef ref, int totalQuestions) async {
    try {
      final dataService = await ref.read(localDataServiceProvider.future);
      final quizResults = ref.read(quizResultsProvider);
      final quizLength = ref.read(quizLengthProvider);
      final currentPlugin = ref.read(currentLanguagePluginProvider);
      
      final correctAnswers = quizResults.where((r) => r).length;
      final percentage = (correctAnswers / totalQuestions * 100).round();
      
      // Create quiz result data
      final quizResultData = {
        'date': DateTime.now().toIso8601String(),
        'language': currentPlugin?.language.code ?? 'unknown',
        'quizLength': quizLength.displayName,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'incorrectAnswers': totalQuestions - correctAnswers,
        'percentage': percentage,
        'results': quizResults,
      };
      
      // Save with unique ID
      final quizId = 'quiz_${DateTime.now().millisecondsSinceEpoch}';
      await dataService.saveQuizResult(quizId, quizResultData);
      
      debugPrint('✅ Quiz results saved: $correctAnswers/$totalQuestions ($percentage%)');
    } catch (e) {
      debugPrint('❌ Failed to save quiz results: $e');
      // Silent fail - don't break the quiz experience
    }
  }


  Widget _buildQuizLengthSelector(BuildContext context, WidgetRef ref) {
    final currentLength = ref.watch(quizLengthProvider);
    
    return Semantics(
      label: 'Quiz length selector',
      hint: 'Tap to change quiz length. Currently set to ${currentLength.displayName}',
      button: true,
      child: PopupMenuButton<QuizLength>(
        key: const Key('quiz_length_selector'),
        icon: const Icon(Icons.quiz),
        tooltip: 'Quiz Length: ${currentLength.displayName}',
        onSelected: (QuizLength length) {
          ref.read(quizLengthProvider.notifier).setQuizLength(length);
          
          // Reset quiz when length changes
          _resetQuiz(ref);
        },
        itemBuilder: (BuildContext context) => QuizLength.values.map((QuizLength length) {
          return PopupMenuItem<QuizLength>(
            key: Key('quiz_length_option_${length.name}'),
            value: length,
            child: Semantics(
              label: '${length.displayName} questions',
              hint: length == currentLength ? 'Currently selected' : 'Tap to select',
              selected: length == currentLength,
              child: Row(
                children: [
                  Icon(
                    length == currentLength ? Icons.check : Icons.radio_button_unchecked,
                    size: 20,
                    semanticLabel: length == currentLength ? 'Selected' : 'Not selected',
                  ),
                  const SizedBox(width: 8),
                  Text(length.displayName),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getEncouragingMessage(int percentage) {
    if (percentage >= 90) return 'Outstanding! You\'re mastering this language! 🏆';
    if (percentage >= 80) return 'Excellent work! Keep it up! 🌟';
    if (percentage >= 70) return 'Good job! You\'re making great progress! 👍';
    if (percentage >= 60) return 'Nice effort! Keep studying and you\'ll improve! 📚';
    return 'Don\'t give up! Practice makes perfect! 💪';
  }
}