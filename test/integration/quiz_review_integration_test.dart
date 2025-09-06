import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/language_study_config.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/models/word.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';

void main() {
  group('Quiz Review Integration Tests', () {
    late LocalDataService dataService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dataService = await LocalDataService.create();
      
      // Enable Spanish for testing
      final spanishConfig = LanguageStudyConfig(
        language: AppLanguage.spanish,
        level: VocabularyLevel.beginner,
        isEnabled: true,
      );
      await dataService.updateLanguageConfig(AppLanguage.spanish, spanishConfig);
      await dataService.setCurrentLanguage(AppLanguage.spanish);
    });

    test('quiz wrong answers are added to review list', () async {
      final testWord = Word(
        id: 'test_quiz_word',
        latin: 'hola',
        english: 'hello',
        pos: 'interjection',
      );

      // Simulate getting quiz question wrong
      await dataService.markWordAsDifficultForLanguage(
        testWord.id,
        AppLanguage.spanish.name,
      );

      // Verify word is now in difficult/review list for Spanish
      final difficultWords = dataService.getDifficultWordsForLanguage(
        AppLanguage.spanish.name,
      );
      
      expect(difficultWords, contains(testWord.id));
      
      // Verify it's not in the known words
      final knownWords = dataService.getKnownWordsForLanguage(
        AppLanguage.spanish.name,
      );
      expect(knownWords, isNot(contains(testWord.id)));
    });

    test('quiz correct answers remove words from review list', () async {
      final testWord = Word(
        id: 'test_review_word',
        latin: 'gracias',
        english: 'thank you',
        pos: 'expression',
      );

      // First mark word as difficult (simulate previous wrong answer)
      await dataService.markWordAsDifficultForLanguage(
        testWord.id,
        AppLanguage.spanish.name,
      );
      
      // Verify it's in review list
      var difficultWords = dataService.getDifficultWordsForLanguage(
        AppLanguage.spanish.name,
      );
      expect(difficultWords, contains(testWord.id));

      // Now simulate getting it right in quiz
      await dataService.markWordAsKnownForLanguage(
        testWord.id,
        AppLanguage.spanish.name,
      );

      // Verify it's removed from difficult words and added to known words
      difficultWords = dataService.getDifficultWordsForLanguage(
        AppLanguage.spanish.name,
      );
      final knownWords = dataService.getKnownWordsForLanguage(
        AppLanguage.spanish.name,
      );
      
      expect(difficultWords, isNot(contains(testWord.id)));
      expect(knownWords, contains(testWord.id));
    });

    test('quiz tracking works per language', () async {
      // Enable Latin as well
      final latinConfig = LanguageStudyConfig(
        language: AppLanguage.latin,
        level: VocabularyLevel.beginner,
        isEnabled: true,
      );
      await dataService.updateLanguageConfig(AppLanguage.latin, latinConfig);

      final spanishWord = Word(
        id: 'spanish_word',
        latin: 'agua',
        english: 'water',
        pos: 'noun',
      );

      final latinWord = Word(
        id: 'latin_word', 
        latin: 'aqua',
        english: 'water',
        pos: 'noun',
      );

      // Mark Spanish word as difficult
      await dataService.markWordAsDifficultForLanguage(
        spanishWord.id,
        AppLanguage.spanish.name,
      );

      // Mark Latin word as known
      await dataService.markWordAsKnownForLanguage(
        latinWord.id,
        AppLanguage.latin.name,
      );

      // Verify separate tracking
      final spanishDifficult = dataService.getDifficultWordsForLanguage(
        AppLanguage.spanish.name,
      );
      final latinDifficult = dataService.getDifficultWordsForLanguage(
        AppLanguage.latin.name,
      );
      final latinKnown = dataService.getKnownWordsForLanguage(
        AppLanguage.latin.name,
      );

      expect(spanishDifficult, contains(spanishWord.id));
      expect(spanishDifficult, isNot(contains(latinWord.id)));
      expect(latinDifficult, isNot(contains(latinWord.id)));
      expect(latinKnown, contains(latinWord.id));
    });
  });
}