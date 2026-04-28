#!/bin/bash
# =============================================================================
# LMS Price Persistence Fix - Remote Server Deployment
# Deploys industry training price persistence and cart functionality fixes
# =============================================================================

set -e

# Configuration
SERVER_IP="154.66.211.3"
USER="tk"
SSH_PORT="2222"
SSH_KEY="$HOME/.ssh/id_rsa"
DEPLOY_PATH="/home/tk/lms-prod"

echo "🚀 Deploying Price Persistence Fixes to Remote Server"
echo "======================================================================"
echo "Server: $SERVER_IP:$SSH_PORT"
echo "User: $USER"
echo "Deploy Path: $DEPLOY_PATH"
echo "======================================================================"
echo ""

SSH_OPTS="-o StrictHostKeyChecking=no -P $SSH_PORT -i $SSH_KEY"

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

# 1. Git commit if there are changes
log_info "Checking for changes..."
cd "$DEPLOY_PATH"
if ! git diff-index --quiet HEAD --; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    log_info "Staging and committing changes..."
    git add -A
    git commit -m "Deploy: Price persistence fixes - $TIMESTAMP"
    log_success "Changes committed"
else
    log_warning "No changes to commit"
fi

# 2. Sync files to remote server
echo ""
log_info "Syncing files to remote server..."

# Sync frontend files
rsync -avz -e "ssh -p $SSH_PORT -i $SSH_KEY" \
    --exclude '.git' \
    --exclude '__pycache__' \
    --exclude '*.pyc' \
    --exclude 'node_modules' \
    --exclude '.env' \
    --exclude 'build/' \
    --exclude 'prebuilt_web/' \
    /home/tk/lms-prod/frontend/lib/src/presentation/widgets/modals/aicerts/ \
    ${USER}@${SERVER_IP}:${DEPLOY_PATH}/frontend/lib/src/presentation/widgets/modals/aicerts/

rsync -avz -e "ssh -p $SSH_PORT -i $SSH_KEY" \
    /home/tk/lms-prod/frontend/lib/src/presentation/pages/industry_training/ \
    ${USER}@${SERVER_IP}:${DEPLOY_PATH}/frontend/lib/src/presentation/pages/industry_training/

rsync -avz -e "ssh -p $SSH_PORT -i $SSH_KEY" \
    /home/tk/lms-prod/frontend/lib/src/presentation/pages/custom_selection/ \
    ${USER}@${SERVER_IP}:${DEPLOY_PATH}/frontend/lib/src/presentation/pages/custom_selection/

log_success "Frontend files synced"

# 3. Build Flutter frontend on remote server
echo ""
log_info "Building Flutter frontend on remote server..."
ssh $SSH_OPTS ${USER}@${SERVER_IP} << 'EOF'
cd /home/tk/lms-prod

# Export Flutter path
export PATH="$PATH:$HOME/flutter/bin"

# Navigate to frontend
cd frontend

# Clean build
log_info "Cleaning previous build..."
flutter clean

# Build web release
log_info "Building Flutter web release..."
flutter build web --release

# Copy to prebuilt_web
log_info "Copying build to prebuilt_web..."
rm -rf prebuilt_web/*
cp -r build/web/* prebuilt_web/

log_success "Flutter frontend built successfully"
EOF

# 4. Rebuild and restart frontend container
echo ""
log_info "Rebuilding and restarting frontend container..."
ssh $SSH_OPTS ${USER}@${SERVER_IP} << 'EOF'
cd /home/tk/lms-prod

# Rebuild frontend container
docker compose build frontend

# Restart frontend service
docker compose up -d frontend

# Check container status
docker compose ps frontend
EOF

log_success "Frontend container restarted"

# 5. Verify deployment
echo ""
log_info "Verifying deployment..."
ssh $SSH_OPTS ${USER}@${SERVER_IP} << 'EOF'
cd /home/tk/lms-prod

# Check frontend container logs
echo "📋 Last 10 frontend logs:"
docker compose logs --tail=10 frontend

# Check if container is running
echo ""
echo "📊 Container status:"
docker compose ps | grep frontend
EOF

# 6. Summary
echo ""
echo "======================================================================"
log_success "Deployment Complete!"
echo "======================================================================"
echo ""
echo "📦 Access URLs:"
echo "   Frontend:     http://${SERVER_IP}:7000"
echo "   Backend API:  http://${SERVER_IP}:7001"
echo "   SocketIO:     http://${SERVER_IP}:7002"
echo ""
echo "🎯 Deployed Features:"
echo "   ✓ Price persistence in Industry Training enrollment"
echo "   ✓ Price persistence in Custom Selection enrollment"
echo "   ✓ Cart functionality for Industry Training"
echo "   ✓ Payment initiation API integration"
echo "   ✓ Price banners visible throughout enrollment flow"
echo ""
echo "🧪 Testing Checklist:"
echo "   1. Browse Industry Training courses"
echo "   2. Add courses to cart (multiple selection)"
echo "   3. Verify price shows in cart summary bar"
echo "   4. Click 'Enroll Now' and check price in modal"
echo "   5. Verify price persists through all enrollment steps"
echo "   6. Complete payment and verify amount matches"
echo ""
echo "🔧 Quick Commands:"
echo "   Logs:       ssh -p $SSH_PORT ${USER}@${SERVER_IP} 'cd $DEPLOY_PATH && docker compose logs -f frontend'"
echo "   Restart:    ssh -p $SSH_PORT ${USER}@${SERVER_IP} 'cd $DEPLOY_PATH && docker compose restart frontend'"
echo "   Status:     ssh -p $SSH_PORT ${USER}@${SERVER_IP} 'cd $DEPLOY_PATH && docker compose ps'"
echo ""
echo "📝 Documentation:"
echo "   See: INDUSTRY_TRAINING_PRICE_PERSISTENCE_FIX.md"
echo ""
