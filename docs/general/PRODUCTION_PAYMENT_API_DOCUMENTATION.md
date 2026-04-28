# PRODUCTION PAYMENT API INTEGRATION - COMPLETE

## Overview
This document provides the complete production API integration details for all payment gateways configured in the Hosi Academy LMS.

---

## 🔄 FLUTTERWAVE (Pan-Africa)

### Production API Endpoints

| Operation | Method | URL |
|-----------|--------|-----|
| Initialize Payment | POST | `https://api.flutterwave.com/v3/payments` |
| Verify Payment | GET | `https://api.flutterwave.com/v3/transactions/verify_by_reference?tx_ref={ref}` |
| Webhook | POST | Your configured webhook URL |

### Authentication
```
Authorization: Bearer {FLUTTERWAVE_SECRET_KEY}
Content-Type: application/json
```

### Initialize Payment Request
```json
POST https://api.flutterwave.com/v3/payments

{
  "tx_ref": "HOSI-20240316-001",
  "amount": "1500.00",
  "currency": "ZAR",
  "redirect_url": "https://lms.hosiacademy.co.za/payment/callback",
  "payment_options": "card,bank_transfer",
  "customer": {
    "email": "customer@example.com",
    "name": "John Doe",
    "phonenumber": "+27123456789"
  },
  "customizations": {
    "title": "Hosi Academy",
    "description": "Course Enrollment Payment",
    "logo": "https://lms.hosiacademy.co.za/static/logo.png"
  },
  "meta": {
    "enrollment_id": "123",
    "user_id": "456"
  },
  "session_duration": 10,
  "max_retry_attempt": 5
}
```

### Success Response
```json
{
  "status": "success",
  "message": "Hosted Link",
  "data": {
    "link": "https://checkout.flutterwave.com/v3/hosted/pay/..."
  }
}
```

### Webhook Events
- `charge.completed` - Payment successful
- `charge.failed` - Payment failed

---

## 💳 PAYSTACK (Nigeria, Ghana, Kenya, South Africa)

### Production API Endpoints

| Operation | Method | URL |
|-----------|--------|-----|
| Initialize Transaction | POST | `https://api.paystack.co/transaction/initialize` |
| Verify Transaction | GET | `https://api.paystack.co/transaction/verify/{reference}` |
| Webhook | POST | Your configured webhook URL |

### Authentication
```
Authorization: Bearer {PAYSTACK_SECRET_KEY}
Content-Type: application/json
```

### Initialize Transaction Request
```json
POST https://api.paystack.co/transaction/initialize

{
  "email": "customer@example.com",
  "amount": 150000,  // Amount in kobo (multiply by 100)
  "reference": "HOSI-20240316-001",
  "callback_url": "https://lms.hosiacademy.co.za/payment/callback",
  "metadata": {
    "enrollment_id": "123",
    "user_id": "456",
    "program_type": "short_course"
  },
  "bearer": "account"
}
```

### Success Response
```json
{
  "status": true,
  "message": "Authorization URL created",
  "data": {
    "authorization_url": "https://checkout.paystack.com/...",
    "access_code": "...",
    "reference": "HOSI-20240316-001"
  }
}
```

### Webhook Events
- `charge.success` - Payment successful
- `charge.failed` - Payment failed
- `charge.refund` - Payment refunded

---

## 🇿🇦 PAYFAST (South Africa)

### Production API Endpoints

| Operation | Method | URL |
|-----------|--------|-----|
| Process Payment | POST | `https://www.payfast.co.za/eng/process` |
| ITN Webhook | POST | Your configured notify_url |

### Authentication
MD5 Signature of all parameters + passphrase

### Payment Form Data
```
POST https://www.payfast.co.za/eng/process

merchant_id=10000100
merchant_key=your_merchant_key
amount=1500.00
item_name=Course Enrollment
return_url=https://lms.hosiacademy.co.za/payment/success
cancel_url=https://lms.hosiacademy.co.za/payment/cancel
notify_url=https://lms.hosiacademy.co.za/api/v1/payments/webhook/payfast
name_first=John
name_last=Doe
email_address=customer@example.com
custom_str1=123  // enrollment_id
custom_str2=456  // user_id
custom_str3=HOSI-20240316-001  // transaction_ref
signature=md5_hash_of_all_parameters
```

### Signature Generation
```python
# Sort parameters alphabetically
param_string = '&'.join(f"{k}={v}" for k, v in sorted(data.items()))

# Add passphrase if configured
if passphrase:
    param_string += f"&passphrase={passphrase}"

# Generate MD5 hash
signature = hashlib.md5(param_string.encode()).hexdigest()
```

### ITN Webhook Data
PayFast sends POST to notify_url with:
```
payment_status=COMPLETE
m_payment_id=12345678
payer_email=customer@example.com
amount_gross=1500.00
custom_str3=HOSI-20240316-001
signature=md5_hash
```

### ITN Response Codes
- `COMPLETE` - Payment successful
- `FAILED` - Payment failed
- `PENDING` - Payment pending

---

## 🇰🇪 M-PESA DARAJA (Kenya, Tanzania)

### Production API Endpoints

| Operation | Method | URL |
|-----------|--------|-----|
| OAuth Token | GET | `https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials` |
| STK Push | POST | `https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest` |
| STK Query | POST | `https://api.safaricom.co.ke/mpesa/stkpushquery/v1/query` |
| Callback | POST | Your configured CallBackURL |

### Authentication
OAuth 2.0 Bearer Token

### Get Access Token
```
GET https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials

Authorization: Basic base64(ConsumerKey:ConsumerSecret)
```

