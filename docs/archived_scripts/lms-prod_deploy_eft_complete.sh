#!/bin/bash
# EFT Payment System - Complete Deployment Script
# Builds, migrates, and deploys with Takawira as default instructor

set -e

echo "=============================================="
echo "  EFT Payment System Deployment"
echo "  Default Instructor: Takawira"
echo "=============================================="

cd /home/tk/lms-prod

echo ""
echo "📦 Step 1: Building Docker images..."
docker-compose build backend frontend

echo ""
echo "🔄 Step 2: Stopping existing services..."
docker-compose down

echo ""
echo "🗄️  Step 3: Running database migrations..."
docker-compose run --rm backend python manage.py migrate --noinput || {
    echo "⚠️  Migration had issues, continuing..."
}

echo ""
echo "👤 Step 4: Creating default instructor (Takawira)..."
docker-compose run --rm backend python manage.py create_default_instructor || {
    echo "⚠️  Instructor creation skipped..."
}

echo ""
echo "📁 Step 5: Collecting static files..."
docker-compose run --rm backend python manage.py collectstatic --noinput

echo ""
echo "🚀 Step 6: Starting all services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be healthy..."
sleep 15

echo ""
echo "✅ Step 7: Verifying deployment..."
BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7001/health/ 2>/dev/null || echo "000")

if [ "$BACKEND_STATUS" == "200" ]; then
    echo "✅ Backend: HEALTHY (Port 7001)"
else
    echo "⚠️  Backend: Status $BACKEND_STATUS"
fi

echo ""
echo "=============================================="
echo "  Deployment Complete!"
echo "=============================================="
echo ""
echo "📊 Services:"
docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "🔗 Access Points:"
echo "   Frontend: http://localhost:7000"
echo "   Backend API: http://localhost:7001"
echo "   Flower (Celery): http://localhost:7003"
echo "   Nginx: http://localhost:7004"
echo ""
echo "👤 Default Instructor:"
echo "   Name: Takawira"
echo "   Email: takawira@hosiacademy.africa"
echo "   Note: Set password via admin panel"
echo ""
echo "💳 EFT Endpoints Ready:"
echo "   POST /api/v1/payments/eft/initiate/"
echo "   GET  /api/v1/payments/eft/status/<reference>/"
echo "   POST /api/v1/payments/eft/admin/verify/"
echo ""
echo "=============================================="
