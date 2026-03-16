import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octo_vocab/core/language/language_plugin.dart';
import 'package:octo_vocab/core/language/language_registry.dart';
import 'package:octo_vocab/core/language/language_state_notifier.dart';
import 'package:octo_vocab/core/language/models/language.dart';
import 'package:octo_vocab/core/language/models/vocabulary_item.dart';
import 'package:octo_vocab/core/providers/study_config_providers.dart';

// ignore_for_file: public_member_api_docs

/// Provider for the language registry
final languageRegistryProvider = Provider<LanguageRegistry>((ref) {
  return LanguageRegistry.instance;
});

/// Provider for available languages
final availableLanguagesProvider = Provider<List<Language>>((ref) {
  final registry = ref.watch(languageRegistryProvider);
  return registry.getAvailableLanguages();
});

/// Provider for selected language with persistence
/// This is now handled by LanguageStateNotifier for proper persistence
final selectedLanguageProvider = Provider<String>((ref) {
  return ref.watch(languageStateNotifierProvider);
});

/// Provider for current language plugin
final currentLanguagePluginProvider = Provider<LanguagePlugin?>((ref) {
  final selectedLanguageCode = ref.watch(selectedLanguageProvider);
  final registry = ref.watch(languageRegistryProvider);
  return registry.getPlugin(selectedLanguageCode);
});

/// Provider for loading vocabulary based on selected language and level
final vocabularyProvider = FutureProvider.autoDispose<List<VocabularyItem>>((
  ref,
) async {
  final selectedLanguageCode = ref.watch(selectedLanguageProvider);
  final level = ref.watch(vocabularyLevelProvider);
  final registry = ref.watch(languageRegistryProvider);

  return registry.loadVocabulary(selectedLanguageCode, level);
});