#!/bin/bash
set -e

echo "=========================================="
echo "Full Production Build & Deploy"
echo "=========================================="

cd /home/tk/lms-prod/frontend

echo "Building Flutter web with HTTPS support..."
docker run --rm \
  -v /home/tk/lms-prod/frontend:/app \
  -w /app \
  ghcr.io/cirruslabs/flutter:stable \
  bash -c "echo 'Starting clean...' && flutter clean && echo 'Starting pub get...' && flutter pub get -v && echo 'Starting build web...' && flutter build web --release \
    --dart-define=ENV=production \
    --no-wasm-dry-run"

echo "Updating prebuilt_web directory..."
rm -rf /home/tk/lms-prod/frontend/prebuilt_web/*
cp -r /home/tk/lms-prod/frontend/build/web/* /home/tk/lms-prod/frontend/prebuilt_web/

cd /home/tk/lms-prod

echo "Rebuilding and restarting frontend and socketio containers..."
docker compose build frontend socketio
docker compose up -d frontend socketio

echo "Restarting backend and proxy containers..."
docker compose restart backend nginx celery celery-beat flower

echo "=========================================="
echo "✅ DEPLOYMENT COMPLETE!"
echo "=========================================="
