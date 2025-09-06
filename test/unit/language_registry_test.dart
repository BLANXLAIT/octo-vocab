import 'package:flutter_saas_template/core/models/language_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LanguageRegistry Tests', () {
    test('provides correct language definitions', () {
      // Test available languages
      final availableLanguages = LanguageRegistry.availableLanguages;

      expect(availableLanguages.length, equals(2));
      expect(availableLanguages.every((lang) => lang.isAvailable), true);

      final codes = availableLanguages.map((lang) => lang.code).toSet();
      expect(codes, containsAll(['latin', 'spanish']));
    });

    test('getLanguage returns correct definitions', () {
      final latin = LanguageRegistry.getLanguage('latin');
      final spanish = LanguageRegistry.getLanguage('spanish');
      final nonExistent = LanguageRegistry.getLanguage('klingon');

      expect(latin?.displayName, 'Latin');
      expect(latin?.isAvailable, true);
      expect(latin?.primaryColor.value, isNotNull);

      expect(spanish?.displayName, 'Spanish');
      expect(spanish?.isAvailable, true);
      expect(spanish?.family, LanguageFamily.romance);

      expect(nonExistent, isNull);
    });

    test('filters languages by family correctly', () {
      final romanceLanguages = LanguageRegistry.getLanguagesByFamily(
        LanguageFamily.romance,
      );

      expect(
        romanceLanguages.any((lang) => lang.code == 'spanish'),
        true,
        reason: 'Spanish should be in romance languages',
      );
      expect(
        romanceLanguages.any((lang) => lang.code == 'french'),
        true,
        reason: 'French should be in romance languages (even if unavailable)',
      );
    });

    test('future languages are marked as unavailable', () {
      final allLanguages = LanguageRegistry.allLanguages;
      final futureLanguages = allLanguages
          .where((lang) => !lang.isAvailable)
          .map((lang) => lang.code)
          .toSet();

      expect(futureLanguages, containsAll(['french', 'german']));
    });

    test('language properties are consistent', () {
      for (final language in LanguageRegistry.allLanguages) {
        expect(language.code, isNotEmpty);
        expect(language.displayName, isNotEmpty);
        expect(language.nativeName, isNotEmpty);
        expect(language.flag, isNotEmpty);
        expect(language.primaryColor, isNotNull);
        expect(language.family, isNotNull);
        expect(language.writingSystem, isNotNull);
      }
    });

    test('supports language checking', () {
      expect(LanguageRegistry.isSupported('latin'), true);
      expect(LanguageRegistry.isSupported('spanish'), true);
      expect(
        LanguageRegistry.isSupported('french'),
        true,
      ); // Defined but unavailable
      expect(LanguageRegistry.isSupported('klingon'), false);
    });

    test('provides available language codes', () {
      final codes = LanguageRegistry.availableLanguageCodes;
      expect(codes, containsAll(['latin', 'spanish']));
      expect(codes, isNot(contains('french'))); // French is unavailable
    });
  });

  group('LanguageFamily Tests', () {
    test('family labels are correct', () {
      expect(LanguageFamily.romance.label, 'Romance Languages');
      expect(LanguageFamily.germanic.label, 'Germanic Languages');
      expect(LanguageFamily.other.label, 'Other Languages');
    });
  });

  group('WritingSystem Tests', () {
    test('writing system labels are correct', () {
      expect(WritingSystem.latin.label, 'Latin Script');
      expect(WritingSystem.cyrillic.label, 'Cyrillic Script');
      expect(WritingSystem.arabic.label, 'Arabic Script');
    });

    test('provides correct font requirements', () {
      expect(WritingSystem.latin.needsSpecialFont, false);
      expect(WritingSystem.arabic.needsSpecialFont, true);
      expect(WritingSystem.chinese.needsSpecialFont, true);
    });
  });
}
