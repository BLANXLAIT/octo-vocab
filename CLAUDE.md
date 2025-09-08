# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Octo Vocab** is a privacy-first offline vocabulary learning app for students in grades 7-12 learning foreign languages. The app emphasizes privacy by being completely offline with no user login or data collection. Currently supports Latin and Spanish with plans for future language expansion.

## Essential Commands

### Setup & Dependencies
```bash
# Install dependencies
flutter pub get

# Add Dart MCP server to Claude Code (for enhanced testing/code execution)
claude mcp add dart -- dart mcp-server
```

### Code Generation (Critical)
This project relies heavily on code generation. Run after any changes to `@riverpod`, `@freezed`, or `@JsonSerializable` annotated code:

```bash
# Generate all code (Riverpod providers, Freezed classes, JSON serialization)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for active development
dart run build_runner watch --delete-conflicting-outputs
```

### Testing
The project includes comprehensive testing infrastructure with automated scripts:

**Pre-commit Testing (ALWAYS RUN BEFORE COMMITTING):**
```bash
# Run all pre-commit checks (formatting, linting, tests, build)
./scripts/pre-commit.sh
```

**Test Scripts:**
```bash
# Full test suite with coverage and HTML reports
./scripts/test.sh all --coverage --html

# Unit tests only
./scripts/test.sh unit --coverage

# Widget tests only  
./scripts/test.sh widget

# Quick test run (no coverage, for development)
./scripts/test-quick.sh
```

**Test Organization:**
- Test configuration: `dart_test.yaml`
- Unit tests: `test/unit/**_test.dart`
- Widget tests: `test/widget/**_test.dart`
- Integration tests: `test/integration/**_test.dart`

**Coverage Reports:**
- Coverage data: `coverage/lcov.info`
- HTML reports: `coverage/html/index.html`
- Current coverage: ~29% (unit tests focused on study configuration system)

### Linting & Analysis
```bash
# Run static analysis
flutter analyze

# Check formatting
dart format --set-exit-if-changed .

# Fix formatting
dart format .
```

### Development
```bash
# Run the app
flutter run

# Hot reload (in development)
# Press 'r' in terminal or use IDE hot reload

# Clean build files
flutter clean
```

### Vocabulary Asset Management
```bash
# Vocabulary data is stored in JSON files in assets/vocab/
# Structure: assets/vocab/{language}/grade8_set1.json
# Currently supported: latin, spanish
# Future expansion will add more languages and grade levels
```

## Architecture & Key Patterns

### State Management with Riverpod
Uses Riverpod for state management with providers for:
- Language selection (`appLanguageProvider`)
- Vocabulary data loading from assets (`vocabSetProvider`, `quizVocabProvider`)
- Quiz/flashcard session state (index, selected answers, results)

### Privacy-First Offline Architecture
- **No authentication** - No user accounts or login system
- **No data collection** - No analytics or user tracking
- **Offline-first** - All vocabulary data stored in app assets
- **Local state only** - User progress and preferences stored locally

### Language Support System
- Enum-based language system (`AppLanguage.latin`, `AppLanguage.spanish`)
- Asset path resolution: `assets/vocab/{language}/grade8_set1.json`
- Language switching with persistent selection
- Extensible for future languages

### Code Generation Files
- `lib/**/*.g.dart` - Riverpod providers and JSON serialization
- `lib/**/*.freezed.dart` - Immutable data classes
- These files are excluded from analysis and git

## Configuration Files

- `pubspec.yaml` - Dependencies configured for Flutter 3.35.0+, Dart 3.9.0+
- `analysis_options.yaml` - Strict linting with `very_good_analysis`, excludes generated files
- `build.yaml` - Code generation configuration for Riverpod and JSON
- `dart_test.yaml` - Test runner with organized test sets (unit/widget/integration) and coverage exclusions
- `.github/copilot-instructions.md` - Comprehensive development patterns and architecture guidance

## App Features & Structure

### Learning Modes
- **Flashcards** (`lib/features/flashcards/`) - Traditional flashcard study mode
- **Quiz** (`lib/features/quiz/`) - Multiple-choice vocabulary quizzes  
- **Review** (`lib/features/review/`) - Spaced repetition review system
- **Progress** (`lib/features/progress/`) - Learning progress tracking

### Core Models
- **Word** (`lib/core/models/word.dart`) - Vocabulary word with foreign/English terms, parts of speech, examples, and tags
- **Language** (`lib/core/language/language.dart`) - Language selection and asset path management

### Target Audience Considerations
- **Ages 12-18** - 7th grade through high school students
- **Educational context** - Designed for classroom and homework use
- **Privacy compliance** - COPPA/FERPA compliant by design (no data collection)
- **Accessibility** - Screen reader support and high contrast for diverse learners

## Important Notes

- Privacy-first design - no network requests, user accounts, or data collection
- Always run code generation after modifying annotated classes
- Use ConsumerWidget for all widgets that read providers
- Implement accessibility-first design with proper semantic labels and contrast
- Generated files are excluded from version control and static analysis
- Vocabulary data stored as JSON assets for offline access

## iOS Deployment & TestFlight Setup

### Environment Configuration

**IMPORTANT: Never use .env files for deployment secrets. Always use ~/.zshrc environment variables for local development.**

#### App Store Connect API Key Setup

**Local Development (Recommended)**: Use JSON file method
1. Create `ios/fastlane/AuthKey_NYY9BJ3V2H.json` with your API key details
2. This file is already configured in the Fastfile and will be used automatically

**Environment Variables (.zshrc)**: Only needed for Match & Fastlane settings
```bash
# Match & Fastlane settings
export FASTLANE_TEAM_ID="[YOUR_TEAM_ID]"
export MATCH_PASSWORD="[YOUR_MATCH_PASSWORD]"
export MATCH_GIT_URL="https://github.com/BLANXLAIT/blanxlait-ci-shared"
export MATCH_CERTS_PAT="[YOUR_GITHUB_PAT]"
```

> **Note:** This follows the official Fastlane recommendations. Local development uses JSON file authentication (most convenient), while CI/CD uses organization-level GitHub secrets. No custom base64 encoding or environment variable handling needed.

#### Local Development Only
**IMPORTANT**: After extensive testing, Fastlane iOS deployments only work locally, not via GitHub Actions.

Organization-level secrets are configured but GitHub Actions automation proved unreliable:
- `APP_STORE_CONNECT_API_KEY_CONTENT`
- `APP_STORE_CONNECT_API_KEY_ID` 
- `APP_STORE_CONNECT_ISSUER_ID`

### iOS Deployment Commands (LOCAL ONLY)
```bash
# Deploy to TestFlight (LOCAL DEVELOPMENT ONLY)
cd ios && fastlane beta

# Deploy to App Store (LOCAL DEVELOPMENT ONLY)
cd ios && fastlane release

# Sync certificates (LOCAL DEVELOPMENT ONLY)
cd ios && fastlane sync_certificates

# Test authentication (LOCAL DEVELOPMENT ONLY)
cd ios && fastlane test_auth
```

### Key Learnings
- ✅ **Local Fastlane works perfectly** with JSON API key files
- ❌ **GitHub Actions automation is unreliable** - removed all deployment workflows  
- ✅ **Organization secrets are configured** but only useful for local development
- 🏠 **Manual deployment process** - run Fastlane locally when ready to deploy