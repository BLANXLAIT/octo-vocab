import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/language_study_config.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/providers/study_config_providers.dart';

/// Unified card for managing language learning settings
class LanguageLearningSettingsCard extends ConsumerWidget {
  const LanguageLearningSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(studyConfigurationProvider);

    return configAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(height: 8),
              Text('Error loading settings: $error'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ref.read(studyConfigurationProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (configSet) => _buildSettingsCard(context, ref, configSet),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    WidgetRef ref,
    StudyConfigurationSet configSet,
  ) {
    final theme = Theme.of(context);
    final enabledCount = configSet.enabledConfigurations.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.school),
                const SizedBox(width: 12),
                const Text(
                  'Language Learning Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$enabledCount active',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enable languages and set difficulty levels. Your progress is tracked separately for each language.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),

            // Current active language indicator
            if (enabledCount > 1) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Currently studying: ${configSet.currentLanguage.label}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Language configurations
            ...AppLanguage.values.map((language) {
              final config = configSet.getConfigForLanguage(language) ??
                  LanguageStudyConfig(
                    language: language,
                    level: VocabularyLevel.beginner,
                    isEnabled: false,
                  );

              return _buildLanguageSettingTile(
                context,
                ref,
                config,
                configSet,
              );
            }),

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
                      'Each language has its own difficulty level and progress tracking. Switch between languages using the language icon in app bars.',
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
  }

  Widget _buildLanguageSettingTile(
    BuildContext context,
    WidgetRef ref,
    LanguageStudyConfig config,
    StudyConfigurationSet configSet,
  ) {
    final theme = Theme.of(context);
    final isCurrentLanguage = config.language == configSet.currentLanguage;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(
          color: config.isEnabled
              ? theme.colorScheme.primary.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
        color: config.isEnabled
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Language header with enable/disable switch
            Row(
              children: [
                _getLanguageIcon(config.language.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getLanguageDisplayName(config.language.name),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isCurrentLanguage) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (config.isEnabled)
                        Text(
                          '${config.level.label} level',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: config.level.color,
                          ),
                        ),
                    ],
                  ),
                ),
                Switch(
                  value: config.isEnabled,
                  onChanged: (enabled) {
                    if (!enabled) {
                      // Don't allow disabling all languages
                      final enabledCount = configSet.enabledConfigurations.length;
                      if (enabledCount <= 1) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You must have at least one language enabled'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                    }

                    // Update the configuration
                    final newConfig = config.copyWith(isEnabled: enabled);
                    ref.read(studyConfigurationProvider.notifier)
                        .updateLanguageConfig(config.language, newConfig);

                    // If enabling and no current language is set, make this current
                    if (enabled && configSet.enabledConfigurations.isEmpty) {
                      ref.read(studyConfigurationProvider.notifier)
                          .setCurrentLanguage(config.language);
                    }
                  },
                ),
              ],
            ),

            // Difficulty level selector (only shown when enabled)
            if (config.isEnabled) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 28), // Align with language icon
                  Text(
                    'Difficulty Level:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(width: 28), // Align with language icon
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: VocabularyLevel.values.map((level) {
                        final isSelected = config.level == level;
                        return FilterChip(
                          selected: isSelected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                level.icon,
                                size: 14,
                                color: isSelected
                                    ? theme.colorScheme.onSecondaryContainer
                                    : level.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                level.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              final newConfig = config.copyWith(level: level);
                              ref.read(studyConfigurationProvider.notifier)
                                  .updateLanguageConfig(
                                    config.language,
                                    newConfig,
                                  );
                            }
                          },
                          backgroundColor: level.color.withValues(alpha: 0.1),
                          selectedColor: level.color.withValues(alpha: 0.2),
                          checkmarkColor: level.color,
                          side: BorderSide(
                            color: level.color.withValues(
                              alpha: isSelected ? 0.6 : 0.3,
                            ),
                            width: isSelected ? 2 : 1,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getLanguageIcon(String language) {
    switch (language) {
      case 'latin':
        return const Text('🏛️', style: TextStyle(fontSize: 18));
      case 'spanish':
        return const Text('🇪🇸', style: TextStyle(fontSize: 18));
      default:
        return const Icon(Icons.language, size: 18);
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