# System Architecture: Portal Roles & Enrollment Flows

## Portal Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         LMS MONOREPO SYSTEM                              │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  STUDENT PORTAL  │  │  ONBOARDING      │  │  PAYMENT ADMIN   │
│  (Existing)      │  │  (New Students)  │  │  (Analytics)     │
├──────────────────┤  ├──────────────────┤  ├──────────────────┤
│ ✅ Catalog       │  │ ❌ Catalog       │  │ ❌ Catalog       │
│ ✅ Cart          │  │ ❌ Cart          │  │ ❌ Cart          │
│ ✅ Wishlist      │  │ ❌ Wishlist      │  │ ❌ Wishlist      │
│ ✅ Enrollment    │  │ ✅ First Enroll  │  │ ✅ Analytics     │
│ ✅ Payment       │  │ ✅ Payment       │  │ ✅ Verification  │
└──────────────────┘  └──────────────────┘  └──────────────────┘

┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐
│  HR ADMIN        │  │  EXECUTIVE       │  │  INSTRUCTOR      │
├──────────────────┤  ├──────────────────┤  ├──────────────────┤
│ ❌ Catalog       │  │ ❌ Catalog       │  │ ❌ Catalog       │
│ ❌ Cart          │  │ ❌ Cart          │  │ ❌ Cart          │
│ ❌ Wishlist      │  │ ❌ Wishlist      │  │ ❌ Wishlist      │
│ ✅ HR Tools      │  │ ✅ Dashboards    │  │ ✅ Teaching      │
└──────────────────┘  └──────────────────┘  └──────────────────┘
```

---

## Enrollment Flow: Existing vs. New Students

```
┌─────────────────────────────────────────────────────────────────┐
│                    USER ENTERS SYSTEM                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ Has Enrollments?│
                    └─────────────────┘
                       │           │
              YES ◄────┘           └────► NO
               │                          │
               ▼                          ▼
    ┌──────────────────┐      ┌──────────────────┐
    │ EXISTING STUDENT │      │   NEW STUDENT    │
    │   (Portal Flow)  │      │ (Onboarding Flow)│
    └──────────────────┘      └──────────────────┘
               │                          │
               ▼                          ▼
    ┌──────────────────┐      ┌──────────────────┐
    │ Browse Catalog   │      │ Personal Info    │
    │ Add to Cart      │      │ Collection       │
    │ Add to Wishlist  │      │ (Full Profile)   │
    └──────────────────┘      └──────────────────┘
               │                          │
               ▼                          ▼
    ┌──────────────────┐      ┌──────────────────┐
    │ Checkout         │      │ Training         │
    │                  │      │ Selection        │
    └──────────────────┘      └──────────────────┘
               │                          │
               ▼                          ▼
    ┌──────────────────┐      ┌──────────────────┐
    │ Skip Personal    │      │ Collect Personal │
    │ Info Step        │      │ Info             │
    └──────────────────┘      └──────────────────┘
               │                          │
               └──────────┬───────────────┘
                          ▼
                ┌──────────────────┐
                │ Architecture     │
                │ Selection        │
                │ (Individual/Corp)│
                └──────────────────┘
                          │
                          ▼
                ┌──────────────────┐
                │ Course           │
                │ Preferences      │
                └──────────────────┘
                          │
                          ▼
                ┌──────────────────┐
                │ Review & Confirm │
                └──────────────────┘
                          │
                          ▼
                ┌──────────────────┐
                │ Payment          │
                │ Processing       │
                └──────────────────┘
                          │
                          ▼
                ┌──────────────────┐
                │ Provision Access │
                │ (AICERTS)        │
                └──────────────────┘
```

---

## Training Pathway Provisioning Logic

```
┌─────────────────────────────────────────────────────────────────┐
│              PAYMENT SUCCESS → PROVISION ACCESS                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ Enrollment Type?│
                    └─────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐   ┌───────────────┐   ┌───────────────┐
│ MASTERCLASS   │   │ LEARNERSHIP   │   │ INDUSTRY      │
└───────────────┘   └───────────────┘   │ TRAINING      │
        │                   │            └───────────────┘
        ▼                   ▼                    │
┌───────────────┐   ┌───────────────┐           ▼
│ Immediate     │   │ Set expiry:   │   ┌───────────────┐
│ AICERTS       │   │ now() + 7days │   │ Bulk          │
│ Access        │   │               │   │ Provisioning  │
└───────────────┘   └───────────────┘   │ (Iterative)   │
                            │            └───────────────┘
                            ▼                    │
                    ┌───────────────┐           │
                    │ Status:       │           │
                    │ PROVISIONAL   │           │
                    └───────────────┘           │
                            │                   │
                            ▼                   │
                    ┌───────────────┐           │
                    │ Admin Verify  │           │
                    │ Prerequisites │           │
                    └───────────────┘           │
                            │                   │
                ┌───────────┴───────────┐       │
                ▼                       ▼       │
        ┌───────────────┐   ┌───────────────┐  │
        │ VERIFIED      │   │ EXPIRED       │  │
        │ → ENROLLED    │   │ → REFUND      │  │
        └───────────────┘   └───────────────┘  │
                │                               │
                └───────────────┬───────────────┘
                                ▼
                        ┌───────────────┐
                        │ AICERTS       │
                        │ Enrollment    │
                        │ Sync          │
                        └───────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    CUSTOM SELECTION                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ Extract Course  │
                    │ IDs from        │
                    │ metadata        │
                    └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ For each course:│
                    │ - Get AICerts   │
                    │   course object │
                    │ - Enroll user   │
                    └─────────────────┘
