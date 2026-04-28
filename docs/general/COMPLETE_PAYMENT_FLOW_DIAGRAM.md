# 🎯 COMPLETE PAYMENT FLOW DIAGRAM - ENROLLMENT TO ADMIN DASHBOARD

## 📊 End-to-End Payment Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         CUSTOMER JOURNEY                                │
└─────────────────────────────────────────────────────────────────────────┘

                    START: Customer visits hosiacademy.com
                                      │
                                      ▼
                    ┌─────────────────────────────────┐
                    │  Browse Courses                 │
                    │  • Masterclass                  │
                    │  • Learnership                  │
                    │  • Industry Programs            │
                    └─────────────────────────────────┘
                                      │
                                      ▼
                    ┌─────────────────────────────────┐
                    │  Click "Enroll Now"             │
                    └─────────────────────────────────┘
                                      │
                                      ▼
                    ┌─────────────────────────────────┐
                    │  Fill Enrollment Form           │
                    │  • Personal Details             │
                    │  • Contact Information          │
                    │  • Program Selection            │
                    └─────────────────────────────────┘
                                      │
                                      ▼
        ┌──────────────────────────────────────────────────────────┐
        │             PAYMENT METHOD SELECTION                     │
        └──────────────────────────────────────────────────────────┘
                        │                              │
        ┌───────────────┴───────────────┐  ┌──────────┴──────────┐
        │   ONLINE PAYMENTS             │  │  IN-PERSON PAYMENTS │
        │   (Self-Service)              │  │  (Office Visit)     │
        ├───────────────────────────────┤  ├─────────────────────┤
        │  💳 Card (Flutterwave)        │  │  💰 Cash            │
        │  📱 Mobile Money (M-Pesa)     │  │  🏦 EFT (Assisted)  │
        │  🏦 EFT/Bank Transfer         │  │  💳 Card (Terminal) │
        │                               │  │  📱 Mobile Money    │
        └───────────────────────────────┘  └─────────────────────┘
                        │                              │
                        ▼                              ▼
        ┌─────────────────────────┐      ┌─────────────────────────┐
        │  ONLINE EFT FLOW        │      │  IN-PERSON FLOW         │
        ├─────────────────────────┤      ├─────────────────────────┤
        │ 1. Select Country       │      │ 1. Visit Office         │
        │    (KE/ZW/ZA)           │      │    (Nairobi/Harare/JHB) │
        │ 2. See Bank Details     │      │ 2. Staff Creates        │
        │    KE: KCB 05808133206350│      │    Enrollment           │
        │    ZW: CBZ 262728293     │      │ 3. Staff Records       │
        │ 3. Get Reference        │      │    Payment              │
        │    EFT-20260318-XXXXXX  │      │ 4. Payment saved as    │
        │ 4. Make Transfer        │      │    "in-person"          │
        │    from Banking App     │      │    payment_method=cash  │
        │ 5. (Optional) Upload    │      │ 5. Receipt issued       │
        │    Proof of Payment     │      │    immediately          │
        │ 6. Status: PENDING      │      │ 6. Status: PENDING      │
        └─────────────────────────┘      └─────────────────────────┘
                        │                              │
                        └──────────┬───────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      DATABASE STORAGE                                   │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  Online EFT:                          In-Person:                        │
