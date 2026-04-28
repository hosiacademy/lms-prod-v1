#!/bin/bash

# Start Celery Worker Script
# Run this in a separate terminal after starting Django

echo "=========================================="
echo "Starting Celery Worker"
echo "=========================================="
echo ""

# Check if we're in the backend directory
if [ ! -f "manage.py" ]; then
    echo "Error: Please run this script from the backend directory"
    exit 1
fi

# Use python3 if available
PYTHON_CMD="python"
if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
fi

# Check if Celery is installed
if ! $PYTHON_CMD -c "import celery" 2>/dev/null; then
    echo "Error: Celery is not installed"
    echo "Install with: pip install celery redis"
    exit 1
fi

# Check if Redis is running
if ! pgrep redis-server > /dev/null; then
    echo "Warning: Redis doesn't appear to be running"
    echo "Start Redis with: redis-server --daemonize yes"
    echo ""
    echo "Attempting to start Redis..."
    if command -v redis-server >/dev/null 2>&1; then
        redis-server --daemonize yes
        sleep 2
        echo "✓ Redis started"
    else
        echo "Error: Redis is not installed"
        exit 1
    fi
fi

echo "Starting Celery worker..."
echo "Press Ctrl+C to stop"
echo ""

# Start Celery worker
celery -A lms_project worker -l info
