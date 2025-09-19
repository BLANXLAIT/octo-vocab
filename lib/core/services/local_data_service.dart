// ignore_for_file: public_member_api_docs, directives_ordering
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octo_vocab/core/models/word_interaction.dart';

/// Privacy-first local data storage service
/// All user data stays on device - no network transmission
class LocalDataService {
  const LocalDataService._(this._prefs);

  static const String _keyWordProgress = 'word_progress';
  static const String _keyStudySessions = 'study_sessions';
  static const String _keyQuizResults = 'quiz_results';
  static const String _keyAppSettings = 'app_settings';
  static const String _keyWordInteractions = 'word_interactions';

  final SharedPreferences _prefs;

  static Future<LocalDataService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalDataService._(prefs);
  }

  /// Word Progress Tracking (Privacy-First)
  /// Tracks mastery levels: new, learning, mastered
  Map<String, String> getWordProgress() {
    final json = _prefs.getString(_keyWordProgress);
    if (json == null) return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded.cast<String, String>();
    } catch (e) {
      return {};
    }
  }

  Future<bool> setWordProgress(Map<String, String> progress) async {
    return _prefs.setString(_keyWordProgress, jsonEncode(progress));
  }

  /// Study Sessions (Local Analytics Only)
  /// Tracks daily study for streaks - never leaves device
  List<DateTime> getStudySessions() {
    final json = _prefs.getString(_keyStudySessions);
    if (json == null) return [];
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded
          .map((e) => DateTime.tryParse(e.toString()))
          .whereType<DateTime>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> recordStudySession([DateTime? sessionTime]) async {
    final sessions = getStudySessions();
    final now = sessionTime ?? DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);

    if (!sessions.any(
      (s) =>
          s.year == todayOnly.year &&
          s.month == todayOnly.month &&
          s.day == todayOnly.day,
    )) {
      sessions.add(todayOnly);
      return _prefs.setString(
        _keyStudySessions,
        jsonEncode(sessions.map((s) => s.toIso8601String()).toList()),
      );
    }
    return true;
  }

  /// Quiz Results Storage
  Map<String, dynamic> getQuizResults() {
    final json = _prefs.getString(_keyQuizResults);
    if (json == null) return {};
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<bool> saveQuizResult(
    String quizId,
    Map<String, dynamic> result,
  ) async {
    final results = getQuizResults();
    results[quizId] = result;
    return _prefs.setString(_keyQuizResults, jsonEncode(results));
  }

  /// App Settings
  Map<String, dynamic> getAppSettings() {
    final json = _prefs.getString(_keyAppSettings);
    if (json == null) return {};
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<bool> saveAppSettings(Map<String, dynamic> settings) async {
    return _prefs.setString(_keyAppSettings, jsonEncode(settings));
  }

  /// Word Interactions for Enhanced Spaced Repetition
  Map<String, WordInteraction> getWordInteractions() {
    final json = _prefs.getString(_keyWordInteractions);
    if (json == null) return {};
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final interactions = <String, WordInteraction>{};
      for (final entry in decoded.entries) {
        try {
          interactions[entry.key] = WordInteraction.fromJson(
            entry.value as Map<String, dynamic>,
          );
        } catch (e) {
          // Skip invalid entries
        }
      }
      return interactions;
    } catch (e) {
      return {};
    }
  }

  Future<bool> setWordInteractions(Map<String, WordInteraction> interactions) async {
    final jsonMap = <String, dynamic>{};
    for (final entry in interactions.entries) {
      jsonMap[entry.key] = entry.value.toJson();
    }
    return _prefs.setString(_keyWordInteractions, jsonEncode(jsonMap));
  }

  /// Record a word interaction and update timing data
  Future<bool> recordWordInteraction(
    String wordId,
    InteractionType type, [
    DateTime? timestamp,
  ]) async {
    final interactions = getWordInteractions();
    final existing = interactions[wordId];

    if (existing != null) {
      interactions[wordId] = existing.withNewInteraction(type, timestamp);
    } else {
      interactions[wordId] = WordInteraction.initial(wordId)
          .withNewInteraction(type, timestamp);
    }

    return setWordInteractions(interactions);
  }

  /// Get words that are available for presentation based on timing constraints
  List<String> getAvailableWords(List<String> allWordIds, [DateTime? now]) {
    final interactions = getWordInteractions();
    now ??= DateTime.now();

    return allWordIds.where((wordId) {
      final interaction = interactions[wordId];
      if (interaction == null) return true; // New words are always available
      return interaction.isAvailableForPresentation(now);
    }).toList();
  }

  /// Privacy Compliance
  Future<bool> clearAllData() async {
    debugPrint('🗑️ CLEAR DATA: Starting to clear all SharedPreferences data');
    final success = await _prefs.clear();
    debugPrint(
      '🗑️ CLEAR DATA: Clear operation ${success ? "successful" : "failed"}',
    );
    return success;
  }
}

/// Provider for local data service
final localDataServiceProvider = FutureProvider<LocalDataService>((ref) {
  return LocalDataService.create();
});
