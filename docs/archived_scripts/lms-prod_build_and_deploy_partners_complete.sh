#!/bin/bash
# =============================================================================
# COMPLETE BUILD & DEPLOY SCRIPT FOR LMS-PROD
# Targets all containers and ports as specified
# =============================================================================
# SERVICES & PORTS:
#   Frontend (Main):     7000 → lms-prod-frontend-1:80
#   Backend API:         7001 → lms-prod-backend-1:8000
#   SocketIO:            7002 → lms_socketio:8001
#   Flower:              7003 → lms_flower:5555
#   Secondary Frontend:  7004 → lms_nginx:80
#   Sentry:              9000 → lms_sentry:9000
#   PostgreSQL:          Internal 5432 → lms_db
#   Redis:               Internal 6379 → lms_redis
#   Celery Workers:      Internal → lms_celery_beat, lms-prod-celery-1, lms-prod-celery-2-1
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PROJECT_NAME="lms-prod"
DEPLOY_LOG="/tmp/lms_deploy_$(date +%Y%m%d_%H%M%S).log"

echo -e "${BLUE}================================================================${NC}" | tee -a "$DEPLOY_LOG"
echo -e "${BLUE}  LMS-PROD COMPLETE BUILD & DEPLOY${NC}" | tee -a "$DEPLOY_LOG"
echo -e "${BLUE}  $(date '+%Y-%m-%d %H:%M:%S')${NC}" | tee -a "$DEPLOY_LOG"
echo -e "${BLUE}================================================================${NC}" | tee -a "$DEPLOY_LOG"

# Function to print section headers
print_section() {
    echo -e "\n${CYAN}$1${NC}" | tee -a "$DEPLOY_LOG"
    echo -e "${CYAN}$(printf '=%.0s' $(seq 1 60))${NC}" | tee -a "$DEPLOY_LOG"
}

# Function to check container status
check_container() {
    local container=$1
    if docker ps --format "{{.Names}}" | grep -q "^${container}$"; then
        echo -e "${GREEN}✓${NC} $container"
        return 0
    else
        echo -e "${RED}✗${NC} $container (NOT RUNNING)"
        return 1
    fi
}

cd /home/tk/lms-prod

# =============================================================================
# STEP 0: PRE-DEPLOYMENT CHECKS
# =============================================================================
print_section "[0/10] Pre-Deployment Checks"

echo -e "${YELLOW}Checking container status...${NC}" | tee -a "$DEPLOY_LOG"
check_container "lms_db"
check_container "lms_redis"
check_container "lms-prod-backend-1"
check_container "lms-prod-frontend-1"
check_container "lms_socketio"
check_container "lms_flower"
check_container "lms_nginx"
check_container "lms_celery_beat"
check_container "lms-prod-celery-1"
check_container "lms-prod-celery-2-1"
# =============================================================================
# STEP 1: BACKUP CURRENT STATE
# =============================================================================
print_section "[1/10] Creating Backup"

BACKUP_DIR="/home/tk/lms-prod/backups/pre_deploy_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo -e "${YELLOW}Backing up current frontend build...${NC}" | tee -a "$DEPLOY_LOG"
docker cp lms-prod-frontend-1:/usr/share/nginx/html "$BACKUP_DIR/frontend_backup" 2>/dev/null || echo "No existing build to backup"

echo -e "${GREEN}✓ Backup created at: $BACKUP_DIR${NC}" | tee -a "$DEPLOY_LOG"

# =============================================================================
# STEP 2: STOP FRONTEND (Zero-downtime strategy)
# =============================================================================
print_section "[2/10] Preparing Frontend"

echo -e "${YELLOW}Preparing frontend container...${NC}" | tee -a "$DEPLOY_LOG"
# Keep container running, we'll just update files

# =============================================================================
# STEP 3: BUILD FLUTTER WEB
# =============================================================================
print_section "[3/10] Building Flutter Web"

cd /home/tk/lms-prod/frontend

echo -e "${YELLOW}Cleaning previous build...${NC}" | tee -a "$DEPLOY_LOG"
rm -rf build/web

echo -e "${YELLOW}Running Flutter build...${NC}" | tee -a "$DEPLOY_LOG"
flutter build web --release 2>&1 | tee -a "$DEPLOY_LOG"

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Flutter build failed!${NC}" | tee -a "$DEPLOY_LOG"
    exit 1
fi

echo -e "${GREEN}✓ Flutter build completed${NC}" | tee -a "$DEPLOY_LOG"

