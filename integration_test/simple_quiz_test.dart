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

  group('Simple Quiz Test', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('Answer selection enables Next button', (tester) async {
      debugPrint('🚀 Simple quiz test');
      
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      await TestHelpers.navigateToQuizTab(tester);
      await tester.pumpAndSettle();

      // Set to Quick (5) mode
      debugPrint('⚙️ Setting quiz to Quick (5) mode');
      await tester.tap(find.byKey(const Key('quiz_length_selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quick (5)'));
      await tester.pumpAndSettle();

      debugPrint('📝 Initial state - button should be disabled');
      
      // Find Next Question button and verify it's disabled
      final nextButton = find.text('Next Question');
      expect(nextButton, findsOneWidget);
      
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(button.onPressed, isNull); // Should be null (disabled)

      // Answer the question
      final answerButtons = find.byType(InkWell);
      expect(answerButtons.evaluate().isNotEmpty, isTrue);
      
      debugPrint('👆 Tapping answer...');
      await tester.tap(answerButtons.first);
      await tester.pump(); // Just pump once, don't settle

      debugPrint('✅ Test completed - checking if button is enabled now');
      
      // Check if button is now enabled
      final buttonAfter = tester.widget<ElevatedButton>(find.byType(ElevatedButton).first);
      expect(buttonAfter.onPressed, isNotNull); // Should be enabled now

      debugPrint('✅ Success - button is now enabled!');
      
      // Now test clicking Next Question
      debugPrint('🔄 Clicking Next Question...');
      await tester.tap(nextButton);
      await tester.pump(); // Just pump once
      
      debugPrint('✅ Next button clicked successfully!');
      
      // Test second question
      await tester.pumpAndSettle();
      debugPrint('📝 Should now be on question 2');
      
      // Answer second question
      final answerButtons2 = find.byType(InkWell);
      await tester.tap(answerButtons2.first);
      await tester.pump();
      
      // Click Next again
      debugPrint('🔄 Clicking Next Question for question 2...');
      await tester.tap(nextButton);
      await tester.pump();
      
      debugPrint('✅ Successfully advanced through 2 questions!');
    });
  });
}