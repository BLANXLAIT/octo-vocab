# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **template repository** for Flutter/Firebase SaaS applications featuring streaming authentication, real-time data patterns, and Riverpod state management with code generation. This is NOT a regular Flutter project - it's designed to be used as a GitHub template.

## Essential Commands

### Setup & Dependencies
```bash
# Install dependencies
flutter pub get

# Activate Firebase CLI
dart pub global activate flutterfire_cli

# Configure Firebase for new projects
flutterfire configure

# Initialize Firebase Functions (TypeScript)
firebase init functions
# Select TypeScript when prompted
# Install dependencies: cd functions && npm install

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
**Always use the Dart MCP server for running tests** instead of terminal commands:
- Use the `mcp__ide__executeCode` tool for running tests
- The Dart MCP server provides better integration and output handling
- Test organization follows `dart_test.yaml` configuration:
  - Unit tests: `test/unit/**_test.dart`
  - Widget tests: `test/widget/**_test.dart` 
  - Integration tests: `test/integration/**_test.dart`

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

### Firebase Functions (TypeScript)
```bash
# Deploy functions
firebase deploy --only functions

# Run functions locally
cd functions && npm run serve

# Build TypeScript functions
cd functions && npm run build

# Run functions shell for testing
cd functions && npm run shell
```

## Architecture & Key Patterns

### State Management with Riverpod
Always use Riverpod with code generation (`@riverpod` annotation). Generated providers automatically get `.g.dart` suffix.

### Streaming Authentication Pattern
Use Firebase auth streams for real-time authentication state. All Firebase operations should default to streams for real-time updates.

### SaaS-Specific Patterns
- Multi-tenant organization access with streaming permissions
- Subscription & billing status streams
- Real-time usage metrics
- TypeScript Firebase Functions for backend logic (user provisioning, webhooks, notifications)

### Code Generation Files
- `lib/**/*.g.dart` - Riverpod providers and JSON serialization
- `lib/**/*.freezed.dart` - Immutable data classes
- These files are excluded from analysis and git

## Configuration Files

- `pubspec.yaml` - Dependencies configured for Flutter 3.35.0+, Dart 3.9.0+
- `analysis_options.yaml` - Strict linting with `very_good_analysis`, excludes generated files
- `build.yaml` - Code generation configuration for Riverpod and JSON
- `dart_test.yaml` - Test runner with organized test sets (unit/widget/integration) and coverage exclusions
- `.github/copilot-instructions.md` - Comprehensive development patterns and SaaS architecture guidance

## Important Notes

- This is a template repository - use "Use this template" on GitHub rather than cloning directly
- Always run code generation after modifying annotated classes
- Follow streaming patterns for all Firebase operations
- Use ConsumerWidget for all widgets that read providers
- Implement accessibility-first design with proper semantic labels and contrast
- Generated files are excluded from version control and static analysis