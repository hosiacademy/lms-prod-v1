# Industry & Role-Based Training Pathway - Current State Analysis

## Overview

This document traces the **Industry-Based Training** and **Role-Based Training** enrollment pathways and identifies gaps in the current implementation.

## Current Implementation Status

### ✅ What Exists

#### 1. Enrollment Type Definitions
```python
# apps/payments/models.py
class EnrollmentType(models.TextChoices):
    MASTERCLASS = 'masterclass', 'Masterclass'
    LEARNERSHIP = 'learnership', 'Learnership'
    INDUSTRY_TRAINING = 'industry_training', 'Industry-Based Training'  # ← Defined
    ROLE_TRAINING = 'role_training', 'Role-Based Training'              # ← Defined
    CUSTOM_SELECTION = 'custom_selection', 'Custom Course Selection'
```

#### 2. Industry-Based Training App Models
```python
# apps/industry_based_training/models.py

class Industry:
    """Industry categories (Healthcare, Finance, Mining, etc.)"""
    name = CharField(unique=True)
    description = TextField()

class AiCertsCourse:
    """Industry-specific course bucket"""
    course_id = CharField(unique=True)  # API ID
    title = CharField()
    lms_id = CharField(null=True)  # Moodle LMS ID (nullable)
    industry = ForeignKey(Industry)
    price_usd = DecimalField(null=True)
    raw_course = ForeignKey('aicerts_courses.AiCertsCourse', null=True)

class Offering:
    """Bundled courses for specific roles/industries"""
    name = CharField()
    industry = ForeignKey(Industry)
    courses = ManyToManyField(AiCertsCourse)
    price_usd = DecimalField()
```

#### 3. Generic Enrollment Model Reference
```python
# apps/payments/models.py
class Enrollment(models.Model):
    enrollment_type = CharField(choices=EnrollmentType.choices)
    
    # Pathway-specific FKs
    learnership_enrollment_id = IntegerField(null=True)
    masterclass_enrollment_id = IntegerField(null=True)
    aicerts_enrollment_id = IntegerField(null=True)
    industry_enrollment_id = IntegerField(null=True)  # ← References non-existent model
    
    content_type = ForeignKey(ContentType)
    object_id = PositiveIntegerField()
    content_object = GenericForeignKey()
```

#### 4. Cash Payment Views
```python
# apps/payments/cash_payment_views.py
def _get_industry_training_cash_instructions(self, program_title: str) -> dict:
    # Returns cash payment instructions for industry training
    
def _get_role_training_cash_instructions(self, program_title: str) -> dict:
    # Returns cash payment instructions for role training
```

---

### ❌ What's Missing (GAP)

#### 1. No IndustryTrainingEnrollment Model

**Problem:** The `Enrollment` model has `industry_enrollment_id` field, but there's **no corresponding model** to reference.

**Impact:** 
- No dedicated tracking table for industry/role training enrollments
- Cannot store industry-specific enrollment data
- No linkage to payment transactions

#### 2. No Provisioning Logic in PaymentService

**Problem:** The `_provision_enrollment()` method has **NO handler** for `industry_training` or `role_training`:

```python
# apps/payments/services/payment_service.py
def _provision_enrollment(self, user, enrollment_type, program_id, transaction):
    
    if enrollment_type == 'masterclass':
        # ... implemented
    
    elif enrollment_type == 'custom_selection':
        # ... implemented
    
    elif enrollment_type == 'learnership':
        # ... implemented
    
    # ❌ MISSING: industry_training and role_training
    # What happens if transaction has these types?
    # → Nothing! No enrollment records created.
    # → No AICerts enrollment.
    # → No generic Enrollment record.
```

#### 3. No AICerts Integration

**Problem:** No service exists to enroll users in AICerts LMS for industry/role training courses.

**Current State:**
- `industry_based_training.AiCertsCourse` has `lms_id` field (nullable)
- No `EnrollmentSyncService` equivalent for industry courses
- No AICerts user creation/enrollment flow

---

## Current Pathway Flow (As Implemented)

### What Happens When a User Pays for Industry Training

