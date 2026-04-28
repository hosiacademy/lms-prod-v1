#!/bin/bash

# ==================== LMS PRODUCTION DEPLOYMENT SCRIPT ====================
# Deploys the LMS platform to any Linux server
# Uses Docker Compose with Nginx reverse proxy (Ports 80/443)
#
# Usage:
#   ./deploy-prod.sh <server_ip> <user> [ssh_key_path]
# Example:
#   ./deploy-prod.sh 203.0.113.5 ubuntu ~/.ssh/id_rsa
#

set -e

# Configuration
SERVER_IP=$1
USER=$2
SSH_KEY=$3
DEPLOY_PATH="/home/$USER/lms-prod"

if [ -z "$SERVER_IP" ] || [ -z "$USER" ]; then
    echo "Usage: ./deploy-prod.sh <server_ip> <user> [ssh_key_path]"
    exit 1
fi

SSH_OPTS="-o StrictHostKeyChecking=no -p 2222"
if [ ! -z "$SSH_KEY" ]; then
    SSH_OPTS="$SSH_OPTS -i $SSH_KEY"
fi

# Function to run remote commands
run_remote() {
    ssh $SSH_OPTS ${USER}@${SERVER_IP} "$@"
}

echo "🚀 Starting Deployment to ${SERVER_IP}..."

# 1. Update Server & Install Docker (if needed)
echo "Skipping Docker installation check as it is confirmed installed."
# if ! run_remote "docker --version" > /dev/null 2>&1; then
#     echo "Installing Docker..."
#     run_remote "curl -fsSL https://get.docker.com | sh"
#     run_remote "sudo usermod -aG docker $USER"
#     echo "Docker installed. Please re-run script or ensure permissions are refreshed."
# fi

# 2. Create Directory
echo "Creating deployment directory..."
run_remote "mkdir -p $DEPLOY_PATH"

# 3. Copy Files
echo "Copying files..."
rsync -avz -e "ssh $SSH_OPTS" \
    --exclude '.git' \
    --exclude '.venv' \
    --exclude 'node_modules' \
    --exclude '__pycache__' \
    --exclude 'lms-monorepo' \
    --exclude 'lms-monorepo.old' \
    --exclude 'frontend/linux/flutter/ephemeral' \
    --exclude 'frontend/windows/flutter/ephemeral' \
    --exclude 'backend/venv' \
    --exclude 'backend/.venv' \
    --exclude 'frontend/build' \
    --exclude 'frontend/.dart_tool' \
    --exclude 'flutter' \
    --exclude '.npm' \
    --exclude '.nvm' \
    --exclude '.ssh' \
    --exclude '.vscode' \
    --exclude '.idea' \
    --exclude '.config' \
    --exclude '.cache' \
    --exclude '.local' \
    --exclude '.bash_history' \
    --exclude '.bash_logout' \
    --exclude '.bashrc' \
    --exclude '.profile' \
    --exclude 'backend/celerybeat-schedule' \
    . ${USER}@${SERVER_IP}:${DEPLOY_PATH}/

# 4. Create .env file remotely if it doesn't exist
echo "Checking environment variables..."
run_remote "if [ ! -f $DEPLOY_PATH/backend/.env ]; then echo 'Creating default .env...'; cp $DEPLOY_PATH/backend/.env.example $DEPLOY_PATH/backend/.env; fi"

# 5. Build and Start Services
echo "Building and starting services..."
# echo "Forcing clean rebuild (no cache)..." 
# run_remote "cd $DEPLOY_PATH && docker compose --env-file ./backend/.env -f docker-compose.yml -f docker-compose.prod.yml build --no-cache"
echo "Building with cache for speed..."
run_remote "cd $DEPLOY_PATH && docker compose --env-file ./backend/.env -f docker-compose.yml -f docker-compose.prod.yml build"
run_remote "cd $DEPLOY_PATH && docker compose --env-file ./backend/.env -f docker-compose.yml -f docker-compose.prod.yml up -d"

# 6. Run Migrations & Collect Static
echo "Running migrations..."
run_remote "cd $DEPLOY_PATH && docker compose --env-file ./backend/.env -f docker-compose.yml -f docker-compose.prod.yml exec backend python manage.py migrate"
run_remote "cd $DEPLOY_PATH && docker compose --env-file ./backend/.env -f docker-compose.yml -f docker-compose.prod.yml exec backend python manage.py collectstatic --noinput"


# 7. Check Health
echo "Waiting for services to be healthy..."
sleep 15
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://${SERVER_IP}/health/)

if [ "$STATUS" == "200" ]; then
    echo "✅ Deployment Successful! Access at http://${SERVER_IP}"
else
    echo "⚠️ Warning: Health check returned $STATUS. Check logs manually."
fi
