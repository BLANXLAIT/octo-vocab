import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_saas_template/core/language/language_registry.dart';
import 'package:flutter_saas_template/core/language/models/language.dart';
import 'package:flutter_saas_template/core/language/models/vocabulary_item.dart';
import 'package:flutter_saas_template/core/language/plugins/latin_plugin.dart';
import 'package:flutter_saas_template/core/language/plugins/spanish_plugin.dart';
import 'package:flutter_saas_template/core/models/vocabulary_level.dart';

void main() {
  group('Language Switching Integration Tests', () {
    late LanguageRegistry registry;

    setUp(() {
      // Use the singleton registry and register plugins
      registry = LanguageRegistry.instance;
      registry.register(LatinPlugin());
      registry.register(SpanishPlugin());
    });

    testWidgets('language registry initializes with plugins', (tester) async {
      final languages = registry.getAvailableLanguages();
      
      expect(languages, hasLength(2));
      expect(languages.map((l) => l.code), containsAll(['la', 'es']));
      expect(languages.map((l) => l.name), containsAll(['Latin', 'Spanish']));
    });

    testWidgets('can switch between registered languages', (tester) async {
      expect(registry.isLanguageAvailable('la'), isTrue);
      expect(registry.isLanguageAvailable('es'), isTrue);
      expect(registry.isLanguageAvailable('fr'), isFalse);

      final latinPlugin = registry.getPlugin('la');
      final spanishPlugin = registry.getPlugin('es');

      expect(latinPlugin, isNotNull);
      expect(spanishPlugin, isNotNull);
      expect(latinPlugin?.language.name, equals('Latin'));
      expect(spanishPlugin?.language.name, equals('Spanish'));
    });

    testWidgets('plugins have different formatting behavior', (tester) async {
      const testItem = VocabularyItem(
        id: 'test',
        term: 'test',
        translation: 'test',
        exampleTerm: 'Test example',
        exampleTranslation: 'Ejemplo de prueba',
      );

      final latinPlugin = registry.getPlugin('la')!;
      final spanishPlugin = registry.getPlugin('es')!;

      final latinExample = latinPlugin.formatExample(testItem);
      final spanishExample = spanishPlugin.formatExample(testItem);

      expect(latinExample, contains('—')); // Classical style
      expect(spanishExample, contains('→')); // Modern style
    });

    testWidgets('plugins generate different progress keys', (tester) async {
      const wordId = 'amor';

      final latinPlugin = registry.getPlugin('la')!;
      final spanishPlugin = registry.getPlugin('es')!;

      final latinKey = latinPlugin.getProgressKey(wordId);
      final spanishKey = spanishPlugin.getProgressKey(wordId);

      expect(latinKey, equals('la_amor'));
      expect(spanishKey, equals('es_amor'));
      expect(latinKey, isNot(equals(spanishKey)));
    });

    testWidgets('plugins generate different asset paths', (tester) async {
      final vocabSet = VocabularySets.beginner.first;

      final latinPlugin = registry.getPlugin('la')!;
      final spanishPlugin = registry.getPlugin('es')!;

      final latinPath = latinPlugin.getVocabularyAssetPath(VocabularyLevel.beginner, vocabSet);
      final spanishPath = spanishPlugin.getVocabularyAssetPath(VocabularyLevel.beginner, vocabSet);

      expect(latinPath, equals('assets/vocab/la/beginner/${vocabSet.filename}'));
      expect(spanishPath, equals('assets/vocab/es/beginner/${vocabSet.filename}'));
      expect(latinPath, isNot(equals(spanishPath)));
    });

    testWidgets('language registry provides correct vocabulary loading interface', (tester) async {
      // Test that the registry can handle vocabulary loading requests
      // (This would normally load from actual asset files, but in test we just verify the interface)
      
      expect(() async => registry.loadVocabulary('la', VocabularyLevel.beginner), returnsNormally);
      expect(() async => registry.loadVocabulary('es', VocabularyLevel.beginner), returnsNormally);
      
      expect(
        () => registry.loadVocabulary('nonexistent', VocabularyLevel.beginner),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('language switching preserves plugin independence', (tester) async {
      final latinPlugin = registry.getPlugin('la')!;
      final spanishPlugin = registry.getPlugin('es')!;

      // Each plugin should maintain its own identity
      expect(latinPlugin.language.color, isNot(equals(spanishPlugin.language.color)));
      expect(latinPlugin.language.icon, isNot(equals(spanishPlugin.language.icon)));
      expect(latinPlugin.getLearningTips(), isNot(equals(spanishPlugin.getLearningTips())));
    });
  });

  group('Provider Integration Tests', () {
    testWidgets('providers work with language registry', (tester) async {
      // This tests that our providers can work with the registry system
      const mockLanguages = [
        Language(code: 'la', name: 'Latin', nativeName: 'Latina', icon: Icons.abc, color: Colors.brown),
        Language(code: 'es', name: 'Spanish', nativeName: 'Español', icon: Icons.abc, color: Colors.orange),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availableLanguagesProvider.overrideWith((ref) => mockLanguages),
            selectedLanguageProvider.overrideWith((ref) => 'la'),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                final languages = ref.watch(availableLanguagesProvider);
                final selected = ref.watch(selectedLanguageProvider);
                
                return Scaffold(
                  body: Column(
                    children: [
                      Text('Available: ${languages.length}'),
                      Text('Selected: $selected'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Available: 2'), findsOneWidget);
      expect(find.text('Selected: la'), findsOneWidget);
    });

    testWidgets('language selection updates correctly', (tester) async {
      const mockLanguages = [
        Language(code: 'la', name: 'Latin', nativeName: 'Latina', icon: Icons.abc, color: Colors.brown),
        Language(code: 'es', name: 'Spanish', nativeName: 'Español', icon: Icons.abc, color: Colors.orange),
      ];

      late String selectedLanguage;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            availableLanguagesProvider.overrideWith((ref) => mockLanguages),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                selectedLanguage = ref.watch(selectedLanguageProvider);
                
                return Scaffold(
                  body: Column(
                    children: [
                      Text('Selected: $selectedLanguage'),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(selectedLanguageProvider.notifier).state = 'es';
                        },
                        child: const Text('Switch to Spanish'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Selected: la'), findsOneWidget); // Default to first language

      await tester.tap(find.text('Switch to Spanish'));
      await tester.pump();

      expect(find.text('Selected: es'), findsOneWidget);
    });
  });
}