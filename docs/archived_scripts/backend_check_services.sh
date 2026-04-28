#!/bin/bash

# Check Services Status Script
# Verifies all required services are running

echo "=========================================="
echo "Checking Service Status"
echo "=========================================="
echo ""

services_ok=true

# Check Redis
echo "1. Redis Server:"
if pgrep redis-server > /dev/null; then
    echo "   ✓ Running"
else
    echo "   ✗ Not running"
    echo "   Start with: redis-server --daemonize yes"
    services_ok=false
fi

# Check if Redis is responding
if command -v redis-cli >/dev/null 2>&1; then
    if redis-cli ping > /dev/null 2>&1; then
        echo "   ✓ Redis responding to commands"
    else
        echo "   ✗ Redis not responding"
        services_ok=false
    fi
fi

echo ""

# Check Django
echo "2. Django Server:"
if curl -s http://127.0.0.1:8000/ > /dev/null 2>&1; then
    echo "   ✓ Running on http://127.0.0.1:8000"
else
    echo "   ✗ Not running"
    echo "   Start with: ./start_services.sh"
    services_ok=false
fi

echo ""

# Check Celery
echo "3. Celery Worker:"
if pgrep -f "celery.*worker" > /dev/null; then
    echo "   ✓ Running"
    worker_count=$(pgrep -f "celery.*worker" | wc -l)
    echo "   Workers: $worker_count"
else
    echo "   ✗ Not running"
    echo "   Start with: ./start_celery.sh"
    services_ok=false
fi

echo ""

# Check Payment Configuration
echo "4. Payment Configuration:"
if [ -f ".env" ]; then
    if grep -q "PAYMENT_SANDBOX_MODE=True" .env; then
        echo "   ✓ .env file exists"
        echo "   ✓ Sandbox mode: ENABLED"
    else
        echo "   ⚠ Sandbox mode: DISABLED (Production mode)"
    fi

    # Check for payment provider keys
    if grep -q "FLUTTERWAVE_PUBLIC_KEY" .env && grep -q "FLUTTERWAVE_SECRET_KEY" .env; then
        echo "   ✓ Flutterwave configured"
    else
        echo "   ⚠ Flutterwave not configured"
    fi
else
    echo "   ✗ .env file not found"
    echo "   Create from: cp .env.payment.example .env"
    services_ok=false
fi

echo ""
echo "=========================================="

if [ "$services_ok" = true ]; then
    echo "✓ All services are running!"
    echo ""
    echo "API Endpoints:"
    echo "  - Admin: http://127.0.0.1:8000/admin/"
    echo "  - API Root: http://127.0.0.1:8000/api/"
    echo "  - Enrollments: http://127.0.0.1:8000/api/enrollments/"
    echo "  - Payments: http://127.0.0.1:8000/api/payments/"
    echo ""
    echo "Ready to accept enrollments! 🎓"
else
    echo "⚠ Some services are not running"
    echo "Please start the missing services"
fi

echo "=========================================="