```
┌─────────────────────────────────────────────────────────────────┐
│ 1. PAYMENT SUCCESS (Webhook)                                    │
│    PaymentTransaction.status = 'SUCCESSFUL'                     │
│    PaymentTransaction.enrollment_type = 'industry_training'     │
│    PaymentTransaction.metadata.program_id = <Offering ID>       │
│    OR                                                           │
│    PaymentTransaction.metadata.course_ids = [<IndustryCourse>]  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 2. PaymentService._handle_successful_payment()                  │
│    ↓                                                            │
│    provision_enrollment_async.delay(transaction_id)  # Celery   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 3. PaymentService._provision_enrollment()                       │
│                                                                 │
│    if enrollment_type == 'industry_training':                   │
│        ❌ NO HANDLER - Falls through silently                   │
│        logger.info(f"Provisioning {enrollment_type}...")        │
│        # No enrollment records created                          │
│        # No AICerts enrollment                                  │
│        # No generic Enrollment                                  │
│                                                                 │
│    if enrollment_type == 'role_training':                       │
│        ❌ NO HANDLER - Falls through silently                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│ 4. RESULT                                                       │
│    ✅ Payment marked SUCCESSFUL                                 │
│    ❌ NO enrollment records created                             │
│    ❌ NO AICerts LMS access                                     │
│    ❌ NO Sales Admin visibility                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Comparison with Other Pathways

| Pathway | Dedicated Model | Generic Enrollment | AICerts Integration | Sales Admin Visible |
|---------|-----------------|-------------------|---------------------|---------------------|
| **Learnership** | ✅ LearnershipEnrollment | ✅ (via signal) | ✅ (via EnrollmentSyncService) | ✅ Yes |
| **Masterclass** | ✅ MasterclassEnrollment | ✅ (via signal) | ✅ (via EnrollmentSyncService) | ✅ Yes |
| **Custom Selection** | ✅ AICertsEnrollment | ✅ (created in provisioning) | ✅ (via EnrollmentSyncService) | ✅ Yes |
| **Industry Training** | ❌ **MISSING** | ❌ **NOT CREATED** | ❌ **NOT IMPLEMENTED** | ❌ **NO** |
| **Role Training** | ❌ **MISSING** | ❌ **NOT CREATED** | ❌ **NOT IMPLEMENTED** | ❌ **NO** |

---

## AICerts API Requirements (Same as Custom Selection)

Based on AICerts API Documentation v1.0:

### Required API Calls

1. **Create User API**
   ```
   POST /server.php?wsfunction=core_user_create_users
   ```
   - Creates user on AICerts LMS
   - Returns AICerts user ID

2. **Enroll User API**
   ```
   POST /server.php?wsfunction=enrol_manual_enrol_users
   ```
   - Enrolls user in Moodle course
   - Requires: `courseid` (LMS course ID), `userid` (AICerts user ID)

3. **SSO Authentication**
   ```
   GET /server.php?wsfunction=local_myauthplugin_authenticate_user
   ```
   - Auto-login user to AICerts LMS

### Data Requirements

| Field | Source |
|-------|--------|
| `firstname` | User.first_name |
| `lastname` | User.last_name |
| `email` | User.email |
| `username` | User.email |
| `partner_id` | settings.AICERTS_PARTNER_ID |
| `courseid` | IndustryCourse.lms_id (currently nullable!) |
| `roleid` | settings.AICERTS_STUDENT_ROLE_ID |

---

## Recommended Implementation

### Step 1: Create IndustryTrainingEnrollment Model

```python
# apps/industry_based_training/models.py

class IndustryTrainingEnrollment(models.Model):
    """
    Tracks enrollments in industry-based and role-based training.
    
    Supports:
    - Single course enrollment (industry_training)
    - Bundled offering enrollment (role_training)
    - AICerts LMS synchronization
    """
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('enrolled', 'Enrolled'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('dropped_out', 'Dropped Out'),
    ]
    
    # User linkage
    user = ForeignKey('users.User', on_delete.CASCADE)
    
    # Training type
    enrollment_type = CharField(choices=[
        ('industry_training', 'Industry Training'),
        ('role_training', 'Role Training'),
    ])
    
    # Content linkage (polymorphic)
    content_type = ForeignKey(ContentType)
    object_id = PositiveIntegerField()
    content_object = GenericForeignKey()
    # Can be: IndustryCourse or Offering
    
    # Payment linkage
    payment_transaction = ForeignKey(
        'payments.PaymentTransaction',
        on_delete=SET_NULL, null=True
    )
    
    # Status tracking
    status = CharField(choices=STATUS_CHOICES, default='pending')
    payment_status = CharField(default='pending')
    
    # AICerts tracking
    aicerts_user_id = IntegerField(null=True)
    aicerts_enrollment_ids = JSONField(default=list)  # List of enrolled course IDs
    
    # Progress tracking
    enrolled_at = DateTimeField(auto_now_add=True)
    started_at = DateTimeField(null=True)
    completed_at = DateTimeField(null=True)
    
    class Meta:
        db_table = 'industry_training_enrollments'
        indexes = [
            Index(fields=['user', 'status']),
            Index(fields=['content_type', 'object_id']),
        ]
```

### Step 2: Update PaymentService._provision_enrollment()

```python
# apps/payments/services/payment_service.py

