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
read -p "Enter your App Store Connect API Key ID: " API_KEY_ID
$set_secret_fn "APP_STORE_CONNECT_API_KEY_ID" "$API_KEY_ID" "App Store Connect API Key ID"

# App Store Connect Issuer ID
read -p "Enter your App Store Connect Issuer ID: " ISSUER_ID
$set_secret_fn "APP_STORE_CONNECT_ISSUER_ID" "$ISSUER_ID" "App Store Connect API Issuer ID"

# App Store Connect API Key (Content or Path)
echo "📄 Choose API Key input method:"
echo "1) Provide file path to .p8 key file"
echo "2) Paste API key content directly"
read -p "Enter choice (1 or 2): " choice

if [ "$choice" = "1" ]; then
    read -p "Enter path to your .p8 API key file: " API_KEY_PATH
    if [ -f "$API_KEY_PATH" ]; then
        echo "📄 Found API key file at: $API_KEY_PATH"
        echo "🔄 Reading API key content..."
        API_KEY_CONTENT=$(cat "$API_KEY_PATH")
        $set_secret_fn "APP_STORE_CONNECT_API_KEY_CONTENT" "$API_KEY_CONTENT" "App Store Connect API Key content (.p8 file)"
    else
        echo "❌ API key file not found at: $API_KEY_PATH"
        echo "Please ensure the API key file exists at the correct location."
        echo
    fi
elif [ "$choice" = "2" ]; then
    echo "Paste your API key content (including -----BEGIN PRIVATE KEY----- and -----END PRIVATE KEY----- lines):"
    echo "Press Enter, then Ctrl+D when finished:"
    API_KEY_CONTENT=$(cat)
    $set_secret_fn "APP_STORE_CONNECT_API_KEY_CONTENT" "$API_KEY_CONTENT" "App Store Connect API Key content"
else
    echo "❌ Invalid choice. Skipping API key setup."
    echo
fi

echo "📜 Setting up Match (Certificate Management) secrets ($level_desc)..."
echo

# Match Password
read -s -p "Enter your Match password: " MATCH_PASSWORD
echo
$set_secret_fn "MATCH_PASSWORD" "$MATCH_PASSWORD" "Password for Match certificate repository"

# Match Git URL
read -p "Enter Match Git repository URL: " MATCH_GIT_URL
$set_secret_fn "MATCH_GIT_URL" "$MATCH_GIT_URL" "Git repository URL for Match certificates"

# Match Personal Access Token
read -s -p "Enter GitHub Personal Access Token for Match repository: " MATCH_CERTS_PAT
echo
$set_secret_fn "MATCH_CERTS_PAT" "$MATCH_CERTS_PAT" "GitHub Personal Access Token for Match repository access"

# Fastlane Team ID
read -p "Enter your Fastlane Team ID: " FASTLANE_TEAM_ID
$set_secret_fn "FASTLANE_TEAM_ID" "$FASTLANE_TEAM_ID" "Apple Developer Team ID"


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