#!/bin/bash
# Simple build script focusing on core build
set -e

cd /home/tk/lms-prod/frontend

echo "=== Clean ==="
rm -rf build .dart_tool .flutter-plugins* .packages pubspec.lock

echo "=== Get dependencies ==="
docker run --rm \
  -v flutter-pub-cache:/root/.pub-cache \
  -v $(pwd):/app \
  -w /app \
  ghcr.io/cirruslabs/flutter:stable \
  flutter pub get

echo "=== Build web ==="
docker run --rm \
  -v flutter-pub-cache:/root/.pub-cache \
  -v $(pwd):/app \
  -w /app \
  ghcr.io/cirruslabs/flutter:stable \
  flutter build web --release \
    --dart-define=ENV=production \
    --no-wasm-dry-run

echo "=== Check build ==="
if [ -f "build/web/main.dart.js" ]; then
    echo "Build successful! Size: $(du -sh build/web | cut -f1)"
    echo "=== Update prebuilt_web ==="
    rm -rf prebuilt_web/*
    cp -r build/web/* prebuilt_web/
    
    echo "=== Restart frontend ==="
    docker restart lms-prod-frontend-1 2>/dev/null && echo "Frontend restarted" || echo "Could not restart frontend"
else
    echo "Build failed!"
    exit 1
fi