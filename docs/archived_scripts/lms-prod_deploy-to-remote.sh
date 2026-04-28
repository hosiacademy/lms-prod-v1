#!/bin/bash
# =============================================================================
# LMS Instructor App Fix - Remote Server Deployment
# Syncs files to remote server and deploys
# =============================================================================

set -e

# Configuration
SERVER_IP="154.66.211.3"
USER="tk"
SSH_PORT="2222"
SSH_KEY="$HOME/.ssh/id_rsa"
DEPLOY_PATH="/home/tk/lms-prod"

echo "🚀 Deploying Instructor App Fixes to Remote Server"
echo "======================================================================"
echo "Server: $SERVER_IP"
echo "User: $USER"
echo "SSH Port: $SSH_PORT"
echo "======================================================================"

SSH_OPTS="-o StrictHostKeyChecking=no -P $SSH_PORT -i $SSH_KEY"

# 1. Sync files to remote server
echo "📦 Syncing files to remote server..."
rsync -avz -e "ssh -p $SSH_PORT -i $SSH_KEY" \
    --exclude '.git' \
    --exclude '__pycache__' \
    --exclude '*.pyc' \
    --exclude 'db.sqlite3' \
    --exclude '.env' \
    --exclude 'media/' \
    --exclude 'static/' \
    /home/tk/lms-prod/backend/apps/instructors/ \
    ${USER}@${SERVER_IP}:${DEPLOY_PATH}/backend/apps/instructors/

echo "✅ Backend app files synced"

# Sync project-level files
rsync -avz -e "ssh -p $SSH_PORT -i $SSH_KEY" \
    /home/tk/lms-prod/backend/lms_project/settings.py \
    /home/tk/lms-prod/backend/lms_project/urls.py \
    ${USER}@${SERVER_IP}:${DEPLOY_PATH}/backend/

echo "✅ Project settings synced"

# Sync deployment script
rsync -avz -e "ssh -p $SSH_PORT -i $SSH_KEY" \
    /home/tk/lms-prod/deploy-instructor-fix.sh \
    ${USER}@${SERVER_IP}:${DEPLOY_PATH}/

echo "✅ Deployment script synced"

# 2. Run remote deployment
echo ""
echo "🔧 Running remote deployment..."
ssh $SSH_OPTS ${USER}@${SERVER_IP} "cd $DEPLOY_PATH && bash deploy-instructor-fix.sh"

echo ""
echo "======================================================================"
echo "✅ Remote Deployment Complete!"
echo "======================================================================"
echo ""
echo "📋 Access URLs:"
echo "   Frontend:     http://${SERVER_IP}:7000"
echo "   Backend API:  http://${SERVER_IP}:7001/api/v1/instructors/"
echo "   SocketIO:     http://${SERVER_IP}:7002"
echo ""
echo "🔑 Test the instructor dashboard by logging in as an instructor"
echo ""
