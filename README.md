# Octo Vocab

[![CI](https://github.com/BLANXLAIT/octo-vocab/actions/workflows/ci.yml/badge.svg)](https://github.com/BLANXLAIT/octo-vocab/actions/workflows/ci.yml)
[![Test Status](https://github.com/BLANXLAIT/octo-vocab/actions/workflows/test-status.yml/badge.svg)](https://github.com/BLANXLAIT/octo-vocab/actions/workflows/test-status.yml)
[![Privacy Compliance](https://img.shields.io/badge/Privacy-COPPA%2FFERPA%2FGDPR-green?logo=shield&logoColor=white)](https://github.com/BLANXLAIT/octo-vocab/actions/workflows/test-status.yml)
[![codecov](https://codecov.io/gh/BLANXLAIT/octo-vocab/branch/main/graph/badge.svg)](https://codecov.io/gh/BLANXLAIT/octo-vocab)
[![Tests](https://img.shields.io/badge/Tests-26%20Passing-brightgreen?logo=checkmarx&logoColor=white)](https://github.com/BLANXLAIT/octo-vocab/actions/workflows/test-status.yml)

[![Flutter](https://img.shields.io/badge/Flutter-3.35.0-blue?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.9.0-blue?logo=dart&logoColor=white)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey?logo=flutter&logoColor=white)](https://github.com/BLANXLAIT/octo-vocab)
[![Offline](https://img.shields.io/badge/100%25-Offline-green?logo=airplane&logoColor=white)](README.md#privacy-first-design)
[![Education](https://img.shields.io/badge/Education-Grades%207--12-orange?logo=graduation-cap&logoColor=white)](README.md#target-audience)

A privacy-first offline vocabulary learning app designed for students in grades 7-12 learning foreign languages. Built with Flutter, Octo Vocab emphasizes educational excellence and user privacy by being completely offline with no user login or data collection.

## 📚 Language Learning Made Simple

Octo Vocab currently supports **Latin** and **Spanish** with comprehensive vocabulary sets aligned to ACTFL standards and K-12 educational progression. More languages are planned for future releases.

### 🎯 Target Audience
- **Students**: Grades 7-12 (ages 12-18)
- **Educators**: Teachers looking for classroom-ready vocabulary tools
- **Parents**: Supporting student language learning at home
- **Self-Learners**: Anyone wanting to master classical and modern languages

## ✨ Key Features

### 🔐 Privacy-First Design
- **100% Offline** - No internet connection required after installation
- **No User Accounts** - No login or registration needed
- **Zero Data Collection** - No analytics, tracking, or data harvesting
- **COPPA/FERPA Compliant** - Safe for educational use

### 📖 Comprehensive Learning Modes
- **Flashcards** - Traditional spaced repetition study mode
- **Quiz** - Multiple-choice vocabulary testing
- **Review** - Intelligent review system for difficult words
- **Progress Tracking** - Visual progress analytics per language

### 🏫 Educational Excellence
- **ACTFL Standards Aligned** - Professional language learning standards
- **Grade-Level Appropriate** - Content tailored to student developmental stages
- **Multi-Difficulty Levels**:
  - **Beginner** (Grades 7-8): Essential words and phrases
  - **Intermediate** (Grades 9-10): Common vocabulary and grammar
  - **Advanced** (Grades 11-12): Complex texts and literature

### 📱 Modern User Experience
- **Adaptive Design** - Optimized for both phone and tablet
- **Material Design 3** - Clean, intuitive interface
- **Dark/Light Themes** - Comfortable viewing in any environment
- **Accessibility Support** - Screen reader compatible

## 🗣️ Supported Languages

### Latin 📜
**135+ vocabulary words** across all difficulty levels
- **Beginner**: Essentials, Family & Home, Basic Verbs (60 words)
- **Intermediate**: Verbs & Actions, Adjectives & Descriptions (50 words)  
- **Advanced**: Literature & Rhetoric (25 words)

### Spanish 🇪🇸
**90+ vocabulary words** across all difficulty levels
- **Beginner**: Essentials, Family & Home (40 words)
- **Intermediate**: Daily Activities (25 words)
- **Advanced**: Abstract Concepts (25 words)

## 🚀 Getting Started

### Prerequisites
- Flutter 3.35.0 or higher
- Dart 3.9.0 or higher
- iOS 12.0+ or Android 6.0+

### Installation for Development

```bash
# Clone the repository
git clone https://github.com/BLANXLAIT/octo-vocab.git
cd octo-vocab

# Install dependencies
flutter pub get

# Generate code (Riverpod providers, Freezed classes, JSON serialization)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run
```

### 🏗️ Code Generation
This project uses code generation extensively. Always run after modifying annotated classes:

```bash
# One-time generation
dart run build_runner build --delete-conflicting-outputs

# Watch mode for development
dart run build_runner watch --delete-conflicting-outputs
```

## 🧪 Testing

The project includes comprehensive testing infrastructure:

```bash
# Full test suite with coverage and HTML reports
./scripts/test.sh all --coverage --html

# Unit tests only
./scripts/test.sh unit --coverage

# Widget tests only
./scripts/test.sh widget

# Quick test (development)
./scripts/test-quick.sh

# View coverage report
open coverage/html/index.html
```

**Current Test Coverage**: ~29% (focused on core study configuration system)

## 📱 App Store & Distribution

### Automated Screenshot Generation
The project includes automated screenshot generation for App Store submission:

```bash
# Generate screenshots for all supported devices
fastlane ios screenshots

# Upload screenshots to App Store Connect
fastlane ios upload_existing_screenshots
```

### Build & Release
```bash
# Build for iOS
fastlane ios build

# Deploy to TestFlight
fastlane ios beta

# Deploy to App Store (requires manual review submission)
fastlane ios release
```

## 🏗️ Architecture

### State Management
- **Riverpod** - Type-safe, reactive state management with code generation
- **Provider Pattern** - Clean separation of business logic and UI

### Data Storage
- **Local JSON Assets** - Vocabulary stored in app bundle
- **SharedPreferences** - User preferences and progress tracking
- **No External Dependencies** - Fully offline architecture

### Project Structure
```
lib/
├── core/                    # Core utilities and models
│   ├── language/           # Language selection and management
│   ├── models/             # Data models (Word, LanguageConfig, etc.)
│   ├── navigation/         # Adaptive navigation components
│   └── services/           # Business logic services
├── features/               # Feature-specific UI and logic
│   ├── flashcards/        # Flashcard study mode
│   ├── quiz/              # Quiz functionality
│   ├── progress/          # Progress tracking
│   └── settings/          # App configuration
└── app.dart               # App root and routing

assets/vocab/              # Vocabulary JSON files
├── latin/                 # Latin vocabulary by difficulty
└── spanish/              # Spanish vocabulary by difficulty
```

### Vocabulary Data Format
```json
[
  {
    "id": "sum",
    "latin": "sum",
    "english": "I am",
    "pos": "verb",
    "exampleLatin": "Sum discipulus.",
    "exampleEnglish": "I am a student.",
    "tags": ["beginner", "essentials", "verb", "high-frequency"]
  }
]
```

## 🧪 Testing & Quality Assurance

### Comprehensive Test Suite

Octo Vocab includes a robust testing infrastructure with **26 automated tests** covering all aspects of functionality and privacy compliance:

| Test Type | Count | Coverage | Purpose |
|-----------|-------|----------|---------|
| **Unit Tests** | 14 | Privacy Compliance | COPPA, FERPA, GDPR verification |
| **Widget Tests** | 6 | UI Components | Privacy UI elements & dialogs |
| **Integration Tests** | 6 | End-to-End | Full app workflows & privacy flows |

### Privacy Compliance Testing

Our automated tests specifically verify:

- 🛡️ **COPPA Compliance** - No personal information collection from minors
- 🏫 **FERPA Compliance** - Educational records remain on-device only  
- 🇪🇺 **GDPR Compliance** - Right to data export and erasure
- 📱 **Offline-First** - No network requests during operation
- 🔒 **Data Security** - Local storage only, no external services

### Running Tests

```bash
# Run all tests with coverage
./scripts/test.sh all --coverage --html

# Run specific test suites
./scripts/test.sh unit              # Unit tests
./scripts/test.sh widget            # Widget tests  
./scripts/test.sh integration       # Integration tests
./scripts/test.sh privacy           # Privacy compliance tests

# View HTML coverage report
open coverage/html/index.html
```

### Continuous Integration

- ✅ **Automated Testing** - All PRs run full test suite
- 🔍 **Code Quality** - Formatting, analysis, and linting
- 🛡️ **Security Scans** - Dependency vulnerabilities and hardcoded secrets
- 🏗️ **Build Verification** - iOS and Android build validation
- 📊 **Coverage Reports** - Detailed test coverage analytics

The test suite ensures educational privacy standards are maintained throughout development while providing confidence in app reliability.

## 🤝 Contributing

We welcome contributions! Please see our contribution guidelines:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Run tests** (`./scripts/test.sh all`)
4. **Follow the existing code patterns** (see `.github/copilot-instructions.md`)
5. **Commit your changes** (`git commit -m 'Add amazing feature'`)
6. **Push to the branch** (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

### Adding New Vocabulary
To add vocabulary for existing languages:
1. Add words to appropriate JSON files in `assets/vocab/[language]/[level]/`
2. Update `VocabularySets` in `lib/core/models/vocabulary_level.dart`
3. Run code generation: `dart run build_runner build --delete-conflicting-outputs`
4. Test thoroughly with widget and integration tests

### Adding New Languages
1. Create directory structure: `assets/vocab/[language]/beginner/`
2. Add language to `AppLanguage` enum in `lib/core/language/language.dart`
3. Create vocabulary JSON files following existing format
4. Update vocabulary sets configuration
5. Add appropriate tests

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **ACTFL** - For language proficiency standards
- **Material Design Team** - For design system guidance
- **Flutter Community** - For amazing framework and packages
- **Educational Consultants** - For pedagogical insights

## 📞 Support

For support, questions, or feature requests:
- **Issues**: [GitHub Issues](https://github.com/BLANXLAIT/octo-vocab/issues)
- **Discussions**: [GitHub Discussions](https://github.com/BLANXLAIT/octo-vocab/discussions)

## 🔮 Roadmap

### Upcoming Features
- [ ] **French** vocabulary sets
- [ ] **German** vocabulary sets  
- [ ] **Advanced spaced repetition algorithm**
- [ ] **Vocabulary import/export**
- [ ] **Study streak tracking**
- [ ] **Offline voice pronunciation**

### Long-term Goals
- [ ] **Community vocabulary contributions**
- [ ] **Teacher classroom management tools**
- [ ] **Advanced analytics and reporting**
- [ ] **Integration with educational platforms**

---

**Octo Vocab** - Making language learning accessible, private, and effective for students worldwide. 🌍📚