# =============================================================================
# STEP 4: PATCH SERVICE WORKER
# =============================================================================
print_section "[4/10] Patching Service Worker"

cat > /home/tk/lms-prod/frontend/build/web/flutter_service_worker.js << 'EOF'
'use strict';
self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', (event) => { event.waitUntil(self.clients.claim()); });
EOF

echo -e "${GREEN}✓ Service worker patched${NC}" | tee -a "$DEPLOY_LOG"

# =============================================================================
# STEP 5: BACKEND MIGRATIONS
# =============================================================================
print_section "[5/10] Backend Migrations"

cd /home/tk/lms-prod

echo -e "${YELLOW}Creating migrations for referrals app...${NC}" | tee -a "$DEPLOY_LOG"
docker-compose -p $PROJECT_NAME run --rm backend python manage.py makemigrations referrals 2>&1 | tee -a "$DEPLOY_LOG"

echo -e "${YELLOW}Applying all migrations...${NC}" | tee -a "$DEPLOY_LOG"
docker-compose -p $PROJECT_NAME run --rm backend python manage.py migrate 2>&1 | tee -a "$DEPLOY_LOG"

echo -e "${GREEN}✓ Migrations complete${NC}" | tee -a "$DEPLOY_LOG"

# =============================================================================
# STEP 6: COLLECT STATIC FILES
# =============================================================================
print_section "[6/10] Collecting Static Files"

echo -e "${YELLOW}Collecting Django static files...${NC}" | tee -a "$DEPLOY_LOG"
docker-compose -p $PROJECT_NAME run --rm backend python manage.py collectstatic --noinput 2>&1 | tee -a "$DEPLOY_LOG"

echo -e "${GREEN}✓ Static files collected${NC}" | tee -a "$DEPLOY_LOG"

# =============================================================================
# STEP 7: DEPLOY FRONTEND
# =============================================================================
print_section "[7/10] Deploying Frontend"

echo -e "${YELLOW}Copying build to container lms-prod-frontend-1...${NC}" | tee -a "$DEPLOY_LOG"
docker cp /home/tk/lms-prod/frontend/build/web/. lms-prod-frontend-1:/usr/share/nginx/html/ 2>&1 | tee -a "$DEPLOY_LOG"

echo -e "${YELLOW}Reloading Nginx in frontend container...${NC}" | tee -a "$DEPLOY_LOG"
docker exec lms-prod-frontend-1 nginx -s reload 2>&1 | tee -a "$DEPLOY_LOG"

echo -e "${GREEN}✓ Frontend deployed on port 7000${NC}" | tee -a "$DEPLOY_LOG"

# =============================================================================
# STEP 8: RESTART BACKEND (if needed)
# =============================================================================
print_section "[8/10] Restarting Backend Services"

echo -e "${YELLOW}Restarting backend (port 7001)...${NC}" | tee -a "$DEPLOY_LOG"
docker-compose -p $PROJECT_NAME restart backend 2>&1 | tee -a "$DEPLOY_LOG"

echo -e "${YELLOW}Restarting SocketIO (port 7002)...${NC}" | tee -a "$DEPLOY_LOG"
docker-compose -p $PROJECT_NAME restart socketio 2>&1 | tee -a "$DEPLOY_LOG"

echo -e "${GREEN}✓ Backend services restarted${NC}" | tee -a "$DEPLOY_LOG"

# =============================================================================
# STEP 9: VERIFY DEPLOYMENT
# =============================================================================
print_section "[9/10] Verifying Deployment"

sleep 5

echo -e "${YELLOW}Checking service health...${NC}" | tee -a "$DEPLOY_LOG"

# Check Frontend (port 7000)
if curl -s -o /dev/null -w "%{http_code}" http://localhost:7000 | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✓ Frontend (port 7000) - OK${NC}" | tee -a "$DEPLOY_LOG"
else
    echo -e "${RED}✗ Frontend (port 7000) - FAILED${NC}" | tee -a "$DEPLOY_LOG"
fi

# Check Backend API (port 7001)
if curl -s -o /dev/null -w "%{http_code}" http://localhost:7001/api/ | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✓ Backend API (port 7001) - OK${NC}" | tee -a "$DEPLOY_LOG"
else
    echo -e "${RED}✗ Backend API (port 7001) - FAILED${NC}" | tee -a "$DEPLOY_LOG"
fi

