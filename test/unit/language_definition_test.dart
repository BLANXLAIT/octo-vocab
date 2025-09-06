import 'package:flutter_saas_template/core/models/language_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LanguageDefinition Tests', () {
    test('LanguageRegistry returns correct available languages', () {
      final availableLanguages = LanguageRegistry.availableLanguages;

      expect(availableLanguages.length, 2); // Latin and Spanish
      expect(availableLanguages.any((lang) => lang.code == 'latin'), true);
      expect(availableLanguages.any((lang) => lang.code == 'spanish'), true);
      expect(availableLanguages.every((lang) => lang.isAvailable), true);
    });

    test('LanguageRegistry getLanguage works correctly', () {
      final latin = LanguageRegistry.getLanguage('latin');
      final spanish = LanguageRegistry.getLanguage('spanish');
      final french = LanguageRegistry.getLanguage('french');
      final nonExistent = LanguageRegistry.getLanguage('klingon');

      expect(latin?.displayName, 'Latin');
      expect(latin?.flag, '🏛️');
      expect(latin?.isAvailable, true);

      expect(spanish?.displayName, 'Spanish');
      expect(spanish?.flag, '🇪🇸');
      expect(spanish?.isAvailable, true);

      expect(french?.displayName, 'French');
      expect(french?.isAvailable, false); // French exists but is unavailable

      expect(nonExistent, isNull); // Klingon not defined
    });

    test('LanguageRegistry includes future languages as unavailable', () {
      final allLanguages = LanguageRegistry.allLanguages;

      expect(
        allLanguages.length,
        greaterThan(2),
      ); // Should include future languages

      final french = allLanguages.firstWhere(
        (lang) => lang.code == 'french',
        orElse: () => throw Exception('French not found'),
      );
      expect(french.isAvailable, false);
      expect(french.displayName, 'French');
    });

    test('LanguageRegistry filtering by family works', () {
      final romanceLanguages = LanguageRegistry.getLanguagesByFamily(
        LanguageFamily.romance,
      );

      expect(romanceLanguages.any((lang) => lang.code == 'spanish'), true);
      expect(romanceLanguages.any((lang) => lang.code == 'french'), true);
      expect(
        romanceLanguages.any((lang) => lang.code == 'latin'),
        false,
      ); // Latin is classified as 'other'
    });

    test('Language definitions have required properties', () {
      final latin = LanguageRegistry.getLanguage('latin')!;

      expect(latin.code, isNotEmpty);
      expect(latin.displayName, isNotEmpty);
      expect(latin.nativeName, isNotEmpty);
      expect(latin.flag, isNotEmpty);
      expect(latin.primaryColor, isNotNull);
      expect(latin.family, isNotNull);
      expect(latin.writingSystem, isNotNull);
    });
  });
}
