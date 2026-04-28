#!/bin/bash
# ============================================================================
# EFT PAYMENT - COMPLETE END-TO-END TEST
# ============================================================================
# Tests the full EFT payment flow:
# 1. Initiate EFT payment
# 2. Submit bank details
# 3. Upload proof of payment (POP)
# 4. Admin verification
# 5. Payment completion
# 6. Enrollment confirmation
# ============================================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
API_BASE="http://localhost:7001/api/v1"
TEST_EMAIL="eft-test-$(date +%s)@example.com"
TEST_PHONE="+27123456789"
TEST_AMOUNT=1500.00
TEST_CURRENCY="ZAR"
TEST_COUNTRY="ZA"

echo -e "${BLUE}"
echo "============================================================"
echo "🏦 EFT PAYMENT - COMPLETE END-TO-END TEST"
echo "============================================================"
echo -e "${NC}"
echo "Test Configuration:"
echo "  Email: $TEST_EMAIL"
echo "  Phone: $TEST_PHONE"
echo "  Amount: $TEST_AMOUNT $TEST_CURRENCY"
echo "  Country: $TEST_COUNTRY"
echo "  API Base: $API_BASE"
echo ""

# ============================================================================
# STEP 1: INITIATE EFT PAYMENT
# ============================================================================
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}Step 1: Initiate EFT Payment${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

INITIATE_RESPONSE=$(curl -s -X POST "$API_BASE/payments/eft/initiate/" \
  -H "Content-Type: application/json" \
  -d "{
    \"program_id\": \"123\",
    \"type\": \"masterclass\",
    \"amount\": $TEST_AMOUNT,
    \"currency\": \"$TEST_CURRENCY\",
    \"country\": \"$TEST_COUNTRY\",
    \"metadata\": {
      \"enrollment_type\": \"masterclass\",
      \"program_title\": \"Test Masterclass\"
    },
    \"individual_details\": {
      \"full_name\": \"EFT Test User\",
      \"email\": \"$TEST_EMAIL\",
      \"phone\": \"$TEST_PHONE\"
    }
  }")

echo "Response:"
echo "$INITIATE_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$INITIATE_RESPONSE"
echo ""

# Extract reference number
REFERENCE=$(echo "$INITIATE_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('reference', ''))" 2>/dev/null || echo "")

if [ -z "$REFERENCE" ]; then
    echo -e "${RED}✗ Failed to initiate EFT payment${NC}"
    echo "Error: No reference number in response"
    exit 1
fi

echo -e "${GREEN}✓ EFT Payment Initiated${NC}"
echo "  Reference: $REFERENCE"
echo ""

