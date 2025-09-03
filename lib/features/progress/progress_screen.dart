// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/models/word.dart';
import 'package:flutter_saas_template/core/providers/study_config_providers.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';
import 'package:flutter_saas_template/core/services/vocabulary_cache_service.dart';

/// Helper function to load all vocabulary sets for a given language and level
Future<List<Word>> _loadAllVocabularyForLevel(
  VocabularyCacheService cacheService,
  AppLanguage language,
  VocabularyLevel level,
) async {
  final allWords = <Word>[];
  final vocabularySets = VocabularySets.getSetsForLevel(level);
  
  if (vocabularySets.isEmpty) {
    // Fallback to grade8_set1 if no sets are defined for this level
    try {
      final fallbackWords = await cacheService.loadVocabulary(
        language: language,
        level: level,
        setName: 'grade8_set1',
      );
      allWords.addAll(fallbackWords);
    } catch (e) {
      // If no vocabulary exists, return empty list
    }
  } else {
    // Load all vocabulary sets for this level using the cache service
    for (final vocabSet in vocabularySets) {
      try {
        final setWords = await cacheService.loadVocabulary(
          language: language,
          level: level,
          setName: vocabSet.filename, // Pass filename directly to cache service
        );
        allWords.addAll(setWords);
      } catch (e) {
        // Skip sets that don't exist for this language
        continue;
      }
    }
  }
  
  return allWords;
}

/// Optimized multi-language progress data provider with caching
final multiLanguageProgressProvider = FutureProvider<MultiLanguageProgressData>((ref) async {
  final dataService = await ref.read(localDataServiceProvider.future);
  final enabledConfigs = ref.watch(enabledLanguageConfigsProvider);
  final cacheService = ref.read(vocabularyCacheServiceProvider);
  
  final languageProgressMap = <String, LanguageProgressData>{};
  
  // Load vocabulary concurrently for better performance
  final vocabularyFutures = <String, Future<List<Word>>>{};
  
  for (final config in enabledConfigs) {
    final language = config.language.name;
    final level = config.level;
    
    // Load ALL vocabulary sets for this language/level combination
    vocabularyFutures[language] = _loadAllVocabularyForLevel(
      cacheService,
      config.language,
      level,
    );
  }
  
  // Wait for all vocabulary to load and build progress data
  for (final config in enabledConfigs) {
    final language = config.language.name;
    
    try {
      final allWords = await vocabularyFutures[language]!;
      
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
    } catch (e) {
      // Graceful fallback for failed vocabulary loading
      languageProgressMap[language] = LanguageProgressData(
        language: language,
        totalWords: 0,
        masteredCount: 0,
        learningCount: 0,
        unstudiedCount: 0,
        difficultWordIds: const {},
        knownWordIds: const {},
      );
    }
  }
  
  // Create set of studying languages from enabled configs
  final studyingLanguages = enabledConfigs.map((config) => config.language.name).toSet();
  
  return MultiLanguageProgressData(
    languages: languageProgressMap,
    studyingLanguages: studyingLanguages,
  );
}, dependencies: [localDataServiceProvider, enabledLanguageConfigsProvider]);

/// Combined progress data including vocabulary and learning statistics (backward compatibility)
final progressDataProvider = FutureProvider.autoDispose<ProgressData>((ref) async {
  final multiLangProgress = await ref.watch(multiLanguageProgressProvider.future);
  final currentLang = ref.watch(currentLanguageProvider);
  
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        automaticallyImplyLeading: false,
        actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language-specific Progress
            _buildLanguageProgressSection(context, ref),
            
            const SizedBox(height: 16),
            
            // Privacy notice
            _buildPrivacyNotice(context),
          ],
        ),
      ),
    );
  }


  Widget _buildPrivacyNotice(BuildContext context) {
    return Container(
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
    );
  }

  Widget _buildLanguageProgressSection(BuildContext context, WidgetRef ref) {
    final multiLangAsync = ref.watch(multiLanguageProgressProvider);
    
    return multiLangAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              Text('Error loading progress: $e'),
            ],
          ),
        ),
      ),
      data: (multiLangData) {
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              multiLangData.languages.length > 1 ? 'Progress by Language' : 'Your Progress',
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
