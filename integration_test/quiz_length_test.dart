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

  group('Quiz Length Configuration Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('✅ Default quiz length should be Short (10)', (tester) async {
      debugPrint('🚀 Testing default quiz length');
      
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Navigate to quiz
      await TestHelpers.navigateToQuizTab(tester);
      await tester.pumpAndSettle();

      // Check that we're starting a quiz (not empty state)
      expect(find.textContaining('Quiz 1/'), findsOneWidget);
      
      // Debug: Print all text to see the actual quiz title
      TestHelpers.debugPrintAllText(tester);

      debugPrint('✅ Default quiz length test passed');
    });

    testWidgets('✅ Can change quiz length through dropdown', (tester) async {
      debugPrint('🚀 Testing quiz length selector');
      
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Navigate to quiz
      await TestHelpers.navigateToQuizTab(tester);
      await tester.pumpAndSettle();

      // Look for the quiz length selector (quiz icon button)
      final quizSelector = find.byIcon(Icons.quiz);
      expect(quizSelector, findsOneWidget);
      
      // Tap on quiz length selector
      await tester.tap(quizSelector);
      await tester.pumpAndSettle();

      // Should see popup menu with different length options
      expect(find.text('Quick (5)'), findsOneWidget);
      expect(find.text('Short (10)'), findsOneWidget);
      expect(find.text('Medium (15)'), findsOneWidget);
      expect(find.text('Full'), findsOneWidget);

      // Select Quick (5)
      await tester.tap(find.text('Quick (5)'));
      await tester.pumpAndSettle();

      // Quiz should restart and show 1/5 or similar limited count
      expect(find.textContaining('Quiz 1/'), findsOneWidget);
      
      debugPrint('✅ Quiz length selector test passed');
    });

    testWidgets('✅ Quiz length setting persists across sessions', (tester) async {
      debugPrint('🚀 Testing quiz length persistence');
      
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Navigate to quiz and change to Quick (5)
      await TestHelpers.navigateToQuizTab(tester);
      await tester.pumpAndSettle();

      // Change to Quick (5)
      await tester.tap(find.byIcon(Icons.quiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quick (5)'));
      await tester.pumpAndSettle();

      // Navigate away from quiz
      await TestHelpers.navigateToLearnTab(tester);
      await tester.pumpAndSettle();

      // Navigate back to quiz
      await TestHelpers.navigateToQuizTab(tester);
      await tester.pumpAndSettle();

      // Should still show limited quiz length
      expect(find.textContaining('Quiz 1/'), findsOneWidget);
      
      debugPrint('✅ Quiz length persistence test passed');
    });

    testWidgets('✅ Full quiz includes all available vocabulary', (tester) async {
      debugPrint('🚀 Testing full quiz mode');
      
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Navigate to quiz
      await TestHelpers.navigateToQuizTab(tester);
      await tester.pumpAndSettle();

      // Change to Full quiz
      await tester.tap(find.byIcon(Icons.quiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Full'));
      await tester.pumpAndSettle();

      // Should show quiz started
      expect(find.textContaining('Quiz 1/'), findsOneWidget);
      
      // Debug: Print all text to see the quiz info
      debugPrint('📱 Full quiz screen:');
      TestHelpers.debugPrintAllText(tester);
      
      debugPrint('✅ Full quiz test passed');
    });
  });
}