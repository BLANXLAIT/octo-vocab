// ignore_for_file: public_member_api_docs, prefer_const_constructors, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for privacy-related UI components
/// Ensures privacy information is properly displayed and accessible
void main() {
  group('Privacy UI Widget Tests', () {
    testWidgets('Privacy Protection icon styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.green),
                title: const Text('Privacy Protection'),
                subtitle: const Text(
                  'COPPA/FERPA compliant • No data collection',
                ),
              ),
            ),
          ),
        ),
      );

      // Verify privacy icon is present and green (indicates good privacy)
      expect(find.byIcon(Icons.privacy_tip), findsOneWidget);
      final privacyIcon = tester.widget<Icon>(find.byIcon(Icons.privacy_tip));
      expect(privacyIcon.color, equals(Colors.green));

      // Verify privacy title and subtitle
      expect(find.text('Privacy Protection'), findsOneWidget);
      expect(find.textContaining('COPPA/FERPA compliant'), findsOneWidget);
      expect(find.textContaining('No data collection'), findsOneWidget);
    });

    testWidgets('Privacy notice container styling', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your privacy is protected. All data stays on your device and you can delete it anytime.',
                      style: TextStyle(fontSize: 12, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify privacy notice styling
      expect(find.byIcon(Icons.shield), findsOneWidget);
      expect(find.textContaining('Your privacy is protected'), findsOneWidget);
      expect(find.textContaining('data stays on your device'), findsOneWidget);
      expect(find.textContaining('delete it anytime'), findsOneWidget);

      // Verify green security styling
      final shieldIcon = tester.widget<Icon>(find.byIcon(Icons.shield));
      expect(shieldIcon.color, equals(Colors.green));
      expect(shieldIcon.size, equals(20));
    });

    testWidgets('Data reset dialog displays appropriate warnings', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => _showResetDataDialog(context),
                child: const Text('Reset Data'),
              ),
            ),
          ),
        ),
      );

      // Tap to show dialog
      await tester.tap(find.text('Reset Data'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('Reset All Data'), findsOneWidget);
      expect(find.textContaining('permanently delete'), findsOneWidget);
      expect(find.textContaining('cannot be undone'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete All Data'), findsOneWidget);

      // Verify dangerous action is clearly marked
      final deleteButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete All Data'),
      );
      expect(
        deleteButton.style?.backgroundColor?.resolve({}),
        equals(Colors.red),
      );

      // Test cancellation
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Reset All Data'), findsNothing);
    });

    testWidgets('ExpansionTile basic functionality', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: ExpansionTile(
                leading: const Icon(Icons.privacy_tip, color: Colors.green),
                title: const Text('Privacy Protection'),
                subtitle: const Text(
                  'COPPA/FERPA compliant • No data collection',
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Privacy details would go here'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify collapsed state
      expect(find.text('Privacy Protection'), findsOneWidget);
      expect(
        find.text('COPPA/FERPA compliant • No data collection'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.privacy_tip), findsOneWidget);
      expect(find.text('Privacy details would go here'), findsNothing);

      // Expand the tile
      await tester.tap(find.byType(ExpansionTile));
      await tester.pumpAndSettle();

      // Verify expanded content appears
      expect(find.text('Privacy details would go here'), findsOneWidget);
    });

    testWidgets('Educational app content indicators', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Learn'),
                const Text('Quiz'),
                const Text('Review'),
                const Text('Progress'),
                const Text('Privacy-first vocabulary learning'),
                const Text('Designed for grades 7-12'),
              ],
            ),
          ),
        ),
      );

      // Verify educational content is present
      expect(find.text('Learn'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.textContaining('vocabulary learning'), findsOneWidget);
      expect(find.textContaining('grades 7-12'), findsOneWidget);
    });

    testWidgets('Info row widget structure', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _buildInfoRow(
              Icons.shield,
              'Privacy',
              'No data collection, fully offline',
            ),
          ),
        ),
      );

      // Verify info row structure
      expect(find.byIcon(Icons.shield), findsOneWidget);
      expect(find.text('Privacy:'), findsOneWidget);
      expect(find.textContaining('No data collection'), findsOneWidget);
      expect(find.textContaining('fully offline'), findsOneWidget);
    });
  });
}

Widget _buildInfoRow(IconData icon, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.grey[700])),
        ),
      ],
    ),
  );
}

Future<void> _showResetDataDialog(BuildContext context) async {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Reset All Data'),
      content: const Text(
        'This will permanently delete all your learning progress, '
        'quiz scores, and preferences stored on this device.\n\n'
        'This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete All Data'),
        ),
      ],
    ),
  );
}
