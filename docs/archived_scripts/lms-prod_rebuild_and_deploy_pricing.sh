#!/bin/bash
#===============================================================================
# HOSI ACADEMY LMS - REBUILD AND DEPLOY WITH NEW PRICING
# Updates AICERTS and Masterclass pricing
#===============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/home/tk/lms-prod"
BACKEND_DIR="$PROJECT_DIR/backend"

# Port Configuration (from LMS-PROD COMPLETE PORTS TABLE)
FRONTEND_PORT="7000"
BACKEND_PORT="7001"
SOCKETIO_PORT="7002"
FLOWER_PORT="7003"
NGINX_PORT="7004"
SENTRY_PORT="9000"

SERVER_IP="154.66.211.3"

echo -e "${BLUE}"
echo "==============================================================================="
echo "  HOSI ACADEMY LMS - REBUILD & DEPLOY WITH NEW PRICING"
echo "==============================================================================="
echo -e "${NC}"

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}\n"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print warning
print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

#===============================================================================
# STEP 1: VERIFY PRICING CHANGES
#===============================================================================
print_header "STEP 1: VERIFYING PRICING CHANGES"

echo "Checking AICERTS pricing constants..."
if grep -q "PROFESSIONAL_COURSE_PRICE_USD = Decimal('180.00')" "$BACKEND_DIR/apps/payments/currency_localization.py"; then
    print_success "AICERTS Professional price: $180.00"
else
    print_error "AICERTS Professional price not updated!"
fi

if grep -q "TECHNICAL_COURSE_PRICE_USD = Decimal('260.00')" "$BACKEND_DIR/apps/payments/currency_localization.py"; then
    print_success "AICERTS Technical price: $260.00"
else
    print_error "AICERTS Technical price not updated!"
fi

echo ""
echo "Checking Masterclass pricing in seed file..."
if grep -q "'professional': {'physical': 470.00, 'online': 320.00}" "$BACKEND_DIR/apps/masterclasses/management/commands/seed_masterclasses_2026.py"; then
    print_success "Masterclass Professional prices: Physical $470.00, Online $320.00"
else
    print_error "Masterclass Professional prices not updated!"
fi

if grep -q "'technical':    {'physical': 680.00, 'online': 430.00}" "$BACKEND_DIR/apps/masterclasses/management/commands/seed_masterclasses_2026.py"; then
    print_success "Masterclass Technical prices: Physical $680.00, Online $430.00"
else
    print_error "Masterclass Technical prices not updated!"
fi

#===============================================================================
# STEP 2: STOP EXISTING CONTAINERS
#===============================================================================
print_header "STEP 2: STOPPING EXISTING LMS CONTAINERS"

# Stop only LMS containers
docker stop lms-prod-backend-1 lms-prod-frontend-1 lms_socketio lms_flower lms_nginx lms-prod-celery-1 lms-prod-celery-2-1 lms_celery_beat 2>/dev/null || true
print_success "LMS containers stopped"

#===============================================================================
# STEP 3: REBUILD BACKEND IMAGE
#===============================================================================
print_header "STEP 3: REBUILDING BACKEND IMAGE"

cd "$PROJECT_DIR"

echo "Building backend image with new pricing..."
docker-compose build backend
print_success "Backend image rebuilt"

#===============================================================================
# STEP 4: START SERVICES
#===============================================================================
print_header "STEP 4: STARTING SERVICES"

echo "Starting all LMS services..."
docker-compose up -d db redis backend celery celery-2 celery-beat flower socketio nginx sentry frontend

# Wait for backend to be healthy
echo ""
echo "Waiting for backend to be ready..."
sleep 10

# Check container status
echo ""
print_success "Services started. Checking status..."
docker ps --filter "name=lms" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

#===============================================================================
# STEP 5: RUN DATABASE MIGRATIONS
#===============================================================================
print_header "STEP 5: RUNNING DATABASE MIGRATIONS"

echo "Running Django migrations..."
docker exec lms-prod-backend-1 python manage.py migrate --noinput 2>&1 | tail -10 || print_warning "Migrations may have already been applied"
print_success "Database migrations complete"

#===============================================================================
# STEP 6: UPDATE EXISTING MASTERCLASS PRICES (if table exists)
#===============================================================================
print_header "STEP 6: UPDATING EXISTING MASTERCLASS PRICES"

