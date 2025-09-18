import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_vocab/core/language/language_plugin.dart';
import 'package:octo_vocab/core/language/language_registry.dart';
import 'package:octo_vocab/core/language/models/language.dart';
import 'package:octo_vocab/core/language/models/vocabulary_item.dart';
import 'package:octo_vocab/core/models/vocabulary_level.dart';

// Test plugin implementation
class TestLanguagePlugin extends LanguagePlugin {
  TestLanguagePlugin(this._language, [this._vocabulary = const []]);

  final Language _language;
  final List<VocabularyItem> _vocabulary;

  @override
  Language get language => _language;

  @override
  Future<List<VocabularyItem>> loadVocabulary(VocabularyLevel level, VocabularySet vocabSet) async {
    // For testing, only return vocabulary for the first set to avoid duplicates
    final sets = VocabularySets.getSetsForLevel(level);
    if (vocabSet == sets.first) {
      return _vocabulary;
    }
    // Throw exception for other sets to simulate them not existing
    throw Exception('Mock vocabulary set not found');
  }

  @override
  String formatTerm(VocabularyItem item) => '${item.term} (${language.code})';
}

void main() {
  group('LanguageRegistry', () {
    late LanguageRegistry registry;

    setUp(() {
      registry = LanguageRegistry.instance;
      // Clear any existing plugins from previous tests
      registry.clear();
    });

    test('starts empty', () {
      expect(registry.getAvailableLanguages(), isEmpty);
    });

    test('registers and retrieves a language plugin', () {
      const testLanguage = Language(
        code: 'test',
        name: 'Test Language',
        nativeName: 'Test',
        icon: Icons.abc,
        color: Colors.blue,
      );
      final plugin = TestLanguagePlugin(testLanguage);

      registry.register(plugin);

      expect(registry.getAvailableLanguages(), hasLength(1));
      expect(registry.getAvailableLanguages().first.code, equals('test'));
      expect(registry.getPlugin('test'), equals(plugin));
    });

    test('registers multiple language plugins', () {
      const lang1 = Language(code: 'la', name: 'Latin', nativeName: 'Latina', icon: Icons.abc, color: Colors.brown);
      const lang2 = Language(code: 'es', name: 'Spanish', nativeName: 'Español', icon: Icons.abc, color: Colors.orange);
      
      final plugin1 = TestLanguagePlugin(lang1);
      final plugin2 = TestLanguagePlugin(lang2);

      registry.register(plugin1);
      registry.register(plugin2);

      final languages = registry.getAvailableLanguages();
      expect(languages, hasLength(2));
      expect(languages.map((l) => l.code), containsAll(['la', 'es']));
      
      expect(registry.getPlugin('la'), equals(plugin1));
      expect(registry.getPlugin('es'), equals(plugin2));
    });

    test('checks if language is available', () {
      const testLanguage = Language(code: 'fr', name: 'French', nativeName: 'Français', icon: Icons.abc, color: Colors.blue);
      final plugin = TestLanguagePlugin(testLanguage);

      expect(registry.isLanguageAvailable('fr'), isFalse);
      
      registry.register(plugin);
      
      expect(registry.isLanguageAvailable('fr'), isTrue);
      expect(registry.isLanguageAvailable('de'), isFalse);
    });

    test('returns null for unregistered language', () {
      expect(registry.getPlugin('nonexistent'), isNull);
    });

    test('loads vocabulary through registry', () async {
      const testLanguage = Language(code: 'test', name: 'Test', nativeName: 'Test', icon: Icons.abc, color: Colors.blue);
      final testVocabulary = [
        const VocabularyItem(id: '1', term: 'hello', translation: 'hola'),
        const VocabularyItem(id: '2', term: 'world', translation: 'mundo'),
      ];
      final plugin = TestLanguagePlugin(testLanguage, testVocabulary);

      registry.register(plugin);

      final vocabulary = await registry.loadVocabulary('test', VocabularyLevel.beginner);
      
      expect(vocabulary, hasLength(2));
      expect(vocabulary[0].term, equals('hello'));
      expect(vocabulary[1].term, equals('world'));
    });

    test('throws exception when loading vocabulary for unregistered language', () async {
      expect(
        () => registry.loadVocabulary('nonexistent', VocabularyLevel.beginner),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Language plugin not found: nonexistent'),
        )),
      );
    });

    test('loads specific vocabulary set through registry', () async {
      const testLanguage = Language(code: 'test', name: 'Test', nativeName: 'Test', icon: Icons.abc, color: Colors.blue);
      final testVocabulary = [
        const VocabularyItem(id: '1', term: 'essential', translation: 'esencial'),
      ];
      final plugin = TestLanguagePlugin(testLanguage, testVocabulary);

      registry.register(plugin);

      final vocabSet = VocabularySets.beginner.first; // essentials set
      final vocabulary = await registry.loadVocabularySet('test', VocabularyLevel.beginner, vocabSet);
      
      expect(vocabulary, hasLength(1));
      expect(vocabulary[0].term, equals('essential'));
    });

    test('replaces plugin when registering same language code twice', () {
      const testLanguage = Language(code: 'test', name: 'Test', nativeName: 'Test', icon: Icons.abc, color: Colors.blue);
      final plugin1 = TestLanguagePlugin(testLanguage, [const VocabularyItem(id: '1', term: 'first', translation: 'primero')]);
      final plugin2 = TestLanguagePlugin(testLanguage, [const VocabularyItem(id: '2', term: 'second', translation: 'segundo')]);

      registry.register(plugin1);
      expect(registry.getPlugin('test'), equals(plugin1));

      registry.register(plugin2);
      expect(registry.getPlugin('test'), equals(plugin2));
      expect(registry.getAvailableLanguages(), hasLength(1)); // Still only one language
    });

    test('uses singleton instance', () {
      final instance1 = LanguageRegistry.instance;
      final instance2 = LanguageRegistry.instance;

      expect(identical(instance1, instance2), isTrue);
    });
  });
}