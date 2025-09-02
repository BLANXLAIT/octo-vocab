// Basic smoke test for Octo Vocab app.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_saas_template/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test: renders Home screen', (
    WidgetTester tester,
  ) async {
    // Build the app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: OctoVocabApp()));

    // Verify app loads and key navigation items are present.
    expect(find.text('Learn'), findsAtLeastNWidgets(1));
    expect(find.text('Quiz'), findsAtLeastNWidgets(1));
    expect(find.text('Review'), findsAtLeastNWidgets(1));
    expect(find.text('Progress'), findsAtLeastNWidgets(1));
    expect(find.text('Settings'), findsAtLeastNWidgets(1));
  });
}