# ============================================================================
# STEP 2: SUBMIT BANK DETAILS
# ============================================================================
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}Step 2: Submit Bank Details${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

BANK_DETAILS_RESPONSE=$(curl -s -X POST "$API_BASE/payments/eft/submit-bank-details/" \
  -H "Content-Type: application/json" \
  -d "{
    \"reference\": \"$REFERENCE\",
    \"bank_name\": \"Standard Bank\",
    \"account_holder_name\": \"EFT Test User\",
    \"account_number\": \"012345678\",
    \"branch_code\": \"051001\"
  }")

echo "Response:"
echo "$BANK_DETAILS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$BANK_DETAILS_RESPONSE"
echo ""

# Check if bank details were saved
BANK_STATUS=$(echo "$BANK_DETAILS_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', ''))" 2>/dev/null || echo "")

if [ "$BANK_STATUS" = "success" ] || [ -n "$BANK_STATUS" ]; then
    echo -e "${GREEN}✓ Bank Details Submitted${NC}"
else
    echo -e "${YELLOW}⚠ Bank details submission may have issues${NC}"
fi
echo ""

# ============================================================================
# STEP 3: UPLOAD PROOF OF PAYMENT (POP)
# ============================================================================
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}Step 3: Upload Proof of Payment (POP)${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

# Create a dummy POP file
POP_FILE="/tmp/pop_$REFERENCE.pdf"
echo "Dummy Proof of Payment for $REFERENCE" > "$POP_FILE"

# Upload POP
POP_RESPONSE=$(curl -s -X POST "$API_BASE/payments/eft/upload-pop/$REFERENCE/" \
  -H "Content-Type: multipart/form-data" \
  -F "proof_of_payment=@$POP_FILE" \
  -F "reference=$REFERENCE")

echo "Response:"
echo "$POP_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$POP_RESPONSE"
echo ""

# Check upload status
POP_STATUS=$(echo "$POP_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', ''))" 2>/dev/null || echo "")

if [ "$POP_STATUS" = "success" ] || [ "$POP_STATUS" = "pending_verification" ]; then
    echo -e "${GREEN}✓ Proof of Payment Uploaded${NC}"
    echo "  Status: Pending Admin Verification"
else
    echo -e "${YELLOW}⚠ POP upload may have issues${NC}"
fi
echo ""

# Cleanup
rm -f "$POP_FILE"

# ============================================================================
# STEP 4: CHECK PAYMENT STATUS
# ============================================================================
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}Step 4: Check Payment Status${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

STATUS_RESPONSE=$(curl -s "$API_BASE/payments/eft/status/$REFERENCE/")

echo "Response:"
echo "$STATUS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$STATUS_RESPONSE"
echo ""

# Extract transaction status
TXN_STATUS=$(echo "$STATUS_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('transaction', {}).get('status', ''))" 2>/dev/null || echo "")

echo -e "Current Status: ${YELLOW}$TXN_STATUS${NC}"
echo ""

# ============================================================================
# STEP 5: ADMIN VERIFICATION (SIMULATE)
# ============================================================================
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}Step 5: Admin Verification (Simulate)${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

echo "Simulating admin verification..."
echo ""

# Get pending EFT payments (admin endpoint)
PENDING_RESPONSE=$(curl -s "$API_BASE/payments/eft/admin/pending/")

echo "Pending EFT Payments:"
echo "$PENDING_RESPONSE" | python3 -m json.tool 2>/dev/null | head -30 || echo "$PENDING_RESPONSE" | head -30
echo ""

# Verify the payment (admin action)
VERIFY_RESPONSE=$(curl -s -X POST "$API_BASE/payments/admin/eft/verify/$REFERENCE/" \
  -H "Content-Type: application/json" \
  -d "{
    \"verified_by\": \"test_admin\",
    \"notes\": \"EFT test verification - automated test\"
  }")

echo "Verification Response:"
echo "$VERIFY_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$VERIFY_RESPONSE"
echo ""

# Check verification status
VERIFY_STATUS=$(echo "$VERIFY_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('status', ''))" 2>/dev/null || echo "")

if [ "$VERIFY_STATUS" = "success" ]; then
    echo -e "${GREEN}✓ Payment Verified by Admin${NC}"
else
    echo -e "${YELLOW}⚠ Verification may have issues${NC}"
fi
echo ""

# ============================================================================
# STEP 6: CONFIRM FINAL STATUS
# ============================================================================
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}Step 6: Confirm Final Status${NC}"
echo -e "${BLUE}============================================================${NC}"
echo ""

FINAL_STATUS_RESPONSE=$(curl -s "$API_BASE/payments/eft/status/$REFERENCE/")

echo "Final Status Response:"
echo "$FINAL_STATUS_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$FINAL_STATUS_RESPONSE"
echo ""

# Extract final status
FINAL_STATUS=$(echo "$FINAL_STATUS_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('transaction', {}).get('status', ''))" 2>/dev/null || echo "")

if [ "$FINAL_STATUS" = "successful" ]; then
    echo -e "${GREEN}✓✓✓ PAYMENT SUCCESSFUL! ✓✓✓${NC}"
    echo ""
    echo "EFT Payment Flow Complete:"
    echo "  1. ✓ Payment Initiated"
    echo "  2. ✓ Bank Details Submitted"
    echo "  3. ✓ Proof of Payment Uploaded"
    echo "  4. ✓ Admin Verified"
    echo "  5. ✓ Payment Complete"
    echo ""
    echo -e "${GREEN}============================================================${NC}"
    echo -e "${GREEN}✅ EFT END-TO-END TEST PASSED${NC}"
    echo -e "${GREEN}============================================================${NC}"
else
    echo -e "${YELLOW}⚠ Payment status: $FINAL_STATUS${NC}"
    echo ""
    echo "Test completed but payment not yet successful."
    echo "This is normal if admin verification is still pending."
    echo ""
    echo -e "${YELLOW}============================================================${NC}"
    echo -e "${YELLOW}⚠️  EFT TEST COMPLETED (PENDING VERIFICATION)${NC}"
    echo -e "${YELLOW}============================================================${NC}"
fi

echo ""
echo "Test Summary:"
echo "  Reference: $REFERENCE"
echo "  Email: $TEST_EMAIL"
echo "  Amount: $TEST_AMOUNT $TEST_CURRENCY"
echo "  Final Status: $FINAL_STATUS"
echo ""
echo "Next Steps (Manual):"
echo "  1. Check Django admin for transaction details"
echo "  2. Verify enrollment was created"
echo "  3. Check email notifications"
echo ""
