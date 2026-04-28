#!/bin/bash
#===============================================================================
# REBUILD FLUTTER WEB FRONTEND WITH HTTPS API URL
#===============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "==============================================================================="
echo "  REBUILDING FLUTTER FRONTEND WITH HTTPS API CONFIGURATION"
echo "==============================================================================="
echo -e "${NC}"

FRONTEND_DIR="/home/tk/lms-prod/frontend"
SERVER_IP="154.66.211.3"

cd "$FRONTEND_DIR"

echo -e "${BLUE}Step 1: Cleaning previous build...${NC}"
rm -rf "$FRONTEND_DIR/build/web"

echo -e "${BLUE}Step 2: Building Flutter web with HTTPS API URL...${NC}"
docker run --rm \
    -v "$FRONTEND_DIR:/app" \
    -w /app \
    ghcr.io/cirruslabs/flutter:stable \
    sh -c "flutter clean && flutter pub get && flutter build web --release \
        --dart-define=API_BASE_URL=https://hosiacademy.africa \
        --dart-define=SOCKET_URL=https://hosiacademy.africa \
        --dart-define=ENV=production" 2>&1 | tail -30

echo -e "\n${GREEN}✓ Flutter build complete${NC}"

echo -e "${BLUE}Step 3: Copying to prebuilt_web...${NC}"
rm -rf "$FRONTEND_DIR/prebuilt_web"
mkdir -p "$FRONTEND_DIR/prebuilt_web"
cp -r "$FRONTEND_DIR/build/web/"* "$FRONTEND_DIR/prebuilt_web/"

echo -e "${BLUE}Step 4: Rebuilding Docker image...${NC}"
cd /home/tk/lms-prod
docker-compose build frontend

echo -e "${BLUE}Step 5: Restarting frontend container...${NC}"
docker-compose up -d frontend

echo -e "${BLUE}Step 6: Verifying deployment...${NC}"
sleep 3
docker ps --filter "name=lms-prod-frontend" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo -e "${GREEN}"
echo "==============================================================================="
echo "  ✅ FRONTEND REBUILT WITH HTTPS!"
echo "==============================================================================="
echo -e "${NC}"

echo -e "${YELLOW}IMPORTANT: Clear browser cache (Ctrl+Shift+R) to see changes${NC}"
echo ""
echo -e "${BLUE}API Configuration:${NC}"
echo "  API Base URL: https://hosiacademy.africa"
echo "  Socket URL:   https://hosiacademy.africa"
echo ""
echo -e "${BLUE}All API calls will now use HTTPS instead of HTTP${NC}"
