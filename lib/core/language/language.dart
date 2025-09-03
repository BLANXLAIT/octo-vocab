// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';
import 'package:flutter_saas_template/core/providers/study_config_providers.dart';

enum AppLanguage { latin, spanish }

extension AppLanguageX on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.latin:
        return 'latin';
      case AppLanguage.spanish:
        return 'spanish';
    }
  }

  String get label {
    switch (this) {
      case AppLanguage.latin:
        return 'Latin';
      case AppLanguage.spanish:
        return 'Spanish';
    }
  }

  IconData get icon {
    switch (this) {
      case AppLanguage.latin:
        return Icons.school;
      case AppLanguage.spanish:
        return Icons.translate;
    }
  }
}

// Legacy providers - will be replaced by new system
final appLanguageProvider = StateProvider<AppLanguage>((ref) {
  // Use new system if available, fallback to default
  return ref.watch(currentLanguageProvider);
});

final vocabularyLevelProvider = StateProvider<VocabularyLevel>((ref) {
  // Use new system if available, fallback to default
  return ref.watch(currentLevelProvider);
});

String vocabAssetPath(AppLanguage lang, String filename) {
  // Legacy support for old format: 'grade8_set1.json'
  return 'assets/vocab/${lang.code}/$filename';
}

String leveledVocabAssetPath(
  AppLanguage lang,
  VocabularyLevel level,
  String filename,
) {
  // New leveled format: 'assets/vocab/latin/beginner/set1_essentials.json'
  return 'assets/vocab/${lang.code}/${level.code}/$filename';
}

String vocabularySetAssetPath(AppLanguage lang, VocabularySet set) {
  return leveledVocabAssetPath(lang, set.level, set.filename);
}

class LanguageSwitcherAction extends ConsumerWidget {
  const LanguageSwitcherAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(currentLanguageProvider);
    final enabledConfigs = ref.watch(enabledLanguageConfigsProvider);

    // Only show languages that are enabled for study
    final availableLanguages = enabledConfigs
        .map((config) => config.language)
        .toList();

    if (availableLanguages.isEmpty || availableLanguages.length == 1) {
      // If no enabled languages or only one, just show current language as icon
      return Icon(lang.icon);
    }

    return PopupMenuButton<AppLanguage>(
      tooltip: 'Switch Active Language',
      icon: Icon(lang.icon),
      onSelected: (value) {
        ref.read(studyConfigurationProvider.notifier).setCurrentLanguage(value);
      },
      itemBuilder: (context) => [
        for (final l in availableLanguages)
          PopupMenuItem<AppLanguage>(
            value: l,
            child: Row(
              children: [
                Icon(l.icon, size: 18),
                const SizedBox(width: 8),
                Text(l.label),
                if (l == lang) ...[
                  const Spacer(),
                  const Icon(Icons.check, size: 16),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
