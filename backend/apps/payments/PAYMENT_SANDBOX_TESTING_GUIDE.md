# Payment Provider Sandbox Testing Guide

## Overview

This guide provides comprehensive instructions for testing payment provider integrations across all 58 African countries. Each provider has sandbox/test credentials and test scenarios documented.

## Quick Start

```bash
# List all available sandbox tests
python manage.py test_payment_sandbox --list

# Test a specific provider
python manage.py test_payment_sandbox --provider=paynow
python manage.py test_payment_sandbox --provider=mpesa
python manage.py test_payment_sandbox --provider=paystack

# Test webhook endpoint
python manage.py test_payment_sandbox --provider=paynow --webhook
```

---

## 🇿🇼 Zimbabwe - Paynow (EcoCash)

### Sandbox Credentials
- **URL**: https://sandbox.paynow.co.zw/
- **Integration ID**: Check `.env` for `PAYNOW_INTEGRATION_ID`
- **Integration Key**: Check `.env` for `PAYNOW_INTEGRATION_KEY`

### Test Scenarios

| Scenario | Phone | Email | Expected Result |
|----------|-------|-------|-----------------|
| Successful Payment | +263771234567 | success@test.com | Payment Success |
| Failed Payment | +263771234568 | failure@test.com | Insufficient Funds |
| Cancelled | +263771234569 | cancel@test.com | User Cancelled |

### Testing Steps

1. **Initiate Payment**
   ```bash
   python manage.py test_payment_sandbox --provider=paynow
   ```

2. **Test Webhook**
   ```bash
   curl -X POST http://localhost:8000/api/payments/webhooks/paynow/ \
     -H "Content-Type: application/json" \
     -d '{
       "status": "Success",
       "reference": "TEST123456",
       "amount": 10.00,
       "currency": "USD"
     }'
   ```

3. **Verify in Dashboard**
   - Login to Paynow sandbox dashboard
   - Check transaction status
   - Verify webhook logs

### Expected Flow
```
User → Select Paynow → Enter Phone → EcoCash Prompt → Enter PIN (1234) → Success
                                                              ↓
                                              Webhook → /api/payments/webhooks/paynow/
```

---

## 🇰🇪 Kenya - M-Pesa (Safaricom)

### Sandbox Credentials
- **URL**: https://sandbox.safaricom.co.ke/
- **Consumer Key**: Check `.env` for `MPESA_CONSUMER_KEY`
- **Consumer Secret**: Check `.env` for `MPESA_CONSUMER_SECRET`
- **Passkey**: `bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919`
- **Business Shortcode**: `174379`

### Test Phone Numbers

| Scenario | Phone Number | Expected |
|----------|--------------|----------|
| Successful STK Push | +254708374166 | Success |
| Failed (Wrong PIN) | +254708374167 | Failed |
| Timeout | +254708374168 | Timeout |

### Testing Steps

1. **Get OAuth Token**
   ```bash
   curl -X GET https://sandbox.safaricom.co.ke/oauth/v1/generate \
     -u "CONSUMER_KEY:CONSUMER_SECRET"
   ```

2. **Initiate STK Push**
   ```bash
   python manage.py test_payment_sandbox --provider=mpesa
   ```

3. **Test Callback**
   ```bash
   curl -X POST http://localhost:8000/api/payments/webhooks/mpesa/ \
     -H "Content-Type: application/json" \
     -d '{
       "Body": {
         "stkCallback": {
           "MerchantRequestID": "12345",
           "CheckoutRequestID": "ws_CO_123456",
           "ResultCode": 0,
           "ResultDesc": "The service request is processed successfully."
         }
       }
     }'
   ```

### STK Push Test PIN
- **Success**: Enter `1234` on phone simulator
- **Failure**: Enter wrong PIN

---

## 🇳🇬 Nigeria - Paystack

