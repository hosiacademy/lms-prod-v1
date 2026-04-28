#!/bin/bash

# Quick Payment System Test Script
# This script validates your payment configuration and runs basic tests

echo "=========================================="
echo "Payment System Quick Test"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if virtual environment is activated
if [ -z "$VIRTUAL_ENV" ]; then
    echo -e "${YELLOW}⚠ Virtual environment not activated${NC}"
    echo "Activating virtual environment..."

    if [ -d "venv" ]; then
        source venv/bin/activate || source venv/Scripts/activate
    elif [ -d "../venv" ]; then
        source ../venv/bin/activate || source ../venv/Scripts/activate
    else
        echo -e "${RED}✗ Virtual environment not found${NC}"
        echo "Please run: python -m venv venv"
        exit 1
    fi
fi

echo -e "${GREEN}✓ Virtual environment active${NC}"
echo ""

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}✗ .env file not found${NC}"
    echo "Please create .env file with your API keys"
    echo "See .env.payment.example for reference"
    exit 1
fi

echo -e "${GREEN}✓ .env file found${NC}"
echo ""

# Run validation
echo "=========================================="
echo "1. Validating Configuration"
echo "=========================================="
echo ""

python setup_payments.py --validate
VALIDATION_STATUS=$?

if [ $VALIDATION_STATUS -ne 0 ]; then
    echo ""
    echo -e "${RED}✗ Configuration validation failed${NC}"
    echo "Please add API keys to .env file"
    echo "See PROVIDER_SIGNUP_GUIDE.md for instructions"
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Configuration valid${NC}"
echo ""

# Setup database
echo "=========================================="
echo "2. Setting Up Database"
echo "=========================================="
echo ""

python setup_payments.py --setup-db

echo ""
echo -e "${GREEN}✓ Database setup complete${NC}"
echo ""

# Test API endpoint
echo "=========================================="
echo "3. Testing API Endpoint"
echo "=========================================="
echo ""

# Start server in background
echo "Starting development server..."
python manage.py runserver 0.0.0.0:8000 > /tmp/django_server.log 2>&1 &
SERVER_PID=$!

# Wait for server to start
sleep 3

# Test providers endpoint
echo "Testing /api/payments/providers/ endpoint..."
RESPONSE=$(curl -s "http://127.0.0.1:8000/api/payments/providers/?country=NG&amount=5000&currency=NGN")

if echo "$RESPONSE" | grep -q "providers"; then
    echo -e "${GREEN}✓ API endpoint working${NC}"
    echo ""
    echo "Available providers:"
    echo "$RESPONSE" | python -m json.tool 2>/dev/null | grep -E '"name"|"code"' | head -10
    echo ""
else
    echo -e "${RED}✗ API endpoint failed${NC}"
    echo "Response: $RESPONSE"
    kill $SERVER_PID
    exit 1
fi

# Kill server
kill $SERVER_PID 2>/dev/null
sleep 1

echo ""
echo "=========================================="
echo "✅ All Tests Passed!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Start server: python manage.py runserver"
echo "2. Test full flow: python manage.py test_payment_providers --full"
echo "3. See PAYMENT_SETUP_AND_TESTING.md for complete guide"
echo ""
echo "Payment system is ready to use! 🎉"
echo ""
