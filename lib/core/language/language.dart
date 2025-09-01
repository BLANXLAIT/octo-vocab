// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';

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

final appLanguageProvider = StateProvider<AppLanguage>((ref) {
  return AppLanguage.latin; // default
});

final vocabularyLevelProvider = StateProvider<VocabularyLevel>((ref) {
  return VocabularyLevel.beginner; // default
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
    final lang = ref.watch(appLanguageProvider);
    return PopupMenuButton<AppLanguage>(
      tooltip: 'Language',
      icon: const Icon(Icons.language),
      onSelected: (value) {
        ref.read(appLanguageProvider.notifier).state = value;
      },
      itemBuilder: (context) => [
        for (final l in AppLanguage.values)
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
