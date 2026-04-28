# 💳 CARD PAYMENT vs EFT/BANK TRANSFER - Enrollment Flow

**Date:** March 13, 2026  
**Context:** Payment methods in enrollment flow

---

## 📋 OVERVIEW

In the LMS payment system, **Card Payment** and **EFT/Bank Transfer** are two distinct payment methods that serve different student needs and payment preferences.

---

## 💳 CARD PAYMENT (payment_method='card')

### **What It Is:**

Card payment refers to **instant electronic payments** made using credit or debit cards through payment gateways. This is the most common and immediate payment method for online enrollments.

### **Supported Cards:**
- **Visa** (Credit/Debit)
- **Mastercard** (Credit/Debit)
- **American Express** (depending on provider)
- **Other local card schemes** (e.g., Verve in Nigeria)

### **How It Works:**

```
Student selects "Pay by Card"
    ↓
Enters card details (number, expiry, CVV)
    ↓
Payment gateway validates card
    ↓
3D Secure authentication (OTP/PIN)
    ↓
Instant authorization
    ↓
Payment confirmed immediately
    ↓
Enrollment activated instantly
```

### **Technical Implementation:**

**Model Definition:**
```python
class PaymentMethod(models.TextChoices):
    CARD = 'card', 'Credit/Debit Card'
```

**Payment Flow:**
1. Student selects card payment during enrollment
2. Frontend calls: `POST /api/v1/payments/initiate/`
   ```json
   {
     "program_id": 123,
     "amount": 5000,
     "currency": "ZAR",
     "payment_method": "card",
     "provider_code": "flutterwave" // or paystack, yoco, etc.
   }
   ```
3. Backend creates `PaymentTransaction` with `payment_method='card'`
4. Payment gateway returns checkout URL or card form
5. Student enters card details
6. Gateway processes payment instantly
7. Webhook confirms payment
8. Enrollment is confirmed

### **Payment Providers Supporting Card:**

| Provider | Countries | Card Types |
|----------|-----------|------------|
| **Flutterwave** | Pan-Africa | Visa, Mastercard, Verve |
| **Paystack** | Nigeria, Ghana, SA | Visa, Mastercard, Verve |
| **Yoco** | South Africa | Visa, Mastercard |
| **PayFast** | South Africa | Visa, Mastercard |
| **Stripe** | International | Visa, Mastercard, Amex |
| **Pesapal** | East Africa | Visa, Mastercard |

### **Characteristics:**

✅ **Instant Confirmation** - Payment verified in real-time  
✅ **Immediate Enrollment** - Student gets access immediately  
✅ **Automated** - No manual intervention required  
✅ **Secure** - PCI DSS compliant, 3D Secure authentication  
✅ **Refundable** - Can process refunds programmatically  
⚡ **Processing Time:** Immediate (seconds)  
💰 **Fees:** 2.5% - 3.5% + fixed fee per transaction  

### **Use Cases:**

- Students wanting **immediate access** to course materials
- **Last-minute enrollments** before class starts
- **International students** without local bank accounts
- **Corporate enrollments** with company credit cards
- **Installment payments** (if supported by provider)

---

## 🏦 EFT/BANK TRANSFER (payment_method='eft' or 'bank_transfer')

### **What It Is:**

EFT (Electronic Funds Transfer) or Bank Transfer is a **direct bank-to-bank payment** method where students transfer money from their bank account to the institution's account. This includes:
- **Traditional EFT** (1-3 business days)
- **Instant EFT** (real-time, country-dependent)
- **Wire transfers** (international)

### **Types of EFT:**

#### **1. Traditional EFT (Standard Bank Transfer)**
- Takes 1-3 business days to clear
- Student receives bank details and makes transfer
- Payment team manually verifies and confirms
- Enrollment activated after confirmation

#### **2. Instant EFT (Real-time)**
- Immediate payment confirmation
- Uses services like Ozow (SA), i-Pay, etc.
- Student logs into online banking via secure redirect
- Payment verified in real-time
- Enrollment activated immediately

