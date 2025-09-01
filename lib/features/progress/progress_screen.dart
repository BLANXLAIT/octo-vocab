// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_saas_template/core/language/language.dart';
import 'package:flutter_saas_template/core/models/word.dart';

final progressVocabProvider = FutureProvider.autoDispose<List<Word>>((
  ref,
) async {
  final lang = ref.watch(appLanguageProvider);
  final path = vocabAssetPath(lang, 'grade8_set1.json');
  final jsonStr = await rootBundle.loadString(path);
  return Word.listFromJsonString(jsonStr);
});

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsync = ref.watch(progressVocabProvider);

    return wordsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Progress'),
          automaticallyImplyLeading: false,
          actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => Scaffold(
        appBar: AppBar(
          title: const Text('Progress'),
          automaticallyImplyLeading: false,
          actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
        ),
        body: Center(child: Text('Failed to load vocab: $e')),
      ),
      data: (words) {
        final total = words.length;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Progress'),
            automaticallyImplyLeading: false,
            actions: const [LanguageSwitcherAction(), SizedBox(width: 8)],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.library_books),
                    title: const Text('Total words'),
                    trailing: Text('$total'),
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Mastered (MVP placeholder)'),
                    trailing: Text('—'),
                  ),
                ),
                const SizedBox(height: 12),
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.school_outlined),
                    title: Text('In learning (MVP placeholder)'),
                    trailing: Text('—'),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Notes',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mastery tracking will use local persistence and a spaced '
                  'repetition scheduler in a later milestone. '
                  'For now, this screen shows basic totals as a placeholder.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
