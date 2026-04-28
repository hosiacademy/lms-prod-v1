# HOSI ACADEMY LMS - User Credentials

**Generated:** 2026-03-09  
**Total Users:** 33

---

## 🔐 Django Superadmin

| Name | Email | Password | Access |
|------|-------|----------|--------|
| System Administrator | `system.admin@hosi.academy` | `System@Hosi2026!` | Full system access (Django superuser) |

---

## 👥 All Users

| Name | Country | Email | Role | Password |
|------|---------|-------|------|----------|
| System Administrator | All | `system.admin@hosi.academy` | Django Superadmin | `System@Hosi2026!` |
| Executive Admin - Botswana | Botswana | `executive.botswana@hosi.academy` | Executive Admin | `BW-exec-2026@` |
| Executive Admin - Kenya | Kenya | `executive.kenya@hosi.academy` | Executive Admin | `KE-exec-2026@` |
| Executive Admin - Zambia | Zambia | `executive.zambia@hosi.academy` | Executive Admin | `ZM-exec-2026@` |
| Executive Admin - Zimbabwe | Zimbabwe | `executive.zimbabwe@hosi.academy` | Executive Admin | `ZW-exec-2026@` |
| HR Admin - Botswana | Botswana | `hr.botswana@hosi.academy` | HR Admin | `BW-hr-2026@` |
| HR Admin - Kenya | Kenya | `hr.kenya@hosi.academy` | HR Admin | `KE-hr-2026@` |
| HR Admin - Zambia | Zambia | `hr.zambia@hosi.academy` | HR Admin | `ZM-hr-2026@` |
| HR Admin - Zimbabwe | Zimbabwe | `hr.zimbabwe@hosi.academy` | HR Admin | `ZW-hr-2026@` |
| Payment Admin - Botswana | Botswana | `payments.botswana@hosi.academy` | Payment Admin | `BW-payment-2026@` |
| Payment Admin - Kenya | Kenya | `payments.kenya@hosi.academy` | Payment Admin | `KE-payment-2026@` |
| Payment Admin - Zambia | Zambia | `payments.zambia@hosi.academy` | Payment Admin | `ZM-payment-2026@` |
| Payment Admin - Zimbabwe | Zimbabwe | `payments.zimbabwe@hosi.academy` | Payment Admin | `ZW-payment-2026@` |
| Lohn Banda | Zimbabwe | `lohn.banda@hosiacademy.co.za` | Instructor | `Instructor@2026!` |
| Takawira Mazando | Zimbabwe | `takawira.mazando@hosiacademy.co.za` | Instructor | `Instructor@2026!` |
| Tariro Moyo | Zimbabwe | `tariro.moyo.zimbabwe@learner.hosiacademy.co.za` | Student | `Student@2026!` |
| Wanjiru Omondi | Kenya | `wanjiru.omondi.kenya@learner.hosiacademy.co.za` | Student | `Student@2026!` |
| Thabo Dlamini | South Africa | `thabo.dlamini.southafrica@learner.hosiacademy.co.za` | Student | `Student@2026!` |
| Chanda Mwanza | Zambia | `chanda.mwanza.zambia@learner.hosiacademy.co.za` | Student | `Student@2026!` |
| Mulenga Phiri | Zambia | `mulenga.phiri.zambia@learner.hosiacademy.co.za` | Student | `Student@2026!` |
| Student1 Botswana | Botswana | `student1.botswana@test.hosi.academy` | Student | `Student@2026!` |
| Student2 Botswana | Botswana | `student2.botswana@test.hosi.academy` | Student | `Student@2026!` |
| Student3 Botswana | Botswana | `student3.botswana@test.hosi.academy` | Student | `Student@2026!` |
| Student1 Kenya | Kenya | `student1.kenya@test.hosi.academy` | Student | `Student@2026!` |
| Student2 Kenya | Kenya | `student2.kenya@test.hosi.academy` | Student | `Student@2026!` |
| Student3 Kenya | Kenya | `student3.kenya@test.hosi.academy` | Student | `Student@2026!` |
| Student1 Zambia | Zambia | `student1.zambia@test.hosi.academy` | Student | `Student@2026!` |
| Student2 Zambia | Zambia | `student2.zambia@test.hosi.academy` | Student | `Student@2026!` |
| Student3 Zambia | Zambia | `student3.zambia@test.hosi.academy` | Student | `Student@2026!` |
| Student1 Zimbabwe | Zimbabwe | `student1.zimbabwe@test.hosi.academy` | Student | `Student@2026!` |
| Student2 Zimbabwe | Zimbabwe | `student2.zimbabwe@test.hosi.academy` | Student | `Student@2026!` |
| Student3 Zimbabwe | Zimbabwe | `student3.zimbabwe@test.hosi.academy` | Student | `Student@2026!` |
| admin | All | `admin@example.com` | Student | `Admin123!` |

---

## 📊 Summary by Role

| Role | Count | Password Pattern |
|------|-------|-----------------|
| Django Superadmin | 1 | `System@Hosi2026!` |
| Executive Admin | 4 | `<CC>-exec-2026@` |
| HR Admin | 4 | `<CC>-hr-2026@` |
| Payment Admin | 4 | `<CC>-payment-2026@` |
| Instructor | 2 | `Instructor@2026!` |
| Student | 18 | `Student@2026!` |

**CC** = Country Code (KE, ZW, ZM, BW)

---

## 🌍 Summary by Country

| Country | Users |
|---------|-------|
| All Countries | 2 (Superadmin, admin@example.com) |
| Kenya | 7 |
| Zimbabwe | 8 |
| Zambia | 8 |
| Botswana | 7 |
| South Africa | 1 |

---

## ⚠️ Security Notes

1. **Change all passwords immediately** after first login
2. **Store this file securely** - do not commit to version control
3. **Django Superadmin** (`system.admin@hosi.academy`) has unrestricted access
4. Country-based admins can only access data for their assigned country

---

## 🔧 Password Reset

```bash
cd /home/tk/lms-prod/backend
source venv_linux/bin/activate
python manage.py changepassword <email>
```