### Sandbox Credentials
- **URL**: https://test.paystack.com/
- **Public Key**: Check `.env` for `PAYSTACK_PUBLIC_KEY`
- **Secret Key**: Check `.env` for `PAYSTACK_SECRET_KEY`
- **Webhook Secret**: Check `.env` for `PAYSTACK_WEBHOOK_SECRET`

### Test Cards

| Card Type | Number | CVV | Expiry | Expected |
|-----------|--------|-----|--------|----------|
| Visa Success | 4084084084084081 | 888 | 01/2030 | Success |
| MC Success | 5336699999999992 | 737 | 12/2029 | Success |
| Declined | 4084084084084082 | 888 | 01/2030 | Declined |
| Insufficient Funds | 4084084084084083 | 888 | 01/2030 | Failed |

### Test Mobile Money

| Network | Phone | Country | Expected |
|---------|-------|---------|----------|
| MTN MoMo | +233540000001 | Ghana | Success |
| Airtel | +233540000002 | Ghana | Success |

### Testing Steps

1. **Initialize Payment**
   ```bash
   python manage.py test_payment_sandbox --provider=paystack
   ```

2. **Test Card Payment**
   - Use test cards above in payment form
   - No 3DS required in sandbox

3. **Test Webhook Signature**
   ```bash
   # Paystack sends X-Paystack-Signature header
   # Verify using PAYSTACK_WEBHOOK_SECRET
   ```

---

## 🌍 Flutterwave (Pan-African)

### Sandbox Credentials
- **URL**: https://sandbox.flutterwave.com/
- **Public Key**: Check `.env` for `FLUTTERWAVE_PUBLIC_KEY`
- **Secret Key**: Check `.env` for `FLUTTERWAVE_SECRET_KEY`

### Supported Countries
NG, KE, GH, ZA, UG, TZ, RW, ZM, CM, SN, CI, ML, BF, NE, TG, BJ

### Test Cards

| Card Type | Number | CVV | Expiry | Expected |
|-----------|--------|-----|--------|----------|
| Visa Success | 4543474001573969 | 577 | 09/2026 | Success |
| MC Success | 5531886652142950 | 577 | 09/2026 | Success |

### Test Mobile Money

| Provider | Phone | Country | Expected |
|----------|-------|---------|----------|
| M-Pesa | +254708374166 | Kenya | Success |
| MTN MoMo | +256700000001 | Uganda | Success |
| Airtel | +256700000002 | Uganda | Success |

---

## 🇿🇦 South Africa - PayFast

### Sandbox Credentials
- **URL**: https://sandbox.payfast.co.za/
- **Merchant ID**: Check `.env`
- **Merchant Key**: Check `.env`

### Test Scenarios

| Scenario | Method | Expected |
|----------|--------|----------|
| Card Payment | Visa/Mastercard | Success |
| Instant EFT | Standard Bank | Success |
| Zapper | QR Code | Success |

### Testing Steps

1. **Create Payment Form**
   ```html
   <form action="https://sandbox.payfast.co.za/eng/process" method="post">
     <input type="hidden" name="merchant_id" value="YOUR_ID">
     <input type="hidden" name="amount" value="10.00">
     <input type="hidden" name="return_url" value="http://yoursite.com/success">
     <input type="hidden" name="cancel_url" value="http://yoursite.com/cancel">
   </form>
   ```

2. **Test ITN (Instant Transaction Notification)**
   ```bash
   curl -X POST http://localhost:8000/api/payments/webhooks/payfast/ \
     -d "payment_status=COMPLETE" \
     -d "amount_gross=10.00"
   ```

---

## 🇬🇭 Ghana - MTN MoMo

### Sandbox Credentials
- **API URL**: https://sandbox.momodeveloper.mtn.com/
- **API Key**: Check `.env`
- **User ID**: Check `.env`

### Test Numbers

| Scenario | Phone | Expected |
|----------|-------|----------|
| Success | +233540000001 | Success |
| Invalid | +233540000000 | Failed |

---

## 🇪🇬 Egypt - Fawry

