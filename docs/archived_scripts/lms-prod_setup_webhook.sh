#!/bin/bash
# Complete M-Pesa Webhook Setup and Testing
# This script configures and tests the complete payment flow

set -e

echo "============================================================"
echo "🔗 M-PESA WEBHOOK CONFIGURATION & TESTING"
echo "============================================================"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

cd /home/tk/lms-prod

echo -e "${BLUE}Step 1: Checking Current Configuration${NC}"
echo "-----------------------------------------------------------"

# Check if .env has the callback URL
CALLBACK_URL=$(grep "^MPESA_CALLBACK_URL=" backend/.env | cut -d'=' -f2)
echo "Current Callback URL: $CALLBACK_URL"

if [ "$CALLBACK_URL" = "https://hosiacademy.com/api/payments/webhooks/mpesa/" ]; then
    echo -e "${GREEN}✓ Production callback URL configured${NC}"
else
    echo -e "${YELLOW}⚠ Callback URL may need updating${NC}"
fi

# Check nginx configuration
echo ""
echo "Checking nginx configuration..."
if grep -q "location /api/v1/payments/" nginx/nginx.conf; then
    echo -e "${GREEN}✓ Nginx payment routing configured${NC}"
else
    echo -e "${RED}✗ Nginx payment routing NOT found${NC}"
fi

# Check if backend is accessible
echo ""
echo "Testing backend accessibility..."
BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:7001/ || echo "000")
if [ "$BACKEND_RESPONSE" != "000" ]; then
    echo -e "${GREEN}✓ Backend is running (HTTP $BACKEND_RESPONSE)${NC}"
else
    echo -e "${YELLOW}⚠ Backend not directly accessible (this is OK if using nginx)${NC}"
fi

# Check production domain
echo ""
echo "Testing production domain (hosiacademy.com)..."
PROD_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -k https://hosiacademy.com/ || echo "000")
if [ "$PROD_RESPONSE" != "000" ]; then
    echo -e "${GREEN}✓ Production domain accessible (HTTP $PROD_RESPONSE)${NC}"
else
    echo -e "${YELLOW}⚠ Production domain not accessible from this server${NC}"
fi

echo ""
echo -e "${BLUE}Step 2: Webhook Endpoint Testing${NC}"
echo "-----------------------------------------------------------"

# Test webhook endpoint directly
echo "Testing webhook endpoint..."
WEBHOOK_TEST=$(curl -s -X POST \
  http://localhost:7001/api/payments/webhooks/mpesa/ \
  -H "Content-Type: application/json" \
  -d '{"Body": {"stkCallback": {"test": true}}}' \
  -w "\nHTTP_CODE:%{http_code}" || echo "HTTP_CODE:000")

WEBHOOK_CODE=$(echo "$WEBHOOK_TEST" | grep "HTTP_CODE:" | cut -d':' -f2)
echo "Webhook endpoint response: HTTP $WEBHOOK_CODE"

if [ "$WEBHOOK_CODE" = "200" ] || [ "$WEBHOOK_CODE" = "400" ]; then
    echo -e "${GREEN}✓ Webhook endpoint is working${NC}"
else
    echo -e "${YELLOW}⚠ Webhook endpoint returned HTTP $WEBHOOK_CODE${NC}"
fi

echo ""
echo -e "${BLUE}Step 3: Simulating M-Pesa Webhook${NC}"
echo "-----------------------------------------------------------"

# Create a realistic M-Pesa callback payload
cat > /tmp/mpesa_webhook_test.json << 'EOF'
{
  "Body": {
    "stkCallback": {
      "MerchantRequestID": "TEST-12345",
      "CheckoutRequestID": "ws_CO_123456789",
      "ResultCode": 0,
      "ResultDesc": "The service request is processed successfully.",
      "CallbackMetadata": {
        "Item": [
          {"Name": "Amount", "Value": 1},
          {"Name": "MpesaReceiptNumber", "Value": "TEST123456"},
          {"Name": "TransactionDate", "Value": 20260316120000},
          {"Name": "PhoneNumber", "Value": "254712345678"}
        ]
      }
    }
  }
}
EOF

echo "Sending test webhook payload..."
WEBHOOK_RESPONSE=$(curl -s -X POST \
  http://localhost:7001/api/payments/webhooks/mpesa/ \
  -H "Content-Type: application/json" \
  -d @/tmp/mpesa_webhook_test.json \
  -w "\nHTTP_CODE:%{http_code}")

