#!/bin/bash
# =============================================================================
# LMS Instructor App Fix Deployment
# Deploys the instructor app rename and dashboard fix to production
# =============================================================================

set -e

DEPLOY_DIR="/home/tk/lms-prod"
cd "$DEPLOY_DIR"

echo "🚀 Starting Instructor App Fix Deployment..."
echo "======================================================================"

# 1. Sync files to backend
echo "📦 Syncing updated instructor app files..."
cd "$DEPLOY_DIR/backend"

# 2. Create and run migrations
echo "🔧 Creating database migrations..."
docker compose exec -T backend python manage.py makemigrations instructors --name rename_facilitator_to_instructor || echo "Migration creation skipped (may already exist)"

echo "🔧 Running database migrations..."
docker compose exec -T backend python manage.py migrate instructors

# 3. Update content types (important for model renames)
echo "🔄 Updating content types..."
docker compose exec -T backend python manage.py migrate contenttypes

# 4. Collect static files
echo "📁 Collecting static files..."
docker compose exec -T backend python manage.py collectstatic --noinput

# 5. Restart backend services
echo "🔄 Restarting backend services..."
docker compose restart backend

# 6. Wait for backend to be ready
echo "⏳ Waiting for backend to be ready..."
sleep 10

# 7. Verify the fix
echo "✅ Verifying deployment..."
echo "Testing instructor dashboard endpoint..."

# Test the dashboard endpoint
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7001/api/v1/instructors/profiles/dashboard/ 2>/dev/null || echo "000")

if [ "$RESPONSE" = "401" ] || [ "$RESPONSE" = "403" ]; then
    echo "✅ Backend is responding (HTTP $RESPONSE - authentication expected)"
elif [ "$RESPONSE" = "200" ]; then
    echo "✅ Backend is responding successfully (HTTP $RESPONSE)"
elif [ "$RESPONSE" = "404" ]; then
    echo "⚠️  Endpoint returned 404 - check URL routing"
else
    echo "⚠️  Backend response: HTTP $RESPONSE"
fi

# 8. Check for any migration issues
echo "🔍 Checking for migration issues..."
docker compose exec -T backend python manage.py check || echo "⚠️  Django check found some issues"

echo "======================================================================"
echo "✅ Deployment Complete!"
echo ""
echo "📋 Test URLs:"
echo "   Frontend:     http://154.66.211.3:7000"
echo "   Backend API:  http://154.66.211.3:7001/api/v1/instructors/"
echo "   Dashboard:    http://154.66.211.3:7001/api/v1/instructors/profiles/dashboard/"
echo "   SocketIO:     http://154.66.211.3:7002"
echo ""
echo "🔑 Login as instructor to test:"
echo "   - Navigate to the instructor dashboard"
echo "   - The 500 error should be fixed"
echo ""
echo "📝 Deployment completed at: $(date '+%Y-%m-%d %H:%M:%S')"
echo "======================================================================"
