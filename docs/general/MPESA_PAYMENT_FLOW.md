# M-Pesa Payment Flow Documentation

## Overview
Your LMS has a complete M-Pesa STK Push integration for Kenya. This document shows the entire payment flow, API endpoints, and data flow.

---

## 1. Configuration (`backend/.env`)

```bash
# M-Pesa Configuration
MPESA_ENVIRONMENT=sandbox
MPESA_CONSUMER_KEY=your_consumer_key          # Get from Daraja Portal
MPESA_CONSUMER_SECRET=your_consumer_secret    # Get from Daraja Portal
MPESA_BUSINESS_SHORTCODE=174379               # Sandbox shortcode
MPESA_PASSKEY=bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919
MPESA_INITIATOR_NAME=testapi
MPESA_SECURITY_CREDENTIAL=your_security_credential
MPESA_CALLBACK_URL=https://hosiacademy.com/api/payments/webhooks/mpesa/
```

---

## 2. Payment Flow Sequence

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Frontend  │     │  Your LMS API │     │  M-Pesa API │     │   Customer   │     │   Webhook   │
│  (React/JS) │     │  (Django)     │     │  (Safaricom)│     │   (Phone)    │     │  Endpoint   │
└──────┬──────┘     └──────┬───────┘     └──────┬──────┘     └──────┬───────┘     └──────┬──────┘
       │                   │                     │                   │                   │
       │ 1. GET /api/payments/providers/?country=KE
       │──────────────────>│                     │                   │                   │
       │                   │                     │                   │                   │
       │ 2. Returns M-Pesa as available provider
       │<──────────────────│                     │                   │                   │
       │                   │                     │                   │                   │
       │ 3. POST /api/payments/initiate/
       │    {provider: 'mpesa', phone: '2547...', amount: 1000}
       │──────────────────>│                     │                   │                   │
       │                   │                     │                   │                   │
       │                   │ 4. Get OAuth Token  │                   │                   │
       │                   │────────────────────>│                   │                   │
       │                   │                     │                   │                   │
       │                   │ 5. Access Token     │                   │                   │
       │                   │<────────────────────│                   │                   │
       │                   │                     │                   │                   │
       │                   │ 6. POST STK Push Request
       │                   │────────────────────>│                   │                   │
       │                   │                     │                   │                   │
       │ 7. Checkout ID    │                     │                   │                   │
       │<──────────────────│                     │                   │                   │
       │                   │                     │                   │                   │
       │ 8. Show "Check your phone" message
       │                   │                     │ 9. USSD Prompt    │                   │
       │────────────────────────────────────────────────────────────>│                   │
       │                   │                     │                   │                   │
       │                   │                     │ 10. User enters PIN
       │                   │                     │<──────────────────│                   │
       │                   │                     │                   │                   │
       │                   │ 11. POST Callback (async)
       │                   │<────────────────────────────────────────────────────────────│
       │                   │                     │                   │                   │
       │                   │ 12. Process Webhook │                   │                   │
       │                   │     - Update transaction status
       │                   │     - Trigger enrollment
       │                   │                     │                   │                   │
       │ 13. Poll status   │                     │                   │                   │
       │──────────────────>│                     │                   │                   │
       │                   │                     │                   │                   │
       │ 14. Payment complete
       │<──────────────────│                     │                   │                   │
       │                   │                     │                   │                   │
```

---

## 3. API Endpoints

### 3.1 Get Available Providers
```http
GET /api/payments/providers/?country=KE&currency=KES
```

**Response:**
```json
{
  "detected_country": "KE",
  "detected_currency": "KES",
  "available_providers": [
    {
      "code": "mpesa",
      "name": "M-Pesa",
      "supported": true,
      "requires_phone": true
    }
  ]
}
```

---

### 3.2 Initiate Payment (STK Push)
```http
POST /api/payments/initiate/
Content-Type: application/json

{
  "provider": "mpesa",
  "amount": 1000,
  "currency": "KES",
  "country": "KE",
  "phone_number": "254712345678",
  "metadata": {
    "email": "user@example.com",
    "enrollment_code": "ENR-ABC123"
  }
}
```

**Response:**
```json
{
  "status": "success",
  "transaction": {
    "id": "txn_12345",
    "provider_reference": "MPESA_20260316_001",
    "status": "pending"
  },
  "provider_code": "mpesa",
  "requires_stk_push": true,
  "stk_push_message": "Check your phone to complete payment",
  "checkout_id": "ws_CO_123456789"
}
```

---

### 3.3 Webhook Endpoint (Callback)
```http
POST /api/payments/webhooks/mpesa/
Content-Type: application/json

