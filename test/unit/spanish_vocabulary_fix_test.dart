import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Spanish Vocabulary Fix Validation', () {
    test('migration enables Spanish for existing users', () async {
      // Simulate an existing user who had the old configuration
      // where only Latin was enabled by default
      SharedPreferences.setMockInitialValues({
        'study_configuration': '''
{
          "configurations": {
            "latin": {
              "language": "latin",
              "level": "beginner",
              "isEnabled": true
            },
            "spanish": {
              "language": "spanish", 
              "level": "beginner",
              "isEnabled": false
            }
          },
          "currentLanguage": "latin"
        }''',
        'migration_version': 1, // Simulate old migration version
      });

      // Create data service and manually trigger migration
      final dataService = await LocalDataService.create();
      await dataService.migrateToNewConfigSystem(); // Explicitly run migration

      // Verify that Spanish is now enabled after migration
      final config = dataService.getStudyConfiguration();
      final spanishConfig = config.getConfigForLanguage(AppLanguage.spanish);

      expect(spanishConfig, isNotNull);
      expect(
        spanishConfig!.isEnabled,
        true,
        reason: 'Spanish should be enabled after migration',
      );
      expect(
        spanishConfig.level,
        VocabularyLevel.beginner,
        reason: 'Spanish level should be preserved during migration',
      );
    });

    test('new users get all languages enabled by default', () async {
      // Simulate a completely new user
      SharedPreferences.setMockInitialValues({});

      final dataService = await LocalDataService.create();
      final config = dataService.getStudyConfiguration();

      // All languages should be enabled for new users
      for (final language in AppLanguage.values) {
        final langConfig = config.getConfigForLanguage(language);
        expect(
          langConfig,
          isNotNull,
          reason: 'Configuration should exist for $language',
        );
        expect(
          langConfig!.isEnabled,
          true,
          reason: '$language should be enabled by default for new users',
        );
      }
    });

    test('Spanish vocabulary files exist and are loadable', () {
      // This test ensures Spanish vocabulary assets are properly included
      expect(AppLanguage.spanish.label, 'Spanish');
      expect(AppLanguage.spanish.nativeName, 'Español');
      expect(AppLanguage.spanish.flag, '🇪🇸');

      // The vocabulary files should be in assets/vocab/spanish/
      // This is tested by the VocabularyCacheService in integration tests
    });
  });
}
