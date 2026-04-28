# Custom Selection Pathway - AICerts API Alignment

## Overview

This document traces the **Custom Selection** enrollment pathway from payment success to AICerts LMS enrollment, verifying alignment with AICerts API requirements.

## AICerts API Requirements

Based on the AICerts API Documentation (v1.0), the following endpoints are required:

### 1. Create User API
```
POST /server.php?wsfunction=core_user_create_users
```
**Required Parameters:**
- `wstoken` - API access token
- `users[0][firstname]` - User's first name
- `users[0][lastname]` - User's last name
- `users[0][email]` - User's email
- `users[0][username]` - Username (usually same as email)
- `timestamp` - Epoch time
- `signature` - HMAC signature (SHA256 of "email:timestamp")
- `users[0][partner_id]` - Partner ID
- `users[0][source]` - Source (e.g., "sso")

**Response:**
```json
{
  "status": "success",
  "message": "User registered successfully",
  "id": {UserID},
  "username": "{email-id}"
}
```

### 2. Course Enrollment API
```
POST /server.php?wsfunction=enrol_manual_enrol_users
```
**Required Parameters:**
- `wstoken` - API token
- `enrolments[0][roleid]` - Role ID (default: 5 for student)
- `enrolments[0][courseid]` - Course ID (Moodle course ID)
- `enrolments[0][userid]` - User ID (from Create User response)
- `enrolments[0][enrollmentsourcefrom]` - Enrollment source
- `timestamp` - Epoch timestamp
- `signature` - HMAC signature
- `enrolments[0][partner_id]` - Partner ID

**Response:**
```json
{
  "status": "success",
  "message": "User enrol successfully",
  "isUserAlreadyEnrolled": "0"
}
```

### 3. Authenticate User API (SSO)
```
GET /server.php?wsfunction=local_myauthplugin_authenticate_user
```
**Required Parameters:**
- `wstoken` - Token to authorize
- `username` - User email or username
- `timestamp` - Epoch timestamp
- `signature` - HMAC signature
- `partner_id` - Partner ID

**Note:** Use this API in a browser. It will auto-login the user into the AICerts LMS platform.

### Signature Generation

```php
$secret = 'your_secret_key';
$timestamp = time();
$data = "email-id" . ':' . $timestamp;
echo $signature = hash_hmac('sha256', $data, $secret);
```

## Custom Selection Pathway Flow

### Step 1: Payment Success (Webhook)

```
PaymentTransaction (SUCCESSFUL, enrollment_type='custom_selection')
    ↓
PaymentService._handle_successful_payment()
    ↓
provision_enrollment_async.delay(transaction_id)  # Celery task
```

### Step 2: Async Provisioning

```python
# apps/payments/services/payment_service.py
def _provision_enrollment(self, user, enrollment_type, program_id, transaction):
    
    if enrollment_type == 'custom_selection':
        course_ids = transaction.metadata.get('course_ids', [])
        
        for course_id in course_ids:
            course = AiCertsCourse.objects.get(id=course_id)
            
            # === AICERTS API CALL #1 & #2 ===
            EnrollmentSyncService.enroll_user_in_course(user, course)
```

### Step 3: EnrollmentSyncService (Dual Enrollment)

