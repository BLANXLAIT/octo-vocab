import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_saas_template/core/language/models/language.dart';

void main() {
  group('Language', () {
    test('creates a complete language', () {
      const language = Language(
        code: 'la',
        name: 'Latin',
        nativeName: 'Lingua Latina',
        icon: Icons.account_balance,
        color: Colors.brown,
        description: 'Classical Latin',
      );

      expect(language.code, equals('la'));
      expect(language.name, equals('Latin'));
      expect(language.nativeName, equals('Lingua Latina'));
      expect(language.icon, equals(Icons.account_balance));
      expect(language.color, equals(Colors.brown));
      expect(language.description, equals('Classical Latin'));
    });

    test('creates a language without description', () {
      const language = Language(
        code: 'es',
        name: 'Spanish',
        nativeName: 'Español',
        icon: Icons.language,
        color: Colors.orange,
      );

      expect(language.code, equals('es'));
      expect(language.name, equals('Spanish'));
      expect(language.nativeName, equals('Español'));
      expect(language.icon, equals(Icons.language));
      expect(language.color, equals(Colors.orange));
      expect(language.description, isNull);
    });

    test('equality is based on language code', () {
      const language1 = Language(
        code: 'fr',
        name: 'French',
        nativeName: 'Français',
        icon: Icons.language,
        color: Colors.blue,
      );
      
      const language2 = Language(
        code: 'fr',
        name: 'French (Different Name)',
        nativeName: 'Le Français',
        icon: Icons.flag,
        color: Colors.red,
      );
      
      const language3 = Language(
        code: 'de',
        name: 'German',
        nativeName: 'Deutsch',
        icon: Icons.language,
        color: Colors.yellow,
      );

      expect(language1, equals(language2)); // Same code
      expect(language1, isNot(equals(language3))); // Different code
      expect(language1.hashCode, equals(language2.hashCode));
      expect(language1.hashCode, isNot(equals(language3.hashCode)));
    });

    test('toString shows code and name', () {
      const language = Language(
        code: 'it',
        name: 'Italian',
        nativeName: 'Italiano',
        icon: Icons.language,
        color: Colors.green,
      );

      expect(language.toString(), equals('Language(code: it, name: Italian)'));
    });

    test('handles common language codes', () {
      const languages = [
        Language(code: 'en', name: 'English', nativeName: 'English', icon: Icons.language, color: Colors.blue),
        Language(code: 'es', name: 'Spanish', nativeName: 'Español', icon: Icons.language, color: Colors.orange),
        Language(code: 'fr', name: 'French', nativeName: 'Français', icon: Icons.language, color: Colors.blue),
        Language(code: 'de', name: 'German', nativeName: 'Deutsch', icon: Icons.language, color: Colors.red),
        Language(code: 'it', name: 'Italian', nativeName: 'Italiano', icon: Icons.language, color: Colors.green),
        Language(code: 'la', name: 'Latin', nativeName: 'Lingua Latina', icon: Icons.account_balance, color: Colors.brown),
      ];

      expect(languages.map((l) => l.code), equals(['en', 'es', 'fr', 'de', 'it', 'la']));
      expect(languages.map((l) => l.name), equals(['English', 'Spanish', 'French', 'German', 'Italian', 'Latin']));
    });
  });
}