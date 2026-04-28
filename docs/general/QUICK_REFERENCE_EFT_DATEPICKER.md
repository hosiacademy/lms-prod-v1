# Quick Reference: EFT Notifications & Date Picker

## 🚀 Quick Start

### 1. Configure Environment

```bash
# Add to .env file
EMAIL_HOST_USER=your-email@hosiacademy.africa
EMAIL_HOST_PASSWORD=your-app-password
TWILIO_ACCOUNT_SID=ACxxxxxxxxx
TWILIO_AUTH_TOKEN=your-token
TWILIO_WHATSAPP_NUMBER=whatsapp:+27123456789

# Bank Accounts
ZA_BANK_NAME=FNB Business
ZA_ACCOUNT_NUMBER=123456789
ZA_ACCOUNT_NAME=HosiTech LMS (Pty) Ltd
```

### 2. Test Notifications

```bash
cd /home/tk/lms-prod/backend
python test_eft_notifications.py
```

### 3. Deploy

```bash
# Backend
docker-compose restart backend

# Frontend
cd /home/tk/lms-prod/frontend
flutter build web  # or flutter build apk

# Celery
docker-compose restart celery-worker
```

---

## 📧 Email Templates

### Location
`backend/apps/notifications/templates/notifications/emails/`

- `eft_initiated.html` - Bank details + instructions
- `eft_verified.html` - Payment confirmation
- `eft_rejected.html` - Rejection notice

### Trigger Points

```python
# backend/apps/payments/views/eft_views.py

# Line 195: Initiated
send_eft_notifications.delay(transaction.id, 'initiated')

# Line 844: Verified
send_eft_notifications.delay(transaction.id, 'verified')

# Line 965: Rejected
send_eft_notifications.delay(transaction.id, 'rejected', reason)
```

---

## 📱 SMS Templates

### Message Formats

**Initiated:**
```
Hosi Academy: EFT payment initiated. 
Ref: EFT-20260314-123456 
Amount: ZAR 1,500.00 
Bank: FNB Business 
Complete payment within 72hrs.
```

**Verified:**
```
Hosi Academy: Payment verified! 
Ref: EFT-20260314-123456 
Your enrollment is now confirmed. 
Access: portal.hosiacademy.africa
```

**Rejected:**
```
Hosi Academy: Payment issue. 
Ref: EFT-20260314-123456 
Reason: [reason]. 
Contact support: +27 11 234 5678
```

---

## 📅 Date Picker Implementation

### Files Changed

**Frontend:**
- `frontend/lib/src/presentation/widgets/modals/multi_step_learnership_enrollment_modal.dart`

### Changes Made

1. **Added `selectedDob` field** to `LearnerFormData` class (Line 2355)
   ```dart
   DateTime? selectedDob; // For date picker
   ```

2. **Replaced TextField with DatePicker** (Line 2673-2683)
   ```dart
   _buildDatePickerField(
     controller: learnerData.dobController,
     label: 'Date of Birth *',
     icon: Icons.calendar_today_outlined,
     onDateSelected: (DateTime picked) {
       setState(() {
         learnerData.selectedDob = picked;
       });
     },
     selectedDate: learnerData.selectedDob,
   )
   ```

3. **Added `_buildDatePickerField` method** (Line 3013-3112)
   - Calendar icon button
   - Date picker dialog
   - Age validation (16+)
   - Format validation (YYYY-MM-DD)

---

## 🧪 Testing Checklist

### Email Notifications
- [ ] EFT initiated email received
- [ ] Bank details correct
- [ ] Reference number displayed
- [ ] Email renders on mobile
- [ ] Links working

### SMS Notifications
- [ ] EFT initiated SMS received
- [ ] Reference number correct
- [ ] Phone number format valid
- [ ] Message under 160 chars

### Date Picker
- [ ] Calendar icon clickable
- [ ] Date picker opens
- [ ] Date selection works
- [ ] Format is YYYY-MM-DD
- [ ] Age validation (16+)
- [ ] Error messages display

---

## 🔧 Troubleshooting

### Email Not Sending

**Check:**
```bash
# Celery logs
docker-compose logs celery-worker | grep "EFT"

# Email config
docker-compose exec backend python manage.py shell
>>> from django.conf import settings
>>> print(settings.EMAIL_HOST_USER)
>>> print(settings.EMAIL_HOST_PASSWORD)
```

**Fix:**
```bash
# Restart Celery
docker-compose restart celery-worker

# Check SMTP connection
telnet smtp.gmail.com 587
```

### SMS Not Sending

**Check:**
```bash
# Twilio config
docker-compose exec backend python manage.py shell
>>> from django.conf import settings
>>> print(settings.TWILIO_ACCOUNT_SID)
>>> print(settings.TWILIO_AUTH_TOKEN)
```

**Fix:**
```bash
# Verify Twilio credentials
curl -X GET 'https://api.twilio.com/2010-04-01/Accounts/ACxxxxx.json' \
  -u ACxxxxx:your-token
```

### Date Picker Not Working

**Check:**
```bash
# Flutter build
cd /home/tk/lms-prod/frontend
flutter analyze lib/src/presentation/widgets/modals/multi_step_learnership_enrollment_modal.dart

# Check for import errors
grep "import.*intl" lib/src/presentation/widgets/modals/multi_step_learnership_enrollment_modal.dart
```

**Fix:**
```bash
# Rebuild Flutter
flutter clean
flutter pub get
flutter build web
```

---

## 📊 Monitoring

### Dashboard Queries

```sql
-- Pending EFT payments
SELECT COUNT(*) FROM payments_paymenttransaction 
WHERE provider='eft' AND status='pending';

-- Verified today
SELECT COUNT(*) FROM payments_paymenttransaction 
WHERE provider='eft' AND status='successful' 
AND completed_at::date = CURRENT_DATE;

-- Average verification time
SELECT AVG(completed_at - created_at) 
FROM payments_paymenttransaction 
WHERE provider='eft' AND status='successful';
```

### Celery Task Status

```bash
# View active tasks
docker-compose exec celery-worker celery -A lms_project inspect active

# View registered tasks
docker-compose exec celery-worker celery -A lms_project inspect registered | grep eft
```

---

## 📞 Support Contacts

**Technical Issues:**
- Email: support@hosiacademy.africa
- Phone: +27 11 234 5678

**Bank Details:**
- South Africa: FNB Business (011 234 5678)
- Kenya: Equity Bank (0763 636 000)
- Zimbabwe: CBZ Bank (+263 242 700 000)

---

## 🔐 Security Checklist

- [ ] Email credentials in .env (not in code)
- [ ] Twilio tokens encrypted
- [ ] Bank account numbers not logged
- [ ] Reference numbers unique per transaction
- [ ] HTTPS for all API endpoints
- [ ] Rate limiting on SMS sending
- [ ] POPIA/GDPR compliant data handling

---

**Last Updated:** March 14, 2026  
**Version:** 1.0  
**Status:** ✅ Production Ready
