import 'package:flutter/material.dart';

// ignore_for_file: public_member_api_docs

/// Represents a language that can be studied in the app
class Language {
  const Language({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.icon,
    required this.color,
    this.description,
  });

  /// Language code (e.g., "la" for Latin, "es" for Spanish)
  final String code;

  /// English name of the language
  final String name;

  /// Native name of the language (e.g., "Lingua Latina", "Español")
  final String nativeName;

  /// Icon to represent this language in the UI
  final IconData icon;

  /// Primary color for this language's theme
  final Color color;

  /// Optional description
  final String? description;

  @override
  String toString() => 'Language(code: $code, name: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Language &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}
