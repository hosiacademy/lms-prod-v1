# M-Pesa Multi-Country Quick Reference

## 🌍 Countries at a Glance

```
┌──────────────┬─────────────────┬───────────────┬──────────┬──────────────────────────┐
│ Country      │ Provider        │ Code          │ Currency │ Portal                   │
├──────────────┼─────────────────┼───────────────┼──────────┼──────────────────────────┤
│ Kenya 🇰🇪     │ Safaricom M-Pesa│ mpesa         │ KES      │ developer.safaricom.co.ke│
│ Tanzania 🇹🇿  │ Vodacom M-Pesa  │ vodacom_mpesa │ TZS      │ developer.vodacom.co.tz  │
│ Mozambique 🇲🇿│ Vodacom M-Pesa  │ vodacom_mpesa │ MZN      │ developer.vodacom.co.mz  │
│ DRC 🇨🇩       │ Vodacom M-Pesa  │ vodacom_mpesa │ USD/CDF  │ developer.vodacom.cd     │
│ Lesotho 🇱🇸   │ Vodacom M-Pesa  │ vodacom_mpesa │ LSL/ZAR  │ developer.vodacom.co.ls  │
│ Egypt 🇪🇬     │ Vodafone Cash   │ vodafone_cash │ EGP      │ developer.vodafone.com.eg│
└──────────────┴─────────────────┴───────────────┴──────────┴──────────────────────────┘
```

---

## 🔑 Environment Variables Template

```bash
# Kenya
MPESA_CONSUMER_KEY=your_key
MPESA_CONSUMER_SECRET=your_secret
MPESA_BUSINESS_SHORTCODE=174379
MPESA_PASSKEY=bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919
MPESA_CALLBACK_URL=https://yourdomain.com/api/payments/webhooks/mpesa/

# Tanzania
VODACOM_MPESA_TZ_CONSUMER_KEY=your_key
VODACOM_MPESA_TZ_CONSUMER_SECRET=your_secret
VODACOM_MPESA_TZ_SHORTCODE=174379
VODACOM_MPESA_TZ_PASSKEY=your_passkey
VODACOM_MPESA_TZ_CALLBACK_URL=https://yourdomain.com/api/payments/webhooks/vodacom_mpesa/

# Mozambique
VODACOM_MPESA_MZ_CONSUMER_KEY=your_key
VODACOM_MPESA_MZ_CONSUMER_SECRET=your_secret
VODACOM_MPESA_MZ_SHORTCODE=174379
VODACOM_MPESA_MZ_PASSKEY=your_passkey
VODACOM_MPESA_MZ_CALLBACK_URL=https://yourdomain.com/api/payments/webhooks/vodacom_mpesa/

# DRC
VODACOM_MPESA_CD_CONSUMER_KEY=your_key
VODACOM_MPESA_CD_CONSUMER_SECRET=your_secret
VODACOM_MPESA_CD_SHORTCODE=174379
VODACOM_MPESA_CD_PASSKEY=your_passkey
VODACOM_MPESA_CD_CALLBACK_URL=https://yourdomain.com/api/payments/webhooks/vodacom_mpesa/

# Lesotho
VODACOM_MPESA_LS_CONSUMER_KEY=your_key
VODACOM_MPESA_LS_CONSUMER_SECRET=your_secret
VODACOM_MPESA_LS_SHORTCODE=174379
VODACOM_MPESA_LS_PASSKEY=your_passkey
VODACOM_MPESA_LS_CALLBACK_URL=https://yourdomain.com/api/payments/webhooks/vodacom_mpesa/

# Egypt
VODAFONE_CASH_CLIENT_ID=your_id
VODAFONE_CASH_CLIENT_SECRET=your_secret
VODAFONE_CASH_MERCHANT_ID=your_merchant_id
VODAFONE_CASH_CALLBACK_URL=https://yourdomain.com/api/payments/webhooks/vodafone_cash/
```

---

## 📱 Phone Number Formats

| Country | Format | Example Input | Auto-Converted To |
|---------|--------|---------------|-------------------|
| Kenya | 2547XXXXXXXX | `0712345678` | `254712345678` |
| Tanzania | 2557XXXXXXXX | `0712345678` | `255712345678` |
| Mozambique | 2588XXXXXXXX | `841234567` | `258841234567` |
| DRC | 2438XXXXXXXX | `0812345678` | `243812345678` |
| Lesotho | 266XXXXXXXX | `51234567` | `26651234567` |
| Egypt | 201XXXXXXXXX | `01234567890` | `201234567890` |

**Note:** Adapters automatically format phone numbers correctly.

---

## 🧪 Test Credentials (Sandbox)

### Kenya
- **Phone:** `254708374149`
- **PIN:** Sent via SMS
- **Portal:** https://developer.safaricom.co.ke/

### Tanzania
- **Phone:** `255711111111`
- **PIN:** `1234`

### Mozambique
- **Phone:** `258841111111`
- **PIN:** `1234`

### DRC
- **Phone:** `243811111111`
- **PIN:** `1234`

