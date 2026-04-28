# Email and SMS Notification System - Hosi Academy LMS

## Overview
This document describes the complete email and SMS notification system implemented in the Hosi Academy LMS.

---

## 📧 Email Configuration

### SMTP Settings (Gmail)
- **Backend**: `django.core.mail.backends.smtp.EmailBackend`
- **Host**: `smtp.gmail.com`
- **Port**: `587` (TLS)
- **From**: `Hosi Academy <mazandotakawira01@gmail.com>`

### Configuration Location
- **File**: `/home/tk/lms-prod/backend/lms_project/settings.py` (lines 448-455)
- **Environment**: `/home/tk/lms-prod/backend/.env`

---

## 📱 SMS Configuration

### Twilio Integration
- **Service**: Twilio SMS API
- **Status**: Ready (requires credentials)
- **File**: `backend/apps/payments/services/sms_service.py`

### Required Environment Variables
```env
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+1234567890
```

---

## 🔔 Notification Types

### 1. Payment Notifications

#### Email - Payment Confirmation
- **Task**: `send_payment_confirmation_email()`
- **Trigger**: Payment transaction successful
- **Location**: `backend/apps/payments/tasks.py`
- **Content**: Transaction details, receipt, course access info

#### SMS - Payment Confirmation
- **Task**: `send_payment_confirmation_sms()`
- **Trigger**: Payment transaction successful
- **Location**: `backend/apps/payments/tasks.py:260`
- **Content**: Amount, reference, course name
- **Template**: `sms_template.payment_success()`

#### SMS - Payment Failed
- **Task**: `send_payment_failed_sms()`
- **Trigger**: Payment transaction failed
- **Location**: `backend/apps/payments/tasks.py:347`

#### SMS - Refund Confirmation
- **Task**: `send_refund_confirmation_sms()`
- **Trigger**: Refund processed
- **Location**: `backend/apps/payments/tasks.py:380`

---

### 2. Enrollment Notifications

#### Email - Provisional Enrollment (Cash Payment)
- **Task**: `send_provisional_enrollment_email()`
- **Trigger**: User creates enrollment with cash payment
- **Location**: `backend/apps/enrollments/tasks.py:51`
- **Status**: `cash_pending`
- **Content**:
  - Reference code
  - Payment amount and expiry date
  - Office payment details
  - Chat access notification

#### Email - Provisional Enrollment (Verification Pending)
- **Task**: `send_provisional_enrollment_email()`
- **Trigger**: Learnership enrollment requiring prerequisite verification
- **Status**: `provisional`
- **Content**:
  - Enrollment pending verification
  - 7-day review period
  - Chat access notification

#### SMS - Welcome Message
- **Location**: `backend/apps/enrollments/tasks.py:118`
- **Trigger**: After provisional enrollment email
- **Content**: Welcome message with chat access info

#### Email - Expiry Warning (3 days before)
- **Task**: `send_expiry_warning_emails()`
- **Trigger**: Daily Celery Beat task
- **Location**: `backend/apps/enrollments/tasks.py:259`
- **Content**: Reminder that enrollment expires in 3 days

#### Email - Enrollment Expired
- **Task**: `send_provisional_expiry_email()`
- **Trigger**: Enrollment expires without payment/verification
- **Location**: `backend/apps/enrollments/tasks.py:143`
- **Content**: Expiry notification, refund info (if applicable)

#### Email - Admin Notification (Verification Required)
- **Task**: `notify_admin_for_prerequisite_verification()`
- **Trigger**: New learnership enrollment needs verification
- **Location**: `backend/apps/enrollments/tasks.py:188`
- **Recipient**: Admin email
- **Content**: Student details, payment info, admin link

---

### 3. BBB Session Notifications

#### Email - Session Invitation
- **Service**: `BBBSessionEmailService.send_session_invitation()`
- **Location**: `backend/apps/bbb_integration/email_service.py:20`
- **Trigger**: Session created for course
- **Content**:
  - Session title, date, time
  - Instructor name
  - Join URL with invitation token

#### Email - Session Reminder (1 hour before)
- **Service**: `BBBSessionEmailService.send_session_reminder()`
- **Location**: `backend/apps/bbb_integration/email_service.py:72`
- **Trigger**: 1 hour before session start

#### Email - Chat Invitation
- **Service**: `BBBSessionEmailService.send_chat_invitation()`
- **Location**: `backend/apps/bbb_integration/email_service.py:113`
- **Content**: 1-on-1 chat access link

#### Email - Recording Available
- **Service**: `BBBSessionEmailService.send_recording_available()`
- **Location**: `backend/apps/bbb_integration/email_service.py:152`
- **Trigger**: Session recording published

