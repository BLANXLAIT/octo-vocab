// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';

/// Comprehensive language definition for vocabulary learning
class LanguageDefinition {
  const LanguageDefinition({
    required this.code,
    required this.name,
    required this.displayName,
    required this.nativeName,
    required this.icon,
    required this.flag,
    required this.primaryColor,
    required this.family,
    required this.writingSystem,
    required this.isRightToLeft,
    this.isEnabled = true,
    this.isAvailable = true,
    this.alternativeNames = const [],
    this.description = '',
    this.learningTips = '',
  });

  final String code;
  final String name;
  final String displayName;
  final String nativeName;
  final IconData icon;
  final String flag;
  final Color primaryColor;
  final LanguageFamily family;
  final WritingSystem writingSystem;
  final bool isRightToLeft;
  final bool isEnabled;
  final bool isAvailable;
  final List<String> alternativeNames;
  final String description;
  final String learningTips;

  LanguageDefinition copyWith({
    String? code,
    String? name,
    String? displayName,
    String? nativeName,
    IconData? icon,
    String? flag,
    Color? primaryColor,
    LanguageFamily? family,
    WritingSystem? writingSystem,
    bool? isRightToLeft,
    bool? isEnabled,
    bool? isAvailable,
    List<String>? alternativeNames,
    String? description,
    String? learningTips,
  }) {
    return LanguageDefinition(
      code: code ?? this.code,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      nativeName: nativeName ?? this.nativeName,
      icon: icon ?? this.icon,
      flag: flag ?? this.flag,
      primaryColor: primaryColor ?? this.primaryColor,
      family: family ?? this.family,
      writingSystem: writingSystem ?? this.writingSystem,
      isRightToLeft: isRightToLeft ?? this.isRightToLeft,
      isEnabled: isEnabled ?? this.isEnabled,
      isAvailable: isAvailable ?? this.isAvailable,
      alternativeNames: alternativeNames ?? this.alternativeNames,
      description: description ?? this.description,
      learningTips: learningTips ?? this.learningTips,
    );
  }
}

/// Language family groupings for educational organization
enum LanguageFamily { romance, germanic, slavic, asian, semitic, other }

extension LanguageFamilyX on LanguageFamily {
  String get label {
    switch (this) {
      case LanguageFamily.romance:
        return 'Romance Languages';
      case LanguageFamily.germanic:
        return 'Germanic Languages';
      case LanguageFamily.slavic:
        return 'Slavic Languages';
      case LanguageFamily.asian:
        return 'Asian Languages';
      case LanguageFamily.semitic:
        return 'Semitic Languages';
      case LanguageFamily.other:
        return 'Other Languages';
    }
  }

  Color get color {
    switch (this) {
      case LanguageFamily.romance:
        return Colors.red.shade300;
      case LanguageFamily.germanic:
        return Colors.blue.shade300;
      case LanguageFamily.slavic:
        return Colors.green.shade300;
      case LanguageFamily.asian:
        return Colors.orange.shade300;
      case LanguageFamily.semitic:
        return Colors.purple.shade300;
      case LanguageFamily.other:
        return Colors.grey.shade300;
    }
  }
}

/// Writing system types for proper UI handling
enum WritingSystem { latin, arabic, chinese, cyrillic, devanagari, other }

extension WritingSystemX on WritingSystem {
  String get label {
    switch (this) {
      case WritingSystem.latin:
        return 'Latin Script';
      case WritingSystem.arabic:
        return 'Arabic Script';
      case WritingSystem.chinese:
        return 'Chinese Characters';
      case WritingSystem.cyrillic:
        return 'Cyrillic Script';
      case WritingSystem.devanagari:
        return 'Devanagari Script';
      case WritingSystem.other:
        return 'Other Script';
    }
  }

  bool get needsSpecialFont {
    switch (this) {
      case WritingSystem.latin:
        return false;
      case WritingSystem.arabic:
      case WritingSystem.chinese:
      case WritingSystem.cyrillic:
      case WritingSystem.devanagari:
      case WritingSystem.other:
        return true;
    }
  }
}

/// Registry of all supported languages
class LanguageRegistry {
  static const Map<String, LanguageDefinition> _languages = {
    'latin': LanguageDefinition(
      code: 'latin',
      name: 'latin',
      displayName: 'Latin',
      nativeName: 'Latina',
      icon: Icons.school,
      flag: '🏛️',
      primaryColor: Colors.deepPurple,
      family: LanguageFamily.other,
      writingSystem: WritingSystem.latin,
      isRightToLeft: false,
      description: 'Classical Latin language for academic study',
      learningTips: 'Focus on cases and verb conjugations',
    ),
    'spanish': LanguageDefinition(
      code: 'spanish',
      name: 'spanish',
      displayName: 'Spanish',
      nativeName: 'Español',
      icon: Icons.translate,
      flag: '🇪🇸',
      primaryColor: Colors.red,
      family: LanguageFamily.romance,
      writingSystem: WritingSystem.latin,
      isRightToLeft: false,
      description: 'Modern Spanish language for communication',
      learningTips: 'Practice verb tenses and gendered nouns',
    ),
    // Future languages can be easily added here
    'french': LanguageDefinition(
      code: 'french',
      name: 'french',
      displayName: 'French',
      nativeName: 'Français',
      icon: Icons.translate,
      flag: '🇫🇷',
      primaryColor: Colors.blue,
      family: LanguageFamily.romance,
      writingSystem: WritingSystem.latin,
      isRightToLeft: false,
      isAvailable: false, // Not yet implemented
      description: 'French language for global communication',
      learningTips: 'Focus on pronunciation and liaison',
    ),
    'german': LanguageDefinition(
      code: 'german',
      name: 'german',
      displayName: 'German',
      nativeName: 'Deutsch',
      icon: Icons.translate,
      flag: '🇩🇪',
      primaryColor: Colors.amber,
      family: LanguageFamily.germanic,
      writingSystem: WritingSystem.latin,
      isRightToLeft: false,
      isAvailable: false, // Not yet implemented
      description: 'German language for Europe and beyond',
      learningTips: 'Master the case system and compound words',
    ),
  };

  /// Get all available languages
  static List<LanguageDefinition> get availableLanguages =>
      _languages.values.where((lang) => lang.isAvailable).toList();

  /// Get all languages (including unavailable ones)
  static List<LanguageDefinition> get allLanguages =>
      _languages.values.toList();

  /// Get language by code
  static LanguageDefinition? getLanguage(String code) => _languages[code];

  /// Get languages by family
  static List<LanguageDefinition> getLanguagesByFamily(LanguageFamily family) =>
      _languages.values.where((lang) => lang.family == family).toList();

  /// Check if language is supported
  static bool isSupported(String code) => _languages.containsKey(code);

  /// Get language codes only
  static List<String> get availableLanguageCodes =>
      availableLanguages.map((lang) => lang.code).toList();
}
