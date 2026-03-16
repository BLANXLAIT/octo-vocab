import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octo_vocab/core/language/models/vocabulary_item.dart';
import 'package:octo_vocab/core/providers/language_providers.dart';
import 'package:octo_vocab/core/providers/storage_providers.dart';

// ignore_for_file: public_member_api_docs

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
final quizLengthProvider =
    StateNotifierProvider<QuizLengthNotifier, QuizLength>((ref) {
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
      final dataService = _ref.read(localDataServiceProvider);
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
      final dataService = _ref.read(localDataServiceProvider);
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
final isAnswerSubmittedProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
final quizResultsProvider = StateProvider.autoDispose<List<bool>>((ref) => []);

/// Provider that returns quiz vocabulary based on length setting
final quizVocabularyProvider = Provider.autoDispose<List<VocabularyItem>>((
  ref,
) {
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
  final vocabulary = ref.watch(
    quizVocabularyProvider,
  ); // Use limited quiz vocabulary
  final currentQuestionIndex = ref.watch(currentQuestionIndexProvider);

  if (vocabulary.isEmpty || currentQuestionIndex >= vocabulary.length) {
    return <String>[];
  }

  final currentItem = vocabulary[currentQuestionIndex];
  final wrongAnswers =
      vocabulary
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
  final vocabulary = ref.watch(
    quizVocabularyProvider,
  ); // Use limited quiz vocabulary
  final currentQuestionIndex = ref.watch(currentQuestionIndexProvider);
  final shuffledAnswers = ref.watch(shuffledAnswersProvider);

  if (vocabulary.isEmpty ||
      currentQuestionIndex >= vocabulary.length ||
      shuffledAnswers.isEmpty) {
    return -1;
  }

  final currentItem = vocabulary[currentQuestionIndex];
  return shuffledAnswers.indexOf(currentItem.translation);
});