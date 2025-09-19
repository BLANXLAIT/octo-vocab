# GitHub Copilot Instructions for Octo Vocab

## Project Overview
Octo Vocab is a privacy-first offline vocabulary learning app for students in grades 7-12 learning foreign languages. Built with Flutter and Riverpod, it emphasizes educational excellence and user privacy by being completely offline with no user login or data collection.

## Architecture Principles

### Privacy-First Offline Design
- **100% Offline** - No internet connection required after installation
- **No User Accounts** - No login or registration needed
- **Zero Data Collection** - No analytics, tracking, or data harvesting
- **COPPA/FERPA Compliant** - Safe for educational use

### State Management with Riverpod
Use Riverpod with proper reactive patterns:

```dart
// ✅ Good: Reactive provider that watches dependencies
@riverpod
class LanguageStateNotifier extends StateNotifier<String> {
  LanguageStateNotifier(this.dataService) : super('la');

  Future<void> setLanguage(String code) async {
    state = code;
    await dataService.saveAppSettings({'selectedLanguage': code});
  }
}

// ✅ Good: Provider that watches other providers reactively
final vocabularyProvider = FutureProvider.autoDispose<List<VocabularyItem>>((ref) async {
  final selectedLanguage = ref.watch(selectedLanguageProvider);
  final level = ref.watch(vocabularyLevelProvider);
  return registry.loadVocabulary(selectedLanguage, level);
});
```

### Educational Patterns

#### Multi-Language Support
Support multiple languages with plugin architecture:

```dart
// Language-specific plugins for formatting and behavior
abstract class LanguagePlugin {
  Language get language;
  String formatTerm(VocabularyItem item);
  String formatExample(VocabularyItem item);
  String getProgressKey(String itemId);
}

// Registry manages available languages
class LanguageRegistry {
  void register(LanguagePlugin plugin);
  List<Language> getAvailableLanguages();
}
```

#### Learning Progress Tracking
Track student progress locally without data collection:

```dart
// Store progress in SharedPreferences
final wordProgressProvider = FutureProvider<Map<String, String>>((ref) async {
  final dataService = await ref.watch(localDataServiceProvider.future);
  return dataService.getWordProgress();
});

// Filter vocabulary based on learning progress
final learningQueueProvider = FutureProvider.autoDispose<List<VocabularyItem>>((ref) async {
  final vocabulary = await ref.watch(vocabularyProvider.future);
  final progress = await ref.watch(wordProgressProvider.future);

  return vocabulary.where((item) {
    final status = progress[item.id];
    return status != 'known' && status != 'mastered';
  }).toList();
});
```

### Data Persistence Patterns

#### SharedPreferences for Local Storage
All data is stored locally using SharedPreferences:

```dart
class LocalDataService {
  final SharedPreferences _prefs;

  // App settings (language, quiz length, etc.)
  Map<String, dynamic> getAppSettings() =>
    json.decode(_prefs.getString('appSettings') ?? '{}');

  // Word progress tracking
  Map<String, String> getWordProgress() =>
    json.decode(_prefs.getString('wordProgress') ?? '{}');
}
```

#### Asset-Based Vocabulary Loading
Vocabulary data is stored as JSON assets:

```dart
// Load vocabulary from assets based on language and level
Future<List<VocabularyItem>> loadVocabulary(String language, VocabularyLevel level) {
  final assetPath = 'assets/vocab/$language/${level.name}/set1.json';
  return rootBundle.loadString(assetPath)
    .then((json) => VocabularyItem.listFromJsonString(json));
}
```

### UI/UX Patterns

#### Learning Modes
Implement different study modes with consistent state management:

```dart
// Flashcards with swipe gestures
class FlashcardsScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabulary = ref.watch(learningQueueProvider);
    // CardSwiper with proper state management
  }
}

// Quiz with multiple choice
class QuizScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final vocabulary = ref.watch(quizVocabularyProvider);
    // Quiz logic with proper answer tracking
  }
}
```

#### Accessibility
Always implement proper accessibility for educational apps:

```dart
Semantics(
  label: 'Quiz length selector',
  hint: 'Tap to change quiz length. Currently set to ${currentLength.displayName}',
  button: true,
  child: PopupMenuButton<QuizLength>(...),
)
```

## Development Guidelines

### Testing Strategy
- Unit tests for core models and business logic
- Widget tests for UI components
- Integration tests for complete user journeys
- NO network-dependent tests (offline app)

### File Organization
```
lib/
├── core/
│   ├── language/          # Language plugins and registry
│   ├── models/           # Data models
│   ├── services/         # Local data services
│   └── providers/        # Shared providers
├── features/
│   ├── flashcards/       # Flashcard study mode
│   ├── quiz/            # Quiz mode
│   ├── review/          # Review system
│   └── progress/        # Progress tracking
└── main.dart
```

### Code Quality
- Use `very_good_analysis` for strict linting
- Maintain ~80%+ test coverage
- Follow material design principles
- Prioritize accessibility and educational best practices

## Educational Considerations

### Target Audience
- **Students**: Grades 7-12 (ages 12-18)
- **Educators**: Teachers looking for classroom-ready tools
- **Parents**: Supporting student learning at home

### Learning Science Integration
- Implement spaced repetition algorithms
- Track learning metrics locally
- Provide immediate feedback
- Support different learning styles (visual, auditory, kinesthetic)

### Privacy Compliance
- COPPA compliant (no data collection from minors)
- FERPA compliant (educational privacy)
- GDPR compliant (privacy by design)
- Transparent about offline-first approach