#!/bin/bash
# =============================================================================
# LMS Consolidated CLI Utility
# =============================================================================
# This script consolidates all deployment, setup, and testing scripts.
# Run: ./lms.sh help
# =============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="/home/tk/lms-prod"
if [ ! -d "$PROJECT_DIR" ]; then
    PROJECT_DIR=$(pwd)
fi

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
    echo -e "${BLUE}================================================================${NC}"
    echo -e "${BLUE}  HOSI ACADEMY LMS - CONSOLIDATED CLI UTILITY${NC}"
    echo -e "${BLUE}================================================================${NC}"
    echo ""
    echo "Usage: ./lms.sh [command] [subcommand]"
    echo ""
    echo "Deployment Commands:"
    echo "  deploy all        - Full production build and deployment"
    echo "  deploy frontend   - Build and deploy frontend only"
    echo "  deploy staging    - Deploy to staging server"
    echo ""
    echo "Setup & Config:"
    echo "  setup multitenant - Initialize multitenant database setup"
    echo "  setup webhooks    - Configure and test M-Pesa webhooks"
    echo "  setup partners    - Seed partner program defaults"
    echo ""
    echo "Syncing (WSL/Win):"
    echo "  sync start        - Start bidirectional file sync"
    echo "  sync stop         - Stop bidirectional file sync"
    echo ""
    echo "Testing:"
    echo "  test api          - Test core API endpoints"
    echo "  test eft          - Run end-to-end EFT payment test"
    echo ""
}

case "$1" in
    deploy)
        case "$2" in
            all)
                log_info "Stopping all containers..."
                docker-compose -p lms-prod down
                log_info "Building all Docker images..."
                docker-compose -p lms-prod -f docker-compose.yml -f docker-compose.prod.yml build --no-cache
                log_info "Running migrations..."
                docker-compose -p lms-prod -f docker-compose.yml -f docker-compose.prod.yml run --rm backend python manage.py migrate
                log_info "Collecting static files..."
                docker-compose -p lms-prod -f docker-compose.yml -f docker-compose.prod.yml run --rm backend python manage.py collectstatic --noinput
                log_info "Starting all services..."
                docker-compose -p lms-prod -f docker-compose.yml -f docker-compose.prod.yml up -d
                log_success "Deployment complete!"
                ;;
            frontend)
                log_info "Building Flutter web with HTTPS support..."
                cd "$PROJECT_DIR/frontend"
                rm -rf build/web
                docker run --rm -v "$PROJECT_DIR/frontend:/app" -w /app ghcr.io/cirruslabs/flutter:stable \
                  bash -c "flutter clean && flutter pub get && flutter build web --release --dart-define=ENV=production"
                rm -rf "$PROJECT_DIR/frontend/prebuilt_web/"*
                cp -r "$PROJECT_DIR/frontend/build/web/"* "$PROJECT_DIR/frontend/prebuilt_web/"
                log_info "Restarting frontend container..."
                docker restart lms-prod-frontend-1
                log_success "Frontend deployment complete!"
                ;;
            staging)
                log_info "Deploying to staging..."
                STAGING_SERVER="154.66.211.3"
                DEPLOY_PATH="/opt/lms-staging"
                ssh root@$STAGING_SERVER "cd $DEPLOY_PATH && docker-compose -f docker-compose.yml -f docker-compose.staging.yml build && docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d"
                log_success "Staging deployment complete!"
                ;;
            *)
                show_help
                ;;
        esac
        ;;
    setup)
        case "$2" in
            multitenant)
                log_info "Starting Docker services for multitenant..."
                docker-compose -f docker-compose.multitenant.yml up -d
                log_info "Running migrations..."
                docker-compose -f docker-compose.multitenant.yml exec -T backend python manage.py migrate
                log_success "Multitenant setup complete!"
                ;;
            webhooks)
                log_info "Testing webhook endpoint..."
                curl -X POST http://localhost:7001/api/payments/webhooks/mpesa/ -H "Content-Type: application/json" -d '{"Body": {"stkCallback": {"test": true}}}'
                log_success "Webhook test completed."
                ;;
            partners)
                log_info "Setting up default partner program data..."
                docker-compose -p lms-prod exec -T backend python manage.py shell -c "print('Run seed script manually for partners')"
                ;;
            *)
                show_help
                ;;
        esac
        ;;
    sync)
        case "$2" in
            start)
                log_info "Starting LMS bidirectional sync..."
                nohup "$PROJECT_DIR/lms-sync.sh" > "$PROJECT_DIR/lms-sync.log" 2>&1 &
                echo $! > "$PROJECT_DIR/.lms-sync.pid"
                log_success "Sync started."
                ;;
            stop)
                log_info "Stopping sync..."
                if [ -f "$PROJECT_DIR/.lms-sync.pid" ]; then
                    kill $(cat "$PROJECT_DIR/.lms-sync.pid")
                    rm "$PROJECT_DIR/.lms-sync.pid"
                    log_success "Sync stopped."
                else
                    log_error "Sync not running."
                fi
                ;;
            *)
                show_help
                ;;
        esac
        ;;
    test)
        case "$2" in
            api)
                log_info "Testing API endpoints..."
                curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:7001/api/v1/courses/masterclasses/?page=1\&page_size=1
                ;;
            eft)
                log_info "Testing EFT Complete Flow..."
                curl -X POST "http://localhost:7001/api/v1/payments/eft/initiate/" -H "Content-Type: application/json" -d '{"amount": 1500, "currency": "ZAR", "country": "ZA"}'
                ;;
            *)
                show_help
                ;;
        esac
        ;;
    *)
        show_help
        ;;
esac
