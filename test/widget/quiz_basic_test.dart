import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octo_vocab/core/language/language_registry.dart';
import 'package:octo_vocab/core/language/models/vocabulary_item.dart';
import 'package:octo_vocab/core/language/plugins/latin_plugin.dart';
import 'package:octo_vocab/features/quiz/quiz_screen.dart';

void main() {
  group('Quiz UI Basic Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      LanguageRegistry.instance.clear();
      LanguageRegistry.instance.register(LatinPlugin());
    });

    testWidgets('quiz empty state displays correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [quizVocabularyProvider.overrideWith((ref) => [])],
          child: const MaterialApp(home: QuizScreen()),
        ),
      );

      // Verify basic empty state elements
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('No vocabulary found for quiz'), findsOneWidget);
    });

    testWidgets('error state displays when answers are empty', (tester) async {
      const mockVocabulary = [
        VocabularyItem(id: '1', term: 'amare', translation: 'to love'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            quizVocabularyProvider.overrideWith((ref) => mockVocabulary),
            shuffledAnswersProvider.overrideWith((ref) => []), // Empty answers
            correctAnswerIndexProvider.overrideWith((ref) => -1),
          ],
          child: const MaterialApp(home: QuizScreen()),
        ),
      );

      // Verify error state
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.text('Error loading quiz question'), findsOneWidget);
    });

    testWidgets('quiz length enum values are correct', (tester) async {
      // Test QuizLength enum functionality (no UI rendering)
      expect(QuizLength.quick5.count, equals(5));
      expect(QuizLength.short10.count, equals(10));
      expect(QuizLength.medium15.count, equals(15));
      expect(QuizLength.full.count, equals(0)); // 0 means all questions

      expect(QuizLength.quick5.displayName, equals('Quick (5)'));
      expect(QuizLength.short10.displayName, equals('Short (10)'));
      expect(QuizLength.medium15.displayName, equals('Medium (15)'));
      expect(QuizLength.full.displayName, equals('Full'));
    });
  });
}
