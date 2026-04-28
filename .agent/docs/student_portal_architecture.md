# Student Portal Architecture - Enrollment Flow

## Overview
This document outlines the enrollment architecture for existing vs. new students, ensuring existing students can enroll in new training without re-entering personal information.

## Portal Architecture

### 1. **Student Portal** (Primary Enrollment Hub for Existing Students)
**Purpose**: Allow existing students to browse and enroll in new training programs

**Features**:
- ✅ **Wishlist**: Students can save courses they're interested in
- ✅ **Cart**: Students can add multiple courses from all 4 training pathways
- ✅ **Course Catalog**: Browse all available training (Masterclasses, Learnerships, Industry Training, Custom Selection)
- ✅ **Existing Student Detection**: Automatically checks if user has prior enrollments
- ✅ **Streamlined Enrollment**: Skips personal info collection for existing students

**Enrollment Flow for Existing Students**:
```
Browse Catalog → Add to Cart → Checkout → 
  ↓
Check Existing Student Status (API: /api/v1/learner-portal/profile/check_existing_student/)
  ↓
If Existing Student:
  - Skip personal information step
  - Show only: Architecture Selection → Course Preferences → Review → Payment
  
If New Student:
  - Redirect to Onboarding (first-time setup)
```

**Key Files**:
- `frontend/lib/src/presentation/pages/student_portal/course_cart_page.dart`
- `frontend/lib/src/presentation/pages/student_portal/wishlist_page.dart`
- `frontend/lib/src/presentation/widgets/panels/enhanced_enrollment_panel.dart`
- `frontend/lib/src/core/api/api_client.dart` (checkExistingStudent method)

---

### 2. **Onboarding Portal** (New Students Only)
**Purpose**: First-time user setup and initial enrollment

**Features**:
- ✅ **Personal Information Collection**: Full learner profile
- ✅ **Initial Training Selection**: Choose first program
- ✅ **One-Time Setup**: Only runs once per student

**Flow**:
```
Welcome → Personal Info → Training Selection → Payment → Complete
```

**Key Point**: After completing onboarding, students become "existing students" and use the Student Portal for all future enrollments.

---

### 3. **Payment/Admin Portal** (Sales & Marketing Dashboard)
**Purpose**: Analytics and insights, NOT enrollment

**Features**:
- ✅ **Payment Tracking**: Monitor all transactions
- ✅ **Wishlist Analytics**: See what students want (market demand)
- ✅ **Enrollment Statistics**: Track enrollment trends
- ❌ **NO Catalog/Cart/Wishlist**: This is analytics only

**Key Point**: This portal shows WHAT students are buying and WHAT they wish to study, providing sales and marketing insights.

---

### 4. **Other Portals** (Instructor, HR, Executive)
**Purpose**: Role-specific functionality

**Features**:
- ❌ **NO Catalog/Cart/Wishlist**: These are not enrollment portals
- ✅ **Role-Specific Tools**: Teaching, HR management, executive dashboards

---

## Backend Implementation

### Existing Student Detection
**Endpoint**: `GET /api/v1/learner-portal/profile/check_existing_student/`

**Response**:
```json
{
  "is_existing_student": true,
  "user_id": 123,
  "email": "student@example.com",
  "full_name": "John Doe",
  "phone": "+27123456789",
  "enrollments_count": 3
}
```

**Logic**:
```python
def check_existing_student(request):
    user = request.user
    enrollment_count = Enrollment.objects.filter(user=user).count()
    
    return Response({
        'is_existing_student': enrollment_count > 0,
        'user_id': user.id,
        'email': user.email,
        'full_name': user.get_full_name(),
        'phone': user.phone,
        'enrollments_count': enrollment_count
    })
```

### Enrollment Creation
**Endpoints**:
- `POST /api/v1/payments/enrollments/` - Individual enrollment
- `POST /api/v1/payments/bulk-enrollments/` - Corporate/bulk enrollment
- `POST /api/v1/payments/enrollments/{id}/proceed_to_payment/` - Create order

**Flow**:
```
1. Create Enrollment Record (with or without personal info)
2. Generate Order with tracking ID
3. Navigate to Payment Provider Selection
4. Process Payment via Adapter Pattern
5. Provision Access in AICERTS (or create provisional learnership)
```

---

## Frontend Implementation

### EnhancedEnrollmentPanel
**Purpose**: Universal enrollment widget that adapts to student status

**Props**:
- `courses`: List of courses to enroll in
- `isExistingStudent`: Boolean flag
- `existingStudentData`: Pre-filled user data (if existing)

**Behavior**:
```dart
if (isExistingStudent) {
  // Steps: Architecture → Course Preferences → Review → Payment
  // Personal info is PRE-FILLED from existingStudentData
} else {
  // Steps: Architecture → Personal Info → Course Preferences → Review → Payment
  // Personal info must be COLLECTED
}
```

### Cart Checkout Integration
**File**: `course_cart_page.dart`

**Key Method**: `_proceedToPayment()`
```dart
Future<void> _proceedToPayment(CartCheckoutReady state) async {
  // 1. Check if user is existing student
  final existingStudentData = await ApiClient.checkExistingStudent();
  final isExistingStudent = existingStudentData['is_existing_student'];
  
  // 2. Convert cart items to Course objects
  final courses = _currentCart!.items.map((item) => Course(...)).toList();
  
  // 3. Show enrollment panel with appropriate flow
  showDialog(
    context: context,
    builder: (context) => EnhancedEnrollmentPanel(
      courses: courses,
      isExistingStudent: isExistingStudent,
      existingStudentData: isExistingStudent ? existingStudentData : null,
    ),
  );
}
```

---

## Training Pathways (All 4 Supported)

### 1. Masterclass
- **Type**: `masterclass`
- **Provisioning**: Immediate AICERTS access
- **Payment**: Required upfront

### 2. Learnership
- **Type**: `learnership`
- **Provisioning**: 7-day provisional enrollment
- **Payment**: Required upfront
- **Special Rule**: `expiry_date` set to 7 days from enrollment

### 3. Industry Training (Corporate/Bulk)
- **Type**: `industry_training`
- **Provisioning**: Iterative for all learners
- **Payment**: Corporate billing

### 4. Custom Selection
- **Type**: `custom_selection`
- **Provisioning**: Individual course provisioning from cart
- **Payment**: Bundle pricing

---

## Key Takeaways

✅ **Existing students NEVER go through onboarding again**
✅ **Student Portal is the ONLY place for catalog/cart/wishlist**
✅ **Payment Portal is for analytics, NOT enrollment**
✅ **All 4 training pathways are supported in the cart**
✅ **Personal info is automatically skipped for existing students**

---

## Testing Checklist

- [ ] Existing student can add courses to cart
- [ ] Existing student checkout skips personal info
- [ ] New student is redirected to onboarding
- [ ] All 4 training types work in cart
- [ ] Payment portal shows wishlist analytics
- [ ] Other portals don't have catalog/cart/wishlist

---

**Last Updated**: 2026-02-10
**Status**: ✅ Implementation Complete
