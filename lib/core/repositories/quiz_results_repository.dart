import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for managing quiz results data
/// Provides type-safe access to quiz performance and statistics
class QuizResultsRepository {
  const QuizResultsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String storageKey = 'quiz_results';

  /// Get all quiz results and review sessions
  Map<String, dynamic> getAllResults() {
    final json = _prefs.getString(storageKey);
    if (json == null) return {};

    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  /// Get quiz results filtered by language code
  /// Only returns entries starting with "quiz_<languageCode>_"
  Map<String, dynamic> getResultsForLanguage(String languageCode) {
    final allResults = getAllResults();
    final prefix = 'quiz_${languageCode}_';

    return Map.fromEntries(
      allResults.entries.where((entry) => entry.key.startsWith(prefix)),
    );
  }

  /// Save a single quiz result
  Future<bool> saveQuizResult(
    String quizId,
    Map<String, dynamic> result,
  ) async {
    try {
      final allResults = getAllResults();
      allResults[quizId] = result;
      return await _prefs.setString(storageKey, jsonEncode(allResults));
    } catch (e) {
      return false;
    }
  }

  /// Get quiz statistics for a language
  QuizStatistics getQuizStatistics(String languageCode) {
    final results = getResultsForLanguage(languageCode);

    if (results.isEmpty) {
      return const QuizStatistics(
        totalQuizzes: 0,
        averageScore: 0,
        bestScore: 0,
        worstScore: 0,
      );
    }

    final scores = <int>[];
    for (final entry in results.entries) {
      if (entry.value is Map<String, dynamic>) {
        final quizData = entry.value as Map<String, dynamic>;
        if (quizData['percentage'] is int) {
          scores.add(quizData['percentage'] as int);
        }
      }
    }

    if (scores.isEmpty) {
      return const QuizStatistics(
        totalQuizzes: 0,
        averageScore: 0,
        bestScore: 0,
        worstScore: 0,
      );
    }

    final average = scores.reduce((a, b) => a + b) ~/ scores.length;
    final best = scores.reduce((a, b) => a > b ? a : b);
    final worst = scores.reduce((a, b) => a < b ? a : b);

    return QuizStatistics(
      totalQuizzes: scores.length,
      averageScore: average,
      bestScore: best,
      worstScore: worst,
    );
  }

  /// Get recent quizzes for a language, sorted by date (newest first)
  List<Map<String, dynamic>> getRecentQuizzes(
    String languageCode, {
    int limit = 10,
  }) {
    final results = getResultsForLanguage(languageCode);

    final quizList = results.entries
        .map(
          (entry) => {
            'id': entry.key,
            ...(entry.value as Map<String, dynamic>),
          },
        )
        .toList();

    // Sort by date (newest first)
    quizList.sort((a, b) {
      final dateA = DateTime.tryParse(a['date']?.toString() ?? '');
      final dateB = DateTime.tryParse(b['date']?.toString() ?? '');

      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });

    return quizList.take(limit).toList();
  }

  /// Clear quiz results for specific language
  Future<bool> clearResultsForLanguage(String languageCode) async {
    final allResults = getAllResults();
    final prefix = 'quiz_${languageCode}_';

    allResults.removeWhere((key, _) => key.startsWith(prefix));
    return await _prefs.setString(storageKey, jsonEncode(allResults));
  }

  /// Clear all quiz results
  Future<bool> clearAllResults() async {
    return await _prefs.remove(storageKey);
  }
}

/// Statistics for quiz performance
class QuizStatistics {
  const QuizStatistics({
    required this.totalQuizzes,
    required this.averageScore,
    required this.bestScore,
    required this.worstScore,
  });

  final int totalQuizzes;
  final int averageScore;
  final int bestScore;
  final int worstScore;
}
