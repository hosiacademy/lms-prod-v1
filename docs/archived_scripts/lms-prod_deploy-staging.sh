#!/bin/bash

# ==================== LMS STAGING DEPLOYMENT SCRIPT ====================
# Deploys the LMS platform to staging server at 154.66.211.3
# Uses Docker Compose with ports 7000 and 7001
#
# Usage:
#   ./deploy-staging.sh
#
# Requirements:
#   - Docker and Docker Compose installed on staging server
#   - SSH access to staging server
#   - Firewall configured (ports 7000, 7001, 5432, 6379 open)

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STAGING_SERVER="154.66.211.3"
DEPLOY_USER="root"  # Change if using non-root user
DEPLOY_PATH="/opt/lms-staging"
GIT_REPO="$(git remote get-url origin 2>/dev/null || echo 'not-a-git-repo')"
BRANCH="main"  # or staging branch if you have one

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}LMS Staging Deployment Script${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo "Staging Server: $STAGING_SERVER"
echo "Deploy Path: $DEPLOY_PATH"
echo "Ports: 7000 (backend), 7001 (backend-secondary)"
echo ""

# Function to run commands on staging server
run_remote() {
    ssh ${DEPLOY_USER}@${STAGING_SERVER} "$@"
}

# Function to copy files to staging server
copy_to_staging() {
    scp -r "$1" ${DEPLOY_USER}@${STAGING_SERVER}:"$2"
}

echo -e "${YELLOW}Step 1: Checking SSH connection...${NC}"
if ! ssh -o ConnectTimeout=5 ${DEPLOY_USER}@${STAGING_SERVER} "echo 'SSH connection successful'"; then
    echo -e "${RED}❌ Cannot connect to staging server${NC}"
    echo "Please check:"
    echo "  1. Server IP is correct: $STAGING_SERVER"
    echo "  2. SSH is configured properly"
    echo "  3. You have the correct credentials"
    exit 1
fi
echo -e "${GREEN}✅ SSH connection successful${NC}"
echo ""

echo -e "${YELLOW}Step 2: Checking Docker installation on staging server...${NC}"
if run_remote "docker --version && docker-compose --version"; then
    echo -e "${GREEN}✅ Docker and Docker Compose are installed${NC}"
else
    echo -e "${RED}❌ Docker or Docker Compose not found${NC}"
    echo "Installing Docker on staging server..."
    run_remote "curl -fsSL https://get.docker.com | sh && \
                sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && \
                sudo chmod +x /usr/local/bin/docker-compose"
    echo -e "${GREEN}✅ Docker installed${NC}"
fi
echo ""

echo -e "${YELLOW}Step 3: Creating deployment directory...${NC}"
run_remote "mkdir -p $DEPLOY_PATH"
echo -e "${GREEN}✅ Directory created: $DEPLOY_PATH${NC}"
echo ""

echo -e "${YELLOW}Step 4: Copying project files to staging server...${NC}"
echo "This may take a few minutes..."

# Create a temporary directory for files to deploy
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy necessary files
cp -r backend $TEMP_DIR/
cp docker-compose.yml $TEMP_DIR/
cp docker-compose.staging.yml $TEMP_DIR/
cp -r infrastructure $TEMP_DIR/ 2>/dev/null || true
cp -r scripts $TEMP_DIR/ 2>/dev/null || true

# Copy .env file
cp backend/.env $TEMP_DIR/backend/.env

echo "Transferring files to staging server..."
rsync -avz --progress $TEMP_DIR/ ${DEPLOY_USER}@${STAGING_SERVER}:${DEPLOY_PATH}/

echo -e "${GREEN}✅ Files copied to staging server${NC}"
echo ""

echo -e "${YELLOW}Step 5: Building Docker images on staging server...${NC}"
run_remote "cd $DEPLOY_PATH && docker-compose -f docker-compose.yml -f docker-compose.staging.yml build"
echo -e "${GREEN}✅ Docker images built${NC}"
echo ""

echo -e "${YELLOW}Step 6: Starting services...${NC}"
run_remote "cd $DEPLOY_PATH && docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d"
echo -e "${GREEN}✅ Services started${NC}"
echo ""

echo -e "${YELLOW}Step 7: Waiting for services to be healthy...${NC}"
sleep 10  # Give services time to start

run_remote "cd $DEPLOY_PATH && docker-compose -f docker-compose.yml -f docker-compose.staging.yml ps"
echo ""

echo -e "${YELLOW}Step 8: Running database migrations...${NC}"
run_remote "cd $DEPLOY_PATH && docker-compose -f docker-compose.yml -f docker-compose.staging.yml exec -T backend python manage.py migrate"
echo -e "${GREEN}✅ Migrations completed${NC}"
echo ""

echo -e "${YELLOW}Step 9: Collecting static files...${NC}"
run_remote "cd $DEPLOY_PATH && docker-compose -f docker-compose.yml -f docker-compose.staging.yml exec -T backend python manage.py collectstatic --noinput"
echo -e "${GREEN}✅ Static files collected${NC}"
echo ""

echo -e "${YELLOW}Step 10: Testing health endpoints...${NC}"
echo "Testing port 7000..."
if curl -s -f http://${STAGING_SERVER}:7000/health/ > /dev/null; then
    echo -e "${GREEN}✅ Port 7000 is responding${NC}"
else
    echo -e "${RED}⚠️  Port 7000 is not responding yet${NC}"
fi

echo "Testing port 7001..."
if curl -s -f http://${STAGING_SERVER}:7001/health/ > /dev/null; then
    echo -e "${GREEN}✅ Port 7001 is responding${NC}"
else
    echo -e "${RED}⚠️  Port 7001 is not responding yet${NC}"
fi
echo ""

echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}✅ Staging Deployment Complete!${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo "Access your staging environment:"
echo "  - Backend (Port 7000): http://${STAGING_SERVER}:7000"
echo "  - Backend (Port 7001): http://${STAGING_SERVER}:7001"
echo "  - Admin Panel: http://${STAGING_SERVER}:7000/admin/"
echo "  - Health Check: http://${STAGING_SERVER}:7000/health/"
echo "  - API Health: http://${STAGING_SERVER}:7000/api/health/"
echo ""
echo "Useful commands:"
echo "  - View logs: ssh ${DEPLOY_USER}@${STAGING_SERVER} 'cd ${DEPLOY_PATH} && docker-compose -f docker-compose.yml -f docker-compose.staging.yml logs -f'"
echo "  - Restart services: ssh ${DEPLOY_USER}@${STAGING_SERVER} 'cd ${DEPLOY_PATH} && docker-compose -f docker-compose.yml -f docker-compose.staging.yml restart'"
echo "  - Stop services: ssh ${DEPLOY_USER}@${STAGING_SERVER} 'cd ${DEPLOY_PATH} && docker-compose -f docker-compose.yml -f docker-compose.staging.yml down'"
echo ""
echo "Next steps:"
echo "  1. Create superuser: ssh ${DEPLOY_USER}@${STAGING_SERVER} 'cd ${DEPLOY_PATH} && docker-compose -f docker-compose.yml -f docker-compose.staging.yml exec backend python manage.py createsuperuser'"
echo "  2. Test all critical flows"
echo "  3. Monitor logs for errors"
echo ""
