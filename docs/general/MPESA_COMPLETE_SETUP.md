# 🚀 M-Pesa Complete Setup Guide

## Overview

This guide covers all three steps to get your M-Pesa integration fully operational:
1. ✅ **Webhook Configuration** - DONE
2. 🧪 **Frontend Testing** - IN PROGRESS
3. 📋 **Production Credentials** - PENDING

---

## Step 1: ✅ Webhook Configuration (COMPLETE)

### Current Configuration

**Callback URL:** `https://hosiacademy.com/api/v1/payments/webhooks/mpesa/`

**Status:** ✅ Configured and ready

### What's Working

- ✅ Nginx routing configured (`/api/v1/payments/`)
- ✅ Webhook endpoint: `/api/v1/payments/webhooks/mpesa/`
- ✅ Django settings updated
- ✅ Callback URL in `.env` updated

### Webhook Flow

```
User pays on phone → Safaricom → Your webhook → Database → Enrollment complete
                        ↓
            https://hosiacademy.com/api/v1/payments/webhooks/mpesa/
```

---

## Step 2: 🧪 Frontend Testing

### Test Page Created

**File:** `/home/tk/lms-prod/mpesa_test_page.html`

### How to Use the Test Page

#### Option 1: Open Directly

```bash
# Open the file in your browser
xdg-open /home/tk/lms-prod/mpesa_test_page.html
# or
firefox /home/tk/lms-prod/mpesa_test_page.html
```

#### Option 2: Serve via Nginx

1. **Copy to nginx html directory:**
   ```bash
   cp /home/tk/lms-prod/mpesa_test_page.html /home/tk/lms-prod/nginx/html/
   ```

2. **Access via browser:**
   ```
   https://hosiacademy.com/mpesa_test_page.html
   ```

#### Option 3: Use Python HTTP Server

```bash
cd /home/tk/lms-prod
python3 -m http.server 8080
# Open: http://localhost:8080/mpesa_test_page.html
```

### Test Page Features

✅ **Phone number input** (pre-filled with test number)
✅ **Amount input** (pre-filled with 1 KES)
✅ **Provider selection** (Kenya, Tanzania, etc.)
✅ **Real-time status updates**
✅ **Automatic payment polling**
✅ **Success/error messages**

### Testing Steps

1. **Open test page** in your browser
2. **Enter details:**
   - Phone: `254708374149` (test number)
   - Amount: `1` KES
   - Email: `test@example.com`
3. **Click "Pay with M-Pesa"**
4. **Check console** for API responses
5. **Watch status messages** for updates

### Expected Flow

```
1. Click "Pay with M-Pesa"
   ↓
2. API call to /api/v1/payments/initiate/
   ↓
3. STK Push sent to phone
   ↓
4. User receives prompt on phone
   ↓
5. User enters PIN
   ↓
6. Payment processed (10-60 seconds)
   ↓
7. Webhook sent to your backend
   ↓
8. Transaction marked successful
   ↓
9. Frontend shows success message
```

### Manual API Test

If you prefer testing via curl:

```bash
# 1. Initiate payment
curl -X POST http://localhost:7001/api/v1/payments/initiate/ \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "mpesa",
    "amount": 1,
    "currency": "KES",
    "country": "KE",
    "phone_number": "254708374149",
    "metadata": {
      "email": "test@example.com"
    }
  }'

# 2. Check transaction status (replace TRANSACTION_ID)
curl http://localhost:7001/api/v1/payments/verify/TRANSACTION_ID/
```

---

## Step 3: 📋 Production Credentials Setup

### Current Status

**Environment:** Sandbox ✅
**Sandbox Credentials:** Working ✅
**Production Credentials:** Need to obtain

---

### How to Get Production Credentials

#### 1. Visit Safaricom Daraja Portal

**URL:** https://developer.safaricom.co.ke/

#### 2. Requirements for Production

Before applying for production credentials, ensure you have:

- ✅ **Business Registration** (Certificate of Incorporation)
- ✅ **KRA PIN Certificate**
- ✅ **Company ID/Passport**
- ✅ **M-Pesa Buy Goods/Paybill Number** (or apply for one)
- ✅ **Company Bank Account Details**

#### 3. Application Process

**Step 1: Login to Daraja Portal**
```
https://developer.safaricom.co.ke/
→ Click "Login"
→ Use your sandbox account credentials
```

**Step 2: Create Production App**
```
Dashboard → My Apps → Create New App
→ App Name: "Hosi Academy LMS Production"
→ App Type: "Production"
→ API: Select "M-Pesa Express API"
→ Submit
```

**Step 3: Submit Documents**
- Upload business registration documents
- Upload KRA PIN certificate
- Upload authorized person's ID
- Provide Paybill/Till number

**Step 4: Wait for Approval**
- Typical approval time: **2-5 business days**
- Safaricom will review your application
- You'll receive email confirmation

**Step 5: Get Production Credentials**
Once approved:
- Login to Daraja Portal
- Go to "My Apps"
- Select your production app
- Copy credentials:
  - **Consumer Key** (production)
  - **Consumer Secret** (production)

---

### Update Configuration for Production

Once you receive production credentials:

#### 1. Update `.env` File

