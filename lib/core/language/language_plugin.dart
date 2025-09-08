import 'package:flutter/services.dart';
import 'package:flutter_saas_template/core/language/models/language.dart';
import 'package:flutter_saas_template/core/language/models/vocabulary_item.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';

// ignore_for_file: public_member_api_docs

/// Abstract base class for language plugins
/// Each language implements this interface to provide modular language support
abstract class LanguagePlugin {
  /// Language metadata
  Language get language;

  /// Load vocabulary items for a specific level and set
  Future<List<VocabularyItem>> loadVocabulary(VocabularyLevel level, VocabularySet vocabSet);

  /// Load all vocabulary for a specific level
  Future<List<VocabularyItem>> loadLevelVocabulary(VocabularyLevel level) async {
    final allVocabulary = <VocabularyItem>[];
    final sets = VocabularySets.getSetsForLevel(level);
    
    for (final vocabSet in sets) {
      try {
        final vocabulary = await loadVocabulary(level, vocabSet);
        allVocabulary.addAll(vocabulary);
      } catch (e) {
        // Skip sets that don't exist for this language
        print('DEBUG: Failed to load ${vocabSet.name} for ${language.name}: $e');
        continue;
      }
    }
    
    return allVocabulary;
  }

  /// Get the asset path for a vocabulary set
  String getVocabularyAssetPath(VocabularyLevel level, VocabularySet vocabSet) {
    return 'assets/vocab/${language.code}/${level.code}/${vocabSet.filename}';
  }

  /// Load vocabulary from asset bundle (default implementation)
  Future<List<VocabularyItem>> loadVocabularyFromAsset(VocabularyLevel level, VocabularySet vocabSet) async {
    final path = getVocabularyAssetPath(level, vocabSet);
    final jsonStr = await rootBundle.loadString(path);
    return VocabularyItem.listFromJsonString(jsonStr);
  }

  /// Get progress tracking key for this language
  String getProgressKey(String wordId) => '${language.code}_$wordId';

  /// Optional: Custom term display formatting
  String formatTerm(VocabularyItem item) => item.term;

  /// Optional: Custom translation display formatting  
  String formatTranslation(VocabularyItem item) => item.translation;

  /// Optional: Custom example formatting
  String? formatExample(VocabularyItem item) {
    if (item.exampleTerm != null && item.exampleTranslation != null) {
      return '"${item.exampleTerm}" — ${item.exampleTranslation}';
    }
    return null;
  }

  /// Optional: Language-specific quiz difficulty adjustments
  int getQuizChoiceCount() => 4;

  /// Optional: Language-specific learning recommendations
  List<String> getLearningTips() => [];
}