```

---

## Data Flow: Cart to Payment

```
┌─────────────────────────────────────────────────────────────────┐
│                  STUDENT PORTAL CART FLOW                        │
└─────────────────────────────────────────────────────────────────┘

1. Browse Catalog
   │
   ├─► Masterclasses
   ├─► Learnerships
   ├─► Industry Training
   └─► Custom Selection (Multiple Courses)
   
2. Add to Cart
   │
   └─► CourseCartItem {
         objectId: course_id,
         trainingType: 'masterclass' | 'learnership' | 'industry_training',
         price: amount,
         courseTitle: title
       }

3. Checkout Button Clicked
   │
   └─► _proceedToPayment(CartCheckoutReady state)

4. Check Existing Student
   │
   └─► ApiClient.checkExistingStudent()
       │
       └─► Response: {
             is_existing_student: true/false,
             user_id: 123,
             email: "student@example.com",
             full_name: "John Doe"
           }

5. Show EnhancedEnrollmentPanel
   │
   ├─► If existing: Skip personal info
   └─► If new: Collect personal info

6. Create Enrollment
   │
   └─► ApiClient.createEnrollment({
         training_id: course_id,
         enrollment_type: 'custom_selection',
         learner_full_name: "John Doe",
         metadata: {
           selected_course_ids: [1, 2, 3]
         }
       })

7. Proceed to Payment
   │
   └─► ApiClient.proceedToPayment({
         enrollmentId: enrollment.id,
         isBulk: false
       })
       │
       └─► Response: {
             order_id: "ORD-ABC123",
             amount: 500.00,
             currency: "USD"
           }

8. Navigate to Payment Provider Selection
   │
   └─► context.push('/payment', extra: {
         orderId: "ORD-ABC123",
         amount: 500.00,
         programId: course_id,
         programType: 'custom_selection'
       })

9. Payment Success
   │
   └─► Webhook → _provision_training_access()
       │
       └─► For each course in selected_course_ids:
           - Get AICerts course
           - EnrollmentSyncService.enroll_user_in_course()
```

---

## API Endpoint Map

```
┌─────────────────────────────────────────────────────────────────┐
│                      BACKEND API STRUCTURE                       │
└─────────────────────────────────────────────────────────────────┘

/api/v1/
│
├─ learner-portal/
│  └─ profile/
│     └─ check_existing_student/  [GET]  ← Existing student detection
│
├─ payments/
│  ├─ enrollments/                [POST] ← Create individual enrollment
│  │  └─ {id}/
│  │     └─ proceed_to_payment/   [POST] ← Create order
│  │
│  ├─ bulk-enrollments/           [POST] ← Create bulk enrollment
│  │  └─ {id}/
│  │     └─ proceed_to_payment/   [POST] ← Create bulk order
│  │
│  ├─ initiate/                   [POST] ← Initiate payment
│  ├─ verify/{reference}/         [GET]  ← Verify payment
│  └─ providers/                  [GET]  ← Get payment providers
│
├─ courses/
│  ├─ masterclasses/              [GET]  ← List masterclasses
│  └─ ...
│
├─ industry-training/
│  └─ active-courses/             [GET]  ← List industry courses
│
└─ learnerships/
   └─ programmes/                 [GET]  ← List learnerships
```

---

## Database Schema Changes

```sql
-- payments.Enrollment
ALTER TABLE payments_enrollment
ADD COLUMN enrollment_type VARCHAR(50) 
CHECK (enrollment_type IN (
    'masterclass', 
    'learnership', 
    'industry_training', 
    'role_training', 
    'custom_selection'  -- ✅ NEW
));

-- learnerships.LearnershipEnrollment
ALTER TABLE learnerships_learnershipenrollment
ADD COLUMN expiry_date TIMESTAMP NULL;  -- ✅ NEW

-- Index for expiry queries
CREATE INDEX idx_learnership_expiry 
ON learnerships_learnershipenrollment(expiry_date)
WHERE expiry_date IS NOT NULL;
```

---

## Key Takeaways

### ✅ **What Was Implemented**
1. Existing student detection via API
2. Conditional enrollment flow (skip personal info for existing students)
3. Support for all 4 training pathways
4. Custom selection multi-course provisioning
5. Learnership 7-day provisional rule
6. Portal separation (catalog/cart/wishlist only in Student Portal)
7. Payment admin as analytics dashboard

### ❌ **What Is NOT Implemented**
1. Wishlist analytics in Payment Admin (future enhancement)
2. Automatic expiry handling for learnerships (needs Celery task)
3. Email notifications for expiry warnings
4. Automatic refund processing

### 🎯 **Production Readiness**
- **Backend**: ✅ Ready
- **Frontend**: ✅ Ready
- **Database**: ✅ Migrations complete
- **Testing**: ⏳ Awaiting QA
- **Documentation**: ✅ Complete

---

**Last Updated**: 2026-02-10 06:08 AM
