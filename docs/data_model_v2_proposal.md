# Data Model V2: Scalable Architecture Proposal

## Current vs Proposed Storage

### Current (Good for <= 500 words)
```
SharedPreferences {
  "word_progress": "{la_amor: known, la_vita: difficult, ...}" // Single giant JSON
  "quiz_results": "{quiz_la_123: {...}, quiz_es_456: {...}}"   // Single giant JSON
  "study_sessions": "[2024-01-15, 2024-01-16, ...]"          // Single array
}
```

### Proposed (Scalable for 10,000+ words)
```
SQLite Database {
  progress_table(language, word_id, status, updated_at)
  quiz_results_table(id, language, score, timestamp, metadata)
  study_sessions_table(date, language, duration, words_studied)
  app_settings_table(key, value)  // Keep simple settings in SharedPrefs
}
```

## Benefits of Migration

### 1. Selective Data Loading
```dart
// Current: Load ALL progress data
Map<String, String> getAllProgress() // Loads everything

// Proposed: Load only what's needed
Future<Map<String, String>> getProgressByLanguage(String lang)
Future<String?> getWordProgress(String lang, String wordId)
```

### 2. Efficient Updates
```dart
// Current: Read all, modify, write all
final allProgress = getWordProgress();
allProgress['la_amor'] = 'known';
setWordProgress(allProgress); // Rewrites entire JSON

// Proposed: Targeted updates
await updateWordProgress('la', 'amor', 'known'); // Single row update
```

### 3. Advanced Queries
```sql
-- Find words that need review
SELECT word_id FROM progress
WHERE language = 'la' AND status = 'difficult'
ORDER BY updated_at ASC;

-- Calculate language-specific statistics
SELECT status, COUNT(*) FROM progress
WHERE language = 'la' GROUP BY status;

-- Find study patterns
SELECT date, COUNT(*) FROM study_sessions
WHERE date >= date('now', '-30 days')
GROUP BY date;
```

## Migration Strategy

### Phase 1: Backwards Compatible
- Add SQLite alongside SharedPreferences
- Write to both systems during transition
- Read from SharedPreferences first, fallback to SQLite

### Phase 2: Gradual Migration
- Implement data migration on app startup
- Move user data from SharedPreferences to SQLite
- Keep SharedPreferences for simple settings only

### Phase 3: Full Migration
- Remove SharedPreferences for complex data
- SQLite becomes primary storage
- Maintain privacy-first local-only approach

## Implementation Plan

### 1. Database Schema
```sql
CREATE TABLE word_progress (
  language TEXT NOT NULL,
  word_id TEXT NOT NULL,
  status TEXT NOT NULL,
  updated_at INTEGER NOT NULL,
  review_count INTEGER DEFAULT 0,
  PRIMARY KEY (language, word_id)
);

CREATE TABLE quiz_results (
  id TEXT PRIMARY KEY,
  language TEXT NOT NULL,
  score INTEGER NOT NULL,
  total_questions INTEGER NOT NULL,
  percentage INTEGER NOT NULL,
  timestamp INTEGER NOT NULL,
  duration_seconds INTEGER,
  metadata TEXT -- JSON for additional data
);

CREATE TABLE study_sessions (
  date TEXT PRIMARY KEY, -- 'YYYY-MM-DD' format
  languages_studied TEXT, -- JSON array of languages
  total_duration INTEGER,
  words_learned INTEGER,
  created_at INTEGER NOT NULL
);

CREATE INDEX idx_progress_language ON word_progress(language);
CREATE INDEX idx_progress_status ON word_progress(status);
CREATE INDEX idx_quiz_language ON quiz_results(language);
CREATE INDEX idx_quiz_timestamp ON quiz_results(timestamp);
```

### 2. Service Layer
```dart
abstract class DataStorage {
  Future<String?> getWordProgress(String language, String wordId);
  Future<void> setWordProgress(String language, String wordId, String status);
  Future<Map<String, String>> getProgressByLanguage(String language);
  Future<List<QuizResult>> getQuizResults(String language, {int? limit});
  Future<void> saveQuizResult(QuizResult result);
  Future<List<DateTime>> getStudySessions({int? days});
  Future<void> recordStudySession();
}

class SQLiteDataStorage implements DataStorage {
  // Efficient, scalable implementation
}

class SharedPreferencesDataStorage implements DataStorage {
  // Legacy implementation for backwards compatibility
}
```

### 3. Performance Benefits
- **Memory**: Load only current language data
- **Speed**: Indexed queries vs full JSON parsing
- **Storage**: Efficient binary storage vs JSON strings
- **Scalability**: Handles 10,000+ words efficiently

## Privacy Considerations

### Maintaining Privacy-First Approach
- SQLite database stored locally only
- No cloud sync or external dependencies
- Same privacy guarantees as current SharedPreferences
- User can still clear all data instantly

### COPPA/FERPA Compliance
- No changes to privacy model
- All data remains on-device
- No personal identifiers stored
- Learning analytics stay local

## Vocabulary Asset Optimization

### Current Asset Loading
```dart
// Loads all vocabulary synchronously
final vocabulary = await rootBundle.loadString(assetPath);
final items = VocabularyItem.listFromJsonString(vocabulary);
```

### Proposed: Lazy Loading + Caching
```dart
class VocabularyCache {
  final Map<String, List<VocabularyItem>> _cache = {};

  Future<List<VocabularyItem>> loadVocabularySet(
    String language,
    VocabularyLevel level,
    String setName,
  ) async {
    final cacheKey = '$language-$level-$setName';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Load asynchronously in background
    final items = await _loadFromAsset(language, level, setName);
    _cache[cacheKey] = items;
    return items;
  }
}
```

## Timeline & Effort

### Small Scale (Current): No changes needed
- Current architecture works fine for 2-3 languages
- 500-1000 words total
- Educational use cases

### Medium Scale (6 months): Hybrid approach
- Add SQLite for progress tracking
- Keep SharedPreferences for settings
- Implement data migration

### Large Scale (1 year): Full optimization
- Complete SQLite migration
- Advanced vocabulary caching
- Performance optimizations

## Recommendation

**For current scope (Latin + Spanish)**: Current architecture is perfectly adequate.

**For future expansion (5+ languages)**: Implement SQLite migration in next major version.

**Immediate improvements we could make:**
1. Add data compression for SharedPreferences JSON
2. Implement vocabulary set lazy loading
3. Add progress data compaction (remove old review sessions)
4. Optimize JSON serialization with more efficient formats