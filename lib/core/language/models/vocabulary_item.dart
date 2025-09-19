import 'dart:convert';

// ignore_for_file: public_member_api_docs

/// Generic vocabulary item that can represent any language pair
/// Replaces the hard-coded Word model with flexible structure
class VocabularyItem {
  const VocabularyItem({
    required this.id,
    required this.term,
    required this.translation,
    this.partOfSpeech,
    this.exampleTerm,
    this.exampleTranslation,
    this.tags = const [],
    this.extras = const {},
  });

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: (json['id'] ?? json['term'] ?? json['latin'] ?? json['spanish'] ?? '')
          .toString(),
      term: (json['term'] ?? json['latin'] ?? json['spanish'] ?? '').toString(),
      translation: (json['translation'] ?? json['english'] ?? '').toString(),
      partOfSpeech: json['partOfSpeech'] as String? ?? json['pos'] as String?,
      exampleTerm:
          json['exampleTerm'] as String? ??
          json['exampleLatin'] as String? ??
          json['exampleSpanish'] as String?,
      exampleTranslation:
          json['exampleTranslation'] as String? ??
          json['exampleEnglish'] as String?,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      extras: Map<String, dynamic>.from(json)
        ..removeWhere(
          (key, _) => [
            'id',
            'term',
            'latin',
            'translation',
            'english',
            'partOfSpeech',
            'pos',
            'exampleTerm',
            'exampleLatin',
            'exampleTranslation',
            'exampleEnglish',
            'tags',
          ].contains(key),
        ),
    );
  }

  /// Unique identifier for this vocabulary item
  final String id;

  /// The foreign language term (e.g., "amor" in Latin)
  final String term;

  /// The English translation (e.g., "love")
  final String translation;

  /// Part of speech (noun, verb, adjective, etc.)
  final String? partOfSpeech;

  /// Example usage of the term in the foreign language
  final String? exampleTerm;

  /// Translation of the example usage
  final String? exampleTranslation;

  /// Tags for categorization (e.g., ["family", "emotions"])
  final List<String> tags;

  /// Additional language-specific data
  final Map<String, dynamic> extras;

  /// Convert from JSON string list to VocabularyItem list
  static List<VocabularyItem> listFromJsonString(String jsonStr) {
    final data = json.decode(jsonStr) as List<dynamic>;
    return data
        .map((e) => VocabularyItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'id': id,
      'term': term,
      'translation': translation,
    };

    if (partOfSpeech != null) json['partOfSpeech'] = partOfSpeech;
    if (exampleTerm != null) json['exampleTerm'] = exampleTerm;
    if (exampleTranslation != null)
      json['exampleTranslation'] = exampleTranslation;
    if (tags.isNotEmpty) json['tags'] = tags;

    json.addAll(extras);
    return json;
  }

  @override
  String toString() =>
      'VocabularyItem(id: $id, term: $term, translation: $translation)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabularyItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
