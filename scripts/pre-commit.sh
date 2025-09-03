#!/bin/bash

# Pre-commit validation script
# Run this before every commit to catch issues locally

set -e  # Exit on any error

echo "🔍 Pre-commit validation starting..."

# 1. Check formatting
echo "📝 Checking code formatting..."
if ! dart format --set-exit-if-changed .; then
    echo "❌ Code formatting issues found. Run: dart format ."
    exit 1
fi
echo "✅ Code formatting looks good"

# 2. Run linting
echo "🔍 Running static analysis..."
if ! flutter analyze; then
    echo "❌ Linting issues found. Fix them before committing."
    exit 1
fi
echo "✅ No linting issues found"

# 3. Run tests
echo "🧪 Running test suite..."

echo "  📋 Unit tests..."
if ! ./scripts/test.sh unit; then
    echo "❌ Unit tests failed"
    exit 1
fi

echo "  🎨 Widget tests..."  
if ! ./scripts/test.sh widget; then
    echo "❌ Widget tests failed"
    exit 1
fi

echo "  🔗 Integration tests..."
if ! ./scripts/test.sh integration; then
    echo "❌ Integration tests failed"
    exit 1
fi

echo "✅ All tests passed!"

# 4. Build check
echo "🏗️  Testing build..."
if ! flutter build web --no-pub; then
    echo "❌ Build failed"
    exit 1
fi
echo "✅ Build successful"

echo ""
echo "🎉 All pre-commit checks passed! Safe to commit."
echo "💡 Next steps:"
echo "   git add ."
echo "   git commit -m 'your message'"
echo "   git push"