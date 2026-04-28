#!/bin/bash

# End-to-End Enrollment & Payment Test Script
# Tests the complete flow from enrollment creation to payment verification

echo "=========================================="
echo "Enrollment & Payment System E2E Test"
echo "=========================================="
echo ""

# Configuration
BASE_URL="http://127.0.0.1:8000"
API_TOKEN="" # Add your JWT token if authentication is required

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test
run_test() {
    local test_name="$1"
    local command="$2"
    local expected_code="$3"

    echo -n "Testing: $test_name... "

    response=$(eval "$command" 2>&1)
    status_code=$?

    if [ $status_code -eq 0 ] || [ $status_code -eq $expected_code ]; then
        echo -e "${GREEN}✓ PASSED${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        echo "Response: $response"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Check if backend is running
echo "1. Checking Backend Status"
if ! curl -s "$BASE_URL" > /dev/null 2>&1; then
    echo -e "${RED}Error: Backend is not running on $BASE_URL${NC}"
    echo "Start backend with: ./start_services.sh"
    exit 1
fi
echo -e "${GREEN}✓ Backend is running${NC}"
echo ""

# Test 1: Get Payment Providers for South Africa
echo "2. Testing Payment Providers Endpoint"
run_test "Get providers for ZA" \
    "curl -s -w '\n%{http_code}' '$BASE_URL/api/payments/providers/?country=ZA&amount=10000&currency=ZAR' | tail -1 | grep -q '200'" \
    0

run_test "Get providers for NG" \
    "curl -s -w '\n%{http_code}' '$BASE_URL/api/payments/providers/?country=NG&amount=50000&currency=NGN' | tail -1 | grep -q '200'" \
    0

run_test "Get providers for KE" \
    "curl -s -w '\n%{http_code}' '$BASE_URL/api/payments/providers/?country=KE&amount=10000&currency=KES' | tail -1 | grep -q '200'" \
    0

echo ""

# Test 2: Create Test Enrollment
echo "3. Testing Enrollment Creation"

ENROLLMENT_DATA='{
    "training_id": 1,
    "enrollment_type": "learnership",
    "learner_full_name": "Test User",
    "learner_email": "test@example.com",
    "learner_phone": "+27123456789",
    "learner_id_number": "8801015800080",
    "learner_dob": "1988-01-01",
    "learner_gender": "male",
    "learner_address": "123 Test Street",
    "learner_city": "Johannesburg",
    "learner_country": "SOUTH_AFRICA",
    "learner_postal_code": "2000",
    "current_occupation": "Software Developer",
    "education_level": "bachelors",
    "institution": "Test University",
    "emergency_contact_name": "Emergency Contact",
    "emergency_contact_phone": "+27123456780",
    "emergency_contact_relationship": "spouse",
    "enrollment_fee": 100.00,
    "currency": "ZAR",
    "terms_accepted": true,
    "terms_accepted_at": "2024-01-24T10:00:00Z"
}'

echo "Creating test enrollment..."
ENROLLMENT_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_TOKEN" \
    -d "$ENROLLMENT_DATA" \
    "$BASE_URL/api/enrollments/")

if echo "$ENROLLMENT_RESPONSE" | grep -q "enrollment_code"; then
    echo -e "${GREEN}✓ Enrollment created successfully${NC}"
    ENROLLMENT_ID=$(echo "$ENROLLMENT_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
    ENROLLMENT_CODE=$(echo "$ENROLLMENT_RESPONSE" | grep -o '"enrollment_code":"[^"]*"' | cut -d'"' -f4)
    echo "  Enrollment ID: $ENROLLMENT_ID"
    echo "  Enrollment Code: $ENROLLMENT_CODE"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}✗ Enrollment creation failed${NC}"
    echo "Response: $ENROLLMENT_RESPONSE"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

echo ""

# Test 3: Initiate Payment (Sandbox)
if [ -n "$ENROLLMENT_ID" ]; then
    echo "4. Testing Payment Initiation"

    PAYMENT_DATA='{
        "enrollment_id": "'$ENROLLMENT_ID'",
        "amount": 10000,
        "currency": "ZAR",
        "country": "ZA",
        "provider": "flutterwave",
        "payment_method": "card",
        "email": "test@example.com"
    }'

    echo "Initiating test payment..."
    PAYMENT_RESPONSE=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$PAYMENT_DATA" \
        "$BASE_URL/api/payments/initiate/")

    if echo "$PAYMENT_RESPONSE" | grep -q "transaction_id"; then
        echo -e "${GREEN}✓ Payment initiated successfully${NC}"
        TRANSACTION_ID=$(echo "$PAYMENT_RESPONSE" | grep -o '"transaction_id":"[^"]*"' | cut -d'"' -f4)
        FLOW_TYPE=$(echo "$PAYMENT_RESPONSE" | grep -o '"flow_type":"[^"]*"' | cut -d'"' -f4)
        echo "  Transaction ID: $TRANSACTION_ID"
        echo "  Flow Type: $FLOW_TYPE"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗ Payment initiation failed${NC}"
        echo "Response: $PAYMENT_RESPONSE"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    echo ""

    # Test 4: Verify Payment Status
    if [ -n "$TRANSACTION_ID" ]; then
        echo "5. Testing Payment Verification"

        sleep 2 # Wait a bit before verifying

        VERIFY_RESPONSE=$(curl -s "$BASE_URL/api/payments/verify/$TRANSACTION_ID/")

        if echo "$VERIFY_RESPONSE" | grep -q "status"; then
            echo -e "${GREEN}✓ Payment verification successful${NC}"
            STATUS=$(echo "$VERIFY_RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
            echo "  Payment Status: $STATUS"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "${RED}✗ Payment verification failed${NC}"
            echo "Response: $VERIFY_RESPONSE"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi
fi

echo ""
echo "=========================================="
echo "Test Results"
echo "=========================================="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo "=========================================="

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Test on frontend: flutter run"
    echo "2. Test actual payment with sandbox credentials"
    echo "3. Verify email/SMS notifications"
    exit 0
else
    echo -e "${RED}Some tests failed. Please check the errors above.${NC}"
    exit 1
fi
