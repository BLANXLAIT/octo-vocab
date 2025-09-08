import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_saas_template/core/language/language_plugin.dart';
import 'package:flutter_saas_template/core/language/models/language.dart';
import 'package:flutter_saas_template/core/language/models/vocabulary_item.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/providers/study_config_providers.dart';

// ignore_for_file: public_member_api_docs

/// Registry that manages all available language plugins
class LanguageRegistry {
  LanguageRegistry._();
  
  static final instance = LanguageRegistry._();

  final Map<String, LanguagePlugin> _plugins = {};

  /// Register a language plugin
  void register(LanguagePlugin plugin) {
    _plugins[plugin.language.code] = plugin;
    print('DEBUG: Registered language plugin: ${plugin.language.name} (${plugin.language.code})');
  }

  /// Clear all registered language plugins (mainly for testing)
  void clear() {
    _plugins.clear();
  }

  /// Get all available languages
  List<Language> getAvailableLanguages() {
    return _plugins.values.map((plugin) => plugin.language).toList();
  }

  /// Get a language plugin by code
  LanguagePlugin? getPlugin(String languageCode) {
    return _plugins[languageCode];
  }

  /// Check if a language is available
  bool isLanguageAvailable(String languageCode) {
    return _plugins.containsKey(languageCode);
  }

  /// Load vocabulary for a specific language and level
  Future<List<VocabularyItem>> loadVocabulary(String languageCode, VocabularyLevel level) async {
    final plugin = getPlugin(languageCode);
    if (plugin == null) {
      throw Exception('Language plugin not found: $languageCode');
    }
    
    return plugin.loadLevelVocabulary(level);
  }

  /// Load vocabulary for a specific language, level, and set
  Future<List<VocabularyItem>> loadVocabularySet(
    String languageCode, 
    VocabularyLevel level, 
    VocabularySet vocabSet,
  ) async {
    final plugin = getPlugin(languageCode);
    if (plugin == null) {
      throw Exception('Language plugin not found: $languageCode');
    }
    
    return plugin.loadVocabulary(level, vocabSet);
  }
}

/// Provider for the language registry
final languageRegistryProvider = Provider<LanguageRegistry>((ref) {
  return LanguageRegistry.instance;
});

/// Provider for available languages
final availableLanguagesProvider = Provider<List<Language>>((ref) {
  final registry = ref.watch(languageRegistryProvider);
  return registry.getAvailableLanguages();
});

/// Provider for selected language (defaults to the first available language)
final selectedLanguageProvider = StateProvider<String>((ref) {
  final availableLanguages = ref.watch(availableLanguagesProvider);
  return availableLanguages.isNotEmpty ? availableLanguages.first.code : 'la';
});

/// Provider for current language plugin
final currentLanguagePluginProvider = Provider<LanguagePlugin?>((ref) {
  final selectedLanguageCode = ref.watch(selectedLanguageProvider);
  final registry = ref.watch(languageRegistryProvider);
  return registry.getPlugin(selectedLanguageCode);
});

/// Provider for loading vocabulary based on selected language and level
final vocabularyProvider = FutureProvider.autoDispose<List<VocabularyItem>>((ref) async {
  final selectedLanguageCode = ref.watch(selectedLanguageProvider);
  final level = ref.watch(vocabularyLevelProvider);
  final registry = ref.watch(languageRegistryProvider);
  
  return registry.loadVocabulary(selectedLanguageCode, level);
});

