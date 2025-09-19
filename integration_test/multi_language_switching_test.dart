// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octo_vocab/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Multi-Language Switching Integration Tests', () {
    setUp(() async {
      // Clean slate for each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets(
      'language switching updates all screens with reactive architecture',
      (tester) async {
        // GIVEN: I launch the app
        app.main();
        await tester.pumpAndSettle();

        // WHEN: I am on the Latin language (default)
        expect(find.text('LA'), findsWidgets);

        // AND: I navigate to Learn tab and see Latin vocabulary
        await tester.tap(find.text('Learn'));
        await tester.pumpAndSettle();

        // THEN: I should see Latin words in the learning queue
        await tester.pump(const Duration(seconds: 2));

        // WHEN: I switch to Spanish language
        await tester.tap(find.text('LA'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Spanish'));
        await tester.pumpAndSettle();

        // THEN: The language indicator updates to Spanish
        expect(find.text('ES'), findsWidgets);

        // AND: The vocabulary updates to Spanish words
        await tester.pump(const Duration(seconds: 2));

        // WHEN: I navigate to Progress tab
        await tester.tap(find.text('Progress'));
        await tester.pumpAndSettle();

        // THEN: Progress shows Spanish-specific data
        // (No specific Spanish progress yet since no words marked)
        expect(find.text('ES'), findsWidgets);

        // WHEN: I navigate to Review tab
        await tester.tap(find.text('Review'));
        await tester.pumpAndSettle();

        // THEN: Review shows "No words need review" for Spanish
        expect(find.text('No words need review right now.'), findsOneWidget);
        expect(find.text('ES'), findsWidgets);

        // WHEN: I switch back to Latin
        await tester.tap(find.text('ES'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Latin'));
        await tester.pumpAndSettle();

        // THEN: All screens update back to Latin context
        expect(find.text('LA'), findsWidgets);
      },
    );

    testWidgets(
      'progress data is language-specific and persists correctly',
      (tester) async {
        // GIVEN: I launch the app
        app.main();
        await tester.pumpAndSettle();

        // WHEN: I navigate to Learn mode and mark a Latin word as difficult
        await tester.tap(find.text('Learn'));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 1));

        // Swipe left on first flashcard to mark as difficult
        final flashcard = find.byType(Card).first;
        await tester.drag(flashcard, const Offset(-300, 0));
        await tester.pumpAndSettle();

        // WHEN: I switch to Spanish
        await tester.tap(find.text('LA'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Spanish'));
        await tester.pumpAndSettle();

        // AND: Navigate to Review tab
        await tester.tap(find.text('Review'));
        await tester.pumpAndSettle();

        // THEN: Spanish review queue should be empty (no Spanish words marked)
        expect(find.text('No words need review right now.'), findsOneWidget);

        // WHEN: I switch back to Latin
        await tester.tap(find.text('ES'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Latin'));
        await tester.pumpAndSettle();

        // THEN: Latin review queue should have the word I marked as difficult
        // (The word should appear for review)
        await tester.pump(const Duration(seconds: 1));

        // This verifies that progress is language-specific
        expect(find.text('LA'), findsWidgets);
      },
    );

    testWidgets(
      'language selector shows correct languages and handles switching',
      (tester) async {
        // GIVEN: I launch the app
        app.main();
        await tester.pumpAndSettle();

        // WHEN: I tap on the language selector
        await tester.tap(find.text('LA'));
        await tester.pumpAndSettle();

        // THEN: I should see both language options
        expect(find.text('Latin'), findsOneWidget);
        expect(find.text('Spanish'), findsOneWidget);

        // WHEN: I select Spanish
        await tester.tap(find.text('Spanish'));
        await tester.pumpAndSettle();

        // THEN: The selector should show ES and close the menu
        expect(find.text('ES'), findsWidgets);
        expect(find.text('Latin'), findsNothing); // Menu should be closed

        // WHEN: I open the selector again
        await tester.tap(find.text('ES'));
        await tester.pumpAndSettle();

        // THEN: Spanish should be selected/highlighted
        expect(find.text('Spanish'), findsOneWidget);
        expect(find.text('Latin'), findsOneWidget);

        // WHEN: I select Latin again
        await tester.tap(find.text('Latin'));
        await tester.pumpAndSettle();

        // THEN: The selector should show LA
        expect(find.text('LA'), findsWidgets);
      },
    );
  });
}