│  ┌─────────────────────────────┐     ┌─────────────────────────────┐   │
│  │ PaymentTransaction          │     │ PaymentReference            │   │
│  │ ├ provider: 'eft'           │     │ ├ payment_method: 'cash'    │   │
│  │ ├ provider_reference:       │     │ ├ reference:                │   │
│  │ │   'EFT-20260318-XXXXXX'   │     │ │   'CASH-20260318-XXX'     │   │
│  │ ├ status: PENDING           │     │ ├ status: 'pending'         │   │
│  │ ├ amount: 1500.00 KES       │     │ ├ amount: 15.00 USD         │   │
│  │ ├ individual_name: John     │     │ ├ learner_name: Tinashe     │   │
│  │ ├ metadata: {               │     │ └ training_title: Course    │   │
│  │ │   program_title: Course,  │     └─────────────────────────────┘   │
│  │ │   bank_details: {...}     │                                       │
│  │ │ }                         │                                       │
│  └─────────────────────────────┘                                       │
│                                                                         │
│  Both link to:                                                          │
│  ┌───────────────────────────────────────────────────────────┐         │
│  │ ProvisionalEnrollment                                     │         │
│  │ ├ status: 'cash_pending'                                  │         │
│  │ ├ enrollment_type: masterclass|learnership|industry       │         │
│  │ ├ payment_transaction: (link to PaymentTransaction)       │         │
│  │ └ expires_at: 2026-03-21                                  │         │
│  └───────────────────────────────────────────────────────────┘         │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    ADMIN DASHBOARD (Unified View)                       │
└─────────────────────────────────────────────────────────────────────────┘

                    Admin logs in: hosiacademy.com/admin
                                      │
                                      ▼
                    ┌─────────────────────────────────┐
                    │  Payment Admin Dashboard        │
                    │  /admin/#/payments              │
                    └─────────────────────────────────┘
                                      │
                                      ▼
        ┌──────────────────────────────────────────────────────────┐
        │             TAB 1: OVERVIEW                              │
        ├──────────────────────────────────────────────────────────┤
        │  KPI Cards:                                              │
        │  ┌────────────┐ ┌────────────┐ ┌────────────┐           │
        │  │Total Revenue│ │Cash Pending│ │EFT Pending │           │
        │  │  $50,000   │ │    12      │ │     8      │           │
        │  └────────────┘ └────────────┘ └────────────┘           │
        │  ┌────────────┐ ┌────────────┐ ┌────────────┐           │
        │  │Awaiting    │ │Verified    │ │Conversion  │           │
        │  │Verification│ │  Today     │ │   Rate     │           │
        │  │     20     │ │     15     │ │   12.5%    │           │
        │  └────────────┘ └────────────┘ └────────────┘           │
        └──────────────────────────────────────────────────────────┘
                                      │
                                      ▼
        ┌──────────────────────────────────────────────────────────┐
        │             TAB 2: PAYMENTS (Unified)                    │
        ├──────────────────────────────────────────────────────────┤
        │                                                          │
        │  ┌────────────────────────────────────────────────────┐ │
        │  │ 🏦 John Kamau                    [EFT Online] 🔵   │ │
        │  │    Python Masterclass                              │ │
        │  │    Email: john@example.com                         │ │
        │  │    KES 1,500.00                                    │ │
        │  │    Ref: EFT-20260318-123456                        │ │
        │  │    ✓ Bank details submitted                        │ │
        │  │    ✓ Proof of payment uploaded                     │ │
        │  │    ⏱ 48 hours remaining                           │ │
        │  │    ┌──────────┐ ┌──────────┐                      │ │
        │  │    │  Verify  │ │  Reject  │                      │ │
        │  │    └──────────┘ └──────────┘                      │ │
        │  └────────────────────────────────────────────────────┘ │
        │                                                          │
        │  ┌────────────────────────────────────────────────────┐ │
        │  │ 💰 Tinashe Moyo                 [Cash/In-Person] 🟠│ │
        │  │    Business Management                             │ │
        │  │    Email: tinashe@example.com                      │ │
        │  │    $15.00 USD                                      │ │
        │  │    Ref: CASH-20260318-001                          │ │
        │  │    ┌──────────┐ ┌──────────┐                      │ │
        │  │    │  Verify  │ │  Reject  │                      │ │
        │  │    └──────────┘ └──────────┘                      │ │
        │  └────────────────────────────────────────────────────┘ │
        │                                                          │
        │  ┌────────────────────────────────────────────────────┐ │
        │  │ 💳 Sarah Johnson                 [Card] 🟣         │ │
        │  │    Data Science Bootcamp                           │ │
        │  │    Email: sarah@example.com                        │ │
        │  │    R 2,500.00 ZAR                                  │ │
        │  │    Ref: FLW-20260318-789012                        │ │
        │  │    Status: SUCCESSFUL (Auto-verified)              │ │
        │  └────────────────────────────────────────────────────┘ │
        │                                                          │
        └──────────────────────────────────────────────────────────┘
                                      │
                                      ▼
        ┌──────────────────────────────────────────────────────────┐
        │             ADMIN ACTION: VERIFY PAYMENT                 │
        ├──────────────────────────────────────────────────────────┤
        │                                                          │
        │  Admin clicks "Verify" → Confirmation Dialog:            │
        │  ┌────────────────────────────────────────────────────┐ │
        │  │  Verify Payment                                    │ │
        │  │                                                     │ │
        │  │  Confirm you have verified this payment in your    │ │
        │  │  bank statement?                                   │ │
        │  │                                                     │ │
        │  │  Reference: EFT-20260318-123456                    │ │
        │  │  Amount: KES 1,500.00                              │ │
        │  │  Customer: John Kamau                              │ │
        │  │                                                     │ │
        │  │       [Cancel]          [✓ Verify]                 │ │
        │  └────────────────────────────────────────────────────┘ │
        │                                                          │
        │  Admin clicks "Verify" → Backend API Call:              │
        │  POST /api/v1/payments/admin/eft/verify/EFT-20260318-123456/
        │  {                                                       │
        │    "notes": "Verified against KCB bank statement"       │
        │  }                                                       │
        │                                                          │
        └──────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      BACKEND PROCESSING                                 │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  verify_payment() function (admin_views.py:216-309)                    │