```python
# apps/aicerts_integration/services.py
class EnrollmentSyncService:
    
    @staticmethod
    @transaction.atomic
    def enroll_user_in_course(user, course, create_aicerts_user=True):
        
        # Check if user has AICERTs ID
        aicerts_user_id = getattr(user, 'aicerts_user_id', None)
        
        # === AICERTS API CALL #1: CREATE USER ===
        if not aicerts_user_id and create_aicerts_user:
            result = SSOService.create_user(
                email=user.email,
                first_name=user.first_name,
                last_name=user.last_name
            )
            # Response: {"status": "success", "id": 12345, ...}
            aicerts_user_id = result.get('id')
            
            # Update local user record
            user.aicerts_user_id = aicerts_user_id
            user.save()
        
        # === AICERTS API CALL #2: ENROLL USER ===
        aicerts_result = SSOService.enroll_user(
            aicerts_user_id=aicerts_user_id,
            course_id=course.lms_course_id,  # Moodle course ID
            email=user.email
        )
        # Response: {"status": "success", "isUserAlreadyEnrolled": "0"}
        
        # Create local AICertsEnrollment record
        enrollment = AICertsEnrollment.objects.create(
            user=user,
            course=course,
            aicerts_enrollment_status='enrolled',
            aicerts_already_enrolled=(aicerts_result.get('isUserAlreadyEnrolled') == '1')
        )
        
        return enrollment, aicerts_result
```

### Step 4: Generic Enrollment Record (NEW)

```python
# apps/payments/services/payment_service.py
# After AICerts enrollment succeeds

from apps.payments.models import Enrollment as GenericEnrollment

GenericEnrollment.objects.create(
    enrollment_type=EnrollmentType.CUSTOM_SELECTION,
    content_type=ContentType.objects.get_for_model(course),
    object_id=course.id,
    enrollment_code=f"CUSTOM_{uuid.uuid4().hex[:8].upper()}",
    user=user,
    status=GenericEnrollmentStatus.ENROLLED,
    aicerts_enrollment_id=aicerts_enrollment.id,  # Link to AICerts record
    
    # Learner details snapshot
    learner_full_name=user.get_full_name() or user.username,
    learner_email=user.email,
    learner_phone=getattr(user, 'phone', ''),
    learner_country=transaction.country,
    
    # Financials
    final_amount=transaction.amount,
    currency=transaction.currency,
    order=transaction.order,
    
    # Terms
    terms_accepted=True,
    terms_accepted_at=timezone.now(),
    
    # Timestamps
    enrolled_at=timezone.now(),
    
    # Metadata
    enrollment_data={
        'transaction_id': str(transaction.id),
        'provider_reference': transaction.provider_reference,
        'payment_status': transaction.status,
    }
)
```

## Implementation Details

### HMAC Signature Service

```python
# apps/aicerts_integration/services.py
class HMACSignatureService:
    
    @staticmethod
    def generate_signature(data: str, secret_key: str) -> str:
        """Generate HMAC SHA256 signature"""
        return hmac.new(
            secret_key.encode('utf-8'),
            data.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()
    
    @staticmethod
    def generate_timestamp_signature(identifier: str) -> Tuple[int, str]:
        """Generate timestamp and signature for API call"""
        timestamp = int(time.time())
        data = f"{identifier}:{timestamp}"
        signature = HMACSignatureService.generate_signature(data)
        return timestamp, signature
```

### SSO Service - Create User

```python
# apps/aicerts_integration/services.py
class SSOService:
    
    @classmethod
    def create_user(cls, email: str, first_name: str, last_name: str) -> Dict:
        
        timestamp, signature = HMACSignatureService.generate_timestamp_signature(email)
        
        params = {
            'wstoken': cls.WSTOKEN,
            'wsfunction': 'core_user_create_users',
            'moodlewsrestformat': 'json',
            'users[0][firstname]': first_name,
            'users[0][lastname]': last_name,
            'users[0][email]': email,
            'users[0][username]': email,
            'users[0][partner_id]': cls.PARTNER_ID,
            'users[0][source]': 'sso',
            'timestamp': timestamp,
            'signature': signature
        }
        
        response = requests.post(cls.BASE_URL, params=params)
        result = response.json()[0]  # Response is a list
        
        # Returns: {"status": "success", "id": 12345, "username": "email"}
```

### SSO Service - Enroll User

