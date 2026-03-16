import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:octo_vocab/core/repositories/word_progress_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSharedPreferences mockPrefs;
  late WordProgressRepository repository;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    repository = WordProgressRepository(mockPrefs);
  });

  group('WordProgressRepository', () {
    group('getWordProgress', () {
      test('returns empty map when no data stored', () {
        when(() => mockPrefs.getString(any())).thenReturn(null);

        final result = repository.getWordProgress();

        expect(result, isEmpty);
      });

      test('returns parsed word progress from storage', () {
        const jsonData = '{"la_word1":"known","la_word2":"difficult"}';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final result = repository.getWordProgress();

        expect(result, {
          'la_word1': 'known',
          'la_word2': 'difficult',
        });
      });

      test('returns empty map when JSON is invalid', () {
        when(() => mockPrefs.getString(any())).thenReturn('invalid json');

        final result = repository.getWordProgress();

        expect(result, isEmpty);
      });

      test('handles corrupted data gracefully', () {
        when(() => mockPrefs.getString(any())).thenReturn('{"la_word1":123}');

        final result = repository.getWordProgress();

        // Should handle type mismatch gracefully
        expect(result, isA<Map<String, String>>());
      });
    });

    group('setWordProgress', () {
      test('saves word progress to storage', () async {
        when(() => mockPrefs.setString(any(), any()))
            .thenAnswer((_) async => true);

        final progress = {'la_word1': 'known', 'la_word2': 'difficult'};
        final result = await repository.setWordProgress(progress);

        expect(result, isTrue);
        verify(() => mockPrefs.setString(
              WordProgressRepository.storageKey,
              '{"la_word1":"known","la_word2":"difficult"}',
            )).called(1);
      });

      test('returns false when storage fails', () async {
        when(() => mockPrefs.setString(any(), any()))
            .thenAnswer((_) async => false);

        final progress = {'la_word1': 'known'};
        final result = await repository.setWordProgress(progress);

        expect(result, isFalse);
      });
    });

    group('getProgressForLanguage', () {
      test('filters progress by language code', () {
        const jsonData = '''
          {
            "la_word1": "known",
            "la_word2": "difficult",
            "es_word1": "known",
            "es_word2": "reviewing"
          }
        ''';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final result = repository.getProgressForLanguage('la');

        expect(result, {
          'la_word1': 'known',
          'la_word2': 'difficult',
        });
        expect(result, isNot(contains('es_word1')));
      });

      test('returns empty map when no progress for language', () {
        const jsonData = '{"es_word1":"known"}';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final result = repository.getProgressForLanguage('la');

        expect(result, isEmpty);
      });
    });

    group('updateWordStatus', () {
      test('updates single word status', () async {
        const jsonData = '{"la_word1":"difficult"}';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);
        when(() => mockPrefs.setString(any(), any()))
            .thenAnswer((_) async => true);

        final result = await repository.updateWordStatus('la_word1', 'known');

        expect(result, isTrue);
        verify(() => mockPrefs.setString(
              WordProgressRepository.storageKey,
              '{"la_word1":"known"}',
            )).called(1);
      });

      test('adds new word status', () async {
        const jsonData = '{}';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);
        when(() => mockPrefs.setString(any(), any()))
            .thenAnswer((_) async => true);

        final result =
            await repository.updateWordStatus('la_word1', 'difficult');

        expect(result, isTrue);
        verify(() => mockPrefs.setString(
              WordProgressRepository.storageKey,
              '{"la_word1":"difficult"}',
            )).called(1);
      });
    });

    group('getWordStatus', () {
      test('returns status for existing word', () {
        const jsonData = '{"la_word1":"known"}';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final result = repository.getWordStatus('la_word1');

        expect(result, 'known');
      });

      test('returns null for non-existent word', () {
        const jsonData = '{}';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final result = repository.getWordStatus('la_word1');

        expect(result, isNull);
      });
    });

    group('getStatsByLanguage', () {
      test('returns statistics for language', () {
        const jsonData = '''
          {
            "la_word1": "known",
            "la_word2": "known",
            "la_word3": "difficult",
            "la_word4": "reviewing",
            "la_word5": "mastered",
            "es_word1": "known"
          }
        ''';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final stats = repository.getStatsByLanguage('la');

        expect(stats.totalWords, 5);
        expect(stats.knownWords, 2);
        expect(stats.difficultWords, 1);
        expect(stats.reviewingWords, 1);
        expect(stats.masteredWords, 1);
      });

      test('returns zero stats for empty language', () {
        const jsonData = '{}';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final stats = repository.getStatsByLanguage('la');

        expect(stats.totalWords, 0);
        expect(stats.knownWords, 0);
        expect(stats.difficultWords, 0);
      });
    });

    group('clearProgressForLanguage', () {
      test('removes all progress for language', () async {
        const jsonData = '''
          {
            "la_word1": "known",
            "la_word2": "difficult",
            "es_word1": "known"
          }
        ''';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);
        when(() => mockPrefs.setString(any(), any()))
            .thenAnswer((_) async => true);

        final result = await repository.clearProgressForLanguage('la');

        expect(result, isTrue);
        verify(() => mockPrefs.setString(
              WordProgressRepository.storageKey,
              '{"es_word1":"known"}',
            )).called(1);
      });
    });

    group('clearAllProgress', () {
      test('removes all word progress', () async {
        when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

        final result = await repository.clearAllProgress();

        expect(result, isTrue);
        verify(() => mockPrefs.remove(WordProgressRepository.storageKey))
            .called(1);
      });
    });
  });
}