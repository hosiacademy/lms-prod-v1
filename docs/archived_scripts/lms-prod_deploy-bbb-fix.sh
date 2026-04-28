#!/bin/bash
set -e

SERVER_IP="154.66.211.3"
USER="tk"
SSH_PORT="2222"
SSH_KEY="$HOME/.ssh/id_rsa"
DEPLOY_PATH="/home/tk/lms-prod"

echo "🚀 Deploying BBB Dashboard Fixes to Remote Server ($SERVER_IP)"

SSH_OPTS="-o StrictHostKeyChecking=no -p $SSH_PORT -i $SSH_KEY"

# Sync backend
echo "📦 Syncing backend views.py..."
rsync -avz -e "ssh $SSH_OPTS" \
    /home/tk/lms-prod/backend/apps/bbb_integration/views.py \
    ${USER}@${SERVER_IP}:${DEPLOY_PATH}/backend/apps/bbb_integration/views.py

# Sync frontend prebuilt
echo "📦 Syncing prebuilt frontend..."
rsync -avz -e "ssh $SSH_OPTS" \
    --delete \
    /home/tk/lms-prod/prebuilt_web/ \
    ${USER}@${SERVER_IP}:${DEPLOY_PATH}/prebuilt_web/

echo "🔧 Restarting remote containers..."
ssh $SSH_OPTS ${USER}@${SERVER_IP} "cd $DEPLOY_PATH && docker compose -f docker-compose.yml -f docker-compose.prod.yml build --no-cache frontend && docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d frontend backend"

echo "✅ Deployment Complete!"
