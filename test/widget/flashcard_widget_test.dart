import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octo_vocab/core/language/language_registry.dart';
import 'package:octo_vocab/core/language/models/vocabulary_item.dart';
import 'package:octo_vocab/core/language/plugins/latin_plugin.dart';
import 'package:octo_vocab/features/flashcards/flashcards_screen.dart';

void main() {
  group('FlashcardWidget Tests', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      LanguageRegistry.instance.clear();
      LanguageRegistry.instance.register(LatinPlugin());
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('displays front content correctly', (tester) async {
      const testVocabItem = VocabularyItem(
        id: 'test_1',
        term: 'amare',
        translation: 'to love',
        partOfSpeech: 'verb',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isCardFlippedProvider.overrideWith((ref) => false),
            currentLanguagePluginProvider.overrideWith((ref) => LatinPlugin()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: FlashcardWidget(
                vocabularyItem: testVocabItem,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Verify front content
      expect(
        find.text('amare'),
        findsOneWidget,
      ); // Term as-is (Latin plugin doesn't change it)
      expect(find.text('Tap to reveal meaning'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget); // Latin icon
      expect(find.text('to love'), findsNothing); // Hidden on front

      // Verify swipe instructions
      expect(find.byIcon(Icons.swipe_left), findsOneWidget);
      expect(find.byIcon(Icons.swipe_right), findsOneWidget);
      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text('Known'), findsOneWidget);
    });

    testWidgets('displays back content when flipped', (tester) async {
      const testVocabItem = VocabularyItem(
        id: 'test_1',
        term: 'amare',
        translation: 'to love',
        partOfSpeech: 'verb',
        exampleTerm: 'Amo te',
        exampleTranslation: 'I love you',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isCardFlippedProvider.overrideWith((ref) => true),
            currentLanguagePluginProvider.overrideWith((ref) => LatinPlugin()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: FlashcardWidget(
                vocabularyItem: testVocabItem,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Verify back content
      expect(find.text('to love'), findsOneWidget); // Translation visible
      expect(find.byIcon(Icons.lightbulb), findsOneWidget); // Back icon
      expect(
        find.text('Tap to reveal meaning'),
        findsNothing,
      ); // Hidden on back

      // Verify example content - Latin plugin formats as: 'term — "translation"'
      expect(find.textContaining('Amo te'), findsOneWidget);
      expect(find.textContaining('"I love you"'), findsOneWidget);

      // Swipe instructions still visible
      expect(find.text('Unknown'), findsOneWidget);
      expect(find.text('Known'), findsOneWidget);
    });

    testWidgets('handles tap to flip card', (tester) async {
      bool onTapCalled = false;
      const testVocabItem = VocabularyItem(
        id: 'test_1',
        term: 'amare',
        translation: 'to love',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isCardFlippedProvider.overrideWith((ref) => false),
            currentLanguagePluginProvider.overrideWith((ref) => LatinPlugin()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: FlashcardWidget(
                vocabularyItem: testVocabItem,
                onTap: () => onTapCalled = true,
              ),
            ),
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(FlashcardWidget));
      await tester.pump();

      expect(onTapCalled, isTrue);
    });

    testWidgets('shows proper styling and colors', (tester) async {
      const testVocabItem = VocabularyItem(
        id: 'test_1',
        term: 'amare',
        translation: 'to love',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isCardFlippedProvider.overrideWith((ref) => false),
            currentLanguagePluginProvider.overrideWith((ref) => LatinPlugin()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: FlashcardWidget(
                vocabularyItem: testVocabItem,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Verify card structure
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(AnimatedSwitcher), findsOneWidget);

      // Verify gradient container exists (get the first decorated container)
      final containers = find.descendant(
        of: find.byType(Card),
        matching: find.byType(Container),
      );
      expect(containers, findsWidgets);

      final decoratedContainers = tester
          .widgetList<Container>(containers)
          .where((c) => c.decoration != null);
      expect(decoratedContainers.isNotEmpty, isTrue);

      final container = decoratedContainers.first;
      expect(container.decoration, isA<BoxDecoration>());

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());
      expect(decoration.borderRadius, isNotNull);
      expect(decoration.border, isNotNull);
    });

    testWidgets('handles null language plugin gracefully', (tester) async {
      const testVocabItem = VocabularyItem(
        id: 'test_1',
        term: 'amare',
        translation: 'to love',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isCardFlippedProvider.overrideWith((ref) => false),
            currentLanguagePluginProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: FlashcardWidget(
                vocabularyItem: testVocabItem,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Should show fallback content
      expect(find.text('No language plugin available'), findsOneWidget);
    });

    testWidgets('displays vocabulary without examples correctly', (
      tester,
    ) async {
      const testVocabItem = VocabularyItem(
        id: 'test_1',
        term: 'amare',
        translation: 'to love',
        partOfSpeech: 'verb',
        // No examples
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isCardFlippedProvider.overrideWith((ref) => true),
            currentLanguagePluginProvider.overrideWith((ref) => LatinPlugin()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: FlashcardWidget(
                vocabularyItem: testVocabItem,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Back should show translation but no example container
      expect(find.text('to love'), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb), findsOneWidget);

      // No example container should be present
      final containers = tester.widgetList<Container>(find.byType(Container));
      final exampleContainers = containers.where((container) {
        final decoration = container.decoration as BoxDecoration?;
        return decoration?.color?.toString().contains('secondaryContainer') ??
            false;
      });
      expect(exampleContainers.isEmpty, isTrue);
    });

    testWidgets('displays correct swipe instruction colors', (tester) async {
      const testVocabItem = VocabularyItem(
        id: 'test_1',
        term: 'amare',
        translation: 'to love',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isCardFlippedProvider.overrideWith((ref) => false),
            currentLanguagePluginProvider.overrideWith((ref) => LatinPlugin()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: FlashcardWidget(
                vocabularyItem: testVocabItem,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Find swipe instruction icons
      final leftSwipeIcon = tester.widget<Icon>(find.byIcon(Icons.swipe_left));
      final rightSwipeIcon = tester.widget<Icon>(
        find.byIcon(Icons.swipe_right),
      );

      // Verify colors match the UI design (check for red-ish and green-ish colors)
      expect(
        leftSwipeIcon.color?.red,
        greaterThan(150),
      ); // Red component for unknown
      expect(
        rightSwipeIcon.color?.green,
        greaterThan(150),
      ); // Green component for known
    });
  });
}
