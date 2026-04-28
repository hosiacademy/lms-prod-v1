# HOSI ACADEMY LMS - User Roles & Login Credentials

**Generated:** 2026-03-09  
**System:** Hosi Academy LMS (Production)  
**Database:** `hosiacademylms`

---

## ⚠️ SECURITY WARNING

- **Change all default passwords immediately after first login**
- **Store credentials securely - do not share via email**
- **This file should be kept in a secure location with restricted access**
- **Contact system administrator for access issues**

---

## 📋 Role Structure

| Role ID | Role Name | Access Level |
|---------|-----------|--------------|
| 1 | Admin | Full system access |
| 2 | Instructor/Facilitator | Course management, student facilitation |
| 3 | Student/Learner | Course access, learning materials |
| 4 | HR Admin | Personnel management (country-specific) |
| 5 | Payment Admin | Payment & enrollment management (country-specific) |
| 6 | Executive Admin | Analytics & oversight (country-specific) |

---

## 👥 USERS BY ROLE

### 🔴 ROLE 1: ADMIN (Superusers)

| Name | Email | User ID | Password | Access |
|------|-------|---------|----------|--------|
| System Administrator | `system.admin@hosi.academy` | 11 | `System@Hosi2026!` | Full system - All countries |

---

### 🟡 ROLE 2: INSTRUCTOR/FACILITATOR

| Name | Email | User ID | Password | Country |
|------|-------|---------|----------|---------|
| Takawira Mazando | `takawira.mazando@hosiacademy.co.za` | 1 | `Instructor@2026!` | Zimbabwe |
| Lohn Banda | `lohn.banda@hosiacademy.co.za` | 7 | `Instructor@2026!` | Zimbabwe |

---

### 🟢 ROLE 3: STUDENT/LEARNER

#### Named Students

| Name | Email | User ID | Password | Country |
|------|-------|---------|----------|---------|
| Tariro Moyo | `tariro.moyo.zimbabwe@learner.hosiacademy.co.za` | 2 | `Student@2026!` | Zimbabwe |
| Wanjiru Omondi | `wanjiru.omondi.kenya@learner.hosiacademy.co.za` | 3 | `Student@2026!` | Kenya |
| Thabo Dlamini | `thabo.dlamini.southafrica@learner.hosiacademy.co.za` | 4 | `Student@2026!` | South Africa |
| Chanda Mwanza | `chanda.mwanza.zambia@learner.hosiacademy.co.za` | 5 | `Student@2026!` | Zambia |
| Mulenga Phiri | `mulenga.phiri.zambia@learner.hosiacademy.co.za` | 6 | `Student@2026!` | Zambia |

#### Test Students (Kenya)

| Name | Email | User ID | Password |
|------|-------|---------|----------|
| Student1 Kenya | `student1.kenya@test.hosi.academy` | 60 | `Student@2026!` |
| Student2 Kenya | `student2.kenya@test.hosi.academy` | 61 | `Student@2026!` |
| Student3 Kenya | `student3.kenya@test.hosi.academy` | 62 | `Student@2026!` |

#### Test Students (Zimbabwe)

| Name | Email | User ID | Password |
|------|-------|---------|----------|
| Student1 Zimbabwe | `student1.zimbabwe@test.hosi.academy` | 63 | `Student@2026!` |
| Student2 Zimbabwe | `student2.zimbabwe@test.hosi.academy` | 64 | `Student@2026!` |
| Student3 Zimbabwe | `student3.zimbabwe@test.hosi.academy` | 65 | `Student@2026!` |

#### Test Students (Zambia)

| Name | Email | User ID | Password |
|------|-------|---------|----------|
| Student1 Zambia | `student1.zambia@test.hosi.academy` | 66 | `Student@2026!` |
| Student2 Zambia | `student2.zambia@test.hosi.academy` | 67 | `Student@2026!` |
| Student3 Zambia | `student3.zambia@test.hosi.academy` | 68 | `Student@2026!` |

#### Test Students (Botswana)

| Name | Email | User ID | Password |
|------|-------|---------|----------|
| Student1 Botswana | `student1.botswana@test.hosi.academy` | 69 | `Student@2026!` |
| Student2 Botswana | `student2.botswana@test.hosi.academy` | 70 | `Student@2026!` |
| Student3 Botswana | `student3.botswana@test.hosi.academy` | 71 | `Student@2026!` |

#### Additional Student

