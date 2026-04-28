#!/bin/bash
# Rebuild Flutter Web with correct API URL for BBB Sessions
cd /home/tk/lms-prod/frontend

echo "=========================================="
echo "Rebuilding Flutter Web"
echo "API URL: http://154.66.211.3:7001"
echo "=========================================="

docker run --rm \
  -v /home/tk/lms-prod/frontend:/app \
  -w /app \
  ghcr.io/cirruslabs/flutter:stable \
  sh -c "flutter pub get && flutter build web --release --dart-define=API_BASE_URL=http://154.66.211.3:7001 --dart-define=ENV=production"

echo "=========================================="
echo "Build complete!"
echo "Output in: /home/tk/lms-prod/frontend/build/web"
echo "=========================================="

# Copy to nginx volume
echo "Copying to nginx volume..."
docker cp /home/tk/lms-prod/frontend/build/web lms-prod-frontend-1:/usr/share/nginx/html

echo "Done! Refresh browser to see changes."
