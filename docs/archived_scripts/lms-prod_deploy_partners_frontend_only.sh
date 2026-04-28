#!/bin/bash
# =============================================================================
# DEPLOY PARTNERS FEATURE - FRONTEND ONLY (Workaround)
# Run this on production server
# =============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}DEPLOYING PARTNERS FEATURE (Frontend Only)${NC}"
echo -e "${BLUE}================================================================${NC}"

cd /home/tk/lms-prod

# Build Flutter Frontend
echo -e "\n${YELLOW}[1/3] Building Flutter web...${NC}"
cd /home/tk/lms-prod/frontend
flutter build web --release --web-renderer canvaskit

# Patch Service Worker
echo -e "\n${YELLOW}[2/3] Patching service worker...${NC}"
cat > build/web/flutter_service_worker.js << 'EOF'
'use strict';
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => { event.waitUntil(self.clients.claim()); });
EOF

# Deploy to Container
echo -e "\n${YELLOW}[3/3] Deploying to container...${NC}"
docker cp build/web/. lms-prod-frontend-1:/usr/share/nginx/html/
docker exec lms-prod-frontend-1 nginx -s reload

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}✅ PARTNERS MODAL DEPLOYED${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e ""
echo -e "Note: Backend has a pre-existing error with quotation_models"
echo -e "The Partners modal will work on the frontend."
echo -e ""
echo -e "Test at: ${BLUE}http://154.66.211.3:7000${NC}"
