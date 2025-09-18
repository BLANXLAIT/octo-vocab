import 'package:flutter/material.dart';
import 'package:octo_vocab/core/language/language_plugin.dart';
import 'package:octo_vocab/core/language/models/language.dart';
import 'package:octo_vocab/core/language/models/vocabulary_item.dart';
import 'package:octo_vocab/core/models/vocabulary_level.dart';

// ignore_for_file: public_member_api_docs

/// Spanish language plugin implementation
class SpanishPlugin extends LanguagePlugin {
  @override
  Language get language => const Language(
        code: 'es',
        name: 'Spanish',
        nativeName: 'Español',
        icon: Icons.language,
        color: Color(0xFFFF6B35), // Spanish Orange
        description: 'Modern Spanish for communication',
      );

  @override
  Future<List<VocabularyItem>> loadVocabulary(VocabularyLevel level, VocabularySet vocabSet) async {
    return loadVocabularyFromAsset(level, vocabSet);
  }

  @override
  String getVocabularyAssetPath(VocabularyLevel level, VocabularySet vocabSet) {
    // Use 'spanish' directory instead of 'es' language code
    return 'assets/vocab/spanish/${level.code}/${vocabSet.filename}';
  }

  @override
  String formatTerm(VocabularyItem item) {
    // For Spanish, we might want to show accent marks clearly
    return item.term;
  }

  @override
  String formatTranslation(VocabularyItem item) {
    return item.translation;
  }

  @override
  String? formatExample(VocabularyItem item) {
    if (item.exampleTerm != null && item.exampleTranslation != null) {
      // Use modern quotation style for Spanish
      return '"${item.exampleTerm}" → "${item.exampleTranslation}"';
    }
    return null;
  }

  @override
  List<String> getLearningTips() {
    return [
      'Pay attention to masculine and feminine nouns',
      'Practice verb conjugations in present tense first',
      'Listen to Spanish music and shows for pronunciation',
      'Learn common phrases for daily conversation',
    ];
  }

  @override
  int getQuizChoiceCount() => 4; // Standard 4-choice quiz for Spanish
}