#!/bin/bash

# Hindu Connect iOS Build Script for Codemagic
# This script builds the iOS app for App Store distribution

set -e

echo "🚀 Starting Hindu Connect iOS build..."

# Set environment variables
export FLUTTER_ROOT=/usr/local/bin/flutter
export PATH="$FLUTTER_ROOT/bin:$PATH"

# Verify Flutter installation
echo "📱 Verifying Flutter installation..."
flutter --version
flutter doctor

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Install iOS pods
echo "🍎 Installing iOS pods..."
cd ios
pod install --repo-update
cd ..

# Run Flutter analyze
echo "🔍 Running Flutter analyze..."
flutter analyze

# Run tests
echo "🧪 Running Flutter tests..."
flutter test

# Build iOS app
echo "🏗️ Building iOS app for App Store..."
flutter build ipa \
  --release \
  --build-name="$APP_VERSION" \
  --build-number="$BUILD_NUMBER" \
  --export-options-plist=ios/export_options.plist

echo "✅ iOS build completed successfully!"

# List build artifacts
echo "📋 Build artifacts:"
ls -la build/ios/ipa/

echo "🎉 Hindu Connect iOS build process completed!"
