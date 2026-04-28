#!/bin/bash
# Flutter Web Build Script
cd /home/tk/lms-prod/frontend

# Build using Flutter Docker container
docker run --rm \
  -v /home/tk/lms-prod/frontend:/app \
  -w /app \
  ghcr.io/cirruslabs/flutter:stable \
  sh -c "flutter pub get && flutter build web --release"

echo "Build complete!"
echo "Output in: /home/tk/lms-prod/frontend/build/web"
