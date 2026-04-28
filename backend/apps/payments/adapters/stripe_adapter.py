# apps/payments/adapters/stripe_adapter.py
import stripe
import hashlib
import hmac
from typing import Dict, Any, List
from django.conf import settings
from django.utils import timezone
from .base import BasePaymentAdapter, PaymentError, SignatureVerificationError
from ..models import PaymentProvider, PaymentMethod, Currency


class StripeAdapter(BasePaymentAdapter):
    """
    Stripe payment adapter - International coverage
    Documentation: https://stripe.com/docs/api
    """

    PROVIDER_NAME = "Stripe"
    PROVIDER_CODE = PaymentProvider.STRIPE

    # Stripe supports 135+ currencies, listing most relevant for Africa
    SUPPORTED_CURRENCIES = [
        Currency.USD, Currency.EUR, Currency.GBP,
        Currency.ZAR, Currency.NGN, Currency.GHS,
        Currency.KES, Currency.TZS, Currency.UGX,
        Currency.EGP, Currency.MAD, Currency.TND,
    ]

    # Stripe operates globally
    SUPPORTED_COUNTRIES = [
        'NG', 'ZA', 'KE', 'GH', 'EG', 'MA', 'TN', 'TZ', 'UG',
        'US', 'GB', 'CA', 'AU', 'DE', 'FR', 'IT', 'ES',
        # + 130 more countries
    ]

    def __init__(self, provider_config=None):
        super().__init__(provider_config)
        stripe.api_key = self._get_secret_key()
        stripe.api_version = '2023-10-16'

    def _get_secret_key(self) -> str:
        """Get Stripe secret key"""
        if self.config and self.config.secret_key:
            return self.config.secret_key
        return getattr(settings, 'STRIPE_SECRET_KEY', '')

    def _get_public_key(self) -> str:
        """Get Stripe publishable key"""
        if self.config and self.config.api_key:
            return self.config.api_key
        return getattr(settings, 'STRIPE_PUBLIC_KEY', '')

    def _is_sandbox(self) -> bool:
        """Check if using test mode"""
        secret_key = self._get_secret_key()
        return secret_key.startswith('sk_test_')

    def get_supported_countries(self) -> List[str]:
        """Stripe supports 46+ countries"""
        return self.SUPPORTED_COUNTRIES

    def get_supported_currencies(self) -> List[str]:
        """Stripe supports 135+ currencies"""
        return [str(c) for c in self.SUPPORTED_CURRENCIES]

    def get_supported_methods(self) -> List[str]:
        """Stripe supports multiple payment methods"""
        return [
            'card',
            'bank_transfer',
            'wallet',  # Apple Pay, Google Pay
            'sepa_debit',
            'ideal',
            'giropay',
            'eps',
            'p24',
            'bancontact',
        ]

    def initiate_payment(self, transaction, callback_url: str, **kwargs) -> Dict[str, Any]:
        """
        Initiate Stripe payment using Payment Intents API
        Documentation: https://stripe.com/docs/api/payment_intents
        """
        try:
            # Convert amount to smallest currency unit (cents)
            amount_in_cents = self._to_minor_unit(
                float(transaction.amount),
                transaction.currency
            )

            user = transaction.user
            email = getattr(user, 'email', None) or kwargs.get('email') or transaction.metadata.get('email') or transaction.metadata.get('learner_email')
            
            # Create payment intent
            payment_intent = stripe.PaymentIntent.create(
                amount=amount_in_cents,
                currency=transaction.currency.lower(),
                payment_method_types=self._get_payment_method_types(
                    transaction.country,
                    kwargs.get('payment_method')
                ),
                metadata={
                    'transaction_id': str(transaction.id),
                    'user_id': str(user.id) if user else 'guest',
                    'order_id': transaction.metadata.get('order_id', ''),
                    'country': transaction.country,
                    'is_guest': user is None
                },
                description=transaction.description[:500] if transaction.description else f"Payment Ref: {transaction.provider_reference}",
                receipt_email=email,
                return_url=callback_url,
                confirm=False,  # Don't auto-confirm, let frontend handle
            )

            # Store payment intent ID in transaction metadata
            transaction.metadata['stripe_payment_intent_id'] = payment_intent.id
            transaction.metadata['stripe_client_secret'] = payment_intent.client_secret
            transaction.save()

            self.logger.info(f"Stripe payment intent created: {payment_intent.id}")

            return {
                'payment_intent_id': payment_intent.id,
                'client_secret': payment_intent.client_secret,
                'provider_reference': payment_intent.id,
                'requires_redirect': False,  # Use Stripe.js on frontend
                'requires_confirmation': True,
                'public_key': self._get_public_key(),
                'provider_data': payment_intent,
            }

        except stripe.error.CardError as e:
            # Card declined
            self.logger.error(f"Stripe card error: {str(e)}")
            raise PaymentError(f"Card declined: {e.user_message}")

        except stripe.error.RateLimitError as e:
            # Too many requests
            self.logger.error(f"Stripe rate limit error: {str(e)}")
            raise PaymentError("Too many requests. Please try again later.")

        except stripe.error.InvalidRequestError as e:
            # Invalid parameters
            self.logger.error(f"Stripe invalid request: {str(e)}")
            raise PaymentError(f"Invalid payment request: {str(e)}")

        except stripe.error.AuthenticationError as e:
            # Authentication failed
            self.logger.error(f"Stripe authentication error: {str(e)}")
            raise PaymentError("Payment provider authentication failed")

        except stripe.error.APIConnectionError as e:
            # Network error
            self.logger.error(f"Stripe connection error: {str(e)}")
            raise PaymentError("Connection to payment provider failed")

        except stripe.error.StripeError as e:
            # Generic Stripe error
            self.logger.error(f"Stripe error: {str(e)}")
            raise PaymentError(f"Payment processing failed: {str(e)}")

        except Exception as e:
            # Unknown error
            self.logger.error(f"Unexpected error: {str(e)}", exc_info=True)
            raise PaymentError(f"Payment failed: {str(e)}")

    def _get_payment_method_types(self, country: str, method: str = None) -> List[str]:
        """Get Stripe payment method types based on country and method"""
        # Default to card
        if not method or method == 'card':
            return ['card']

        # Map our methods to Stripe payment method types
        method_mapping = {
            'card': ['card'],
            'bank_transfer': ['sepa_debit', 'us_bank_account'],
            'wallet': ['card'],  # Apple Pay, Google Pay work through card type
            'sepa_debit': ['sepa_debit'],
            'ideal': ['ideal'],
            'giropay': ['giropay'],
        }

        return method_mapping.get(method, ['card'])

    def _to_minor_unit(self, amount: float, currency: str) -> int:
        """
        Convert amount to smallest currency unit
        Most currencies use 2 decimal places (cents)
        Some currencies have 0 decimal places (JPY, KRW)
        """
        zero_decimal_currencies = ['BIF', 'CLP', 'DJF', 'GNF', 'JPY', 'KMF', 'KRW',
                                   'MGA', 'PYG', 'RWF', 'UGX', 'VND', 'VUV', 'XAF',
                                   'XOF', 'XPF']

        if currency.upper() in zero_decimal_currencies:
            return int(amount)
        else:
            return int(amount * 100)

    def _from_minor_unit(self, amount: int, currency: str) -> float:
        """Convert from smallest currency unit to major unit"""
        zero_decimal_currencies = ['BIF', 'CLP', 'DJF', 'GNF', 'JPY', 'KMF', 'KRW',
                                   'MGA', 'PYG', 'RWF', 'UGX', 'VND', 'VUV', 'XAF',
                                   'XOF', 'XPF']

        if currency.upper() in zero_decimal_currencies:
            return float(amount)
        else:
            return float(amount) / 100

    def verify_payment(self, reference: str) -> Dict[str, Any]:
        """
        Verify payment with Stripe
        Documentation: https://stripe.com/docs/api/payment_intents/retrieve
        """
        try:
            # Retrieve payment intent
            payment_intent = stripe.PaymentIntent.retrieve(reference)

            # Map Stripe status to our status
            status_mapping = {
                'succeeded': 'successful',
                'processing': 'pending',
                'requires_payment_method': 'pending',
                'requires_confirmation': 'pending',
                'requires_action': 'pending',
                'requires_capture': 'pending',
                'canceled': 'cancelled',
                'failed': 'failed',
            }

            status = status_mapping.get(payment_intent.status, 'pending')

            return {
                'status': status,
                'amount': self._from_minor_unit(payment_intent.amount, payment_intent.currency),
                'currency': payment_intent.currency.upper(),
                'reference': payment_intent.id,
                'confirmed_at': self._timestamp_to_iso(payment_intent.created),
                'provider_data': payment_intent,
            }

        except stripe.error.InvalidRequestError as e:
            self.logger.error(f"Stripe verification error: {str(e)}")
            raise PaymentError(f"Payment not found: {str(e)}")

        except stripe.error.StripeError as e:
            self.logger.error(f"Stripe error during verification: {str(e)}")
            raise PaymentError(f"Verification failed: {str(e)}")

    def refund_payment(self, transaction, amount: float = None, reason: str = "") -> Dict[str, Any]:
        """
        Process refund with Stripe
        Documentation: https://stripe.com/docs/api/refunds
        """
        try:
            # Get payment intent ID from transaction metadata
            payment_intent_id = transaction.metadata.get('stripe_payment_intent_id')

            if not payment_intent_id:
                raise PaymentError("Payment intent ID not found")

            # Convert refund amount to cents
            refund_amount = amount or float(transaction.amount)
            refund_cents = self._to_minor_unit(refund_amount, transaction.currency)

            # Create refund
            refund = stripe.Refund.create(
                payment_intent=payment_intent_id,
                amount=refund_cents,
                reason=self._map_refund_reason(reason),
                metadata={
                    'transaction_id': str(transaction.id),
                    'reason': reason,
                }
            )

            self.logger.info(f"Stripe refund created: {refund.id}")

            return {
                'status': 'success' if refund.status == 'succeeded' else 'pending',
                'refund_id': refund.id,
                'amount': self._from_minor_unit(refund.amount, refund.currency),
                'message': f"Refund {refund.status}",
                'provider_data': refund,
            }

        except stripe.error.InvalidRequestError as e:
            self.logger.error(f"Stripe refund error: {str(e)}")
            raise PaymentError(f"Refund failed: {str(e)}")

        except stripe.error.StripeError as e:
            self.logger.error(f"Stripe error during refund: {str(e)}")
            raise PaymentError(f"Refund processing failed: {str(e)}")

    def _map_refund_reason(self, reason: str) -> str:
        """Map our refund reason to Stripe's reasons"""
        reason_lower = reason.lower()

        if 'duplicate' in reason_lower:
            return 'duplicate'
        elif 'fraud' in reason_lower:
            return 'fraudulent'
        else:
            return 'requested_by_customer'

    def verify_webhook_signature(self, payload: bytes, headers: Dict[str, str]) -> bool:
        """
        Verify Stripe webhook signature
        Documentation: https://stripe.com/docs/webhooks/signatures
        """
        try:
            # Get signature from headers
            sig_header = headers.get('HTTP_STRIPE_SIGNATURE') or headers.get('Stripe-Signature')

            if not sig_header:
                self.logger.warning("No Stripe signature found in headers")
                return False

            # Get webhook secret
            webhook_secret = getattr(settings, 'STRIPE_WEBHOOK_SECRET', '')

            if not webhook_secret:
                self.logger.warning("No Stripe webhook secret configured")
                return True  # Skip verification in dev mode

            # Verify signature using Stripe's built-in method
            try:
                stripe.Webhook.construct_event(
                    payload, sig_header, webhook_secret
                )
                return True

            except stripe.error.SignatureVerificationError:
                self.logger.warning("Stripe webhook signature verification failed")
                return False

        except Exception as e:
            self.logger.error(f"Webhook signature verification error: {str(e)}")
            return False

    def parse_webhook(self, payload: Dict[str, Any]) -> Dict[str, Any]:
        """
        Parse Stripe webhook payload
        Documentation: https://stripe.com/docs/api/events
        """
        event_type = payload.get('type', '')
        data = payload.get('data', {}).get('object', {})

        # Map Stripe events to standard events
        event_mapping = {
            'payment_intent.succeeded': 'payment.success',
            'payment_intent.payment_failed': 'payment.failed',
            'payment_intent.canceled': 'payment.cancelled',
            'charge.refunded': 'refund.processed',
            'charge.succeeded': 'payment.success',
            'charge.failed': 'payment.failed',
        }

        # Get payment intent or charge data
        payment_intent_id = data.get('id', '')
        amount = data.get('amount', 0)
        currency = data.get('currency', 'usd')
        status = data.get('status', '')

        # Map Stripe status
        status_mapping = {
            'succeeded': 'successful',
            'failed': 'failed',
            'canceled': 'cancelled',
            'pending': 'pending',
        }

        return {
            'event': event_mapping.get(event_type, event_type),
            'reference': payment_intent_id,
            'status': status_mapping.get(status, 'pending'),
            'amount': self._from_minor_unit(amount, currency),
            'currency': currency.upper(),
            'method': 'card',  # Stripe doesn't specify in webhook
            'timestamp': self._timestamp_to_iso(data.get('created', 0)),
            'provider_data': payload,
        }

    def _timestamp_to_iso(self, timestamp: int) -> str:
        """Convert Unix timestamp to ISO format"""
        if timestamp:
            from datetime import datetime
            return datetime.fromtimestamp(timestamp).isoformat()
        return timezone.now().isoformat()

    def get_provider_name(self) -> str:
        return self.PROVIDER_NAME

    def get_provider_code(self) -> str:
        return self.PROVIDER_CODE
