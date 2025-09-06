import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/language_study_config.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';

void main() {
  group('Migration System Tests', () {
    test('v1 to v2 migration enables all languages', () async {
      // Simulate v1 configuration with only Latin enabled
      SharedPreferences.setMockInitialValues({
        'selected_language': 'latin', // Use the correct key
        'vocabulary_level': 'beginner',
        'latin_enabled': true,
        'spanish_enabled': false,
        'migration_version': 1, // v1 data
      });

      final dataService = await LocalDataService.create();

      // Verify migration occurred by checking the configuration
      final config = dataService.getStudyConfiguration();

      expect(config.currentLanguage, AppLanguage.latin);
      expect(
        config.enabledConfigurations,
        hasLength(AppLanguage.values.length),
      );

      for (final languageConfig in config.enabledConfigurations) {
        expect(
          languageConfig.isEnabled,
          true,
          reason:
              '${languageConfig.language} should be enabled after migration',
        );
        expect(languageConfig.level, VocabularyLevel.beginner);
      }
    });

    test('v1 to v2 migration enables all languages by default', () async {
      // Simulate v1 configuration - focus on the core feature we're testing
      SharedPreferences.setMockInitialValues({
        'selected_language': 'spanish',
        'migration_version': 1,
      });

      final dataService = await LocalDataService.create();

      final config = dataService.getStudyConfiguration();

      // The key feature: v2 migration ensures all languages are enabled
      expect(
        config.enabledConfigurations,
        hasLength(AppLanguage.values.length),
      );

      for (final languageConfig in config.enabledConfigurations) {
        expect(
          languageConfig.isEnabled,
          true,
          reason:
              '${languageConfig.language} should be enabled after v2 migration',
        );
      }

      // Migration creates a valid configuration
      expect(config.currentLanguage, isIn(AppLanguage.values));
    });

    test('v1 to v2 migration handles missing data gracefully', () async {
      // Simulate partial v1 data
      SharedPreferences.setMockInitialValues({
        'latin_enabled': true,
        // Missing other keys - should use defaults
        'migration_version': 1,
      });

      final dataService = await LocalDataService.create();

      final config = dataService.getStudyConfiguration();

      // Should use defaults for missing data
      expect(config.currentLanguage, AppLanguage.latin);

      for (final languageConfig in config.enabledConfigurations) {
        expect(languageConfig.isEnabled, true);
        expect(languageConfig.level, VocabularyLevel.beginner);
      }
    });

    test('fresh install starts with v2 data structure', () async {
      // Clean slate - no existing data
      SharedPreferences.setMockInitialValues({});

      final dataService = await LocalDataService.create();

      final config = dataService.getStudyConfiguration();

      // Should have all languages enabled by default
      expect(config.currentLanguage, AppLanguage.latin);
      expect(
        config.enabledConfigurations,
        hasLength(AppLanguage.values.length),
      );

      for (final languageConfig in config.enabledConfigurations) {
        expect(languageConfig.isEnabled, true);
        expect(languageConfig.level, VocabularyLevel.beginner);
      }
    });

    test('v2 data is not re-migrated', () async {
      // Simulate v2 configuration
      final v2ConfigMap = <String, LanguageStudyConfig>{
        'latin': const LanguageStudyConfig(
          language: AppLanguage.latin,
          level: VocabularyLevel.intermediate,
          isEnabled: false, // Deliberately disabled
        ),
        'spanish': const LanguageStudyConfig(
          language: AppLanguage.spanish,
          level: VocabularyLevel.advanced,
          isEnabled: true,
        ),
      };

      final v2Config = StudyConfigurationSet(
        configurations: v2ConfigMap,
        currentLanguage: AppLanguage.spanish,
      );

      SharedPreferences.setMockInitialValues({
        'study_configuration': jsonEncode(v2Config.toJson()),
        'migration_version': 2,
      });

      final dataService = await LocalDataService.create();

      final config = dataService.getStudyConfiguration();

      // Original v2 configuration should be preserved
      expect(config.currentLanguage, AppLanguage.spanish);

      final latinConfig = config.configurations['latin'];
      expect(latinConfig?.isEnabled, false); // Should remain disabled
      expect(latinConfig?.level, VocabularyLevel.intermediate);

      final spanishConfig = config.configurations['spanish'];
      expect(spanishConfig?.isEnabled, true);
      expect(spanishConfig?.level, VocabularyLevel.advanced);
    });

    test('migration preserves progress data', () async {
      // Simulate v1 configuration with existing progress
      SharedPreferences.setMockInitialValues({
        'selected_language': 'latin', // Use the correct key
        'vocabulary_level': 'beginner',
        'latin_enabled': true,
        'spanish_enabled': false,
        'migration_version': 1,
        // Some existing progress data
        'difficult_words': '["aqua", "terra"]',
        'known_words': '["bonus", "malus"]',
      });

      final dataService = await LocalDataService.create();

      // Migration should preserve progress data
      expect(dataService.isWordDifficult('aqua'), true);
      expect(dataService.isWordDifficult('terra'), true);
      expect(dataService.isWordKnown('bonus'), true);
      expect(dataService.isWordKnown('malus'), true);

      // And enable all languages
      final config = dataService.getStudyConfiguration();
      for (final languageConfig in config.enabledConfigurations) {
        expect(languageConfig.isEnabled, true);
      }
    });

    test('migration handles edge case with invalid language names', () async {
      // Simulate v1 configuration with invalid current language
      SharedPreferences.setMockInitialValues({
        'selected_language': 'invalid_language', // Use the correct key
        'vocabulary_level': 'beginner',
        'latin_enabled': true,
        'spanish_enabled': false,
        'migration_version': 1,
      });

      final dataService = await LocalDataService.create();

      final config = dataService.getStudyConfiguration();

      // Should fallback to default language
      expect(config.currentLanguage, AppLanguage.latin);

      // All languages should still be enabled
      for (final languageConfig in config.enabledConfigurations) {
        expect(languageConfig.isEnabled, true);
      }
    });

    test('migration is idempotent', () async {
      // Simulate v1 configuration
      SharedPreferences.setMockInitialValues({
        'selected_language': 'latin', // Use the correct key
        'vocabulary_level': 'intermediate',
        'latin_enabled': true,
        'spanish_enabled': false,
        'migration_version': 1,
      });

      // First migration
      final dataService1 = await LocalDataService.create();
      final config1 = dataService1.getStudyConfiguration();

      // Reset shared preferences with the result of first migration
      SharedPreferences.setMockInitialValues({
        'study_configuration': jsonEncode(config1.toJson()),
        'migration_version': 2,
      });

      // Second migration (should be no-op)
      final dataService2 = await LocalDataService.create();
      final config2 = dataService2.getStudyConfiguration();

      // Results should be identical
      expect(config1.toJson(), config2.toJson());
    });

    test('migration works with partially corrupted v1 data', () async {
      // Simulate v1 configuration with some corrupted data
      SharedPreferences.setMockInitialValues({
        'selected_language': 'latin', // Use the correct key
        'vocabulary_level': 'invalid_level', // Invalid level
        'latin_enabled': 'not_a_bool', // Invalid boolean
        'spanish_enabled': false,
        'migration_version': 1,
      });

      final dataService = await LocalDataService.create();

      final config = dataService.getStudyConfiguration();

      // Should handle corrupted data gracefully
      expect(config.currentLanguage, AppLanguage.latin);

      // All languages should be enabled (v2 migration)
      for (final languageConfig in config.enabledConfigurations) {
        expect(languageConfig.isEnabled, true);
        // Should use default level when original is invalid
        expect(languageConfig.level, VocabularyLevel.beginner);
      }
    });
  });
}
