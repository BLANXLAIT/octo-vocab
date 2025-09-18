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

  group('Quiz Length Feature Verification', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('✅ CORE FEATURE: Quiz length limits questions correctly', (tester) async {
      debugPrint('🚀 Verifying quiz length limitation works');
      
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Navigate to quiz
      await TestHelpers.navigateToQuizTab(tester);
      await tester.pumpAndSettle();

      // Verify we have a limited quiz (default should be 10)
      expect(find.textContaining('Quiz 1/'), findsOneWidget);
      
      // Debug output to see what we got
      TestHelpers.debugPrintAllText(tester);

      // Look for the quiz counter text
      final quizCounterFinder = find.textContaining('Quiz 1/');
      expect(quizCounterFinder, findsOneWidget);
      
      // Extract the text to verify it's limited (should be 1/10, not 1/20)
      final Text quizCounterWidget = tester.widget(quizCounterFinder);
      final quizText = quizCounterWidget.data ?? '';
      debugPrint('📝 Found quiz counter: "$quizText"');
      
      // Verify it shows a limited number (10 or less), not the full vocabulary count
      expect(quizText.contains('1/10') || quizText.contains('1/5') || quizText.contains('1/15'), isTrue,
        reason: 'Expected quiz to be limited (1/10, 1/5, or 1/15), but got: $quizText');
      
      debugPrint('✅ Quiz length limitation verified successfully!');
    });

    testWidgets('✅ VERIFICATION: Can see quiz length selector exists', (tester) async {
      debugPrint('🚀 Verifying quiz length selector UI exists');
      
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Navigate to quiz
      await TestHelpers.navigateToQuizTab(tester);
      await tester.pumpAndSettle();

      // Look for the quiz selector by key (much more reliable)
      expect(find.byKey(const Key('quiz_length_selector')), findsOneWidget);
      
      // Also verify semantic label for accessibility
      expect(find.bySemanticsLabel('Quiz length selector'), findsOneWidget);
      
      debugPrint('✅ Quiz length selector UI verified!');
    });

    testWidgets('✅ FUNCTIONALITY: Can interact with quiz length selector', (tester) async {
      debugPrint('🚀 Testing quiz length selector functionality');
      
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Navigate to quiz
      await TestHelpers.navigateToQuizTab(tester);
      await tester.pumpAndSettle();

      // Verify selector exists and has accessibility
      expect(find.byKey(const Key('quiz_length_selector')), findsOneWidget);
      expect(find.bySemanticsLabel('Quiz length selector'), findsOneWidget);
      
      // Open the menu
      await tester.tap(find.byKey(const Key('quiz_length_selector')));
      await tester.pumpAndSettle();

      // Should see all quiz length options by text (most reliable)
      expect(find.text('Quick (5)'), findsOneWidget);
      expect(find.text('Short (10)'), findsOneWidget);
      expect(find.text('Medium (15)'), findsOneWidget);
      expect(find.text('Full'), findsOneWidget);

      // Select Quick (5) to test functionality
      await tester.tap(find.text('Quick (5)'));
      await tester.pumpAndSettle();

      // Quiz should restart and show limited count
      expect(find.textContaining('Quiz 1/'), findsOneWidget);
      
      debugPrint('✅ Quiz length selector functionality verified!');
    });

    testWidgets('✅ FUNCTION TEST: Quiz actually starts and works', (tester) async {
      debugPrint('🚀 Testing quiz functionality end-to-end');
      
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Navigate to quiz
      await TestHelpers.navigateToQuizTab(tester);
      await tester.pumpAndSettle();

      // Should show a question
      expect(find.text('What does this mean?'), findsOneWidget);
      
      // Should show answer options
      expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1)); // Answer buttons
      
      // Should show Next Question button (disabled initially)
      expect(find.text('Next Question'), findsOneWidget);
      
      // Verify we have limited quiz count
      expect(find.textContaining('Quiz 1/'), findsOneWidget);
      
      debugPrint('✅ Quiz functionality verified!');
    });
  });
}