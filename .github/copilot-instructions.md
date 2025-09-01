# GitHub Copilot Instructions for Flutter/Firebase SaaS Template

## Project Overview
This is a **template repository** for Flutter/Firebase SaaS applications using streaming authentication and real-time data patterns with Riverpod state management. The codebase emphasizes code generation, strict typing, and AI-assisted development.

## Template Usage
This is NOT a regular Flutter project - it's a GitHub template:
```bash
# Don't create a new Flutter project - use the GitHub template instead
# 1. Click "Use this template" on GitHub
# 2. Clone your new repository
git clone https://github.com/yourusername/your-saas-app.git
cd your-saas-app

# 3. Install dependencies (already configured in pubspec.yaml)
flutter pub get

# 4. Configure Firebase for your project
dart pub global activate flutterfire_cli
flutterfire configure
```

## Core Architecture

### State Management with Riverpod
Always use Riverpod with code generation:

```dart
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  Stream<User?> build() {
    return FirebaseAuth.instance.authStateChanges();
  }
}
```

### Streaming Authentication Pattern
Use Firebase auth streams for real-time authentication state:

```dart
@riverpod
Stream<User?> authState(AuthStateRef ref) {
  return FirebaseAuth.instance.authStateChanges();
}

// UI automatically updates with auth changes
class AuthGate extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (user) => user != null ? DashboardPage() : LoginPage(),
      loading: () => LoadingScreen(),
      error: (error, _) => ErrorScreen(error: error),
    );
  }
}
```

### Firestore Streaming Pattern
Default to streams for all Firestore operations:

```dart
@riverpod
Stream<List<Document>> documents(DocumentsRef ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  
  return FirebaseFirestore.instance
      .collection('documents')
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Document.fromJson(doc.data()))
          .toList());
}
```

## SaaS-Specific Patterns

### Multi-Tenant Organization Access
Stream organization membership and permissions for team-based SaaS:

```dart
@riverpod
Stream<List<Organization>> userOrganizations(UserOrganizationsRef ref) {
  // Stream organizations user belongs to
}

@riverpod  
Stream<UserPermissions> userPermissions(UserPermissionsRef ref) {
  // Stream real-time permissions for current org context
}
```

### Subscription & Billing Streams
Always stream subscription status and usage for SaaS apps:

```dart
@riverpod
Stream<SubscriptionStatus> subscriptionStatus(SubscriptionStatusRef ref) {
  // Stream Stripe subscription status from Firestore
}

@riverpod
Stream<UsageMetrics> usageMetrics(UsageMetricsRef ref) {
  // Stream real-time usage data for billing/limits
}
```

### Firebase Functions Integration (TypeScript)
**Always use TypeScript for Firebase Functions** to ensure type safety and better developer experience.

Standard Firebase Functions setup:
```bash
# Initialize with TypeScript
firebase init functions
# Select TypeScript when prompted

# Project structure:
functions/
├── src/
│   ├── index.ts           # Function exports
│   ├── auth/              # Authentication functions
│   ├── webhooks/          # Stripe/external webhooks
│   ├── notifications/     # Email/push notifications
│   └── utils/             # Shared utilities
├── package.json
├── tsconfig.json
└── .eslintrc.js
```

Core SaaS Functions in TypeScript:
```typescript
// src/auth/onUserCreate.ts
import { auth } from 'firebase-functions/v1';
import { getFirestore } from 'firebase-admin/firestore';

export const onUserCreate = auth.user().onCreate(async (user) => {
  const db = getFirestore();
  
  // Create user profile with default organization
  await db.collection('users').doc(user.uid).set({
    email: user.email,
    createdAt: new Date(),
    organizationId: null,
    role: 'member',
  });
});

// src/webhooks/stripeWebhook.ts
import { https } from 'firebase-functions/v1';
import { StripeWebhookEvent } from '../types/stripe';

export const stripeWebhook = https.onRequest(async (req, res) => {
  const event: StripeWebhookEvent = req.body;
  
  switch (event.type) {
    case 'customer.subscription.created':
      await handleSubscriptionCreated(event.data.object);
      break;
    case 'customer.subscription.updated':
      await handleSubscriptionUpdated(event.data.object);
      break;
  }
  
  res.status(200).send('Webhook processed');
});
```

Key patterns:
- User provisioning on signup with typed data models
- Stripe webhook handling with proper TypeScript interfaces
- Email notifications using SendGrid/Firebase Extensions
- Usage tracking and aggregation with Cloud Firestore
- Organization management with role-based access
- Background job processing for billing and analytics

### Security & Access Control
Implement proper Firestore security rules for multi-tenant access:
- Users can only access their own data
- Organization-based access control
- Role-based permissions within organizations

## Development Guidelines

### Key Patterns
1. **Always use streams** for Firebase data (auth, Firestore)
2. **Use Riverpod code generation** with `@riverpod` annotation
3. **ConsumerWidget** for all widgets that read providers
4. **AsyncValue.guard()** for error handling in async operations
5. **Accessibility-first design** - Include semantic labels, proper contrast, keyboard navigation

### Accessibility Guidelines
Always implement proper accessibility in UI components:
- Use `Semantics` widgets for screen reader support
- Provide meaningful labels with `semanticsLabel`
- Ensure sufficient color contrast (4.5:1 minimum)
- Support keyboard navigation and focus management
- Test with TalkBack/VoiceOver enabled
- Use `MaterialApp.builder` for consistent accessibility theming

### Project Setup
Use the Dart MCP server to initialize project structure and create files:
- Ask the AI to "create a new Flutter project with Riverpod providers"
- The Dart MCP server will use the `create_project` tool to set up appropriate folder structure
- Follow streaming patterns for all data providers

### Development Workflow
**Always use Context7 MCP** to look up recent documentation before beginning development:
- Use Context7 to get latest Flutter, Firebase, and Riverpod documentation
- Check for updated patterns and best practices before implementing features

**Use Dart MCP server** for all development tasks it supports:
- `run_tests` for running unit, widget, and integration tests
- `hot_reload` for applying code changes to running Flutter apps
- `create_project` for setting up new Flutter/Dart projects
- Use Dart MCP server instead of terminal commands when available

**Use Maestro MCP server** for UX testing and app automation:
- Create Maestro flows for testing user journeys and UI interactions
- Test authentication flows, navigation, and key SaaS features
- Automate regression testing of critical user paths
- Validate accessibility and user experience across devices

## Code Generation Workflow
**Critical**: This project relies heavily on code generation. After any changes to `@riverpod`, `@freezed`, or `@JsonSerializable` annotated code:

```bash
# Generate all code (Riverpod providers, Freezed classes, JSON serialization)
dart run build_runner build --delete-conflicting-outputs

# For development with file watching
dart run build_runner watch --delete-conflicting-outputs
```

**Generated files pattern**:
- `lib/**/*.g.dart` - Riverpod providers and JSON serialization
- `lib/**/*.freezed.dart` - Immutable data classes
- These files are excluded from analysis (`analysis_options.yaml`) and git (`.gitignore`)

## Configuration Files Overview
- `pubspec.yaml` - Stable versions for Flutter 3.35.0+, Dart 3.9.0+
- `analysis_options.yaml` - Strict linting with `very_good_analysis`
- `build.yaml` - Code generation configuration for Riverpod and JSON
- `dart_test.yaml` - Test runner configuration with coverage exclusions

This template prioritizes real-time streaming data, clean state management with Riverpod, and AI-assisted development through the Dart MCP server.
