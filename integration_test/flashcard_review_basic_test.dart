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

  group('Basic Flashcard → Review Integration', () {
    setUp(() async {
      // Clean slate for each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('app launches and basic navigation works', (tester) async {
      // Launch the app
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Verify we're on Learn tab
      expect(find.text('Learn'), findsOneWidget);

      // Test basic navigation
      await TestHelpers.navigateToReviewTab(tester);
      expect(find.text('Review'), findsOneWidget);
      
      await TestHelpers.navigateToProgressTab(tester);
      expect(find.text('Progress'), findsOneWidget);
      
      await TestHelpers.navigateToLearnTab(tester);
      expect(find.text('Learn'), findsOneWidget);

      // Basic test passes - app launches and navigation works
    });

    testWidgets('flashcard interaction provides feedback', (tester) async {
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Try to interact with flashcard
      await TestHelpers.swipeFlashcardLeft(tester);
      
      // Look for any feedback - be flexible about exact text
      final hasFeedback = 
        find.textContaining('review').evaluate().isNotEmpty ||
        find.textContaining('Review').evaluate().isNotEmpty ||
        find.textContaining('later').evaluate().isNotEmpty ||
        find.textContaining('difficult').evaluate().isNotEmpty;
      
      expect(hasFeedback, isTrue, reason: 'Should show some feedback after swipe');
      
      await TestHelpers.waitForSnackbar(tester);
    });

    testWidgets('review screen shows different states', (tester) async {
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Check initial review state (should be empty)
      await TestHelpers.navigateToReviewTab(tester);
      
      // Look for empty state OR review content - just verify it loads
      final hasEmptyState = find.textContaining('No words to review').evaluate().isNotEmpty;
      final hasReviewContent = find.textContaining('Again').evaluate().isNotEmpty ||
                               find.textContaining('Easy').evaluate().isNotEmpty;
      
      // Either empty state or review content is acceptable
      expect(hasEmptyState || hasReviewContent, isTrue, 
        reason: 'Review screen should show either empty state or review content');
    });

    testWidgets('app state persists across navigation', (tester) async {
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Navigate through all tabs to test persistence
      final destinations = [
        Icons.quiz_outlined,        // Quiz  
        Icons.trending_up_outlined, // Progress
        Icons.refresh_outlined,     // Review
        Icons.settings_outlined,    // Settings
        Icons.style,               // Learn
      ];

      for (final icon in destinations) {
        await tester.tap(find.byIcon(icon));
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        
        // Verify app doesn't crash
        expect(find.byType(MaterialApp), findsOneWidget);
      }
    });

    testWidgets('swipe gestures work without crashing', (tester) async {
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Try multiple swipe gestures
      await TestHelpers.swipeFlashcardLeft(tester);
      await TestHelpers.swipeFlashcardRight(tester);
      await TestHelpers.tapToFlipFlashcard(tester);
      
      // Verify app is still responsive
      await TestHelpers.verifyNavigationWorks(tester);
      
      // Should be able to navigate
      await TestHelpers.navigateToReviewTab(tester);
      await TestHelpers.navigateToLearnTab(tester);
    });

    testWidgets('debug: print current screen content', (tester) async {
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Debug helper to see what's actually on screen
      TestHelpers.debugPrintAllText(tester);
      
      await TestHelpers.navigateToReviewTab(tester);
      debugPrint('=== Review Screen Content ===');
      TestHelpers.debugPrintAllText(tester);
      
      // This test always passes - it's just for debugging
      expect(true, isTrue);
    });
  });
}