#!/bin/bash
set -e

echo "============================================================"
echo "📲 Building ShiftOps Flutter Mobile Application (APK)"
echo "============================================================"

cd "$(dirname "$0")/frontend_flutter"

echo "1. Fetching Flutter packages..."
flutter pub get

echo "2. Building Android APK (Release)..."
flutter build apk --release

echo ""
echo "============================================================"
echo "✅ APK Build Complete!"
echo "📦 File Location: frontend_flutter/build/app/outputs/flutter-apk/app-release.apk"
echo "============================================================"