### **How Traditional EFT Works:**

```
Student selects "Bank Transfer/EFT"
    ↓
System displays bank account details
    ↓
Student makes transfer from their bank
    ↓
Payment takes 1-3 days to clear
    ↓
Finance team verifies payment manually
    ↓
Enrollment confirmed after verification
```

### **How Instant EFT Works:**

```
Student selects "Instant EFT"
    ↓
Redirected to Instant EFT provider (e.g., Ozow)
    ↓
Student selects bank and logs in
    ↓
Payment authorized in real-time
    ↓
Instant confirmation
    ↓
Enrollment activated immediately
```

### **Technical Implementation:**

**Model Definition:**
```python
class PaymentMethod(models.Textchoices):
    EFT = 'eft', 'Electronic Funds Transfer'
    BANK_TRANSFER = 'bank_transfer', 'Bank Transfer'
```

**Payment Flow (Traditional EFT):**
1. Student selects EFT during enrollment
2. Backend generates bank details:
   ```json
   {
     "bank_name": "Standard Bank",
     "account_name": "Hosi Academy",
     "account_number": "123456789",
     "branch_code": "051001",
     "reference": "STU-12345",
     "amount": "5000.00 ZAR"
   }
   ```
3. Student makes transfer manually
4. System creates `PaymentTransaction` with `payment_method='eft'`
5. Transaction status: `pending` until verified
6. Finance team receives bank statement
7. Manual reconciliation with reference number
8. Enrollment confirmed

**Payment Flow (Instant EFT):**
1. Student selects "Instant EFT"
2. Backend calls Instant EFT provider API:
   ```python
   ozow_adapter.initiate_payment(
       transaction=transaction,
       callback_url=callback_url,
       payment_method='instant_eft'
   )
   ```
3. Student redirected to Ozow/i-Pay
4. Selects bank, logs in, authorizes
5. Instant confirmation via webhook
6. Enrollment activated immediately

### **Payment Providers Supporting EFT:**

| Provider | Type | Countries | Processing Time |
|----------|------|-----------|-----------------|
| **Ozow** | Instant EFT | South Africa, Namibia, Botswana | Real-time |
| **PayFast** | EFT + Instant EFT | South Africa | 1-3 days / Instant |
| **Flutterwave** | Bank Transfer | Nigeria, Ghana, Kenya | 1-2 days |
| **Paystack** | Bank Transfer | Nigeria, Ghana | 1-2 days |
| **Monnify** | Virtual Accounts | Nigeria | Real-time |
| **Pesapal** | Bank Deposit | East Africa | 1-2 days |

### **Characteristics:**

**Traditional EFT:**
✅ **Lower fees** - Usually fixed fee or free for students  
✅ **Higher limits** - No card transaction limits  
✅ **Widely available** - All bank account holders  
⏳ **Processing Time:** 1-3 business days  
⚠️ **Manual verification** - Requires finance team intervention  
❌ **Delayed enrollment** - Student waits for confirmation  

**Instant EFT:**
✅ **Real-time confirmation** - Like card payments  
✅ **Secure** - Uses bank's own authentication  
✅ **No card needed** - Direct from bank account  
✅ **Lower fraud risk** - Bank-level security  
⚡ **Processing Time:** Immediate  
💰 **Fees:** 1% - 2% (lower than cards)  

### **Use Cases:**

**Traditional EFT:**
- **Large amounts** (exceeding card limits)
- **Corporate payments** from company accounts
- **Students without cards** but with bank accounts
- **Budget-conscious students** (lower/no fees)
- **Government-sponsored students** (requires bank transfer)

**Instant EFT:**
- **South African students** (Ozow widely adopted)
- **Students preferring bank payments** but want instant access
- **High-value enrollments** with immediate confirmation
- **Students without credit cards** but with online banking

---

## 🔄 KEY DIFFERENCES

