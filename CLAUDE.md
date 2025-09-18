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


## Configuration Files

- `pubspec.yaml` - Dependencies configured for Flutter 3.35.0+, Dart 3.9.0+
- `analysis_options.yaml` - Strict linting with `very_good_analysis`
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
- Use ConsumerWidget for all widgets that read providers
- Implement accessibility-first design with proper semantic labels and contrast
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

## TestFlight Troubleshooting Guide

### Common Issue: Builds Not Appearing in TestFlight

**Root Cause**: When you distribute a build to the App Store (production), Apple prevents new TestFlight builds with the same version number.

**Symptoms**:
- Fastlane upload completes successfully (no errors)
- Long upload times (7+ minutes for small apps)
- `fastlane test_auth` works fine
- Latest build number missing from TestFlight
- No processing indication in App Store Connect

**Solution**: Increment the version number in `pubspec.yaml`, not just the build number.

```bash
# Before (causes issues if 1.0.0 was distributed to App Store)
version: 1.0.0+31

# After (allows new TestFlight builds)
version: 1.0.1+1  # Can restart build numbers with new versions
```

### Version vs Build Number Management

**Key Insight**: Apple tracks build numbers per version. Each version can have its own sequence:
- Version 1.0.0: builds 1-31
- Version 1.0.1: builds 1-N (fresh start)
- Version 1.0.2: builds 1-N (fresh start)

**Fastlane Build Number Behavior**:
- `increment_build_number` ignores `Info.plist` `CFBundleVersion`
- Uses `CURRENT_PROJECT_VERSION` from `Runner.xcodeproj/project.pbxproj`
- Auto-increments from existing project value, not pubspec.yaml

**Files to Update for Version Changes**:
1. `pubspec.yaml`: `version: X.Y.Z+N`
2. `ios/Runner/Info.plist`: `CFBundleVersion` (optional - Fastlane overrides)
3. `ios/Runner.xcodeproj/project.pbxproj`: `CURRENT_PROJECT_VERSION` (controls Fastlane)

### Debugging TestFlight Issues

**Quick Diagnostics**:
```bash
# Test authentication (should show latest successful build)
cd ios && fastlane test_auth

# Check recent build logs
tail -50 /Users/ryan/Library/Logs/gym/Runner-Runner.log

# Check upload timing (in ios/fastlane/report.xml)
# Normal: <60 seconds, Problem: >300 seconds
```

**Version Conflict Indicators**:
- Upload succeeds but takes 7+ minutes
- No error messages from Fastlane
- No "Processing" status in App Store Connect
- Build numbers increment in `Info.plist` but builds don't appear

### API Key Authentication Notes

**Current Setup (Working)**:
- API Key file: `~/.appstoreconnect/private/AuthKey_XGFA878VQB.p8`
- Fastlane properly handles `.p8` files via `app_store_connect_api_key` action
- Direct `pilot` commands fail (expect JSON format)
- Use Fastlane lanes, not direct pilot commands

**Environment Variables** (for reference, not currently needed):
```bash
# Fastlane's default environment variable names
export APP_STORE_CONNECT_API_KEY_KEY_ID="XGFA878VQB"
export APP_STORE_CONNECT_API_KEY_ISSUER_ID="69a6de83-1bd1-47e3-e053-5b8c7c11a4d1"
export APP_STORE_CONNECT_API_KEY_KEY="$(cat ~/.appstoreconnect/private/AuthKey_XGFA878VQB.p8)"
```

### Apple's TestFlight Processing Delays (2024-2025)

**Known Issues**:
- Apple's servers experience regular delays
- Builds can be stuck "Processing" for hours or days
- First builds for an app take ~24 hours
- Subsequent builds: minutes to hours (unpredictable)

**Workarounds**:
- Upload builds early to account for delays
- Check email for rejection notifications (not always shown in web interface)
- Use Transporter app for detailed build status
- Wait 24-48 hours before assuming upload failed