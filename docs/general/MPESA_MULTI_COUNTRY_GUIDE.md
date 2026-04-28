# M-Pesa Multi-Country Integration Guide

## Overview

Your LMS now supports M-Pesa and M-Pesa-like mobile money services across **7 African countries**:

| Country | Provider | Adapter | Currency | Status |
|---------|----------|---------|----------|--------|
| 🇰🇪 Kenya | Safaricom M-Pesa | `MpesaAdapter` | KES | ✅ Active |
| 🇹🇿 Tanzania | Vodacom M-Pesa | `VodacomMpesaAdapter` | TZS | ✅ Active |
| 🇲🇿 Mozambique | Vodacom M-Pesa | `VodacomMpesaAdapter` | MZN | ✅ Active |
| 🇨🇩 DRC | Vodacom M-Pesa | `VodacomMpesaAdapter` | USD/CDF | ✅ Active |
| 🇱🇸 Lesotho | Vodacom M-Pesa | `VodacomMpesaAdapter` | LSL/ZAR | ✅ Active |
| 🇪🇬 Egypt | Vodafone Cash | `VodafoneCashAdapter` | EGP | ✅ Active |

---

## 1. Architecture

### Adapter Structure

```
backend/apps/payments/adapters/
├── mpesa.py              # Kenya (Safaricom)
├── vodacom_mpesa.py      # Tanzania, Mozambique, DRC, Lesotho
├── vodafone_cash.py      # Egypt
└── base.py               # Base adapter class
```

### Provider Codes

```python
# Use these provider codes in API calls
'mpesa'          # Kenya
'vodacom_mpesa'  # Tanzania, Mozambique, DRC, Lesotho
'vodafone_cash'  # Egypt
```

---

## 2. Configuration

### Kenya (Safaricom M-Pesa)

**File:** `backend/.env`

```bash
# Safaricom M-Pesa (Kenya)
MPESA_ENVIRONMENT=sandbox
MPESA_CONSUMER_KEY=your_consumer_key
MPESA_CONSUMER_SECRET=your_consumer_secret
MPESA_BUSINESS_SHORTCODE=174379
MPESA_PASSKEY=bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919
MPESA_INITIATOR_NAME=testapi
MPESA_SECURITY_CREDENTIAL=your_security_credential
MPESA_CALLBACK_URL=https://hosiacademy.com/api/payments/webhooks/mpesa/
```

**Get Credentials:** https://developer.safaricom.co.ke/

---

### Tanzania (Vodacom M-Pesa)

```bash
# Vodacom M-Pesa Tanzania
VODACOM_MPESA_SANDBOX=True
VODACOM_MPESA_TZ_CONSUMER_KEY=your_tanzania_consumer_key
VODACOM_MPESA_TZ_CONSUMER_SECRET=your_tanzania_consumer_secret
VODACOM_MPESA_TZ_SHORTCODE=174379
VODACOM_MPESA_TZ_PASSKEY=your_tanzania_passkey
VODACOM_MPESA_TZ_INITIATOR_NAME=testapi
VODACOM_MPESA_TZ_SECURITY_CREDENTIAL=your_security_credential
VODACOM_MPESA_TZ_CALLBACK_URL=https://hosiacademy.com/api/payments/webhooks/vodacom_mpesa/
```

**Get Credentials:** https://developer.vodacom.co.tz/

---

### Mozambique (Vodacom M-Pesa)

```bash
# Vodacom M-Pesa Mozambique
VODACOM_MPESA_MZ_CONSUMER_KEY=your_mozambique_consumer_key
VODACOM_MPESA_MZ_CONSUMER_SECRET=your_mozambique_consumer_secret
VODACOM_MPESA_MZ_SHORTCODE=174379
VODACOM_MPESA_MZ_PASSKEY=your_mozambique_passkey
VODACOM_MPESA_MZ_CALLBACK_URL=https://hosiacademy.com/api/payments/webhooks/vodacom_mpesa/
```

**Get Credentials:** https://developer.vodacom.co.mz/

---

### DRC (Vodacom M-Pesa)

