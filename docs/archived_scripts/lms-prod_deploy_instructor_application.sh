#!/bin/bash
# Deployment Script for Instructor Application System
# Date: March 3, 2026

set -e  # Exit on error

echo "=========================================="
echo "Hosi Academy LMS - Instructor Application"
echo "System Deployment Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BACKEND_DIR="/home/tk/lms-prod/backend"
FRONTEND_DIR="/home/tk/lms-prod/frontend"
VENV_DIR="$BACKEND_DIR/venv_linux"

echo -e "${YELLOW}Step 1: Activating Python virtual environment...${NC}"
cd $BACKEND_DIR
source $VENV_DIR/bin/activate
echo -e "${GREEN}✓ Virtual environment activated${NC}"
echo ""

echo -e "${YELLOW}Step 2: Running database migrations...${NC}"
python manage.py migrate facilitators
echo -e "${GREEN}✓ Database migrations completed${NC}"
echo ""

echo -e "${YELLOW}Step 3: Collecting static files...${NC}"
python manage.py collectstatic --noinput
echo -e "${GREEN}✓ Static files collected${NC}"
echo ""

echo -e "${YELLOW}Step 4: Checking for migration issues...${NC}"
python manage.py makemigrations --dry-run --check 2>&1 | head -20 || true
echo -e "${GREEN}✓ Migration check completed${NC}"
echo ""

echo -e "${YELLOW}Step 5: Restarting backend services...${NC}"
# Adjust based on your service management (systemd, supervisor, etc.)
# Example for systemd:
# sudo systemctl restart lms-backend
# Example for supervisor:
# sudo supervisorctl restart lms-backend:*
echo -e "${YELLOW}⚠ Please restart your backend service manually:${NC}"
echo "   sudo systemctl restart lms-backend"
echo "   OR"
echo "   sudo supervisorctl restart lms-backend:*"
echo ""

echo -e "${YELLOW}Step 6: Building Flutter frontend...${NC}"
cd $FRONTEND_DIR
flutter build web --release
echo -e "${GREEN}✓ Frontend build completed${NC}"
echo ""

echo -e "${YELLOW}Step 7: Deploying frontend build...${NC}"
# Adjust based on your deployment setup
# Example: Copy to nginx directory
# sudo cp -r build/web/* /var/www/html/
echo -e "${YELLOW}⚠ Please deploy frontend build manually:${NC}"
echo "   Copy build/web/* to your web server directory"
echo ""

echo "=========================================="
echo -e "${GREEN}✓ Deployment Completed Successfully!${NC}"
echo "=========================================="
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Restart backend service"
echo "2. Deploy frontend build to web server"
echo "3. Verify email configuration"
echo "4. Configure BBB server in admin panel"
echo "5. Test application submission workflow"
echo ""
echo -e "${YELLOW}Verification Checklist:${NC}"
echo "□ Database tables created (instructor_applications, instructor_status_logs, instructor_analytics)"
echo "□ Email templates in place"
echo "□ API endpoints accessible"
echo "□ BBB integration configured"
echo "□ Test credentials show (lnsp) markers"
echo ""
echo -e "${GREEN}Done!${NC}"
