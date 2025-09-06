import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/language_study_config.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/providers/study_config_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('StudyConfigurationProviders Integration Tests', () {
    late ProviderContainer container;

    setUp(() async {
      // Reset shared preferences for each test
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    Future<StudyConfigurationSet> waitForConfiguration() async {
      AsyncValue<StudyConfigurationSet> config;
      int attempts = 0;
      do {
        await Future<void>.delayed(const Duration(milliseconds: 10));
        config = container.read(studyConfigurationProvider);
        attempts++;
      } while (config is AsyncLoading && attempts < 100);

      if (config is AsyncError) {
        throw config.error ?? 'Unknown error';
      }

      return config.value!;
    }

    test('studyConfigurationProvider loads default configuration', () async {
      final configAsync = container.read(studyConfigurationProvider);

      expect(configAsync, isA<AsyncLoading<StudyConfigurationSet>>());

      final config = await waitForConfiguration();
      expect(config.currentLanguage, AppLanguage.latin);
      expect(
        config.enabledConfigurations,
        hasLength(AppLanguage.values.length),
      );
    });

    test('currentLanguageProvider returns correct language', () async {
      await waitForConfiguration();

      final currentLanguage = container.read(currentLanguageProvider);
      expect(currentLanguage, AppLanguage.latin);
    });

    test(
      'currentLanguageConfigProvider returns correct configuration',
      () async {
        await waitForConfiguration();

        final currentConfig = container.read(currentLanguageConfigProvider);
        expect(currentConfig, isNotNull);
        expect(currentConfig!.language, AppLanguage.latin);
        expect(currentConfig.isEnabled, true);
      },
    );

    test('enabledLanguageConfigsProvider filters correctly', () async {
      await waitForConfiguration();

      final enabledConfigs = container.read(enabledLanguageConfigsProvider);
      expect(enabledConfigs, hasLength(AppLanguage.values.length));
      expect(enabledConfigs.every((config) => config.isEnabled), true);
    });

    test('isLanguageEnabledProvider works for each language', () async {
      await waitForConfiguration();

      for (final language in AppLanguage.values) {
        final isEnabled = container.read(isLanguageEnabledProvider(language));
        expect(
          isEnabled,
          true,
          reason: '$language should be enabled by default',
        );
      }
    });

    test(
      'languageConfigProvider returns correct config for each language',
      () async {
        await waitForConfiguration();

        for (final language in AppLanguage.values) {
          final config = container.read(languageConfigProvider(language));
          expect(config, isNotNull);
          expect(config!.language, language);
          expect(config.isEnabled, true);
        }
      },
    );

    test('provider updates when configuration changes', () async {
      await waitForConfiguration();

      final notifier = container.read(studyConfigurationProvider.notifier);

      // Change current language to Spanish
      await notifier.setCurrentLanguage(AppLanguage.spanish);

      final currentLanguage = container.read(currentLanguageProvider);
      expect(currentLanguage, AppLanguage.spanish);
    });

    test('provider updates when language config changes', () async {
      await waitForConfiguration();

      final notifier = container.read(studyConfigurationProvider.notifier);

      // Update Spanish configuration
      const newSpanishConfig = LanguageStudyConfig(
        language: AppLanguage.spanish,
        level: VocabularyLevel.advanced,
        isEnabled: true,
      );

      await notifier.updateLanguageConfig(
        AppLanguage.spanish,
        newSpanishConfig,
      );

      final spanishConfig = container.read(
        languageConfigProvider(AppLanguage.spanish),
      );
      expect(spanishConfig?.level, VocabularyLevel.advanced);
    });

    test('currentLevelProvider returns correct level', () async {
      await waitForConfiguration();

      final currentLevel = container.read(currentLevelProvider);
      expect(currentLevel, VocabularyLevel.beginner);
    });

    test('provider handles errors gracefully', () async {
      // Simulate corrupted data
      SharedPreferences.setMockInitialValues({
        'study_configuration': 'invalid json',
      });

      final newContainer = ProviderContainer();

      try {
        // Wait for initialization with error handling
        AsyncValue<StudyConfigurationSet> config;
        int attempts = 0;
        do {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          config = newContainer.read(studyConfigurationProvider);
          attempts++;
        } while (config is AsyncLoading && attempts < 100);

        // Should recover with default configuration
        if (config is AsyncData) {
          expect(config.value!.currentLanguage, AppLanguage.latin);
        } else if (config is AsyncError) {
          // Error is expected with corrupted data
          expect(config.error, isNotNull);
        }
      } finally {
        newContainer.dispose();
      }
    });
  });
}
