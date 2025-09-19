import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:octo_vocab/core/language/language_registry.dart';
import 'package:octo_vocab/core/language/models/language.dart';
import 'package:octo_vocab/core/language/widgets/language_selector.dart';

void main() {
  group('LanguageSelector Widget Tests', () {
    const mockLanguages = [
      Language(
        code: 'la',
        name: 'Latin',
        nativeName: 'Lingua Latina',
        icon: Icons.account_balance,
        color: Colors.brown,
      ),
      Language(
        code: 'es',
        name: 'Spanish',
        nativeName: 'Español',
        icon: Icons.language,
        color: Colors.orange,
      ),
    ];

    Widget createTestWidget(
      List<Language> languages, [
      String selectedLanguage = 'la',
    ]) {
      return ProviderScope(
        overrides: [
          availableLanguagesProvider.overrideWith((ref) => languages),
          selectedLanguageProvider.overrideWith((ref) => selectedLanguage),
        ],
        child: const MaterialApp(home: Scaffold(body: LanguageSelector())),
      );
    }

    testWidgets('shows nothing when no languages available', (tester) async {
      await tester.pumpWidget(createTestWidget([]));

      expect(find.byType(LanguageSelector), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsNothing);
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('shows chip when only one language available', (tester) async {
      const singleLanguage = [
        Language(
          code: 'la',
          name: 'Latin',
          nativeName: 'Lingua Latina',
          icon: Icons.account_balance,
          color: Colors.brown,
        ),
      ];

      await tester.pumpWidget(createTestWidget(singleLanguage));

      expect(find.byType(Chip), findsOneWidget);
      expect(find.text('Latin'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });

    testWidgets('shows dropdown when multiple languages available', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(mockLanguages));

      expect(find.byType(DropdownButton<String>), findsOneWidget);
      expect(find.text('Latin'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });

    testWidgets('dropdown contains all available languages', (tester) async {
      await tester.pumpWidget(createTestWidget(mockLanguages));

      // Tap the dropdown to open it
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Latin'), findsWidgets);
      expect(find.text('Spanish'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsWidgets);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('can select different language from dropdown', (tester) async {
      String? selectedLanguage;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availableLanguagesProvider.overrideWith((ref) => mockLanguages),
            selectedLanguageProvider.overrideWith((ref) => 'la'),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, child) {
                  selectedLanguage = ref.watch(selectedLanguageProvider);
                  return const LanguageSelector();
                },
              ),
            ),
          ),
        ),
      );

      expect(selectedLanguage, equals('la'));

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Select Spanish
      await tester.tap(find.text('Spanish').last);
      await tester.pumpAndSettle();

      expect(selectedLanguage, equals('es'));
    });
  });

  group('LanguageSelectorAction Widget Tests', () {
    const mockLanguages = [
      Language(
        code: 'la',
        name: 'Latin',
        nativeName: 'Lingua Latina',
        icon: Icons.account_balance,
        color: Colors.brown,
      ),
      Language(
        code: 'es',
        name: 'Spanish',
        nativeName: 'Español',
        icon: Icons.language,
        color: Colors.orange,
      ),
    ];

    Widget createTestWidget(
      List<Language> languages, [
      String selectedLanguage = 'la',
    ]) {
      return ProviderScope(
        overrides: [
          availableLanguagesProvider.overrideWith((ref) => languages),
          selectedLanguageProvider.overrideWith((ref) => selectedLanguage),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(actions: const [LanguageSelectorAction()]),
          ),
        ),
      );
    }

    testWidgets('shows nothing when no languages available', (tester) async {
      await tester.pumpWidget(createTestWidget([]));

      expect(find.byType(LanguageSelectorAction), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });

    testWidgets('shows disabled icon button when only one language', (
      tester,
    ) async {
      const singleLanguage = [
        Language(
          code: 'la',
          name: 'Latin',
          nativeName: 'Lingua Latina',
          icon: Icons.account_balance,
          color: Colors.brown,
        ),
      ];

      await tester.pumpWidget(createTestWidget(singleLanguage));

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.account_balance), findsOneWidget);

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.onPressed, isNull); // Should be disabled
    });

    testWidgets('shows popup menu when multiple languages available', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(mockLanguages));

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      expect(find.text('LA'), findsOneWidget); // Language code in uppercase
    });

    testWidgets('popup menu contains all languages with current selected', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget(mockLanguages, 'es'));

      // Tap the popup menu button
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Latin'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);
      expect(
        find.byIcon(Icons.check),
        findsOneWidget,
      ); // Check mark for selected language
    });

    testWidgets('can select different language from popup menu', (
      tester,
    ) async {
      String? selectedLanguage;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availableLanguagesProvider.overrideWith((ref) => mockLanguages),
            selectedLanguageProvider.overrideWith((ref) => 'la'),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  Consumer(
                    builder: (context, ref, child) {
                      selectedLanguage = ref.watch(selectedLanguageProvider);
                      return const LanguageSelectorAction();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(selectedLanguage, equals('la'));

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Select Spanish
      await tester.tap(find.text('Spanish'));
      await tester.pumpAndSettle();

      expect(selectedLanguage, equals('es'));
    });

    testWidgets('displays correct language code and styling', (tester) async {
      await tester.pumpWidget(createTestWidget(mockLanguages, 'es'));

      expect(find.text('ES'), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(PopupMenuButton<String>),
          matching: find.byType(Container),
        ),
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(Colors.orange.withValues(alpha: 0.1)));
    });
  });
}