```bash
# Vodacom M-Pesa DRC
VODACOM_MPESA_CD_CONSUMER_KEY=your_drc_consumer_key
VODACOM_MPESA_CD_CONSUMER_SECRET=your_drc_consumer_secret
VODACOM_MPESA_CD_SHORTCODE=174379
VODACOM_MPESA_CD_PASSKEY=your_drc_passkey
VODACOM_MPESA_CD_CALLBACK_URL=https://hosiacademy.com/api/payments/webhooks/vodacom_mpesa/
```

**Get Credentials:** https://developer.vodacom.cd/

---

### Lesotho (Vodacom M-Pesa)

```bash
# Vodacom M-Pesa Lesotho
VODACOM_MPESA_LS_CONSUMER_KEY=your_lesotho_consumer_key
VODACOM_MPESA_LS_CONSUMER_SECRET=your_lesotho_consumer_secret
VODACOM_MPESA_LS_SHORTCODE=174379
VODACOM_MPESA_LS_PASSKEY=your_lesotho_passkey
VODACOM_MPESA_LS_CALLBACK_URL=https://hosiacademy.com/api/payments/webhooks/vodacom_mpesa/
```

**Get Credentials:** https://developer.vodacom.co.ls/

---

### Egypt (Vodafone Cash)

```bash
# Vodafone Cash Egypt
VODAFONE_CASH_SANDBOX=True
VODAFONE_CASH_CLIENT_ID=your_egypt_client_id
VODAFONE_CASH_CLIENT_SECRET=your_egypt_client_secret
VODAFONE_CASH_MERCHANT_ID=your_egypt_merchant_id
VODAFONE_CASH_CALLBACK_URL=https://hosiacademy.com/api/payments/webhooks/vodafone_cash/
```

**Get Credentials:** https://developer.vodafone.com.eg/

---

## 3. API Usage

### 3.1 Get Available Providers by Country

```bash
# Kenya
GET /api/payments/providers/?country=KE&currency=KES

# Tanzania
GET /api/payments/providers/?country=TZ&currency=TZS

# Mozambique
GET /api/payments/providers/?country=MZ&currency=MZN

# DRC
GET /api/payments/providers/?country=CD&currency=USD

# Lesotho
GET /api/payments/providers/?country=LS&currency=LSL

# Egypt
GET /api/payments/providers/?country=EG&currency=EGP
```

**Response Example (Kenya):**
```json
{
  "detected_country": "KE",
  "detected_currency": "KES",
  "available_providers": [
    {
      "code": "mpesa",
      "name": "M-Pesa",
      "supported": true,
      "requires_phone": true,
      "methods": ["stk_push", "paybill", "till_number"]
    }
  ]
}
```

---

### 3.2 Initiate Payment

**Endpoint:** `POST /api/payments/initiate/`

#### Kenya Example

