import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_saas_template/core/language/models/vocabulary_item.dart';

void main() {
  group('VocabularyItem', () {
    test('creates a vocabulary item with all fields', () {
      const item = VocabularyItem(
        id: 'amor',
        term: 'amor',
        translation: 'love',
        partOfSpeech: 'noun',
        exampleTerm: 'Amor vincit omnia',
        exampleTranslation: 'Love conquers all',
        tags: ['emotions', 'philosophy'],
        extras: {'gender': 'masculine', 'declension': '3'},
      );

      expect(item.id, equals('amor'));
      expect(item.term, equals('amor'));
      expect(item.translation, equals('love'));
      expect(item.partOfSpeech, equals('noun'));
      expect(item.exampleTerm, equals('Amor vincit omnia'));
      expect(item.exampleTranslation, equals('Love conquers all'));
      expect(item.tags, equals(['emotions', 'philosophy']));
      expect(item.extras, equals({'gender': 'masculine', 'declension': '3'}));
    });

    test('creates a minimal vocabulary item', () {
      const item = VocabularyItem(
        id: 'casa',
        term: 'casa',
        translation: 'house',
      );

      expect(item.id, equals('casa'));
      expect(item.term, equals('casa'));
      expect(item.translation, equals('house'));
      expect(item.partOfSpeech, isNull);
      expect(item.exampleTerm, isNull);
      expect(item.exampleTranslation, isNull);
      expect(item.tags, isEmpty);
      expect(item.extras, isEmpty);
    });

    test('creates from JSON with all fields', () {
      final json = {
        'id': 'veritas',
        'term': 'veritas',
        'translation': 'truth',
        'partOfSpeech': 'noun',
        'exampleTerm': 'Veritas vos liberabit',
        'exampleTranslation': 'The truth will set you free',
        'tags': ['philosophy', 'abstract'],
        'customField': 'customValue',
      };

      final item = VocabularyItem.fromJson(json);

      expect(item.id, equals('veritas'));
      expect(item.term, equals('veritas'));
      expect(item.translation, equals('truth'));
      expect(item.partOfSpeech, equals('noun'));
      expect(item.exampleTerm, equals('Veritas vos liberabit'));
      expect(item.exampleTranslation, equals('The truth will set you free'));
      expect(item.tags, equals(['philosophy', 'abstract']));
      expect(item.extras['customField'], equals('customValue'));
    });

    test('creates from JSON with legacy Word format (latin/english)', () {
      final json = {
        'id': 'pax',
        'latin': 'pax',
        'english': 'peace',
        'pos': 'noun',
        'exampleLatin': 'Pax vobiscum',
        'exampleEnglish': 'Peace be with you',
        'tags': ['greeting', 'religion'],
      };

      final item = VocabularyItem.fromJson(json);

      expect(item.id, equals('pax'));
      expect(item.term, equals('pax'));
      expect(item.translation, equals('peace'));
      expect(item.partOfSpeech, equals('noun'));
      expect(item.exampleTerm, equals('Pax vobiscum'));
      expect(item.exampleTranslation, equals('Peace be with you'));
      expect(item.tags, equals(['greeting', 'religion']));
    });

    test('creates from JSON with missing fields', () {
      final json = {
        'latin': 'sol',
        'english': 'sun',
      };

      final item = VocabularyItem.fromJson(json);

      expect(item.id, equals('sol'));
      expect(item.term, equals('sol'));
      expect(item.translation, equals('sun'));
      expect(item.partOfSpeech, isNull);
      expect(item.tags, isEmpty);
      expect(item.extras, isEmpty);
    });

    test('converts to JSON correctly', () {
      const item = VocabularyItem(
        id: 'luna',
        term: 'luna',
        translation: 'moon',
        partOfSpeech: 'noun',
        exampleTerm: 'Luna plena',
        exampleTranslation: 'Full moon',
        tags: ['astronomy'],
        extras: {'gender': 'feminine'},
      );

      final json = item.toJson();

      expect(json['id'], equals('luna'));
      expect(json['term'], equals('luna'));
      expect(json['translation'], equals('moon'));
      expect(json['partOfSpeech'], equals('noun'));
      expect(json['exampleTerm'], equals('Luna plena'));
      expect(json['exampleTranslation'], equals('Full moon'));
      expect(json['tags'], equals(['astronomy']));
      expect(json['gender'], equals('feminine'));
    });

    test('loads list from JSON string', () {
      const jsonString = '''
      [
        {
          "id": "vita",
          "term": "vita",
          "translation": "life",
          "partOfSpeech": "noun"
        },
        {
          "id": "mors",
          "term": "mors",
          "translation": "death",
          "partOfSpeech": "noun"
        }
      ]
      ''';

      final items = VocabularyItem.listFromJsonString(jsonString);

      expect(items, hasLength(2));
      expect(items[0].id, equals('vita'));
      expect(items[0].translation, equals('life'));
      expect(items[1].id, equals('mors'));
      expect(items[1].translation, equals('death'));
    });

    test('equality works correctly', () {
      const item1 = VocabularyItem(id: 'test', term: 'test', translation: 'test');
      const item2 = VocabularyItem(id: 'test', term: 'test', translation: 'test');
      const item3 = VocabularyItem(id: 'other', term: 'other', translation: 'other');

      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
      expect(item1.hashCode, equals(item2.hashCode));
      expect(item1.hashCode, isNot(equals(item3.hashCode)));
    });

    test('toString works correctly', () {
      const item = VocabularyItem(
        id: 'amor',
        term: 'amor',
        translation: 'love',
      );

      expect(item.toString(), equals('VocabularyItem(id: amor, term: amor, translation: love)'));
    });
  });
}