// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octo_vocab/main.dart' as app;
import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Quiz → Progress Integration', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('✅ INTEGRATION: Completed quiz appears in progress screen', (
      tester,
    ) async {
      debugPrint('🚀 Testing quiz → progress integration');

      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Step 1: Check initial progress state (should be empty)
      await TestHelpers.navigateToProgressTab(tester);
      await tester.pumpAndSettle();

      // Should show "no quiz results yet"
      expect(find.textContaining('No quiz results yet'), findsOneWidget);
      debugPrint('✅ Initial state: No quiz results found');

      // Step 2: Take a complete quiz
      await TestHelpers.navigateToQuizTab(tester);
      await tester.pumpAndSettle();

      // Set quiz length to Quick (5) for faster testing
      await tester.tap(find.byKey(const Key('quiz_length_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quick (5)'));
      await tester.pumpAndSettle();

      // Complete all 5 questions
      for (int i = 0; i < 5; i++) {
        debugPrint('📝 Answering question ${i + 1}/5');

        // Wait for question to load
        await tester.pumpAndSettle();

        // Should see a question
        expect(find.text('What does this mean?'), findsOneWidget);

        // Tap the first answer (doesn't matter if it's right or wrong for this test)
        final answerButtons = find.byType(ElevatedButton);
        await tester.tap(answerButtons.first);
        await tester.pumpAndSettle();

        // Tap Next Question (or Finish Quiz on last question)
        if (i < 4) {
          await tester.tap(find.text('Next Question'));
        } else {
          await tester.tap(find.text('Finish Quiz'));
        }
        await tester.pumpAndSettle();
      }

      // Should now be on results screen
      expect(find.textContaining('Quiz Complete'), findsOneWidget);
      debugPrint('✅ Quiz completed successfully');

      // Step 3: Check that results appear in progress screen
      await TestHelpers.navigateToProgressTab(tester);
      await tester.pumpAndSettle();

      // Should NO LONGER show "no quiz results yet"
      expect(find.textContaining('No quiz results yet'), findsNothing);

      // Should show quiz performance section with data
      expect(find.textContaining('Quiz Performance'), findsOneWidget);
      expect(find.textContaining('Quizzes Taken'), findsOneWidget);
      expect(
        find.textContaining('1'),
        findsWidgets,
      ); // Should show 1 quiz taken

      debugPrint(
        '✅ Quiz results successfully integrated with progress screen!',
      );
    });

    testWidgets('✅ MULTIPLE QUIZZES: Multiple quizzes accumulate in progress', (
      tester,
    ) async {
      debugPrint('🚀 Testing multiple quiz accumulation');

      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Take two short quizzes
      for (int quiz = 1; quiz <= 2; quiz++) {
        debugPrint('📚 Taking quiz $quiz');

        await TestHelpers.navigateToQuizTab(tester);
        await tester.pumpAndSettle();

        // Set to Quick (5) questions
        await tester.tap(find.byKey(const Key('quiz_length_selector')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Quick (5)'));
        await tester.pumpAndSettle();

        // Complete the quiz quickly
        for (int q = 0; q < 5; q++) {
          await tester.pumpAndSettle();
          final answerButtons = find.byType(ElevatedButton);
          await tester.tap(answerButtons.first);
          await tester.pumpAndSettle();

          if (q < 4) {
            await tester.tap(find.text('Next Question'));
          } else {
            await tester.tap(find.text('Finish Quiz'));
          }
          await tester.pumpAndSettle();
        }

        debugPrint('✅ Quiz $quiz completed');
      }

      // Check progress shows 2 quizzes
      await TestHelpers.navigateToProgressTab(tester);
      await tester.pumpAndSettle();

      expect(find.textContaining('Quiz Performance'), findsOneWidget);
      expect(
        find.textContaining('2'),
        findsWidgets,
      ); // Should show 2 quizzes taken

      debugPrint('✅ Multiple quiz accumulation verified!');
    });
  });
}