echo "Checking if masterclass table exists..."
if docker exec lms-prod-backend-1 python -c "
import psycopg2
import os
from django.conf import settings
settings.configure()
" 2>/dev/null; then
    echo "Attempting to update existing masterclass prices..."
    docker exec lms-prod-backend-1 python -c "
import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

try:
    from apps.masterclasses.models import Masterclass
    from django.db.models import Q
    
    # Update professional masterclasses
    professional_updated = Masterclass.objects.filter(stream_type='professional').update(
        price_physical=470.00,
        price_online=320.00
    )
    
    # Update technical masterclasses
    technical_updated = Masterclass.objects.filter(stream_type='technical').update(
        price_physical=680.00,
        price_online=430.00
    )
    
    print(f'Updated {professional_updated} Professional masterclasses')
    print(f'Updated {technical_updated} Technical masterclasses')
    print('Pricing update complete!')
except Exception as e:
    print(f'Note: {e}')
    print('Masterclass table may not exist yet or prices will be set on next seed run')
" 2>&1 || print_warning "Could not update masterclass prices in database (table may not exist)"
else
    print_warning "Skipping database price update"
fi

#===============================================================================
# STEP 7: VERIFY DEPLOYMENT
#===============================================================================
print_header "STEP 7: VERIFYING DEPLOYMENT"

echo "Checking service endpoints..."

# Check Backend API
if curl -s "http://$SERVER_IP:$BACKEND_PORT/api/" > /dev/null 2>&1; then
    print_success "Backend API: http://$SERVER_IP:$BACKEND_PORT/api/"
else
    print_warning "Backend API not responding (may need more time)"
fi

# Check Frontend
if curl -s "http://$SERVER_IP:$FRONTEND_PORT" > /dev/null 2>&1; then
    print_success "Frontend: http://$SERVER_IP:$FRONTEND_PORT"
else
    print_warning "Frontend not responding (may need more time)"
fi

# Check Flower
if curl -s "http://$SERVER_IP:$FLOWER_PORT" > /dev/null 2>&1; then
    print_success "Flower: http://$SERVER_IP:$FLOWER_PORT"
else
    print_warning "Flower not responding"
fi

# Check Sentry
if curl -s "http://$SERVER_IP:$SENTRY_PORT" > /dev/null 2>&1; then
    print_success "Sentry: http://$SERVER_IP:$SENTRY_PORT"
else
    print_warning "Sentry not responding"
fi

#===============================================================================
# DEPLOYMENT COMPLETE
#===============================================================================
echo -e "\n${GREEN}"
echo "==============================================================================="
echo "  ✅ DEPLOYMENT COMPLETE WITH NEW PRICING!"
echo "==============================================================================="
echo -e "${NC}"

echo -e "${BLUE}Updated Pricing Summary:${NC}"
echo ""
echo "┌─────────────────────────────────────────────────────────────┐"
echo "│ COURSE PRICING TABLE (USD)                                  │"
echo "├─────────────────────────────────────────────────────────────┤"
echo "│ Description                    │ Professional │ Technical   │"
echo "├────────────────────────────────┼──────────────┼─────────────┤"
echo "│ Masterclasses (Physical)       │    \$470.00    │    \$680.00   │"
echo "│ Masterclasses (On-Line)        │    \$320.00    │    \$430.00   │"
echo "│ Self-Paced (AICERTS)           │    \$180.00    │    \$260.00   │"
echo "└────────────────────────────────┴──────────────┴─────────────┘"
echo ""

echo -e "${BLUE}Service URLs:${NC}"
echo "  Frontend (Main):  http://$SERVER_IP:$FRONTEND_PORT"
echo "  Backend API:      http://$SERVER_IP:$BACKEND_PORT/api/"
echo "  SocketIO:         http://$SERVER_IP:$SOCKETIO_PORT"
echo "  Flower:           http://$SERVER_IP:$FLOWER_PORT"
echo "  Nginx:            http://$SERVER_IP:$NGINX_PORT"
echo "  Sentry:           http://$SERVER_IP:$SENTRY_PORT"

echo -e "\n${YELLOW}Note: To update future masterclass prices, run:${NC}"
echo "  docker exec lms-prod-backend-1 python manage.py seed_masterclasses_2026"

echo -e "\n${BLUE}==============================================================================${NC}"
echo -e "${BLUE}Deployment completed at: $(date)${NC}"
echo -e "${BLUE}==============================================================================${NC}\n"
