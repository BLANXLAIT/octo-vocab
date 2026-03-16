import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octo_vocab/core/repositories/quiz_results_repository.dart';
import 'package:octo_vocab/core/repositories/study_session_repository.dart';
import 'package:octo_vocab/core/repositories/word_progress_repository.dart';
import 'package:octo_vocab/core/services/local_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences instance provider
/// This is overridden in main.dart with the actual instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in main.dart',
  );
});

/// Word progress repository provider
final wordProgressRepositoryProvider = Provider<WordProgressRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return WordProgressRepository(prefs);
});

/// Quiz results repository provider
final quizResultsRepositoryProvider = Provider<QuizResultsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return QuizResultsRepository(prefs);
});

/// Study session repository provider
final studySessionRepositoryProvider = Provider<StudySessionRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return StudySessionRepository(prefs);
});

/// Local data service provider (kept for backward compatibility)
/// This wraps the repositories for legacy code that still uses LocalDataService
final localDataServiceProvider = Provider<LocalDataService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalDataService(prefs);
});
