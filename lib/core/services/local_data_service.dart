// ignore_for_file: public_member_api_docs, directives_ordering
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/language_study_config.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';

/// Privacy-first local data storage service
/// All user data stays on device - no network transmission
class LocalDataService {
  const LocalDataService._(this._prefs);

  static const String _keyWordProgress = 'word_progress';
  static const String _keyStudySessions = 'study_sessions';
  static const String _keyQuizResults = 'quiz_results';
  static const String _keyAppSettings = 'app_settings';
  static const String _keySelectedLanguage = 'selected_language';
  static const String _keyDifficultWords = 'difficult_words';
  static const String _keyKnownWords = 'known_words';
  static const String _keyStudyingLanguages = 'studying_languages';
  static const String _keyPerLanguageProgress = 'per_language_progress';
  static const String _keyStudyConfiguration = 'study_configuration';
  static const String _keyMigrationVersion = 'migration_version';

  // Current migration version
  static const int _currentMigrationVersion = 3;

  final SharedPreferences _prefs;

  static Future<LocalDataService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalDataService._(prefs);
  }

  /// Word Progress Tracking (Privacy-First)
  /// Tracks mastery levels: new, learning, mastered
  Map<String, String> getWordProgress() {
    final json = _prefs.getString(_keyWordProgress);
    if (json == null) return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.cast<String, String>();
    } catch (e) {
      return {};
    }
  }

  Future<bool> setWordProgress(Map<String, String> progress) async {
    return _prefs.setString(_keyWordProgress, jsonEncode(progress));
  }

  /// Study Sessions (Local Analytics Only)
  /// Tracks daily study for streaks - never leaves device
  List<DateTime> getStudySessions() {
    final json = _prefs.getString(_keyStudySessions);
    if (json == null) return [];
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.map((e) => DateTime.parse(e as String)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> addStudySession(DateTime session) async {
    final sessions = getStudySessions()..add(session);
    return _prefs.setString(
      _keyStudySessions,
      jsonEncode(sessions.map((e) => e.toIso8601String()).toList()),
    );
  }

  /// Quiz Results (Privacy-First Performance Tracking)
  /// Local-only quiz scores for progress visualization
  List<Map<String, dynamic>> getQuizResults() {
    final json = _prefs.getString(_keyQuizResults);
    if (json == null) return [];
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<bool> addQuizResult({
    required int score,
    required int total,
    required String language,
    required DateTime timestamp,
  }) async {
    final results = getQuizResults()
      ..add({
        'score': score,
        'total': total,
        'language': language,
        'timestamp': timestamp.toIso8601String(),
      });
    return _prefs.setString(_keyQuizResults, jsonEncode(results));
  }

  /// Language Selection (Privacy-Compliant Preferences)
  String? getSelectedLanguage() {
    return _prefs.getString(_keySelectedLanguage);
  }

  Future<bool> setSelectedLanguage(String language) async {
    return _prefs.setString(_keySelectedLanguage, language);
  }

  /// Word Difficulty Tracking (Privacy-First Learning Analytics)
  /// Tracks which words users find difficult for personalized review

  // Note: getDifficultWords, getKnownWords, markWordAsDifficult, and markWordAsKnown
  // methods are now implemented at the end of this class with per-language support

  /// Get basic learning statistics
  Map<String, int> getLearningStats() {
    final difficultWords = getDifficultWords();
    final knownWords = getKnownWords();

    return {
      'difficult_count': difficultWords.length,
      'known_count': knownWords.length,
      'total_studied': difficultWords.length + knownWords.length,
    };
  }

  /// Check if a word is marked as difficult
  bool isWordDifficult(String wordId) {
    return getDifficultWords().contains(wordId);
  }

  /// Check if a word is marked as known
  bool isWordKnown(String wordId) {
    return getKnownWords().contains(wordId);
  }

  /// App Settings (Local Configuration Only)
  Map<String, dynamic> getAppSettings() {
    final json = _prefs.getString(_keyAppSettings);
    if (json == null) return {};
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<bool> setAppSettings(Map<String, dynamic> settings) async {
    return _prefs.setString(_keyAppSettings, jsonEncode(settings));
  }

  /// PRIVACY CONTROL: Complete Data Reset
  /// Allows users to completely delete all stored data
  /// COPPA/FERPA compliant - user has full control
  Future<bool> resetAllData() async {
    try {
      await Future.wait([
        _prefs.remove(_keyWordProgress),
        _prefs.remove(_keyStudySessions),
        _prefs.remove(_keyQuizResults),
        _prefs.remove(_keyAppSettings),
        _prefs.remove(_keySelectedLanguage),
        _prefs.remove(_keyDifficultWords),
        _prefs.remove(_keyKnownWords),
        _prefs.remove(_keyStudyingLanguages),
        _prefs.remove(_keyPerLanguageProgress),
        _prefs.remove(_keyStudyConfiguration),
        _prefs.remove(_keyMigrationVersion),
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// DEBUG: Reset language configuration and force re-migration
  Future<bool> resetLanguageSettings() async {
    try {
      // Reset migration version to force re-migration
      await _prefs.remove(_keyMigrationVersion);
      await _prefs.remove(_keyStudyConfiguration);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Privacy Transparency: Show User Their Data
  /// Allows users to see exactly what's stored locally
  Map<String, dynamic> getAllUserData() {
    return {
      'word_progress': getWordProgress(),
      'study_sessions': getStudySessions()
          .map((e) => e.toIso8601String())
          .toList(),
      'quiz_results': getQuizResults(),
      'app_settings': getAppSettings(),
      'selected_language': getSelectedLanguage(),
      'difficult_words': getDifficultWords().toList(),
      'known_words': getKnownWords().toList(),
      'learning_stats': getLearningStats(),
    };
  }

  /// Privacy Compliance: Data Export
  /// Let users export their data for backup/transparency
  String exportUserData() {
    return jsonEncode({
      'app': 'Octo Vocab',
      'export_date': DateTime.now().toIso8601String(),
      'privacy_note': 'This data never leaves your device unless you share it',
      'data': getAllUserData(),
    });
  }

  /// Language Management for Multi-Language Learning
  /// Tracks which languages the user is actively studying

  /// Get set of languages user is actively studying
  Set<String> getStudyingLanguages() {
    final json = _prefs.getString(_keyStudyingLanguages);
    if (json == null) {
      // Default to current selected language if none set
      final currentLang = getSelectedLanguage();
      return currentLang != null ? {currentLang} : <String>{};
    }
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.cast<String>().toSet();
    } catch (e) {
      return <String>{};
    }
  }

  /// Add a language to study list
  Future<bool> addStudyingLanguage(String language) async {
    final languages = getStudyingLanguages()..add(language);
    return _prefs.setString(
      _keyStudyingLanguages,
      jsonEncode(languages.toList()),
    );
  }

  /// Remove a language from study list
  Future<bool> removeStudyingLanguage(String language) async {
    final languages = getStudyingLanguages()..remove(language);
    return _prefs.setString(
      _keyStudyingLanguages,
      jsonEncode(languages.toList()),
    );
  }

  /// Set complete list of studying languages
  Future<bool> setStudyingLanguages(Set<String> languages) async {
    return _prefs.setString(
      _keyStudyingLanguages,
      jsonEncode(languages.toList()),
    );
  }

  /// Per-Language Progress Tracking
  /// Stores progress data separately for each language

  /// Get per-language progress data
  Map<String, Map<String, dynamic>> getPerLanguageProgress() {
    final json = _prefs.getString(_keyPerLanguageProgress);
    if (json == null) return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.cast<String, Map<String, dynamic>>();
    } catch (e) {
      return {};
    }
  }

  /// Get difficult words for a specific language
  Set<String> getDifficultWordsForLanguage(String language) {
    final allProgress = getPerLanguageProgress();
    final languageProgress = allProgress[language];
    if (languageProgress == null) return <String>{};

    try {
      final difficultWords =
          languageProgress['difficult_words'] as List<dynamic>?;
      return difficultWords?.cast<String>().toSet() ?? <String>{};
    } catch (e) {
      return <String>{};
    }
  }

  /// Get known words for a specific language
  Set<String> getKnownWordsForLanguage(String language) {
    final allProgress = getPerLanguageProgress();
    final languageProgress = allProgress[language];
    if (languageProgress == null) return <String>{};

    try {
      final knownWords = languageProgress['known_words'] as List<dynamic>?;
      return knownWords?.cast<String>().toSet() ?? <String>{};
    } catch (e) {
      return <String>{};
    }
  }

  /// Mark word as difficult for specific language
  Future<bool> markWordAsDifficultForLanguage(
    String wordId,
    String language,
  ) async {
    final allProgress = getPerLanguageProgress();
    final languageProgress = allProgress[language] ?? {};

    final difficultWords =
        (languageProgress['difficult_words'] as List<dynamic>?)
            ?.cast<String>()
            .toSet() ??
        <String>{};
    final knownWords =
        (languageProgress['known_words'] as List<dynamic>?)
            ?.cast<String>()
            .toSet() ??
        <String>{};

    // Add to difficult, remove from known
    difficultWords.add(wordId);
    knownWords.remove(wordId);

    languageProgress['difficult_words'] = difficultWords.toList();
    languageProgress['known_words'] = knownWords.toList();
    allProgress[language] = languageProgress;

    return _prefs.setString(_keyPerLanguageProgress, jsonEncode(allProgress));
  }

  /// Mark word as known for specific language
  Future<bool> markWordAsKnownForLanguage(
    String wordId,
    String language,
  ) async {
    final allProgress = getPerLanguageProgress();
    final languageProgress = allProgress[language] ?? {};

    final difficultWords =
        (languageProgress['difficult_words'] as List<dynamic>?)
            ?.cast<String>()
            .toSet() ??
        <String>{};
    final knownWords =
        (languageProgress['known_words'] as List<dynamic>?)
            ?.cast<String>()
            .toSet() ??
        <String>{};

    // Add to known, remove from difficult
    knownWords.add(wordId);
    difficultWords.remove(wordId);

    languageProgress['difficult_words'] = difficultWords.toList();
    languageProgress['known_words'] = knownWords.toList();
    allProgress[language] = languageProgress;

    return _prefs.setString(_keyPerLanguageProgress, jsonEncode(allProgress));
  }

  /// Get learning stats for specific language
  Map<String, int> getLearningStatsForLanguage(String language) {
    final difficultWords = getDifficultWordsForLanguage(language);
    final knownWords = getKnownWordsForLanguage(language);

    return {
      'difficult_count': difficultWords.length,
      'known_count': knownWords.length,
      'total_studied': difficultWords.length + knownWords.length,
    };
  }

  /// Get learning stats for all studying languages
  Map<String, Map<String, int>> getMultiLanguageStats() {
    final studyingLanguages = getStudyingLanguages();
    final stats = <String, Map<String, int>>{};

    for (final language in studyingLanguages) {
      stats[language] = getLearningStatsForLanguage(language);
    }

    return stats;
  }

  /// Migration helpers - update existing methods to use per-language storage
  /// These maintain backward compatibility while migrating to new structure

  Set<String> getDifficultWords() {
    // Use current language data or fallback to legacy
    final currentLang = getSelectedLanguage();
    if (currentLang != null) {
      final perLangWords = getDifficultWordsForLanguage(currentLang);
      if (perLangWords.isNotEmpty) return perLangWords;
    }

    // Fallback to legacy global storage
    final json = _prefs.getString(_keyDifficultWords);
    if (json == null) return <String>{};
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.cast<String>().toSet();
    } catch (e) {
      return <String>{};
    }
  }

  Set<String> getKnownWords() {
    // Use current language data or fallback to legacy
    final currentLang = getSelectedLanguage();
    if (currentLang != null) {
      final perLangWords = getKnownWordsForLanguage(currentLang);
      if (perLangWords.isNotEmpty) return perLangWords;
    }

    // Fallback to legacy global storage
    final json = _prefs.getString(_keyKnownWords);
    if (json == null) return <String>{};
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.cast<String>().toSet();
    } catch (e) {
      return <String>{};
    }
  }

  Future<bool> markWordAsDifficult(String wordId) async {
    final currentLang = getSelectedLanguage();
    if (currentLang != null) {
      // Use per-language storage
      return markWordAsDifficultForLanguage(wordId, currentLang);
    }

    // Fallback to legacy global storage
    final difficultWords = getDifficultWords()..add(wordId);
    final knownWords = getKnownWords()..remove(wordId);
    await _prefs.setString(_keyKnownWords, jsonEncode(knownWords.toList()));
    return _prefs.setString(
      _keyDifficultWords,
      jsonEncode(difficultWords.toList()),
    );
  }

  Future<bool> markWordAsKnown(String wordId) async {
    final currentLang = getSelectedLanguage();
    if (currentLang != null) {
      // Use per-language storage
      return markWordAsKnownForLanguage(wordId, currentLang);
    }

    // Fallback to legacy global storage
    final knownWords = getKnownWords()..add(wordId);
    final difficultWords = getDifficultWords()..remove(wordId);
    await _prefs.setString(
      _keyDifficultWords,
      jsonEncode(difficultWords.toList()),
    );
    return _prefs.setString(_keyKnownWords, jsonEncode(knownWords.toList()));
  }

  /// New Study Configuration System
  /// Stores language + difficulty level configurations with enabled state

  /// Get the current study configuration set
  StudyConfigurationSet getStudyConfiguration() {
    final json = _prefs.getString(_keyStudyConfiguration);
    if (json == null) {
      // Create and save default configuration
      final defaultConfig = StudyConfigurationSet.createDefault();
      setStudyConfiguration(defaultConfig);
      return defaultConfig;
    }

    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return StudyConfigurationSet.fromJson(decoded);
    } catch (e) {
      // If corrupted, return default
      final defaultConfig = StudyConfigurationSet.createDefault();
      setStudyConfiguration(defaultConfig);
      return defaultConfig;
    }
  }

  /// Save the study configuration set
  Future<bool> setStudyConfiguration(StudyConfigurationSet config) async {
    return _prefs.setString(
      _keyStudyConfiguration,
      jsonEncode(config.toJson()),
    );
  }

  /// Update configuration for a specific language
  Future<bool> updateLanguageConfig(
    AppLanguage language,
    LanguageStudyConfig config,
  ) async {
    final currentConfig = getStudyConfiguration();
    final updatedConfig = currentConfig.updateLanguageConfig(language, config);
    return setStudyConfiguration(updatedConfig);
  }

  /// Set the current active language
  Future<bool> setCurrentLanguage(AppLanguage language) async {
    final currentConfig = getStudyConfiguration();
    final updatedConfig = currentConfig.withCurrentLanguage(language);
    return setStudyConfiguration(updatedConfig);
  }

  /// Get all enabled language configurations
  List<LanguageStudyConfig> getEnabledLanguageConfigs() {
    return getStudyConfiguration().enabledConfigurations;
  }

  /// Get the current active language configuration
  LanguageStudyConfig? getCurrentLanguageConfig() {
    return getStudyConfiguration().currentConfiguration;
  }

  /// Migration: Convert existing settings to new configuration system
  Future<bool> migrateToNewConfigSystem() async {
    final currentVersion = _prefs.getInt(_keyMigrationVersion) ?? 0;

    // If we're already at the current version, no migration needed
    if (currentVersion >= _currentMigrationVersion) {
      return true;
    }

    // Migration version 1: Initial configuration system
    if (currentVersion < 1) {
      await _migrateToV1();
    }

    // Migration version 2: Enable all available languages by default
    if (currentVersion < 2) {
      await _migrateToV2();
    }

    // Migration version 3: Force Spanish to be enabled (debug Spanish issue)
    if (currentVersion < 3) {
      await _migrateToV3();
    }

    // Update migration version
    await _prefs.setInt(_keyMigrationVersion, _currentMigrationVersion);
    return true;
  }

  /// Version 1 migration: Initial configuration system
  Future<void> _migrateToV1() async {
    final existingConfig = _prefs.getString(_keyStudyConfiguration);
    if (existingConfig != null) {
      return; // Already has configuration
    }

    // Create default configuration
    var configSet = StudyConfigurationSet.createDefault();

    // Migrate selected language if it exists
    final selectedLang = getSelectedLanguage();
    if (selectedLang != null) {
      try {
        final appLang = AppLanguage.values.firstWhere(
          (lang) => lang.name == selectedLang,
        );
        configSet = configSet.withCurrentLanguage(appLang);
      } catch (e) {
        // If language not found, keep default
      }
    }

    await setStudyConfiguration(configSet);
  }

  /// Version 2 migration: Enable all available languages by default
  Future<void> _migrateToV2() async {
    var configSet = getStudyConfiguration();

    // Ensure all available languages are enabled
    for (final language in AppLanguage.values) {
      final currentConfig = configSet.getConfigForLanguage(language);
      if (currentConfig != null && !currentConfig.isEnabled) {
        // Enable the language while preserving the user's chosen level
        configSet = configSet.updateLanguageConfig(
          language,
          currentConfig.copyWith(isEnabled: true),
        );
      }
    }

    await setStudyConfiguration(configSet);
  }

  /// Version 3 migration: Force Spanish to be enabled and create missing configs
  Future<void> _migrateToV3() async {
    var configSet = getStudyConfiguration();
    bool configChanged = false;

    // Ensure ALL languages in the AppLanguage enum have configurations
    for (final language in AppLanguage.values) {
      final currentConfig = configSet.getConfigForLanguage(language);
      
      if (currentConfig == null) {
        // Create missing configuration for this language
        final newConfig = LanguageStudyConfig(
          language: language,
          level: VocabularyLevel.beginner,
          isEnabled: true,
        );
        configSet = configSet.updateLanguageConfig(language, newConfig);
        configChanged = true;
      } else if (!currentConfig.isEnabled) {
        // Force enable disabled languages (especially Spanish)
        configSet = configSet.updateLanguageConfig(
          language,
          currentConfig.copyWith(isEnabled: true),
        );
        configChanged = true;
      }
    }

    // Save configuration if it was changed
    if (configChanged) {
      await setStudyConfiguration(configSet);
    }
  }
}

/// Riverpod provider for the local data service
final localDataServiceProvider = FutureProvider<LocalDataService>((ref) async {
  return LocalDataService.create();
});
