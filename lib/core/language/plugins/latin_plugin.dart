import 'package:flutter/material.dart';
import 'package:flutter_saas_template/core/language/language_plugin.dart';
import 'package:flutter_saas_template/core/language/models/language.dart';
import 'package:flutter_saas_template/core/language/models/vocabulary_item.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';

// ignore_for_file: public_member_api_docs

/// Latin language plugin implementation
class LatinPlugin extends LanguagePlugin {
  @override
  Language get language => const Language(
        code: 'la',
        name: 'Latin',
        nativeName: 'Lingua Latina',
        icon: Icons.account_balance,
        color: Color(0xFF8B4513), // Saddle Brown - classical/ancient feel
        description: 'Classical Latin for academic study',
      );

  @override
  Future<List<VocabularyItem>> loadVocabulary(VocabularyLevel level, VocabularySet vocabSet) async {
    return loadVocabularyFromAsset(level, vocabSet);
  }

  @override
  String getVocabularyAssetPath(VocabularyLevel level, VocabularySet vocabSet) {
    // Use 'latin' directory instead of 'la' language code
    return 'assets/vocab/latin/${level.code}/${vocabSet.filename}';
  }

  @override
  String formatTerm(VocabularyItem item) {
    // For Latin, we might want to emphasize classical formatting
    return item.term;
  }

  @override
  String formatTranslation(VocabularyItem item) {
    return item.translation;
  }

  @override
  String? formatExample(VocabularyItem item) {
    if (item.exampleTerm != null && item.exampleTranslation != null) {
      // Use classical quotation style for Latin
      return '${item.exampleTerm} — "${item.exampleTranslation}"';
    }
    return null;
  }

  @override
  List<String> getLearningTips() {
    return [
      'Focus on case endings for nouns and adjectives',
      'Learn verb conjugation patterns early',
      'Practice with familiar phrases and sayings',
      'Use mnemonic devices for vocabulary retention',
    ];
  }

  @override
  int getQuizChoiceCount() => 4; // Standard 4-choice quiz for Latin
}