import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for managing word progress data
/// Provides type-safe access to word learning status
class WordProgressRepository {
  const WordProgressRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String storageKey = 'word_progress';

  /// Get all word progress as map of wordKey -> status
  Map<String, String> getWordProgress() {
    final json = _prefs.getString(storageKey);
    if (json == null) return {};

    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.cast<String, String>();
    } catch (e) {
      return {};
    }
  }

  /// Save word progress map
  Future<bool> setWordProgress(Map<String, String> progress) async {
    try {
      return await _prefs.setString(storageKey, jsonEncode(progress));
    } catch (e) {
      return false;
    }
  }

  /// Get progress filtered by language code
  /// Returns map with keys like "la_word1" -> "known"
  Map<String, String> getProgressForLanguage(String languageCode) {
    final allProgress = getWordProgress();
    final prefix = '${languageCode}_';

    return Map.fromEntries(
      allProgress.entries.where((entry) => entry.key.startsWith(prefix)),
    );
  }

  /// Update status for a single word
  Future<bool> updateWordStatus(String wordKey, String status) async {
    final progress = getWordProgress();
    progress[wordKey] = status;
    return setWordProgress(progress);
  }

  /// Get status for a specific word
  String? getWordStatus(String wordKey) {
    final progress = getWordProgress();
    return progress[wordKey];
  }

  /// Get statistics for a specific language
  WordProgressStats getStatsByLanguage(String languageCode) {
    final progress = getProgressForLanguage(languageCode);

    var known = 0;
    var difficult = 0;
    var reviewing = 0;
    var mastered = 0;

    for (final status in progress.values) {
      switch (status) {
        case 'known':
          known++;
        case 'difficult':
          difficult++;
        case 'reviewing':
          reviewing++;
        case 'mastered':
          mastered++;
      }
    }

    return WordProgressStats(
      totalWords: progress.length,
      knownWords: known,
      difficultWords: difficult,
      reviewingWords: reviewing,
      masteredWords: mastered,
    );
  }

  /// Clear progress for specific language
  Future<bool> clearProgressForLanguage(String languageCode) async {
    final allProgress = getWordProgress();
    final prefix = '${languageCode}_';

    allProgress.removeWhere((key, _) => key.startsWith(prefix));
    return setWordProgress(allProgress);
  }

  /// Clear all word progress
  Future<bool> clearAllProgress() async {
    return await _prefs.remove(storageKey);
  }
}

/// Statistics for word progress
class WordProgressStats {
  const WordProgressStats({
    required this.totalWords,
    required this.knownWords,
    required this.difficultWords,
    required this.reviewingWords,
    required this.masteredWords,
  });

  final int totalWords;
  final int knownWords;
  final int difficultWords;
  final int reviewingWords;
  final int masteredWords;

  int get unstudiedWords =>
      totalWords -
      (knownWords + difficultWords + reviewingWords + masteredWords);
}
