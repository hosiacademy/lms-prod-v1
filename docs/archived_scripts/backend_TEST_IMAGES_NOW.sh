#!/bin/bash
# Quick test script to verify profile pictures are working
# Run this: bash TEST_IMAGES_NOW.sh

echo "=========================================="
echo "PROFILE PICTURES TEST - Hosi Academy LMS"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "Step 1: Checking media directory..."
if [ -d "media/profiles/defaults" ]; then
    echo -e "${GREEN}✓${NC} Media directory exists"
    echo "  Files found:"
    ls -1 media/profiles/defaults/ | head -10
    file_count=$(ls -1 media/profiles/defaults/ | wc -l)
    echo "  Total: $file_count files"
else
    echo -e "${RED}✗${NC} Media directory NOT found: media/profiles/defaults/"
    echo ""
    echo -e "${YELLOW}CREATING directory...${NC}"
    mkdir -p media/profiles/defaults
    echo -e "${GREEN}✓${NC} Created media/profiles/defaults directory"
    echo ""
    echo -e "${YELLOW}INFO:${NC} Please copy your default profile images to this directory:"
    echo "       - Female defaults: sl1.jpeg, sl2.jpeg, etc."
    echo "       - Male defaults: sm1.jpeg, sm2.jpeg, etc."
fi

echo ""
echo "Step 2: Testing database users..."
python manage.py test_profile_pictures

echo ""
echo "Step 3: Starting Django server..."
echo "  Server will start at http://localhost:8000"
echo ""
echo -e "${GREEN}After server starts, test these URLs in your browser:${NC}"
echo ""
echo "  1. Test API endpoint:"
echo "     http://localhost:8000/api/v1/profiles/test-images/"
echo ""
echo "  2. Get all profiles:"
echo "     http://localhost:8000/api/v1/profiles/?page=1&limit=20"
echo ""
echo "  3. Test image directly:"
echo "     http://localhost:8000/media/profiles/defaults/sl1.jpeg"
echo ""
echo -e "${YELLOW}Press Ctrl+C to stop the server${NC}"
echo ""
echo "=========================================="
echo "Starting server in 3 seconds..."
sleep 3

python manage.py runserver