# Check SocketIO (port 7002)
if curl -s -o /dev/null -w "%{http_code}" http://localhost:7002 | grep -q "200\|400"; then
    echo -e "${GREEN}✓ SocketIO (port 7002) - OK${NC}" | tee -a "$DEPLOY_LOG"
else
    echo -e "${RED}✗ SocketIO (port 7002) - FAILED${NC}" | tee -a "$DEPLOY_LOG"
fi

# Check Flower (port 7003)
if curl -s -o /dev/null -w "%{http_code}" http://localhost:7003 | grep -q "200\|302"; then
    echo -e "${GREEN}✓ Flower (port 7003) - OK${NC}" | tee -a "$DEPLOY_LOG"
else
    echo -e "${RED}✗ Flower (port 7003) - FAILED${NC}" | tee -a "$DEPLOY_LOG"
fi

# Check Secondary Nginx (port 7004)
if curl -s -o /dev/null -w "%{http_code}" http://localhost:7004 | grep -q "200\|301\|302"; then
    echo -e "${GREEN}✓ Secondary Frontend (port 7004) - OK${NC}" | tee -a "$DEPLOY_LOG"
else
    echo -e "${RED}✗ Secondary Frontend (port 7004) - FAILED${NC}" | tee -a "$DEPLOY_LOG"
fi

# Check internal services
echo -e "${YELLOW}Checking internal services...${NC}" | tee -a "$DEPLOY_LOG"
docker-compose -p $PROJECT_NAME ps | grep -E "lms_db|lms_redis|lms_celery" | while read line; do
    if echo "$line" | grep -q "Up"; then
        service=$(echo "$line" | awk '{print $1}')
        echo -e "${GREEN}✓ $service - Running${NC}" | tee -a "$DEPLOY_LOG"
    fi
done

# =============================================================================
# STEP 10: DEPLOYMENT SUMMARY
# =============================================================================
print_section "[10/10] Deployment Summary"

echo -e "${GREEN}================================================================${NC}" | tee -a "$DEPLOY_LOG"
echo -e "${GREEN}  ✅ DEPLOYMENT COMPLETE${NC}" | tee -a "$DEPLOY_LOG"
echo -e "${GREEN}================================================================${NC}" | tee -a "$DEPLOY_LOG"
echo -e "" | tee -a "$DEPLOY_LOG"
echo -e "${CYAN}Service URLs:${NC}" | tee -a "$DEPLOY_LOG"
echo -e "  Main Frontend:    ${BLUE}http://154.66.211.3:7000${NC}" | tee -a "$DEPLOY_LOG"
echo -e "  Backend API:      ${BLUE}http://154.66.211.3:7001/api/${NC}" | tee -a "$DEPLOY_LOG"
echo -e "  SocketIO:         ${BLUE}http://154.66.211.3:7002${NC}" | tee -a "$DEPLOY_LOG"
echo -e "  Flower Monitor:   ${BLUE}http://154.66.211.3:7003${NC}" | tee -a "$DEPLOY_LOG"
echo -e "  Secondary:        ${BLUE}http://154.66.211.3:7004${NC}" | tee -a "$DEPLOY_LOG"
echo -e "  Sentry:           ${BLUE}http://154.66.211.3:9000${NC}" | tee -a "$DEPLOY_LOG"
echo -e "" | tee -a "$DEPLOY_LOG"
echo -e "${CYAN}Test the Partners Feature:${NC}" | tee -a "$DEPLOY_LOG"
echo -e "  1. Go to: ${BLUE}http://154.66.211.3:7000${NC}" | tee -a "$DEPLOY_LOG"
echo -e "  2. Scroll to footer" | tee -a "$DEPLOY_LOG"
echo -e "  3. Click 'Ecosystem' → 'Partners'" | tee -a "$DEPLOY_LOG"
echo -e "" | tee -a "$DEPLOY_LOG"
echo -e "${YELLOW}Deploy log saved to: $DEPLOY_LOG${NC}" | tee -a "$DEPLOY_LOG"
echo -e "" | tee -a "$DEPLOY_LOG"
echo -e "${CYAN}To rollback if needed:${NC}" | tee -a "$DEPLOY_LOG"
echo -e "  docker cp $BACKUP_DIR/frontend_backup/. lms-prod-frontend-1:/usr/share/nginx/html/" | tee -a "$DEPLOY_LOG"
echo -e "  docker exec lms-prod-frontend-1 nginx -s reload" | tee -a "$DEPLOY_LOG"
echo -e "" | tee -a "$DEPLOY_LOG"
