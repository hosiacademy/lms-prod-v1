import hashlib
import hmac
import requests
from django.conf import settings
from django.utils import timezone
from .base import BasePaymentAdapter, PaymentError


class SmatPayAdapter(BasePaymentAdapter):
    """SmatPay - Zimbabwe payment gateway (Visa, Mastercard, ZimSwitch)

    Zimbabwe only. Merchant API Key: 3X0NgDdl4J3xlcaQ9SHRz
    Docs: https://doc.smatpay.africa/doc-605225
    """

    LIVE_URL = "https://live.smatpay.africa"

    def _get_base_url(self):
        return self.LIVE_URL

    def _get_merchant_id(self):
        if self.config and getattr(self.config, 'merchant_id', None):
            return self.config.merchant_id
        return getattr(settings, 'SMATPAY_MERCHANT_ID', '')

    def _get_api_key(self):
        if self.config and getattr(self.config, 'api_key', None):
            return self.config.api_key
        return getattr(settings, 'SMATPAY_MERCHANT_API_KEY', '3X0NgDdl4J3xlcaQ9SHRz')

    def _get_merchant_key(self):
        # DB config stores merchantKey as secret_key
        if self.config and getattr(self.config, 'secret_key', None):
            return self.config.secret_key
        return getattr(settings, 'SMATPAY_MERCHANT_KEY', '')

    def _get_profile_id(self):
        # DB config stores profileId in metadata
        if self.config:
            meta = getattr(self.config, 'metadata', None) or {}
            if meta.get('profile_id'):
                return meta['profile_id']
        return getattr(settings, 'SMATPAY_PROFILE_ID', '')

    def _get_headers(self):
        return {"Content-Type": "application/json"}

    def get_supported_countries(self):
        # SmatPay supports Visa/Mastercard globally
        return ['*']

    def get_supported_currencies(self):
        # Support major African and global currencies
        return ['USD', 'ZAR', 'KES', 'GHS', 'NGN', 'ZMW', 'BWP', 'EUR', 'GBP']

    def get_supported_methods(self):
        return ['card', 'eft', 'mobile_money']

    def initiate_payment(self, transaction, callback_url: str, **kwargs):
        """Initiate a SmatPay card payment via /init/authenticate/merchant/wallet"""
        user = transaction.user
        email = (
            getattr(user, 'email', None)
            or transaction.individual_email
            or getattr(transaction.company, 'email', None)
            or ''
        )
        name = ''
        if user:
            name = user.get_full_name()
        if not name:
            name = transaction.individual_name or getattr(transaction.company, 'name', None) or ''

        amount = str(float(transaction.amount))
        currency = getattr(transaction, 'currency', 'USD') or 'USD'

        # Map payment_method kwarg to SmatPay walletName
        payment_method = kwargs.get('payment_method', 'Visa')
        wallet_map = {
            'visa': 'Visa',
            'mastercard': 'Mastercard',
            'zimswitch': 'ZimSwitch',
            'eft': 'ZimSwitch',
            'card': 'Visa',
        }
        wallet_name = wallet_map.get(str(payment_method).lower(), 'Visa')

        payer_account_id = getattr(user, 'id', 0) if user else 0

        profile_id_raw = self._get_profile_id()
        try:
            profile_id = int(profile_id_raw) if profile_id_raw else 0
        except (ValueError, TypeError):
            profile_id = 0

        payload = {
            "merchantId": str(self._get_merchant_id()),
            "merchantApiKey": self._get_api_key(),
            "merchantKey": self._get_merchant_key(),
            "walletName": wallet_name,
            "amount": amount,
            "paymentCurrency": currency,
            "paymentDescription": f"Hosi Academy - {transaction.provider_reference}",
            "payerName": name,
            "payerReference": transaction.provider_reference,
            "payerAccountId": payer_account_id,
            "profileId": profile_id,
        }

        try:
            response = requests.post(
                f"{self._get_base_url()}/init/authenticate/merchant/wallet",
                headers=self._get_headers(),
                json=payload,
                timeout=30,
            )
            response.raise_for_status()
            data = response.json()

            payment_resp = data.get('paymentInitiationResponse', {})
            status_code = str(payment_resp.get('status', ''))

            # SmatPay success codes start with '000'
            if status_code and not status_code.startswith('000'):
                auth_obj = data.get('auth', {}) or {}
                error_obj = auth_obj.get('errorResponse') or {}
                error_msg = (error_obj.get('errorMessage') if error_obj else None) or status_code
                raise PaymentError(f"SmatPay payment failed: {error_msg}")

            checkout_url = (
                payment_resp.get('checkOutRedirectUrl')
                or payment_resp.get('paymentToken')
            )
            provider_ref = (
                payment_resp.get('paymentId')
                or transaction.provider_reference
            )

            return {
                'status': 'pending',
                'checkout_url': checkout_url,
                'provider_reference': provider_ref,
                'requires_redirect': bool(checkout_url),
                'requires_mobile_approval': False,
                'provider_data': data,
            }

        except requests.exceptions.RequestException as e:
            raise PaymentError(f"SmatPay connection error: {str(e)}")

    def verify_payment(self, reference: str):
        """Verify payment status"""
        payload = {
            "merchantId": str(self._get_merchant_id()),
            "merchantApiKey": self._get_api_key(),
            "paymentId": reference,
        }
        try:
            response = requests.post(
                f"{self._get_base_url()}/api/v1/payments/status",
                headers=self._get_headers(),
                json=payload,
                timeout=30,
            )
            response.raise_for_status()
            data = response.json()

            raw_status = (
                data.get('status')
                or data.get('transactionStatus')
                or 'pending'
            )
            status = self._map_status(str(raw_status))

            return {
                'status': status,
                'amount': float(data.get('amount', 0)),
                'currency': data.get('currency', 'USD'),
                'reference': data.get('paymentId') or data.get('reference') or reference,
                'confirmed_at': data.get('completedAt') or data.get('paidAt'),
                'provider_data': data,
            }

        except requests.exceptions.RequestException as e:
            raise PaymentError(f"SmatPay verification failed: {str(e)}")

    def refund_payment(self, transaction, amount=None, reason=''):
        """Process refund"""
        payload = {
            "merchantId": str(self._get_merchant_id()),
            "merchantApiKey": self._get_api_key(),
            "transactionId": transaction.provider_reference,
            "amount": str(float(amount or transaction.amount)),
            "reason": reason,
        }

        try:
            response = requests.post(
                f"{self._get_base_url()}/api/v1/payments/refund",
                headers=self._get_headers(),
                json=payload,
                timeout=30,
            )
            response.raise_for_status()
            data = response.json()

            raw_status = data.get('status', '')
            status = 'successful' if self._map_status(str(raw_status)) == 'successful' else 'failed'

            return {
                'status': status,
                'refund_reference': data.get('refundId') or data.get('reference'),
                'provider_data': data,
            }

        except requests.exceptions.RequestException as e:
            raise PaymentError(f"SmatPay refund failed: {str(e)}")

    def verify_webhook_signature(self, payload, headers):
        """Verify SmatPay webhook HMAC signature"""
        merchant_key = self._get_merchant_key()
        if not merchant_key:
            return True  # No key configured — skip verification

        signature = headers.get('X-Smatpay-Signature', '') or headers.get('x-smatpay-signature', '')
        if not signature:
            return False

        if isinstance(payload, str):
            payload = payload.encode('utf-8')

        expected = hmac.new(
            merchant_key.encode('utf-8'),
            payload,
            hashlib.sha256,
        ).hexdigest()

        return hmac.compare_digest(expected, signature)

    def parse_webhook(self, payload):
        """Parse SmatPay webhook into standardized format"""
        event = payload.get('event') or payload.get('type') or 'payment.update'

        raw_status = (
            payload.get('status')
            or payload.get('transactionStatus')
            or 'pending'
        )
        status = self._map_status(str(raw_status))

        reference = (
            payload.get('reference')
            or payload.get('transactionId')
            or payload.get('merchantReference')
        )

        return {
            'event': event,
            'reference': reference,
            'status': status,
            'amount': float(payload.get('amount', 0)),
            'currency': payload.get('currency', 'USD'),
            'method': payload.get('paymentMethod') or payload.get('method'),
            'timestamp': payload.get('timestamp') or timezone.now().isoformat(),
            'provider_data': payload,
        }

    def get_provider_name(self):
        return "SmatPay"

    def get_provider_code(self):
        return "smatpay"