| Feature | Card Payment | EFT (Traditional) | Instant EFT |
|---------|--------------|-------------------|-------------|
| **Processing Time** | Instant | 1-3 business days | Instant |
| **Confirmation** | Automatic | Manual | Automatic |
| **Enrollment Access** | Immediate | After verification | Immediate |
| **Transaction Fees** | 2.5-3.5% + fixed | Low/None | 1-2% |
| **Payment Limits** | Card limits apply | Bank account limits | Bank limits |
| **Fraud Protection** | 3D Secure, CVV | Bank verification | Bank login |
| **Refund Processing** | Automated | Manual transfer | Automated |
| **International** | ✅ Yes | ⚠️ Complex | ❌ Country-specific |
| **Required Info** | Card number, CVV, expiry | Bank account details | Online banking login |
| **Manual Work** | None | Finance team verification | None |

---

## 💻 CODE EXAMPLES

### **Initiating Card Payment:**

```python
# Frontend calls API
POST /api/v1/payments/initiate/
{
  "program_id": 123,
  "amount": 5000,
  "currency": "ZAR",
  "payment_method": "card",  // ← Card payment
  "provider_code": "flutterwave"
}

# Backend creates transaction
transaction = PaymentTransaction.objects.create(
    user=user,
    amount=5000,
    currency='ZAR',
    provider='flutterwave',
    payment_method='card',  // ← Card
    status='pending'
)

# Initiates card checkout
result = payment_service.initiate_payment(
    user=user,
    amount=5000,
    payment_method='card',
    provider_code='flutterwave'
)

# Returns card checkout URL
{
  "checkout_url": "https://checkout.flutterwave.com/...",
  "requires_redirect": True
}
```

### **Initiating Traditional EFT:**

```python
# Frontend calls API
POST /api/v1/payments/initiate/
{
  "program_id": 123,
  "amount": 5000,
  "currency": "ZAR",
  "payment_method": "eft",  // ← EFT payment
  "provider_code": "bank_transfer"
}

# Backend creates transaction
transaction = PaymentTransaction.objects.create(
    user=user,
    amount=5000,
    currency='ZAR',
    provider='bank_transfer',
    payment_method='eft',  // ← EFT
    status='pending'
)

# Returns bank details (no checkout URL)
{
  "bank_details": {
    "bank_name": "Standard Bank",
    "account_name": "Hosi Academy",
    "account_number": "123456789",
    "branch_code": "051001",
    "reference": "STU-12345"
  },
  "requires_manual_verification": True
}
```

### **Initiating Instant EFT:**

```python
# Frontend calls API
POST /api/v1/payments/initiate/
{
  "program_id": 123,
  "amount": 5000,
  "currency": "ZAR",
  "payment_method": "instant_eft",  // ← Instant EFT
  "provider_code": "ozow"
}

# Backend uses Ozow adapter
ozow_adapter = OzowAdapter()
result = ozow_adapter.initiate_payment(
    transaction=transaction,
    callback_url=callback_url
)

# Returns Instant EFT redirect URL
{
  "checkout_url": "https://pay.ozow.com?...",
  "requires_redirect": True
}
```

---

## 🎯 ENROLLMENT FLOW COMPARISON

### **Card Payment Flow:**

```
1. Student selects course
2. Proceeds to enrollment
3. Chooses "Pay by Card"
4. Enters card details
5. 3D Secure authentication
6. ✅ Payment confirmed instantly
7. ✅ Enrollment activated immediately
8. ✅ Access to course materials
9. ✅ Receipt emailed automatically
```

### **Traditional EFT Flow:**

```
1. Student selects course
2. Proceeds to enrollment
3. Chooses "Bank Transfer/EFT"
4. Receives bank account details
5. Makes transfer from their bank
6. ⏳ Waits 1-3 business days
7. Finance team verifies payment
8. ✅ Enrollment confirmed manually
9. ✅ Access to course materials
10. ✅ Receipt emailed after confirmation
```

### **Instant EFT Flow:**

```
1. Student selects course
2. Proceeds to enrollment
3. Chooses "Instant EFT"
4. Redirected to Ozow/i-Pay
5. Selects bank, logs in
6. Authorizes payment
7. ✅ Payment confirmed instantly
8. ✅ Enrollment activated immediately
9. ✅ Access to course materials
10. ✅ Receipt emailed automatically
```

