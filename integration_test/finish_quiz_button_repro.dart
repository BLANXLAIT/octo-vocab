// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octo_vocab/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Finish Quiz Button Bug Reproduction', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets(
      'BUG REPRODUCTION: Finish Quiz button should be clickable',
      (tester) async {
        // Start app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Navigate to Quiz
        await tester.tap(find.text('Quiz'));
        await tester.pumpAndSettle();

        // Set to Quick (5) mode for faster testing
        final lengthSelector = find.byKey(const Key('quiz_length_selector'));
        if (lengthSelector.evaluate().isNotEmpty) {
          await tester.tap(lengthSelector);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Quick (5)'));
          await tester.pumpAndSettle();
        }

        print('=== BUG REPRODUCTION TEST ===');

        // Answer first 4 questions
        for (int i = 1; i <= 4; i++) {
          print('Question $i of 5');

          final answerButtons = find.byType(InkWell);
          await tester.tap(answerButtons.first);
          await tester.pump();

          final nextButton = find.text('Next Question');
          await tester.tap(nextButton);
          await tester.pump();
          await tester.pumpAndSettle();
        }

        // Question 5 - the critical test
        print('🎯 Question 5 of 5 - Testing Finish Quiz Button');

        // BEFORE selecting answer - button should be disabled
        final elevatedButtons = find.byType(ElevatedButton);
        expect(elevatedButtons, findsOneWidget, reason: 'Should find one ElevatedButton');

        final buttonBeforeAnswer = tester.widget<ElevatedButton>(elevatedButtons);
        expect(buttonBeforeAnswer.onPressed, isNull,
            reason: 'Button should be disabled before selecting answer');
        print('✅ Button correctly disabled before answer selection');

        // Check button text
        final buttonChild = buttonBeforeAnswer.child as Text;
        expect(buttonChild.data, equals('Finish Quiz'),
            reason: 'Button should show "Finish Quiz" on last question');
        print('✅ Button correctly shows "Finish Quiz" text');

        // Select answer
        print('🎯 Selecting answer...');
        final answerButtons = find.byType(InkWell);
        await tester.tap(answerButtons.first);
        await tester.pump();

        // AFTER selecting answer - button should be enabled (THIS IS THE BUG TEST)
        final elevatedButtonsAfter = find.byType(ElevatedButton);
        final buttonAfterAnswer = tester.widget<ElevatedButton>(elevatedButtonsAfter);

        if (buttonAfterAnswer.onPressed != null) {
          print('✅ SUCCESS: Button is enabled after answer selection');

          // Try to finish the quiz
          await tester.tap(elevatedButtonsAfter);
          await tester.pumpAndSettle();

          expect(find.text('Quiz Complete!'), findsOneWidget);
          print('✅ Quiz completed successfully');
        } else {
          print('❌ BUG CONFIRMED: Finish Quiz button is disabled after selecting answer!');

          // Let's debug what's happening
          print('Debug info:');
          print('  - Button text: ${(buttonAfterAnswer.child as Text).data}');
          print('  - Button enabled: ${buttonAfterAnswer.onPressed != null}');

          // This should fail the test to confirm the bug
          expect(buttonAfterAnswer.onPressed, isNotNull,
              reason: 'BUG: Finish Quiz button should be enabled after selecting answer on last question');
        }
      },
    );
  });
}