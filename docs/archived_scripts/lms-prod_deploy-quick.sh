#!/bin/bash
# =============================================================================
# LMS Quick Deploy (Silent Mode)
# For use in git hooks - minimal output
# =============================================================================

set -e

DEPLOY_DIR="/home/tk/lms-prod"
cd "$DEPLOY_DIR"

# Build Flutter frontend
export PATH="$PATH:/home/tk/flutter/bin"
cd frontend

flutter clean > /dev/null 2>&1
flutter build web --release > /dev/null 2>&1

rm -rf prebuilt_web/*
cp -r build/web/* prebuilt_web/

cd "$DEPLOY_DIR"

# Restart containers
docker compose build frontend > /dev/null 2>&1
docker compose up -d frontend > /dev/null 2>&1

echo "Deployed at $(date '+%Y-%m-%d %H:%M:%S')"
