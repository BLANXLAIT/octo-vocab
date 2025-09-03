// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, directives_ordering

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/language_study_config.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';

void main() {
  group('LanguageStudyConfig Tests', () {
    test('creates config with correct properties', () {
      const config = LanguageStudyConfig(
        language: AppLanguage.latin,
        level: VocabularyLevel.beginner,
        isEnabled: true,
      );

      expect(config.language, AppLanguage.latin);
      expect(config.level, VocabularyLevel.beginner);
      expect(config.isEnabled, true);
    });

    test('copyWith updates properties correctly', () {
      const original = LanguageStudyConfig(
        language: AppLanguage.latin,
        level: VocabularyLevel.beginner,
        isEnabled: false,
      );

      final updated = original.copyWith(
        level: VocabularyLevel.advanced,
        isEnabled: true,
      );

      expect(updated.language, AppLanguage.latin); // unchanged
      expect(updated.level, VocabularyLevel.advanced); // changed
      expect(updated.isEnabled, true); // changed
    });

    test('equality and hashCode work correctly', () {
      const config1 = LanguageStudyConfig(
        language: AppLanguage.latin,
        level: VocabularyLevel.beginner,
        isEnabled: true,
      );

      const config2 = LanguageStudyConfig(
        language: AppLanguage.latin,
        level: VocabularyLevel.beginner,
        isEnabled: true,
      );

      const config3 = LanguageStudyConfig(
        language: AppLanguage.spanish,
        level: VocabularyLevel.beginner,
        isEnabled: true,
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1, isNot(equals(config3)));
    });

    test('JSON serialization works correctly', () {
      const config = LanguageStudyConfig(
        language: AppLanguage.spanish,
        level: VocabularyLevel.intermediate,
        isEnabled: true,
      );

      final json = config.toJson();
      final restored = LanguageStudyConfig.fromJson(json);

      expect(restored.language, AppLanguage.spanish);
      expect(restored.level, VocabularyLevel.intermediate);
      expect(restored.isEnabled, true);
      expect(restored, equals(config));
    });

    test('handles invalid JSON gracefully', () {
      final invalidJson = {
        'language': 'nonexistent',
        'level': 'invalid',
        'isEnabled': true,
      };

      final config = LanguageStudyConfig.fromJson(invalidJson);

      // Should fallback to defaults for invalid values
      expect(config.language, AppLanguage.latin);
      expect(config.level, VocabularyLevel.beginner);
      expect(config.isEnabled, true);
    });

    test('toString provides useful debug information', () {
      const config = LanguageStudyConfig(
        language: AppLanguage.latin,
        level: VocabularyLevel.advanced,
        isEnabled: false,
      );

      final string = config.toString();
      expect(string, contains('LanguageStudyConfig'));
      expect(string, contains('latin'));
      expect(string, contains('advanced'));
      expect(string, contains('false'));
    });
  });

  group('StudyConfigurationSet Tests', () {
    test('creates default configuration correctly', () {
      final configSet = StudyConfigurationSet.createDefault();

      expect(configSet.currentLanguage, AppLanguage.latin);
      expect(configSet.configurations, hasLength(AppLanguage.values.length));

      // Only Latin should be enabled by default
      final enabledConfigs = configSet.enabledConfigurations;
      expect(enabledConfigs, hasLength(1));
      expect(enabledConfigs.first.language, AppLanguage.latin);
      expect(enabledConfigs.first.level, VocabularyLevel.beginner);
    });

    test('gets current configuration correctly', () {
      final configSet = StudyConfigurationSet.createDefault();
      final currentConfig = configSet.currentConfiguration;

      expect(currentConfig, isNotNull);
      expect(currentConfig!.language, AppLanguage.latin);
      expect(currentConfig.isEnabled, true);
    });

    test('gets configuration for specific language', () {
      final configSet = StudyConfigurationSet.createDefault();

      final latinConfig = configSet.getConfigForLanguage(AppLanguage.latin);
      final spanishConfig = configSet.getConfigForLanguage(AppLanguage.spanish);

      expect(latinConfig, isNotNull);
      expect(latinConfig!.language, AppLanguage.latin);
      expect(latinConfig.isEnabled, true);

      expect(spanishConfig, isNotNull);
      expect(spanishConfig!.language, AppLanguage.spanish);
      expect(spanishConfig.isEnabled, false);
    });

    test('updates language configuration correctly', () {
      final original = StudyConfigurationSet.createDefault();

      const newSpanishConfig = LanguageStudyConfig(
        language: AppLanguage.spanish,
        level: VocabularyLevel.advanced,
        isEnabled: true,
      );

      final updated = original.updateLanguageConfig(
        AppLanguage.spanish,
        newSpanishConfig,
      );

      final spanishConfig = updated.getConfigForLanguage(AppLanguage.spanish);
      expect(spanishConfig, isNotNull);
      expect(spanishConfig!.level, VocabularyLevel.advanced);
      expect(spanishConfig.isEnabled, true);

      // Original should be unchanged
      final originalSpanish = original.getConfigForLanguage(
        AppLanguage.spanish,
      );
      expect(originalSpanish!.isEnabled, false);
    });

    test('changes current language correctly', () {
      final original = StudyConfigurationSet.createDefault();
      final updated = original.withCurrentLanguage(AppLanguage.spanish);

      expect(updated.currentLanguage, AppLanguage.spanish);
      expect(original.currentLanguage, AppLanguage.latin); // Original unchanged
    });

    test('filters enabled configurations correctly', () {
      var configSet = StudyConfigurationSet.createDefault();

      // Enable Spanish
      const spanishConfig = LanguageStudyConfig(
        language: AppLanguage.spanish,
        level: VocabularyLevel.intermediate,
        isEnabled: true,
      );
      configSet = configSet.updateLanguageConfig(
        AppLanguage.spanish,
        spanishConfig,
      );

      final enabled = configSet.enabledConfigurations;
      expect(enabled, hasLength(2));
      expect(
        enabled.map((c) => c.language),
        containsAll([AppLanguage.latin, AppLanguage.spanish]),
      );
    });

    test('JSON serialization works for full configuration set', () {
      var configSet = StudyConfigurationSet.createDefault();

      // Enable Spanish with different level
      const spanishConfig = LanguageStudyConfig(
        language: AppLanguage.spanish,
        level: VocabularyLevel.advanced,
        isEnabled: true,
      );
      configSet = configSet.updateLanguageConfig(
        AppLanguage.spanish,
        spanishConfig,
      );
      configSet = configSet.withCurrentLanguage(AppLanguage.spanish);

      final json = configSet.toJson();
      final restored = StudyConfigurationSet.fromJson(json);

      expect(restored.currentLanguage, AppLanguage.spanish);
      expect(restored.enabledConfigurations, hasLength(2));

      final restoredSpanish = restored.getConfigForLanguage(
        AppLanguage.spanish,
      );
      expect(restoredSpanish!.level, VocabularyLevel.advanced);
      expect(restoredSpanish.isEnabled, true);
    });

    test('equality works correctly', () {
      final config1 = StudyConfigurationSet.createDefault();
      final config2 = StudyConfigurationSet.createDefault();

      expect(config1, equals(config2));

      final config3 = config1.withCurrentLanguage(AppLanguage.spanish);
      expect(config1, isNot(equals(config3)));
    });

    test('handles empty or invalid JSON gracefully', () {
      final emptyConfig = StudyConfigurationSet.fromJson({});
      expect(emptyConfig.currentLanguage, AppLanguage.latin);
      expect(emptyConfig.configurations, isNotEmpty); // Should create default

      final invalidConfig = StudyConfigurationSet.fromJson({
        'currentLanguage': 'invalid',
        'configurations': 'not a map',
      });
      expect(invalidConfig.currentLanguage, AppLanguage.latin);
      expect(invalidConfig.configurations, isNotEmpty); // Should create default
    });
  });
}
