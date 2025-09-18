import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_vocab/core/language/models/vocabulary_item.dart';
import 'package:octo_vocab/core/language/plugins/latin_plugin.dart';
import 'package:octo_vocab/core/language/plugins/spanish_plugin.dart';
import 'package:octo_vocab/core/models/vocabulary_level.dart';

void main() {
  group('LatinPlugin', () {
    late LatinPlugin plugin;

    setUp(() {
      plugin = LatinPlugin();
    });

    test('has correct language metadata', () {
      final language = plugin.language;
      
      expect(language.code, equals('la'));
      expect(language.name, equals('Latin'));
      expect(language.nativeName, equals('Lingua Latina'));
      expect(language.icon, equals(Icons.account_balance));
      expect(language.color, equals(const Color(0xFF8B4513))); // Saddle Brown
      expect(language.description, equals('Classical Latin for academic study'));
    });

    test('formats term correctly', () {
      const item = VocabularyItem(id: 'amor', term: 'amor', translation: 'love');
      
      final formattedTerm = plugin.formatTerm(item);
      
      expect(formattedTerm, equals('amor'));
    });

    test('formats translation correctly', () {
      const item = VocabularyItem(id: 'amor', term: 'amor', translation: 'love');
      
      final formattedTranslation = plugin.formatTranslation(item);
      
      expect(formattedTranslation, equals('love'));
    });

    test('formats example with classical style', () {
      const item = VocabularyItem(
        id: 'veritas',
        term: 'veritas',
        translation: 'truth',
        exampleTerm: 'Veritas vos liberabit',
        exampleTranslation: 'The truth will set you free',
      );
      
      final formattedExample = plugin.formatExample(item);
      
      expect(formattedExample, equals('Veritas vos liberabit — "The truth will set you free"'));
    });

    test('returns null for example when no examples provided', () {
      const item = VocabularyItem(id: 'amor', term: 'amor', translation: 'love');
      
      final formattedExample = plugin.formatExample(item);
      
      expect(formattedExample, isNull);
    });

    test('provides learning tips', () {
      final tips = plugin.getLearningTips();
      
      expect(tips, isNotEmpty);
      expect(tips, contains(matches(RegExp(r'case endings', caseSensitive: false))));
      expect(tips, contains(matches(RegExp(r'verb conjugation', caseSensitive: false))));
    });

    test('has correct quiz choice count', () {
      expect(plugin.getQuizChoiceCount(), equals(4));
    });

    test('generates correct asset path', () {
      final vocabSet = VocabularySets.beginner.first;
      final path = plugin.getVocabularyAssetPath(VocabularyLevel.beginner, vocabSet);
      
      expect(path, equals('assets/vocab/latin/beginner/${vocabSet.filename}'));
    });

    test('generates correct progress key', () {
      const wordId = 'amor';
      final progressKey = plugin.getProgressKey(wordId);
      
      expect(progressKey, equals('la_amor'));
    });
  });

  group('SpanishPlugin', () {
    late SpanishPlugin plugin;

    setUp(() {
      plugin = SpanishPlugin();
    });

    test('has correct language metadata', () {
      final language = plugin.language;
      
      expect(language.code, equals('es'));
      expect(language.name, equals('Spanish'));
      expect(language.nativeName, equals('Español'));
      expect(language.icon, equals(Icons.language));
      expect(language.color, equals(const Color(0xFFFF6B35))); // Spanish Orange
      expect(language.description, equals('Modern Spanish for communication'));
    });

    test('formats term correctly', () {
      const item = VocabularyItem(id: 'casa', term: 'casa', translation: 'house');
      
      final formattedTerm = plugin.formatTerm(item);
      
      expect(formattedTerm, equals('casa'));
    });

    test('formats translation correctly', () {
      const item = VocabularyItem(id: 'casa', term: 'casa', translation: 'house');
      
      final formattedTranslation = plugin.formatTranslation(item);
      
      expect(formattedTranslation, equals('house'));
    });

    test('formats example with modern style', () {
      const item = VocabularyItem(
        id: 'hola',
        term: 'hola',
        translation: 'hello',
        exampleTerm: 'Hola, ¿cómo estás?',
        exampleTranslation: 'Hello, how are you?',
      );
      
      final formattedExample = plugin.formatExample(item);
      
      expect(formattedExample, equals('"Hola, ¿cómo estás?" → "Hello, how are you?"'));
    });

    test('returns null for example when no examples provided', () {
      const item = VocabularyItem(id: 'casa', term: 'casa', translation: 'house');
      
      final formattedExample = plugin.formatExample(item);
      
      expect(formattedExample, isNull);
    });

    test('provides learning tips', () {
      final tips = plugin.getLearningTips();
      
      expect(tips, isNotEmpty);
      expect(tips, contains(matches(RegExp(r'masculine and feminine', caseSensitive: false))));
      expect(tips, contains(matches(RegExp(r'verb conjugations', caseSensitive: false))));
    });

    test('has correct quiz choice count', () {
      expect(plugin.getQuizChoiceCount(), equals(4));
    });

    test('generates correct asset path', () {
      final vocabSet = VocabularySets.beginner.first;
      final path = plugin.getVocabularyAssetPath(VocabularyLevel.beginner, vocabSet);
      
      expect(path, equals('assets/vocab/spanish/beginner/${vocabSet.filename}'));
    });

    test('generates correct progress key', () {
      const wordId = 'casa';
      final progressKey = plugin.getProgressKey(wordId);
      
      expect(progressKey, equals('es_casa'));
    });
  });

  group('Plugin Comparison', () {
    test('plugins have different language codes', () {
      final latinPlugin = LatinPlugin();
      final spanishPlugin = SpanishPlugin();
      
      expect(latinPlugin.language.code, isNot(equals(spanishPlugin.language.code)));
      expect(latinPlugin.language.name, isNot(equals(spanishPlugin.language.name)));
    });

    test('plugins have different colors and icons', () {
      final latinPlugin = LatinPlugin();
      final spanishPlugin = SpanishPlugin();
      
      expect(latinPlugin.language.color, isNot(equals(spanishPlugin.language.color)));
      expect(latinPlugin.language.icon, isNot(equals(spanishPlugin.language.icon)));
    });

    test('plugins format examples differently', () {
      final latinPlugin = LatinPlugin();
      final spanishPlugin = SpanishPlugin();
      
      const item = VocabularyItem(
        id: 'test',
        term: 'test',
        translation: 'test',
        exampleTerm: 'Example term',
        exampleTranslation: 'Example translation',
      );
      
      final latinExample = latinPlugin.formatExample(item);
      final spanishExample = spanishPlugin.formatExample(item);
      
      expect(latinExample, contains('—')); // Classical dash
      expect(spanishExample, contains('→')); // Modern arrow
    });
  });
}