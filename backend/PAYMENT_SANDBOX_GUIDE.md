# Payment Provider Sandbox Guide

This guide provides information on how to test the various payment providers integrated into Hosi Academy LMS using their respective sandbox/test environments.

## General Configuration

Ensure your `.env` file has `PAYMENT_SANDBOX_MODE=True` (or `PAYMENT_TEST_MODE=True` depending on your version) and that you are using test API keys (usually prefixed with `pk_test_` or `sk_test_`).

---

## 1. Flutterwave (Pan-African)
**Dashboard**: [Flutterwave Dashboard](https://dashboard.flutterwave.com/)
**Sandbox Mode**: Set `FLUTTERWAVE_SANDBOX=True`.

### Test Cards
| Card Number | CVV | Expiry | PIN | OTP |
| :--- | :--- | :--- | :--- | :--- |
| `5531 8866 5214 2950` | `564` | `09/32` | `3310` | `12345` |
| `4000 0000 0000 0001` | `123` | `01/25` | `1234` | `12345` |

---

## 2. Paystack (Nigeria, Ghana, Kenya, South Africa)
**Dashboard**: [Paystack Dashboard](https://dashboard.paystack.com/)
**Sandbox Mode**: Set `PAYSTACK_SANDBOX=True`.

### Test Cards
| Scenario | Card Number | CVV | Expiry | OTP |
| :--- | :--- | :--- | :--- | :--- |
| **Success** | `4084 0840 8408 4081` | `408` | Any Future | `123456` |
| **Failed** | `5060 6666 6666 6666` | `123` | Any Future | N/A |

---

## 3. Safaricom M-Pesa (Kenya)
**Portal**: [Safaricom Developer Portal](https://developer.safaricom.co.ke/)
**Sandbox Mode**: Set `MPESA_SANDBOX=True`.

### Testing STK Push
Use the following test phone number to trigger a successful simulation:
- **Phone Number**: `254708374149`
- **PIN**: Any 4 digits (in sandbox simulation)

---

## 4. Paynow (Zimbabwe)
**Portal**: [Paynow Integration Guide](https://www.paynow.co.zw/Home/MasterGuide)
**Sandbox Mode**: Set `PAYNOW_SANDBOX=True`.

### Test Details
- **Email**: Any valid email.
- **EcoCash/OneMoney**: Use any Zimbabwean number like `0771234567`.
- **Note**: In sandbox, Paynow provides a "Simulate" button on their payment page to mock a successful payment.

---

## 5. MTN MoMo (Ghana, Uganda, Zambia, etc.)
**Portal**: [MTN MoMo Developer](https://momodeveloper.mtn.com/)
**Sandbox Mode**: Automatic when using `sandbox` environment.

### Test Phone Numbers
- **Ghana**: `233241234567`
- **Uganda**: `256771234567`
- **Zambia**: `260961234567`
- **Note**: Use the `X-Target-Environment` header (handled by adapter) to target `sandbox`.

---

## 6. Yoco (South Africa)
**Portal**: [Yoco Developer Portal](https://developer.yoco.com/)
**Sandbox Mode**: Uses `sk_test_...` key.

### Test Cards
- **Success**: Any Visa/Mastercard test card number from Stripe/Paystack often works, or use `4242 4242 4242 4242`.

---

## 7. Stripe (International)
**Dashboard**: [Stripe Dashboard](https://dashboard.stripe.com/)

### Test Cards
- **Success**: `4242 4242 4242 4242`
- **CVV**: Any 3 digits
- **Expiry**: Any future date

---

## Troubleshooting Webhooks

Since payment providers need to send notifications to your LMS, you need a public URL if testing locally. Use **ngrok** or **Localtunnel**:

1. Run ngrok: `ngrok http 8000`
2. Update your `.env`: `API_URL=https://your-ngrok-id.ngrok.io`
3. Ensure the webhook URL in the provider's dashboard matches: `https://your-ngrok-id.ngrok.io/api/payments/webhooks/[provider]/`
