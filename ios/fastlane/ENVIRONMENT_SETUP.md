# Fastlane Environment Setup Guide

This guide explains how to configure your Fastlane environment for both local development and GitHub Actions deployment.

## Overview

The Fastfile has been standardized to use centralized environment configuration that works seamlessly with both:
- **Local Development**: Using system environment variables (`.zshrc`)
- **GitHub Actions**: Using GitHub Secrets for secure CI/CD deployment

## 🔧 Local Development Setup

### Configure Your `.zshrc` File

Add these environment variables to your `~/.zshrc` file:

```bash
# Apple Developer Team Configuration
export FASTLANE_TEAM_ID=YOUR_TEAM_ID
export FASTLANE_ITC_TEAM_ID=YOUR_TEAM_ID

# App Store Connect API Configuration
export APP_STORE_CONNECT_API_KEY_ID=YOUR_API_KEY_ID
export APP_STORE_CONNECT_ISSUER_ID=YOUR_ISSUER_ID
export APP_STORE_CONNECT_API_KEY_PATH="$HOME/.appstoreconnect/private/AuthKey_YOURKEY.p8"

# Match (Certificate Management) Configuration  
export MATCH_PASSWORD=YOUR_MATCH_PASSWORD
export MATCH_GIT_URL="https://github.com/YOUR_ORG/YOUR_MATCH_REPO"
export MATCH_CERTS_PAT="YOUR_GITHUB_PAT"

# Legacy Apple ID Configuration (Optional)
export APPLE_ID="your.email@example.com"
export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=your-app-specific-password
```

### Download App Store Connect API Key

1. Go to [App Store Connect API Keys](https://appstoreconnect.apple.com/access/api)
2. Download your `.p8` key file 
3. Store it at: `~/.appstoreconnect/private/AuthKey_YOURKEY.p8`

After updating `.zshrc`, reload it:
```bash
source ~/.zshrc
```

⚠️ **Security Note**: Your `.zshrc` file stays on your local machine and is never committed to version control.

## 🚀 GitHub Actions Setup

### Quick Setup

Use the provided script to automatically configure all GitHub secrets:

```bash
# Navigate to the fastlane directory
cd ios/fastlane

# Run the setup script (requires GitHub CLI)
./setup-github-secrets.sh
```

This script will:
- Check for required API key files
- Base64 encode the API key automatically
- Set all required secrets in your GitHub repository
- Provide verification steps

### Manual Setup (Alternative)

### Required GitHub Secrets

Configure these secrets in your GitHub repository settings under **Settings > Secrets and variables > Actions**:

#### App Store Connect API Configuration
```
APP_STORE_CONNECT_API_KEY_ID=S9RAGF997L
APP_STORE_CONNECT_ISSUER_ID=69a6de83-1bd1-47e3-e053-5b8c7c11a4d1
APP_STORE_CONNECT_API_KEY=<base64-encoded-p8-key-content>
```

#### Certificate Management (Match)
```
MATCH_PASSWORD=qdPe8fFWewKF2CMfjkn9
MATCH_GIT_URL=https://github.com/BLANXLAIT/ios-certificates.git
MATCH_GIT_BRANCH=main
MATCH_CERTS_PAT=<your-github-personal-access-token>
```

#### Optional (Legacy Support)
```
FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=tsbh-tmbs-gqoo-cxym
```

### How to Get Values

#### APP_STORE_CONNECT_API_KEY (Base64 Encoded)

1. Download your `.p8` key file from App Store Connect
2. Base64 encode it:
   ```bash
   base64 -i AuthKey_S9RAGF997L.p8 | pbcopy
   ```
3. Use the encoded content as the secret value

#### MATCH_CERTS_PAT (GitHub Personal Access Token)

1. Go to [GitHub Settings > Developer settings > Personal access tokens](https://github.com/settings/tokens)
2. Generate a new token with `repo` scope
3. Use this token to access your private certificates repository

## 🏗️ How It Works

### Environment Loading Priority

1. **GitHub Actions**: Environment variables set via secrets
2. **Local Development**: System environment variables from `.zshrc`

### Centralized Configuration

The Fastfile includes these helper functions:

- **`validate_environment!`**: Ensures all required variables are present
- **`get_app_store_api_key`**: Creates API key configuration from environment
- **System environment integration**: Uses variables from shell configuration

### Security Features

- ✅ Sensitive files are in `.gitignore`
- ✅ Environment validation with clear error messages
- ✅ Supports both file-based (local) and content-based (CI) API keys
- ✅ Fallback mechanisms for different deployment scenarios

## 🧪 Testing Your Setup

### Local Testing
```bash
cd ios
fastlane sync_certificates  # Test certificate sync
fastlane build_only         # Test build process
```

### GitHub Actions Testing
1. Push changes to trigger the workflow
2. Check GitHub Actions logs for environment validation
3. Ensure all secrets are properly configured

## 🔍 Troubleshooting

### Common Issues

**Missing Environment Variables**
- Error: `❌ Missing required environment variables`
- Solution: Ensure all required secrets are configured in `.zshrc` (local) or GitHub Secrets (CI)

**API Key Issues**
- Error: `❌ Either APP_STORE_CONNECT_API_KEY_CONTENT or APP_STORE_CONNECT_API_KEY_PATH must be set`
- Solution: For local dev, set `APP_STORE_CONNECT_API_KEY_PATH`. For CI, set `APP_STORE_CONNECT_API_KEY_CONTENT`

**Path Resolution Issues**
- Error: `Couldn't find key p8 file at path '$HOME/.appstoreconnect/private/AuthKey_S9RAGF997L.p8'`
- Solution: Use absolute paths instead of `$HOME` in environment variables, or ensure variable expansion is working
- Fixed: The Fastfile now automatically expands `$HOME` in environment variables

**Match Repository Access**
- Error: Authentication failure with match repository
- Solution: Ensure `MATCH_CERTS_PAT` has proper repository access and `repo` scope permissions

**GitHub Secrets Not Set**
- Error: Workflow fails with missing secrets
- Solution: Run the setup script: `./ios/fastlane/setup-github-secrets.sh`

**Base64 Encoding Issues**
- Error: Invalid API key format in GitHub Actions
- Solution: Ensure API key is properly base64 encoded: `base64 -i AuthKey_S9RAGF997L.p8`

### Debugging Commands

```bash
# Check environment loading
cd ios && fastlane run validate_environment!

# Test API key configuration
cd ios && fastlane run app_store_connect_api_key

# Check match configuration
cd ios && fastlane run match type:appstore readonly:true
```

## 📝 Current Configuration Summary

**Fixed Values (Hardcoded):**
- Team ID: `GCRLV5UC4Q` 
- App Identifier: `com.blanxlait.octo-vocab`
- App Name: `Octo Vocab`

**Configurable via Environment:**
- All App Store Connect API credentials
- All Match/certificate management settings
- Repository URLs and access tokens

This setup provides maximum security while maintaining flexibility for both development and production deployment scenarios.