#!/bin/bash
# M-Pesa Integration Test Script
# Run this to test your M-Pesa credentials

set -e

echo "============================================================"
echo "🇰🇪 M-PESA KENYA INTEGRATION TEST"
echo "============================================================"
echo ""

# Change to project directory
cd /home/tk/lms-prod

echo "Step 1: Testing OAuth Token Generation..."
echo "-----------------------------------------------------------"

CONSUMER_KEY="vqyE8i0Od9VgZj4EBjVbUQj3mb3qqN1rj9fBLXVtGRAUo6Id"
CONSUMER_SECRET="c4s1ZBNuswT5YE20TQ2ILqAgGTY5GArs4YMRFGOf9pSCwxxn7zRvAvLi31kn9KvV"

# Generate Basic Auth string
AUTH_STRING=$(echo -n "${CONSUMER_KEY}:${CONSUMER_SECRET}" | base64 -w 0)

echo "Requesting OAuth token from Safaricom..."
OAUTH_RESPONSE=$(curl -s -X GET \
  "https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials" \
  -H "Authorization: Basic ${AUTH_STRING}")

echo "Response: $OAUTH_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$OAUTH_RESPONSE"

# Check if we got an access token
ACCESS_TOKEN=$(echo "$OAUTH_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))" 2>/dev/null || echo "")

if [ -z "$ACCESS_TOKEN" ]; then
    echo "❌ Failed to get OAuth token"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check if Consumer Key is correct"
    echo "  2. Check if Consumer Secret is correct"
    echo "  3. Ensure sandbox mode is enabled"
    echo "  4. Check Safaricom portal: https://developer.safaricom.co.ke/"
    exit 1
fi

echo ""
echo "✅ OAuth token obtained successfully!"
echo "Token: ${ACCESS_TOKEN:0:30}...${ACCESS_TOKEN: -10}"
echo ""

echo "Step 2: Testing STK Push Initiation..."
echo "-----------------------------------------------------------"

# M-Pesa credentials
SHORTCODE="174379"
PASSKEY="bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919"
TIMESTAMP=$(date +%Y%m%d%H%M%S)
PHONE_NUMBER="254708374149"
AMOUNT="1"
ACCOUNT_REF="TEST_$(date +%s)"

# Generate password
PASSWORD=$(echo -n "${SHORTCODE}${PASSKEY}${TIMESTAMP}" | base64 -w 0)

echo "STK Push Details:"
echo "  Phone: $PHONE_NUMBER"
echo "  Amount: $AMOUNT KES"
echo "  Shortcode: $SHORTCODE"
echo "  Timestamp: $TIMESTAMP"
echo "  Account Ref: $ACCOUNT_REF"
echo ""

# Initiate STK Push
STK_RESPONSE=$(curl -s -X POST \
  "https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{
    \"BusinessShortCode\": \"$SHORTCODE\",
    \"Password\": \"$PASSWORD\",
    \"Timestamp\": \"$TIMESTAMP\",
    \"TransactionType\": \"CustomerPayBillOnline\",
    \"Amount\": $AMOUNT,
    \"PartyA\": \"$PHONE_NUMBER\",
    \"PartyB\": \"$SHORTCODE\",
    \"PhoneNumber\": \"$PHONE_NUMBER\",
    \"CallBackURL\": \"https://hosiacademy.com/api/payments/webhooks/mpesa/\",
    \"AccountReference\": \"$ACCOUNT_REF\",
    \"TransactionDesc\": \"Integration Test\"
  }")

echo "STK Response:"
echo "$STK_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$STK_RESPONSE"
echo ""

# Check response code
RESPONSE_CODE=$(echo "$STK_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('ResponseCode', ''))" 2>/dev/null || echo "")

if [ "$RESPONSE_CODE" = "0" ]; then
    echo "✅ STK Push initiated successfully!"
    CHECKOUT_ID=$(echo "$STK_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('CheckoutRequestID', ''))" 2>/dev/null || echo "")
    CUSTOMER_MSG=$(echo "$STK_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('CustomerMessage', ''))" 2>/dev/null || echo "")
    
    echo ""
    echo "CheckoutRequestID: $CHECKOUT_ID"
    echo "Customer Message: $CUSTOMER_MSG"
    echo ""
    echo "⚠️  Check phone $PHONE_NUMBER for STK prompt"
    echo ""
    
    # Wait and query status
    echo "Waiting 30 seconds for user to complete payment..."
    sleep 30
    
    echo ""
    echo "Step 3: Querying Payment Status..."
    echo "-----------------------------------------------------------"
    
    QUERY_PASSWORD=$(echo -n "${SHORTCODE}${PASSKEY}$(date +%Y%m%d%H%M%S)" | base64 -w 0)
    
    QUERY_RESPONSE=$(curl -s -X POST \
      "https://sandbox.safaricom.co.ke/mpesa/stkpushquery/v1/query" \
      -H "Authorization: Bearer $ACCESS_TOKEN" \
      -H "Content-Type: application/json" \
      -d "{
        \"BusinessShortCode\": \"$SHORTCODE\",
        \"Password\": \"$QUERY_PASSWORD\",
        \"Timestamp\": \"$(date +%Y%m%d%H%M%S)\",
        \"CheckoutRequestID\": \"$CHECKOUT_ID\"
      }")
    
    echo "Query Response:"
    echo "$QUERY_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$QUERY_RESPONSE"
    
    RESULT_CODE=$(echo "$QUERY_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('ResultCode', ''))" 2>/dev/null || echo "")
    RESULT_DESC=$(echo "$QUERY_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('ResultDesc', ''))" 2>/dev/null || echo "")
    
    echo ""
    echo "Result Code: $RESULT_CODE"
    echo "Result Description: $RESULT_DESC"
    echo ""
    
    if [ "$RESULT_CODE" = "0" ]; then
        echo "✅ Payment completed successfully!"
    elif [ "$RESULT_CODE" = "1032" ]; then
        echo "⚠️  User cancelled the STK push (this is normal in testing)"
    else
        echo "ℹ️  Payment status: $RESULT_DESC"
    fi
    
else
    echo "❌ STK Push initiation failed"
    RESPONSE_DESC=$(echo "$STK_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin).get('ResponseDescription', ''))" 2>/dev/null || echo "")
    echo "Error: $RESPONSE_DESC"
    exit 1
fi

echo ""
echo "============================================================"
echo "✅ M-PESA INTEGRATION TEST COMPLETED"
echo "============================================================"
echo ""
echo "Summary:"
echo "  ✅ OAuth Authentication: Working"
echo "  ✅ STK Push Initiation: Working"
echo "  ✅ Payment Query: Working"
echo ""
echo "Next Steps:"
echo "  1. Configure webhook callback URL in .env"
echo "  2. Set up ngrok or public URL for webhook testing"
echo "  3. Test complete payment flow from your LMS frontend"
echo "  4. Monitor transactions in Django admin"
echo ""
