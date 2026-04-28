# HOSI ACADEMY LMS - Complete User Credentials Table

**Generated:** 2026-03-09  
**Total Users:** 33  
**Login URL:** `http://localhost:8000/admin/login/`

---

| Name | Country | Email | Role | Password |
|------|---------|-------|------|----------|
| System Administrator | All | system.admin@hosi.academy | Django Superadmin | System@Hosi2026! |
| Executive Admin Botswana | Botswana | executive.botswana@hosi.academy | Executive Admin | BW-exec-2026@ |
| Executive Admin Kenya | Kenya | executive.kenya@hosi.academy | Executive Admin | KE-exec-2026@ |
| Executive Admin Zambia | Zambia | executive.zambia@hosi.academy | Executive Admin | ZM-exec-2026@ |
| Executive Admin Zimbabwe | Zimbabwe | executive.zimbabwe@hosi.academy | Executive Admin | ZW-exec-2026@ |
| HR Admin Botswana | Botswana | hr.botswana@hosi.academy | HR Admin | BW-hr-2026@ |
| HR Admin Kenya | Kenya | hr.kenya@hosi.academy | HR Admin | KE-hr-2026@ |
| HR Admin Zambia | Zambia | hr.zambia@hosi.academy | HR Admin | ZM-hr-2026@ |
| HR Admin Zimbabwe | Zimbabwe | hr.zimbabwe@hosi.academy | HR Admin | ZW-hr-2026@ |
| Payment Admin Botswana | Botswana | payments.botswana@hosi.academy | Payment Admin | BW-payment-2026@ |
| Payment Admin Kenya | Kenya | payments.kenya@hosi.academy | Payment Admin | KE-payment-2026@ |
| Payment Admin Zambia | Zambia | payments.zambia@hosi.academy | Payment Admin | ZM-payment-2026@ |
| Payment Admin Zimbabwe | Zimbabwe | payments.zimbabwe@hosi.academy | Payment Admin | ZW-payment-2026@ |
| Lohn Banda | Zimbabwe | lohn.banda@hosiacademy.co.za | Instructor | Instructor@2026! |
| Takawira Mazando | Zimbabwe | takawira.mazando@hosiacademy.co.za | Instructor | Instructor@2026! |
| Tariro Moyo | Zimbabwe | tariro.moyo.zimbabwe@learner.hosiacademy.co.za | Student | Student@2026! |
| Wanjiru Omondi | Kenya | wanjiru.omondi.kenya@learner.hosiacademy.co.za | Student | Student@2026! |
| Thabo Dlamini | South Africa | thabo.dlamini.southafrica@learner.hosiacademy.co.za | Student | Student@2026! |
| Chanda Mwanza | Zambia | chanda.mwanza.zambia@learner.hosiacademy.co.za | Student | Student@2026! |
| Mulenga Phiri | Zambia | mulenga.phiri.zambia@learner.hosiacademy.co.za | Student | Student@2026! |
| Student 1 Botswana | Botswana | student1.botswana@test.hosi.academy | Student | Student@2026! |
| Student 2 Botswana | Botswana | student2.botswana@test.hosi.academy | Student | Student@2026! |
| Student 3 Botswana | Botswana | student3.botswana@test.hosi.academy | Student | Student@2026! |
| Student 1 Kenya | Kenya | student1.kenya@test.hosi.academy | Student | Student@2026! |
| Student 2 Kenya | Kenya | student2.kenya@test.hosi.academy | Student | Student@2026! |
| Student 3 Kenya | Kenya | student3.kenya@test.hosi.academy | Student | Student@2026! |
| Student 1 Zambia | Zambia | student1.zambia@test.hosi.academy | Student | Student@2026! |
| Student 2 Zambia | Zambia | student2.zambia@test.hosi.academy | Student | Student@2026! |
| Student 3 Zambia | Zambia | student3.zambia@test.hosi.academy | Student | Student@2026! |
| Student 1 Zimbabwe | Zimbabwe | student1.zimbabwe@test.hosi.academy | Student | Student@2026! |
| Student 2 Zimbabwe | Zimbabwe | student2.zimbabwe@test.hosi.academy | Student | Student@2026! |
| Student 3 Zimbabwe | Zimbabwe | student3.zimbabwe@test.hosi.academy | Student | Student@2026! |
| Admin Test | All | admin@example.com | Student | Admin123! |

---

## Quick Reference by Role

| Role | Count | Email Pattern | Password |
|------|-------|---------------|----------|
| Django Superadmin | 1 | `system.admin@hosi.academy` | `System@Hosi2026!` |
| Executive Admin | 4 | `executive.<country>@hosi.academy` | `<CC>-exec-2026@` |
| HR Admin | 4 | `hr.<country>@hosi.academy` | `<CC>-hr-2026@` |
| Payment Admin | 4 | `payments.<country>@hosi.academy` | `<CC>-payment-2026@` |
| Instructor | 2 | `<name>@hosiacademy.co.za` | `Instructor@2026!` |
| Student | 18 | Varies | `Student@2026!` (or `Admin123!` for admin@example.com) |

**Country Codes:** KE=Kenya, ZW=Zimbabwe, ZM=Zambia, BW=Botswana

---

## Quick Reference by Country

| Country | Users |
|---------|-------|
| **All Countries** | system.admin@hosi.academy, admin@example.com |
| **Kenya** | executive.kenya, hr.kenya, payments.kenya, wanjiru.omondi, student1-3.kenya (7 total) |
| **Zimbabwe** | executive.zimbabwe, hr.zimbabwe, payments.zimbabwe, lohn.banda, takawira.mazando, tariro.moyo, student1-3.zimbabwe (9 total) |
| **Zambia** | executive.zambia, hr.zambia, payments.zambia, chanda.mwanza, mulenga.phiri, student1-3.zambia (9 total) |
| **Botswana** | executive.botswana, hr.botswana, payments.botswana, student1-3.botswana (7 total) |
| **South Africa** | thabo.dlamini (1 total) |

---

## Password Reset Command

```bash
cd /home/tk/lms-prod/backend && source venv_linux/bin/activate
python manage.py changepassword <email>
```
