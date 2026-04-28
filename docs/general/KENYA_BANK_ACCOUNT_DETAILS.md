# KENYA BANK ACCOUNT DETAILS - UPDATED

## Company Information
**Account Name:** HOSI TECHNOLOGIES KENYA LIMITED

---

## 🏦 Bank Accounts

### 1. KES Account (Primary - Kenyan Shilling)
| Field | Details |
|-------|---------|
| **Bank** | Kenya Commercial Bank (KCB) |
| **Account Name** | HOSI TECHNOLOGIES KENYA LIMITED |
| **Account Number** | 05808133206350 |
| **Branch Code** | 01100 |
| **Account Type** | Current Account |
| **Currency** | KES (Kenyan Shilling) |
| **Default** | Yes |
| **Priority** | 1 |

### 2. USD Account (US Dollar)
| Field | Details |
|-------|---------|
| **Bank** | Kenya Commercial Bank (KCB) |
| **Account Name** | HOSI TECHNOLOGIES KENYA LIMITED |
| **Account Number** | 05808133201250 |
| **Branch Code** | 01100 |
| **Account Type** | Current Account |
| **Currency** | USD (US Dollar) |
| **Default** | No |
| **Priority** | 2 |

### 3. M-Pesa Paybill (Mobile Money)
| Field | Details |
|-------|---------|
| **Service** | M-Pesa (Safaricom) |
| **Paybill Number** | 542542 |
| **Account Name** | HOSI TECHNOLOGIES KENYA LIMITED |
| **Account Number** | 542542 |
| **Currency** | KES (Kenyan Shilling) |
| **Default** | No |
| **Priority** | 3 |

---

## 💳 Payment Instructions for Customers

### Bank Transfer (EFT)
1. **Log in** to your banking app
2. **Add beneficiary**: HOSI TECHNOLOGIES KENYA LIMITED
3. **Select bank**: Kenya Commercial Bank (KCB)
4. **Enter account number**: 
   - KES: `05808133206350`
   - USD: `05808133201250`
5. **Enter amount** in KES or USD
6. **Use reference**: Your enrollment reference number
7. **Complete transfer**

### M-Pesa Payment
1. Go to **M-Pesa Menu**
2. Select **Lipa Na M-Pesa**
3. Select **Paybill**
4. Enter **Business Number**: `542542`
5. Enter **Account Number**: Your enrollment reference
6. Enter **Amount**
7. Enter **PIN** and send

---

## 📋 Files Updated

| File | Purpose |
|------|---------|
| `backend/setup_company_bank_accounts.py` | Django setup script |
| `backend/create_company_bank_accounts_sql.py` | Direct SQL setup |
| `backend/update_kenya_bank_accounts.py` | Update script (run to apply changes) |

---

## 🚀 Deployment

### Option 1: Run Django Script
```bash
cd /home/tk/lms-prod/backend
python update_kenya_bank_accounts.py
```

### Option 2: Run SQL Script
```bash
cd /home/tk/lms-prod/backend
python create_company_bank_accounts_sql.py
```

### Option 3: Django Management Command
```bash
cd /home/tk/lms-prod/backend
python manage.py shell < setup_company_bank_accounts.py
```

---

## ✅ Verification

After running the update script, verify the accounts:

```bash
cd /home/tk/lms-prod/backend
python manage.py shell
```

```python
from apps.payments.models import CompanyBankAccount, AfricanCountry

kenya = AfricanCountry.objects.get(code='KE')
accounts = CompanyBankAccount.objects.filter(country=kenya, is_active=True)

for acc in accounts:
    print(f"Bank: {acc.bank_name}")
    print(f"Account: {acc.account_number}")
    print(f"Name: {acc.account_name}")
    print(f"Currency: {acc.currency}")
    print("---")
```

---

## 📞 Contact Information

**HOSI TECHNOLOGIES KENYA LIMITED**
- **Location**: Kenya
- **Bank**: Kenya Commercial Bank (KCB)
- **M-Pesa Paybill**: 542542

---

**Date:** March 16, 2026
**Status:** ✅ UPDATED
