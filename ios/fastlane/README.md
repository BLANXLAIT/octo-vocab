fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios create_bundle_id

```sh
[bundle exec] fastlane ios create_bundle_id
```

Create bundle identifier on Apple Developer Portal

### ios create_app

```sh
[bundle exec] fastlane ios create_app
```

Create app on App Store Connect and Developer Portal

### ios sync_certificates

```sh
[bundle exec] fastlane ios sync_certificates
```

Sync certificates and provisioning profiles using match

### ios build

```sh
[bundle exec] fastlane ios build
```

Build the iOS app

### ios build_only

```sh
[bundle exec] fastlane ios build_only
```

Build app for distribution

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Deploy to TestFlight for beta testing

### ios release

```sh
[bundle exec] fastlane ios release
```

Deploy to App Store for production release

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Generate App Store screenshots

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Generate and upload App Store screenshots

### ios upload_existing_screenshots

```sh
[bundle exec] fastlane ios upload_existing_screenshots
```

Upload existing screenshots to App Store Connect

### ios update_metadata

```sh
[bundle exec] fastlane ios update_metadata
```

Update App Store metadata and screenshots

### ios update_store_assets

```sh
[bundle exec] fastlane ios update_store_assets
```

Generate screenshots and update metadata

### ios setup

```sh
[bundle exec] fastlane ios setup
```

Setup: Create app and sync certificates (run once)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
