import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_saas_template/core/language/language_registry.dart';
import 'package:flutter_saas_template/core/language/models/language.dart';

// ignore_for_file: public_member_api_docs

/// A widget that allows users to select a language
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableLanguages = ref.watch(availableLanguagesProvider);
    final selectedLanguageCode = ref.watch(selectedLanguageProvider);
    
    if (availableLanguages.isEmpty) {
      return const SizedBox.shrink();
    }

    if (availableLanguages.length == 1) {
      // Only one language available, show as a chip
      final language = availableLanguages.first;
      return Chip(
        avatar: Icon(language.icon, size: 16),
        label: Text(language.name),
        backgroundColor: language.color.withValues(alpha: 0.1),
      );
    }

    // Multiple languages available, show as dropdown
    final selectedLanguage = availableLanguages.firstWhere(
      (lang) => lang.code == selectedLanguageCode,
      orElse: () => availableLanguages.first,
    );

    return DropdownButton<String>(
      value: selectedLanguageCode,
      onChanged: (String? newLanguageCode) {
        if (newLanguageCode != null) {
          ref.read(selectedLanguageProvider.notifier).state = newLanguageCode;
        }
      },
      items: availableLanguages.map<DropdownMenuItem<String>>((Language language) {
        return DropdownMenuItem<String>(
          value: language.code,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(language.icon, size: 16, color: language.color),
              const SizedBox(width: 8),
              Text(language.name),
            ],
          ),
        );
      }).toList(),
      underline: Container(), // Remove default underline
      icon: const Icon(Icons.arrow_drop_down),
      isDense: true,
    );
  }
}

/// A compact language selector for app bars
class LanguageSelectorAction extends ConsumerWidget {
  const LanguageSelectorAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableLanguages = ref.watch(availableLanguagesProvider);
    final selectedLanguageCode = ref.watch(selectedLanguageProvider);
    
    if (availableLanguages.isEmpty) {
      return const SizedBox.shrink();
    }

    if (availableLanguages.length == 1) {
      // Only one language available, show as icon button (disabled)
      final language = availableLanguages.first;
      return IconButton(
        onPressed: null,
        icon: Icon(language.icon),
        tooltip: language.name,
      );
    }

    // Multiple languages available, show as popup menu
    final selectedLanguage = availableLanguages.firstWhere(
      (lang) => lang.code == selectedLanguageCode,
      orElse: () => availableLanguages.first,
    );

    return PopupMenuButton<String>(
      onSelected: (String languageCode) {
        ref.read(selectedLanguageProvider.notifier).state = languageCode;
      },
      itemBuilder: (BuildContext context) {
        return availableLanguages.map((Language language) {
          final isSelected = language.code == selectedLanguageCode;
          return PopupMenuItem<String>(
            value: language.code,
            child: Row(
              children: [
                Icon(
                  language.icon, 
                  size: 18, 
                  color: isSelected ? language.color : null,
                ),
                const SizedBox(width: 12),
                Text(
                  language.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? language.color : null,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Icon(Icons.check, size: 16, color: language.color),
                ],
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selectedLanguage.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selectedLanguage.icon, size: 16, color: selectedLanguage.color),
            const SizedBox(width: 4),
            Text(
              selectedLanguage.code.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: selectedLanguage.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}