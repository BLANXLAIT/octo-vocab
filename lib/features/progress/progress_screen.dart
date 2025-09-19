// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:octo_vocab/core/language/language_registry.dart';
import 'package:octo_vocab/core/language/widgets/language_selector.dart';
import 'package:octo_vocab/core/services/local_data_service.dart';
import 'package:octo_vocab/features/flashcards/flashcards_screen.dart';

/// Progress tracking providers
final studySessionsProvider = FutureProvider<List<DateTime>>((ref) async {
  final dataService = await ref.watch(localDataServiceProvider.future);
  return dataService.getStudySessions();
});

final wordProgressProvider = FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final dataService = await ref.watch(localDataServiceProvider.future);
  final selectedLanguage = ref.watch(selectedLanguageProvider);
  final currentPlugin = ref.watch(currentLanguagePluginProvider);

  final allProgress = dataService.getWordProgress();

  // Filter progress to only include items for the current language
  if (currentPlugin == null) return {};

  final languageSpecificProgress = <String, String>{};
  for (final entry in allProgress.entries) {
    // Progress keys are stored as "languageCode_wordId"
    if (entry.key.startsWith('${selectedLanguage}_')) {
      // KEEP the full key (including language prefix) - other providers expect this format
      languageSpecificProgress[entry.key] = entry.value;
    }
  }

  return languageSpecificProgress;
});

final quizResultsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final dataService = await ref.watch(localDataServiceProvider.future);
  final selectedLanguage = ref.watch(selectedLanguageProvider);

  final allResults = dataService.getQuizResults();

  // Filter quiz results to only include current language
  final languageSpecificResults = <String, dynamic>{};
  for (final entry in allResults.entries) {
    if (entry.key.startsWith('quiz_${selectedLanguage}_')) {
      languageSpecificResults[entry.key] = entry.value;
    }
  }

  return languageSpecificResults;
});

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studySessionsAsync = ref.watch(studySessionsProvider);
    final wordProgressAsync = ref.watch(wordProgressProvider);
    final quizResultsAsync = ref.watch(quizResultsProvider);
    final vocabularyAsync = ref.watch(learningQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        automaticallyImplyLeading: false,
        actions: const [LanguageSelectorAction(), SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Study Streak Section
            _buildStudyStreakCard(studySessionsAsync),
            const SizedBox(height: 16),

            // Vocabulary Progress Section
            _buildVocabularyProgressCard(wordProgressAsync, vocabularyAsync),
            const SizedBox(height: 16),

            // Quiz Results Section
            _buildQuizResultsCard(quizResultsAsync),
            const SizedBox(height: 16),

            // Recent Activity Section
            _buildRecentActivityCard(studySessionsAsync),
            const SizedBox(height: 16),

            // Learning Tips Section
            _buildLearningTipsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyStreakCard(AsyncValue<List<DateTime>> studySessionsAsync) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange[600]),
                const SizedBox(width: 8),
                const Text(
                  'Study Streak',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            studySessionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error loading streak: $error'),
              data: (sessions) {
                final streak = _calculateStreak(sessions);
                final totalDays = sessions.length;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'Current Streak',
                          '$streak days',
                          Icons.whatshot,
                        ),
                        _buildStatColumn(
                          'Total Days',
                          '$totalDays days',
                          Icons.calendar_today,
                        ),
                        _buildStatColumn(
                          'This Week',
                          '${_getThisWeekSessions(sessions)} days',
                          Icons.date_range,
                        ),
                      ],
                    ),
                    if (streak > 0) ...[
                      const SizedBox(height: 16),
                      _buildStreakVisualizer(sessions),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVocabularyProgressCard(
    AsyncValue<Map<String, String>> wordProgressAsync,
    AsyncValue<List<dynamic>> vocabularyAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Colors.blue[600]),
                const SizedBox(width: 8),
                const Text(
                  'Vocabulary Mastery',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                return wordProgressAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) =>
                      Text('Error loading progress: $error'),
                  data: (wordProgress) {
                    return vocabularyAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Text('Error loading vocabulary: $error'),
                      data: (vocabulary) {
                        final knownWords = wordProgress.values
                            .where((status) => status == 'known')
                            .length;
                        final difficultWords = wordProgress.values
                            .where((status) => status == 'difficult')
                            .length;
                        final totalWords = vocabulary.length;
                        final studiedWords = knownWords + difficultWords;
                        final unstudiedWords = totalWords - studiedWords;

                        final progressPercentage = totalWords > 0
                            ? (knownWords / totalWords * 100).round()
                            : 0;

                        return Column(
                          children: [
                            // Progress Bar
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: totalWords > 0
                                        ? knownWords / totalWords
                                        : 0,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.green[600],
                                    ),
                                    minHeight: 8,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '$progressPercentage%',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatColumn(
                                  'Known',
                                  '$knownWords',
                                  Icons.check_circle,
                                  Colors.green,
                                ),
                                _buildStatColumn(
                                  'Learning',
                                  '$difficultWords',
                                  Icons.school,
                                  Colors.orange,
                                ),
                                _buildStatColumn(
                                  'New',
                                  '$unstudiedWords',
                                  Icons.fiber_new,
                                  Colors.grey,
                                ),
                              ],
                            ),

                            if (totalWords > 0) ...[
                              const SizedBox(height: 16),
                              _buildProgressChart(
                                knownWords,
                                difficultWords,
                                unstudiedWords,
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizResultsCard(
    AsyncValue<Map<String, dynamic>> quizResultsAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: Colors.purple[600]),
                const SizedBox(width: 8),
                const Text(
                  'Quiz Performance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            quizResultsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Text('Error loading quiz results: $error'),
              data: (quizResults) {
                if (quizResults.isEmpty) {
                  return const Column(
                    children: [
                      Icon(Icons.quiz_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No quiz results yet'),
                      Text(
                        'Take your first quiz to see progress!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  );
                }

                // Calculate quiz stats
                final totalQuizzes = quizResults.length;

                // Calculate best and average scores
                final quizScores = quizResults.entries
                    .where((entry) => entry.key.startsWith('quiz_'))
                    .map((entry) => entry.value as Map<String, dynamic>)
                    .where((quiz) => quiz['percentage'] != null)
                    .map((quiz) => quiz['percentage'] as int)
                    .toList();

                final bestScore = quizScores.isNotEmpty
                    ? quizScores.reduce((a, b) => a > b ? a : b)
                    : 0;
                final avgScore = quizScores.isNotEmpty
                    ? (quizScores.reduce((a, b) => a + b) / quizScores.length)
                          .round()
                    : 0;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(
                          'Quizzes Taken',
                          '$totalQuizzes',
                          Icons.assignment_turned_in,
                        ),
                        _buildStatColumn(
                          'Best Score',
                          quizScores.isNotEmpty ? '$bestScore%' : 'N/A',
                          Icons.emoji_events,
                        ),
                        _buildStatColumn(
                          'Avg Score',
                          quizScores.isNotEmpty ? '$avgScore%' : 'N/A',
                          Icons.trending_up,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard(
    AsyncValue<List<DateTime>> studySessionsAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.indigo[600]),
                const SizedBox(width: 8),
                const Text(
                  'Recent Activity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            studySessionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Error loading activity: $error'),
              data: (sessions) {
                if (sessions.isEmpty) {
                  return const Column(
                    children: [
                      Icon(
                        Icons.history_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text('No study sessions yet'),
                      Text(
                        'Start learning to track your progress!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  );
                }

                final recentSessions = sessions.take(7).toList();
                return Column(
                  children: recentSessions.map((session) {
                    final dayOfWeek = _getDayOfWeek(session.weekday);
                    final formattedDate = '${session.month}/${session.day}';
                    final isToday = _isToday(session);

                    return ListTile(
                      dense: true,
                      leading: Icon(
                        isToday ? Icons.today : Icons.calendar_today,
                        color: isToday ? Colors.green : Colors.grey,
                        size: 20,
                      ),
                      title: Text(
                        dayOfWeek,
                        style: TextStyle(
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: Text(
                        formattedDate,
                        style: TextStyle(
                          color: isToday ? Colors.green : Colors.grey[600],
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningTipsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber[700]),
                const SizedBox(width: 8),
                const Text(
                  'Learning Tips',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer(
              builder: (context, ref, child) {
                final currentPlugin = ref.watch(currentLanguagePluginProvider);
                final tips =
                    currentPlugin?.getLearningTips() ??
                    [
                      'Study a little bit every day for best results',
                      'Use flashcards to reinforce vocabulary',
                      'Practice with quizzes to test your knowledge',
                      'Review difficult words more frequently',
                    ];

                return Column(
                  children: tips
                      .take(3)
                      .map(
                        (tip) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.tips_and_updates,
                                size: 16,
                                color: Colors.amber[700],
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(tip)),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(
    String label,
    String value,
    IconData icon, [
    Color? color,
  ]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey[600], size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStreakVisualizer(List<DateTime> sessions) {
    final now = DateTime.now();
    final last7Days = List.generate(7, (index) {
      return DateTime(now.year, now.month, now.day - (6 - index));
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: last7Days.map((day) {
        final hasSession = sessions.any(
          (session) =>
              session.year == day.year &&
              session.month == day.month &&
              session.day == day.day,
        );

        return Column(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: hasSession ? Colors.green[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
              child: hasSession
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(height: 4),
            Text(
              _getDayOfWeek(day.weekday).substring(0, 1),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildProgressChart(int known, int difficult, int unstudied) {
    final total = known + difficult + unstudied;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      height: 140,
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBar('Known', known, total, Colors.green[600]!),
          _buildBar('Learning', difficult, total, Colors.orange[600]!),
          _buildBar('New', unstudied, total, Colors.grey[400]!),
        ],
      ),
    );
  }

  Widget _buildBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? value / total : 0;
    const maxHeight = 80.0;
    final barHeight = maxHeight * percentage;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: barHeight,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  int _calculateStreak(List<DateTime> sessions) {
    if (sessions.isEmpty) return 0;

    final sortedSessions = sessions.toList()
      ..sort((a, b) => b.compareTo(a)); // Most recent first

    final today = DateTime.now();
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    final todayNormalized = DateTime(today.year, today.month, today.day);

    // Check if user studied today or yesterday to continue streak
    final latestSession = sortedSessions.first;
    final latestNormalized = DateTime(
      latestSession.year,
      latestSession.month,
      latestSession.day,
    );

    if (latestNormalized != todayNormalized && latestNormalized != yesterday) {
      return 0; // Streak is broken
    }

    var streak = 0;
    var currentDay = latestNormalized;

    for (final session in sortedSessions) {
      final sessionDay = DateTime(session.year, session.month, session.day);

      if (sessionDay == currentDay) {
        streak++;
        currentDay = DateTime(
          currentDay.year,
          currentDay.month,
          currentDay.day - 1,
        );
      } else if (sessionDay.isBefore(currentDay)) {
        break; // Gap in streak
      }
    }

    return streak;
  }

  int _getThisWeekSessions(List<DateTime> sessions) {
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

  String _getDayOfWeek(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
