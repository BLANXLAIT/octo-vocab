import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/language_study_config.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';

void main() {
  group('LocalDataService Study Configuration Tests', () {
    late LocalDataService dataService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dataService = await LocalDataService.create();
    });

    group('Study Configuration Management', () {
      test('creates default configuration on first access', () {
        final config = dataService.getStudyConfiguration();

        expect(config.currentLanguage, AppLanguage.latin);
        expect(config.enabledConfigurations, hasLength(1));
        expect(config.enabledConfigurations.first.language, AppLanguage.latin);
        expect(
          config.enabledConfigurations.first.level,
          VocabularyLevel.beginner,
        );
        expect(config.enabledConfigurations.first.isEnabled, true);
      });

      test('saves and retrieves configuration correctly', () async {
        var config = dataService.getStudyConfiguration();

        // Enable Spanish with advanced level
        const spanishConfig = LanguageStudyConfig(
          language: AppLanguage.spanish,
          level: VocabularyLevel.advanced,
          isEnabled: true,
        );

        config = config.updateLanguageConfig(
          AppLanguage.spanish,
          spanishConfig,
        );
        await dataService.setStudyConfiguration(config);

        // Retrieve and verify
        final retrievedConfig = dataService.getStudyConfiguration();
        final spanishRetrieved = retrievedConfig.getConfigForLanguage(
          AppLanguage.spanish,
        );

        expect(spanishRetrieved, isNotNull);
        expect(spanishRetrieved!.isEnabled, true);
        expect(spanishRetrieved.level, VocabularyLevel.advanced);
      });

      test('updates individual language configuration', () async {
        const newConfig = LanguageStudyConfig(
          language: AppLanguage.spanish,
          level: VocabularyLevel.intermediate,
          isEnabled: true,
        );

        await dataService.updateLanguageConfig(AppLanguage.spanish, newConfig);

        final config = dataService.getStudyConfiguration();
        final spanishConfig = config.getConfigForLanguage(AppLanguage.spanish);

        expect(spanishConfig, isNotNull);
        expect(spanishConfig!.level, VocabularyLevel.intermediate);
        expect(spanishConfig.isEnabled, true);
      });

      test('sets current language correctly', () async {
        await dataService.setCurrentLanguage(AppLanguage.spanish);

        final config = dataService.getStudyConfiguration();
        expect(config.currentLanguage, AppLanguage.spanish);
      });

      test('gets enabled language configurations', () async {
        // Enable Spanish
        const spanishConfig = LanguageStudyConfig(
          language: AppLanguage.spanish,
          level: VocabularyLevel.beginner,
          isEnabled: true,
        );
        await dataService.updateLanguageConfig(
          AppLanguage.spanish,
          spanishConfig,
        );

        final enabledConfigs = dataService.getEnabledLanguageConfigs();

        expect(enabledConfigs, hasLength(2)); // Latin (default) + Spanish
        expect(
          enabledConfigs.map((c) => c.language),
          containsAll([AppLanguage.latin, AppLanguage.spanish]),
        );
      });

      test('gets current language configuration', () async {
        final currentConfig = dataService.getCurrentLanguageConfig();

        expect(currentConfig, isNotNull);
        expect(currentConfig!.language, AppLanguage.latin);
        expect(currentConfig.isEnabled, true);
      });

      test('handles corrupted configuration gracefully', () async {
        // Simulate corrupted data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('study_configuration', 'invalid json');

        // Should return default configuration
        final config = dataService.getStudyConfiguration();
        expect(config.currentLanguage, AppLanguage.latin);
        expect(config.enabledConfigurations, hasLength(1));
      });
    });

    group('Migration Tests', () {
      test('migrates from old language selection', () async {
        // Setup old system data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('selected_language', 'spanish');
        // The studying languages is stored as JSON string
        await prefs.setString('studying_languages', '["latin", "spanish"]');

        // Run migration
        await dataService.migrateToNewConfigSystem();

        final config = dataService.getStudyConfiguration();

        // Should have migrated current language
        expect(config.currentLanguage, AppLanguage.spanish);

        // Should have enabled both languages
        final enabledConfigs = config.enabledConfigurations;
        expect(enabledConfigs, hasLength(2));
        expect(
          enabledConfigs.map((c) => c.language),
          containsAll([AppLanguage.latin, AppLanguage.spanish]),
        );
      });

      test('migration is idempotent', () async {
        await dataService.migrateToNewConfigSystem();
        final configAfterFirst = dataService.getStudyConfiguration();

        await dataService.migrateToNewConfigSystem();
        final configAfterSecond = dataService.getStudyConfiguration();

        expect(configAfterFirst.toJson(), equals(configAfterSecond.toJson()));
      });

      test('migration handles missing old data gracefully', () async {
        // No old data exists
        await dataService.migrateToNewConfigSystem();

        final config = dataService.getStudyConfiguration();
        expect(config.currentLanguage, AppLanguage.latin);
        expect(config.enabledConfigurations, hasLength(1));
      });
    });

    group('Per-Language Word Tracking Integration', () {
      test('tracks words for specific languages', () async {
        // Enable Spanish
        const spanishConfig = LanguageStudyConfig(
          language: AppLanguage.spanish,
          level: VocabularyLevel.beginner,
          isEnabled: true,
        );
        await dataService.updateLanguageConfig(
          AppLanguage.spanish,
          spanishConfig,
        );

        // Track words for different languages
        await dataService.markWordAsDifficultForLanguage('word1', 'latin');
        await dataService.markWordAsDifficultForLanguage('word2', 'spanish');
        await dataService.markWordAsKnownForLanguage('word3', 'latin');

        // Verify separate tracking
        final latinDifficult = dataService.getDifficultWordsForLanguage(
          'latin',
        );
        final spanishDifficult = dataService.getDifficultWordsForLanguage(
          'spanish',
        );
        final latinKnown = dataService.getKnownWordsForLanguage('latin');

        expect(latinDifficult, contains('word1'));
        expect(latinDifficult, isNot(contains('word2')));
        expect(spanishDifficult, contains('word2'));
        expect(spanishDifficult, isNot(contains('word1')));
        expect(latinKnown, contains('word3'));
      });

      test('provides statistics per language', () async {
        // Setup data
        await dataService.markWordAsDifficultForLanguage('word1', 'latin');
        await dataService.markWordAsDifficultForLanguage('word2', 'latin');
        await dataService.markWordAsKnownForLanguage('word3', 'latin');

        await dataService.markWordAsDifficultForLanguage('word4', 'spanish');
        await dataService.markWordAsKnownForLanguage('word5', 'spanish');
        await dataService.markWordAsKnownForLanguage('word6', 'spanish');

        // Check stats
        final latinStats = dataService.getLearningStatsForLanguage('latin');
        final spanishStats = dataService.getLearningStatsForLanguage('spanish');

        expect(latinStats['difficult_count'], 2);
        expect(latinStats['known_count'], 1);
        expect(latinStats['total_studied'], 3);

        expect(spanishStats['difficult_count'], 1);
        expect(spanishStats['known_count'], 2);
        expect(spanishStats['total_studied'], 3);
      });
    });

    group('Data Reset', () {
      test('resets all configuration data', () async {
        // Setup some data
        const spanishConfig = LanguageStudyConfig(
          language: AppLanguage.spanish,
          level: VocabularyLevel.advanced,
          isEnabled: true,
        );
        await dataService.updateLanguageConfig(
          AppLanguage.spanish,
          spanishConfig,
        );
        await dataService.setCurrentLanguage(AppLanguage.spanish);

        // Reset
        await dataService.resetAllData();

        // Verify reset
        final config = dataService.getStudyConfiguration();
        expect(config.currentLanguage, AppLanguage.latin);
        expect(config.enabledConfigurations, hasLength(1));
        expect(config.enabledConfigurations.first.language, AppLanguage.latin);
      });
    });
  });
}
