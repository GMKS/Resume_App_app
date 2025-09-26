#!/bin/bash

# APK Size Optimization Build Script
# Run this script to build optimized APK with size analysis

echo "🚀 Starting APK Size Optimization Build..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
flutter pub get

# Build optimized release APK
echo "📦 Building optimized release APK..."
flutter build apk \
  --release \
  --shrink \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --tree-shake-icons \
  --target-platform android-arm64 \
  --analyze-size

# Build App Bundle for Play Store (smaller than APK)
echo "📱 Building optimized App Bundle..."
flutter build appbundle \
  --release \
  --shrink \
  --obfuscate \
  --split-debug-info=build/debug-info \
  --tree-shake-icons

echo "✅ Build completed!"
echo ""
echo "📊 APK Analysis:"
echo "- APK Location: build/app/outputs/flutter-apk/app-release.apk"
echo "- App Bundle Location: build/app/outputs/bundle/release/app-release.aab"
echo "- Size Analysis: build/apk-size-analysis.json"
echo ""
echo "💡 Tips to further reduce size:"
echo "1. Use App Bundle instead of APK for Play Store"
echo "2. Remove unused dependencies"
echo "3. Optimize images and assets"
echo "4. Use vector graphics instead of raster images"