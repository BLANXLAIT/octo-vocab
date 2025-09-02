# App Store Screenshots Setup

This guide explains how to set up and use automated screenshot generation for Octo Vocab.

## Prerequisites

⚠️ **Important**: You need to complete the Xcode setup before screenshots will work.

## Required Xcode Setup

1. **Add UI Test Target to Xcode:**
   - Open `Runner.xcworkspace` in Xcode
   - File → New → Target → iOS UI Testing Bundle
   - Name it "RunnerUITests"

2. **Add Files to UI Test Target:**
   - Add `RunnerUITests/RunnerUITests.swift` to the UI test target
   - Add `RunnerUITests/SnapshotHelper.swift` to the UI test target

3. **Create Shared Scheme:**
   - Product → Scheme → Edit Scheme
   - Check "Shared" box for the RunnerUITests scheme
   - Ensure the scheme is saved

4. **Configure Build Settings:**
   - Select RunnerUITests target
   - Build Settings → Test Host should point to the Runner app

## Screenshot Generation

### Generate Screenshots Only
```bash
fastlane ios screenshots
```

### Generate Screenshots + Upload to App Store
```bash
fastlane ios update_store_assets
```

### Update Metadata Only (No Screenshots)
```bash
fastlane ios update_metadata
```

## Configuration

### Device Coverage
Screenshots are generated for all required App Store device sizes:
- iPhone 15 Pro Max (6.7")
- iPhone 15 (6.1")
- iPhone SE (4.7")
- iPad Pro 12.9" (12.9")
- iPad Pro 11" (11")

### Languages
- English (en-US)

### Output Location
- Local: `./fastlane/screenshots/`
- Uploaded to: App Store Connect

## Customizing Screenshots

Edit `RunnerUITests/RunnerUITests.swift` to:
- Navigate through your app's screens
- Add `snapshot("ScreenName")` calls at key moments
- Wait for animations/loading with `sleep(1)` or better UI waits

### Screenshot Tips
- Use descriptive names: `snapshot("01_Launch")`, `snapshot("02_Home")`
- Wait for content to load before capturing
- Ensure consistent UI state (no loading indicators)
- Test on different device sizes

## Current Screenshot Flow

1. **01_Launch** - App launch/splash screen
2. **02_Home** - Main menu/home screen  
3. **03_Latin_Selection** - Language selection
4. **04_Study_Mode** - Flashcards/study interface
5. **05_Quiz_Mode** - Quiz interface
6. **06_Settings** - Settings/preferences

## Troubleshooting

### "Scheme not found" Error
- Ensure RunnerUITests scheme exists and is shared
- Check scheme name matches Snapfile configuration

### "UI Test Failed" Error
- Update UI test navigation to match your actual app flow
- Add proper wait conditions for dynamic content
- Test UI paths manually first

### "Device not available" Error
- Install required simulators in Xcode
- Update device names in Snapfile if needed

## Advanced Features

### Status Bar Cleanup
- Automatically sets time to 9:41 AM
- Shows full battery and signal
- Configured in Snapfile

### Launch Arguments
- `-snapshot_mode true` - App can detect screenshot mode
- `-disable_animations true` - Faster, consistent captures

### Concurrent Generation
- Fastlane runs multiple simulators simultaneously
- Faster screenshot generation across devices