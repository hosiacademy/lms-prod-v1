#!/bin/bash
set -ex

echo "=== Simple Build Test ==="

# Create minimal test app
mkdir -p test_app
cd test_app

cat > pubspec.yaml << 'PUBSPEC'
name: test_app
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.0.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
PUBSPEC

cat > lib/main.dart << 'MAIN'
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Hello World')))));
}
MAIN

echo "Building test app..."
docker run --rm -v "$(pwd):/app" -w /app ghcr.io/cirruslabs/flutter:stable \
  flutter build web --release 2>&1 | tail -20

if [ -f "build/web/index.html" ]; then
  echo "SUCCESS: Build worked!"
  ls -la build/web/
else
  echo "FAILED: Build failed"
fi

cd ..
