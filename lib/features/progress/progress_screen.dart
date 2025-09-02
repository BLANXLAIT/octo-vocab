// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/language/vocabulary_selector.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/models/word.dart';
import 'package:flutter_saas_template/core/navigation/adaptive_scaffold.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';

/// Multi-language progress data provider
final multiLanguageProgressProvider = FutureProvider.autoDispose<MultiLanguageProgressData>((ref) async {
  final dataService = await ref.read(localDataServiceProvider.future);
  final studyingLanguages = dataService.getStudyingLanguages();
  final level = ref.watch(vocabularyLevelProvider);
  
  final languageProgressMap = <String, LanguageProgressData>{};
  
  for (final language in studyingLanguages) {
    // Load vocabulary for this language
    List<Word> allWords;
    final sets = VocabularySets.getSetsForLevel(level);
    if (sets.isEmpty) {
      final path = vocabAssetPath(AppLanguage.values.firstWhere((l) => l.name == language), 'grade8_set1.json');
      final jsonStr = await rootBundle.loadString(path);
      allWords = Word.listFromJsonString(jsonStr);
    } else {
      final set = sets.first;
      final path = vocabularySetAssetPath(AppLanguage.values.firstWhere((l) => l.name == language), set);
      final jsonStr = await rootBundle.loadString(path);
      allWords = Word.listFromJsonString(jsonStr);
    }
    
    // Get statistics for this language
    final stats = dataService.getLearningStatsForLanguage(language);
    final difficultWords = dataService.getDifficultWordsForLanguage(language);
    final knownWords = dataService.getKnownWordsForLanguage(language);
    
    languageProgressMap[language] = LanguageProgressData(
      language: language,
      totalWords: allWords.length,
      masteredCount: stats['known_count'] ?? 0,
      learningCount: stats['difficult_count'] ?? 0,
      unstudiedCount: allWords.length - (stats['total_studied'] ?? 0),
      difficultWordIds: difficultWords,
      knownWordIds: knownWords,
    );
  }
  
  return MultiLanguageProgressData(
    languages: languageProgressMap,
    studyingLanguages: studyingLanguages,
  );
});

/// Combined progress data including vocabulary and learning statistics (backward compatibility)
final progressDataProvider = FutureProvider.autoDispose<ProgressData>((ref) async {
  final multiLangProgress = await ref.watch(multiLanguageProgressProvider.future);
  final currentLang = ref.watch(appLanguageProvider);
  
  // Return current language progress or combined if no specific language data
  final langProgress = multiLangProgress.languages[currentLang.name];
  if (langProgress != null) {
    return ProgressData(
      totalWords: langProgress.totalWords,
      masteredCount: langProgress.masteredCount,
      learningCount: langProgress.learningCount,
      unstudiedCount: langProgress.unstudiedCount,
      difficultWordIds: langProgress.difficultWordIds,
      knownWordIds: langProgress.knownWordIds,
    );
  }
  
  // Fallback to combined stats
  final totalWords = multiLangProgress.languages.values.fold(0, (sum, lang) => sum + lang.totalWords);
  final masteredCount = multiLangProgress.languages.values.fold(0, (sum, lang) => sum + lang.masteredCount);
  final learningCount = multiLangProgress.languages.values.fold(0, (sum, lang) => sum + lang.learningCount);
  final unstudiedCount = multiLangProgress.languages.values.fold(0, (sum, lang) => sum + lang.unstudiedCount);
  
  return ProgressData(
    totalWords: totalWords,
    masteredCount: masteredCount,
    learningCount: learningCount,
    unstudiedCount: unstudiedCount,
    difficultWordIds: multiLangProgress.languages.values.expand((lang) => lang.difficultWordIds).toSet(),
    knownWordIds: multiLangProgress.languages.values.expand((lang) => lang.knownWordIds).toSet(),
  );
});

/// Data class for progress information
class ProgressData {
  const ProgressData({
    required this.totalWords,
    required this.masteredCount,
    required this.learningCount,
    required this.unstudiedCount,
    required this.difficultWordIds,
    required this.knownWordIds,
  });

  final int totalWords;
  final int masteredCount;
  final int learningCount;
  final int unstudiedCount;
  final Set<String> difficultWordIds;
  final Set<String> knownWordIds;
  
