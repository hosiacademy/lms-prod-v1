#!/bin/bash
#===============================================================================
# REBUILD FLUTTER WEB FRONTEND WITH NEW PRICING
#===============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "==============================================================================="
echo "  REBUILDING FLUTTER FRONTEND WITH NEW PRICING"
echo "==============================================================================="
echo -e "${NC}"

# Configuration
FRONTEND_DIR="/home/tk/lms-prod/frontend"
SERVER_IP="154.66.211.3"
BACKEND_PORT="7001"

cd "$FRONTEND_DIR"

# Verify pricing constants
echo -e "\n${BLUE}Verifying Pricing Constants...${NC}"
grep -A 6 "Masterclass pricing" "$FRONTEND_DIR/lib/src/core/constants/pricing_constants.dart"
grep -A 3 "AICERTS course pricing" "$FRONTEND_DIR/lib/src/core/constants/pricing_constants.dart"

echo -e "\n${BLUE}Cleaning previous build...${NC}"
rm -rf "$FRONTEND_DIR/build/web"

echo -e "${BLUE}Building Flutter web...${NC}"
docker run --rm \
    -v "$FRONTEND_DIR:/app" \
    -w /app \
    ghcr.io/cirruslabs/flutter:stable \
    sh -c "flutter clean && flutter pub get && flutter build web --release \
        --dart-define=API_BASE_URL=http://$SERVER_IP:$BACKEND_PORT \
        --dart-define=SOCKET_URL=http://$SERVER_IP:$BACKEND_PORT \
        --dart-define=ENV=production" 2>&1 | tail -30

echo -e "\n${GREEN}✓ Flutter build complete${NC}"

echo -e "\n${BLUE}Copying to prebuilt_web...${NC}"
rm -rf "$FRONTEND_DIR/prebuilt_web"
mkdir -p "$FRONTEND_DIR/prebuilt_web"
cp -r "$FRONTEND_DIR/build/web/"* "$FRONTEND_DIR/prebuilt_web/"

echo -e "\n${BLUE}Restarting frontend container...${NC}"
docker restart lms-prod-frontend-1

echo -e "\n${GREEN}"
echo "==============================================================================="
echo "  ✅ FLUTTER FRONTEND REBUILT WITH NEW PRICING!"
echo "==============================================================================="
echo -e "${NC}"

echo -e "${YELLOW}New Pricing in Frontend:${NC}"
echo "  AICERTS Professional:    $180.00"
echo "  AICERTS Technical:       $260.00"
echo "  Masterclass Prof Phys:   $470.00"
echo "  Masterclass Prof Online: $320.00"
echo "  Masterclass Tech Phys:   $680.00"
echo "  Masterclass Tech Online: $430.00"

echo -e "\n${BLUE}Clear browser cache to see changes (Ctrl+Shift+R)${NC}"
