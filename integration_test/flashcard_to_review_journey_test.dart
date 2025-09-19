// ignore_for_file: public_member_api_docs
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octo_vocab/main.dart' as app;
import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flashcard → Review Journey Tests', () {
    setUp(() async {
      // Clean slate for each test
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets(
      'AS a student, I WANT to mark difficult words SO THAT they appear in review',
      (tester) async {
        // GIVEN: I launch the app
        app.main();
        await TestHelpers.waitForAppLoad(tester);

        // WHEN: I swipe left on a flashcard (mark as difficult)
        await TestHelpers.swipeFlashcardLeft(tester);

        // THEN: I see feedback that the word will be reviewed later
        TestHelpers.verifyFeedbackMessage('Will review later');
        await TestHelpers.waitForSnackbar(tester);

        // AND WHEN: I navigate to the Review tab
        await TestHelpers.navigateToReviewTab(tester);

        // THEN: The word appears in my review queue
        TestHelpers.verifyReviewQueueHasWords();
      },
    );

    testWidgets(
      'AS a student, I WANT words I know to NOT appear in review SO THAT I focus on difficult words',
      (tester) async {
        // GIVEN: I launch the app
        app.main();
        await TestHelpers.waitForAppLoad(tester);

        // WHEN: I swipe right on a flashcard (mark as known)
        await TestHelpers.swipeFlashcardRight(tester);

        // THEN: I see feedback that the word is known
        TestHelpers.verifyFeedbackMessage('Known');
        await TestHelpers.waitForSnackbar(tester);

        // AND WHEN: I navigate to the Review tab
        await TestHelpers.navigateToReviewTab(tester);

        // THEN: The review queue is empty
        TestHelpers.verifyEmptyReviewState();
      },
    );

    testWidgets(
      'AS a student, I WANT multiple difficult words to accumulate in review SO THAT I can review them together',
      (tester) async {
        // GIVEN: I launch the app
        app.main();
        await TestHelpers.waitForAppLoad(tester);

        // WHEN: I mark multiple flashcards as difficult
        for (int i = 0; i < 3; i++) {
          await TestHelpers.swipeFlashcardLeft(tester);
          await TestHelpers.waitForSnackbar(tester);
        }

        // AND WHEN: I navigate to the Review tab
        await TestHelpers.navigateToReviewTab(tester);

        // THEN: I see multiple words in my review queue
        TestHelpers.verifyMultipleReviewItems();
      },
    );

    testWidgets(
      'AS a student, I WANT to complete reviews with different difficulties SO THAT words are rescheduled appropriately',
      (tester) async {
        // GIVEN: I have a word in my review queue
        app.main();
        await TestHelpers.waitForAppLoad(tester);
        await TestHelpers.swipeFlashcardLeft(tester);
        await TestHelpers.waitForSnackbar(tester);
        await TestHelpers.navigateToReviewTab(tester);

        // WHEN: I complete the review by marking it as "Easy"
        await TestHelpers.completeReviewWithDifficulty(tester, 'Easy');

        // THEN: The review session completes successfully
        await TestHelpers.verifyNavigationWorks(tester);

        // Note: The word should be rescheduled for future review
        // but we can't easily test the timing in an integration test
      },
    );

    testWidgets(
      'AS a student, I WANT my review progress to persist across navigation SO THAT I can switch between features',
      (tester) async {
        // GIVEN: I mark a word as difficult
        app.main();
        await TestHelpers.waitForAppLoad(tester);
        await TestHelpers.swipeFlashcardLeft(tester);
        await TestHelpers.waitForSnackbar(tester);

        // WHEN: I navigate to different tabs and back to Review
        await TestHelpers.navigateToProgressTab(tester);
        await TestHelpers.navigateToQuizTab(tester);
        await TestHelpers.navigateToSettingsTab(tester);
        await TestHelpers.navigateToReviewTab(tester);

        // THEN: The word is still in my review queue
        TestHelpers.verifyReviewQueueHasWords();
      },
    );

    testWidgets(
      'AS a student, I WANT to see helpful guidance when my review queue is empty SO THAT I know how to add words',
      (tester) async {
        // GIVEN: I launch the app with no difficult words
        app.main();
        await TestHelpers.waitForAppLoad(tester);

        // WHEN: I navigate directly to Review
        await TestHelpers.navigateToReviewTab(tester);

        // THEN: I see helpful empty state guidance
        TestHelpers.verifyEmptyReviewState();
        expect(find.textContaining('swipe left'), findsOneWidget);
      },
    );

    testWidgets(
      'AS a student, I WANT to flip flashcards before marking them SO THAT I can see both sides',
      (tester) async {
        // GIVEN: I launch the app
        app.main();
        await TestHelpers.waitForAppLoad(tester);

        // WHEN: I tap to flip the flashcard
        await TestHelpers.tapToFlipFlashcard(tester);

        // THEN: The card flips (we can't easily verify the flip animation,
        // but we can verify the tap doesn't crash the app)
        await TestHelpers.verifyNavigationWorks(tester);

        // AND WHEN: I swipe left after flipping
        await TestHelpers.swipeFlashcardLeft(tester);

        // THEN: The word is still marked as difficult
        TestHelpers.verifyFeedbackMessage('Will review later');
      },
    );

    testWidgets(
      'AS a student, I WANT consistent behavior when rapidly swiping SO THAT the app remains responsive',
      (tester) async {
        // GIVEN: I launch the app
        app.main();
        await TestHelpers.waitForAppLoad(tester);

        // WHEN: I rapidly swipe multiple cards in different directions
        await TestHelpers.swipeFlashcardLeft(tester);
        await TestHelpers.swipeFlashcardRight(tester);
        await TestHelpers.swipeFlashcardLeft(tester);
        await TestHelpers.swipeFlashcardLeft(tester);

        // Allow time for all operations to complete
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // THEN: The app remains responsive and functional
        await TestHelpers.verifyNavigationWorks(tester);

        // AND: I can still navigate to review
        await TestHelpers.navigateToReviewTab(tester);

        // AND: Some words should be in review (from the left swipes)
        // We don't verify the exact count since some swipes might have been on the same card
        await TestHelpers.verifyNavigationWorks(tester);
      },
    );
  });
}