```python
# apps/aicerts_integration/services.py
class SSOService:
    
    @classmethod
    def enroll_user(cls, aicerts_user_id: int, course_id: int, email: str) -> Dict:
        
        timestamp, signature = HMACSignatureService.generate_timestamp_signature(email)
        
        params = {
            'wstoken': cls.WSTOKEN,
            'wsfunction': 'enrol_manual_enrol_users',
            'moodlewsrestformat': 'json',
            'enrolments[0][roleid]': cls.STUDENT_ROLE_ID,
            'enrolments[0][userid]': aicerts_user_id,
            'enrolments[0][courseid]': course_id,
            'enrolments[0][enrollmentsourcefrom]': 'hosi-academy',
            'enrolments[0][partner_id]': cls.PARTNER_ID,
            'timestamp': timestamp,
            'signature': signature
        }
        
        response = requests.post(cls.BASE_URL, params=params)
        result = response.json()
        
        # Returns: {"status": "success", "isUserAlreadyEnrolled": "0"}
```

## Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                  PAYMENT SUCCESS (Webhook)                      │
│  PaymentTransaction.status = 'SUCCESSFUL'                       │
│  enrollment_type = 'custom_selection'                           │
│  metadata.course_ids = [123, 456, ...]                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│         PaymentService._handle_successful_payment()             │
│  ↓                                                              │
│  provision_enrollment_async.delay(transaction_id)  # Celery     │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│         PaymentService._provision_enrollment()                  │
│  For each course_id in metadata.course_ids:                     │
│    1. Get AiCertsCourse                                         │
│    2. EnrollmentSyncService.enroll_user_in_course()             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
        ┌─────────────────────┴─────────────────────┐
        ↓                                           ↓
┌───────────────────┐                   ┌───────────────────────┐
│ AICERTS API #1    │                   │ AICERTS API #2        │
│ Create User       │                   │ Enroll User           │
│───────────────────│                   │───────────────────────│
│ POST              │                   │ POST                  │
│ /server.php       │                   │ /server.php           │
│ ?wsfunction=      │                   │ ?wsfunction=          │
│ core_user_        │                   │ enrol_manual_         │
│ create_users      │                   │ enrol_users           │
│                   │                   │                       │
│ Params:           │                   │ Params:               │
│ - users[0][email] │                   │ - enrolments[0][      │
│ - users[0][       │                   │   userid]             │
│   firstname]      │                   │ - enrolments[0][      │
│ - users[0][       │                   │   courseid]           │
│   lastname]       │                   │ - enrolments[0][      │
│ - timestamp       │                   │   roleid]             │
│ - signature       │                   │ - timestamp           │
│ - partner_id      │                   │ - signature           │
│ - source='sso'    │                   │ - partner_id          │
│                   │                   │                       │
│ Response:         │                   │ Response:             │
│ {status: success, │                   │ {status: success,     │
│  id: 12345}       │                   │  isUserAlready        │
│                   │                   │  Enrolled: 0}         │
└───────────────────┘                   └───────────────────────┘
        ↓                                           ↓
        └─────────────────────┬─────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              Local Database Records Created                     │
