import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octo_vocab/core/models/word_interaction.dart';
import 'package:octo_vocab/core/providers/language_providers.dart';
import 'package:octo_vocab/core/providers/storage_providers.dart';

// ignore_for_file: public_member_api_docs

/// Progress tracking providers
final studySessionsProvider = FutureProvider<List<DateTime>>((ref) async {
  final dataService = ref.watch(localDataServiceProvider);
  return dataService.getStudySessions();
});

final wordProgressProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final dataService = ref.watch(localDataServiceProvider);
  final selectedLanguage = ref.watch(selectedLanguageProvider);
  final currentPlugin = ref.watch(currentLanguagePluginProvider);

  final allProgress = dataService.getWordProgress();

  // Filter progress to only include items for the current language
  if (currentPlugin == null) return {};

  final languageSpecificProgress = <String, String>{};
  for (final entry in allProgress.entries) {
    // Progress keys are stored as "languageCode_wordId"
    if (entry.key.startsWith('${selectedLanguage}_')) {
      // KEEP the full key (including language prefix) - other providers expect this format
      languageSpecificProgress[entry.key] = entry.value;
    }
  }

  return languageSpecificProgress;
});

final quizResultsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dataService = ref.watch(localDataServiceProvider);
  final selectedLanguage = ref.watch(selectedLanguageProvider);

  final allResults = dataService.getQuizResults();

  // Filter quiz results to only include current language
  final languageSpecificResults = <String, dynamic>{};
  for (final entry in allResults.entries) {
    if (entry.key.startsWith('quiz_${selectedLanguage}_')) {
      languageSpecificResults[entry.key] = entry.value;
    }
  }

  return languageSpecificResults;
});

/// Word interactions provider for enhanced spaced repetition tracking
final wordInteractionsProvider = FutureProvider.autoDispose<Map<String, WordInteraction>>((ref) async {
  final dataService = ref.watch(localDataServiceProvider);
  return dataService.getWordInteractions();
});