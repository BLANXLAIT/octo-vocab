# iOS Deployment Troubleshooting Guide

## Issue Summary

The iOS deployment GitHub Actions workflow was failing with the error:

```
No profile for team 'GCRLV5UC4Q' matching 'Octo Vocab App Store' found: 
Xcode couldn't find any provisioning profiles matching 'GCRLV5UC4Q/Octo Vocab App Store'.
```

## Root Cause

The workflow was unable to access organization secrets and fastlane match was not properly downloading certificates and provisioning profiles from the shared repository.

## Solution Implemented

### 1. Fixed Organization Secret Access

**Problem**: All organization secrets were empty in the workflow execution.

**Solution**: Added `secrets: inherit` to the `ios_deploy` job to enable access to organization secrets.

```yaml
ios_deploy:
  runs-on: macos-15
  timeout-minutes: 60
  secrets: inherit  # ✅ Added this line
```

### 2. Added Team ID Configuration

**Problem**: Missing `FASTLANE_TEAM_ID` and `FASTLANE_ITC_TEAM_ID` secrets.

**Solution**: Hardcoded the known team ID (`GCRLV5UC4Q`) since it's fixed for the Apple Developer account.

```yaml
env:
  FASTLANE_TEAM_ID: "GCRLV5UC4Q"
  FASTLANE_ITC_TEAM_ID: "GCRLV5UC4Q"
```

### 3. Added Personal Access Token Support

**Problem**: Cannot access private match repository without authentication.

**Solution**: Added support for `MATCH_CERTS_PAT` secret for private repository access.

```ruby
# Fastfile - sync_certificates lane
if ENV["MATCH_CERTS_PAT"]
  git_url = ENV["MATCH_GIT_URL"].gsub('https://github.com/', "https://#{ENV["MATCH_CERTS_PAT"]}@github.com/")
end
```

### 4. Added Fastlane Match Integration

**Problem**: Certificates and provisioning profiles were not being downloaded before build.

**Solution**: Added explicit step to run `fastlane sync_certificates` before building.

```yaml
- name: 🔐 Sync certificates with Match
  working-directory: ios
  run: |
    fastlane sync_certificates
```

### 5. Simplified Build Configuration

**Problem**: Hardcoded certificate and provisioning profile UUIDs were causing conflicts.

**Solution**: Let match handle the provisioning profile selection automatically.

```ruby
# Removed hardcoded UUIDs, now uses:
export_options: {
  method: "app-store",
  teamID: ENV["FASTLANE_TEAM_ID"]
}
```

## Required Organization Secrets

Ensure these secrets are configured in your GitHub organization:

| Secret Name | Purpose | Example |
|-------------|---------|---------|
| `MATCH_PASSWORD` | Encryption password for match certificates | `your-secure-password` |
| `MATCH_GIT_URL` | URL to shared certificates repository | `https://github.com/BLANXLAIT/blanxlait-ci-shared` |
| `MATCH_GIT_BRANCH` | Branch in certificates repository | `main` |
| `MATCH_CERTS_PAT` | Personal Access Token for private repo | `ghp_xxxxxxxxxxxx` |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API Key ID | `ABC123DEF4` |
| `APP_STORE_CONNECT_ISSUER_ID` | App Store Connect Issuer ID | `12345678-1234-1234-1234-123456789012` |
| `APP_STORE_CONNECT_API_KEY` | Base64-encoded API key file | `LS0tLS1CRUdJTi...` |
| `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD` | App-specific password | `abcd-efgh-ijkl-mnop` |

## Testing the Fix

You can test the deployment using manual workflow dispatch:

1. Go to **Actions** → **iOS App Store Deployment**
2. Click **Run workflow**
3. Select `deployment_target: beta`
4. Click **Run workflow**

## Expected Workflow Steps

The workflow should now:

1. ✅ Access organization secrets successfully
2. ✅ Validate all required secrets are available  
3. ✅ Configure App Store Connect API authentication
4. ✅ Download certificates and provisioning profiles via fastlane match
5. ✅ Build the iOS app with proper code signing
6. ✅ Upload to TestFlight

## Troubleshooting

If the workflow still fails:

1. **Check secret validation step**: Ensure all required secrets are available
2. **Check match authentication**: Verify `MATCH_CERTS_PAT` has access to the private repository
3. **Check certificates repository**: Ensure `blanxlait-ci-shared` contains valid certificates
4. **Check App Store Connect API**: Verify API key has proper permissions

## Files Modified

- `.github/workflows/ios-deploy.yml` - Added secret access and validation
- `ios/fastlane/Fastfile` - Updated match integration and build configuration  
- `ios/fastlane/Matchfile` - Made repository configuration dynamic
- `docs/ios-deployment-troubleshooting.md` - This documentation

## Next Steps

After successful deployment, consider:

1. Setting up automated releases on version tags
2. Adding notification webhooks for deployment status
3. Implementing staged rollouts for production releases