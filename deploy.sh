#!/bin/bash
# =============================================================================
# LMS Quick Deploy
# Simple deployment script for daily use
# =============================================================================

set -e

DEPLOY_DIR="/home/tk/lms-prod"
cd "$DEPLOY_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

echo ""
echo "============================================="
echo "  🚀 LMS Quick Deploy"
echo "============================================="
echo ""

# 1. Git commit if there are changes
log_info "Checking for changes..."
if ! git diff-index --quiet HEAD --; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    log_info "Staging and committing changes..."
    git add -A
    git commit -m "Deploy: $TIMESTAMP"
    log_success "Changes committed"
else
    log_warning "No changes to commit"
fi

# 2. Build Flutter frontend
log_info "Building Flutter frontend..."
export PATH="$PATH:$HOME/flutter/bin"
cd frontend

flutter clean > /dev/null 2>&1
flutter build web --release > /dev/null 2>&1

rm -rf prebuilt_web/*
cp -r build/web/* prebuilt_web/

cd "$DEPLOY_DIR"
log_success "Frontend built"

# 3. Restart containers
log_info "Restarting services..."
docker compose build frontend > /dev/null 2>&1
docker compose up -d frontend > /dev/null 2>&1
log_success "Services restarted"

# 4. Summary
echo ""
echo "============================================="
log_success "Deployment Complete!"
echo "============================================="
echo ""
echo "📦 Frontend: http://154.66.211.3:7000"
echo "🔧 Backend:  http://154.66.211.3:7001"
echo ""
echo "Quick commands:"
echo "  Logs:     docker compose logs -f"
echo "  Status:   git status"
echo "  Restart:  docker compose restart"
echo ""
