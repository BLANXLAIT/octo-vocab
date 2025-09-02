// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';

/// Combined language and level selection widget
class VocabularySelector extends ConsumerWidget {
  const VocabularySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(appLanguageProvider);
    final level = ref.watch(vocabularyLevelProvider);

    return PopupMenuButton<VocabularySelection>(
      tooltip: 'Select Language & Level',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(language.icon, size: 20),
          const SizedBox(width: 4),
          Icon(level.icon, size: 16, color: level.color),
        ],
      ),
      onSelected: (selection) {
        if (selection.language != language) {
          ref.read(appLanguageProvider.notifier).state = selection.language;
        }
        if (selection.level != level) {
          ref.read(vocabularyLevelProvider.notifier).state = selection.level;
        }
      },
      itemBuilder: (context) => [
        // Language Section
        const PopupMenuItem<VocabularySelection>(
          enabled: false,
          child: Text(
            'Language',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        for (final lang in AppLanguage.values)
          PopupMenuItem<VocabularySelection>(
            value: VocabularySelection(language: lang, level: level),
            child: Row(
              children: [
                Icon(lang.icon, size: 18),
                const SizedBox(width: 8),
                Text(lang.label),
                if (lang == language) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 16),
                ],
              ],
            ),
          ),
        
        // Divider
        const PopupMenuDivider(),
        
        // Level Section  
        const PopupMenuItem<VocabularySelection>(
          enabled: false,
          child: Text(
            'Difficulty Level',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        for (final lvl in VocabularyLevel.values)
          PopupMenuItem<VocabularySelection>(
            value: VocabularySelection(language: language, level: lvl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(lvl.icon, size: 18, color: lvl.color),
                    const SizedBox(width: 8),
                    Text(lvl.label, style: TextStyle(color: lvl.color)),
                    if (lvl == level) ...[
                      const Spacer(),
                      const Icon(Icons.check, size: 16),
                    ],
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Text(
                    lvl.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Data class for vocabulary selection
class VocabularySelection {
  const VocabularySelection({
    required this.language,
    required this.level,
  });

  final AppLanguage language;
  final VocabularyLevel level;
}

/// Compact level selector for use in app bars
class LevelSelector extends ConsumerWidget {
  const LevelSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final level = ref.watch(vocabularyLevelProvider);

    return PopupMenuButton<VocabularyLevel>(
      tooltip: 'Select Difficulty Level',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: level.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: level.color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(level.icon, size: 14, color: level.color),
            const SizedBox(width: 4),
            Text(
              level.label,
              style: TextStyle(
                color: level.color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      onSelected: (selectedLevel) {
        ref.read(vocabularyLevelProvider.notifier).state = selectedLevel;
      },
      itemBuilder: (context) => VocabularyLevel.values
          .map(
            (lvl) => PopupMenuItem<VocabularyLevel>(
              value: lvl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(lvl.icon, size: 18, color: lvl.color),
                      const SizedBox(width: 8),
                      Text(lvl.label, style: TextStyle(color: lvl.color)),
                      if (lvl == level) ...[
                        const Spacer(),
                        const Icon(Icons.check, size: 16),
                      ],
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 26),
                    child: Text(
                      lvl.description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

/// Material 3 SegmentedButton for language selection
class LanguageSegmentedButton extends ConsumerWidget {
  const LanguageSegmentedButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(appLanguageProvider);
    
    return SegmentedButton<AppLanguage>(
      segments: AppLanguage.values.map((language) {
        return ButtonSegment<AppLanguage>(
          value: language,
          icon: Icon(language.icon, size: 18),
          label: Text(
            language.label,
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
      selected: {currentLanguage},
      onSelectionChanged: (Set<AppLanguage> selected) {
        if (selected.isNotEmpty) {
          ref.read(appLanguageProvider.notifier).state = selected.first;
        }
      },
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Material 3 Chips for vocabulary level selection
class VocabularyLevelChips extends ConsumerWidget {
  const VocabularyLevelChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLevel = ref.watch(vocabularyLevelProvider);
    
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: VocabularyLevel.values.map((level) {
        final isSelected = currentLevel == level;
        
        return FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                level.icon,
                size: 16,
                color: isSelected 
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : level.color,
              ),
              const SizedBox(width: 6),
              Text(
                level.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
          onSelected: (selected) {
            if (selected) {
              ref.read(vocabularyLevelProvider.notifier).state = level;
            }
          },
          backgroundColor: level.color.withValues(alpha: 0.1),
          selectedColor: level.color.withValues(alpha: 0.2),
          checkmarkColor: level.color,
          side: BorderSide(
            color: level.color.withValues(alpha: isSelected ? 0.6 : 0.3),
            width: isSelected ? 2 : 1,
          ),
        );
      }).toList(),
    );
  }
}