```bash
# Change from sandbox to production
MPESA_SANDBOX=False
MPESA_ENVIRONMENT=production

# Replace with your production credentials
MPESA_CONSUMER_KEY=your_production_consumer_key_here
MPESA_CONSUMER_SECRET=your_production_consumer_secret_here

# Keep the same shortcode and passkey
MPESA_BUSINESS_SHORTCODE=your_paybill_number
MPESA_PASSKEY=your_production_passkey

# Ensure callback URL uses HTTPS
MPESA_CALLBACK_URL=https://hosiacademy.com/api/v1/payments/webhooks/mpesa/
```

#### 2. Restart Backend

```bash
cd /home/tk/lms-prod
docker-compose restart backend
```

#### 3. Test with Small Amount

```bash
# Use the test script with real phone number
/home/tk/lms-prod/test_mpesa_simple.sh

# Or test manually with small amount (10 KES)
curl -X POST http://localhost:7001/api/v1/payments/initiate/ \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "mpesa",
    "amount": 10,
    "currency": "KES",
    "country": "KE",
    "phone_number": "2547XXXXXXXX",
    "metadata": {"email": "real@test.com"}
  }'
```

#### 4. Monitor First Transactions

```bash
# Watch logs
docker-compose logs -f backend | grep -i mpesa

# Check transactions in Django admin
# Visit: https://hosiacademy.com/admin/
# → Payments → Payment Transactions
```

---

## Production Checklist

### Before Going Live

- [ ] **SSL Certificate** installed on hosiacademy.com
- [ ] **Production credentials** obtained from Safaricom
- [ ] **`.env` updated** with `MPESA_SANDBOX=False`
- [ ] **Callback URL** uses HTTPS
- [ ] **Test transaction** completed successfully (10-50 KES)
- [ ] **Webhook logging** verified
- [ ] **Django admin** shows transactions
- [ ] **Error monitoring** configured (Sentry)
- [ ] **Support team** trained on M-Pesa payments

### After Going Live

- [ ] **Monitor** first 100 transactions
- [ ] **Track** success rate (target: >95%)
- [ ] **Review** webhook delivery (target: >99%)
- [ ] **Check** average transaction time (target: <60s)
- [ ] **Document** any issues and resolutions

---

## Multi-Country Production Setup

### For Other Countries (Tanzania, Mozambique, etc.)

Repeat the same process for each country:

#### Tanzania (Vodacom)
- Portal: https://developer.vodacom.co.tz/
- Credentials: `VODACOM_MPESA_TZ_*`

#### Mozambique (Vodacom)
- Portal: https://developer.vodacom.co.mz/
- Credentials: `VODACOM_MPESA_MZ_*`

#### Egypt (Vodafone)
- Portal: https://developer.vodafone.com.eg/
- Credentials: `VODAFONE_CASH_*`

---

## Troubleshooting

### Webhook Not Received

1. **Check callback URL is accessible:**
   ```bash
   curl -X POST https://hosiacademy.com/api/v1/payments/webhooks/mpesa/ \
     -H "Content-Type: application/json" \
     -d '{"test": true}'
   ```

2. **Verify SSL certificate:**
   ```bash
   curl -I https://hosiacademy.com
   ```

3. **Check nginx logs:**
   ```bash
   docker-compose logs nginx | grep webhook
   ```

### Payment Failed

1. **Check credentials:**
   ```bash
   docker-compose exec backend python manage.py shell
   >>> from django.conf import settings
   >>> print(settings.MPESA_CONSUMER_KEY)
   ```

2. **Verify phone number format:**
   - Must start with `254` (not `0` or `+`)
   - Example: `254712345678`

3. **Check Safaricom status:**
   - Visit: https://developer.safaricom.co.ke/status

---

## Success Metrics

### Monitor These KPIs

| Metric | Target | How to Track |
|--------|--------|--------------|
| Payment Success Rate | >95% | Django admin |
| Avg Transaction Time | <60s | Logs |
| Webhook Delivery | >99% | PaymentWebhookLog |
| Failed Payment Recovery | >80% | Manual follow-up |
| Customer Support Tickets | <2% | Support system |

---

## Support Contacts

### Safaricom (Kenya)
- **Portal:** https://developer.safaricom.co.ke/
- **Email:** api_support@safaricom.co.ke
- **Phone:** +254 722 004 311

### Vodacom (Tanzania)
- **Portal:** https://developer.vodacom.co.tz/
- **Email:** developer@vodacom.co.tz

### Vodacom (Mozambique)
- **Portal:** https://developer.vodacom.co.mz/
- **Email:** developer@vodacom.co.mz

### Vodafone (Egypt)
- **Portal:** https://developer.vodafone.com.eg/
- **Email:** developer@vodafone.com.eg

---

## Quick Reference

### Test Script
```bash
/home/tk/lms-prod/test_mpesa_simple.sh
```

### Frontend Test Page
```bash
firefox /home/tk/lms-prod/mpesa_test_page.html
```

### View Logs
```bash
docker-compose logs -f backend | grep -i mpesa
```

### Check Transactions
```
https://hosiacademy.com/admin/
→ Payments → Payment Transactions
```

### Production Credentials Location
```bash
# In .env file:
MPESA_CONSUMER_KEY=xxx
MPESA_CONSUMER_SECRET=xxx
```

---

## 🎉 You're Ready!

**Status:**
- ✅ Webhook configured
- ✅ Frontend test page ready
- ⏳ Production credentials (pending application)

**Next Actions:**
1. Test with frontend test page
2. Apply for production credentials
3. Test with real transactions
4. Launch to users!

---

**Last Updated:** March 16, 2026
**Status:** 🚀 Ready for Production Deployment
