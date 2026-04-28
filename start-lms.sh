#!/bin/bash
# LMS Quick Start Script

echo "=========================================="
echo "  Starting LMS Application"
echo "=========================================="

# Navigate to backend directory
cd /home/tk/lms-prod/backend

# Activate virtual environment
source venv/bin/activate

# Check if PostgreSQL is running
if ! systemctl is-active --quiet postgresql; then
    echo "PostgreSQL is not running. Starting..."
    sudo systemctl start postgresql
fi

# Run migrations (optional, uncomment if needed)
# echo "Running migrations..."
# python manage.py migrate

# Start the server with Uvicorn (ASGI server for WebSocket support)
echo "Starting Django ASGI server with Uvicorn..."
echo "Access the app at: http://localhost:8000"
echo "Admin panel at: http://localhost:8000/admin"
echo "Socket.IO WebSocket server running on same port"
echo "Press CTRL+C to stop the server"
echo "=========================================="

uvicorn lms_project.asgi:application --host 0.0.0.0 --port 8000 --reload
