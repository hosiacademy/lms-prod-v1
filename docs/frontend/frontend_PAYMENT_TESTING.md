# Payment System Testing Guide

## ⚠️ Important: Sandbox Configuration
The application is configured to use environment variables for payment keys to ensure security. 

**For Development/Testing:**
You must provide the `STRIPE_PK`, `PAYSTACK_PK`, and `FLUTTERWAVE_PK` environment variables when running the app if you want to test payments. 
If not provided, the app will use empty strings and payment initialization will likely fail or use the gateway's fallback if properly configured on their hosted page.

To run with test keys (example):
```bash
flutter run --dart-define=STRIPE_PK=pk_test_... --dart-define=PAYSTACK_PK=pk_test_... --dart-define=FLUTTERWAVE_PK=FLWPUBK_TEST-...
```

---

## 🌍 Pan-African Payment Testing
We support Paystack and Flutterwave which cover the majority of African countries.

### 🧪 Test Credentials
When in Sandbox/Test mode (using test keys), use the following credentials on the payment page.

#### 💳 Credit/Debit Cards
| Type | Card Number | Expiry | CVV | PIN/OTP |
|------|-------------|--------|-----|---------|
| **Mastercard (Success)** | `5531 8866 5214 2950` | Any Future (e.g. 12/30) | `123` | `3310` / `12345` |
| **Visa (Success)** | `4084 0840 8408 4081` | Any Future | `408` | `12345` |
| **Verve (Success)** | `5061 4604 1012 0223` | Any Future | `123` | `3310` |
| **Decline Test** | `4084 0800 0000 5408` | Any Future | `001` | - |

#### 📱 Mobile Money (M-Pesa / MTN / Airtel)
For mobile money, the phone number often determines the outcome in test mode.

| Country | Provider | Test Number | Outcome |
|---------|----------|-------------|---------|
| **Kenya (KE)** | M-Pesa | `0700 000 000` | ✅ Success |
| **Kenya (KE)** | M-Pesa | `0700 000 001` | ❌ Failure |
| **Ghana (GH)** | MTN/Voda | `055 123 4987` | ✅ Success |
| **Tanzania (TZ)** | Tigo/Airtel| `0780 000 000` | ✅ Success |
| **Uganda (UG)** | MTN/Airtel | `0770 000 000` | ✅ Success |
| **Zambia (ZM)** | MTN | `0960 000 000` | ✅ Success |

### 🏦 Bank Transfers (Nigeria)
- Select **Zenith Bank**
- Account Number: `0000000000`
- OTP: `12345`

---

## 🔄 Sandbox Flow
1. **Initiate Payment**: Click "Pay Now" in the app.
2. **Provider Page**: You will see the Paystack/Flutterwave test page.
3. **Enter Credentials**: Use the test numbers above.
4. **Validation**: The backend will poll for status.
   - If you complete payment successfully on the web page: App will verify and auto-close the modal.
   - If you cancel/fail: App will show error message.

## 🛠 Troubleshooting
- **"Invalid Key" Error**: Ensure you started the app with `--dart-define` keys or have them in your `.env` (if using dotenv).
- **Polling Timeout**: If verify dialog stays open, check usage of the "Authorize" button on the test page. Some test pages require you to click a specific "Authorize Test Payment" button.