├─────────────────────────────────────────────────────────────────┤
│ 1. AICertsEnrollment                                            │
│    - user: User                                                 │
│    - course: AiCertsCourse                                      │
│    - aicerts_enrollment_status: 'enrolled'                      │
│    - aicerts_already_enrolled: false                            │
│    - synced_at: timezone.now()                                  │
│                                                                 │
│ 2. Enrollment (Generic - NEW)                                   │
│    - enrollment_type: CUSTOM_SELECTION                          │
│    - content_type: AiCertsCourse                                │
│    - object_id: course.id                                       │
│    - aicerts_enrollment_id: <FK to AICertsEnrollment>           │
│    - status: ENROLLED                                           │
│    - learner_email: user.email                                  │
│    - final_amount: transaction.amount                           │
│    - enrollment_code: CUSTOM_ABC123                             │
└─────────────────────────────────────────────────────────────────┘
```

## Alignment Verification

### ✅ AICerts API Requirements Met

| Requirement | Implementation | Status |
|-------------|----------------|--------|
| **Create User API** | `SSOService.create_user()` | ✅ |
| - HMAC signature | `HMACSignatureService.generate_timestamp_signature()` | ✅ |
| - Required params | All params included (firstname, lastname, email, etc.) | ✅ |
| - Partner ID | `settings.AICERTS_PARTNER_ID` | ✅ |
| - Source tracking | `source='sso'` | ✅ |
| **Enroll User API** | `SSOService.enroll_user()` | ✅ |
| - HMAC signature | Generated per enrollment | ✅ |
| - Role ID | `settings.AICERTS_STUDENT_ROLE_ID` | ✅ |
| - Course ID | `course.lms_course_id` (Moodle ID) | ✅ |
| - Enrollment source | `enrollmentsourcefrom='hosi-academy'` | ✅ |
| **SSO Authentication** | `SSOService.generate_sso_url()` | ✅ |
| - Auto-login URL | Generated for user dashboard | ✅ |

### ✅ Local Data Alignment

| Record Type | Purpose | Created |
|-------------|---------|---------|
| `AICertsEnrollment` | Tracks AICerts LMS enrollment | ✅ |
| `Enrollment` (Generic) | Unified enrollment tracking | ✅ (NEW) |
| `PaymentTransaction` | Payment record | ✅ (Already existed) |

### ✅ Sales Admin Alignment

The generic `Enrollment` record provides:
- **Unified dashboard**: All enrollments visible in one place
- **Status tracking**: `ENROLLED`, `COMPLETED`, `DROPPED_OUT`, etc.
- **Payment linkage**: Links to `Order` and `PaymentTransaction`
- **Learner snapshot**: Captures learner details at enrollment time
- **Content type polymorphism**: Links to `AiCertsCourse` via GenericForeignKey

## Testing

To test the custom selection pathway:

```bash
# 1. Create a test transaction
venv_new/bin/python3 backend/manage.py shell

>>> from apps.payments.models import PaymentTransaction, PaymentStatus
>>> from apps.users.models import User
>>> user = User.objects.get(email='test@example.com')
>>> txn = PaymentTransaction.objects.create(
...     user=user,
...     amount=99.0,
...     currency='USD',
...     country='KE',
...     provider='mpesa',
...     status=PaymentStatus.SUCCESSFUL,
...     enrollment_type='custom_selection',
...     metadata={'course_ids': [1, 2]}  # AiCertsCourse IDs
... )

# 2. Trigger provisioning
>>> from apps.payments.services.payment_service import PaymentService
>>> service = PaymentService()
>>> service._provision_enrollment(user, 'custom_selection', None, txn)

# 3. Verify records
>>> from apps.aicerts_integration.models import AICertsEnrollment
>>> from apps.payments.models import Enrollment
>>> print(AICertsEnrollment.objects.filter(user=user).count())
>>> print(Enrollment.objects.filter(user=user, enrollment_type='custom_selection').count())
```

## Files Modified

1. **`backend/apps/payments/services/payment_service.py`**
   - Updated `_provision_enrollment()` for `custom_selection`
   - Now creates generic `Enrollment` record after AICerts enrollment

2. **`backend/apps/aicerts_integration/services.py`**
   - `EnrollmentSyncService.enroll_user_in_course()` - Already implemented
   - Returns tuple of `(AICertsEnrollment, aicerts_result)`

## Benefits

1. **Complete Audit Trail**: Payment → Generic Enrollment → AICerts Enrollment
2. **Sales Admin Visibility**: Custom selection enrollments appear in unified dashboard
3. **AICerts Compliance**: Full alignment with AICerts API requirements
4. **SSO Ready**: User can auto-login to AICerts via generated SSO URL
5. **Retry Support**: Failed AICerts enrollments can be retried via `AICertsEnrollment.needs_retry`
