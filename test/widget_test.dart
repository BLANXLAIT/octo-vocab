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

    // Verify Home app bar/title and key navigation items are present.
    expect(find.text('Octo Vocab'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
  });
}
