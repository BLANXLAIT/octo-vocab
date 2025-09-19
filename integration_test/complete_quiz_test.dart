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

  group('Complete Quiz Test', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('Complete 5-question quiz and check progress', (tester) async {
      debugPrint('🚀 Testing complete quiz flow');

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

      // Complete all 5 questions
      for (int i = 1; i <= 5; i++) {
        debugPrint('📝 Answering question $i');

        // Answer the question
        final answerButtons = find.byType(InkWell);
        await tester.tap(answerButtons.first);
        await tester.pump();

        // Click Next Question (or Finish Quiz on last question)
        final nextButton = find.text(i == 5 ? 'Finish Quiz' : 'Next Question');
        await tester.tap(nextButton);
        await tester.pump();

        if (i < 5) {
          await tester.pumpAndSettle();
        }
      }

      debugPrint('🏁 Quiz should be complete - checking results screen');
      await tester.pumpAndSettle();

      // Should now be on quiz results screen
      expect(find.text('Quiz Complete!'), findsOneWidget);

      debugPrint('✅ Quiz completed - now checking Progress tab');

      // Navigate to Progress tab
      await TestHelpers.navigateToProgressTab(tester);
      await tester.pumpAndSettle();

      // Check if quiz results are saved
      debugPrint('📊 Checking progress screen for quiz results');
      TestHelpers.debugPrintAllText(tester);

      // Should not see "no quiz results yet"
      expect(find.text('No quiz results yet'), findsNothing);

      debugPrint('✅ Test complete');
    });
  });
}
