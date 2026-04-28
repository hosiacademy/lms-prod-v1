# 🎯 COMPREHENSIVE ROLE-BASED DASHBOARD SPECIFICATION
## Hosi Academy LMS - Complete Analysis & Enhancement Plan

**Date:** March 18, 2026  
**Analysis Scope:** All user roles, dashboards, database models, and JWT-based access control  
**Status:** ✅ COMPLETE ANALYSIS

---

## 📋 TABLE OF CONTENTS

1. [Executive Summary](#executive-summary)
2. [User Role Architecture](#user-role-architecture)
3. [JWT Authentication & Role Filtering](#jwt-authentication--role-filtering)
4. [Dashboard Analysis by Role](#dashboard-analysis-by-role)
5. [Database Models Mapping](#database-models-mapping)
6. [HR Admin Enhancement: Instructor Applications & BBB Interviewing](#hr-admin-enhancement)
7. [Complete Dashboard Specification Matrix](#dashboard-specification-matrix)
8. [Implementation Recommendations](#implementation-recommendations)

---

## 🎯 EXECUTIVE SUMMARY

### Current System Architecture

The Hosi Academy LMS implements a **sophisticated role-based access control (RBAC) system** with:

- **7 distinct user roles** with hierarchical permissions
- **JWT token-based authentication** with role embedding
- **Country-based filtering** for multi-country operations
- **4 enrollment pathways** integrated across dashboards
- **BBB integration** for live sessions and interviews
- **Instructor application system** with full workflow

### Key Findings

✅ **Strengths:**
- Robust JWT authentication with role data embedded in token
- Comprehensive AdminRole model with country access control
- Complete InstructorApplication model with BBB interview integration
- Well-structured dashboard serializers for each role
- Permission-based API endpoints

⚠️ **Enhancement Opportunities:**
- HR Admin dashboard needs full Instructor Application workflow integration
- Hours claims management system needs implementation
- BBB interviewing platform needs frontend integration
- Some dashboard insights can be enriched with additional database queries

---

## 👥 USER ROLE ARCHITECTURE

### Role Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                    ROLE HIERARCHY                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  SYSTEM ADMIN (Superuser)                            │  │
│  │  - Unrestricted access to all data & functionality  │  │
│  │  - All countries, all roles, all features           │  │
│  │  - role_id: 1 OR is_superuser: True                 │  │
│  └──────────────────────────────────────────────────────┘  │
│                          │                                  │
│         ┌────────────────┼────────────────┐                │
│         ▼                ▼                ▼                │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │EXECUTIVE    │  │HR ADMIN     │  │PAYMENT ADMIN│        │
│  │ADMIN        │  │             │  │             │        │
│  │             │  │             │  │             │        │
│  │• All data   │  │• Instructors│  │• Payments   │        │
│  │• Analytics  │  │• Payroll    │  │• Revenue    │        │
│  │• Country    │  │• BBB Interview│• Refunds    │        │
│  │  filtering  │  │• Applications│  │  filtering │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  INSTRUCTOR (Facilitator)                            │  │
│  │  - Assigned courses/learnerships                     │  │
│  │  - BBB sessions, students, chat                      │  │
│  │  - Earnings, hourly rate                             │  │
│  │  - role_id: 2                                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  LEARNER (Student)                                   │  │
│  │  - Enrolled courses                                  │  │
│  │  - Learning progress, BBB sessions                   │  │
│  │  - Chat, assignments                                 │  │
│  │  - role_id: 3                                        │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Role Definitions

| Role | role_id | AdminRole Type | Primary Focus |
|------|---------|----------------|---------------|
| **System Admin** | 1 or is_superuser | N/A | Full system control |
| **Executive Admin** | 1 | `executive_admin` | Strategic analytics |
| **HR Admin** | 1 | `hr_admin` | Instructor management |
| **Payment Admin** | 1 | `payment_admin` | Financial operations |
| **Instructor** | 2 | N/A | Teaching & facilitation |
| **Learner** | 3 | N/A | Learning & development |

---

## 🔐 JWT AUTHENTICATION & ROLE FILTERING

### Authentication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                  JWT AUTHENTICATION FLOW                    │
└─────────────────────────────────────────────────────────────┘

1. LOGIN REQUEST
   POST /api/v1/auth/login/
   {
     "email": "user@hosiacademy.com",
     "password": "******"
   }
                          │
                          ▼
2. BACKEND VALIDATION
   - Find user by email
   - Verify password
   - Check is_active status
   - Load role information
                          │
                          ▼
3. TOKEN GENERATION
   - Create RefreshToken.for_user(user)
   - Embed claims in access token:
     {
       "user_id": 123,
       "email": "user@hosiacademy.com",
       "role_id": 2,
       "is_superuser": false,
       "admin_roles": ["hr_admin"],
       "exp": 1234567890
     }
                          │
                          ▼
4. RESPONSE TO CLIENT
   {
     "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
     "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc...",
     "user": {
       "id": 123,
       "name": "John Doe",
       "email": "john@example.com",
       "role_id": 2,
       ...
     },
     "dashboard": {
       "role": "instructor",
       "profile": {...},
       "courses": [...],
       "students": [...],
       ...
     }
   }
                          │
                          ▼
5. CLIENT STORAGE
   - Store tokens in SharedPreferences
   - Store user profile
   - Store dashboard data
   - Route to appropriate dashboard
                          │
                          ▼
6. SUBSEQUENT REQUESTS
   Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGc...
                          │
                          ▼
7. BACKEND VALIDATION
   - Decode JWT token
   - Verify signature
   - Check expiration
   - Extract role claims
   - Apply permissions
                          │
                          ▼
8. ROLE-BASED RESPONSE
   - Filter data by role
   - Filter by country access
   - Return role-specific data
```

### Token Claims Structure

```python
# backend/apps/users/views_auth.py - CustomTokenObtainPairSerializer

class CustomTokenObtainPairSerializer(serializers.Serializer):
    """
    JWT login serializer that accepts EMAIL and password.
    Returns access/refresh tokens + user profile + dashboard data.
    """
    
    email = serializers.EmailField(write_only=True)
    password = serializers.CharField(write_only=True)
    access = serializers.CharField(read_only=True)  # JWT token
    refresh = serializers.CharField(read_only=True)  # JWT token
    user = UserSerializer(read_only=True)  # User profile
    dashboard = serializers.DictField(read_only=True)  # Role-specific data
```

### Permission Classes

```python
# backend/apps/users/permissions.py

class IsHrAdmin(permissions.BasePermission):
    """HR Admin role permission"""
    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        if request.user.is_superuser:
            return True
        return AdminRole.is_hr_admin(request.user)

class IsPaymentAdmin(permissions.BasePermission):
    """Payment Admin role permission"""
    
class IsExecutiveAdmin(permissions.BasePermission):
    """Executive Admin role permission"""
    
class CanAccessCountryData(permissions.BasePermission):
    """Country-based data access permission"""
    def has_object_permission(self, request, view, obj):
        # Check if user can access object's country
        return can_user_access_country(
            request.user, 
            obj.country_id
        )
```

---

## 📊 DASHBOARD ANALYSIS BY ROLE

### 1. 🎓 LEARNER DASHBOARD

**File:** `frontend/lib/src/presentation/pages/dashboard/student_dashboard.dart`

#### Current Insights & Functionality:

```dart
// Data loaded from login response
{
  "role": "student",
  "profile": {
    "student_id": "STU123",
    "name": "John Doe",
    "email": "john@example.com",
    "avatar": "url"
  },
  "enrollments": [
    {
      "id": 1,
      "title": "Python Masterclass",
      "type": "masterclass|learnership|industry|aicerts",
      "progress": 45.5,
      "status": "active",
      "start_date": "2026-03-01",
      "end_date": "2026-09-01",
      "instructor": "Jane Smith",
      "sso_url": "https://aicerts.moodle/..."  // For AICERTS courses
    }
  ],
  "bbb_sessions": [
    {
      "id": 1,
      "title": "Live Q&A Session",
      "course": "Python Masterclass",
      "instructor": "Jane Smith",
      "startTime": "2026-03-20T14:00:00Z",
      "duration_minutes": 60,
      "status": "scheduled|live|completed",
      "joinUrl": "/api/v1/bbb/sessions/1/join/",
      "isLive": false
    }
  ],
  "chatrooms": [
    {
      "id": 1,
      "name": "Python Masterclass",
      "chat_type": "course|one_on_one|community",
      "unread_count": 3,
      "last_message": {...}
    }
  ],
  "learning_progress": {
    "total_enrollments": 3,
    "active_enrollments": 2,
    "completed_enrollments": 1,
    "average_progress": 45.5,
    "certificates_earned": 1
  },
  "stats": {
    "total_courses": 3,
    "completed_courses": 1,
    "in_progress": 2,
    "hours_spent": 25.5
  }
}
```

#### Database Sources:

| Data | Database Table | Model |
|------|---------------|-------|
| Enrollments | `learnerships_learnershipenrollment` | LearnershipEnrollment |
| AICERTS Enrollments | `aicerts_integration_aicertsenrollment` | AICertsEnrollment |
| Masterclass Enrollments | `masterclasses_masterclassenrollment` | MasterclassEnrollment |
| BBB Sessions | `bbb_integration_livesession` | LiveSession |
| Chat Rooms | `communication_chatroom` | ChatRoom |
| Messages | `communication_message` | Message |

#### Enhancements Recommended:

✅ **Already Complete:**
- All 4 enrollment pathways integrated
- BBB session integration
- Chat system with unread counts
- AICERTS SSO integration
- Progress tracking

🔄 **Can Be Enhanced:**
- Add assignment deadlines to dashboard
- Add upcoming assessment reminders
- Add instructor feedback notifications
- Add learning streak/gamification

---

### 2. 👨‍🏫 INSTRUCTOR DASHBOARD

**File:** `frontend/lib/src/presentation/pages/dashboard/instructor_dashboard.dart`

#### Current Insights & Functionality:

```dart
// 10-tab comprehensive dashboard
{
  "role": "instructor",
  "profile": {
    "facilitator_id": "FAC123",
    "facilitator_type": "internal|external",
    "department": "Technology",
    "specialization": "Python, Data Science",
    "work_email": "jane@hosiacademy.com",
    "is_available": true,
    "hourly_rate": 50.00,
    "overall_rating": 4.8,
    "total_courses_taught": 15,
    "total_students_taught": 450
  },
  "assigned_learnerships": [
    {
      "id": 1,
      "title": "Python Programming",
      "specialization": "Technology",
      "status": "ongoing",
      "start_date": "2026-03-01",
      "end_date": "2026-09-01",
      "student_count": 30
    }
  ],
  "bbb_sessions": [
    {
      "id": 1,
      "title": "Week 3: Advanced Python",
      "course_id": 1,
      "course_type": "learnership",
      "scheduled_start": "2026-03-20T14:00:00Z",
      "scheduled_end": "2026-03-20T15:00:00Z",
      "duration_minutes": 60,
      "status": "scheduled",
      "is_live": false,
      "is_upcoming": true,
      "invited_students_count": 30,
      "max_participants": 100,
      "moderator_password": "mod123",
      "attendee_password": "att123",
      "join_url": "/api/v1/bbb/sessions/1/join/",
      "start_url": "/api/v1/bbb/sessions/1/start/"
    }
  ],
  "students": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com",
      "role": "student",
      "programmes": ["Python Programming"],
      "unread_count": 2,
      "last_message": "Hello, I have a question...",
      "last_message_at": "2026-03-18T10:00:00Z"
    }
  ],
  "chatrooms": [
    {
      "type": "community|course|direct",
      "room": {...}
    }
  ],
  "stats": {
    "total_courses_taught": 15,
    "total_students_taught": 450,
    "average_student_rating": 4.8,
    "completion_rate": 92.5,
    "active_assignments": 3,
    "overall_rating": 4.8
  },
  "engagement": {
    "total_students": 450,
    "active_students": 420,
    "average_progress": 65.0,
    "students_needing_attention": 15,
    "engagement_rate": 93.3
  },
  "earnings": {
    "hourly_rate": 50.00,
    "total_hours_taught": 120,
    "pending_payment_hours": 15,
    "total_earnings": 6000.00,
    "paid_earnings": 5250.00,
    "pending_earnings": 750.00
  }
}
```

#### Database Sources:

| Data | Database Table | Model |
|------|---------------|-------|
| Facilitator Profile | `instructors_instructor` | Instructor |
| Assigned Learnerships | `learnerships_learnershipprogramme` | LearnershipProgramme |
| BBB Sessions | `bbb_integration_livesession` | LiveSession |
| Students | `users` + enrollment tables | User |
| Chat Rooms | `communication_chatroom` | ChatRoom |
| Earnings | `instructors_instructor` (hourly_rate) | Instructor |
| Hours Taught | `bbb_integration_livesession` (completed) | LiveSession |

#### Enhancements Recommended:

✅ **Already Complete:**
- Assigned courses/learnerships
- BBB session management
- Student chat with unread counts
- Earnings tracking (hourly rate)
- Engagement metrics

🔄 **Can Be Enhanced:**
- **Hours claims submission** (link to HR Admin system)
- **Overtime request** workflow
- **Student performance analytics** per course
- **Assignment grading queue**
- **Upcoming session reminders**

---

### 3. 💼 PAYMENT ADMIN DASHBOARD

**File:** `frontend/lib/src/presentation/pages/admin/payment_admin_page.dart`

#### Current Insights & Functionality:

```dart
// 7-tab comprehensive payment operations dashboard
{
  "summary": {
    "total_revenue": 50000.00,
    "pending_cash": 12,
    "pending_eft": 8,
    "awaiting_verification": 20,
    "verified_today": 15,
    "conversion_rate": 12.5,
    "total_leads": 450
  },
  "cash_payments": [
    {
      "id": 1,
      "reference_code": "CASH-20260318-001",
      "learner_name": "John Doe",
      "course_title": "Python Masterclass",
      "amount": 1500.00,
      "currency": "KES",
      "email": "john@example.com",
      "phone": "+254712345678",
      "company_name": "Company Ltd"
    }
  ],
  "eft_payments": [
    {
      "id": "eft_12345",
      "reference": "EFT-20260318-123456",
      "customer_name": "Jane Smith",
      "program_title": "Data Science",
      "amount": 2500.00,
      "currency": "ZAR",
      "customer_email": "jane@example.com",
      "bank_details_submitted": true,
      "proof_of_payment_uploaded": true,
      "time_remaining": "48 hours"
    }
  ],
  "provisional_enrollments": [
    {
      "id": 1,
      "learner_name": "John Doe",
      "enrollment_type": "learnership",
      "course_title": "Python Programming",
      "expires_at": "2026-03-21T23:59:59Z",
      "verification_notes": ""
    }
  ],
  "revenue_by_country": [
    {"country": "Kenya", "revenue": 25000.00, "percentage": 50},
    {"country": "Zimbabwe", "revenue": 15000.00, "percentage": 30},
    {"country": "South Africa", "revenue": 10000.00, "percentage": 20}
  ],
  "payment_method_breakdown": {
    "card": 45,
    "eft": 25,
    "mpesa": 15,
    "cash": 10,
    "paynow": 5
  },
  "marketing_stats": {
    "total_leads": 450,
    "conversion_rate": 12.5,
    "wishlist_leads": 120,
    "recent_conversions": 25
  }
}
```

#### Database Sources:

| Data | Database Table | Model |
|------|---------------|-------|
| Cash Payments | `payments_paymentreference` | PaymentReference |
| EFT Payments | `payments_paymenttransaction` | PaymentTransaction |
| Provisional Enrollments | `enrollments_provisionalenrollment` | ProvisionalEnrollment |
| Revenue | `payments_paymenttransaction` (successful) | PaymentTransaction |
| Countries | `localization_country` | Country |
| Admin Role Access | `admin_roles` + `admin_country_access` | AdminRole |

#### Enhancements Recommended:

✅ **Already Complete:**
- Unified payment view (Cash + EFT + Card + Mobile)
- Payment verification workflow
- Revenue analytics by country
- Payment method breakdown
- Marketing integration

🔄 **Can Be Enhanced:**
- **Refund management** workflow
- **Payment dispute** tracking
- **Recurring payment** management
- **Invoice generation** automation

---

### 4. 👔 HR ADMIN DASHBOARD ⚠️ NEEDS ENHANCEMENT

**File:** `frontend/lib/src/presentation/pages/admin/hr_admin_page.dart`

#### Current Insights & Functionality:

```dart
// 6-tab HR operations dashboard
{
  "dashboard": {
    "total_instructors": 45,
    "active_instructors": 38,
    "pending_applications": 12,
    "scheduled_interviews": 5,
    "pending_overtime": 8,
    "total_payroll_this_month": 25000.00
  },
  "instructors": [
    {
      "id": 1,
      "name": "Jane Smith",
      "email": "jane@hosiacademy.com",
      "facilitator_type": "internal",
      "department": "Technology",
      "specialization": "Python, Data Science",
      "hourly_rate": 50.00,
      "total_courses": 5,
      "total_students": 150,
      "rating": 4.8,
      "is_available": true,
      "country": "Kenya"
    }
  ],
  "applications": [
    {
      "id": 1,
      "application_id": "INST-APP-ABC123",
      "applicant_name": "John Doe",
      "applicant_email": "john@example.com",
      "professional_headline": "Senior Python Developer",
      "areas_of_expertise": "Python, Django, ML",
      "years_of_experience": 10,
      "status": "pending",
      "submitted_at": "2026-03-15T10:00:00Z",
      "country": "Kenya"
    }
  ],
  "attendance_logs": [
    {
      "id": 1,
      "instructor_name": "Jane Smith",
      "session_title": "Python Week 3",
      "scheduled_start": "2026-03-18T14:00:00Z",
      "actual_start": "2026-03-18T14:05:00Z",
      "duration_minutes": 60,
      "status": "completed"
    }
  ],
  "overtime_requests": [
    {
      "id": 1,
      "instructor_name": "Jane Smith",
      "overtime_date": "2026-03-20",
      "hours_requested": 2,
      "reason": "Extra tutoring session",
      "status": "pending",
      "hourly_rate": 50.00,
      "total_claim": 100.00
    }
  ],
  "payroll": {
    "total_instructors": 45,
    "total_hours_this_month": 500,
    "total_payroll": 25000.00,
    "pending_payments": 750.00
  }
}
```

#### Database Sources:

| Data | Database Table | Model |
|------|---------------|-------|
| Instructors | `instructors_instructor` | Instructor |
| Applications | `instructor_applications` | InstructorApplication |
| Attendance | `bbb_integration_livesession` + `instructors_instructorattendancelog` | LiveSession |
| Overtime | `instructors_instructorovertime` | InstructorOvertime |
| Payroll | `instructors_instructor` + sessions | Instructor |
| Countries | `localization_country` | Country |

#### ⚠️ CRITICAL ENHANCEMENTS NEEDED:

**1. Instructor Application Management:**
- ✅ Backend model exists (`InstructorApplication`)
- ✅ BBB integration fields exist (`bbb_meeting_id`, `bbb_moderator_password`)
- ⚠️ **Frontend workflow needs full integration**
- ⚠️ **BBB interview scheduling needs implementation**

**2. Hours Claims Management:**
- ⚠️ **Needs dedicated hours claims submission system**
- ⚠️ **Needs instructor-facing claims submission form**
- ⚠️ **Needs HR approval workflow**

**3. BBB Interviewing Platform:**
- ✅ Backend models support BBB sessions
- ⚠️ **Needs interview-specific BBB session creation**
- ⚠️ **Needs invitation system integration**
- ⚠️ **Needs interview feedback form**

---

### 5. 🎯 EXECUTIVE ADMIN DASHBOARD

**File:** `frontend/lib/src/presentation/pages/admin/executive_admin_page.dart`

#### Current Insights & Functionality:

```dart
// Executive analytics dashboard
{
  "overview": {
    "total_revenue": 150000.00,
    "total_students": 1250,
    "total_courses": 85,
    "total_instructors": 45,
    "completion_rate": 78.5,
    "satisfaction_rate": 4.6
  },
  "revenue_trends": [
    {"month": "2026-01", "revenue": 45000.00},
    {"month": "2026-02", "revenue": 52000.00},
    {"month": "2026-03", "revenue": 53000.00}
  ],
  "country_performance": [
    {
      "country": "Kenya",
      "revenue": 75000.00,
      "students": 625,
      "courses": 42,
      "growth": 15.5
    },
    {
      "country": "Zimbabwe",
      "revenue": 45000.00,
      "students": 375,
      "courses": 28,
      "growth": 12.3
    },
    {
      "country": "South Africa",
      "revenue": 30000.00,
      "students": 250,
      "courses": 15,
      "growth": 8.7
    }
  ],
  "course_performance": [
    {
      "course_type": "Learnership",
      "enrollments": 450,
      "revenue": 67500.00,
      "completion_rate": 82.5
    },
    {
      "course_type": "Masterclass",
      "enrollments": 550,
      "revenue": 55000.00,
      "completion_rate": 75.0
    },
    {
      "course_type": "AICERTS",
      "enrollments": 250,
      "revenue": 27500.00,
      "completion_rate": 88.0
    }
  ]
}
```

#### Database Sources:

| Data | Database Table | Model |
|------|---------------|-------|
| Revenue | `payments_paymenttransaction` | PaymentTransaction |
| Students | `users` (role_id=3) | User |
| Courses | Multiple course tables | Various |
| Instructors | `instructors_instructor` | Instructor |
| Countries | `localization_country` | Country |
| Enrollments | Multiple enrollment tables | Various |

---

## 🗄️ DATABASE MODELS MAPPING

### Core User & Role Models

```python
# Users Table
class User(AbstractUser):
    role_id = models.IntegerField(default=3)  # 1=Admin, 2=Instructor, 3=Student
    name = models.CharField(max_length=191)
    email = models.EmailField()
    hourly_rate = models.DecimalField(max_digits=10, decimal_places=2)
    # ... 100+ fields
    
# Admin Roles Table
class AdminRole(models.Model):
    role_type = models.CharField(max_length=50, choices=[
        ('payment_admin', 'Payment Admin'),
        ('hr_admin', 'HR Admin'),
        ('executive_admin', 'Executive Admin'),
    ])
    user = models.ForeignKey('users.User', on_delete=models.CASCADE)
    is_active = models.BooleanField(default=True)
    permissions = models.JSONField(default=dict)
    
# Country Access Table
class AdminCountryAccess(models.Model):
    admin_role = models.ForeignKey('payments.AdminRole', on_delete=models.CASCADE)
    country = models.ForeignKey('localization.Country', on_delete=models.CASCADE)
    is_active = models.BooleanField(default=True)
```

### Instructor Management Models

```python
# Instructors Table
class Instructor(models.Model):
    facilitator_id = models.CharField(max_length=50, unique=True)
    user = models.OneToOneField('users.User', on_delete=models.CASCADE)
    facilitator_type = models.CharField(max_length=20, choices=[
        ('internal', 'Internal'),
        ('external', 'External'),
    ])
    department = models.CharField(max_length=100)
    specialization = models.TextField()
    hourly_rate = models.DecimalField(max_digits=10, decimal_places=2)
    is_available = models.BooleanField(default=True)
    
# Instructor Applications Table
class InstructorApplication(models.Model):
    application_id = models.CharField(max_length=50, unique=True)
    applicant_name = models.CharField(max_length=255)
    applicant_email = models.EmailField()
    professional_headline = models.CharField(max_length=255)
    areas_of_expertise = models.TextField()
    years_of_experience = models.PositiveIntegerField()
    motivation_letter = models.TextField()
    cv_file = models.FileField(upload_to=...)
    certificates_file = models.FileField(upload_to=...)
    status = models.CharField(max_length=30, choices=[
        ('pending', 'Pending'),
        ('under_review', 'Under Review'),
        ('interview_scheduled', 'Interview Scheduled'),
        ('interview_completed', 'Interview Completed'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ])
    interview_status = models.CharField(max_length=30, choices=[
        ('not_scheduled', 'Not Scheduled'),
        ('scheduled', 'Scheduled'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ])
    # BBB Integration
    bbb_meeting_id = models.CharField(max_length=255, blank=True, null=True)
    bbb_moderator_password = models.CharField(max_length=255, blank=True, null=True)
    bbb_attendee_password = models.CharField(max_length=255, blank=True, null=True)
    interview_datetime = models.DateTimeField(blank=True, null=True)
    reviewed_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True)
    country = models.ForeignKey('localization.Country', on_delete=models.SET_NULL, null=True)
```

### Payment Models

```python
# Payment Transactions
class PaymentTransaction(models.Model):
    provider = models.CharField(max_length=50)  # eft, flutterwave, mpesa, etc.
    provider_reference = models.CharField(max_length=255)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3)
    status = models.CharField(max_length=20)  # pending, successful, failed
    individual_name = models.CharField(max_length=255)
    individual_email = models.EmailField()
    metadata = models.JSONField(default=dict)
    
# Payment References (Cash/In-Person)
class PaymentReference(models.Model):
    reference = models.CharField(max_length=50, unique=True)
    learner_name = models.CharField(max_length=255)
    learner_email = models.EmailField()
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    status = models.CharField(max_length=20)
```

### BBB Integration Models

```python
# Live Sessions
class LiveSession(models.Model):
    session_id = models.CharField(max_length=255, unique=True)
    meeting_id = models.CharField(max_length=255)
    title = models.CharField(max_length=255)
    description = models.TextField()
    instructor = models.ForeignKey('instructors.Instructor', on_delete=models.CASCADE)
    course_type = models.CharField(max_length=50)
    course_id = models.IntegerField()
    scheduled_start = models.DateTimeField()
    scheduled_end = models.DateTimeField()
    duration_minutes = models.IntegerField()
    status = models.CharField(max_length=20)  # scheduled, live, completed, cancelled
    max_participants = models.IntegerField(default=100)
    moderator_password = models.CharField(max_length=255)
    attendee_password = models.CharField(max_length=255)
    
# Session Invitations
class SessionInvitation(models.Model):
    session = models.ForeignKey('bbb_integration.LiveSession', on_delete=models.CASCADE)
    student = models.ForeignKey('users.User', on_delete=models.CASCADE)
    invitation_token = models.CharField(max_length=255, unique=True)
    status = models.CharField(max_length=20)  # sent, opened, joined
```

---

## 🎯 HR ADMIN ENHANCEMENT: INSTRUCTOR APPLICATIONS & BBB INTERVIEWING

### Complete Workflow Design

```
┌─────────────────────────────────────────────────────────────┐
│            INSTRUCTOR APPLICATION WORKFLOW                  │
└─────────────────────────────────────────────────────────────┘

STEP 1: APPLICATION SUBMISSION (Public)
┌──────────────────────────────────────────────────────────────┐
│ Public "Apply to Teach" Form                                │
│ /instructors/apply/                                         │
│                                                              │
│ Fields:                                                     │
│ • Full Name                                                 │
│ • Email Address                                             │
│ • Phone Number                                              │
│ • Professional Headline                                     │
│ • Areas of Expertise                                        │
│ • Top Qualifications                                        │
│ • Years of Experience                                       │
│ • Motivation Letter                                         │
│ • CV/Resume Upload (PDF)                                    │
│ • Certificates Upload (PDF)                                 │
│ • Additional Documents (up to 5 files)                      │
│ • Country Selection                                         │
│                                                              │
│ Submit → POST /api/v1/instructors/applications/             │
│                                                              │
│ Response:                                                   │
│ {                                                           │
│   "application_id": "INST-APP-ABC123",                     │
│   "status": "pending",                                      │
│   "submitted_at": "2026-03-18T10:00:00Z"                   │
│ }                                                           │
└──────────────────────────────────────────────────────────────┘
                          │
                          ▼
STEP 2: HR ADMIN REVIEW (Dashboard)
┌──────────────────────────────────────────────────────────────┐
│ HR Admin Dashboard → Applications Tab                       │
│ /admin/hr/#/applications                                    │
│                                                              │
│ Pending Applications List:                                  │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ 📄 John Doe - INST-APP-ABC123        [Pending] 🟡     │ │
│ │    Senior Python Developer                             │ │
│ │    Expertise: Python, Django, ML                       │ │
│ │    Experience: 10 years                                │ │
│ │    Country: Kenya 🇰🇪                                  │ │
│ │    Submitted: Mar 15, 2026                             │ │
│ │    Attachments: CV, Certificates (3 files)             │ │
│ │    ┌──────────┐ ┌──────────┐                          │ │
│ │    │  Review  │ │ Schedule │                          │ │
│ │    │  Details │ │ Interview│                          │ │
│ │    └──────────┘ └──────────┘                          │ │
│ └────────────────────────────────────────────────────────┘ │
│                                                              │
│ Application Detail View:                                    │
│ • Full application form data                                │
│ • Downloadable attachments (CV, certificates)               │
│ • Applicant profile summary                                 │
│ • Country assignment dropdown                               │
│ • Internal notes field                                      │
│                                                              │
│ Actions:                                                    │
│ • Move to "Under Review"                                    │
│ • Schedule BBB Interview                                    │
│ • Reject with reason                                        │
│ • Approve (creates Instructor record)                       │
└──────────────────────────────────────────────────────────────┘
                          │
                          ▼
STEP 3: BBB INTERVIEW SCHEDULING
┌──────────────────────────────────────────────────────────────┐
│ Schedule Interview Modal                                    │
│                                                              │
│ Interview Details:                                          │
│ • Date/Time Picker                                          │
│ • Duration (30/45/60 minutes)                               │
│ • Interview Panel (select HR admins)                        │
│ • Auto-create BBB Session                                   │
│                                                              │
│ Backend: POST /api/v1/instructors/applications/{id}/schedule│
│ {                                                           │
│   "interview_datetime": "2026-03-25T14:00:00Z",            │
│   "duration_minutes": 45,                                   │
│   "interview_panel": [1, 5],  // HR admin user IDs         │
│   "create_bbb_session": true                                │
│ }                                                           │
│                                                              │
│ Response:                                                   │
│ {                                                           │
│   "success": true,                                          │
│   "bbb_session": {                                          │
│     "id": 123,                                              │
│     "meeting_id": "interview-abc123",                      │
│     "join_url": "/api/v1/bbb/sessions/123/join/",          │
│     "moderator_password": "mod123",                        │
│     "attendee_password": "att123"                          │
│   },                                                        │
│   "invitations": [                                          │
│     {                                                       │
│       "email": "applicant@example.com",                     │
│       "invitation_token": "tok_abc123",                    │
│       "join_url": "/api/v1/bbb/invite/tok_abc123"          │
│     }                                                       │
│   ]                                                         │
│ }                                                           │
│                                                              │
│ Status Update:                                              │
│ application.interview_status = 'scheduled'                 │
│ application.bbb_meeting_id = 'interview-abc123'            │
│ application.interview_datetime = datetime                  │
│                                                              │
│ Email Sent:                                                 │
│ • To applicant: Interview invitation with BBB link          │
│ • To panel: Interview reminder with moderator link          │
└──────────────────────────────────────────────────────────────┘
                          │
                          ▼
STEP 4: INTERVIEW EXECUTION (BBB)
┌──────────────────────────────────────────────────────────────┐
│ BBB Interview Session                                       │
│ /bbb/interview/{session_id}/                                │
│                                                              │
│ Features:                                                   │
│ • Video conferencing (BigBlueButton)                        │
│ • Screen sharing                                            │
│ • Whiteboard                                                │
│ • Recording (optional)                                      │
│ • Chat                                                      │
│                                                              │
│ Participant Roles:                                          │
│ • Applicant: Attendee role (attendee_password)              │
│ • HR Panel: Moderator role (moderator_password)             │
│                                                              │
│ Session Controls:                                           │
│ • Mute/unmute participants                                  │
│ • Share screen                                              │
│ • Start/stop recording                                      │
│ • End session                                               │
│                                                              │
│ Post-Session:                                               │
│ • Session recording saved (if enabled)                      │
│ • Attendance logged                                         │
│ • Duration tracked                                          │
│ • Application status auto-updated to                       │
│   "interview_completed"                                     │
└──────────────────────────────────────────────────────────────┘
                          │
                          ▼
STEP 5: INTERVIEW FEEDBACK & DECISION
┌──────────────────────────────────────────────────────────────┐
│ Interview Feedback Form                                     │
│                                                              │
│ Rating Categories (1-5 stars):                              │
│ • Technical Expertise                                       │
│ • Communication Skills                                      │
│ • Teaching Ability                                          │
│ • Professionalism                                           │
│ • Cultural Fit                                              │
│                                                              │
│ Feedback Fields:                                            │
│ • Strengths (text)                                          │
│ • Areas for Improvement (text)                              │
│ • Overall Recommendation:                                   │
│   ○ Strongly Recommend                                      │
│   ○ Recommend                                               │
│   ○ Recommend with Reservations                             │
│   ○ Do Not Recommend                                        │
│                                                              │
│ Decision:                                                   │
│ ○ Approve as Instructor                                     │
│ ○ Reject                                                    │
│ ○ Request Additional Information                            │
│                                                              │
│ If Approved:                                                │
│ • Instructor record created                                 │
│ • Facilitator ID generated                                  │
│ • Default hourly rate set                                   │
│ • Country assignment                                        │
│ • Welcome email sent                                        │
│                                                              │
│ If Rejected:                                                │
│ • Rejection reason required                                 │
│ • Polite rejection email sent                               │
│ • Application archived                                      │
└──────────────────────────────────────────────────────────────┘
```

### Hours Claims Management System

```
┌─────────────────────────────────────────────────────────────┐
│              INSTRUCTOR HOURS CLAIMS WORKFLOW               │
└─────────────────────────────────────────────────────────────┘

INSTRUCTOR SIDE:
┌──────────────────────────────────────────────────────────────┐
│ Instructor Dashboard → Earnings Tab → Submit Hours Claim    │
│ /instructor/dashboard/#/earnings                            │
│                                                              │
│ Monthly Hours Claim Form:                                   │
│ • Month/Year Selector                                       │
│ • Auto-populated sessions from BBB                          │
│   ┌────────────────────────────────────────────────────┐   │
│   │ Date       │ Session          │ Duration │ Claim  │   │
│   │ 2026-03-01 │ Python Week 1    │ 60 min   │ ☑     │   │
│   │ 2026-03-08 │ Python Week 2    │ 60 min   │ ☑     │   │
│   │ 2026-03-15 │ Python Week 3    │ 60 min   │ ☑     │   │
│   │ 2026-03-20 │ Extra Tutoring   │ 90 min   │ ☑     │   │
│   └────────────────────────────────────────────────────┘   │
│                                                              │
│ • Overtime Hours (if applicable)                            │
│   - Date: _______                                           │
│   - Hours: _______                                          │
│   - Reason: _______                                         │
│   - Supporting documents: [Upload]                          │
│                                                              │
│ • Summary:                                                  │
│   Regular Hours: 180 min (3 hours)                          │
│   Overtime Hours: 90 min (1.5 hours)                        │
│   Hourly Rate: $50.00                                       │
│   Total Claim: $225.00                                      │
│                                                              │
│ Submit → POST /api/v1/instructors/hours-claims/             │
└──────────────────────────────────────────────────────────────┘
                          │
                          ▼
HR ADMIN SIDE:
┌──────────────────────────────────────────────────────────────┐
│ HR Admin Dashboard → Payroll Tab → Hours Claims             │
│ /admin/hr/#/payroll                                         │
│                                                              │
│ Pending Claims List:                                        │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ 👤 Jane Smith                        [Pending] 🟡      │ │
│ │    Month: March 2026                                   │ │
│ │    Regular Hours: 20 hours                             │ │
│ │    Overtime Hours: 5 hours                             │ │
│ │    Total Claim: $1,250.00                              │ │
│ │    Submitted: Mar 31, 2026                             │ │
│ │    ┌──────────┐ ┌──────────┐                          │ │
│ │    │  Review  │ │  Reject  │                          │ │
│ │    │  & Pay   │ │          │                          │ │
│ │    └──────────┘ └──────────┘                          │ │
│ └────────────────────────────────────────────────────────┘ │
│                                                              │
│ Claim Review Detail:                                        │
│ • Instructor profile                                        │
│ • Session breakdown with BBB verification                   │
│ • Overtime justification                                    │
│ • Historical claims comparison                              │
│ • Budget impact analysis                                    │
│                                                              │
│ Actions:                                                    │
│ • Approve & Process Payment                                 │
│ • Request Clarification                                     │
│ • Reject with reason                                        │
│ • Partial approval                                          │
└──────────────────────────────────────────────────────────────┘
```

---

## 📊 COMPLETE DASHBOARD SPECIFICATION MATRIX

| Dashboard | Primary Data Sources | Key Insights | Key Actions | Country Filtering |
|-----------|---------------------|--------------|-------------|-------------------|
| **Learner** | Enrollments, BBB Sessions, Chat | Progress, Upcoming Sessions, Messages | Join Sessions, Chat, View Courses | No (student sees own data) |
| **Instructor** | Assigned Courses, BBB Sessions, Students, Earnings | Teaching Load, Student Engagement, Earnings | Start Sessions, Grade, Chat, Submit Claims | No (instructor sees assigned data) |
| **Payment Admin** | PaymentTransaction, PaymentReference | Revenue, Pending Payments, Conversion | Verify Payments, Process Refunds | ✅ Yes (by AdminCountryAccess) |
| **HR Admin** | Instructor, Applications, Attendance, Overtime | Instructor Performance, Pending Applications, Payroll | Review Applications, Schedule Interviews, Approve Claims | ✅ Yes (by AdminCountryAccess) |
| **Executive** | All aggregated data | Strategic Metrics, Country Performance, Trends | View Analytics, Export Reports | ✅ Yes (all countries or selected) |
| **System Admin** | Everything | Full system visibility | All operations | ✅ Yes (unrestricted) |

---

## 🎯 IMPLEMENTATION RECOMMENDATIONS

### Priority 1: HR Admin Enhancement (CRITICAL)

**1.1 Instructor Application Management**
```python
# Backend endpoints needed:
GET    /api/v1/instructors/applications/              # List all applications
GET    /api/v1/instructors/applications/{id}/         # Get application detail
POST   /api/v1/instructors/applications/              # Submit application (public)
PATCH  /api/v1/instructors/applications/{id}/         # Update application status
POST   /api/v1/instructors/applications/{id}/schedule/ # Schedule BBB interview
POST   /api/v1/instructors/applications/{id}/review/  # Submit review & decision
```

**1.2 BBB Interview Integration**
```python
# Backend service integration:
class InstructorInterviewService:
    @staticmethod
    def schedule_interview(application, datetime, panel):
        # Create BBB session
        session = LiveSession.objects.create(
            title=f"Instructor Interview: {application.applicant_name}",
            scheduled_start=datetime,
            duration_minutes=45,
            course_type='interview',
            course_id=application.id,
            max_participants=10,
        )
        
        # Update application
        application.bbb_meeting_id = session.meeting_id
        application.bbb_moderator_password = session.moderator_password
        application.bbb_attendee_password = session.attendee_password
        application.interview_status = 'scheduled'
        application.interview_datetime = datetime
        application.save()
        
        # Send invitations
        for panel_member in panel:
            invitation = SessionInvitation.objects.create(
                session=session,
                user=panel_member,
                role='moderator'
            )
            invitation.send_email()
        
        # Send applicant invitation
        applicant_invite = SessionInvitation.objects.create(
            session=session,
            email=application.applicant_email,
            role='attendee'
        )
        applicant_invite.send_email()
        
        return session
```

**1.3 Hours Claims System**
```python
# New model needed:
class InstructorHoursClaim(models.Model):
    claim_id = models.CharField(max_length=50, unique=True)
    instructor = models.ForeignKey('instructors.Instructor', on_delete=models.CASCADE)
    month = models.IntegerField()  # 1-12
    year = models.IntegerField()
    
    regular_hours = models.DecimalField(max_digits=6, decimal_places=2)
    overtime_hours = models.DecimalField(max_digits=6, decimal_places=2, default=0)
    
    hourly_rate = models.DecimalField(max_digits=10, decimal_places=2)
    total_claim_amount = models.DecimalField(max_digits=10, decimal_places=2)
    
    status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending'),
        ('under_review', 'Under Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('paid', 'Paid'),
    ])
    
    sessions = models.JSONField(default=list)  # Session IDs included
    overtime_justification = models.TextField(blank=True, null=True)
    
    reviewed_by = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True)
    reviewed_at = models.DateTimeField(null=True, blank=True)
    paid_at = models.DateTimeField(null=True, blank=True)
```

### Priority 2: Dashboard Enhancements

**2.1 Real-time Notifications**
- WebSocket integration for live updates
- Push notifications for pending actions
- Email digest for daily summaries

**2.2 Advanced Analytics**
- Predictive analytics for student success
- Instructor performance trends
- Revenue forecasting

**2.3 Mobile Optimization**
- Responsive design for all dashboards
- Mobile-specific actions (quick verify, approve)
- Offline mode for basic viewing

### Priority 3: Integration & Automation

**3.1 AICERTS Integration**
- Unified dashboard for AICERTS courses
- SSO improvements
- Grade synchronization

**3.2 Automated Reporting**
- Scheduled report generation
- Email delivery
- Export to multiple formats (PDF, Excel)

**3.3 Workflow Automation**
- Auto-approve low-value claims
- Auto-remind pending reviews
- Auto-archive old applications

---

## 📋 CONCLUSION

The Hosi Academy LMS has a **robust foundation** for role-based dashboards with:

✅ **Strong authentication** with JWT and role embedding  
✅ **Comprehensive data models** for all user types  
✅ **Country-based access control** for multi-country operations  
✅ **BBB integration** ready for expansion  
✅ **Instructor application system** with full workflow support  

**Key enhancements needed:**

1. **HR Admin Dashboard** - Full instructor application workflow with BBB interviewing
2. **Hours Claims System** - Complete claims submission and approval workflow
3. **Enhanced Analytics** - Predictive insights and trend analysis
4. **Mobile Optimization** - Responsive design for all roles
5. **Automation** - Workflow automation for routine tasks

**Implementation Timeline:**
- **Week 1-2:** HR Admin instructor application workflow
- **Week 3-4:** Hours claims management system
- **Week 5-6:** BBB interview integration
- **Week 7-8:** Dashboard enhancements and analytics

---

**This specification document provides the complete blueprint for implementing a world-class role-based dashboard system for Hosi Academy LMS.**
