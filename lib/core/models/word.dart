import 'dart:convert';

// ignore_for_file: public_member_api_docs

/// Vocabulary word model:
/// - `latin` holds the foreign term
/// - `english` its translation.
class Word {
  Word({
    required this.id,
    required this.latin,
    required this.english,
    required this.pos,
    this.exampleLatin,
    this.exampleEnglish,
    this.tags = const [],
  });

  factory Word.fromJson(Map<String, dynamic> json) => Word(
    id: (json['id'] ?? json['latin']).toString(),
    latin: (json['latin'] ?? '').toString(),
    english: (json['english'] ?? '').toString(),
    pos: (json['pos'] ?? '').toString(),
    exampleLatin: json['exampleLatin'] as String?,
    exampleEnglish: json['exampleEnglish'] as String?,
    tags: (json['tags'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList(),
  );

  final String id;
  final String latin;
  final String english;
  final String pos;
  final String? exampleLatin;
  final String? exampleEnglish;
  final List<String> tags;

  static List<Word> listFromJsonString(String jsonStr) {
    final data = json.decode(jsonStr) as List<dynamic>;
    return data.map((e) => Word.fromJson(e as Map<String, dynamic>)).toList();
  }
}
