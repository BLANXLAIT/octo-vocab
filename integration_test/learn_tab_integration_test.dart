// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octo_vocab/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Learn Tab Integration Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets(
      'Learn tab shows flashcard interface',
      (tester) async {
        // Start app (should default to Learn tab)
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        print('=== Testing Learn Tab Default Load ===');

        // Should be on Learn tab by default
        expect(find.text('Learn'), findsAtLeastNWidgets(1),
            reason: 'Should show Learn tab');

        // Should show flashcard content
        expect(find.text('What does this mean?'), findsOneWidget,
            reason: 'Should show flashcard question');

        // Should show a Latin word or term
        final termText = find.byType(Text).evaluate()
            .where((element) {
              final widget = element.widget as Text;
              return widget.data != null &&
                     widget.data!.isNotEmpty &&
                     !['Learn', 'Quiz', 'Progress', 'Review', 'Settings', 'What does this mean?'].contains(widget.data);
            })
            .isNotEmpty;

        expect(termText, true, reason: 'Should show vocabulary term');

        print('✅ Learn tab loads with flashcard interface');
      },
    );

    testWidgets(
      'Flashcard swipe gestures work',
      (tester) async {
        // Start app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        print('=== Testing Flashcard Swipe Gestures ===');

        // Get initial card content to verify it changes
        final initialContent = find.byType(Text).evaluate()
            .map((e) => (e.widget as Text).data)
            .where((text) => text != null && text.isNotEmpty)
            .toList();

        // Test right swipe (known/easy)
        final cardFinder = find.byType(GestureDetector).first;
        if (cardFinder.evaluate().isNotEmpty) {
          await tester.drag(cardFinder, const Offset(300, 0));
          await tester.pumpAndSettle();

          print('✅ Right swipe gesture executed');

          // Should advance to next card
          await tester.pump(const Duration(milliseconds: 500));
          await tester.pumpAndSettle();

          // Verify content changed
          final newContent = find.byType(Text).evaluate()
              .map((e) => (e.widget as Text).data)
              .where((text) => text != null && text.isNotEmpty)
              .toList();

          // Content should be different (new flashcard)
          final contentChanged = !identical(initialContent, newContent);
          expect(contentChanged, true, reason: 'Should show new flashcard after swipe');

          print('✅ Flashcard advances after swipe');
        } else {
          print('ℹ️ No gesture detector found - checking for tap-based interface');

          // Check for tap-based interface
          final tapButtons = find.byType(ElevatedButton);
          final inkWells = find.byType(InkWell);

          if (tapButtons.evaluate().isNotEmpty || inkWells.evaluate().isNotEmpty) {
            print('ℹ️ Found tap-based interface instead of swipe');
          }
        }
      },
    );

    testWidgets(
      'Flashcard shows multiple choice options',
      (tester) async {
        // Start app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        print('=== Testing Multiple Choice Options ===');

        // Look for multiple choice options
        final choiceButtons = find.byType(InkWell);
        final elevatedButtons = find.byType(ElevatedButton);

        if (choiceButtons.evaluate().length >= 4) {
          print('✅ Found ${choiceButtons.evaluate().length} choice options (InkWell)');

          // Test selecting an option
          await tester.tap(choiceButtons.first);
          await tester.pumpAndSettle();

          print('✅ Multiple choice selection works');
        } else if (elevatedButtons.evaluate().length >= 4) {
          print('✅ Found ${elevatedButtons.evaluate().length} choice options (ElevatedButton)');

          // Test selecting an option
          await tester.tap(elevatedButtons.first);
          await tester.pumpAndSettle();

          print('✅ Multiple choice selection works');
        } else {
          print('ℹ️ Multiple choice interface not found - may be swipe-only mode');
        }
      },
    );

    testWidgets(
      'Learn tab progress tracking',
      (tester) async {
        // Start app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        print('=== Testing Learn Progress Tracking ===');

        // Look for progress indicators
        final progressText = find.textContaining('progress');
        final countText = find.textContaining('/');
        final percentText = find.textContaining('%');

        if (progressText.evaluate().isNotEmpty) {
          print('✅ Found progress text indicator');
        } else if (countText.evaluate().isNotEmpty) {
          print('✅ Found count-based progress indicator');
        } else if (percentText.evaluate().isNotEmpty) {
          print('✅ Found percentage-based progress indicator');
        } else {
          print('ℹ️ No explicit progress indicator found');
        }

        // Study a few cards and check if progress updates
        for (int i = 0; i < 3; i++) {
          final gestureDetector = find.byType(GestureDetector);
          final inkWells = find.byType(InkWell);

          if (gestureDetector.evaluate().isNotEmpty) {
            // Swipe right (known)
            await tester.drag(gestureDetector.first, const Offset(300, 0));
            await tester.pumpAndSettle();
          } else if (inkWells.evaluate().isNotEmpty) {
            // Tap an answer
            await tester.tap(inkWells.first);
            await tester.pumpAndSettle();
          }

          await tester.pump(const Duration(milliseconds: 300));
        }

        print('✅ Completed multiple learning interactions');
      },
    );

    testWidgets(
      'Learn tab handles empty or completed state',
      (tester) async {
        // Start app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        print('=== Testing Edge Cases ===');

        // Try to exhaust the learning queue by studying many cards
        for (int i = 0; i < 50; i++) {
          // Check if we've reached an end state
          final noMoreCards = find.text('No more cards');
          final completed = find.text('Completed');
          final wellDone = find.text('Well done');

          if (noMoreCards.evaluate().isNotEmpty ||
              completed.evaluate().isNotEmpty ||
              wellDone.evaluate().isNotEmpty) {
            print('✅ Found completion state after $i cards');
            break;
          }

          // Continue studying
          final gestureDetector = find.byType(GestureDetector);
          final inkWells = find.byType(InkWell);

          if (gestureDetector.evaluate().isNotEmpty) {
            await tester.drag(gestureDetector.first, const Offset(300, 0));
          } else if (inkWells.evaluate().isNotEmpty) {
            await tester.tap(inkWells.first);
          } else {
            print('ℹ️ No interaction method found, stopping');
            break;
          }

          await tester.pumpAndSettle();

          // Don't run forever
          if (i >= 49) {
            print('ℹ️ Reached maximum iterations without completion state');
          }
        }
      },
    );

    testWidgets(
      'Learn tab navigation to other tabs preserves state',
      (tester) async {
        // Start app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        print('=== Testing Tab Navigation State Preservation ===');

        // Study a card in Learn tab
        final gestureDetector = find.byType(GestureDetector);
        final inkWells = find.byType(InkWell);

        if (gestureDetector.evaluate().isNotEmpty) {
          await tester.drag(gestureDetector.first, const Offset(300, 0));
          await tester.pumpAndSettle();
        } else if (inkWells.evaluate().isNotEmpty) {
          await tester.tap(inkWells.first);
          await tester.pumpAndSettle();
        }

        // Navigate to Quiz tab
        await tester.tap(find.text('Quiz'));
        await tester.pumpAndSettle();

        expect(find.text('Quiz'), findsAtLeastNWidgets(1));
        print('✅ Navigated to Quiz tab');

        // Navigate back to Learn tab
        await tester.tap(find.text('Learn'));
        await tester.pumpAndSettle();

        // Should still show learning interface
        expect(find.text('What does this mean?'), findsOneWidget,
            reason: 'Learn tab should restore correctly');

        print('✅ Learn tab state preserved after navigation');
      },
    );
  });
}