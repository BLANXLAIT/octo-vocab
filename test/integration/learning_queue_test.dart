import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_vocab/core/language/language_plugin.dart';
import 'package:octo_vocab/core/language/language_registry.dart';
import 'package:octo_vocab/core/language/models/vocabulary_item.dart';
import 'package:octo_vocab/core/language/plugins/latin_plugin.dart';
import 'package:octo_vocab/core/language/plugins/spanish_plugin.dart';
import 'package:octo_vocab/features/flashcards/flashcards_screen.dart';
import 'package:octo_vocab/features/progress/progress_screen.dart';

void main() {
  group('Learning Queue Logic Tests', () {
    late ProviderContainer container;
    late Map<String, String> mockWordProgress;
    late List<VocabularyItem> mockVocabulary;

    setUp(() async {
      // Initialize the language plugins manually for tests
      final registry = LanguageRegistry.instance;
      registry.clear(); // Clear any existing plugins
      registry.register(LatinPlugin());
      registry.register(SpanishPlugin());

      // Mock data
      mockVocabulary = [
        const VocabularyItem(id: 'amor', term: 'amor', translation: 'love'),
        const VocabularyItem(id: 'vita', term: 'vita', translation: 'life'),
        const VocabularyItem(id: 'terra', term: 'terra', translation: 'earth'),
        const VocabularyItem(id: 'aqua', term: 'aqua', translation: 'water'),
        const VocabularyItem(id: 'ignis', term: 'ignis', translation: 'fire'),
      ];

      mockWordProgress = <String, String>{};

      container = ProviderContainer(
        overrides: [
          vocabularyProvider.overrideWith((ref) async => mockVocabulary),
          wordProgressProvider.overrideWith((ref) async => mockWordProgress),
          selectedLanguageProvider.overrideWith((ref) => 'la'),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      LanguageRegistry.instance.clear();
    });

    test('all words appear in learning queue when none are known', () async {
      // Arrange: No words marked as known
      final learningQueue = await container.read(learningQueueProvider.future);

      // Assert: All vocabulary words should appear
      expect(learningQueue.length, equals(mockVocabulary.length));
      expect(
        learningQueue.map((w) => w.id),
        containsAll(['amor', 'vita', 'terra', 'aqua', 'ignis']),
      );
    });

    test('known words are filtered from learning queue', () async {
      // Arrange: Mark some words as known
      mockWordProgress['la_amor'] = 'known';
      mockWordProgress['la_vita'] = 'known';

      // Create a new container with updated mock data
      final testContainer = ProviderContainer(
        overrides: [
          vocabularyProvider.overrideWith((ref) async => mockVocabulary),
          wordProgressProvider.overrideWith((ref) async => mockWordProgress),
          selectedLanguageProvider.overrideWith((ref) => 'la'),
        ],
      );

      try {
        // Act: Get the learning queue
        final learningQueue = await testContainer.read(
          learningQueueProvider.future,
        );

        // Assert: Known words should be filtered out
        expect(learningQueue.length, equals(3)); // 5 total - 2 known = 3
        expect(
          learningQueue.map((w) => w.id),
          containsAll(['terra', 'aqua', 'ignis']),
        );
        expect(learningQueue.map((w) => w.id), isNot(contains('amor')));
        expect(learningQueue.map((w) => w.id), isNot(contains('vita')));
      } finally {
        testContainer.dispose();
      }
    });

    test('mastered words are filtered from learning queue', () async {
      // Arrange: Mark some words as mastered
      mockWordProgress['la_terra'] = 'mastered';
      mockWordProgress['la_aqua'] = 'mastered';

      // Create a new container with updated mock data
      final testContainer = ProviderContainer(
        overrides: [
          vocabularyProvider.overrideWith((ref) async => mockVocabulary),
          wordProgressProvider.overrideWith((ref) async => mockWordProgress),
          selectedLanguageProvider.overrideWith((ref) => 'la'),
        ],
      );

      try {
        // Act: Get the learning queue
        final learningQueue = await testContainer.read(
          learningQueueProvider.future,
        );

        // Assert: Mastered words should be filtered out
        expect(learningQueue.length, equals(3)); // 5 total - 2 mastered = 3
        expect(
          learningQueue.map((w) => w.id),
          containsAll(['amor', 'vita', 'ignis']),
        );
        expect(learningQueue.map((w) => w.id), isNot(contains('terra')));
        expect(learningQueue.map((w) => w.id), isNot(contains('aqua')));
      } finally {
        testContainer.dispose();
      }
    });

    test('difficult words still appear in learning queue', () async {
      // Arrange: Mark some words as difficult
      mockWordProgress['la_amor'] = 'difficult';
      mockWordProgress['la_vita'] = 'difficult';

      // Create a new container with updated mock data
      final testContainer = ProviderContainer(
        overrides: [
          vocabularyProvider.overrideWith((ref) async => mockVocabulary),
          wordProgressProvider.overrideWith((ref) async => mockWordProgress),
          selectedLanguageProvider.overrideWith((ref) => 'la'),
        ],
      );

      try {
        // Act: Get the learning queue
        final learningQueue = await testContainer.read(
          learningQueueProvider.future,
        );

        // Assert: All words should still appear (difficult words need more practice)
        expect(learningQueue.length, equals(5));
        expect(
          learningQueue.map((w) => w.id),
          containsAll(['amor', 'vita', 'terra', 'aqua', 'ignis']),
        );
      } finally {
        testContainer.dispose();
      }
    });

    test('mixed progress statuses work correctly', () async {
      // Arrange: Mix of different statuses
      mockWordProgress['la_amor'] = 'known'; // Should be filtered
      mockWordProgress['la_vita'] = 'mastered'; // Should be filtered
      mockWordProgress['la_terra'] = 'difficult'; // Should appear
      mockWordProgress['la_aqua'] = 'reviewing'; // Should appear
      // ignis has no status (new word) - should appear

      // Create a new container with updated mock data
      final testContainer = ProviderContainer(
        overrides: [
          vocabularyProvider.overrideWith((ref) async => mockVocabulary),
          wordProgressProvider.overrideWith((ref) async => mockWordProgress),
          selectedLanguageProvider.overrideWith((ref) => 'la'),
        ],
      );

      try {
        // Act: Get the learning queue
        final learningQueue = await testContainer.read(
          learningQueueProvider.future,
        );

        // Assert: Only terra, aqua, and ignis should appear
        expect(learningQueue.length, equals(3));
        expect(
          learningQueue.map((w) => w.id),
          containsAll(['terra', 'aqua', 'ignis']),
        );
        expect(learningQueue.map((w) => w.id), isNot(contains('amor')));
        expect(learningQueue.map((w) => w.id), isNot(contains('vita')));
      } finally {
        testContainer.dispose();
      }
    });

    test('empty learning queue when all words are learned', () async {
      // Arrange: Mark all words as known
      for (final word in mockVocabulary) {
        mockWordProgress['la_${word.id}'] = 'known';
      }

      // Create a new container with updated mock data
      final testContainer = ProviderContainer(
        overrides: [
          vocabularyProvider.overrideWith((ref) async => mockVocabulary),
          wordProgressProvider.overrideWith((ref) async => mockWordProgress),
          selectedLanguageProvider.overrideWith((ref) => 'la'),
        ],
      );

      try {
        // Act: Get the learning queue
        final learningQueue = await testContainer.read(
          learningQueueProvider.future,
        );

        // Assert: Learning queue should be empty
        expect(learningQueue, isEmpty);
      } finally {
        testContainer.dispose();
      }
    });
  });
}
