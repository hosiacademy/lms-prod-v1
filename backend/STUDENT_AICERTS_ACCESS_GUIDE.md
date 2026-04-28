# Student Registration & AICerts Access Guide

**Target Student**: Richard Masukume (Typical Student Case)  
**Objective**: Register student, enroll in AICerts courses, and grant seamless material access via Partner Credentials.

---

## 1. Overview
Hosi Academy integrates with AICerts via a secure SSO (Single Sign-On) and enrollment synchronization layer. This allows students like **Richard Masukume** to access world-class certification materials directly from their Hosi Academy student portal without needing separate login credentials for the AICerts platform.

---

## 2. Technical Workflow

### Phase 1: Local User Registration
The student is first registered in the Hosi Academy system.
- **Action**: Create a `User` record with `role_id=3` (Student).
- **Key Fields**: `email`, `first_name`, `last_name`.
- **Reference**: `apps.users.models.User`

### Phase 2: AICerts Account Creation (Partner Sync)
The student's identity is synchronized with the AICerts platform using our unique **Partner ID**.
- **Service**: `SSOService.create_user()`
- **Mechanism**: A signed request (HMAC-SHA256) is sent to the AICerts web service.
- **Result**: The student's `User` record is updated with a unique `aicerts_user_id`.

### Phase 3: Course Enrollment
Once the identity exists on both platforms, the student is enrolled in the specific AI certification course.
- **Service**: `EnrollmentSyncService.enroll_user_in_course()`
- **Process**:
    1. Local record creation in `AICertsEnrollment` model.
    2. API call to `enrol_manual_enrol_users` on the AICerts platform.
    3. Verification of `external_id` mapping between systems.

### Phase 4: Seamless Material Access (SSO)
The student accesses the course materials through a "Launch Course" button in the Student Portal.
- **Service**: `SSOService.generate_sso_url()`
- **Mechanism**: Generates a URL with:
    - `username` (email)
    - `partner_id`
    - `timestamp`
    - **HMAC Signature**: Validates that Hosi Academy (the partner) authorized the access.
- **Experience**: The student is automatically logged in and redirected to the specific course material on the AICerts LMS.

---

## 3. Automation Script (Quick Setup)
To facilitate testing or rapid onboarding for typical students (like Richard), an automation script is available in the backend root:

```python
# Location: backend/create_richard.py
# Usage:
python manage.py shell < create_richard.py
```

**What the script does for Richard Masukume:**
1. Creates his local account: `richard.masukume@gmail.com`.
2. Syncs his identity with the AICerts backend.
3. Enrolls him in three core AI certification courses:
   - **AI Foundation** (Ext ID: 14800)
   - **AI Professional** (Ext ID: 14801)
   - **AI Specialist** (Ext ID: 14802)

---

## 4. Troubleshooting Access
If a student reports "Access Denied" or "Invalid Signature":
1. **Verify Credentials**: Ensure `AICERTS_WSTOKEN` and `AICERTS_SECRET_KEY` are correctly set in the `.env` file.
2. **Identity Link**: Check if the student has a non-null `aicerts_user_id` in the Django Admin.
3. **Enrollment Status**: Confirm the local `AICertsEnrollment` status is set to `enrolled`.

---

**Status**: Verified & Operational  
**Integration Version**: AICerts API v1.1  
**Partner Support**: active@aicerts.ai
