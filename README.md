# Flutter/Firebase SaaS Template

A modern Flutter/Firebase SaaS template using streaming authentication and real-time data patterns with Riverpod state management.

## Setup & Initialization

### Dart MCP Server
Ensure the Dart VS Code extension is installed for enhanced AI context. The MCP server activates automatically when you open a Dart project and provides enhanced AI context for development.

### Project Initialization

```bash
# Use GitHub template to create your repository
# Click "Use this template" on GitHub
# Clone your new repository
git clone https://github.com/yourusername/your-saas-app.git
cd your-saas-app

# Install dependencies from pubspec.yaml
flutter pub get

# Configure Firebase
dart pub global activate flutterfire_cli
flutterfire configure
```

## Features

- **Streaming Authentication** - Real-time auth state updates
- **Riverpod State Management** - With code generation for clean providers
- **Firebase Integration** - Auth, Firestore with streaming patterns
- **Go Router Navigation** - Declarative routing
- **AI-Assisted Development** - Optimized for GitHub Copilot

## Getting Started

1. Install the Dart VS Code extension for enhanced AI context
2. Use this template to create a new repository on GitHub (click "Use this template")
3. Clone your new repository locally
4. Open the project in VS Code
5. **Customize your app identity:**
   - Update `name` in `pubspec.yaml` from `flutter_saas_template` to your app name
   - Update `description` in `pubspec.yaml` 
   - Change bundle ID from `com.example.flutter_saas_template` to your domain (e.g., `com.yourcompany.yourapp`)
6. Run `flutter pub get` to install dependencies
7. Configure Firebase using `flutterfire configure`
8. Follow the architectural patterns in `.github/copilot-instructions.md`
9. Ask AI to help build your SaaS features using the established patterns

## Customizing Your App

After cloning the template, you'll need to customize it for your specific SaaS app:

### App Identity
- **App Name**: Update `name` in `pubspec.yaml` 
- **Description**: Update `description` in `pubspec.yaml`
- **Bundle ID**: Change from `com.example.flutter_saas_template` to your domain
  - iOS: Update in `ios/Runner.xcodeproj/project.pbxproj`
  - Android: Update `applicationId` in `android/app/build.gradle`
  - Or use: `flutter packages pub run change_app_package_name:main com.yourcompany.yourapp`

### Firebase Project
- Run `flutterfire configure` to link your own Firebase project
- This will generate platform-specific Firebase configuration files
- Update Firestore security rules for your app's data structure

This template prioritizes real-time streaming data, clean state management with Riverpod, and AI-assisted development.
