#!/bin/bash

# ==================== LMS DEPLOYMENT USING SSH CONFIG ====================
# Uses SSH config alias 'entai' for connection
# Your ~/.ssh/config should have:
#   Host entai
#     HostName 154.66.211.3
#     User tk
#     Port 2222
#     IdentityFile ~/.ssh/id_rsa

set -e

DEPLOY_PATH="/opt/lms-prod"
SSH_HOST="entai"

echo "🚀 Starting Deployment using SSH config alias: $SSH_HOST"

# Function to run remote commands
run_remote() {
    ssh $SSH_HOST "$@"
}

echo "✓ Testing SSH connection..."
if ! run_remote "echo 'SSH connection successful'"; then
    echo "❌ Cannot connect to server"
    exit 1
fi

echo "✓ Checking Docker installation..."
if ! run_remote "docker --version" > /dev/null 2>&1; then
    echo "Installing Docker..."
    run_remote "curl -fsSL https://get.docker.com | sh"
    run_remote "sudo usermod -aG docker tk"
fi

echo "✓ Creating deployment directory..."
run_remote "sudo mkdir -p $DEPLOY_PATH && sudo chown -R tk:tk $DEPLOY_PATH"

echo "✓ Copying files..."
rsync -avz -e "ssh" \
    --exclude '.git' \
    --exclude '.venv' \
    --exclude 'node_modules' \
    --exclude '__pycache__' \
    --exclude 'local_backup.sql' \
    . ${SSH_HOST}:${DEPLOY_PATH}/

echo "✓ Copying database backup..."
scp local_backup.sql ${SSH_HOST}:${DEPLOY_PATH}/

echo "✓ Setting up environment..."
run_remote "cd $DEPLOY_PATH/backend && if [ ! -f .env ]; then cp .env.example .env; fi"

echo "✓ Building and starting services..."
run_remote "cd $DEPLOY_PATH && docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d --build"

echo "⏳ Waiting for services to start..."
sleep 15

echo "✓ Running migrations..."
run_remote "cd $DEPLOY_PATH && docker compose exec -T backend python manage.py migrate"

echo "✓ Collecting static files..."
run_remote "cd $DEPLOY_PATH && docker compose exec -T backend python manage.py collectstatic --noinput"

echo "✓ Restoring database..."
run_remote "cd $DEPLOY_PATH && docker compose exec -T db psql -U postgres -d hosiacademylms < local_backup.sql"

echo ""
echo "========================================="
echo "✅ Deployment Complete!"
echo "========================================="
echo ""
echo "Access your LMS at: http://154.66.211.3"
echo ""
echo "Useful commands:"
echo "  View logs: ssh $SSH_HOST 'cd $DEPLOY_PATH && docker compose logs -f'"
echo "  Restart: ssh $SSH_HOST 'cd $DEPLOY_PATH && docker compose restart'"
echo "  Stop: ssh $SSH_HOST 'cd $DEPLOY_PATH && docker compose down'"
