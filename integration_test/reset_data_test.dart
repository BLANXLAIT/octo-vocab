// ignore_for_file: public_member_api_docs

/// Reset Data Integration Tests
///
/// This file tests the "Reset All Data" functionality, which was critical to fix
/// during development because it had a provider caching issue.
///
/// CRITICAL FIX IMPLEMENTED:
/// The original implementation only cleared SharedPreferences but didn't invalidate
/// Riverpod providers, causing cached data to persist in the UI after reset.
///
/// The fix involves calling provider invalidation after successful data reset:
/// ```dart
/// if (success) {
///   // Invalidate providers so they reload fresh data after reset
///   ref.invalidate(wordProgressProvider);
///   ref.invalidate(reviewQueueProvider);
///   ref.invalidate(reviewSessionsProvider);
///   ref.invalidate(localDataServiceProvider);
/// }
/// ```
///
/// This ensures that:
/// 1. SharedPreferences data is cleared
/// 2. Provider caches are invalidated
/// 3. UI immediately reflects the reset state
/// 4. All user data disappears from the interface
///
/// See adaptive_scaffold.dart:~line 284 for the implementation.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octo_vocab/main.dart' as app;
import 'package:octo_vocab/core/services/local_data_service.dart';
import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Reset All Data Test', () {
    setUp(() async {
      // For integration tests, we want to use real SharedPreferences
      // Clear any existing data before each test
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('Reset All Data clears all user data completely', (tester) async {
      debugPrint('🧪 Testing Reset All Data functionality');
      
      app.main();
      await TestHelpers.waitForAppLoad(tester);

      // Step 1: Create some user data directly using the service
      debugPrint('📝 Step 1: Creating test data directly');
      
      final dataService = await LocalDataService.create();
      
      // Add test word progress
      await dataService.setWordProgress({
        'test_word_1': 'difficult',
        'test_word_2': 'known', 
        'test_word_3': 'learning'
      });
      
      // Add test quiz result
      await dataService.saveQuizResult('test_quiz_${DateTime.now().millisecondsSinceEpoch}', {
        'score': 4,
        'total': 5,
        'date': DateTime.now().toIso8601String(),
        'duration': 120,
      });
      
      // Record a study session
      await dataService.recordStudySession();
      
      debugPrint('✅ Test data created directly');

      // Step 2: Verify data exists before reset
      debugPrint('📊 Step 2: Verifying data exists before reset');
      
      // Check word progress
      final wordProgressBefore = dataService.getWordProgress();
      debugPrint('📝 Word progress entries before reset: ${wordProgressBefore.length}');
      expect(wordProgressBefore.isNotEmpty, isTrue, reason: 'Should have word progress data');
      
      // Check quiz results
      final quizResultsBefore = dataService.getQuizResults();
      debugPrint('📊 Quiz results entries before reset: ${quizResultsBefore.length}');
      expect(quizResultsBefore.isNotEmpty, isTrue, reason: 'Should have quiz results data');
      
      // Check study sessions
      final studySessionsBefore = dataService.getStudySessions();
      debugPrint('📈 Study sessions before reset: ${studySessionsBefore.length}');
      expect(studySessionsBefore.isNotEmpty, isTrue, reason: 'Should have study sessions data');

      // Step 3: Navigate to Settings and find Reset Data button
      debugPrint('⚙️ Step 3: Navigating to Settings');
      await TestHelpers.navigateToSettingsTab(tester);
      await tester.pumpAndSettle();
      
      // Look for the reset data button - it might be text or an icon
      debugPrint('🔍 Looking for Reset All Data button');
      
      // Look for the reset data button using semantic label first, then fallback to key/text
      Finder resetButton = find.bySemanticsLabel('Reset all learning data and preferences - this action cannot be undone');
      
      if (resetButton.evaluate().isEmpty) {
        resetButton = find.byKey(const Key('reset_data_card'));
      }
      
      if (resetButton.evaluate().isEmpty) {
        resetButton = find.text('Reset My Data');
      }
      
      if (resetButton.evaluate().isEmpty) {
        debugPrint('❌ Reset My Data button not found in UI - checking available elements');
        TestHelpers.debugPrintAllText(tester);
        fail('Reset My Data button not found in Settings screen');
      }
      
      // Step 4: Trigger reset
      debugPrint('🗑️ Step 4: Triggering reset');
      await tester.tap(resetButton);
      await tester.pumpAndSettle();
      
      // Look for confirmation dialog and confirm  
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      
      // Try to find the actual FilledButton by key first, then by text
      Finder confirmButton = find.byKey(const Key('confirm_delete_button'));
      String buttonType = 'key';
      
      if (confirmButton.evaluate().isEmpty) {
        confirmButton = find.text('Delete All Data');
        buttonType = 'text';
      }
      
      // As a last resort, find FilledButton with the specific text
      if (confirmButton.evaluate().isEmpty) {
        confirmButton = find.widgetWithText(FilledButton, 'Delete All Data');
        buttonType = 'FilledButton with text';
      }
      
      if (confirmButton.evaluate().isNotEmpty) {
        debugPrint('✅ Confirmation dialog found using $buttonType - confirming deletion');
        debugPrint('📍 Button widget found: ${confirmButton.evaluate().first.widget}');
        
        await tester.tap(confirmButton);
        await tester.pump(const Duration(milliseconds: 200));
        debugPrint('🔄 Button tapped, waiting for dialog to close...');
        await tester.pumpAndSettle();
      } else {
        debugPrint('⚠️ No confirmation dialog found - checking if reset happened directly');
      }

      // Step 5: Verify all data is cleared
      debugPrint('🧹 Step 5: Verifying all data is cleared');
      
      // Wait a moment for any async operations to complete
      await tester.pump(const Duration(milliseconds: 1000));
      
      // Re-create data service to get fresh data
      final dataServiceAfter = await LocalDataService.create();
      
      // Check word progress is cleared
      final wordProgressAfter = dataServiceAfter.getWordProgress();
      debugPrint('📝 Word progress entries after reset: ${wordProgressAfter.length}');
      expect(wordProgressAfter.isEmpty, isTrue, reason: 'Word progress should be empty after reset');
      
      // Check quiz results are cleared
      final quizResultsAfter = dataServiceAfter.getQuizResults();
      debugPrint('📊 Quiz results entries after reset: ${quizResultsAfter.length}');
      expect(quizResultsAfter.isEmpty, isTrue, reason: 'Quiz results should be empty after reset');
      
      // Check study sessions are cleared
      final studySessionsAfter = dataServiceAfter.getStudySessions();
      debugPrint('📈 Study sessions after reset: ${studySessionsAfter.length}');
      expect(studySessionsAfter.isEmpty, isTrue, reason: 'Study sessions should be empty after reset');
      
      // Check app settings are cleared
      final appSettingsAfter = dataServiceAfter.getAppSettings();
      debugPrint('⚙️ App settings after reset: ${appSettingsAfter.length}');
      expect(appSettingsAfter.isEmpty, isTrue, reason: 'App settings should be empty after reset');

      // Step 6: Verify UI reflects the reset
      debugPrint('🖼️ Step 6: Verifying UI reflects the reset');
      
      // Go to Review tab - should show empty state
      await TestHelpers.navigateToReviewTab(tester);
      await tester.pumpAndSettle();
      
      // Should see "No words to review" or similar empty state message
      final hasEmptyReviewMessage = find.textContaining('No words').evaluate().isNotEmpty ||
                                   find.textContaining('empty').evaluate().isNotEmpty;
      expect(hasEmptyReviewMessage, isTrue, reason: 'Review tab should show empty state after reset');
      
      // Go to Progress tab - should show reset state
      await TestHelpers.navigateToProgressTab(tester);
      await tester.pumpAndSettle();
      
      // Should show no quiz results
      final hasNoQuizResults = find.textContaining('No quiz results').evaluate().isNotEmpty ||
                              find.text('0').evaluate().isNotEmpty;
      expect(hasNoQuizResults, isTrue, reason: 'Progress tab should show no quiz results after reset');

      debugPrint('✅ Reset All Data test completed successfully');
    });

    testWidgets('Reset All Data function works directly via LocalDataService', (tester) async {
      debugPrint('🧪 Testing clearAllData() method directly');
      
      // Clear any existing data first
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Create some test data directly
      final dataService = await LocalDataService.create();
      
      // Add test word progress
      await dataService.setWordProgress({'test_word': 'difficult'});
      
      // Add test quiz result
      await dataService.saveQuizResult('test_quiz', {
        'score': 5,
        'total': 5,
        'date': DateTime.now().toIso8601String(),
      });
      
      // Add test study session
      await dataService.recordStudySession();
      
      // Verify data exists
      expect(dataService.getWordProgress().isNotEmpty, isTrue);
      expect(dataService.getQuizResults().isNotEmpty, isTrue);
      expect(dataService.getStudySessions().isNotEmpty, isTrue);
      
      // Clear all data
      debugPrint('🗑️ Calling clearAllData()');
      final success = await dataService.clearAllData();
      expect(success, isTrue, reason: 'clearAllData should return true');
      
      // Verify all data is cleared
      expect(dataService.getWordProgress().isEmpty, isTrue, reason: 'Word progress should be empty');
      expect(dataService.getQuizResults().isEmpty, isTrue, reason: 'Quiz results should be empty');  
      expect(dataService.getStudySessions().isEmpty, isTrue, reason: 'Study sessions should be empty');
      expect(dataService.getAppSettings().isEmpty, isTrue, reason: 'App settings should be empty');
      
      debugPrint('✅ Direct clearAllData() test passed');
    });
  });
}