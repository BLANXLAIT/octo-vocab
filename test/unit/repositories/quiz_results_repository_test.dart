import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:octo_vocab/core/repositories/quiz_results_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSharedPreferences mockPrefs;
  late QuizResultsRepository repository;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    repository = QuizResultsRepository(mockPrefs);
  });

  group('QuizResultsRepository', () {
    group('getAllResults', () {
      test('returns empty map when no data stored', () {
        when(() => mockPrefs.getString(any())).thenReturn(null);

        final result = repository.getAllResults();

        expect(result, isEmpty);
      });

      test('returns parsed quiz results', () {
        const jsonData = '''
          {
            "quiz_la_123": {"score": 80, "date": "2024-01-01"},
            "quiz_es_456": {"score": 90, "date": "2024-01-02"}
          }
        ''';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final result = repository.getAllResults();

        expect(result, hasLength(2));
        expect(result['quiz_la_123']!['score'], 80);
      });

      test('handles corrupted JSON gracefully', () {
        when(() => mockPrefs.getString(any())).thenReturn('invalid');

        final result = repository.getAllResults();

        expect(result, isEmpty);
      });
    });

    group('getResultsForLanguage', () {
      test('filters results by language code', () {
        const jsonData = '''
          {
            "quiz_la_123": {"score": 80},
            "quiz_la_124": {"score": 85},
            "quiz_es_456": {"score": 90},
            "review_la_789": {"score": 75}
          }
        ''';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final result = repository.getResultsForLanguage('la');

        expect(result, hasLength(2));
        expect(result.keys, everyElement(contains('quiz_la_')));
      });

      test('returns empty map when no results for language', () {
        const jsonData = '{"quiz_es_123":{"score":90}}';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final result = repository.getResultsForLanguage('la');

        expect(result, isEmpty);
      });
    });

    group('saveQuizResult', () {
      test('saves new quiz result', () async {
        when(() => mockPrefs.getString(any())).thenReturn('{}');
        when(() => mockPrefs.setString(any(), any()))
            .thenAnswer((_) async => true);

        final result = await repository.saveQuizResult(
          'quiz_la_123',
          {'score': 80, 'date': '2024-01-01'},
        );

        expect(result, isTrue);
        verify(() => mockPrefs.setString(any(), any())).called(1);
      });

      test('merges with existing results', () async {
        const existingData = '{"quiz_la_123":{"score":80}}';
        when(() => mockPrefs.getString(any())).thenReturn(existingData);
        when(() => mockPrefs.setString(any(), any()))
            .thenAnswer((_) async => true);

        await repository.saveQuizResult(
          'quiz_la_124',
          {'score': 90},
        );

        final captured = verify(() => mockPrefs.setString(
              QuizResultsRepository.storageKey,
              captureAny(),
            )).captured;

        final savedData = captured.first as String;
        expect(savedData, contains('quiz_la_123'));
        expect(savedData, contains('quiz_la_124'));
      });
    });

    group('getQuizStatistics', () {
      test('calculates statistics correctly', () {
        const jsonData = '''
          {
            "quiz_la_1": {"percentage": 80, "totalQuestions": 10},
            "quiz_la_2": {"percentage": 90, "totalQuestions": 10},
            "quiz_la_3": {"percentage": 70, "totalQuestions": 10},
            "quiz_es_1": {"percentage": 95, "totalQuestions": 10}
          }
        ''';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final stats = repository.getQuizStatistics('la');

        expect(stats.totalQuizzes, 3);
        expect(stats.averageScore, 80); // (80+90+70)/3
        expect(stats.bestScore, 90);
        expect(stats.worstScore, 70);
      });

      test('handles empty results', () {
        when(() => mockPrefs.getString(any())).thenReturn('{}');

        final stats = repository.getQuizStatistics('la');

        expect(stats.totalQuizzes, 0);
        expect(stats.averageScore, 0);
        expect(stats.bestScore, 0);
        expect(stats.worstScore, 0);
      });

      test('handles missing percentage field', () {
        const jsonData = '''
          {
            "quiz_la_1": {"totalQuestions": 10},
            "quiz_la_2": {"percentage": 80}
          }
        ''';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final stats = repository.getQuizStatistics('la');

        expect(stats.totalQuizzes, 1); // Only counts valid entries
        expect(stats.averageScore, 80);
      });
    });

    group('clearResultsForLanguage', () {
      test('removes quiz results for specific language', () async {
        const jsonData = '''
          {
            "quiz_la_123": {"score": 80},
            "quiz_es_456": {"score": 90},
            "review_la_789": {"score": 75}
          }
        ''';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);
        when(() => mockPrefs.setString(any(), any()))
            .thenAnswer((_) async => true);

        final result = await repository.clearResultsForLanguage('la');

        expect(result, isTrue);
        final captured = verify(() => mockPrefs.setString(
              QuizResultsRepository.storageKey,
              captureAny(),
            )).captured;

        final savedData = captured.first as String;
        expect(savedData, contains('quiz_es_456'));
        expect(savedData, isNot(contains('quiz_la_123')));
        expect(savedData, contains('review_la_789')); // Only quiz_ removed
      });
    });

    group('clearAllResults', () {
      test('removes all quiz results', () async {
        when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

        final result = await repository.clearAllResults();

        expect(result, isTrue);
        verify(() => mockPrefs.remove(QuizResultsRepository.storageKey))
            .called(1);
      });
    });

    group('getRecentQuizzes', () {
      test('returns most recent quizzes', () {
        const jsonData = '''
          {
            "quiz_la_1000": {"percentage": 80, "date": "2024-01-01T10:00:00.000Z"},
            "quiz_la_2000": {"percentage": 85, "date": "2024-01-02T10:00:00.000Z"},
            "quiz_la_3000": {"percentage": 90, "date": "2024-01-03T10:00:00.000Z"}
          }
        ''';
        when(() => mockPrefs.getString(any())).thenReturn(jsonData);

        final recent = repository.getRecentQuizzes('la', limit: 2);

        expect(recent, hasLength(2));
        expect(recent.first['percentage'], 90); // Most recent first
        expect(recent.last['percentage'], 85);
      });
    });
  });
}