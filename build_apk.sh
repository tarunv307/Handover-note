#!/bin/bash
set -e

echo "============================================================"
echo "📲 Building ShiftOps Flutter Mobile Application (APK)"
echo "============================================================"

cd "$(dirname "$0")/frontend_flutter"

echo "1. Fetching Flutter dependencies..."
flutter pub get

echo "2. Building Android APK (Release)..."
flutter build apk --release --no-tree-shake-icons

echo ""
echo "============================================================"
echo "✅ APK Build Complete!"
echo "📦 Output Location: frontend_flutter/build/app/outputs/flutter-apk/app-release.apk"
echo "============================================================"
