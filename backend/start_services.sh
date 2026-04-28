#!/bin/bash

# Start Backend Services Script
# This script starts all required services for the LMS payment system

echo "=========================================="
echo "Starting Hosi Academy LMS Backend Services"
echo "=========================================="
echo ""

# Check if we're in the backend directory
if [ ! -f "manage.py" ]; then
    echo "Error: Please run this script from the backend directory"
    exit 1
fi

# Check if .env exists
if [ ! -f ".env" ]; then
    echo "Error: .env file not found. Please copy .env.payment.example to .env"
    exit 1
fi

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Python
if ! command_exists python && ! command_exists python3; then
    echo "Error: Python is not installed"
    exit 1
fi

# Use python3 if available, otherwise python
PYTHON_CMD="python"
if command_exists python3; then
    PYTHON_CMD="python3"
fi

# Check Redis
if ! command_exists redis-server; then
    echo "Warning: Redis is not installed. Payment webhooks may not work."
    echo "Install Redis: sudo apt-get install redis-server (Ubuntu/Debian)"
    echo "             or brew install redis (macOS)"
fi

# Check Celery
if ! $PYTHON_CMD -c "import celery" 2>/dev/null; then
    echo "Warning: Celery is not installed. Installing..."
    pip install celery redis
fi

echo "Starting services..."
echo ""

# Start Redis (if available)
if command_exists redis-server; then
    echo "1. Starting Redis..."
    if pgrep redis-server > /dev/null; then
        echo "   ✓ Redis is already running"
    else
        redis-server --daemonize yes
        echo "   ✓ Redis started"
    fi
fi

# Start Django
echo ""
echo "2. Starting Django Development Server..."
echo "   Django will run on http://127.0.0.1:8000"
echo "   Press Ctrl+C to stop"
echo ""
echo "   Note: Open a new terminal to start Celery worker"
echo "   Command: cd backend && celery -A lms_project worker -l info"
echo ""
echo "=========================================="

# Start Django (this will block)
$PYTHON_CMD manage.py runserver 0.0.0.0:8000
