import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for managing study session data
/// Tracks when users study for streak calculation and analytics
class StudySessionRepository {
  const StudySessionRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String storageKey = 'study_sessions';

  /// Get all study sessions as DateTime list
  List<DateTime> getStudySessions() {
    final json = _prefs.getString(storageKey);
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

  /// Record a study session for a specific date
  /// Normalizes to day-level (removes time component)
  /// Returns true if recorded, false if already exists for that day
  Future<bool> recordStudySession([DateTime? sessionTime]) async {
    final sessions = getStudySessions();
    final now = sessionTime ?? DateTime.now();
    final todayOnly = DateTime(now.year, now.month, now.day);

    // Check if already recorded for this day
    final alreadyRecorded = sessions.any(
      (s) =>
          s.year == todayOnly.year &&
          s.month == todayOnly.month &&
          s.day == todayOnly.day,
    );

    if (alreadyRecorded) {
      return true; // Already recorded, no action needed
    }

    sessions.add(todayOnly);
    return await _prefs.setString(
      storageKey,
      jsonEncode(sessions.map((s) => s.toIso8601String()).toList()),
    );
  }

  /// Check if user has studied today
  bool hasStudiedToday() {
    final sessions = getStudySessions();
    final now = DateTime.now();

    return sessions.any(
      (s) => s.year == now.year && s.month == now.month && s.day == now.day,
    );
  }

  /// Calculate current study streak
  /// A streak is broken if there's a gap of more than 1 day
  int getCurrentStreak() {
    final sessions = getStudySessions();
    if (sessions.isEmpty) return 0;

    // Sort sessions most recent first
    final sortedSessions = sessions.toList()..sort((a, b) => b.compareTo(a));

    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final todayNormalized = DateTime(today.year, today.month, today.day);

    // Check if user studied today or yesterday to have active streak
    final latestSession = sortedSessions.first;
    if (latestSession != todayNormalized && latestSession != yesterday) {
      return 0; // Streak is broken
    }

    var streak = 0;
    var currentDay = latestSession;

    for (final session in sortedSessions) {
      if (session == currentDay) {
        streak++;
        currentDay = DateTime(
          currentDay.year,
          currentDay.month,
          currentDay.day - 1,
        );
      } else if (session.isBefore(currentDay)) {
        break; // Gap in streak
      }
    }

    return streak;
  }

  /// Get count of study sessions in current week (Monday-Sunday)
  int getThisWeekSessions() {
    final sessions = getStudySessions();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartNormalized = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    return sessions.where((session) {
      final sessionNormalized = DateTime(
        session.year,
        session.month,
        session.day,
      );
      return sessionNormalized.isAfter(
            weekStartNormalized.subtract(const Duration(days: 1)),
          ) &&
          sessionNormalized.isBefore(now.add(const Duration(days: 1)));
    }).length;
  }

  /// Clear all study sessions
  Future<bool> clearAllSessions() async {
    return await _prefs.remove(storageKey);
  }
}