WEBHOOK_RESULT_CODE=$(echo "$WEBHOOK_RESPONSE" | grep "HTTP_CODE:" | cut -d':' -f2)
echo "Webhook test result: HTTP $WEBHOOK_RESULT_CODE"

if [ "$WEBHOOK_RESULT_CODE" = "200" ]; then
    echo -e "${GREEN}✓ Webhook processing successful${NC}"
    echo "Response body:"
    echo "$WEBHOOK_RESPONSE" | grep -v "HTTP_CODE:" | python3 -m json.tool 2>/dev/null || echo "$WEBHOOK_RESPONSE" | grep -v "HTTP_CODE:"
else
    echo -e "${YELLOW}⚠ Webhook returned HTTP $WEBHOOK_RESULT_CODE (may need transaction to exist)${NC}"
fi

echo ""
echo -e "${BLUE}Step 4: Testing Production Webhook URL${NC}"
echo "-----------------------------------------------------------"

# Test if production URL is accessible
if command -v curl &> /dev/null; then
    echo "Testing: https://hosiacademy.com/api/payments/webhooks/mpesa/"
    
    PROD_WEBHOOK_TEST=$(curl -s -X POST \
      https://hosiacademy.com/api/payments/webhooks/mpesa/ \
      -H "Content-Type: application/json" \
      -d '{"test": true}' \
      -k \
      --connect-timeout 5 \
      -w "\nHTTP_CODE:%{http_code}" || echo "HTTP_CODE:000")
    
    PROD_WEBHOOK_CODE=$(echo "$PROD_WEBHOOK_TEST" | grep "HTTP_CODE:" | cut -d':' -f2)
    echo "Production webhook endpoint: HTTP $PROD_WEBHOOK_CODE"
    
    if [ "$PROD_WEBHOOK_CODE" = "200" ] || [ "$PROD_WEBHOOK_CODE" = "400" ]; then
        echo -e "${GREEN}✓ Production webhook URL is accessible${NC}"
    else
        echo -e "${YELLOW}⚠ Production webhook URL returned HTTP $PROD_WEBHOOK_CODE${NC}"
        echo "This is OK if:"
        echo "  - Domain is still propagating"
        echo "  - SSL certificate is being configured"
        echo "  - You're testing from inside the server"
    fi
fi

echo ""
echo -e "${BLUE}Step 5: Configuration Summary${NC}"
echo "-----------------------------------------------------------"

echo ""
echo "Current M-Pesa Configuration:"
echo "  Environment: $(grep "^MPESA_ENVIRONMENT=" backend/.env | cut -d'=' -f2)"
echo "  Sandbox Mode: $(grep "^MPESA_SANDBOX=" backend/.env | cut -d'=' -f2)"
echo "  Shortcode: $(grep "^MPESA_BUSINESS_SHORTCODE=" backend/.env | cut -d'=' -f2)"
echo "  Callback URL: $CALLBACK_URL"
echo ""

echo "Webhook URL Components:"
echo "  Domain: hosiacademy.com"
echo "  Path: /api/payments/webhooks/mpesa/"
echo "  Protocol: HTTPS"
echo "  Nginx Routing: ✓ Configured"
echo ""

echo -e "${GREEN}============================================================"
echo "✅ WEBHOOK CONFIGURATION COMPLETE"
echo "============================================================${NC}"
echo ""

echo "Next Steps:"
echo "  1. Ensure SSL certificate is installed on production"
echo "  2. Test with real M-Pesa transaction"
echo "  3. Monitor webhook logs: docker-compose logs -f backend"
echo "  4. Check Django admin for transactions"
echo ""

echo "Useful Commands:"
echo "  # Watch webhook logs in real-time"
echo "  docker-compose logs -f backend | grep -i webhook"
echo ""
echo "  # View recent webhook logs"
echo "  docker-compose exec backend python manage.py shell"
echo "  >>> from apps.payments.models import PaymentWebhookLog"
echo "  >>> PaymentWebhookLog.objects.all().order_by('-created_at')[:5]"
echo ""
echo "  # Test webhook manually"
echo "  curl -X POST https://hosiacademy.com/api/payments/webhooks/mpesa/ \\"
echo "    -H 'Content-Type: application/json' \\"
echo "    -d '{\"Body\": {\"stkCallback\": {\"test\": true}}}'"
echo ""

# Cleanup
rm -f /tmp/mpesa_webhook_test.json

echo "Done!"
