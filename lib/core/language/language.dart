// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

String vocabAssetPath(AppLanguage lang, String filename) {
  // filename example: 'grade8_set1.json'
  return 'assets/vocab/${lang.code}/$filename';
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
