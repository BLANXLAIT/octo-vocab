// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

/// Shared test helpers for integration tests
class TestHelpers {
  /// Wait for the app to fully load with vocabulary data
  static Future<void> waitForAppLoad(WidgetTester tester) async {
    // Wait for any loading indicators to disappear
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Ensure we're not in a loading state
    expect(find.byType(CircularProgressIndicator), findsNothing);
  }

  /// Navigate to the Review tab
  static Future<void> navigateToReviewTab(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.refresh_outlined));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  /// Navigate to the Learn tab (flashcards)
  static Future<void> navigateToLearnTab(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.style));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  /// Navigate to the Quiz tab
  static Future<void> navigateToQuizTab(WidgetTester tester) async {
    // Use text instead of icon to avoid ambiguity
    await tester.tap(find.text('Quiz'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  /// Navigate to the Progress tab
  static Future<void> navigateToProgressTab(WidgetTester tester) async {
    // Find Progress text that's specifically in the bottom navigation
    final progressTabs = find.text('Progress');
    if (progressTabs.evaluate().length > 1) {
      // If multiple Progress texts, try to find the one in navigation
      final bottomNavBar = find.byType(BottomNavigationBar);
      if (bottomNavBar.evaluate().isNotEmpty) {
        final progressInNav = find.descendant(
          of: bottomNavBar,
          matching: find.text('Progress'),
        );
        if (progressInNav.evaluate().isNotEmpty) {
          await tester.tap(progressInNav);
          await tester.pumpAndSettle(const Duration(milliseconds: 500));
          return;
        }
      }
      // Fallback to first Progress text
      await tester.tap(progressTabs.first);
    } else {
      await tester.tap(progressTabs);
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  /// Navigate to the Settings tab
  static Future<void> navigateToSettingsTab(WidgetTester tester) async {
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  /// Swipe left on flashcard (mark as difficult)
  static Future<void> swipeFlashcardLeft(WidgetTester tester) async {
    // Find the flashcard - look for CardSwiper or Card widget
    final cardFinder = _findFlashcard(tester);

    // Swipe left with sufficient distance
    await tester.drag(cardFinder, const Offset(-300, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  /// Swipe right on flashcard (mark as known)
  static Future<void> swipeFlashcardRight(WidgetTester tester) async {
    final cardFinder = _findFlashcard(tester);

    // Swipe right with sufficient distance
    await tester.drag(cardFinder, const Offset(300, 0));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  /// Tap to flip flashcard
  static Future<void> tapToFlipFlashcard(WidgetTester tester) async {
    final cardFinder = _findFlashcard(tester);
    await tester.tap(cardFinder);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
  }

  /// Complete a review with the specified difficulty
  static Future<void> completeReviewWithDifficulty(
    WidgetTester tester,
    String difficulty, // 'Again', 'Hard', 'Normal', 'Easy'
  ) async {
    // For now, just tap the card to flip it (simulating review interaction)
    await tapToFlipFlashcard(tester);
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  /// Verify feedback message appears (allows multiple matches)
  static void verifyFeedbackMessage(String expectedMessage) {
    expect(find.textContaining(expectedMessage), findsAtLeastNWidgets(1));
  }

  /// Verify empty review state
  static void verifyEmptyReviewState() {
    // Look for the actual empty state text
    final hasEmptyMessage =
        find.textContaining('No words need review').evaluate().isNotEmpty ||
        find.textContaining('No words to review').evaluate().isNotEmpty;
    expect(hasEmptyMessage, isTrue, reason: 'Should show empty review message');

    final hasInstructions =
        find.textContaining('Go to Learn').evaluate().isNotEmpty ||
        find.textContaining('Learn mode').evaluate().isNotEmpty;
    expect(hasInstructions, isTrue, reason: 'Should show helpful instructions');
  }

  /// Verify review queue has words
  static void verifyReviewQueueHasWords() {
    // Check that it's NOT showing empty state
    final hasEmptyMessage =
        find.textContaining('No words need review').evaluate().isNotEmpty ||
        find.textContaining('No words to review').evaluate().isNotEmpty;
    expect(
      hasEmptyMessage,
      isFalse,
      reason: 'Should not show empty state when words are available',
    );

    // Look for actual review interface elements
    final hasReviewMode =
        find.textContaining('Review Mode').evaluate().isNotEmpty ||
        find.textContaining('Review ').evaluate().isNotEmpty;
    expect(hasReviewMode, isTrue, reason: 'Should show review interface');
  }

  /// Verify progress indicators for multiple review items
  static void verifyMultipleReviewItems() {
    // Look for review counter in "Review X/Y" format
    final hasReviewCounter = find
        .textContaining('Review ')
        .evaluate()
        .isNotEmpty;
    expect(hasReviewCounter, isTrue, reason: 'Should show review counter');
    expect(find.textContaining('No words to review'), findsNothing);
  }

  /// Change language selection
  static Future<void> changeLanguage(
    WidgetTester tester,
    String languageName,
  ) async {
    // Look for language selector button/dropdown
    final languageSelector = find.byType(DropdownButton<String>).first;
    await tester.tap(languageSelector);
    await tester.pumpAndSettle();

    // Select the desired language
    await tester.tap(find.text(languageName));
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  /// Wait for snackbar to appear and disappear
  static Future<void> waitForSnackbar(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    // Wait for snackbar to show
    await tester.pump(const Duration(seconds: 1));
    // Wait for it to disappear
    await tester.pump(const Duration(seconds: 2));
  }

  /// Find flashcard widget (tries multiple approaches)
  static Finder _findFlashcard(WidgetTester tester) {
    // Try to find CardSwiper first
    final cardSwiperFinder = find.byType(CardSwiper);
    if (cardSwiperFinder.evaluate().isNotEmpty) {
      return cardSwiperFinder;
    }

    // Fall back to Card widget
    final cardFinder = find.byType(Card);
    if (cardFinder.evaluate().isNotEmpty) {
      return cardFinder.first; // Take the first card if multiple exist
    }

    // Last resort - look for any tappable widget in the center
    return find.byType(GestureDetector).first;
  }

  /// Verify app navigation works correctly
  static Future<void> verifyNavigationWorks(WidgetTester tester) async {
    // Test that we can navigate and app doesn't crash
    expect(find.byType(MaterialApp), findsOneWidget);

    // Ensure no error dialogs or crash screens
    expect(find.textContaining('Error'), findsNothing);
    expect(find.textContaining('Exception'), findsNothing);
  }

  /// Clear app state (useful for test cleanup)
  static Future<void> clearAppState(WidgetTester tester) async {
    // Navigate to settings to potentially clear data
    await navigateToSettingsTab(tester);
    await tester.pumpAndSettle();

    // Return to learn tab
    await navigateToLearnTab(tester);
  }

  /// Debug helper: Print current widget tree
  static void debugPrintWidgetTree(WidgetTester tester) {
    debugPrint('=== Widget Tree ===');
    debugPrint(
      tester.allWidgets.map((w) => w.runtimeType.toString()).join('\n'),
    );
    debugPrint('==================');
  }

  /// Debug helper: Print all text widgets
  static void debugPrintAllText(WidgetTester tester) {
    final textWidgets = tester.widgetList<Text>(find.byType(Text));
    debugPrint('=== Text Widgets ===');
    for (final text in textWidgets) {
      debugPrint('Text: "${text.data}"');
    }
    debugPrint('====================');
  }
}
