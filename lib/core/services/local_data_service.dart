// ignore_for_file: public_member_api_docs, directives_ordering
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:octo_vocab/core/repositories/quiz_results_repository.dart';
import 'package:octo_vocab/core/repositories/study_session_repository.dart';
import 'package:octo_vocab/core/repositories/word_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octo_vocab/core/models/word_interaction.dart';

/// Privacy-first local data storage service
/// All user data stays on device - no network transmission
///
/// This class now delegates to repository classes for better separation of concerns
class LocalDataService {
  LocalDataService(this._prefs)
      : _wordProgressRepo = WordProgressRepository(_prefs),
        _quizResultsRepo = QuizResultsRepository(_prefs),
        _studySessionRepo = StudySessionRepository(_prefs);

  static const String _keyAppSettings = 'app_settings';
  static const String _keyWordInteractions = 'word_interactions';

  final SharedPreferences _prefs;
  final WordProgressRepository _wordProgressRepo;
  final QuizResultsRepository _quizResultsRepo;
  final StudySessionRepository _studySessionRepo;

  @Deprecated('Use providers instead of create()')
  static Future<LocalDataService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalDataService(prefs);
  }

  /// Word Progress Tracking (Privacy-First)
  /// Tracks mastery levels: new, learning, mastered
  Map<String, String> getWordProgress() => _wordProgressRepo.getWordProgress();

  Future<bool> setWordProgress(Map<String, String> progress) async =>
      _wordProgressRepo.setWordProgress(progress);

  /// Study Sessions (Local Analytics Only)
  /// Tracks daily study for streaks - never leaves device
  List<DateTime> getStudySessions() => _studySessionRepo.getStudySessions();

  Future<bool> recordStudySession([DateTime? sessionTime]) async =>
      _studySessionRepo.recordStudySession(sessionTime);

  /// Quiz Results Storage
  Map<String, dynamic> getQuizResults() => _quizResultsRepo.getAllResults();

  Future<bool> saveQuizResult(
    String quizId,
    Map<String, dynamic> result,
  ) async =>
      _quizResultsRepo.saveQuizResult(quizId, result);

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
