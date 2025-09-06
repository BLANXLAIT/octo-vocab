#!/bin/bash

# GitHub Secrets Setup Script for Octo Vocab iOS Deployment
# This script helps configure all required GitHub secrets for the iOS deployment workflow
# 
# Usage:
#   ./setup-github-secrets.sh [org|repo]
#   
# Arguments:
#   org  - Set secrets at organization level (requires admin:org scope)
#   repo - Set secrets at repository level (default)

set -e

# Determine scope from argument
SCOPE=${1:-repo}
if [[ "$SCOPE" != "org" && "$SCOPE" != "repo" ]]; then
    echo "❌ Invalid argument. Use 'org' or 'repo'"
    echo "Usage: $0 [org|repo]"
    exit 1
fi

echo "🔐 GitHub Secrets Setup for Octo Vocab iOS Deployment ($SCOPE level)"
echo "=============================================================="
echo

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) is not installed."
    echo "Please install it from: https://cli.github.com/"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ Not authenticated with GitHub CLI."
    echo "Please run: gh auth login"
    exit 1
fi

echo "✅ GitHub CLI is installed and authenticated"
echo

# Set organization and repository info
ORG="BLANXLAIT"
REPO="BLANXLAIT/octo-vocab"
echo "🏢 Organization: $ORG"
echo "📁 Repository: $REPO"
echo

# Function to set a secret at organization level
set_org_secret() {
    local name=$1
    local value=$2
    local description=$3
    
    echo "Setting org secret: $name"
    if [ -n "$description" ]; then
        echo "  Description: $description"
    fi
    
    if [ -z "$value" ]; then
        echo "  ⚠️  Value is empty - skipping"
        return
    fi
    
    if echo "$value" | gh secret set "$name" --org "$ORG" --visibility all; then
        echo "  ✅ Set successfully (org-wide)"
    else
        echo "  ❌ Failed to set"
    fi
    echo
}

# Function to set a secret at repository level
set_repo_secret() {
    local name=$1
    local value=$2
    local description=$3
    
    echo "Setting repo secret: $name"
    if [ -n "$description" ]; then
        echo "  Description: $description"
    fi
    
    if [ -z "$value" ]; then
        echo "  ⚠️  Value is empty - skipping"
        return
    fi
    
    if echo "$value" | gh secret set "$name" --repo "$REPO"; then
        echo "  ✅ Set successfully (repo-specific)"
    else
        echo "  ❌ Failed to set"
    fi
    echo
}

# Choose function based on scope
if [ "$SCOPE" = "org" ]; then
    set_secret_fn="set_org_secret"
    level_desc="Organization Level"
else
    set_secret_fn="set_repo_secret" 
    level_desc="Repository Level"
fi

echo "🔑 Setting up App Store Connect API secrets ($level_desc)..."
echo

# App Store Connect API Key ID
$set_secret_fn "APP_STORE_CONNECT_API_KEY_ID" "S9RAGF997L" "App Store Connect API Key ID"

# App Store Connect Issuer ID
$set_secret_fn "APP_STORE_CONNECT_ISSUER_ID" "69a6de83-1bd1-47e3-e053-5b8c7c11a4d1" "App Store Connect API Issuer ID"

# App Store Connect API Key (Base64 encoded)
API_KEY_PATH="$HOME/.appstoreconnect/private/AuthKey_S9RAGF997L.p8"
if [ -f "$API_KEY_PATH" ]; then
    echo "📄 Found API key file at: $API_KEY_PATH"
    echo "🔄 Base64 encoding API key..."
    API_KEY_BASE64=$(base64 -i "$API_KEY_PATH")
    $set_secret_fn "APP_STORE_CONNECT_API_KEY" "$API_KEY_BASE64" "Base64 encoded App Store Connect API Key (.p8 file)"
else
    echo "❌ API key file not found at: $API_KEY_PATH"
    echo "Please ensure the API key file exists at the correct location."
    echo
fi

echo "📜 Setting up Match (Certificate Management) secrets ($level_desc)..."
echo

# Match Password
$set_secret_fn "MATCH_PASSWORD" "qdPe8fFWewKF2CMfjkn9" "Password for Match certificate repository"

# Match Git URL
$set_secret_fn "MATCH_GIT_URL" "https://github.com/BLANXLAIT/blanxlait-ci-shared" "Git repository URL for Match certificates"

# Match Git Branch
$set_secret_fn "MATCH_GIT_BRANCH" "main" "Git branch for Match certificates"

# Match Personal Access Token
$set_secret_fn "MATCH_CERTS_PAT" "YOUR_GITHUB_PAT_HERE" "GitHub Personal Access Token for Match repository access"

echo "🍎 Setting up optional Apple ID secrets ($level_desc)..."
echo

# Apple Application Specific Password (Legacy)
$set_secret_fn "FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD" "YOUR_APP_SPECIFIC_PASSWORD_HERE" "App-specific password for legacy Apple ID authentication"

echo "🎉 GitHub Secrets Setup Complete!"
echo

if [ "$SCOPE" = "org" ]; then
    echo "✅ All secrets have been configured at the organization level for: $ORG"
    echo "   These secrets are now available to all repositories in the organization"
    echo
    echo "Next steps:"
    echo "1. Go to https://github.com/orgs/$ORG/settings/secrets/actions to verify all org secrets are set"
    echo "2. Go to https://github.com/$REPO/settings/secrets/actions to see available secrets"
    echo "3. Test the deployment workflow by running: gh workflow run ios-deploy.yml"
    echo "4. Monitor the workflow progress: gh run list --workflow ios-deploy.yml"
    echo
    echo "🔍 Troubleshooting:"
    echo "- If any secrets failed to set, you can manually add them in GitHub organization settings"
    echo "- Ensure the API key file exists and is readable"
    echo "- Verify the Personal Access Token has 'repo' scope permissions"
    echo "- Organization secrets are automatically inherited by all repos in the org"
    echo "- If you get 403 errors, ensure you have admin:org scope: gh auth refresh -h github.com -s admin:org"
else
    echo "✅ All secrets have been configured at the repository level for: $REPO"
    echo
    echo "Next steps:"
    echo "1. Go to https://github.com/$REPO/settings/secrets/actions to verify all secrets are set"
    echo "2. Test the deployment workflow by running: gh workflow run ios-deploy.yml"
    echo "3. Monitor the workflow progress: gh run list --workflow ios-deploy.yml"
    echo
    echo "🔍 Troubleshooting:"
    echo "- If any secrets failed to set, you can manually add them in GitHub repository settings"
    echo "- Ensure the API key file exists and is readable"
    echo "- Verify the Personal Access Token has 'repo' scope permissions"
    echo "- To set at org level instead: $0 org (requires admin:org scope)"
fi