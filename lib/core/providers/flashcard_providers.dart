import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:octo_vocab/core/language/models/vocabulary_item.dart';
import 'package:octo_vocab/core/providers/language_providers.dart';
import 'package:octo_vocab/core/providers/progress_providers.dart';
import 'package:octo_vocab/core/providers/storage_providers.dart';

// ignore_for_file: public_member_api_docs

/// Learning queue provider - filters out known/mastered words and respects timing constraints
final learningQueueProvider = FutureProvider.autoDispose<List<VocabularyItem>>((
  ref,
) async {
  final vocabulary = await ref.watch(vocabularyProvider.future);
  final wordProgress = await ref.watch(wordProgressProvider.future);
  final dataService = ref.watch(localDataServiceProvider);
  final currentPlugin = ref.watch(currentLanguagePluginProvider);

  debugPrint('📚 LEARNING DEBUG: Loading learning queue...');
  debugPrint('📚 LEARNING DEBUG: Total vocabulary items: ${vocabulary.length}');
  debugPrint(
    '📚 LEARNING DEBUG: Word progress entries: ${wordProgress.length}',
  );

  if (currentPlugin == null) {
    debugPrint(
      '📚 LEARNING DEBUG: No current language plugin, returning empty queue',
    );
    return [];
  }

  // Get timing-available words based on interaction history
  final allWordIds = vocabulary.map((item) => item.id).toList();
  final availableWordIds = dataService.getAvailableWords(allWordIds);

  debugPrint(
    '📚 LEARNING DEBUG: ${availableWordIds.length}/${allWordIds.length} words available based on timing constraints',
  );

  final learningQueue = <VocabularyItem>[];

  for (final item in vocabulary) {
    final progressKey = currentPlugin.getProgressKey(item.id);
    final status = wordProgress[progressKey];

    debugPrint(
      '📚 LEARNING DEBUG: Item "${item.term}" (${item.id}) -> key: "$progressKey" -> status: "$status"',
    );

    // Skip words that are already known or mastered
    if (status == 'known' || status == 'mastered') {
      debugPrint(
        '📚 LEARNING DEBUG: Skipping "${item.term}" - already learned (status: $status)',
      );
      continue;
    }

    // Check timing constraints - skip if word was seen too recently
    if (!availableWordIds.contains(item.id)) {
      debugPrint(
        '📚 LEARNING DEBUG: Skipping "${item.term}" - timing constraint not met',
      );
      continue;
    }

    // Include words that are new (no status), difficult, or reviewing
    // This gives users a chance to learn new words and re-practice difficult ones
    learningQueue.add(item);
  }

  // Shuffle for varied learning order
  learningQueue.shuffle();

  debugPrint(
    '📚 LEARNING DEBUG: Final learning queue contains ${learningQueue.length} words',
  );
  for (final item in learningQueue.take(5)) {
    // Show first 5 for brevity
    debugPrint('📚 LEARNING DEBUG: -> "${item.term}" will appear in Learn tab');
  }
  if (learningQueue.length > 5) {
    debugPrint(
      '📚 LEARNING DEBUG: ... and ${learningQueue.length - 5} more words',
    );
  }

  return learningQueue;
});

/// Card controller for programmatic control
final cardControllerProvider = Provider.autoDispose<CardSwiperController>(
  (ref) => CardSwiperController(),
);

/// Current flashcard index
final currentCardIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

/// Whether the current card is flipped to show back
final isCardFlippedProvider = StateProvider.autoDispose<bool>((ref) => false);