{
  "Body": {
    "stkCallback": {
      "MerchantRequestID": "12345",
      "CheckoutRequestID": "ws_CO_123456789",
      "ResultCode": 0,
      "ResultDesc": "The service request is processed successfully.",
      "CallbackMetadata": {
        "Item": [
          {"Name": "Amount", "Value": 1000},
          {"Name": "MpesaReceiptNumber", "Value": "LGR123456789"},
          {"Name": "TransactionDate", "Value": 20260316120000},
          {"Name": "PhoneNumber", "Value": "254712345678"}
        ]
      }
    }
  }
}
```

**Response:**
```json
{
  "status": "success",
  "message": "Webhook processed successfully",
  "transaction_id": "txn_12345"
}
```

---

### 3.4 Verify Payment Status
```http
GET /api/payments/verify/<transaction_id>/
```

**Response:**
```json
{
  "status": "success",
  "transaction": {
    "id": "txn_12345",
    "status": "successful",
    "amount": 1000,
    "currency": "KES",
    "provider": "mpesa",
    "provider_reference": "LGR123456789",
    "completed_at": "2026-03-16T12:00:00Z"
  }
}
```

---

## 4. Code Flow

### 4.1 Initiate Payment Flow

**File:** `backend/apps/payments/views/payment_views.py`

```python
class InitiatePaymentView(APIView):
    def post(self, request):
        # 1. Validate provider is M-Pesa
        provider_code = data.get('provider')  # 'mpesa'
        
        # 2. Check phone number required for STK Push
        if provider_code in ['mpesa', 'airtel_money', 'mtn_momo']:
            phone_number = get_phone_from_metadata(data)
            if not phone_number:
                return error("Phone number required")
        
        # 3. Call payment service
        result = payment_service.initiate_payment(
            user=user,
            amount=1000,
            currency='KES',
            country='KE',
            provider_code='mpesa',
            phone_number='254712345678',
            metadata={...}
        )
        
        # 4. Return checkout ID
        return Response(result)
```

---

### 4.2 M-Pesa Adapter (STK Push)

**File:** `backend/apps/payments/adapters/mpesa.py`

```python
class MpesaAdapter(BasePaymentAdapter):
    
    def initiate_payment(self, transaction, **kwargs):
        # 1. Format phone number
        phone = self._format_phone(kwargs['phone_number'])  # 254712345678
        
        # 2. Get OAuth token
        token = self._get_access_token()
        
        # 3. Generate password (base64 of shortcode+passkey+timestamp)
        timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
        password = self._generate_password(timestamp)
        
        # 4. Build STK Push payload
        payload = {
            'BusinessShortCode': self.business_shortcode,
            'Password': password,
            'Timestamp': timestamp,
            'TransactionType': 'CustomerPayBillOnline',
            'Amount': int(transaction.amount),
            'PartyA': phone,
            'PartyB': self.business_shortcode,
            'PhoneNumber': phone,
            'CallBackURL': self.callback_url,
            'AccountReference': transaction.provider_reference,
            'TransactionDesc': transaction.description[:20]
        }
        
        # 5. Send request to M-Pesa
        response = requests.post(
            f"{self.base_url}{self.STK_PUSH_URL}",
            headers={'Authorization': f'Bearer {token}'},
            json=payload
        )
        
        # 6. Return checkout ID
        return {
            'checkout_id': response['CheckoutRequestID'],
            'customer_message': response['CustomerMessage']
        }
```

---

### 4.3 Webhook Processing

**File:** `backend/apps/payments/views/webhook_views.py`

```python
@csrf_exempt
@require_POST
def provider_webhook(request, provider_code):
    # 1. Capture raw body (for signature verification)
    raw_body = request.body
    
    # 2. Parse payload
    payload = json.loads(raw_body)
    
    # 3. Log webhook
    PaymentWebhookLog.objects.create(...)
    
    # 4. Process via payment service
    transaction = payment_service.handle_webhook(
        provider_code='mpesa',
        payload=payload,
        headers=dict(request.headers),
        raw_body=raw_body
    )
    
    # 5. Return success
    return JsonResponse({'status': 'success'})
```

---

### 4.4 M-Pesa Callback Handler

**File:** `backend/apps/payments/adapters/mpesa.py`

```python
def process_webhook(self, payload, headers):
    # 1. Extract callback data
    callback_data = payload.get('Body', {}).get('stkCallback', {})
    checkout_id = callback_data.get('CheckoutRequestID')
    result_code = callback_data.get('ResultCode')  # 0 = success
    
    # 2. Find transaction by checkout_id
    transaction = PaymentTransaction.objects.filter(
        metadata__checkout_id=checkout_id
    ).first()
    
    # 3. Update transaction status
    if result_code == 0:
        transaction.status = 'successful'
        
        # Extract payment details
        callback_items = callback_data.get('CallbackMetadata', {}).get('Item', [])
        for item in callback_items:
            if item['Name'] == 'MpesaReceiptNumber':
                transaction.provider_reference = item['Value']
        
        transaction.completed_at = timezone.now()
        transaction.webhook_received = True
        
        # 4. Trigger enrollment completion
        self._handle_successful_payment(transaction)
    else:
        transaction.status = 'failed'
        transaction.metadata['mpesa_error'] = {
            'result_code': result_code,
            'result_desc': callback_data.get('ResultDesc')
        }
    
    transaction.save()
    return transaction
