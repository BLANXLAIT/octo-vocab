import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_saas_template/core/services/local_data_service.dart';
import 'package:flutter_saas_template/features/progress/progress_screen.dart';

void main() {
  group('Multi-Language Progress Integration Tests', () {
    late LocalDataService dataService;
    
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      dataService = await LocalDataService.create();
    });

    test('manages studying languages list correctly', () async {
      // Set a selected language first
      await dataService.setSelectedLanguage('latin');
      
      // Initially should default to current selected language
      var studyingLanguages = dataService.getStudyingLanguages();
      expect(studyingLanguages.isNotEmpty, isTrue, reason: 'Should have at least default language');
      expect(studyingLanguages.contains('latin'), isTrue);
      
      // Add Spanish
      await dataService.addStudyingLanguage('spanish');
      studyingLanguages = dataService.getStudyingLanguages();
      expect(studyingLanguages.contains('spanish'), isTrue);
      
      // Add Latin
      await dataService.addStudyingLanguage('latin');
      studyingLanguages = dataService.getStudyingLanguages();
      expect(studyingLanguages.contains('latin'), isTrue);
      expect(studyingLanguages.contains('spanish'), isTrue);
      
      // Remove Spanish
      await dataService.removeStudyingLanguage('spanish');
      studyingLanguages = dataService.getStudyingLanguages();
      expect(studyingLanguages.contains('spanish'), isFalse);
      expect(studyingLanguages.contains('latin'), isTrue);
    });

    test('tracks progress separately for each language', () async {
      // Set up studying both languages
      await dataService.setStudyingLanguages({'latin', 'spanish'});
      
      // Add progress for Latin
      await dataService.markWordAsKnownForLanguage('aqua', 'latin');
      await dataService.markWordAsKnownForLanguage('terra', 'latin');
      await dataService.markWordAsDifficultForLanguage('ignis', 'latin');
      
      // Add progress for Spanish  
      await dataService.markWordAsKnownForLanguage('agua', 'spanish');
      await dataService.markWordAsDifficultForLanguage('fuego', 'spanish');
      await dataService.markWordAsDifficultForLanguage('tierra', 'spanish');
      
      // Check Latin progress
      final latinStats = dataService.getLearningStatsForLanguage('latin');
      expect(latinStats['known_count'], equals(2));
      expect(latinStats['difficult_count'], equals(1));
      expect(latinStats['total_studied'], equals(3));
      
      // Check Spanish progress  
      final spanishStats = dataService.getLearningStatsForLanguage('spanish');
      expect(spanishStats['known_count'], equals(1));
      expect(spanishStats['difficult_count'], equals(2));
      expect(spanishStats['total_studied'], equals(3));
      
      // Verify they don't interfere with each other
      final latinKnown = dataService.getKnownWordsForLanguage('latin');
      final spanishKnown = dataService.getKnownWordsForLanguage('spanish');
      
      expect(latinKnown.contains('aqua'), isTrue);
      expect(latinKnown.contains('agua'), isFalse); // Spanish word shouldn't be in Latin
      expect(spanishKnown.contains('agua'), isTrue);
      expect(spanishKnown.contains('aqua'), isFalse); // Latin word shouldn't be in Spanish
    });

    test('multi-language stats aggregation works correctly', () async {
      // Set up studying multiple languages
      await dataService.setStudyingLanguages({'latin', 'spanish'});
      
      // Add varied progress
      await dataService.markWordAsKnownForLanguage('word1', 'latin');
      await dataService.markWordAsKnownForLanguage('word2', 'latin');
      await dataService.markWordAsDifficultForLanguage('word3', 'latin');
      
      await dataService.markWordAsKnownForLanguage('palabra1', 'spanish');
      await dataService.markWordAsDifficultForLanguage('palabra2', 'spanish');
      await dataService.markWordAsDifficultForLanguage('palabra3', 'spanish');
      await dataService.markWordAsDifficultForLanguage('palabra4', 'spanish');
      
      // Get multi-language stats
      final multiStats = dataService.getMultiLanguageStats();
      
      expect(multiStats.containsKey('latin'), isTrue);
      expect(multiStats.containsKey('spanish'), isTrue);
      expect(multiStats['latin']!['known_count'], equals(2));
      expect(multiStats['latin']!['difficult_count'], equals(1));
      expect(multiStats['spanish']!['known_count'], equals(1));
      expect(multiStats['spanish']!['difficult_count'], equals(3));
    });

    test('language progress data models calculate percentages correctly', () {
      // Test LanguageProgressData
      const langProgress = LanguageProgressData(
        language: 'latin',
        totalWords: 100,
        masteredCount: 25,
        learningCount: 15,
        unstudiedCount: 60,
        difficultWordIds: {'word1', 'word2'},
        knownWordIds: {'word3', 'word4'},
      );
      
      expect(langProgress.masteryPercentage, equals(25.0));
      expect(langProgress.studiedPercentage, equals(40.0));
      expect(langProgress.displayName, equals('Latin'));
      
      // Test MultiLanguageProgressData combined stats
      final multiLangData = MultiLanguageProgressData(
        languages: {
          'latin': langProgress,
          'spanish': const LanguageProgressData(
            language: 'spanish', 
            totalWords: 80,
            masteredCount: 20,
            learningCount: 10,
            unstudiedCount: 50,
            difficultWordIds: {'palabra1'},
            knownWordIds: {'palabra2'},
          ),
        },
        studyingLanguages: {'latin', 'spanish'},
      );
      
      final combined = multiLangData.combinedProgress;
      expect(combined.totalWords, equals(180));
      expect(combined.masteredCount, equals(45));
      expect(combined.learningCount, equals(25));
      expect(combined.unstudiedCount, equals(110));
    });

    test('backward compatibility with existing methods', () async {
      // Set selected language
      await dataService.setSelectedLanguage('latin');
      
      // Use old methods - should work with per-language storage
      await dataService.markWordAsDifficult('test_word');
      await dataService.markWordAsKnown('known_word');
      
      // Should be stored in Latin language data
      final latinDifficult = dataService.getDifficultWordsForLanguage('latin');
      final latinKnown = dataService.getKnownWordsForLanguage('latin');
      
      expect(latinDifficult.contains('test_word'), isTrue);
      expect(latinKnown.contains('known_word'), isTrue);
      
      // Old methods should also return the same data
      final globalDifficult = dataService.getDifficultWords();
      final globalKnown = dataService.getKnownWords();
      
      expect(globalDifficult.contains('test_word'), isTrue);
      expect(globalKnown.contains('known_word'), isTrue);
    });

    test('data reset clears all language data', () async {
      // Set up multi-language data
      await dataService.setStudyingLanguages({'latin', 'spanish'});
      await dataService.markWordAsKnownForLanguage('aqua', 'latin');
      await dataService.markWordAsDifficultForLanguage('agua', 'spanish');
      
      // Verify data exists
      expect(dataService.getStudyingLanguages().isNotEmpty, isTrue);
      expect(dataService.getKnownWordsForLanguage('latin').isNotEmpty, isTrue);
      expect(dataService.getDifficultWordsForLanguage('spanish').isNotEmpty, isTrue);
      
      // Reset all data
      await dataService.resetAllData();
      
      // Verify everything is cleared
      expect(dataService.getStudyingLanguages().isEmpty, isTrue);
      expect(dataService.getKnownWordsForLanguage('latin').isEmpty, isTrue);
      expect(dataService.getDifficultWordsForLanguage('spanish').isEmpty, isTrue);
      expect(dataService.getPerLanguageProgress().isEmpty, isTrue);
      expect(dataService.getMultiLanguageStats().isEmpty, isTrue);
    });

    test('handles edge cases gracefully', () {
      // Non-existent language
      final nonExistentStats = dataService.getLearningStatsForLanguage('nonexistent');
      expect(nonExistentStats['known_count'], equals(0));
      expect(nonExistentStats['difficult_count'], equals(0));
      
      // Empty studying languages
      final emptyMultiStats = dataService.getMultiLanguageStats();
      expect(emptyMultiStats.isEmpty, isTrue);
      
      // Test display name fallback
      const unknownLangProgress = LanguageProgressData(
        language: 'unknown_lang',
        totalWords: 10,
        masteredCount: 0,
        learningCount: 0,
        unstudiedCount: 10,
        difficultWordIds: <String>{},
        knownWordIds: <String>{},
      );
      expect(unknownLangProgress.displayName, equals('Unknown_lang'));
    });
  });
}