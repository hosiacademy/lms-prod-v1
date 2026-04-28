#!/bin/bash
# Quick deploy - rebuild only backend and frontend containers

set -e

echo "=== Quick Deploy: Updating Backend and Frontend Containers ==="

# 1. Rebuild backend (has new pricing)
echo "Rebuilding backend container..."
cd /home/tk/lms-prod
docker-compose build backend
docker-compose up -d backend

# 2. Rebuild frontend (use existing prebuilt_web if available, or build quickly)
echo "Rebuilding frontend container..."
docker-compose build frontend
docker-compose up -d frontend

echo ""
echo "=== Deploy Complete ==="
docker ps --filter "name=lms-prod" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
