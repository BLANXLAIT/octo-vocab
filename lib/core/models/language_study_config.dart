// ignore_for_file: public_member_api_docs
import 'package:flutter/foundation.dart';
import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';

/// Configuration for a specific language study setup
@immutable
class LanguageStudyConfig {
  const LanguageStudyConfig({
    required this.language,
    required this.level,
    required this.isEnabled,
  });

  final AppLanguage language;
  final VocabularyLevel level;
  final bool isEnabled;

  /// Creates a copy with updated fields
  LanguageStudyConfig copyWith({
    AppLanguage? language,
    VocabularyLevel? level,
    bool? isEnabled,
  }) {
    return LanguageStudyConfig(
      language: language ?? this.language,
      level: level ?? this.level,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'language': language.name,
      'level': level.code,
      'isEnabled': isEnabled,
    };
  }

  /// Creates from JSON storage
  factory LanguageStudyConfig.fromJson(Map<String, dynamic> json) {
    return LanguageStudyConfig(
      language: AppLanguage.values.firstWhere(
        (lang) => lang.name == json['language'],
        orElse: () => AppLanguage.latin,
      ),
      level: VocabularyLevel.values.firstWhere(
        (level) => level.code == json['level'],
        orElse: () => VocabularyLevel.beginner,
      ),
      isEnabled: json['isEnabled'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LanguageStudyConfig &&
        other.language == language &&
        other.level == level &&
        other.isEnabled == isEnabled;
  }

  @override
  int get hashCode => Object.hash(language, level, isEnabled);

  @override
  String toString() {
    return 'LanguageStudyConfig(language: $language, level: $level, isEnabled: $isEnabled)';
  }
}

/// Collection of language study configurations
@immutable
class StudyConfigurationSet {
  const StudyConfigurationSet({
    required this.configurations,
    required this.currentLanguage,
  });

  final Map<String, LanguageStudyConfig> configurations;
  final AppLanguage currentLanguage;

  /// Get all enabled language configurations
  List<LanguageStudyConfig> get enabledConfigurations {
    return configurations.values.where((config) => config.isEnabled).toList();
  }

  /// Get the current active configuration
  LanguageStudyConfig? get currentConfiguration {
    return configurations[currentLanguage.name];
  }

  /// Get configuration for a specific language
  LanguageStudyConfig? getConfigForLanguage(AppLanguage language) {
    return configurations[language.name];
  }

  /// Create a copy with updated configuration for a language
  StudyConfigurationSet updateLanguageConfig(
    AppLanguage language,
    LanguageStudyConfig config,
  ) {
    final updatedConfigs = Map<String, LanguageStudyConfig>.from(configurations);
    updatedConfigs[language.name] = config;
    
    return StudyConfigurationSet(
      configurations: updatedConfigs,
      currentLanguage: currentLanguage,
    );
  }

  /// Create a copy with updated current language
  StudyConfigurationSet withCurrentLanguage(AppLanguage language) {
    return StudyConfigurationSet(
      configurations: configurations,
      currentLanguage: language,
    );
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'configurations': configurations.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'currentLanguage': currentLanguage.name,
    };
  }

  /// Creates from JSON storage
  factory StudyConfigurationSet.fromJson(Map<String, dynamic> json) {
    try {
      final configsJson = json['configurations'] as Map<String, dynamic>? ?? {};
      final configurations = <String, LanguageStudyConfig>{};
      
      for (final entry in configsJson.entries) {
        try {
          if (entry.value is Map<String, dynamic>) {
            configurations[entry.key] = LanguageStudyConfig.fromJson(entry.value as Map<String, dynamic>);
          }
        } catch (e) {
          // Skip invalid configuration entries
          continue;
        }
      }

      // If no valid configurations were loaded, return default
      if (configurations.isEmpty && configsJson.isNotEmpty) {
        return StudyConfigurationSet.createDefault();
      }
      
      // If configurations is completely empty (no configs key), return default
      if (configurations.isEmpty && !json.containsKey('configurations')) {
        return StudyConfigurationSet.createDefault();
      }

      return StudyConfigurationSet(
        configurations: configurations,
        currentLanguage: AppLanguage.values.firstWhere(
          (lang) => lang.name == json['currentLanguage'],
          orElse: () => AppLanguage.latin,
        ),
      );
    } catch (e) {
      // Return default configuration if JSON is completely invalid
      return StudyConfigurationSet.createDefault();
    }
  }

  /// Creates default configuration with Latin enabled at Beginner level
  factory StudyConfigurationSet.createDefault() {
    final configurations = <String, LanguageStudyConfig>{};
    
    // Create configuration for each available language
    for (final language in AppLanguage.values) {
      configurations[language.name] = LanguageStudyConfig(
        language: language,
        level: VocabularyLevel.beginner,
        isEnabled: language == AppLanguage.latin, // Only Latin enabled by default
      );
    }

    return StudyConfigurationSet(
      configurations: configurations,
      currentLanguage: AppLanguage.latin,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudyConfigurationSet &&
        other.currentLanguage == currentLanguage &&
        other.configurations.length == configurations.length &&
        configurations.entries.every(
          (entry) => other.configurations[entry.key] == entry.value,
        );
  }

  @override
  int get hashCode => Object.hash(configurations, currentLanguage);
}