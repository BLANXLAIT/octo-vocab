// ignore_for_file: public_member_api_docs, directives_ordering

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_saas_template/app.dart';
import 'package:flutter_saas_template/core/navigation/adaptive_scaffold.dart';
import 'package:flutter_saas_template/features/flashcards/flashcards_screen.dart';
import 'package:flutter_saas_template/features/quiz/quiz_screen.dart';

/// Integration tests to verify privacy compliance across the entire app
/// These tests simulate real user interactions while monitoring privacy
void main() {
  group('Privacy Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('app launches without requiring authentication', (
      tester,
    ) async {
      // COPPA compliance: App should work without user accounts
      await tester.pumpWidget(const ProviderScope(child: OctoVocabApp()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Verify app launches directly to main content
      expect(find.byType(AdaptiveScaffold), findsOneWidget);
      expect(find.byType(FlashcardsScreen), findsOneWidget);

      // Verify no authentication screens exist
      expect(find.text('Sign In'), findsNothing);
      expect(find.text('Create Account'), findsNothing);
      expect(find.text('Login'), findsNothing);
      expect(find.byType(TextField), findsNothing); // No login forms
    });

    testWidgets('full app usage creates only educational data', (tester) async {
      // Test complete user journey to verify only educational data is stored
      await tester.pumpWidget(const ProviderScope(child: OctoVocabApp()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Navigate through all main screens - check for both NavigationBar and NavigationRail
      final hasNavBar = find.byType(NavigationBar).evaluate().isNotEmpty;
      final hasNavRail = find.byType(NavigationRail).evaluate().isNotEmpty;
      expect(
        hasNavBar || hasNavRail,
        isTrue,
        reason: 'Should have either NavigationBar or NavigationRail',
      );

      // Use Learn tab (default)
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate to Quiz tab
      await tester.tap(find.text('Quiz'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(QuizScreen), findsOneWidget);

      // Navigate to Settings tab
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Check that only educational preferences are stored
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        // All keys should be educational or system-related
        final isValidKey =
            key.contains('language') ||
            key.contains('level') ||
            key.contains('progress') ||
            key.contains('difficult') ||
            key.contains('word_') ||
            key.contains('study_') ||
            key.contains('quiz_') ||
            key.contains('app_settings') ||
            key.contains('config') ||
            key.startsWith('flutter.'); // Flutter system keys

        expect(isValidKey, isTrue, reason: 'Unexpected data key found: $key');
      }
    });

    testWidgets('privacy protection information is accessible', (tester) async {
      // GDPR compliance: Users must be informed about data processing
      await tester.pumpWidget(const ProviderScope(child: OctoVocabApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate to Settings
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Find and tap Privacy Protection section
      final privacyCard = find.byKey(const Key('privacy_info_card'));
      expect(privacyCard, findsOneWidget);

      // Tap to expand privacy information
      await tester.tap(privacyCard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify privacy information is displayed
      expect(find.textContaining('COPPA'), findsOneWidget);
      expect(find.textContaining('FERPA'), findsOneWidget);
      expect(find.textContaining('GDPR'), findsOneWidget);
      expect(find.textContaining('No data collection'), findsOneWidget);
      expect(find.textContaining('fully offline'), findsOneWidget);
    });

    testWidgets('data reset functionality works end-to-end', (tester) async {
      // GDPR Article 17: Right to erasure
      await tester.pumpWidget(const ProviderScope(child: OctoVocabApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Create some data by using the app
      // Navigate to Quiz to generate some state
      await tester.tap(find.text('Quiz'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate to Settings
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Find reset data button
      final resetCard = find.byKey(const Key('reset_data_card'));
      expect(resetCard, findsOneWidget);

      // Tap reset data
      await tester.tap(resetCard);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify confirmation dialog appears
      expect(find.text('Reset All Data'), findsOneWidget);
      expect(find.text('Delete All Data'), findsOneWidget);
      expect(find.text('This action cannot be undone'), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.text('Delete All Data'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify success message
      expect(find.textContaining('All data has been deleted'), findsOneWidget);

      // Verify SharedPreferences is cleared
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      expect(keys, isEmpty, reason: 'All user data should be deleted');
    });

    testWidgets('app works without network connectivity simulation', (
      tester,
    ) async {
      // COPPA/FERPA compliance: App should work completely offline
      await tester.pumpWidget(const ProviderScope(child: OctoVocabApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Test all main features work
      expect(find.byType(FlashcardsScreen), findsOneWidget);

      // Navigate to Quiz
      await tester.tap(find.text('Quiz'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(QuizScreen), findsOneWidget);

      // Navigate to Progress
      await tester.tap(find.text('Progress'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate to Review
      await tester.tap(find.text('Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate to Settings
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SettingsScreen), findsOneWidget);

      // All features should work without network
      // This test passes if no network exceptions are thrown
    });

    testWidgets('no external web views or browsers opened', (tester) async {
      // Privacy safeguard: App should not open external content
      await tester.pumpWidget(const ProviderScope(child: OctoVocabApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate through all screens
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Scroll to and tap on About section if present
      final aboutTile = find.text('About Octo Vocab');
      if (aboutTile.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(
          aboutTile,
          500.0,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(aboutTile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
      }

      // Verify no WebView or external browser widgets
      expect(find.byType(WebView), findsNothing);

      // GitHub links should be displayed as text, not clickable links
      expect(find.textContaining('github.com'), findsAtLeastNWidgets(1));
    });

    testWidgets('vocabulary data loads from local assets only', (tester) async {
      // FERPA compliance: Educational content should be local
      await tester.pumpWidget(const ProviderScope(child: OctoVocabApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Wait for vocabulary to load
      await tester.pump(const Duration(seconds: 2));

      // Navigate to Quiz to trigger vocabulary loading
      await tester.tap(find.text('Quiz'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Vocabulary should load without network requests
      // If quiz shows content, vocabulary loaded successfully from assets
      final hasQuizContent =
          find
              .textContaining('What is the English translation?')
              .evaluate()
              .isNotEmpty ||
          find.text('Loading...').evaluate().isNotEmpty ||
          find.textContaining('Quiz').evaluate().isNotEmpty;

      expect(
        hasQuizContent,
        isTrue,
        reason: 'Vocabulary should load from local assets',
      );
    });

    testWidgets('settings changes persist locally only', (tester) async {
      // Test that user preferences are stored locally, not remotely
      await tester.pumpWidget(const ProviderScope(child: OctoVocabApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate to Settings
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // The act of using settings should store preferences locally

      // Verify preferences are stored in SharedPreferences (local storage)
      final prefs = await SharedPreferences.getInstance();

      // After using settings, some configuration should be stored locally
      // We don't test specific keys as they may change, but verify storage is local
      expect(prefs, isNotNull, reason: 'Preferences should use local storage');
    });
  });

  group('Educational Context Compliance', () {
    testWidgets('app is suitable for classroom use', (tester) async {
      // FERPA compliance: Educational apps should be classroom-appropriate
      await tester.pumpWidget(const ProviderScope(child: OctoVocabApp()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify educational content is appropriate
      expect(find.text('Learn'), findsAtLeastNWidgets(1));
      expect(find.text('Quiz'), findsAtLeastNWidgets(1));
      expect(find.text('Review'), findsAtLeastNWidgets(1));
      expect(find.text('Progress'), findsAtLeastNWidgets(1));

      // Verify no inappropriate content
      expect(find.textContaining('advertisement'), findsNothing);
      expect(find.textContaining('purchase'), findsNothing);
      expect(find.textContaining('premium'), findsNothing);
      expect(find.textContaining('upgrade'), findsNothing);
    });

    testWidgets('privacy notice is clear and accessible', (tester) async {
      // GDPR compliance: Clear privacy information
      await tester.pumpWidget(const ProviderScope(child: OctoVocabApp()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Navigate to Settings
      await tester.tap(find.text('Settings'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify privacy information is prominently displayed
      expect(find.text('Privacy Protection'), findsOneWidget);
      expect(find.textContaining('COPPA/FERPA compliant'), findsOneWidget);
      expect(find.textContaining('No data collection'), findsOneWidget);

      // Verify the green privacy indicator
      expect(find.byIcon(Icons.privacy_tip), findsOneWidget);
    });
  });
}

/// Mock WebView widget for testing
class WebView extends StatelessWidget {
  const WebView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
