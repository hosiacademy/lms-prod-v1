#!/bin/bash
# =============================================================================
# FORCE COMPLETE REBUILD AND DEPLOY
# Clears all caches and builds fresh
# =============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}  FORCE REBUILD - Clearing All Caches${NC}"
echo -e "${BLUE}================================================================${NC}"

cd /home/tk/lms-prod

# Step 1: Clear Flutter build cache
echo -e "\n${YELLOW}[1/6] Clearing Flutter cache...${NC}"
cd /home/tk/lms-prod/frontend
rm -rf build/web
rm -rf .dart_tool/build
flutter clean

# Step 2: Get dependencies
echo -e "\n${YELLOW}[2/6] Getting Flutter dependencies...${NC}"
flutter pub get

# Step 3: Build with no cache
echo -e "\n${YELLOW}[3/6] Building Flutter web (fresh)...${NC}"
flutter build web --release

# Step 4: Patch service worker with cache-busting
echo -e "\n${YELLOW}[4/6] Adding cache-busting to service worker...${NC}"
cat > build/web/flutter_service_worker.js << EOF
'use strict';
const CACHE_NAME = 'flutter-app-cache-v${BUILD_TIME:-$(date +%s)}';

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames.map((cacheName) => {
          if (cacheName !== CACHE_NAME) {
            return caches.delete(cacheName);
          }
        })
      );
    }).then(() => {
      return self.clients.claim();
    })
  );
});
EOF

# Step 5: Clear nginx cache and copy files
echo -e "\n${YELLOW}[5/6] Deploying to container...${NC}"
docker exec lms-prod-frontend-1 rm -rf /usr/share/nginx/html/*
docker cp build/web/. lms-prod-frontend-1:/usr/share/nginx/html/

# Step 6: Restart nginx and set proper permissions
echo -e "\n${YELLOW}[6/6] Restarting nginx...${NC}"
docker exec lms-prod-frontend-1 chmod -R 755 /usr/share/nginx/html
docker exec lms-prod-frontend-1 nginx -s reload

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}✅ FRESH BUILD DEPLOYED${NC}"
echo -e "${GREEN}================================================================${NC}"
echo -e ""
echo -e "${YELLOW}IMPORTANT: Clear your browser cache!${NC}"
echo -e "  Chrome: Ctrl+Shift+R (or Cmd+Shift+R on Mac)"
echo -e "  Or open DevTools (F12) → Network → Disable cache → Reload"
echo -e ""
echo -e "Test at: ${BLUE}http://154.66.211.3:7000${NC}"
echo -e ""
