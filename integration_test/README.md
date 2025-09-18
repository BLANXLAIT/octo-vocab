# Integration Tests

This directory contains end-to-end integration tests that verify complete user journeys in the Octo Vocab app.

## Test Structure

### Journey-Based Organization
Tests are organized by user journeys rather than features:

- `flashcard_to_review_journey_test.dart` - Core learning flow from flashcards to review mode
- `helpers/test_helpers.dart` - Shared utilities for all integration tests

### Test Philosophy
Each test follows the **Given/When/Then** pattern with user story format:
```dart
testWidgets('AS a student, I WANT to mark difficult words SO THAT they appear in review', (tester) async {
  // GIVEN: I launch the app
  // WHEN: I swipe left on a flashcard  
  // THEN: The word appears in my review queue
});
```

## Running Integration Tests

### Prerequisites
- Ensure the app builds successfully: `flutter build apk --debug`
- Have an emulator running or device connected

### Run Individual Journey Tests
```bash
# Test the flashcard → review flow specifically
flutter test integration_test/flashcard_to_review_journey_test.dart

# Run with verbose output for debugging
flutter test integration_test/flashcard_to_review_journey_test.dart -v
```

### Run All Integration Tests
```bash
# Run all integration tests
flutter test integration_test/

# Run on specific device
flutter test integration_test/ -d <device_id>
```

### Using Test Driver (Advanced)
```bash
# Run with test driver for more control
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/flashcard_to_review_journey_test.dart
```

## Test Scenarios Covered

### Flashcard → Review Journey
✅ **Happy Path**: Swipe left → word appears in review  
✅ **Known Words**: Swipe right → word does NOT appear in review  
✅ **Multiple Words**: Multiple left swipes → multiple words in review queue  
✅ **Review Completion**: Complete review with difficulty → word rescheduled  
✅ **Data Persistence**: Review progress persists across navigation  
✅ **Empty State**: Helpful guidance when review queue is empty  
✅ **Card Interaction**: Flip card before marking difficulty  
✅ **Rapid Interaction**: App remains responsive during rapid swiping  

## Test Helpers

### Navigation Helpers
```dart
await TestHelpers.navigateToReviewTab(tester);
await TestHelpers.navigateToLearnTab(tester);
```

### Gesture Helpers
```dart
await TestHelpers.swipeFlashcardLeft(tester);   // Mark as difficult
await TestHelpers.swipeFlashcardRight(tester);  // Mark as known
await TestHelpers.tapToFlipFlashcard(tester);   // Flip card
```

### Verification Helpers
```dart
TestHelpers.verifyReviewQueueHasWords();
TestHelpers.verifyEmptyReviewState();
TestHelpers.verifyFeedbackMessage('Will review later');
```

## Debugging Failed Tests

### Common Issues
1. **App not loading**: Increase `waitForAppLoad` timeout
2. **Widget not found**: Use `TestHelpers.debugPrintWidgetTree(tester)`
3. **Timing issues**: Add more `pumpAndSettle` calls
4. **SharedPreferences**: Ensure `setMockInitialValues` is called

### Debug Helpers
```dart
TestHelpers.debugPrintWidgetTree(tester);  // Print all widgets
TestHelpers.debugPrintAllText(tester);     // Print all text content
```

### Verbose Test Output
```bash
flutter test integration_test/flashcard_to_review_journey_test.dart -v
```

## Adding New Journey Tests

### 1. Create New Journey File
```bash
touch integration_test/quiz_completion_journey_test.dart
```

### 2. Use Standard Template
```dart
// quiz_completion_journey_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:octo_vocab/main.dart' as app;
import 'helpers/test_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Quiz Completion Journey Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    testWidgets('AS a student, I WANT to complete quizzes SO THAT my progress is tracked', (tester) async {
      // Test implementation...
    });
  });
}
```

### 3. Add New Helpers as Needed
Add journey-specific helpers to `helpers/test_helpers.dart`.

## Best Practices

### Test Isolation
- Each test starts with clean SharedPreferences
- Use `setUp()` to reset state
- Don't depend on test execution order

### User-Centric Language
- Write tests from user perspective
- Use "AS a student, I WANT..." format
- Focus on behavior, not implementation

### Realistic Timing
- Use `pumpAndSettle()` with reasonable timeouts
- Wait for animations and state changes
- Don't make tests artificially fast

### Clear Assertions
- Use descriptive helper methods
- Verify both positive and negative cases
- Test error states and edge cases

## CI/CD Integration

### GitHub Actions Example
```yaml
- name: Run Integration Tests
  run: |
    flutter test integration_test/ \
      --coverage \
      --test-randomize-ordering-seed random
```

### Parallel Execution
```bash
# Run different journeys in parallel
flutter test integration_test/flashcard_to_review_journey_test.dart &
flutter test integration_test/quiz_completion_journey_test.dart &
wait
```

## Performance Considerations

- Integration tests are slow (~2-5 minutes per journey)
- Run unit/widget tests first in CI
- Use integration tests for critical user paths only
- Consider running on multiple devices/screen sizes

## Troubleshooting

### Test Environment Issues
- **Problem**: `MissingPluginException`
- **Solution**: Ensure proper device/emulator setup

### Widget Finding Issues  
- **Problem**: `findsNothing` when widget should exist
- **Solution**: Check timing, use debug helpers

### SharedPreferences Issues
- **Problem**: Data not persisting between operations
- **Solution**: Verify `setMockInitialValues` is called in `setUp`