---

## 📊 RECOMMENDATIONS

### **When to Use Card Payment:**

✅ Students want **immediate access**  
✅ **International payments**  
✅ **Small to medium amounts** (under card limits)  
✅ **Automated enrollment** required  
✅ **High-volume enrollments**  

### **When to Use Traditional EFT:**

✅ **Large amounts** (exceeding card limits)  
✅ **Corporate/company payments**  
✅ **Students without cards**  
✅ **Cost-sensitive** (lower fees)  
✅ **Government/institutional sponsorships**  

### **When to Use Instant EFT:**

✅ **South African students** (Ozow widely adopted)  
✅ **Want bank payment** but need instant access  
✅ **High-value enrollments** with immediate confirmation  
✅ **Students prefer bank** over credit cards  
✅ **Lower fees** than cards but instant confirmation  

---

## 🔒 SECURITY CONSIDERATIONS

### **Card Payment Security:**
- **PCI DSS Compliance** - All card data handled by gateway
- **3D Secure** - Additional authentication layer
- **Tokenization** - Card details not stored
- **Fraud Detection** - Gateway-level monitoring
- **Chargeback Protection** - Gateway handles disputes

### **EFT Security:**
- **Bank Authentication** - Student logs into own bank
- **No Card Data** - No sensitive card information stored
- **Direct Bank Transfer** - Bank-to-bank security
- **Reference Tracking** - Unique payment references
- **Manual Verification** - Finance team confirms receipt

### **Instant EFT Security:**
- **Bank-Level Security** - Uses bank's own login
- **No Data Storage** - Credentials not stored
- **Real-Time Verification** - Instant confirmation
- **Lower Fraud Risk** - Direct bank authentication
- **PCI Exempt** - No card data involved

---

## 📈 ANALYTICS & REPORTING

### **Payment Method Tracking:**

```python
# Query transactions by payment method
card_payments = PaymentTransaction.objects.filter(
    payment_method='card',
    status='completed'
)

eft_payments = PaymentTransaction.objects.filter(
    payment_method='eft',
    status='completed'
)

instant_eft = PaymentTransaction.objects.filter(
    payment_method='instant_eft',
    status='completed'
)

# Calculate conversion rates
card_conversion = card_payments.count() / total_enrollments * 100
eft_conversion = eft_payments.count() / total_enrollments * 100
```

### **Revenue by Payment Method:**

```python
# Revenue breakdown
from django.db.models import Sum

revenue_by_method = PaymentTransaction.objects.filter(
    status='completed'
).values('payment_method').annotate(
    total=Sum('amount'),
    count=Count('id')
)

# Result:
[
  {'payment_method': 'card', 'total': 500000, 'count': 150},
  {'payment_method': 'eft', 'total': 200000, 'count': 45},
  {'payment_method': 'instant_eft', 'total': 150000, 'count': 50}
]
```

---

## 🎓 SUMMARY

| Aspect | Card Payment | EFT/Bank Transfer |
|--------|--------------|-------------------|
| **Speed** | ⚡ Instant | 🐌 1-3 days (traditional) / ⚡ Instant (instant EFT) |
| **Fees** | 💰 Higher (2.5-3.5%) | 💵 Lower (0-2%) |
| **Access** | ✅ Immediate | ⏳ After verification (traditional) / ✅ Immediate (instant) |
| **Limits** | ⚠️ Card limits | ✅ Higher/No limits |
| **Manual Work** | ❌ None | ✅ Required (traditional) / ❌ None (instant) |
| **Best For** | Instant enrollment | Large amounts, cost-sensitive |

**Recommendation:** Offer **both payment methods** to cater to different student needs and maximize enrollment conversions.

---

**Document Created:** March 13, 2026  
**Based On:** LMS-Prod Payment System v2.0  
**Payment Providers:** Flutterwave, Paystack, Yoco, PayFast, Ozow, Pesapal