  double get masteryPercentage => totalWords > 0 ? (masteredCount / totalWords) * 100 : 0.0;
  double get studiedPercentage => totalWords > 0 ? ((masteredCount + learningCount) / totalWords) * 100 : 0.0;
}

/// Data class for individual language progress
class LanguageProgressData {
  const LanguageProgressData({
    required this.language,
    required this.totalWords,
    required this.masteredCount,
    required this.learningCount,
    required this.unstudiedCount,
    required this.difficultWordIds,
    required this.knownWordIds,
  });

  final String language;
  final int totalWords;
  final int masteredCount;
  final int learningCount;
  final int unstudiedCount;
  final Set<String> difficultWordIds;
  final Set<String> knownWordIds;
  
  double get masteryPercentage => totalWords > 0 ? (masteredCount / totalWords) * 100 : 0.0;
  double get studiedPercentage => totalWords > 0 ? ((masteredCount + learningCount) / totalWords) * 100 : 0.0;
  
  String get displayName {
    switch (language) {
      case 'latin':
        return 'Latin';
      case 'spanish':
        return 'Spanish';
      default:
        return language.substring(0, 1).toUpperCase() + language.substring(1);
    }
  }
}

/// Data class for multi-language progress information
class MultiLanguageProgressData {
  const MultiLanguageProgressData({
    required this.languages,
    required this.studyingLanguages,
  });

  final Map<String, LanguageProgressData> languages;
  final Set<String> studyingLanguages;
  