### Lesotho
- **Phone:** `26651111111`
- **PIN:** `1234`

### Egypt
- **Phone:** `201000000000`
- **PIN:** `1234`

---

## 🔌 API Quick Start

### 1. Get Available Providers

```bash
curl "http://localhost:8000/api/payments/providers/?country=KE"
```

### 2. Initiate Payment

```bash
curl -X POST http://localhost:8000/api/payments/initiate/ \
  -H "Content-Type: application/json" \
  -d '{
    "provider": "vodacom_mpesa",
    "amount": 25000,
    "currency": "TZS",
    "country": "TZ",
    "phone_number": "255712345678",
    "metadata": {"email": "user@example.com"}
  }'
```

### 3. Simulate Webhook (Sandbox)

```bash
curl -X POST http://localhost:8000/api/payments/webhooks/vodacom_mpesa/ \
  -H "Content-Type: application/json" \
  -d '{
    "Body": {
      "stkCallback": {
        "CheckoutRequestID": "ws_CO_123456789",
        "ResultCode": 0,
        "ResultDesc": "Success"
      }
    }
  }'
```

---

## 💰 Transaction Limits

| Country | Min | Max | Daily Max |
|---------|-----|-----|-----------|
| Kenya | 10 KES | 150,000 KES | 300,000 KES |
| Tanzania | 100 TZS | 5,000,000 TZS | 10,000,000 TZS |
| Mozambique | 50 MZN | 500,000 MZN | 1,000,000 MZN |
| DRC | 1 USD | 5,000 USD | 10,000 USD |
| Lesotho | 10 LSL | 50,000 LSL | 100,000 LSL |
| Egypt | 1 EGP | 10,000 EGP | 50,000 EGP |

---

## ⚠️ Error Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | ✅ Success | Payment completed |
| 1001 | ❌ Insufficient funds | Try different payment method |
| 1002 | ❌ Invalid phone | Validate phone format |
| 1003 | ⏱️ Timeout | Retry |
| 1032 | ❌ User cancelled | Customer cancelled STK |
| 1037 | ⚠️ Duplicate | Already processed |

---

## 📁 File Locations

```
backend/
├── .env                                    # Configuration
├── apps/payments/adapters/
│   ├── __init__.py                         # Adapter registry
│   ├── mpesa.py                            # Kenya
│   ├── vodacom_mpesa.py                    # TZ, MZ, CD, LS
│   └── vodafone_cash.py                    # Egypt
├── apps/payments/views/
│   ├── payment_views.py                    # Initiation
│   └── webhook_views.py                    # Webhooks
└── apps/payments/services/
    └── payment_service.py                  # Orchestration

Documentation/
├── MPESA_MULTI_COUNTRY_GUIDE.md            # Full guide
├── MPESA_PAYMENT_FLOW.md                   # Flow diagrams
├── MPESA_EXPANSION_SUMMARY.md              # Implementation summary
└── MPESA_QUICK_REFERENCE.md                # This file
```

---

## 🚀 Quick Deploy Checklist

For each country:

```
□ 1. Register on developer portal
□ 2. Obtain sandbox credentials
□ 3. Update backend/.env
□ 4. Set *_SANDBOX=True
□ 5. Test with sandbox phone numbers
□ 6. Verify webhook callbacks
□ 7. Obtain production credentials
□ 8. Set *_SANDBOX=False
□ 9. Update callback URLs to HTTPS
□ 10. Test production transaction
□ 11. Monitor for 24 hours
□ 12. Launch to users
```

---

## 🆘 Quick Troubleshooting

```bash
# Check if adapter is loaded
docker-compose exec backend python manage.py shell
>>> from apps.payments.adapters import get_adapter
>>> adapter = get_adapter('vodacom_mpesa')
>>> adapter.get_supported_countries()
['TZ', 'MZ', 'CD', 'LS']

# View recent webhooks
>>> from apps.payments.models import PaymentWebhookLog
>>> PaymentWebhookLog.objects.filter(provider='vodacom_mpesa').count()

# Test callback URL
curl -X POST https://yourdomain.com/api/payments/webhooks/vodacom_mpesa/ \
  -H "Content-Type: application/json" \
  -d '{"test": true}'

# Check logs
docker-compose logs -f backend | grep -i mpesa
```

---

## 📞 Support Emails

| Country | Support Email |
|---------|---------------|
| Kenya | api_support@safaricom.co.ke |
| Tanzania | developer@vodacom.co.tz |
| Mozambique | developer@vodacom.co.mz |
| DRC | support@vodacom.cd |
| Lesotho | support@vodacom.co.ls |
| Egypt | developer@vodafone.com.eg |

---

## 📊 Success Metrics

Monitor these daily:

- ✅ **Payment Success Rate** > 95%
- ✅ **Webhook Delivery** > 99%
- ✅ **Avg Transaction Time** < 60s
- ✅ **Failed Payment Recovery** > 80%
- ✅ **Support Tickets** < 2%

---

**Last Updated:** March 16, 2026  
**Version:** 1.0  
**Status:** ✅ Production Ready
