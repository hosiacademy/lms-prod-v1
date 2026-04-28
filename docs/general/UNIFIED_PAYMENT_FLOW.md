# UNIFIED PAYMENT FLOW - COMPREHENSIVE GUIDE

**Date:** April 17, 2026  
**Status:** ✅ COMPLETE & PRODUCTION READY  
**Version:** 1.0

---

## TABLE OF CONTENTS

1. [Quick Start](#quick-start)
2. [Overview](#overview)
3. [Payment Gateway Policy](#payment-gateway-policy)
4. [Training Type Implementations](#training-type-implementations)
5. [API Endpoint Reference](#api-endpoint-reference)
6. [Backend Implementation](#backend-implementation)
7. [Deployment Guide](#deployment-guide)
8. [Testing & Verification](#testing--verification)
9. [Troubleshooting](#troubleshooting)
10. [FAQ](#faq)

---

## QUICK START

### What Changed?

✅ **SmatPay is now the EXCLUSIVE card payment gateway**
- All credit/debit card payments route through SmatPay
- Supported cards: Visa, Mastercard, ZimSwitch
- No other adapters (Flutterwave, Paystack) handle card payments

✅ **Unified Payment Flow for all 4 training types**
- Masterclass
- Learnership
- AI Certs Courses
- Custom Selection

All have the same 3 payment options:
- 💳 Card Payment (SmatPay) → Instant access
- 🏦 Bank Transfer (EFT) → 1-3 business days
- 💰 Cash at Office → Same day

✅ **New Payment Routing Service**
- Intelligently routes payments based on country and method
- Supports 6 African countries
- Validates payment methods per country

### API Endpoints Summary

```
GET    /api/v1/payments/methods/methods/                    → Available payment methods
POST   /api/v1/payments/methods/validate-method/            → Validate payment method
GET    /api/v1/payments/methods/routing/                    → Get routing information
GET    /api/v1/payments/methods/country-config/             → Get country configuration
GET    /api/v1/payments/methods/smatpay-info/              → Confirm SmatPay exclusivity
GET    /api/v1/payments/methods/methods-for-training/       → Methods for training type
GET    /api/v1/payments/methods/supported-countries/        → All supported countries
```

---

## OVERVIEW

### Core Features

**SmatPay Exclusivity for Cards**
- POLICY: All credit/debit card payments route exclusively through SmatPay
- Supported cards: Visa, Mastercard, ZimSwitch
- Optimized for Africa-specific transactions
- Lower failure rates, better fraud detection
- Dedicated Zimbabwe support

**Unified Payment Methods**
- All 4 training types use same payment flow
- Consistent payment experience
- Country-specific options

**Multi-Country Support**
- Zimbabwe (USD)
- South Africa (ZAR)
- Kenya (KES)
- Tanzania (TZS)
- Nigeria (NGN)
- Uganda (UGX)

---

## PAYMENT GATEWAY POLICY

### Card Payments: SmatPay ONLY

**ENFORCED ACROSS ALL COUNTRIES**

| Requirement | Status |
|------------|--------|
| All card payments go to SmatPay | ✅ Enforced |
| Flutterwave NO card payments | ✅ Verified |
| Paystack NO card payments | ✅ Verified |
| Stripe NO card payments | ✅ Verified |
| SmatPay is the only card provider | ✅ Verified |

**Implementation:**
- Routing validation in PaymentService
- Enforcement in InitiatePaymentView
- Security logging for violations
- Comprehensive error messages

### EFT / Bank Transfer Payments

**By Country:**

| Country | Provider | Method | Access Time |
|---------|----------|--------|-------------|
| Zimbabwe | Direct Transfer | Bank account transfer | 1-3 days |
| South Africa | PayFast | South African EFT/ACH | 1-3 days |
| Kenya | Direct Transfer | M-Pesa Business or bank | 1-3 days |
| Tanzania | Direct Transfer | Bank transfer | 1-3 days |
| Nigeria | Direct Transfer | Bank transfer | 1-3 days |
| Uganda | Direct Transfer | Bank transfer | 1-3 days |

### In-Store Cash Payments

**Office Locations:**
- **Zimbabwe:** Harare HQ (9AM-5PM MON-FRI)
- **South Africa:** Johannesburg Office (9AM-5PM MON-FRI)
- **Kenya:** Nairobi Office (9AM-5PM MON-FRI)
- Other countries: As available

**Process:**
1. Student selects "Pay Cash at Office"
2. Receives payment reference and office details
3. Visits office and pays cash
4. Receives receipt with reference number
5. Enrollment activated upon verification

---

## TRAINING TYPE IMPLEMENTATIONS

### 1. Masterclass

**Training Type Code:** `masterclass`

**Enrollment Flow:**
```
1. Student selects masterclass
2. Views payment options:
   - 💳 Card (Visa/Mastercard/ZimSwitch)
   - 🏦 Bank Transfer
   - 💰 Cash at Office
3. Selects payment method
4. Processes payment
5. Receives enrollment confirmation
6. Gets immediate access to materials
```

**Payment Processing:**
- Card → SmatPay → Instant confirmation
- EFT → Bank transfer → 1-3 business days
- Cash → Office receipt → Same day (upon payment)

**Access:**
- Card: Immediate (within minutes)
- EFT: After payment confirmation (1-3 days)
- Cash: After office staff verification (same day)

### 2. Learnership

**Training Type Code:** `learnership`

**Same unified flow as Masterclass**
- Same 3 payment options
- Same access times
- Same instant access with card

### 3. AI Certs Courses

**Training Type Code:** `aicerts_courses`

**Same unified flow as Masterclass**
- Same 3 payment options
- Same access times
- Same instant access with card

### 4. Custom Selection

**Training Type Code:** `custom_selection`

**Enrollment Flow:**
```
1. Student builds cart with multiple courses
2. Views total amount
3. Views payment options:
   - 💳 Card (SmatPay)
   - 🏦 Bank Transfer
   - 💰 Cash at Office
4. Selects payment method
5. Processes single payment for all courses
6. Receives enrollment confirmation
7. Gets access to all selected courses
```

**Key Features:**
- Single payment for entire cart
- Can use any payment method
- Future enhancement: Split payments (part card, part cash)

---

## API ENDPOINT REFERENCE

### Base URL
```
/api/v1/payments/methods/
```

### Endpoint 1: Get Available Payment Methods

**GET `/methods/`**

**Query Parameters:**
- `country` (required): ISO country code (e.g., 'ZW', 'ZA')
- `training_type` (optional): Training type code

**Example:**
```bash
GET /api/v1/payments/methods/methods/?country=ZW&training_type=masterclass
```

**Response:**
```json
{
  "country": "ZW",
  "training_type": "masterclass",
  "currency": "USD",
  "methods": [
    {
      "method": "card",
      "provider": "smatpay",
      "description": "💳 Visa, Mastercard, or ZimSwitch Card (SmatPay)",
      "card_types": ["Visa", "Mastercard", "ZimSwitch"],
      "enabled": true
    },
    {
      "method": "eft",
      "provider": "bank_transfer",
      "description": "🏦 Bank Transfer",
      "enabled": true
    },
    {
      "method": "cash",
      "provider": "on_site_payment",
      "description": "💰 Pay Cash at Office",
      "locations": [...],
      "enabled": true
    }
  ]
}
```

### Endpoint 2: Validate Payment Method

**POST `/validate-method/`**

**Request Body:**
```json
{
  "country": "ZW",
  "payment_method": "card",
  "training_type": "masterclass"
}
```

**Success Response (200):**
```json
{
  "valid": true,
  "country": "ZW",
  "payment_method": "card",
  "provider": "smatpay",
  "training_type": "masterclass"
}
```

**Error Response (400):**
```json
{
  "valid": false,
  "error": "Payment method 'bitcoin' not available for ZW",
  "country": "ZW",
  "payment_method": "bitcoin"
}
```

### Endpoint 3: Get Payment Routing Info

**GET `/routing/`**

**Query Parameters:**
- `country` (required): ISO country code
- `method` (required): Payment method (card, eft, cash)

**Example:**
```bash
GET /api/v1/payments/methods/routing/?country=ZW&method=card
```

**Response:**
```json
{
  "country": "ZW",
  "method": "card",
  "provider": "smatpay",
  "provider_config": {...},
  "country_currency": "USD"
}
```

### Endpoint 4: Get Country Configuration

**GET `/country-config/`**

**Query Parameters:**
- `country` (required): ISO country code

**Response:**
```json
{
  "country": "ZW",
  "country_name": "Zimbabwe",
  "currency": "USD",
  "payment_methods": {
    "card": {...},
    "eft": {...},
    "cash": {...}
  }
}
```

### Endpoint 5: Get SmatPay Card Gateway Info

**GET `/smatpay-info/`**

**Confirms SmatPay is the exclusive card provider**

**Response:**
```json
{
  "country": "ZW",
  "card_provider": "smatpay",
  "is_exclusive": true,
  "card_types": ["Visa", "Mastercard", "ZimSwitch"],
  "enabled": true
}
```

### Endpoint 6: Get Methods for Training Type

**GET `/methods-for-training/`**

**Returns payment methods specific to training type**

### Endpoint 7: Get All Supported Countries

**GET `/supported-countries/`**

**Returns list of all 6 supported countries with currencies**

---

## BACKEND IMPLEMENTATION

### Files Created

#### 1. PaymentRoutingService (`payment_routing_service.py`)
- Core routing engine
- 7 public methods
- Country-specific configuration
- Training type support

**Key Methods:**
```python
PaymentRoutingService.get_available_payment_methods(country, training_type)
PaymentRoutingService.validate_payment_method(country, method, training_type)
PaymentRoutingService.get_payment_provider(country, method)
PaymentRoutingService.get_country_config(country)
```

#### 2. Payment Methods API (`payment_methods_views.py`)
- 5 API view classes
- 2 convenience functions
- Comprehensive error handling

#### 3. Payment Methods URLs (`payment_methods_urls.py`)
- 7 URL endpoints configured
- RESTful structure

#### 4. Tests (`test_payment_routing.py`)
- 28 comprehensive test cases
- SmatPay exclusivity tests
- Country configuration tests
- Training type flow tests

### Files Modified

#### 1. PaymentService (`payment_service.py`)
- Added `validate_payment_routing()` method
- Routing validation before payment initiation
- SmatPay exclusivity enforcement

#### 2. PaymentView (`payment_views.py`)
- Added routing validation checks
- SmatPay exclusivity enforcement
- Detailed error messages

#### 3. Adapter Registry (`adapters/__init__.py`)
- SmatPay marked as exclusive card provider
- Updated documentation
- Deprecated card handling in other adapters

#### 4. Main URLs (`urls.py`)
- Connected payment methods endpoints

---

## DEPLOYMENT GUIDE

### Phase 1: Code Deployment

#### 1.1 Pull Code
```bash
cd /home/takawira/lms-prod
git pull origin main
```

#### 1.2 Install Dependencies
```bash
cd backend
pip install -r requirements.txt
```

#### 1.3 Run Migrations
```bash
python manage.py migrate
```

#### 1.4 Collect Static Files
```bash
python manage.py collectstatic --noinput
```

#### 1.5 Verify Configuration
```bash
python manage.py shell
>>> from django.conf import settings
>>> print(settings.SMATPAY_MERCHANT_ID)
>>> print(settings.SMATPAY_MERCHANT_API_KEY)
```

### Phase 2: Testing

#### 2.1 Run Tests
```bash
python manage.py test apps.payments.tests.test_payment_routing -v 2
```

**Expected: All 28 tests pass**

#### 2.2 Test API Endpoints
```bash
# Test 1: Get methods
curl -X GET "http://localhost:8000/api/v1/payments/methods/methods/?country=ZW"

# Test 2: Validate method
curl -X POST "http://localhost:8000/api/v1/payments/methods/validate-method/" \
  -H "Content-Type: application/json" \
  -d '{"country":"ZW","payment_method":"card"}'

# Test 3: SmatPay info
curl -X GET "http://localhost:8000/api/v1/payments/methods/smatpay-info/?country=ZW"
```

### Phase 3: Frontend Integration

Frontend team should:
1. Update payment selection UI for all 4 training types
2. Call API endpoints to get available payment methods
3. Display country-specific options
4. Implement error handling
5. Test all flows end-to-end

### Phase 4: Monitoring

**Monitor these metrics:**
- Payment method selection distribution
- SmatPay card payment success rate
- EFT payment volume
- Cash payment volume
- Routing validation errors

**Set alerts for:**
- SmatPay success rate < 95%
- Card payment attempts to non-SmatPay providers > 5/hour
- Payment method validation failures > 10/hour

### Phase 5: Rollback Plan

If issues occur:
```bash
# Code rollback
git revert HEAD
git push origin main
systemctl restart gunicorn

# Database rollback (if migrations applied)
python manage.py migrate [previous_migration]
```

---

## TESTING & VERIFICATION

### Unit Tests
- 28 comprehensive test cases
- SmatPay exclusivity verified
- All country configurations tested
- API endpoint tests
- Error handling tests

### Integration Tests

**Test Card Payment:**
```
1. Go to Masterclass enrollment
2. Select Card Payment
3. Verify SmatPay shown (not Flutterwave)
4. Complete payment
5. Verify instant access
```

**Test EFT Payment:**
```
1. Go to Learnership enrollment
2. Select Bank Transfer
3. Verify bank details shown
4. Complete bank payment
```

**Test Cash Payment:**
```
1. Go to AI Certs enrollment
2. Select Cash at Office
3. Verify office location shown
4. Get payment reference
```

### Manual API Tests

```bash
# Test 1: Get methods
curl http://localhost:8000/api/v1/payments/methods/methods/?country=ZW

# Test 2: Validate
curl -X POST http://localhost:8000/api/v1/payments/methods/validate-method/ \
  -d '{"country":"ZW","payment_method":"card"}' \
  -H "Content-Type: application/json"

# Test 3: Verify exclusivity
curl http://localhost:8000/api/v1/payments/methods/smatpay-info/?country=ZW
```

---

## TROUBLESHOOTING

### Issue: Card payment shows Flutterwave instead of SmatPay

**Cause:** Frontend caching old payment options  
**Solution:** Clear browser cache, restart application

### Issue: API endpoint returns 404

**Cause:** URLs not properly registered  
**Solution:**
```bash
# Verify URLs included
grep -r "payment_methods_urls" backend/apps/payments/urls.py

# Restart server
systemctl restart gunicorn
```

### Issue: Payment method validation fails

**Cause:** Country not configured  
**Solution:**
```bash
python manage.py shell
>>> from apps.payments.services.payment_routing_service import COUNTRY_PAYMENT_CONFIG
>>> print(COUNTRY_PAYMENT_CONFIG.keys())
```

### Issue: SmatPay connection errors

**Cause:** Invalid API credentials  
**Solution:**
```bash
python manage.py shell
>>> from django.conf import settings
>>> print(f"Merchant ID: {settings.SMATPAY_MERCHANT_ID}")
>>> print(f"API Key: {settings.SMATPAY_MERCHANT_API_KEY[:10]}...")
```

---

## FAQ

**Q: Why SmatPay only for cards?**
A: SmatPay is optimized for African card transactions with lower failure rates and better fraud detection.

**Q: Can I use Flutterwave for card payments?**
A: No. Flutterwave is no longer used for card payments. Use SmatPay exclusively.

**Q: What if SmatPay is down?**
A: Customers should use EFT or cash payment methods. Card payment will show as unavailable.

**Q: Can students pay with multiple methods?**
A: Currently no. Future enhancement will support split payments.

**Q: How long does EFT take?**
A: 1-3 business days typically. Cash is same-day at office.

**Q: Which countries are supported?**
A: Zimbabwe, South Africa, Kenya, Tanzania, Nigeria, Uganda. Others can be added per configuration.

**Q: How do I add a new country?**
A: Edit `payment_routing_service.py` and add entry to `COUNTRY_PAYMENT_CONFIG`.

**Q: Are all 4 training types supported?**
A: Yes. Masterclass, Learnership, AI Certs Courses, and Custom Selection all use unified payment flow.

---

## IMPLEMENTATION STATISTICS

| Metric | Count |
|--------|-------|
| Backend Files Created | 4 |
| Backend Files Modified | 4 |
| Lines of Code | ~1,500 |
| API Endpoints | 7 |
| Test Cases | 28 |
| Countries Supported | 6 |
| Training Types | 4 |
| Payment Methods | 3 |

---

## SUPPORT

### Resources
- API Endpoint Reference: Above
- Backend Implementation: PaymentRoutingService class
- Tests: `apps.payments.tests.test_payment_routing`
- Configuration: `COUNTRY_PAYMENT_CONFIG` in routing service

### Contact
- Backend Issues: Backend team
- Frontend Integration: Frontend team
- DevOps/Deployment: DevOps team

---

## SUCCESS CRITERIA - ALL MET ✅

- [x] SmatPay is exclusive card provider
- [x] All 4 training types unified
- [x] 6 countries configured
- [x] 7 API endpoints created
- [x] 28 tests written
- [x] Security enforced
- [x] Documentation complete
- [x] Code quality high
- [x] Error handling comprehensive
- [x] Production ready

---

**Status:** ✅ **READY FOR PRODUCTION DEPLOYMENT**  
**Last Updated:** April 17, 2026  
**Version:** 1.0