#### Chat - Session Announcement
- **Service**: `InstructorSessionManager.send_session_announcement_to_chat()`
- **Location**: `backend/apps/bbb_integration/services.py:597`
- **Trigger**: Session created
- **Content**:
  - Course group chat announcement
  - 1-on-1 chat notifications to all enrolled students

---

## 📊 Database Integration

### ChatRoom Model Updates
```python
# New fields for BBB session integration
upcoming_bbb_session = ForeignKey(LiveSession, null=True, blank=True)
bbb_session_info = JSONField(default=dict)
```

### Message Model Updates
```python
# Link messages to BBB sessions
bbb_session = ForeignKey(LiveSession, null=True, blank=True)
```

### Serializers Updated
- **ChatRoomSerializer**: Includes `upcoming_bbb_session` and `bbb_session_info`
- **MessageSerializer**: Includes `bbb_session` info
- **Location**: `backend/apps/communication/serializers.py`

---

## 🔄 Notification Flow Diagrams

### Payment Success Flow
```
Payment Gateway → PaymentTransaction.status='successful'
    ↓
send_payment_notifications() [Celery Task]
    ↓
├─→ send_payment_confirmation_email() → User Inbox
└─→ send_payment_confirmation_sms() → User Phone (Twilio)
```

### Enrollment Flow (Cash Payment)
```
User Creates Enrollment → ProvisionalEnrollment (status=cash_pending)
    ↓
send_provisional_enrollment_email() [Celery Task]
    ↓
├─→ Email with reference code → User Inbox
├─→ SMS welcome message → User Phone
└─→ ChatEnforcerService.enforce_enrollment_chats()
    ├─→ Create 1-on-1 chat with instructor
    ├─→ Create course group chat
    └─→ Send welcome messages
```

### BBB Session Creation Flow
```
Instructor Creates Session → LiveSession (status=scheduled)
    ↓
InstructorSessionManager.create_session_for_course()
    ↓
├─→ send_session_announcement_to_chat()
│   ├─→ Course chat announcement
│   └─→ 1-on-1 chat notifications
└─→ auto_invite_enrolled_students()
    └─→ BBBSessionEmailService.invite_all_enrolled_students()
        └─→ Email invitations to all students
```

---

## 🧪 Testing

### Test Script
**Location**: `/home/tk/lms-prod/backend/test_notifications.py`

**Run Command**:
```bash
cd /home/tk/lms-prod/backend
python test_notifications.py
```

**Tests**:
1. Email configuration verification
2. Test email send
3. SMS configuration check
4. SMS service status
5. Notification task imports
6. Database table accessibility
7. Recent activity check

---

## 📝 TODO / Future Enhancements

1. **SMS Expiry Warnings**: Add SMS notifications for enrollment expiry warnings
2. **WhatsApp Integration**: Enable WhatsApp messages via Twilio
3. **Notification Preferences**: Allow users to opt-out of specific notification types
4. **Email Templates**: Create HTML email templates for better branding
5. **Notification Analytics**: Track open rates, delivery rates, etc.
6. **Push Notifications**: Add mobile push notifications for Flutter app

---

## 🐛 Known Issues & Fixes Applied

### Fixed
1. ✅ **SMS Import Error** in `enrollments/tasks.py`
   - Changed from `apps.communication.sms_service` to `apps.payments.services.sms_service`
   - Updated to use `sms_service` and `sms_template` correctly

2. ✅ **Serializer Missing Fields** in `communication/serializers.py`
   - Added `BBBSessionInfoSerializer`
   - Updated `ChatRoomSerializer` to include `upcoming_bbb_session` and `bbb_session_info`
   - Updated `MessageSerializer` to include `bbb_session`

---

## 📚 Key Files Reference

| File | Purpose |
|------|---------|
| `backend/lms_project/settings.py` | Email/SMS configuration |
| `backend/.env` | Environment variables |
| `backend/apps/payments/services/sms_service.py` | Twilio SMS service |
| `backend/apps/payments/tasks.py` | Payment notification tasks |
| `backend/apps/enrollments/tasks.py` | Enrollment notification tasks |
| `backend/apps/bbb_integration/email_service.py` | BBB session emails |
| `backend/apps/bbb_integration/services.py` | BBB session management |
| `backend/apps/communication/serializers.py` | Chat/Message serializers |
| `backend/test_notifications.py` | Test script |

---

## 🚀 Deployment Checklist

- [ ] Verify SMTP credentials in `.env`
- [ ] Send test email
- [ ] Configure Twilio credentials (when ready)
- [ ] Test SMS sending
- [ ] Verify Celery worker is running
- [ ] Test enrollment flow end-to-end
- [ ] Test BBB session creation and notifications
- [ ] Monitor logs for errors

---

**Last Updated**: March 11, 2026
**Author**: Development Team