  /// Get combined statistics across all languages
  ProgressData get combinedProgress {
    final totalWords = languages.values.fold(0, (sum, lang) => sum + lang.totalWords);
    final masteredCount = languages.values.fold(0, (sum, lang) => sum + lang.masteredCount);
    final learningCount = languages.values.fold(0, (sum, lang) => sum + lang.learningCount);
    final unstudiedCount = languages.values.fold(0, (sum, lang) => sum + lang.unstudiedCount);
    
    return ProgressData(
      totalWords: totalWords,
      masteredCount: masteredCount,
      learningCount: learningCount,
      unstudiedCount: unstudiedCount,
      difficultWordIds: languages.values.expand((lang) => lang.difficultWordIds).toSet(),
      knownWordIds: languages.values.expand((lang) => lang.knownWordIds).toSet(),
    );
  }
}

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(progressDataProvider);

    return progressAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Progress'),
          automaticallyImplyLeading: false,
          actions: const [VocabularySelector(), SizedBox(width: 8)],
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(
          title: const Text('Progress'),
          automaticallyImplyLeading: false,
          actions: const [VocabularySelector(), SizedBox(width: 8)],
        ),
        body: Center(child: Text('Failed to load progress: $e')),
      ),
      data: (progress) => Scaffold(
        appBar: AppBar(
          title: const Text('Progress'),
          automaticallyImplyLeading: false,
          actions: const [VocabularySelector(), SizedBox(width: 8)],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Progress Card
              _buildOverallProgressCard(context, progress),
              
              const SizedBox(height: 16),
              
              // Statistics Grid
              _buildStatisticsGrid(context, progress),
              
              const SizedBox(height: 16),
              
              // Progress Breakdown
              _buildProgressBreakdown(context, progress),
              
              const SizedBox(height: 16),
              
              // Language-specific Progress
              _buildLanguageProgressSection(context, ref),
              
              const SizedBox(height: 16),
              
              // Quick Actions
              _buildQuickActions(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallProgressCard(BuildContext context, ProgressData progress) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up, 
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Learning Progress',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Progress indicators
            _buildProgressIndicator(
              context,
              label: 'Mastery',
              value: progress.masteryPercentage,
              color: Colors.green,
              count: progress.masteredCount,
              total: progress.totalWords,
            ),
            
            const SizedBox(height: 12),
            
            _buildProgressIndicator(
              context,
              label: 'Overall Study',
              value: progress.studiedPercentage,
              color: Colors.blue,
              count: progress.masteredCount + progress.learningCount,
              total: progress.totalWords,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(
    BuildContext context, {
    required String label,
    required double value,
    required Color color,
    required int count,
    required int total,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$count / $total (${value.toStringAsFixed(1)}%)',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: value / 100,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildStatisticsGrid(BuildContext context, ProgressData progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.8,
          children: [
            _buildStatCard(
              context,
              icon: Icons.check_circle,
              color: Colors.green,
              label: 'Mastered',
              value: '${progress.masteredCount}',
            ),
            _buildStatCard(
              context,
              icon: Icons.psychology,
              color: Colors.orange,
              label: 'In Review',
              value: '${progress.learningCount}',
            ),
            _buildStatCard(
              context,
              icon: Icons.fiber_new,
              color: Colors.blue,
              label: 'Unstudied',
              value: '${progress.unstudiedCount}',
            ),
            _buildStatCard(
              context,
              icon: Icons.library_books,
              color: Colors.purple,
              label: 'Total Words',
              value: '${progress.totalWords}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBreakdown(BuildContext context, ProgressData progress) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress Breakdown',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.withValues(alpha: 0.2),
                  child: const Icon(Icons.check_circle, color: Colors.green),
                ),
                title: const Text('Mastered Words'),
                subtitle: const Text('Words you know well'),
                trailing: Text(
                  '${progress.masteredCount}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withValues(alpha: 0.2),
                  child: const Icon(Icons.psychology, color: Colors.orange),
                ),
                title: const Text('In Review'),
                subtitle: const Text('Words marked as difficult'),
                trailing: Text(
                  '${progress.learningCount}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withValues(alpha: 0.2),
                  child: const Icon(Icons.fiber_new, color: Colors.blue),
                ),
                title: const Text('Not Yet Studied'),
                subtitle: const Text('Words you have not encountered'),
                trailing: Text(
                  '${progress.unstudiedCount}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.school, color: Colors.blue),
                title: const Text('Continue Learning'),
                subtitle: const Text('Study new vocabulary words'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to Learn tab
                  ref.read(navigationIndexProvider.notifier).state = 0;
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.psychology, color: Colors.orange),
                title: const Text('Review Difficult Words'),
                subtitle: const Text('Focus on words you found challenging'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to Review tab
                  ref.read(navigationIndexProvider.notifier).state = 2;
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.quiz, color: Colors.green),
                title: const Text('Take a Quiz'),
                subtitle: const Text('Test your knowledge'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navigate to Quiz tab
                  ref.read(navigationIndexProvider.notifier).state = 1;
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Privacy notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border.all(color: Colors.green.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your progress is stored privately on your device. No data is shared or uploaded.',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageProgressSection(BuildContext context, WidgetRef ref) {
    final multiLangAsync = ref.watch(multiLanguageProgressProvider);
    
    return multiLangAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Text('Error loading multi-language progress: $e'),
      data: (multiLangData) {
        if (multiLangData.languages.length <= 1) {
          // Don't show language breakdown if only one language
          return const SizedBox.shrink();
        }
        
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress by Language',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            // Language progress cards
            ...multiLangData.languages.values.map((langProgress) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Language header
                        Row(
                          children: [
                            _getLanguageFlag(langProgress.language),
                            const SizedBox(width: 12),
                            Text(
                              langProgress.displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${langProgress.masteryPercentage.toStringAsFixed(1)}% mastered',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Progress bar
                        LinearProgressIndicator(
                          value: langProgress.masteryPercentage / 100,
                          backgroundColor: Colors.green.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation(Colors.green),
                          minHeight: 6,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Stats row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildLanguageStatItem(
                              context,
                              icon: Icons.check_circle,
                              label: 'Mastered',
                              count: langProgress.masteredCount,
                              color: Colors.green,
                            ),
                            _buildLanguageStatItem(
                              context,
                              icon: Icons.psychology,
                              label: 'Learning',
                              count: langProgress.learningCount,
                              color: Colors.orange,
                            ),
                            _buildLanguageStatItem(
                              context,
                              icon: Icons.fiber_new,
                              label: 'New',
                              count: langProgress.unstudiedCount,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildLanguageStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _getLanguageFlag(String language) {
    switch (language) {
      case 'latin':
        return const Text('🏛️', style: TextStyle(fontSize: 24)); // Classical building for Latin
      case 'spanish':
        return const Text('🇪🇸', style: TextStyle(fontSize: 24));
      default:
        return const Icon(Icons.language, size: 24);
    }
  }
}
