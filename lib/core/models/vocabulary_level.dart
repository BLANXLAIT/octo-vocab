// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';

/// Vocabulary difficulty levels based on ACTFL standards
/// Aligned with K-12 educational progression
enum VocabularyLevel {
  beginner(
    code: 'beginner',
    label: 'Beginner',
    description: 'Grades 7-8 • Essential words and phrases',
    icon: Icons.star_outline,
    color: Color(0xFF4CAF50), // Green
  ),
  intermediate(
    code: 'intermediate',
    label: 'Intermediate',
    description: 'Grades 9-10 • Common vocabulary and grammar',
    icon: Icons.star_half,
    color: Color(0xFF2196F3), // Blue
  ),
  advanced(
    code: 'advanced',
    label: 'Advanced',
    description: 'Grades 11-12 • Complex texts and literature',
    icon: Icons.star,
    color: Color(0xFF9C27B0), // Purple
  );

  const VocabularyLevel({
    required this.code,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String code;
  final String label;
  final String description;
  final IconData icon;
  final Color color;
}

/// Vocabulary set within a level (e.g., "essentials", "family_home")
class VocabularySet {
  const VocabularySet({
    required this.id,
    required this.name,
    required this.description,
    required this.filename,
    required this.level,
    required this.estimatedWords,
  });

  final String id;
  final String name;
  final String description;
  final String filename;
  final VocabularyLevel level;
  final int estimatedWords;
}

/// Predefined vocabulary sets for each level
class VocabularySets {
  static const List<VocabularySet> beginner = [
    VocabularySet(
      id: 'essentials',
      name: 'Essentials',
      description: 'Most common words - start here!',
      filename: 'set1_essentials.json',
      level: VocabularyLevel.beginner,
      estimatedWords: 20,
    ),
    VocabularySet(
      id: 'family_home',
      name: 'Family & Home',
      description: 'Family members and household items',
      filename: 'set2_family_home.json',
      level: VocabularyLevel.beginner,
      estimatedWords: 20,
    ),
    VocabularySet(
      id: 'basic_verbs',
      name: 'Basic Verbs',
      description: 'Essential action words for daily communication',
      filename: 'set3_basic_verbs.json',
      level: VocabularyLevel.beginner,
      estimatedWords: 20,
    ),
  ];

  static const List<VocabularySet> intermediate = [
    VocabularySet(
      id: 'verbs_actions',
      name: 'Verbs & Actions',
      description: 'Common verbs and action words for daily communication',
      filename: 'set1_verbs_actions.json',
      level: VocabularyLevel.intermediate,
      estimatedWords: 25,
    ),
    VocabularySet(
      id: 'adjectives_descriptions',
      name: 'Adjectives & Descriptions',
      description: 'Descriptive words for people, places, and things',
      filename: 'set2_adjectives_descriptions.json',
      level: VocabularyLevel.intermediate,
      estimatedWords: 25,
    ),
    VocabularySet(
      id: 'daily_activities',
      name: 'Daily Activities',
      description: 'Verbs and phrases for everyday activities and routines',
      filename: 'set1_daily_activities.json',
      level: VocabularyLevel.intermediate,
      estimatedWords: 25,
    ),
  ];

  static const List<VocabularySet> advanced = [
    VocabularySet(
      id: 'literature_rhetoric',
      name: 'Literature & Rhetoric',
      description: 'Advanced vocabulary for classical literature and philosophy',
      filename: 'set1_literature_rhetoric.json',
      level: VocabularyLevel.advanced,
      estimatedWords: 25,
    ),
    VocabularySet(
      id: 'abstract_concepts',
      name: 'Abstract Concepts',
      description: 'Complex philosophical, political, and academic terminology',
      filename: 'set1_abstract_concepts.json',
      level: VocabularyLevel.advanced,
      estimatedWords: 25,
    ),
  ];

  static List<VocabularySet> getAllSets() {
    return [...beginner, ...intermediate, ...advanced];
  }

  static List<VocabularySet> getSetsForLevel(VocabularyLevel level) {
    switch (level) {
      case VocabularyLevel.beginner:
        return beginner;
      case VocabularyLevel.intermediate:
        return intermediate;
      case VocabularyLevel.advanced:
        return advanced;
    }
  }
}
