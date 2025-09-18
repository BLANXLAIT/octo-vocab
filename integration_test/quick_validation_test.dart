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

  group('Quick Validation Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('✅ CORE FLOW: Flashcard left swipe → Review queue works', (tester) async {
      debugPrint('🚀 Testing core flashcard → review flow');
      
      // Launch app
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Swipe left (mark as difficult)
      await TestHelpers.swipeFlashcardLeft(tester);
      TestHelpers.verifyFeedbackMessage('Will review later');
      await TestHelpers.waitForSnackbar(tester);

      // Navigate to review
      await TestHelpers.navigateToReviewTab(tester);
      
      // Verify word is in review queue
      TestHelpers.verifyReviewQueueHasWords();
      
      debugPrint('✅ Core flow test passed!');
    });

    testWidgets('✅ EMPTY STATE: Review shows helpful message when empty', (tester) async {
      debugPrint('🚀 Testing empty review state');
      
      app.main();
      await TestHelpers.waitForAppLoad(tester);
      
      // Go directly to review without marking any words
      await TestHelpers.navigateToReviewTab(tester);
      
      // Should show empty state
      TestHelpers.verifyEmptyReviewState();
      
      debugPrint('✅ Empty state test passed!');
    });

    testWidgets('✅ NAVIGATION: Text-based navigation works', (tester) async {
      debugPrint('🚀 Testing navigation between tabs');
      
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Test all navigation with text labels
      await TestHelpers.navigateToQuizTab(tester);
      expect(find.text('Quiz'), findsOneWidget);
      
      await TestHelpers.navigateToProgressTab(tester);  
      expect(find.text('Progress'), findsOneWidget);
      
      await TestHelpers.navigateToReviewTab(tester);
      expect(find.text('Review'), findsOneWidget);
      
      await TestHelpers.navigateToSettingsTab(tester);
      expect(find.text('Settings'), findsOneWidget);
      
      await TestHelpers.navigateToLearnTab(tester);
      expect(find.text('Learn'), findsOneWidget);
      
      debugPrint('✅ Navigation test passed!');
    });
  });
}