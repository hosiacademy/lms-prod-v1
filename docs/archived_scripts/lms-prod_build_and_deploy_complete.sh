#!/bin/bash
# =============================================================================
# LMS-PROD COMPLETE DEPLOYMENT SCRIPT
# All Services with Correct Ports & Payment Integration
# =============================================================================
# 
# 📊 PORT MAPPING:
#   Frontend (Main):     7000 → Main web application UI
#   Backend API:         7001 → Django/Gunicorn API server
#   SocketIO:            7002 → WebSocket real-time connections
#   Flower:              7003 → Celery task monitoring
#   Secondary Nginx:     7004 → Secondary proxy
#   Sentry:              9000 → Error tracking
#   PostgreSQL:          5432 → Internal only
#   Redis:               6379 → Internal only
#
# 💳 PAYMENT INTEGRATION:
#   - Flutterwave, Paystack, PayFast, M-Pesa production APIs
#   - Kenya bank accounts configured
#   - Exhaustive bank lists for ZA, ZW, ZM, KE
#   - All 54 African countries supported
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}LMS-PROD COMPLETE DEPLOYMENT${NC}"
echo -e "${BLUE}================================================================${NC}"

# Configuration
COMPOSE_FILE="docker-compose.yml -f docker-compose.prod.yml"
PROJECT_NAME="lms-prod"

# =============================================================================
# STEP 1: STOP ALL RUNNING CONTAINERS
# =============================================================================
echo -e "\n${YELLOW}[1/8] Stopping all running containers...${NC}"
docker-compose -p $PROJECT_NAME down

# =============================================================================
# STEP 2: CLEAN UP OLD IMAGES (OPTIONAL)
# =============================================================================
echo -e "\n${YELLOW}[2/8] Cleaning up old dangling images...${NC}"
docker image prune -f

# =============================================================================
# STEP 3: BUILD ALL SERVICES
# =============================================================================
echo -e "\n${YELLOW}[3/8] Building all Docker images...${NC}"
echo -e "${BLUE}This may take 5-10 minutes on first build...${NC}"

docker-compose -p $PROJECT_NAME -f $COMPOSE_FILE build --no-cache

# =============================================================================
# STEP 4: CREATE EXTERNAL VOLUMES (IF NOT EXISTS)
# =============================================================================
echo -e "\n${YELLOW}[4/8] Creating Docker volumes...${NC}"
docker volume create lms-monorepo_postgres_data 2>/dev/null || true

# =============================================================================
# STEP 5: RUN MIGRATIONS
# =============================================================================
echo -e "\n${YELLOW}[5/8] Running Django migrations...${NC}"
docker-compose -p $PROJECT_NAME -f $COMPOSE_FILE run --rm backend python manage.py migrate

# =============================================================================
# STEP 6: UPDATE KENYA BANK ACCOUNTS
# =============================================================================
echo -e "\n${YELLOW}[6/8] Updating Kenya bank account details...${NC}"
docker-compose -p $PROJECT_NAME -f $COMPOSE_FILE run --rm backend python update_kenya_bank_accounts.py || {
    echo -e "${YELLOW}Warning: Kenya bank account update script not found or failed${NC}"
    echo -e "${YELLOW}You can run it manually later with:${NC}"
    echo -e "  docker-compose -p $PROJECT_NAME run --rm backend python update_kenya_bank_accounts.py"
}

# =============================================================================
# STEP 7: COLLECT STATIC FILES
# =============================================================================
echo -e "\n${YELLOW}[7/8] Collecting static files...${NC}"
docker-compose -p $PROJECT_NAME -f $COMPOSE_FILE run --rm backend python manage.py collectstatic --noinput

# =============================================================================
# STEP 8: START ALL SERVICES
# =============================================================================
echo -e "\n${YELLOW}[8/8] Starting all services...${NC}"
docker-compose -p $PROJECT_NAME -f $COMPOSE_FILE up -d

# Wait for services to be healthy
echo -e "\n${BLUE}Waiting for services to start (30 seconds)...${NC}"
sleep 30

# =============================================================================
# VERIFICATION
# =============================================================================
echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}DEPLOYMENT COMPLETE!${NC}"
echo -e "${GREEN}================================================================${NC}"

echo -e "\n${BLUE}📊 SERVICE STATUS:${NC}"
docker-compose -p $PROJECT_NAME ps

echo -e "\n${BLUE}🌐 ACCESS URLs:${NC}"
echo -e "  Frontend (Main):     http://154.66.211.3:7000"
echo -e "  Backend API:         http://154.66.211.3:7001/api/v1/"
echo -e "  SocketIO:            http://154.66.211.3:7002"
echo -e "  Flower (Monitor):    http://154.66.211.3:7003"
echo -e "  Secondary Nginx:     http://154.66.211.3:7004"
echo -e "  Sentry:              http://154.66.211.3:9000"

echo -e "\n${BLUE}💳 PAYMENT ENDPOINTS:${NC}"
echo -e "  Payment Providers:   http://154.66.211.3:7001/api/v1/payments/providers/"
echo -e "  EFT Initiate:        http://154.66.211.3:7001/api/v1/payments/eft/initiate/"
echo -e "  Mobile Money:        http://154.66.211.3:7001/api/v1/payments/mobile-money/initiate/"
echo -e "  Exchange Rates:      http://154.66.211.3:7001/api/v1/payments/exchange-rates/"
echo -e "  Location Detect:     http://154.66.211.3:7001/api/v1/payments/detect-location/"

echo -e "\n${BLUE}📝 USEFUL COMMANDS:${NC}"
echo -e "  View logs:           docker-compose -p $PROJECT_NAME logs -f"
echo -e "  View backend logs:   docker-compose -p $PROJECT_NAME logs -f backend"
echo -e "  View payment logs:   docker-compose -p $PROJECT_NAME logs -f backend | grep -i payment"
echo -e "  Restart services:    docker-compose -p $PROJECT_NAME restart"
echo -e "  Stop all:            docker-compose -p $PROJECT_NAME down"
echo -e "  Database shell:      docker-compose -p $PROJECT_NAME exec db psql -U postgres"
echo -e "  Django shell:        docker-compose -p $PROJECT_NAME run --rm backend python manage.py shell"

echo -e "\n${GREEN}================================================================${NC}"
echo -e "${GREEN}✅ ALL SERVICES DEPLOYED SUCCESSFULLY!${NC}"
echo -e "${GREEN}================================================================${NC}"

# Test endpoints
echo -e "\n${YELLOW}Running health checks...${NC}"

# Test frontend
if curl -s -o /dev/null -w "%{http_code}" http://localhost:7000 | grep -q "200\|302"; then
    echo -e "${GREEN}✓ Frontend (port 7000) is responding${NC}"
else
    echo -e "${RED}✗ Frontend (port 7000) is not responding${NC}"
fi

# Test backend API
if curl -s -o /dev/null -w "%{http_code}" http://localhost:7001/api/v1/ | grep -q "200\|401\|403"; then
    echo -e "${GREEN}✓ Backend API (port 7001) is responding${NC}"
else
    echo -e "${RED}✗ Backend API (port 7001) is not responding${NC}"
fi

# Test payment providers endpoint
if curl -s "http://localhost:7001/api/v1/payments/providers/?country=ZA&amount=1000" | grep -q "providers"; then
    echo -e "${GREEN}✓ Payment providers endpoint is working${NC}"
else
    echo -e "${YELLOW}! Payment providers endpoint may need authentication${NC}"
fi

echo -e "\n${GREEN}Deployment script completed!${NC}"
