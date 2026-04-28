#!/bin/bash

# ==================== QUICK STAGING DEPLOYMENT ====================
# Run this script ON THE STAGING SERVER (154.66.211.3)
# After copying project files to /opt/lms-staging
#
# Usage:
#   1. Copy project to server: scp -r lms-monorepo root@154.66.211.3:/opt/lms-staging
#   2. SSH to server: ssh root@154.66.211.3
#   3. Run this script: cd /opt/lms-staging && ./quick-deploy-staging.sh

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}Quick Staging Deployment${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.staging.yml" ]; then
    echo -e "${RED}❌ docker-compose.staging.yml not found${NC}"
    echo "Please run this script from /opt/lms-staging"
    exit 1
fi

echo -e "${YELLOW}Step 1: Stopping old Django servers...${NC}"
pkill -f "runserver" || true
echo -e "${GREEN}✅ Old servers stopped${NC}"
echo ""

echo -e "${YELLOW}Step 2: Checking Docker installation...${NC}"
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    echo -e "${GREEN}✅ Docker installed${NC}"
else
    echo -e "${GREEN}✅ Docker already installed${NC}"
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Installing Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✅ Docker Compose installed${NC}"
else
    echo -e "${GREEN}✅ Docker Compose already installed${NC}"
fi
echo ""

echo -e "${YELLOW}Step 3: Building Docker images...${NC}"
docker-compose -f docker-compose.yml -f docker-compose.staging.yml build
echo -e "${GREEN}✅ Images built${NC}"
echo ""

echo -e "${YELLOW}Step 4: Starting services...${NC}"
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d
echo -e "${GREEN}✅ Services started${NC}"
echo ""

echo -e "${YELLOW}Step 5: Waiting for services to be ready...${NC}"
sleep 15
docker-compose -f docker-compose.yml -f docker-compose.staging.yml ps
echo ""

echo -e "${YELLOW}Step 6: Running database migrations...${NC}"
docker-compose -f docker-compose.yml -f docker-compose.staging.yml exec -T backend python manage.py migrate
echo -e "${GREEN}✅ Migrations completed${NC}"
echo ""

echo -e "${YELLOW}Step 7: Collecting static files...${NC}"
docker-compose -f docker-compose.yml -f docker-compose.staging.yml exec -T backend python manage.py collectstatic --noinput
echo -e "${GREEN}✅ Static files collected${NC}"
echo ""

echo -e "${YELLOW}Step 8: Testing endpoints...${NC}"
echo "Testing port 7000..."
curl -s http://localhost:7000/health/ || echo -e "${RED}Port 7000 not responding yet${NC}"
echo ""
echo "Testing port 7001..."
curl -s http://localhost:7001/health/ || echo -e "${RED}Port 7001 not responding yet${NC}"
echo ""

echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}✅ Deployment Complete!${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo "Access points:"
echo "  - Port 7000: http://154.66.211.3:7000"
echo "  - Port 7001: http://154.66.211.3:7001"
echo "  - Admin: http://154.66.211.3:7000/admin/"
echo ""
echo "Next steps:"
echo "  1. Create superuser:"
echo "     docker-compose -f docker-compose.yml -f docker-compose.staging.yml exec backend python manage.py createsuperuser"
echo ""
echo "  2. View logs:"
echo "     docker-compose -f docker-compose.yml -f docker-compose.staging.yml logs -f"
echo ""
echo "  3. Test from external:"
echo "     curl http://154.66.211.3:7000/health/"
echo ""
