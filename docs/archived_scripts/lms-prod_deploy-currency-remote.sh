#!/bin/bash
# =============================================================================
# LMS-PROD - IP-Based Currency Conversion Deployment
# Syncs files to remote server (154.66.211.3) and deploys
# =============================================================================

set -e

# Configuration
SERVER_IP="154.66.211.3"
USER="tk"
SSH_PORT="2222"
SSH_KEY="$HOME/.ssh/id_rsa"
DEPLOY_PATH="/home/tk/lms-prod"

echo "🚀 Deploying IP-Based Currency Conversion to Remote Server"
echo "======================================================================"
echo "Server: $SERVER_IP"
echo "User: $USER"
echo "SSH Port: $SSH_PORT"
echo "======================================================================"

SSH_OPTS="-o StrictHostKeyChecking=no -P $SSH_PORT -i $SSH_KEY"

# 1. Build Flutter frontend locally first
echo "📦 Building Flutter frontend..."
cd /home/tk/lms-prod/frontend
export PATH="$PATH:/home/tk/flutter/bin"
flutter build web --release > /dev/null 2>&1
echo "✅ Flutter build complete"

# 2. Sync backend files to remote server
echo ""
echo "📦 Syncing backend files to remote server..."

# Sync payment views (currency endpoints)
rsync -avz -e "ssh -p $SSH_PORT -i $SSH_KEY" \
    /home/tk/lms-prod/backend/apps/payments/views/payment_views.py \
    /home/tk/lms-prod/backend/apps/payments/urls.py \
    /home/tk/lms-prod/backend/apps/payments/services/geolocation_service.py \
    /home/tk/lms-prod/backend/apps/payments/executive_views.py \
    /home/tk/lms-prod/backend/apps/payments/api_views.py \
    ${USER}@${SERVER_IP}:${DEPLOY_PATH}/backend/apps/payments/

echo "✅ Backend payment files synced"

# Sync Flutter frontend
rsync -avz -e "ssh -p $SSH_PORT -i $SSH_KEY" \
    /home/tk/lms-prod/frontend/lib/src/core/services/currency_service.dart \
    ${USER}@${SERVER_IP}:${DEPLOY_PATH}/frontend/lib/src/core/services/

echo "✅ Flutter currency service synced"

# Sync built Flutter web files
rsync -avz -e "ssh -p $SSH_PORT -i $SSH_KEY" \
    --delete \
    /home/tk/lms-prod/frontend/build/web/ \
    ${USER}@${SERVER_IP}:${DEPLOY_PATH}/frontend/prebuilt_web/

echo "✅ Flutter web build synced"

# 3. Run remote deployment
echo ""
echo "🔧 Running remote deployment..."
ssh $SSH_OPTS ${USER}@${SERVER_IP} << 'EOF'
cd /home/tk/lms-prod

# Restart backend to load new endpoints
echo "Restarting backend container..."
docker compose restart backend
sleep 10

# Rebuild and restart frontend with new build
echo "Rebuilding frontend container..."
docker compose build frontend
docker compose up -d frontend
sleep 5

# Verify services
echo ""
echo "Verifying services..."
docker compose ps | grep -E "frontend|backend"
EOF

echo ""
echo "======================================================================"
echo "✅ Remote Deployment Complete!"
echo "======================================================================"
echo ""
echo "📋 Access URLs:"
echo "   Frontend:     http://${SERVER_IP}:7000"
echo "   Backend API:  http://${SERVER_IP}:7001"
echo ""
echo "🧪 Test Currency Conversion:"
echo "   1. Visit http://${SERVER_IP}:7000"
echo "   2. Prices should show in your local currency (ZAR for South Africa)"
echo ""
echo "🔧 API Endpoints:"
echo "   - IP Detection: http://${SERVER_IP}:7001/api/v1/payments/detect-location/"
echo "   - Exchange Rates: http://${SERVER_IP}:7001/api/v1/payments/exchange-rates/"
echo ""