```json
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

#### Tanzania Example

```json
{
  "provider": "vodacom_mpesa",
  "amount": 25000,
  "currency": "TZS",
  "country": "TZ",
  "phone_number": "255712345678",
  "metadata": {
    "email": "user@example.com"
  }
}
```

#### Egypt Example

```json
{
  "provider": "vodafone_cash",
  "amount": 500,
  "currency": "EGP",
  "country": "EG",
  "phone_number": "201234567890",
  "metadata": {
    "email": "user@example.com"
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

### 3.3 Webhook Endpoints

```
# Kenya
POST /api/payments/webhooks/mpesa/

# Tanzania, Mozambique, DRC, Lesotho
POST /api/payments/webhooks/vodacom_mpesa/

# Egypt
POST /api/payments/webhooks/vodafone_cash/
```

---

## 4. Phone Number Formatting

Each country has specific phone number formats:

| Country | Format | Example |
|---------|--------|---------|
| Kenya | 2547XXXXXXXX | 254712345678 |
| Tanzania | 2557XXXXXXXX | 255712345678 |
| Mozambique | 2588XXXXXXXX | 258841234567 |
| DRC | 2438XXXXXXXX | 243812345678 |
| Lesotho | 266XXXXXXXX | 26651234567 |
| Egypt | 201XXXXXXXXX | 201234567890 |

The adapters automatically format phone numbers, so you can send:
- `+254712345678`
- `254712345678`
- `0712345678` (local format)

All will be converted to the correct international format.

---

## 5. Currency Support

| Provider | Currencies |
|----------|------------|
| M-Pesa Kenya | KES, USD |
| Vodacom M-Pesa TZ | TZS, USD |
| Vodacom M-Pesa MZ | MZN, USD |
| Vodacom M-Pesa CD | USD, CDF |
| Vodacom M-Pesa LS | LSL, ZAR, USD |
| Vodafone Cash EG | EGP |

---

## 6. Testing

### Sandbox Test Numbers

#### Kenya (Safaricom)
- Phone: `254708374149`
- PIN: Sent via SMS

#### Tanzania (Vodacom)
- Phone: `255711111111` (sandbox)
- PIN: `1234` (test)

#### Mozambique (Vodacom)
- Phone: `258841111111` (sandbox)
- PIN: `1234` (test)

#### Egypt (Vodafone)
- Phone: `201000000000` (sandbox)
- PIN: `1234` (test)

---

### Run Test Script

```bash
cd /home/tk/lms-prod
python test_comprehensive_payment_sandbox.py
```

---

## 7. Country-Specific Features

### Kenya (Safaricom M-Pesa)

**Features:**
- ✅ STK Push (Lipa Na M-Pesa)
- ✅ Paybill
- ✅ Till Number
- ✅ B2C Payments
- ✅ Transaction Reversal

**Limits:**
- Min: 10 KES
- Max: 150,000 KES per transaction
- Max: 300,000 KES per day

---

### Tanzania (Vodacom M-Pesa)

**Features:**
- ✅ STK Push
- ✅ Paybill
- ✅ Till Number
- ✅ Transaction Reversal

**Limits:**
- Min: 100 TZS
- Max: 5,000,000 TZS per transaction

---

### Mozambique (Vodacom M-Pesa)

**Features:**
- ✅ STK Push
- ✅ Paybill
- ✅ Transaction Reversal

**Limits:**
- Min: 50 MZN
- Max: 500,000 MZN per transaction

---

### DRC (Vodacom M-Pesa)

**Features:**
- ✅ STK Push
- ✅ Paybill

**Limits:**
- Min: 1 USD
- Max: 5,000 USD per transaction

**Note:** Limited availability in DRC

---

### Lesotho (Vodacom M-Pesa)

**Features:**
- ✅ STK Push
- ✅ Paybill
- ✅ Cross-border ZAR support

**Limits:**
- Min: 10 LSL
- Max: 50,000 LSL per transaction

---

### Egypt (Vodafone Cash)

**Features:**
- ✅ Wallet Payment
- ✅ STK Push
- ✅ QR Code Payments
- ✅ Transaction Reversal

**Limits:**
- Min: 1 EGP
- Max: 10,000 EGP per transaction

---

## 8. Webhook Payloads

### Kenya (Safaricom)

```json
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

### Tanzania/Mozambique/DRC/Lesotho (Vodacom)

```json
{
  "Body": {
    "stkCallback": {
      "MerchantRequestID": "12345",
      "CheckoutRequestID": "ws_CO_123456789",
      "ResultCode": 0,
      "ResultDesc": "The service request is processed successfully.",
      "CallbackMetadata": {
        "Item": [
          {"Name": "Amount", "Value": 25000},
          {"Name": "MpesaReceiptNumber", "Value": "VOD123456789"},
          {"Name": "TransactionDate", "Value": 20260316120000},
          {"Name": "PhoneNumber", "Value": "255712345678"}
        ]
      }
    }
  }
}
```

### Egypt (Vodafone Cash)

```json
{
  "transactionId": "VOD_123456789",
  "merchantReference": "ENR-ABC123",
  "status": "success",
  "responseCode": "0",
  "message": "Payment successful",
  "amount": 500,
  "currency": "EGP",
  "phoneNumber": "201234567890",
  "timestamp": "2026-03-16T12:00:00Z"
}
```

---

## 9. Error Codes

### Common Result Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success | Payment completed |
| 1001 | Insufficient funds | Ask customer to try different payment method |
| 1002 | Invalid phone number | Validate phone number format |
| 1003 | Network timeout | Retry or ask customer to try again |
| 1032 | User cancelled | Customer cancelled STK push |
| 1037 | Duplicate transaction | Already processed, ignore |

---

## 10. Production Checklist

### For Each Country

- [ ] Register business with local Vodacom/Safaricom/Vodafone
- [ ] Obtain production API credentials
- [ ] Configure production callback URLs (HTTPS required)
- [ ] Set `*_SANDBOX=False` in `.env`
- [ ] Test with small real transactions
- [ ] Configure webhook logging and monitoring
- [ ] Set up alerts for failed payments
- [ ] Document local support contacts

### Kenya Specific
- [ ] Have valid Paybill/Till number
- [ ] Configure initiator credentials for B2C
- [ ] Test with Safaricom production environment

### Tanzania/Mozambique/DRC/Lesotho Specific
- [ ] Register with Vodacom business portal
- [ ] Configure country-specific shortcodes
- [ ] Test cross-border transactions (Lesotho)

### Egypt Specific
- [ ] Register with Vodafone Egypt business
- [ ] Configure merchant ID
- [ ] Test Arabic language support (if needed)

---

## 11. Troubleshooting

### "Invalid access token"
- Check consumer key/secret for correct country
- Ensure sandbox/production mode matches credentials

### "Callback URL not reachable"
- Verify HTTPS is configured
- Check firewall allows incoming connections
- Test webhook endpoint manually

### "Transaction not found"
- Check CheckoutRequestID matches metadata
- Verify webhook is using correct provider code

### Country-specific issues
- **Kenya:** Ensure Safaricom sandbox credentials are active
- **Tanzania:** Vodacom TZ may have different API endpoints
- **Mozambique:** Check MZN currency conversion
- **DRC:** Limited coverage, verify service availability
- **Lesotho:** Cross-border ZAR transactions may have delays
- **Egypt:** Vodafone Cash requires additional merchant verification

---

## 12. Files Reference

| File | Purpose |
|------|---------|
| `backend/apps/payments/adapters/mpesa.py` | Kenya M-Pesa adapter |
| `backend/apps/payments/adapters/vodacom_mpesa.py` | Tanzania, Mozambique, DRC, Lesotho adapter |
| `backend/apps/payments/adapters/vodafone_cash.py` | Egypt adapter |
| `backend/apps/payments/adapters/__init__.py` | Adapter registry |
| `backend/apps/payments/views/payment_views.py` | Payment initiation |
| `backend/apps/payments/views/webhook_views.py` | Webhook handler |
| `backend/.env` | Configuration |

---

## 13. Getting Credentials Summary

| Country | Portal | Time to Approval |
|---------|--------|------------------|
| Kenya | https://developer.safaricom.co.ke/ | Immediate (sandbox) |
| Tanzania | https://developer.vodacom.co.tz/ | 1-3 days |
| Mozambique | https://developer.vodacom.co.mz/ | 1-3 days |
| DRC | https://developer.vodacom.cd/ | 3-5 days |
| Lesotho | https://developer.vodacom.co.ls/ | 1-3 days |
| Egypt | https://developer.vodafone.com.eg/ | 2-5 days |

---

## Next Steps

1. **Choose target countries** for launch
2. **Register on developer portals** for each country
3. **Obtain sandbox credentials** for testing
4. **Test payment flow** in each country
5. **Apply for production credentials**
6. **Configure local payment methods** (Paybill numbers, etc.)
7. **Launch country by country**

---

## Support

For technical issues with the integration:
- Check logs: `docker-compose logs -f backend`
- Test webhooks: `python test_comprehensive_payment_sandbox.py`
- Review adapter code in `backend/apps/payments/adapters/`

For business/credential issues:
- Contact local Safaricom/Vodacom/Vodafone business support
- Email: api_support@safaricom.co.ke (Kenya)
- Email: developer@vodacom.co.tz (Tanzania)
