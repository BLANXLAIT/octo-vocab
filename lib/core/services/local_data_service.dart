// ignore_for_file: public_member_api_docs
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Privacy-first local data storage service
/// All user data stays on device - no network transmission
class LocalDataService {
  const LocalDataService._(this._prefs);

  static const String _keyWordProgress = 'word_progress';
  static const String _keyStudySessions = 'study_sessions';
  static const String _keyQuizResults = 'quiz_results';
  static const String _keyAppSettings = 'app_settings';
  static const String _keySelectedLanguage = 'selected_language';

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
      return decoded.map((e) => DateTime.parse(e as String)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> addStudySession(DateTime session) async {
    final sessions = getStudySessions()..add(session);
    return _prefs.setString(
      _keyStudySessions,
      jsonEncode(sessions.map((e) => e.toIso8601String()).toList()),
    );
  }

  /// Quiz Results (Privacy-First Performance Tracking)
  /// Local-only quiz scores for progress visualization
  List<Map<String, dynamic>> getQuizResults() {
    final json = _prefs.getString(_keyQuizResults);
    if (json == null) return [];
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<bool> addQuizResult({
    required int score,
    required int total,
    required String language,
    required DateTime timestamp,
  }) async {
    final results = getQuizResults()
      ..add({
        'score': score,
        'total': total,
        'language': language,
        'timestamp': timestamp.toIso8601String(),
      });
    return _prefs.setString(_keyQuizResults, jsonEncode(results));
  }

  /// Language Selection (Privacy-Compliant Preferences)
  String? getSelectedLanguage() {
    return _prefs.getString(_keySelectedLanguage);
  }

  Future<bool> setSelectedLanguage(String language) async {
    return _prefs.setString(_keySelectedLanguage, language);
  }

  /// App Settings (Local Configuration Only)
  Map<String, dynamic> getAppSettings() {
    final json = _prefs.getString(_keyAppSettings);
    if (json == null) return {};
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }

  Future<bool> setAppSettings(Map<String, dynamic> settings) async {
    return _prefs.setString(_keyAppSettings, jsonEncode(settings));
  }

  /// PRIVACY CONTROL: Complete Data Reset
  /// Allows users to completely delete all stored data
  /// COPPA/FERPA compliant - user has full control
  Future<bool> resetAllData() async {
    try {
      await Future.wait([
        _prefs.remove(_keyWordProgress),
        _prefs.remove(_keyStudySessions),
        _prefs.remove(_keyQuizResults),
        _prefs.remove(_keyAppSettings),
        _prefs.remove(_keySelectedLanguage),
      ]);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Privacy Transparency: Show User Their Data
  /// Allows users to see exactly what's stored locally
  Map<String, dynamic> getAllUserData() {
    return {
      'word_progress': getWordProgress(),
      'study_sessions': getStudySessions()
          .map((e) => e.toIso8601String())
          .toList(),
      'quiz_results': getQuizResults(),
      'app_settings': getAppSettings(),
      'selected_language': getSelectedLanguage(),
    };
  }

  /// Privacy Compliance: Data Export
  /// Let users export their data for backup/transparency
  String exportUserData() {
    return jsonEncode({
      'app': 'Octo Vocab',
      'export_date': DateTime.now().toIso8601String(),
      'privacy_note': 'This data never leaves your device unless you share it',
      'data': getAllUserData(),
    });
  }
}

/// Riverpod provider for the local data service
final localDataServiceProvider = FutureProvider<LocalDataService>((ref) async {
  return LocalDataService.create();
});