│                                                                         │
│  1. Check payment_method parameter                                     │
│     • If 'eft' or starts with 'eft_' → Process as EFT                  │
│     • Otherwise → Process as Cash                                      │
│                                                                         │
│  2. For EFT:                                                           │
│     • Find PaymentTransaction by reference                             │
│     • Update status: PENDING → SUCCESSFUL                              │
│     • Set completed_at = now                                           │
│     • Set reconciled = True                                            │
│     • Add verification metadata                                        │
│     • Save transaction                                                 │
│                                                                         │
│  3. Update Enrollment:                                                 │
│     • Find ProvisionalEnrollment by payment_transaction                │
│     • Update status: 'cash_pending' → 'confirmed'                      │
│     • Set verified_by = admin user                                     │
│     • Set verified_at = now                                            │
│     • Save enrollment                                                  │
│                                                                         │
│  4. Trigger Notifications:                                             │
│     • Email to customer: "Payment Verified"                            │
│     • SMS to customer: "Enrollment Confirmed"                          │
│     • Email to admin: "EFT Payment Verified"                           │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      POST-VERIFICATION FLOW                             │
└─────────────────────────────────────────────────────────────────────────┘
                                      │
                    ┌─────────────────┴─────────────────┐
                    │                                   │
                    ▼                                   ▼
        ┌─────────────────────┐           ┌─────────────────────┐
        │  For Masterclass:   │           │  For Learnership:   │
        │  • Instant Access   │           │  • Prerequisites    │
        │  • Course activated │           │    Verification     │
        │  • Email sent       │           │  • Admin reviews    │
        │  • Login → My       │           │  • Documents check  │
        │    Courses          │           │  • Once verified:   │
        │                     │           │    → Enrollment     │
        │                     │           │      Confirmed      │
        │                     │           │  • Email sent       │
        └─────────────────────┘           └─────────────────────┘
                    │                                   │
                    └───────────────┬───────────────────┘
                                    │
                                    ▼
                    ┌─────────────────────────────────┐
                    │  Customer Dashboard              │
                    │  /dashboard                      │
                    ├─────────────────────────────────┤
                    │  ✓ Enrollment Confirmed          │
                    │  📚 Access Course                │
                    │  📄 View Receipt                 │
                    │  💳 Payment History              │
                    └─────────────────────────────────┘
                                    │
                                    ▼
                    ┌─────────────────────────────────┐
                    │  Admin Dashboard Updates         │
                    ├─────────────────────────────────┤
                    │  • Payment moves to "Verified"  │
                    │  • Revenue statistics updated   │
                    │  • Conversion rate updated      │
                    │  • Sales analytics updated      │
                    └─────────────────────────────────┘
```

---

## 📊 Payment Method Comparison Table

| Feature | Online EFT | In-Person Cash | Card (Online) | Mobile Money |
|---------|-----------|----------------|---------------|--------------|
| **Customer Journey** | Self-service online | Office visit | Self-service online | Self-service online |
| **Payment Recording** | PaymentTransaction | PaymentReference | PaymentTransaction | PaymentTransaction |
| **Provider Field** | `provider='eft'` | `payment_method='cash'` | `provider='flutterwave'` | `provider='mpesa'` |
| **Status Flow** | PENDING → SUCCESSFUL | pending → verified | PENDING → SUCCESSFUL | PENDING → SUCCESSFUL |
| **Verification** | Manual (admin) | Manual (admin) | Automatic (webhook) | Automatic (webhook) |
| **Time to Confirm** | 24-72 hours | Same day | Instant | Instant |
| **Bank Account** | KCB/CBZ/FNB | Office safe/terminal | Flutterwave account | M-Pesa Paybill |
| **Admin Dashboard** | ✅ Unified view | ✅ Unified view | ✅ Unified view | ✅ Unified view |
| **Visual Badge** | 🔵 EFT Online | 🟠 Cash/In-Person | 🟣 Card | 🟢 Mobile Money |
| **Proof of Payment** | Optional upload | Receipt issued | N/A (auto) | N/A (auto) |

---

## 🎯 Key Integration Points

### 1. Database Level
- Both EFT and Cash payments link to `ProvisionalEnrollment`
- Unified status tracking (`cash_pending`, `confirmed`, `rejected`)

### 2. API Level
- Single endpoint: `/api/v1/payments/admin/payments/`
- Returns all payment types with `payment_method` discriminator

### 3. Frontend Level
- Single Payment Admin Dashboard
- Unified payment list with visual badges
- Same verify/reject workflow for all types

### 4. Reporting Level
- All payments contribute to total revenue
- Payment method breakdown in Sales tab
- Country-specific filtering available

---

## ✅ Complete Flow Verification

```bash
# 1. Check EFT transactions
SELECT provider_reference, amount, status, individual_name 
FROM payments_paymenttransaction 
WHERE provider = 'eft' 
ORDER BY created_at DESC 
LIMIT 5;

# 2. Check Cash payments
SELECT reference, amount, status, learner_name 
FROM payments_paymentreference 
WHERE status = 'pending' 
ORDER BY created_at DESC 
LIMIT 5;

# 3. Check unified view (both should appear)
# Visit: https://hosiacademy.com/admin/#/payments
# Tab: "Payments"
```

---

**This diagram shows the complete end-to-end flow from customer enrollment to admin verification!** 🎉