### STK Push Request
```json
POST https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest

{
  "BusinessShortCode": "174379",
  "Password": "base64(ShortCode+Passkey+Timestamp)",
  "Timestamp": "20240316120000",
  "TransactionType": "CustomerPayBillOnline",
  "Amount": 1500,
  "PartyA": "254712345678",
  "PartyB": "174379",
  "PhoneNumber": "254712345678",
  "CallBackURL": "https://lms.hosiacademy.co.za/api/v1/payments/webhook/mpesa",
  "AccountReference": "HOSI-20240316-001",
  "TransactionDesc": "Course Enrollment Payment"
}
```

### Password Generation
```python
timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
password = hashlib.sha256(f"{shortcode}{passkey}{timestamp}".encode()).hexdigest()
```

### STK Push Success Response
```json
{
  "MerchantRequestID": "12345-67890-1",
  "CheckoutRequestID": "ws_CO_16032024120000123456",
  "ResultCode": 0,
  "ResultDesc": "Accepted"
}
```

### Callback Webhook
```json
{
  "Body": {
    "stkCallback": {
      "MerchantRequestID": "12345-67890-1",
      "CheckoutRequestID": "ws_CO_16032024120000123456",
      "ResultCode": 0,
      "ResultDesc": "The service request is processed successfully.",
      "CallbackMetadata": {
        "Item": [
          {"Name": "Amount", "Value": 1500},
          {"Name": "MpesaReceiptNumber", "Value": "LGR123456789"},
          {"Name": "PhoneNumber", "Value": "254712345678"},
          {"Name": "TransactionDate", "Value": "20240316120530"}
        ]
      }
    }
  }
}
```

### Result Codes
- `0` - Success
- `1032` - User cancelled
- Other - Various errors

---

## 📋 ENVIRONMENT VARIABLES REQUIRED

### Flutterwave
```bash
FLUTTERWAVE_PUBLIC_KEY=FLWPUBK_LIVE_xxx
FLUTTERWAVE_SECRET_KEY=FLWSECK_LIVE_xxx
FLUTTERWAVE_WEBHOOK_SECRET=your_webhook_secret
```

### Paystack
```bash
PAYSTACK_PUBLIC_KEY=pk_live_xxx
PAYSTACK_SECRET_KEY=sk_live_xxx
PAYSTACK_WEBHOOK_SECRET=whsec_live_xxx
```

### PayFast
```bash
PAYFAST_MERCHANT_ID=your_merchant_id
PAYFAST_MERCHANT_KEY=your_merchant_key
PAYFAST_PASSPHRASE=your_passphrase
```

### M-Pesa
```bash
MPESA_CONSUMER_KEY=your_consumer_key
MPESA_CONSUMER_SECRET=your_consumer_secret
MPESA_PASSKEY=your_passkey
MPESA_SHORTCODE=174379
```

---

## 🔐 WEBHOOK CONFIGURATION

### Configure in Gateway Dashboards:

**Flutterwave:**
- Dashboard → Settings → Webhooks
- URL: `https://lms.hosiacademy.co.za/api/v1/payments/webhook/flutterwave`

**Paystack:**
- Dashboard → Settings → API Keys & Webhooks
- URL: `https://lms.hosiacademy.co.za/api/v1/payments/webhook/paystack`

**PayFast:**
- Account → Integration → ITN Settings
- URL: `https://lms.hosiacademy.co.za/api/v1/payments/webhook/payfast`

**M-Pesa:**
- Configured dynamically in STK Push request
- URL: `https://lms.hosiacademy.co.za/api/v1/payments/webhook/mpesa`

---

## ✅ TESTING CHECKLIST

### Before Production:
- [ ] Test mode enabled (`PAYMENT_TEST_MODE=True`)
- [ ] Sandbox API keys configured
- [ ] Test transactions completed for each gateway
- [ ] Webhooks tested using ngrok for local dev
- [ ] Error handling verified

### Going Live:
- [ ] Set `PAYMENT_TEST_MODE=False`
- [ ] Production API keys configured
- [ ] Webhook URLs updated to production
- [ ] SSL certificates valid
- [ ] Test with small real amounts (R1, $1, etc.)
- [ ] Monitor first transactions closely

---

## 🚨 ERROR HANDLING

### Common Errors:

**401 Unauthorized**
- Invalid API key
- Expired token (M-Pesa tokens expire after 1 hour)

**400 Bad Request**
- Invalid amount format
- Missing required fields
- Invalid phone number format

**402 Payment Required**
- Insufficient funds
- Card declined

**500 Server Error**
- Gateway service down
- Retry with exponential backoff

---

## 📊 MONITORING

### Log These Events:
- Payment initiation requests
- Webhook receipts
- Verification failures
- Signature validation failures

### Metrics to Track:
- Success rate per gateway
- Average transaction time
- Failed transaction reasons
- Webhook delivery rate

---

## 📞 SUPPORT CONTACTS

| Gateway | Countries | Support | Dashboard |
|---------|-----------|---------|-----------|
| Flutterwave | Pan-Africa | support@flutterwave.com | app.flutterwave.com |
| Paystack | NG, GH, KE, ZA | support@paystack.com | dashboard.paystack.com |
| PayFast | ZA, NA, BW | support@payfast.io | www.payfast.io |
| M-Pesa | KE, TZ | developer@safaricom.co.ke | developer.safaricom.co.ke |

---

**Date:** March 16, 2026
**Status:** ✅ PRODUCTION READY
**Version:** 1.0