### Sandbox Credentials
- **URL**: https://atfawry.fawry.com/
- **Merchant Code**: Check `.env`
- **Security Key**: Check `.env`

### Test Scenarios

| Scenario | Reference | Expected |
|----------|-----------|----------|
| Card Payment | TEST123456 | Success |
| Cash at Kiosk | TEST123457 | Pending |

---

## 🇸🇳 Senegal - Wave

### Sandbox Credentials
- **URL**: https://sandbox.wave.com/
- **API Key**: Check `.env`

### Test Numbers

| Scenario | Phone | Expected |
|----------|-------|----------|
| Success | +221770000001 | Success |

---

## Webhook Testing

### Using ngrok for Local Testing

```bash
# Install ngrok
npm install -g ngrok

# Start ngrok tunnel
ngrok http 8000

# Use the ngrok URL in provider dashboard
# Example: https://abc123.ngrok.io/api/payments/webhooks/paynow/
```

### Webhook Verification

Each provider requires signature verification:

```python
# Paynow
hash = hashlib.sha256(
    f"{reference}{status}{PAYNOW_INTEGRATION_KEY}".encode()
).hexdigest()

# Paystack
signature = hmac.new(
    PAYSTACK_WEBHOOK_SECRET.encode(),
    request.body,
    hashlib.sha512
).hexdigest()

# M-Pesa
# Encrypted callback - decrypt using M-Pesa certificate
```

---

## Common Issues & Solutions

### 1. Webhook Not Received

**Problem**: Provider sends webhook but backend doesn't receive it

**Solutions**:
- Ensure server is publicly accessible (use ngrok for local dev)
- Check firewall settings
- Verify webhook URL is correct
- Check server logs

### 2. Signature Verification Fails

**Problem**: Webhook signature doesn't match

**Solutions**:
- Verify you're using correct secret key
- Check request body encoding
- Ensure timestamp is within acceptable range
- Compare raw request body

### 3. Sandbox Credentials Invalid

**Problem**: API returns 401 Unauthorized

**Solutions**:
- Regenerate sandbox credentials in provider dashboard
- Check environment variables are loaded
- Verify sandbox mode is enabled

### 4. Test Card Declined

**Problem**: Test card returns decline

**Solutions**:
- Use correct test card numbers
- Check card expiry is in future
- Verify CVV is correct
- Some providers require specific test cards per scenario

---

## Testing Checklist

### Before Production

- [ ] All sandbox tests pass
- [ ] Webhook endpoints respond with 200 OK
- [ ] Signature verification works
- [ ] Error handling tested
- [ ] Timeout scenarios tested
- [ ] Refund flow tested
- [ ] Currency conversion tested
- [ ] Mobile money tested (if applicable)
- [ ] Card payments tested (if applicable)
- [ ] Bank transfer tested (if applicable)

### For Each Country

- [ ] Local payment methods work
- [ ] Currency displays correctly
- [ ] Amounts validate correctly
- [ ] Success flow completes enrollment
- [ ] Failure flow shows proper error
- [ ] Webhook updates transaction status
- [ ] Email/SMS notifications sent

---

## API Reference

### Get Available Providers by Country
```bash
curl http://localhost:8000/api/payments/providers/?country=ZW
```

### Detect Country from IP
```bash
curl http://localhost:8000/api/payments/detect-country/
```

### Initiate Payment
```bash
curl -X POST http://localhost:8000/api/payments/initiate/ \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "amount": 50.00,
    "currency": "USD",
    "provider": "paynow",
    "phone": "+263771234567"
  }'
```

---

## Support

For provider-specific issues:
- **Paynow**: support@paynow.co.zw
- **M-Pesa**: developers@safaricom.co.ke
- **Paystack**: support@paystack.com
- **Flutterwave**: support@flutterwave.com

For LMS integration issues:
- Check logs: `/home/tk/lms-prod/backend/logs/`
- Review webhook logs in Django admin
- Contact development team
