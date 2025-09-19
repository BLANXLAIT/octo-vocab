// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octo_vocab/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Quiz Progress Display Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets(
      'Quiz results should appear in Progress tab after completing quiz',
      (tester) async {
        // Start app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        print('=== Testing Quiz Results in Progress Tab ===');

        // First, check Progress tab shows "No quiz results yet"
        await tester.tap(find.text('Progress'));
        await tester.pumpAndSettle();

        expect(find.text('No quiz results yet'), findsOneWidget,
            reason: 'Should show no quiz results initially');
        print('✅ Initially shows "No quiz results yet"');

        // Navigate to Quiz and take a quiz
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

        print('🎯 Taking a 5-question quiz...');

        // Complete the quiz
        for (int i = 1; i <= 5; i++) {
          print('  Answering question $i of 5');

          // Select answer
          final answerButtons = find.byType(InkWell);
          await tester.tap(answerButtons.first);
          await tester.pump();

          // Tap proceed button
          final proceedButton = find.byType(ElevatedButton);
          await tester.tap(proceedButton);
          await tester.pump();

          if (i < 5) {
            await tester.pumpAndSettle();
          }
        }

        // Should be on quiz complete screen
        await tester.pumpAndSettle();
        expect(find.text('Quiz Complete!'), findsOneWidget);
        print('✅ Quiz completed successfully');

        // Navigate back to Progress tab
        print('🎯 Checking Progress tab for quiz results...');
        await tester.tap(find.text('Progress'));
        await tester.pumpAndSettle();

        // Should now show quiz performance instead of "No quiz results yet"
        expect(find.text('Quiz Performance'), findsOneWidget,
            reason: 'Should show Quiz Performance section');

        expect(find.text('No quiz results yet'), findsNothing,
            reason: 'Should no longer show "No quiz results yet"');

        // Should show quiz stats
        expect(find.text('Quizzes Taken'), findsOneWidget,
            reason: 'Should show Quizzes Taken stat');

        expect(find.text('Best Score'), findsOneWidget,
            reason: 'Should show Best Score stat');

        expect(find.text('Average'), findsOneWidget,
            reason: 'Should show Average stat');

        print('✅ Quiz Performance section appears with stats');

        // The actual numbers might vary, but we should see some numeric values
        final statColumns = find.byIcon(Icons.quiz);
        expect(statColumns, findsAtLeastNWidgets(1),
            reason: 'Should find quiz icons in stats');

        print('✅ Quiz results successfully displayed in Progress tab');
      },
    );

    testWidgets(
      'Multiple quizzes should update progress statistics',
      (tester) async {
        // Start app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));

        print('=== Testing Multiple Quiz Statistics ===');

        // Take two quizzes to test statistics
        for (int quizNumber = 1; quizNumber <= 2; quizNumber++) {
          print('🎯 Taking quiz $quizNumber...');

          // Navigate to Quiz
          await tester.tap(find.text('Quiz'));
          await tester.pumpAndSettle();

          // Use Quick mode
          final lengthSelector = find.byKey(const Key('quiz_length_selector'));
          if (lengthSelector.evaluate().isNotEmpty) {
            await tester.tap(lengthSelector);
            await tester.pumpAndSettle();
            await tester.tap(find.text('Quick (5)'));
            await tester.pumpAndSettle();
          }

          // Complete the quiz quickly
          for (int i = 1; i <= 5; i++) {
            final answerButtons = find.byType(InkWell);
            await tester.tap(answerButtons.first);
            await tester.pump();
            final proceedButton = find.byType(ElevatedButton);
            await tester.tap(proceedButton);
            await tester.pump();
            if (i < 5) await tester.pumpAndSettle();
          }

          await tester.pumpAndSettle();
          expect(find.text('Quiz Complete!'), findsOneWidget);
          print('  ✅ Quiz $quizNumber completed');
        }

        // Check Progress tab shows updated statistics
        await tester.tap(find.text('Progress'));
        await tester.pumpAndSettle();

        expect(find.text('Quiz Performance'), findsOneWidget,
            reason: 'Should show Quiz Performance section');

        // Should show at least 2 quizzes taken
        expect(find.text('Quizzes Taken'), findsOneWidget);
        expect(find.text('Best Score'), findsOneWidget);
        expect(find.text('Average'), findsOneWidget);

        print('✅ Multiple quiz statistics displayed correctly');
      },
    );
  });
}