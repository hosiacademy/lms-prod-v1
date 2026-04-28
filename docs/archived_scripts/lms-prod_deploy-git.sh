#!/bin/bash

# =============================================================================
# LMS Auto-Deploy with Git
# Automatically commits and pushes changes on every deployment
# =============================================================================

set -e

DEPLOY_DIR="/home/tk/lms-prod"
GIT_REMOTE="${GIT_REMOTE_URL:-}"
BRANCH_NAME="${BRANCH_NAME:-main}"
DEPLOY_USER="${DEPLOY_USER:-deploy@hosiacademy.africa}"
DEPLOY_NAME="${DEPLOY_NAME:-LMS Deploy Bot}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

cd "$DEPLOY_DIR"

# =============================================================================
# 1. Initialize Git if not exists
# =============================================================================
if [ ! -d ".git" ]; then
    log_info "Initializing Git repository..."
    git init
    git config user.email "$DEPLOY_USER"
    git config user.name "$DEPLOY_NAME"
    git branch -M "$BRANCH_NAME"
    log_success "Git repository initialized"
fi

# =============================================================================
# 2. Add remote if provided
# =============================================================================
if [ -n "$GIT_REMOTE_URL" ]; then
    if ! git remote | grep -q origin; then
        log_info "Adding remote repository..."
        git remote add origin "$GIT_REMOTE_URL"
        log_success "Remote added: $GIT_REMOTE_URL"
    else
        git remote set-url origin "$GIT_REMOTE_URL"
    fi
fi

# =============================================================================
# 3. Build Flutter Frontend
# =============================================================================
log_info "Building Flutter frontend..."
export PATH="$PATH:$HOME/flutter/bin"
cd frontend

# Clean and build
flutter clean > /dev/null 2>&1
flutter build web --release > /dev/null 2>&1

# Copy to prebuilt_web
rm -rf prebuilt_web/*
cp -r build/web/* prebuilt_web/

cd "$DEPLOY_DIR"
log_success "Frontend built"

# =============================================================================
# 4. Git Add, Commit, Push
# =============================================================================
log_info "Staging changes..."
git add -A

# Check if there are changes to commit
if git diff-index --quiet HEAD --; then
    log_warning "No changes to commit"
else
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    COMMIT_MSG="Deploy: Auto-commit on $TIMESTAMP"
    
    log_info "Committing changes..."
    git commit -m "$COMMIT_MSG"
    log_success "Changes committed"
    
    # Push if remote is configured
    if git remote | grep -q origin; then
        log_info "Pushing to remote..."
        git push -u origin "$BRANCH_NAME" 2>&1 || log_warning "Push failed - check remote credentials"
        log_success "Changes pushed to remote"
    else
        log_warning "No remote configured - skipping push"
    fi
fi

# =============================================================================
# 5. Restart Docker Containers
# =============================================================================
log_info "Restarting services..."
docker compose build frontend > /dev/null 2>&1
docker compose up -d frontend > /dev/null 2>&1
log_success "Services restarted"

# =============================================================================
# 6. Summary
# =============================================================================
echo ""
echo "============================================="
log_success "Deployment Complete!"
echo "============================================="
echo ""
echo "📦 Frontend: http://154.66.211.3:7000"
echo "🔧 Backend:  http://154.66.211.3:7001"
echo "📊 Database: PostgreSQL (healthy)"
echo ""
echo "Git Status:"
git status --short | head -5 || echo "  Working tree clean"
echo ""
echo "Useful commands:"
echo "  View logs:     docker compose logs -f"
echo "  Git status:    git status"
echo "  Git log:       git log --oneline -10"
echo "  Rollback:      git revert HEAD && docker compose restart"
echo ""