```

---

## 5. Database Models

### PaymentTransaction
```python
class PaymentTransaction(models.Model):
    id = models.UUIDField(primary_key=True)
    user = models.ForeignKey(User)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3)  # 'KES'
    provider = models.CharField(max_length=50)  # 'mpesa'
    provider_reference = models.CharField(max_length=100)  # M-Pesa receipt
    status = models.CharField(max_length=20)  # pending, successful, failed
    metadata = models.JSONField()  # {checkout_id, phone, etc}
    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True)
    webhook_received = models.BooleanField(default=False)
```

---

## 6. Testing the Flow

### Test Script Location
```bash
/home/tk/lms-prod/test_comprehensive_payment_sandbox.py
```

### Run Test
```bash
cd /home/tk/lms-prod
docker-compose run --rm backend python test_comprehensive_payment_sandbox.py
```

### Manual Test (Sandbox)
```bash
# 1. Initiate payment
curl -X POST http://localhost:8000/api/payments/initiate/ \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "mpesa",
    "amount": 1,
    "currency": "KES",
    "country": "KE",
    "phone_number": "254708374149",
    "metadata": {"email": "test@example.com"}
  }'

# 2. Simulate callback
curl -X POST http://localhost:8000/api/payments/webhooks/mpesa/ \
  -H "Content-Type: application/json" \
  -d '{
    "Body": {
      "stkCallback": {
        "CheckoutRequestID": "ws_CO_123456789",
        "ResultCode": 0,
        "ResultDesc": "Success",
        "CallbackMetadata": {
          "Item": [
            {"Name": "Amount", "Value": 1},
            {"Name": "MpesaReceiptNumber", "Value": "LGR123456789"}
          ]
        }
      }
    }
  }'
```

---

## 7. Environment Settings

### Django Settings (`settings.py`)
```python
# M-Pesa Configuration
MPESA_SANDBOX = True  # Set to False for production
MPESA_CONSUMER_KEY = config('MPESA_CONSUMER_KEY', default='')
MPESA_CONSUMER_SECRET = config('MPESA_CONSUMER_SECRET', default='')
MPESA_BUSINESS_SHORTCODE = config('MPESA_BUSINESS_SHORTCODE', default='174379')
MPESA_PASSKEY = config('MPESA_PASSKEY', default='bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919')
MPESA_CALLBACK_URL = config('MPESA_CALLBACK_URL', default='')
```

---

## 8. Production Checklist

- [ ] Get production credentials from Daraja Portal
- [ ] Update `MPESA_SANDBOX=False`
- [ ] Set production `MPESA_CALLBACK_URL` (must be publicly accessible)
- [ ] Configure SSL/HTTPS for webhook endpoint
- [ ] Test with real M-Pesa payments (small amounts)
- [ ] Set up webhook logging monitoring
- [ ] Configure alerting for failed webhooks
- [ ] Document support process for failed payments

---

## 9. Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Invalid access token" | Check Consumer Key/Secret are correct |
| "Callback URL not reachable" | Ensure HTTPS and publicly accessible |
| "Transaction not found" | Check CheckoutRequestID matches metadata |
| "ResultCode: 1032" | User cancelled STK push |
| "ResultCode: 1001" | Insufficient funds |

### Debug Logs
```bash
# View recent webhooks
docker-compose exec backend python manage.py shell
>>> from apps.payments.models import PaymentWebhookLog
>>> PaymentWebhookLog.objects.filter(provider='mpesa').order_by('-created_at')[:5]
```

---

## 10. Files Reference

| File | Purpose |
|------|---------|
| `backend/apps/payments/adapters/mpesa.py` | M-Pesa API integration |
| `backend/apps/payments/views/payment_views.py` | Payment initiation |
| `backend/apps/payments/views/webhook_views.py` | Webhook handler |
| `backend/apps/payments/services/payment_service.py` | Payment orchestration |
| `backend/apps/payments/urls.py` | URL routing |
| `backend/.env` | Configuration |

---

## Next Steps

1. **Get Credentials:** Visit https://developer.safaricom.co.ke/
2. **Update `.env`:** Add your Consumer Key and Secret
3. **Test:** Run the sandbox test script
4. **Deploy:** Configure production callback URL with HTTPS
