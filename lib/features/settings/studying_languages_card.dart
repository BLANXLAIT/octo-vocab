import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/services/local_data_service.dart';

/// Card for managing which languages the user is actively studying
class StudyingLanguagesCard extends ConsumerWidget {
  const StudyingLanguagesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(localDataServiceProvider.future),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        
        final dataService = snapshot.data!;
        final studyingLanguages = dataService.getStudyingLanguages();
        final theme = Theme.of(context);
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school),
                    const SizedBox(width: 12),
                    const Text(
                      'Studying Languages',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select which languages you want to learn. Your progress will be tracked separately for each language.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Language selection chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppLanguage.values.map((language) {
                    final isSelected = studyingLanguages.contains(language.name);
                    return FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _getLanguageIcon(language.name),
                          const SizedBox(width: 8),
                          Text(_getLanguageDisplayName(language.name)),
                        ],
                      ),
                      onSelected: (selected) async {
                        if (selected) {
                          await dataService.addStudyingLanguage(language.name);
                        } else {
                          // Don't allow removing all languages
                          if (studyingLanguages.length > 1) {
                            await dataService.removeStudyingLanguage(language.name);
                          } else {
                            // Show warning
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('You must be studying at least one language'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        }
                        // Trigger rebuild
                        ref.invalidate(localDataServiceProvider);
                      },
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 12),
                
                // Info about separate progress tracking
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your learning progress is tracked separately for each language. You can see individual progress in the Progress tab.',
                          style: TextStyle(fontSize: 12, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _getLanguageIcon(String language) {
    switch (language) {
      case 'latin':
        return const Text('🏛️', style: TextStyle(fontSize: 16));
      case 'spanish':
        return const Text('🇪🇸', style: TextStyle(fontSize: 16));
      default:
        return const Icon(Icons.language, size: 16);
    }
  }

  String _getLanguageDisplayName(String language) {
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