elif enrollment_type in ['industry_training', 'role_training']:
    # Student paid for industry-specific or role-based training
    from apps.industry_based_training.models import (
        IndustryTrainingEnrollment,
        AiCertsCourse as IndustryCourse,
        Offering
    )
    from apps.payments.models import Enrollment as GenericEnrollment
    
    program_id = transaction.metadata.get('program_id')
    course_ids = transaction.metadata.get('course_ids', [])
    
    if enrollment_type == 'role_training' and program_id:
        # Enroll in Offering (bundle of courses)
        try:
            offering = Offering.objects.get(id=program_id)
            courses = offering.courses.all()
        except Offering.DoesNotExist:
            logger.error(f"Offering {program_id} not found")
            return
    
    elif enrollment_type == 'industry_training' and course_ids:
        # Enroll in specific industry courses
        courses = IndustryCourse.objects.filter(id__in=course_ids)
    
    else:
        logger.error(f"No courses found for {enrollment_type} tx {transaction.id}")
        return
    
    # Create industry training enrollment
    industry_enrollment = IndustryTrainingEnrollment.objects.create(
        user=user,
        enrollment_type=enrollment_type,
        content_type=ContentType.objects.get_for_model(offering or courses.first()),
        object_id=offering.id if offering else courses.first().id,
        payment_transaction=transaction,
        status='enrolled',
        payment_status='paid' if transaction.status == PaymentStatus.SUCCESSFUL else 'pending',
    )
    
    # Enroll in each course on AICerts
    for course in courses:
        if course.lms_id:  # Only if LMS ID exists
            try:
                aicerts_enrollment, _ = EnrollmentSyncService.enroll_user_in_course(
                    user, 
                    course.raw_course  # Use raw_course for AICerts enrollment
                )
                industry_enrollment.aicerts_enrollment_ids.append(aicerts_enrollment.id)
            except Exception as e:
                logger.error(f"Failed to enroll in {course.title}: {e}")
        else:
            logger.warning(f"Course {course.title} has no lms_id - skipping AICerts enrollment")
    
    industry_enrollment.save()
    
    # Create generic Enrollment record for Sales Admin
    GenericEnrollment.objects.create(
        enrollment_type=EnrollmentType.INDUSTRY_TRAINING if enrollment_type == 'industry_training' else EnrollmentType.ROLE_TRAINING,
        content_type=ContentType.objects.get_for_model(offering or courses.first()),
        object_id=offering.id if offering else courses.first().id,
        enrollment_code=f"INDUSTRY_{uuid.uuid4().hex[:8].upper()}",
        user=user,
        status=GenericEnrollmentStatus.ENROLLED,
        industry_enrollment_id=industry_enrollment.id,
        learner_full_name=user.get_full_name(),
        learner_email=user.email,
        learner_phone=getattr(user, 'phone', '') or '+1234567890',
        final_amount=transaction.amount,
        currency=transaction.currency,
        terms_accepted=True,
        enrolled_at=timezone.now(),
    )
```

### Step 3: Ensure lms_id is Populated

The `IndustryCourse.lms_id` field is currently **nullable**. For AICerts enrollment to work:

1. **Sync process must populate lms_id** from AICerts API
2. **Admin must verify lms_id** before offering courses for sale
3. **Validation** should prevent enrollment in courses without lms_id

---

## Testing Steps

Once implemented:

```bash
# 1. Create test offering
python backend/manage.py shell

>>> from apps.industry_based_training.models import Industry, Offering, AiCertsCourse as IndustryCourse
>>> from apps.payments.models import PaymentTransaction, PaymentStatus
>>> from apps.users.models import User

# 2. Create offering with courses
>>> healthcare = Industry.objects.get(name='Healthcare')
>>> course1 = IndustryCourse.objects.create(title='AI for Healthcare', lms_id='123', industry=healthcare)
>>> course2 = IndustryCourse.objects.create(title='Medical Ethics AI', lms_id='124', industry=healthcare)
>>> offering = Offering.objects.create(name='Healthcare AI Specialist', industry=healthcare, price_usd=299)
>>> offering.courses.set([course1, course2])

# 3. Create payment transaction
>>> user = User.objects.get(email='test@example.com')
>>> txn = PaymentTransaction.objects.create(
...     user=user,
...     amount=299,
...     status=PaymentStatus.SUCCESSFUL,
...     enrollment_type='role_training',
...     metadata={'program_id': offering.id}
... )

# 4. Trigger provisioning
>>> from apps.payments.services.payment_service import PaymentService
>>> service = PaymentService()
>>> service._provision_enrollment(user, 'role_training', offering.id, txn)

# 5. Verify
>>> from apps.industry_based_training.models import IndustryTrainingEnrollment
>>> from apps.payments.models import Enrollment
>>> print(IndustryTrainingEnrollment.objects.filter(user=user).count())
>>> print(Enrollment.objects.filter(user=user, enrollment_type='role_training').count())
```

---

## Summary

### Current State
- **Enrollment types defined** but **not implemented**
- **No dedicated enrollment model** for industry/role training
- **No provisioning logic** - payments succeed but no enrollment created
- **No AICerts integration** - users cannot access courses on AICerts LMS
- **No Sales Admin visibility** - enrollments don't appear in dashboards

### Required Actions
1. Create `IndustryTrainingEnrollment` model
2. Implement provisioning logic in `PaymentService._provision_enrollment()`
3. Ensure `IndustryCourse.lms_id` is populated for AICerts enrollment
4. Add generic `Enrollment` creation for Sales Admin tracking
5. Add admin views for managing industry/role training enrollments

### Priority
**CRITICAL** - Users who pay for industry/role training currently receive **NO enrollment** and **NO course access**.
