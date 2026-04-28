#!/bin/bash
# =============================================================================
# DEPLOY PARTNERS FEATURE SCRIPT
# Run this on production server (154.66.211.3)
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}DEPLOYING PARTNERS FEATURE${NC}"
echo -e "${BLUE}================================================================${NC}"

cd /home/tk/lms-prod

# Step 1: Backend Migrations (Create and Apply)
echo -e "\n${YELLOW}[1/4] Creating database migrations...${NC}"
docker-compose -p lms-prod run --rm backend python manage.py makemigrations referrals
echo -e "\n${YELLOW}[1.5/4] Applying migrations...${NC}"
docker-compose -p lms-prod run --rm backend python manage.py migrate

# Step 2: Build Flutter Frontend
echo -e "\n${YELLOW}[2/4] Building Flutter web...${NC}"
cd /home/tk/lms-prod/frontend
flutter build web --release

# Step 3: Patch Service Worker
echo -e "\n${YELLOW}[3/4] Patching service worker...${NC}"
cat > build/web/flutter_service_worker.js << 'EOF'
'use strict';
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => { event.waitUntil(self.clients.claim()); });
EOF

# Step 4: Deploy to Container
echo -e "\n${YELLOW}[4/4] Deploying to container...${NC}"
docker cp build/web/. lms-prod-frontend-1:/usr/share/nginx/html/
docker exec lms-prod-frontend-1 nginx -s reload

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}✅ PARTNERS FEATURE DEPLOYED SUCCESSFULLY${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e ""
echo -e "Test the feature at:"
echo -e "  ${BLUE}http://154.66.211.3:7000${NC}"
echo -e ""
echo -e "Check the footer 'Ecosystem' section for 'Partners' link"
echo -e ""