| Name | Email | User ID | Password |
|------|-------|---------|----------|
| admin | `admin@example.com` | 8 | `Admin123!` |

---

### 🟣 ROLE 4: HR ADMIN (Country-Based)

| Country | Name | Email | User ID | Password |
|---------|------|-------|---------|----------|
| Kenya | Hr Admin - Kenya | `hr.kenya@hosi.academy` | 12 | `KE-hr-2026@` |
| Zimbabwe | Hr Admin - Zimbabwe | `hr.zimbabwe@hosi.academy` | 15 | `ZW-hr-2026@` |
| Zambia | Hr Admin - Zambia | `hr.zambia@hosi.academy` | 18 | `ZM-hr-2026@` |
| Botswana | Hr Admin - Botswana | `hr.botswana@hosi.academy` | 21 | `BW-hr-2026@` |

---

### 🔵 ROLE 5: PAYMENT ADMIN (Country-Based)

| Country | Name | Email | User ID | Password |
|---------|------|-------|---------|----------|
| Kenya | Payment Admin - Kenya | `payments.kenya@hosi.academy` | 13 | `KE-payment-2026@` |
| Zimbabwe | Payment Admin - Zimbabwe | `payments.zimbabwe@hosi.academy` | 16 | `ZW-payment-2026@` |
| Zambia | Payment Admin - Zambia | `payments.zambia@hosi.academy` | 19 | `ZM-payment-2026@` |
| Botswana | Payment Admin - Botswana | `payments.botswana@hosi.academy` | 22 | `BW-payment-2026@` |

---

### 🟠 ROLE 6: EXECUTIVE ADMIN (Country-Based)

| Country | Name | Email | User ID | Password |
|---------|------|-------|---------|----------|
| Kenya | Executive Admin - Kenya | `executive.kenya@hosi.academy` | 14 | `KE-exec-2026@` |
| Zimbabwe | Executive Admin - Zimbabwe | `executive.zimbabwe@hosi.academy` | 17 | `ZW-exec-2026@` |
| Zambia | Executive Admin - Zambia | `executive.zambia@hosi.academy` | 20 | `ZM-exec-2026@` |
| Botswana | Executive Admin - Botswana | `executive.botswana@hosi.academy` | 23 | `BW-exec-2026@` |

---

## 🔐 Password Management

### Reset a User Password
```bash
cd /home/tk/lms-prod/backend
source venv_linux/bin/activate
python manage.py changepassword <username>
```

### Create New User via Shell
```bash
cd /home/tk/lms-prod/backend
source venv_linux/bin/activate
python manage.py shell
```

```python
from django.contrib.auth import get_user_model
User = get_user_model()

# Create user
user = User.objects.create_user(
    username='new.user',
    email='new.user@hosi.academy',
    password='SecurePassword123!',
    first_name='New',
    last_name='User',
    role_id=3,  # 1=Admin, 2=Instructor, 3=Student
    is_active=True,
)
```

---

## 🌍 Country Access Matrix

| Country | HR Admin | Payment Admin | Executive Admin |
|---------|----------|---------------|-----------------|
| Kenya | ✅ `hr.kenya@hosi.academy` | ✅ `payments.kenya@hosi.academy` | ✅ `executive.kenya@hosi.academy` |
| Zimbabwe | ✅ `hr.zimbabwe@hosi.academy` | ✅ `payments.zimbabwe@hosi.academy` | ✅ `executive.zimbabwe@hosi.academy` |
| Zambia | ✅ `hr.zambia@hosi.academy` | ✅ `payments.zambia@hosi.academy` | ✅ `executive.zambia@hosi.academy` |
| Botswana | ✅ `hr.botswana@hosi.academy` | ✅ `payments.botswana@hosi.academy` | ✅ `executive.botswana@hosi.academy` |

**Note:** Country-based admins can ONLY access data for their assigned country.

---

## 📊 User Statistics

| Role | Count |
|------|-------|
| Admin | 1 |
| Instructor | 2 |
| Student | 18 |
| HR Admin | 4 |
| Payment Admin | 4 |
| Executive Admin | 4 |
| **TOTAL** | **33** |

---

## 🔗 Quick Links

- **Admin Panel:** `/admin/`
- **Student Portal:** `/student/dashboard/`
- **Instructor Portal:** `/instructor/dashboard/`
- **Payment Admin:** `/admin/payments/`
- **HR Admin:** `/admin/hr/`
- **Executive Dashboard:** `/admin/executive/`

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-09  
**Maintained By:** System Administrator
