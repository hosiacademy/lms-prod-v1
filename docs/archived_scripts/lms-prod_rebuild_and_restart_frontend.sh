#!/bin/bash
#===============================================================================
# REBUILD FRONTEND CONTAINER IMAGE AND RESTART
#===============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "==============================================================================="
echo "  REBUILDING FRONTEND CONTAINER WITH NEW PRICING"
echo "==============================================================================="
echo -e "${NC}"

cd /home/tk/lms-prod

echo -e "${BLUE}Step 1: Stopping frontend container...${NC}"
docker stop lms-prod-frontend-1 || true

echo -e "${BLUE}Step 2: Removing old frontend container...${NC}"
docker rm lms-prod-frontend-1 || true

echo -e "${BLUE}Step 3: Rebuilding frontend image...${NC}"
docker-compose build frontend

echo -e "${BLUE}Step 4: Starting frontend container...${NC}"
docker-compose up -d frontend

echo -e "${BLUE}Step 5: Waiting for startup...${NC}"
sleep 3

echo -e "${BLUE}Step 6: Verifying deployment...${NC}"
docker ps --filter "name=lms-prod-frontend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "${GREEN}"
echo "==============================================================================="
echo "  ✅ FRONTEND CONTAINER REBUILT!"
echo "==============================================================================="
echo -e "${NC}"

echo -e "${YELLOW}IMPORTANT: Clear browser cache (Ctrl+Shift+R) to see new pricing${NC}"
echo ""
echo -e "${BLUE}Updated Pricing:${NC}"
echo "  AICERTS Professional:    \$180.00"
echo "  AICERTS Technical:       \$260.00"
echo "  Masterclass Prof Phys:   \$470.00"
echo "  Masterclass Prof Online: \$320.00"
echo "  Masterclass Tech Phys:   \$680.00"
echo "  Masterclass Tech Online: \$430.00"
