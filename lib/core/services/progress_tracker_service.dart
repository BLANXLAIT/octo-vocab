/// Service for calculating progress statistics and streaks
/// Extracts business logic from UI for better testability
class ProgressTrackerService {
  const ProgressTrackerService();

  /// Calculate the current study streak from session list
  /// Returns 0 if streak is broken (no study in last 2 days)
  int calculateStreak(List<DateTime> sessions) {
    if (sessions.isEmpty) return 0;

    // Normalize dates to day-only (remove time component)
    final normalizedSessions = sessions
        .map((s) => DateTime(s.year, s.month, s.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    // Check if streak is active (studied today or yesterday)
    final latestSession = normalizedSessions.first;
    if (latestSession != today && latestSession != yesterday) {
      return 0; // Streak broken
    }

    // Count consecutive days
    var streak = 0;
    var currentDay = latestSession;

    for (final session in normalizedSessions) {
      if (session == currentDay) {
        streak++;
        currentDay = DateTime(
          currentDay.year,
          currentDay.month,
          currentDay.day - 1,
        );
      } else if (session.isBefore(currentDay)) {
        break; // Gap found
      }
    }

    return streak;
  }

  /// Get count of study sessions in current week (Monday-Sunday)
  int getThisWeekSessionCount(List<DateTime> sessions) {
    if (sessions.isEmpty) return 0;

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

  /// Calculate progress percentage (0-100)
  int calculateProgressPercentage({
    required int completed,
    required int total,
  }) {
    if (total == 0) return 0;
    final percentage = (completed / total * 100).round();
    return percentage > 100 ? 100 : percentage; // Cap at 100
  }

  /// Get detailed progress statistics from word progress map
  ProgressStats getProgressStats(
    Map<String, String> wordProgress, {
    required int totalWords,
  }) {
    var known = 0;
    var difficult = 0;
    var reviewing = 0;
    var mastered = 0;

    for (final status in wordProgress.values) {
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

    final studiedWords = known + difficult + reviewing + mastered;
    final unstudied = totalWords - studiedWords;

    return ProgressStats(
      knownWords: known,
      difficultWords: difficult,
      reviewingWords: reviewing,
      masteredWords: mastered,
      unstudiedWords: unstudied > 0 ? unstudied : 0,
      totalWords: totalWords,
    );
  }

  /// Check if a streak is currently active (studied today or yesterday)
  bool isStreakActive(List<DateTime> sessions) {
    if (sessions.isEmpty) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(today.year, today.month, today.day - 1);

    return sessions.any((session) {
      final sessionNormalized = DateTime(
        session.year,
        session.month,
        session.day,
      );
      return sessionNormalized == today || sessionNormalized == yesterday;
    });
  }
}

/// Progress statistics data class
class ProgressStats {
  const ProgressStats({
    required this.knownWords,
    required this.difficultWords,
    required this.reviewingWords,
    required this.masteredWords,
    required this.unstudiedWords,
    required this.totalWords,
  });

  final int knownWords;
  final int difficultWords;
  final int reviewingWords;
  final int masteredWords;
  final int unstudiedWords;
  final int totalWords;

  int get studiedWords =>
      knownWords + difficultWords + reviewingWords + masteredWords;

  int get progressPercentage =>
      totalWords > 0 ? (studiedWords / totalWords * 100).round() : 0;
}