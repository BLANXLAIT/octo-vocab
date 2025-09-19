// ignore_for_file: public_member_api_docs
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octo_vocab/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Timeout Debug Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets(
      'MINIMAL: App loads without timeout',
      (tester) async {
        print('🔍 Starting minimal app load test');

        // Start app
        app.main();
        print('✅ app.main() called');

        // Wait step by step with logging
        await tester.pump();
        print('✅ Initial pump complete');

        await tester.pump(const Duration(seconds: 1));
        print('✅ 1 second wait complete');

        await tester.pump(const Duration(seconds: 1));
        print('✅ 2 second wait complete');

        await tester.pump(const Duration(seconds: 1));
        print('✅ 3 second wait complete');

        // Try to find basic app structure
        final materialApp = find.byType(MaterialApp);
        print('MaterialApp found: ${materialApp.evaluate().isNotEmpty}');

        final scaffold = find.byType(Scaffold);
        print('Scaffold found: ${scaffold.evaluate().isNotEmpty}');

        // Try to settle
        print('🔍 Attempting pumpAndSettle');
        await tester.pumpAndSettle();
        print('✅ pumpAndSettle complete');

        // Look for bottom navigation or tabs
        final bottomNav = find.byType(BottomNavigationBar);
        final tabBar = find.byType(TabBar);
        print('BottomNav found: ${bottomNav.evaluate().isNotEmpty}');
        print('TabBar found: ${tabBar.evaluate().isNotEmpty}');

        // Look for text content
        final learnTab = find.text('Learn');
        final quizTab = find.text('Quiz');
        print('Learn tab found: ${learnTab.evaluate().isNotEmpty}');
        print('Quiz tab found: ${quizTab.evaluate().isNotEmpty}');

        expect(materialApp, findsOneWidget, reason: 'App should load');
        print('✅ Minimal test completed successfully');
      },
    );

    testWidgets(
      'STEP BY STEP: Navigation test',
      (tester) async {
        print('🔍 Starting step-by-step navigation test');

        // Start app
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 3));
        print('✅ App loaded and settled');

        // Try to navigate to quiz WITHOUT using TestHelpers
        final quizTab = find.text('Quiz');
        if (quizTab.evaluate().isNotEmpty) {
          print('✅ Found Quiz tab, attempting tap');
          await tester.tap(quizTab);
          print('✅ Quiz tab tapped');

          await tester.pump();
          print('✅ Pump after tap complete');

          await tester.pumpAndSettle();
          print('✅ PumpAndSettle after tap complete');
        } else {
          print('❌ Quiz tab not found');
        }

        expect(find.byType(MaterialApp), findsOneWidget);
        print('✅ Step-by-step test completed');
      },
    );

    testWidgets(
      'SPECIFIC: TestHelper waitForAppLoad issue',
      (tester) async {
        print('🔍 Testing TestHelper.waitForAppLoad specifically');

        // Start app
        app.main();
        print('✅ app.main() called');

        // REPLICATE TestHelpers.waitForAppLoad logic step by step
        print('🔍 Waiting 2 seconds...');
        await tester.pumpAndSettle(const Duration(seconds: 2));
        print('✅ 2 second wait complete');

        print('🔍 Checking for CircularProgressIndicator...');
        final loadingIndicators = find.byType(CircularProgressIndicator);
        final indicatorCount = loadingIndicators.evaluate().length;
        print('Found $indicatorCount loading indicators');

        if (indicatorCount > 0) {
          print('⚠️ Still has loading indicators - waiting more...');
          await tester.pumpAndSettle(const Duration(seconds: 2));
          final remainingIndicators = find.byType(CircularProgressIndicator).evaluate().length;
          print('After additional wait: $remainingIndicators indicators');
        }

        expect(find.byType(MaterialApp), findsOneWidget);
        print('✅ TestHelper logic test completed');
      },
    );
  });
}