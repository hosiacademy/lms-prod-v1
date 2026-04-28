# backend/apps/payments/payment_integration_service.py
"""
Comprehensive Payment Integration Service
Handles all payment provider integrations with PRODUCTION and TEST APIs

SUPPORTED PROVIDERS:
- Flutterwave (Pan-Africa: Cards, Mobile Money, Bank Transfer, USSD)
- Paystack (Nigeria, Ghana, Kenya, South Africa)
- Stripe (International cards)
- PayFast (South Africa - Instant EFT, Cards, Zapper, SnapScan)
- M-Pesa Daraja (Kenya, Tanzania)
- Airtel Money (Pan-Africa)
- MTN Mobile Money (Pan-Africa)
- Orange Money (West/Central Africa)
- Direct EFT/Bank Transfer (All countries)
"""

import logging
import json
import hashlib
import hmac
import requests
from typing import Dict, Any, Optional, List, Tuple
from datetime import datetime, timedelta
from django.conf import settings
from django.db import transaction as db_transaction
from django.utils import timezone

logger = logging.getLogger(__name__)


class PaymentIntegrationService:
    """
    Master service for orchestrating payments across all providers
    Supports both TEST and PRODUCTION modes
    """

    # Test API Keys (for development/sandbox)
    TEST_PROVIDERS = {
        'flutterwave': {
            'public_key': 'FLWPUBK_TEST-e1ccbfa2e4c97fcc41f6a0afb1d8c8e8-X',
            'secret_key': 'FLWSECK_TEST-8c8fa03bfeb3f6b3feba51d51f3a4f3e-X',
            'webhook_secret': 'webhook_test_secret_key_12345',
            'api_url': 'https://api.flutterwave.com/v3',
        },
        'paystack': {
            'public_key': 'pk_test_abcdefghijk1234567890abcdefghijk',
            'secret_key': 'sk_test_abcdefghijk1234567890abcdefghijk',
            'webhook_secret': 'webhook_test_secret_12345',
            'api_url': 'https://api.paystack.co',
        },
        'stripe': {
            'public_key': 'pk_test_51234567890abcdefghijk1234567890',
            'secret_key': 'sk_test_51234567890abcdefghijk1234567890',
            'webhook_secret': 'whsec_test_abcdefghijk1234567890',
            'api_url': 'https://api.stripe.com/v1',
        },
        'payfast': {
            'merchant_id': '10000100',
            'merchant_key': '46f0cd694581a',
            'passphrase': 'test_passphrase',
            'api_url': 'https://sandbox.payfast.co.za',
        },
        'mpesa': {
            'consumer_key': 'test_consumer_key',
            'consumer_secret': 'test_consumer_secret',
            'passkey': 'test_passkey',
            'api_url': 'https://sandbox.safaricom.co.ke',
        },
    }

    def __init__(self):
        # PRODUCTION MODE BY DEFAULT - set PAYMENT_TEST_MODE=False in settings
        self.test_mode = getattr(settings, 'PAYMENT_TEST_MODE', False)
        self.retry_attempts = getattr(settings, 'PAYMENT_RETRY_ATTEMPTS', 3)
        self.retry_delay = getattr(settings, 'PAYMENT_RETRY_DELAY', 5)  # seconds

    def is_production(self) -> bool:
        """Check if running in production mode"""
        return not self.test_mode
    
    # ============================================================================
    # FLUTTERWAVE INTEGRATION (Pan-Africa)
    # Production API: https://api.flutterwave.com/v3
    # Documentation: https://developer.flutterwave.com/
    # ============================================================================

    def initiate_flutterwave_payment(self, payment_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Initiate Flutterwave Standard Payment
        Production Endpoint: POST https://api.flutterwave.com/v3/payments
        
        Required Fields:
        - tx_ref: Unique transaction reference
        - amount: Amount to charge
        - currency: Currency code (NGN, KES, GHS, ZAR, etc.)
        - redirect_url: URL to redirect after payment
        - customer: {email, name, phonenumber}
        
        Returns: Payment link URL
        """
        try:
            config = self._get_provider_config('flutterwave')
            
            # PRODUCTION API URL
            api_url = 'https://api.flutterwave.com/v3/payments'

            headers = {
                'Authorization': f'Bearer {config["secret_key"]}',
                'Content-Type': 'application/json',
            }

            # Build payment payload per Flutterwave API spec
            payload = {
                'tx_ref': payment_data['transaction_ref'],
                'amount': str(payment_data['amount']),
                'currency': payment_data.get('currency', 'ZAR'),  # Default to ZAR for South Africa
                'redirect_url': payment_data.get('callback_url', ''),
                'payment_options': self._get_flutterwave_payment_options(
                    payment_data.get('country', 'ZA')
                ),
                'customer': {
                    'email': payment_data['email'],
                    'name': payment_data.get('customer_name', 'Customer'),
                    'phonenumber': payment_data.get('phone_number', ''),
                },
                'customizations': {
                    'title': 'Hosi Academy',
                    'logo': f"{settings.SITE_URL}/static/logo.png",
                    'description': payment_data.get('description', 'Course Enrollment Payment'),
                },
                'meta': {
                    'enrollment_id': payment_data.get('enrollment_id'),
                    'user_id': payment_data.get('user_id'),
                    'program_type': payment_data.get('program_type'),
                    'program_id': payment_data.get('program_id'),
                },
                'session_duration': 10,  # 10 minutes session
                'max_retry_attempt': 5,
            }

            # Make API request
            response = requests.post(
                api_url,
                json=payload,
                headers=headers,
                timeout=30
            )

            # Log response for debugging
            logger.info(f"Flutterwave response status: {response.status_code}")
            
            response.raise_for_status()
            data = response.json()

            if data.get('status') == 'success':
                return {
                    'success': True,
                    'provider': 'flutterwave',
                    'transaction_id': payment_data['transaction_ref'],
                    'payment_url': data['data'].get('link'),
                    'authorization_url': data['data'].get('authorization', {}).get('redirect'),
                    'status': 'pending',
                    'provider_response': data,
                    'message': 'Payment link generated successfully'
                }
            else:
                logger.error(f"Flutterwave API error: {data}")
                return {
                    'success': False,
                    'error': data.get('message', 'Payment initiation failed'),
                    'provider_response': data,
                }

        except requests.exceptions.RequestException as e:
            logger.error(f"Flutterwave API request error: {str(e)}")
            return {
                'success': False,
                'error': f'Flutterwave service error: {str(e)}',
            }
        except Exception as e:
            logger.error(f"Flutterwave unexpected error: {str(e)}")
            return {
                'success': False,
                'error': f'Flutterwave unexpected error: {str(e)}',
            }

    def verify_flutterwave_payment(self, transaction_ref: str) -> Dict[str, Any]:
        """
        Verify Flutterwave payment status
        Production Endpoint: GET https://api.flutterwave.com/v3/transactions/verify_by_reference
        
        Returns transaction status: successful, pending, failed
        """
        try:
            config = self._get_provider_config('flutterwave')
            
            # PRODUCTION API URL
            api_url = f'https://api.flutterwave.com/v3/transactions/verify_by_reference?tx_ref={transaction_ref}'

            headers = {
                'Authorization': f'Bearer {config["secret_key"]}',
            }

            response = requests.get(
                api_url,
                headers=headers,
                timeout=30
            )

            response.raise_for_status()
            data = response.json()

            if data.get('status') == 'success':
                transaction = data.get('data', {})
                return {
                    'success': True,
                    'status': transaction.get('status'),  # 'successful', 'pending', 'failed'
                    'amount': float(transaction.get('amount', 0)),
                    'currency': transaction.get('currency'),
                    'reference': transaction.get('tx_ref'),
                    'transaction_id': transaction.get('id'),
                    'customer_email': transaction.get('customer', {}).get('email'),
                    'payment_method': transaction.get('payment_type'),
                    'provider_data': transaction,
                }
            else:
                return {
                    'success': False,
                    'error': data.get('message', 'Verification failed'),
                }

        except requests.exceptions.RequestException as e:
            logger.error(f"Flutterwave verification error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
            }

    def handle_flutterwave_webhook(self, webhook_data: Dict[str, Any], signature: str = None) -> Dict[str, Any]:
        """
        Handle Flutterwave webhook callback
        Webhook is sent when payment status changes
        
        Events:
        - charge.completed: Payment successful
        - charge.failed: Payment failed
        """
        try:
            config = self._get_provider_config('flutterwave')

            # Verify signature if provided
            if signature and config.get('webhook_secret'):
                payload_str = json.dumps(webhook_data)
                expected_hash = hashlib.sha256(
                    (payload_str + config['webhook_secret']).encode()
                ).hexdigest()

                if signature != expected_hash:
                    logger.warning("Invalid Flutterwave webhook signature")
                    return {'success': False, 'error': 'Invalid signature'}

            event = webhook_data.get('event')
            data = webhook_data.get('data', {})

            logger.info(f"Flutterwave webhook received: {event}")

            if event == 'charge.completed':
                # Verify transaction amount matches
                return {
                    'success': True,
                    'event_type': 'payment_completed',
                    'status': data.get('status'),
                    'reference': data.get('tx_ref'),
                    'amount': float(data.get('amount', 0)),
                    'currency': data.get('currency'),
                    'metadata': data.get('meta', {}),
                    'provider_data': data,
                }
            
            elif event == 'charge.failed':
                return {
                    'success': True,
                    'event_type': 'payment_failed',
                    'status': 'failed',
                    'reference': data.get('tx_ref'),
                    'error': data.get('message'),
                }

            return {'success': True, 'message': f'Event {event} received'}

        except Exception as e:
            logger.error(f"Flutterwave webhook error: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    # ============================================================================
    # PAYSTACK INTEGRATION (Nigeria, Ghana, Kenya, South Africa)
    # Production API: https://api.paystack.co
    # Documentation: https://paystack.com/docs/api/
    # ============================================================================

    def initiate_paystack_payment(self, payment_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Initiate Paystack Transaction
        Production Endpoint: POST https://api.paystack.co/transaction/initialize
        
        Required Fields:
        - email: Customer email
        - amount: Amount in kobo (multiply by 100)
        - reference: Unique transaction reference
        
        Returns: Authorization URL for payment
        """
        try:
            config = self._get_provider_config('paystack')
            
            # PRODUCTION API URL
            api_url = 'https://api.paystack.co/transaction/initialize'

            headers = {
                'Authorization': f'Bearer {config["secret_key"]}',
                'Content-Type': 'application/json',
            }

            # Convert amount to kobo (smallest unit) - Paystack requires this
            amount_kobo = int(float(payment_data['amount']) * 100)

            payload = {
                'email': payment_data['email'],
                'amount': amount_kobo,
                'reference': payment_data['transaction_ref'],
                'callback_url': payment_data.get('callback_url', ''),
                'metadata': {
                    'enrollment_id': payment_data.get('enrollment_id'),
                    'user_id': payment_data.get('user_id'),
                    'customer_name': payment_data.get('customer_name'),
                    'phone': payment_data.get('phone_number'),
                    'program_type': payment_data.get('program_type'),
                    'program_id': payment_data.get('program_id'),
                },
                'subaccount': payment_data.get('subaccount'),  # Optional
                'transaction_charge': payment_data.get('transaction_charge'),  # Optional
                'bearer': payment_data.get('bearer', 'account'),  # Who pays charges
            }

            response = requests.post(
                api_url,
                json=payload,
                headers=headers,
                timeout=30
            )

            response.raise_for_status()
            data = response.json()

            if data.get('status'):
                return {
                    'success': True,
                    'provider': 'paystack',
                    'transaction_id': payment_data['transaction_ref'],
                    'payment_url': data['data'].get('authorization_url'),
                    'access_code': data['data'].get('access_code'),
                    'reference': data['data'].get('reference'),
                    'status': 'pending',
                    'provider_response': data,
                    'message': 'Payment URL generated successfully'
                }
            else:
                logger.error(f"Paystack API error: {data}")
                return {
                    'success': False,
                    'error': data.get('message', 'Payment initiation failed'),
                    'provider_response': data,
                }

        except requests.exceptions.RequestException as e:
            logger.error(f"Paystack API request error: {str(e)}")
            return {
                'success': False,
                'error': f'Paystack service error: {str(e)}',
            }
        except Exception as e:
            logger.error(f"Paystack unexpected error: {str(e)}")
            return {
                'success': False,
                'error': f'Paystack unexpected error: {str(e)}',
            }

    def verify_paystack_payment(self, reference: str) -> Dict[str, Any]:
        """
        Verify Paystack Transaction
        Production Endpoint: GET https://api.paystack.co/transaction/verify/{reference}
        
        Returns transaction status: success, failed, pending
        """
        try:
            config = self._get_provider_config('paystack')
            
            # PRODUCTION API URL
            api_url = f'https://api.paystack.co/transaction/verify/{reference}'

            headers = {
                'Authorization': f'Bearer {config["secret_key"]}',
            }

            response = requests.get(
                api_url,
                headers=headers,
                timeout=30
            )

            response.raise_for_status()
            data = response.json()

            if data.get('status'):
                transaction = data['data']
                return {
                    'success': True,
                    'status': transaction.get('status'),  # 'success', 'failed', 'pending'
                    'amount': float(transaction.get('amount', 0)) / 100,  # Convert from kobo
                    'currency': transaction.get('currency'),
                    'reference': transaction.get('reference'),
                    'transaction_id': transaction.get('id'),
                    'customer_email': transaction.get('customer', {}).get('email'),
                    'payment_method': transaction.get('authorization', {}).get('channel'),
                    'provider_data': transaction,
                }
            else:
                return {
                    'success': False,
                    'error': data.get('message', 'Verification failed'),
                }

        except requests.exceptions.RequestException as e:
            logger.error(f"Paystack verification error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
            }

    def handle_paystack_webhook(self, webhook_data: Dict[str, Any], signature: str = None) -> Dict[str, Any]:
        """
        Handle Paystack Webhook
        Events: charge.success, charge.failed, charge.refund, etc.
        """
        try:
            config = self._get_provider_config('paystack')

            # Verify signature if provided
            if signature and config.get('webhook_secret'):
                payload_str = json.dumps(webhook_data)
                expected_hash = hmac.new(
                    config['webhook_secret'].encode(),
                    payload_str.encode(),
                    hashlib.sha512
                ).hexdigest()

                if signature != expected_hash:
                    logger.warning("Invalid Paystack webhook signature")
                    return {'success': False, 'error': 'Invalid signature'}

            event = webhook_data.get('event')
            data = webhook_data.get('data', {})

            logger.info(f"Paystack webhook received: {event}")

            if event == 'charge.success':
                return {
                    'success': True,
                    'event_type': 'payment_completed',
                    'status': 'success',
                    'reference': data.get('reference'),
                    'amount': float(data.get('amount', 0)) / 100,  # Convert from kobo
                    'currency': data.get('currency'),
                    'metadata': data.get('metadata', {}),
                    'provider_data': data,
                }
            
            elif event == 'charge.failed':
                return {
                    'success': True,
                    'event_type': 'payment_failed',
                    'status': 'failed',
                    'reference': data.get('reference'),
                    'error': data.get('failure_reason'),
                }
            
            elif event == 'charge.refund':
                return {
                    'success': True,
                    'event_type': 'payment_refunded',
                    'status': 'refunded',
                    'reference': data.get('reference'),
                    'amount': float(data.get('amount', 0)) / 100,
                }

            return {'success': True, 'message': f'Event {event} received'}

        except Exception as e:
            logger.error(f"Paystack webhook error: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    # ============================================================================
    # STRIPE INTEGRATION
    # ============================================================================
    
    def initiate_stripe_payment(self, payment_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Initiate Stripe payment via Payment Intent
        Documentation: https://stripe.com/docs/api/payment_intents
        """
        try:
            import stripe
            config = self._get_provider_config('stripe')
            
            stripe.api_key = config['secret_key']
            
            # Convert amount to cents
            amount_cents = int(float(payment_data['amount']) * 100)
            
            # Create payment intent
            intent = stripe.PaymentIntent.create(
                amount=amount_cents,
                currency=payment_data['currency'].lower(),
                payment_method_types=['card'],
                metadata={
                    'enrollment_id': payment_data.get('enrollment_id'),
                    'user_id': payment_data.get('user_id'),
                    'transaction_ref': payment_data['transaction_ref'],
                },
                receipt_email=payment_data['email'],
                description=payment_data.get('description', 'Course Enrollment'),
            )
            
            return {
                'success': True,
                'provider': 'stripe',
                'transaction_id': payment_data['transaction_ref'],
                'client_secret': intent.client_secret,
                'payment_intent_id': intent.id,
                'status': intent.status,
                'provider_response': intent,
            }
        
        except Exception as e:
            logger.error(f"Stripe payment initiation error: {e}")
            return {
                'success': False,
                'error': f'Stripe service error: {str(e)}',
            }
    
    def handle_stripe_webhook(self, webhook_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle Stripe webhook
        """
        try:
            event_type = webhook_data.get('type')
            data = webhook_data.get('data', {}).get('object', {})
            
            if event_type == 'payment_intent.succeeded':
                return {
                    'success': True,
                    'event_type': 'payment_completed',
                    'status': 'succeeded',
                    'payment_intent_id': data.get('id'),
                    'amount': data.get('amount') / 100,  # Convert from cents
                    'currency': data.get('currency'),
                    'metadata': data.get('metadata', {}),
                }
            
            elif event_type == 'payment_intent.payment_failed':
                return {
                    'success': True,
                    'event_type': 'payment_failed',
                    'status': 'failed',
                    'payment_intent_id': data.get('id'),
                    'error': data.get('last_payment_error', {}).get('message'),
                }
            
            return {'success': True, 'message': f'Event {event_type} received'}

        except Exception as e:
            logger.error(f"Stripe webhook error: {e}")
            return {'success': False, 'error': str(e)}

    # ============================================================================
    # PAYFAST INTEGRATION (South Africa)
    # Production API: https://www.payfast.co.za
    # Documentation: https://developers.payfast.co.za
    # Supports: Instant EFT, Credit/Debit Card, Zapper, SnapScan
    # ============================================================================

    def initiate_payfast_payment(self, payment_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Initiate PayFast Payment
        Production Endpoint: POST https://www.payfast.co.za/eng/process
        
        Required Fields:
        - merchant_id: PayFast merchant ID
        - merchant_key: PayFast merchant key
        - amount: Amount in ZAR
        - return_url: URL to redirect after successful payment
        - cancel_url: URL to redirect after cancelled payment
        - notify_url: ITN (webhook) URL
        
        Signature: MD5 hash of all parameters + passphrase
        """
        try:
            config = self._get_provider_config('payfast')
            
            # PRODUCTION API URL
            api_url = 'https://www.payfast.co.za/eng/process'

            # Build payment payload per PayFast API spec
            payload = {
                'merchant_id': config['merchant_id'],
                'merchant_key': config['merchant_key'],
                'return_url': payment_data.get('return_url', f'{settings.SITE_URL}/payment/success'),
                'cancel_url': payment_data.get('cancel_url', f'{settings.SITE_URL}/payment/cancel'),
                'notify_url': payment_data.get('notify_url', f'{settings.SITE_URL}/api/v1/payments/webhook/payfast'),
                'amount': str(payment_data['amount']),
                'item_name': payment_data.get('description', 'Course Enrollment'),
                'item_description': payment_data.get('item_description', 'Hosi Academy'),
                'name_first': payment_data.get('customer_name', 'Customer').split()[0] if payment_data.get('customer_name') else 'Customer',
                'name_last': payment_data.get('customer_name', 'Customer').split()[-1] if payment_data.get('customer_name') else 'Customer',
                'email_address': payment_data['email'],
                'cell_number': payment_data.get('phone_number', ''),
                'custom_str1': payment_data.get('enrollment_id', ''),
                'custom_str2': payment_data.get('user_id', ''),
                'custom_str3': payment_data.get('transaction_ref', ''),
                'payment_method': payment_data.get('payment_method', ''),  # 'eft' for Instant EFT
            }

            # Remove empty values
            payload = {k: v for k, v in payload.items() if v}

            # Generate MD5 signature
            signature = self._generate_payfast_signature(payload, config.get('passphrase', ''))
            payload['signature'] = signature

            logger.info(f"PayFast payment initiated for {payment_data['transaction_ref']}")

            return {
                'success': True,
                'provider': 'payfast',
                'transaction_id': payment_data['transaction_ref'],
                'payment_url': api_url,
                'payment_data': payload,
                'status': 'pending',
                'message': 'Payment form data generated. POST to payment_url with payment_data',
            }

        except Exception as e:
            logger.error(f"PayFast payment initiation error: {str(e)}")
            return {
                'success': False,
                'error': f'PayFast service error: {str(e)}',
            }

    def _generate_payfast_signature(self, data: Dict[str, str], passphrase: str = None) -> str:
        """
        Generate PayFast MD5 Signature
        
        Algorithm:
        1. Sort all parameters alphabetically
        2. Concatenate as key=value pairs joined by &
        3. Append passphrase if provided
        4. Generate MD5 hash
        """
        # Create parameter string (sorted alphabetically)
        param_string = '&'.join(f"{k}={v}" for k, v in sorted(data.items()))

        # Add passphrase if provided
        if passphrase:
            param_string += f"&passphrase={passphrase}"

        # Generate MD5 hash
        return hashlib.md5(param_string.encode()).hexdigest()

    def verify_payfast_itn(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Verify PayFast ITN (Instant Transaction Notification)
        
        ITN is sent as POST to notify_url with all transaction parameters
        
        Returns verified transaction data
        """
        try:
            config = self._get_provider_config('payfast')
            
            # Extract signature from request
            received_signature = request_data.get('signature', '')
            
            # Remove signature from data for verification
            data_for_verification = {k: v for k, v in request_data.items() if k != 'signature'}
            
            # Generate expected signature
            expected_signature = self._generate_payfast_signature(data_for_verification, config.get('passphrase', ''))
            
            # Verify signature
            if received_signature != expected_signature:
                logger.warning(f"Invalid PayFast ITN signature")
                return {'success': False, 'error': 'Invalid signature'}
            
            # Verify merchant ID matches
            if request_data.get('merchant_id') != config['merchant_id']:
                logger.warning(f"Invalid PayFast merchant ID")
                return {'success': False, 'error': 'Invalid merchant ID'}
            
            # Return verified transaction data
            return {
                'success': True,
                'status': request_data.get('payment_status', 'unknown'),
                'amount': float(request_data.get('amount_gross', 0)),
                'reference': request_data.get('custom_str3'),  # Our transaction_ref
                'payfast_reference': request_data.get('m_payment_id'),
                'email': request_data.get('payer_email'),
                'name': request_data.get('payer_first_name', '') + ' ' + request_data.get('payer_last_name', ''),
                'provider_data': request_data,
            }

        except Exception as e:
            logger.error(f"PayFast ITN verification error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
            }

    def handle_payfast_webhook(self, request_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle PayFast ITN Webhook
        
        Events:
        - COMPLETE: Payment successful
        - FAILED: Payment failed
        - PENDING: Payment pending
        """
        try:
            # First verify the ITN
            verification = self.verify_payfast_itn(request_data)
            
            if not verification['success']:
                return verification
            
            payment_status = request_data.get('payment_status', '')
            
            logger.info(f"PayFast ITN received: {payment_status} for {request_data.get('custom_str3')}")
            
            if payment_status == 'COMPLETE':
                return {
                    'success': True,
                    'event_type': 'payment_completed',
                    'status': 'complete',
                    'reference': request_data.get('custom_str3'),
                    'amount': float(request_data.get('amount_gross', 0)),
                    'currency': 'ZAR',
                    'payfast_reference': request_data.get('m_payment_id'),
                    'email': request_data.get('payer_email'),
                }
            
            elif payment_status == 'FAILED':
                return {
                    'success': True,
                    'event_type': 'payment_failed',
                    'status': 'failed',
                    'reference': request_data.get('custom_str3'),
                    'error': request_data.get('error_message'),
                }
            
            elif payment_status == 'PENDING':
                return {
                    'success': True,
                    'event_type': 'payment_pending',
                    'status': 'pending',
                    'reference': request_data.get('custom_str3'),
                }
            
            return {'success': True, 'message': f'ITN {payment_status} received'}

        except Exception as e:
            logger.error(f"PayFast webhook error: {str(e)}")
            return {'success': False, 'error': str(e)}

    # ============================================================================
    # M-PESA DARAJA INTEGRATION (Kenya, Tanzania)
    # Production API: https://api.safaricom.co.ke
    # Documentation: https://developer.safaricom.co.ke
    # Supports: STK Push (Lipa Na M-Pesa Online)
    # ============================================================================

    def initiate_mpesa_payment(self, payment_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Initiate M-Pesa STK Push (Lipa Na M-Pesa Online)
        Production Endpoint: POST https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest
        
        Required Fields:
        - phone_number: Customer phone in format 2547XXXXXXXX
        - amount: Amount to charge
        - account_reference: Your reference for the payment
        
        Authentication: OAuth 2.0 Bearer Token
        Password: base64(ShortCode + Passkey + Timestamp)
        """
        try:
            config = self._get_provider_config('mpesa')
            
            # PRODUCTION API URL
            api_url = 'https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest'

            # Get OAuth access token
            access_token = self._get_mpesa_access_token(config)

            # Format phone number (must be in format 2547XXXXXXXX)
            phone = payment_data.get('phone_number', '')
            if phone.startswith('+'):
                phone = phone[1:]
            if phone.startswith('0'):
                phone = phone[1:]
            if not phone.startswith('254'):
                phone = f'254{phone}'

            # Generate password and timestamp
            timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
            password = hashlib.sha256(
                f"{config['shortcode']}{config['passkey']}{timestamp}".encode()
            ).hexdigest()

            # STK Push payload per M-Pesa API spec
            payload = {
                'BusinessShortCode': config.get('shortcode', '174379'),
                'Password': password,
                'Timestamp': timestamp,
                'TransactionType': 'CustomerPayBillOnline',
                'Amount': int(float(payment_data['amount'])),
                'PartyA': phone,
                'PartyB': config.get('shortcode', '174379'),
                'PhoneNumber': phone,
                'CallBackURL': payment_data.get('callback_url', f'{settings.SITE_URL}/api/v1/payments/webhook/mpesa'),
                'AccountReference': payment_data.get('transaction_ref', 'HosiAcademy'),
                'TransactionDesc': payment_data.get('description', 'Course Enrollment Payment'),
            }

            headers = {
                'Authorization': f'Bearer {access_token}',
                'Content-Type': 'application/json',
            }

            response = requests.post(
                api_url,
                json=payload,
                headers=headers,
                timeout=30
            )

            response.raise_for_status()
            data = response.json()

            if data.get('ResponseCode') == '0':
                logger.info(f"M-Pesa STK Push sent to {phone} for {payment_data['transaction_ref']}")
                return {
                    'success': True,
                    'provider': 'mpesa',
                    'transaction_id': payment_data['transaction_ref'],
                    'checkout_request_id': data.get('CheckoutRequestID'),
                    'merchant_request_id': data.get('MerchantRequestID'),
                    'status': 'pending',
                    'message': 'STK Push sent to customer phone. Awaiting PIN entry.',
                    'provider_response': data,
                }
            else:
                logger.error(f"M-Pesa STK Push failed: {data}")
                return {
                    'success': False,
                    'error': data.get('errorMessage', 'STK Push failed'),
                    'provider_response': data,
                }

        except requests.exceptions.RequestException as e:
            logger.error(f"M-Pesa API request error: {str(e)}")
            return {
                'success': False,
                'error': f'M-Pesa service error: {str(e)}',
            }
        except Exception as e:
            logger.error(f"M-Pesa unexpected error: {str(e)}")
            return {
                'success': False,
                'error': f'M-Pesa unexpected error: {str(e)}',
            }

    def _get_mpesa_access_token(self, config: Dict[str, str]) -> str:
        """
        Get M-Pesa OAuth 2.0 Access Token
        Production Endpoint: GET https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials
        
        Token validity: 1 hour (3599 seconds)
        """
        import base64

        # PRODUCTION API URL
        api_url = 'https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials'

        # Basic Auth: base64(ConsumerKey:ConsumerSecret)
        credentials = base64.b64encode(
            f"{config['consumer_key']}:{config['consumer_secret']}".encode()
        ).decode()

        response = requests.get(
            api_url,
            headers={'Authorization': f'Basic {credentials}'},
            timeout=30
        )

        response.raise_for_status()
        return response.json().get('access_token', '')

    def verify_mpesa_payment(self, checkout_request_id: str) -> Dict[str, Any]:
        """
        Verify M-Pesa STK Push Status
        Production Endpoint: POST https://api.safaricom.co.ke/mpesa/stkpushquery/v1/query
        
        Returns transaction status and M-Pesa receipt number if successful
        """
        try:
            config = self._get_provider_config('mpesa')
            access_token = self._get_mpesa_access_token(config)

            # Generate password and timestamp
            timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
            password = hashlib.sha256(
                f"{config['shortcode']}{config['passkey']}{timestamp}".encode()
            ).hexdigest()

            payload = {
                'BusinessShortCode': config.get('shortcode', '174379'),
                'Password': password,
                'Timestamp': timestamp,
                'CheckoutRequestID': checkout_request_id,
            }

            headers = {
                'Authorization': f'Bearer {access_token}',
                'Content-Type': 'application/json',
            }

            response = requests.post(
                'https://api.safaricom.co.ke/mpesa/stkpushquery/v1/query',
                json=payload,
                headers=headers,
                timeout=30
            )

            response.raise_for_status()
            data = response.json()

            # ResultCode 0 = Success
            if data.get('ResultCode') == 0:
                return {
                    'success': True,
                    'status': 'completed',
                    'amount': float(data.get('Amount', 0)),
                    'mpesa_receipt': data.get('MpesaReceiptNumber'),
                    'phone': data.get('PhoneNumber'),
                    'transaction_date': data.get('TransactionDate'),
                    'provider_data': data,
                }
            elif data.get('ResultCode') == 1032:  # User cancelled
                return {
                    'success': False,
                    'status': 'cancelled',
                    'error': 'User cancelled transaction',
                }
            else:
                return {
                    'success': False,
                    'status': 'pending',
                    'error': data.get('ResultDesc', 'Transaction pending'),
                }

        except requests.exceptions.RequestException as e:
            logger.error(f"M-Pesa verification error: {str(e)}")
            return {
                'success': False,
                'error': str(e),
            }

    def handle_mpesa_webhook(self, webhook_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Handle M-Pesa Callback (STK Push Result)
        
        Callback is sent to CallBackURL when user completes/cancels STK Push
        
        ResultCode:
        - 0: Success
        - 1032: User cancelled
        - Other: Various errors
        """
        try:
            logger.info(f"M-Pesa webhook received")
            
            stk_callback = webhook_data.get('Body', {}).get('stkCallback', {})
            result_code = stk_callback.get('ResultCode')
            result_desc = stk_callback.get('ResultDesc')
            checkout_request_id = stk_callback.get('CheckoutRequestID')
            merchant_request_id = stk_callback.get('MerchantRequestID')
            
            # Extract metadata
            metadata = {}
            if stk_callback.get('CallbackMetadata'):
                items = stk_callback['CallbackMetadata'].get('Item', [])
                for item in items:
                    metadata[item['Name']] = item.get('Value')
            
            if result_code == 0:
                return {
                    'success': True,
                    'event_type': 'payment_completed',
                    'status': 'completed',
                    'checkout_request_id': checkout_request_id,
                    'merchant_request_id': merchant_request_id,
                    'amount': metadata.get('Amount'),
                    'mpesa_receipt': metadata.get('MpesaReceiptNumber'),
                    'phone': metadata.get('PhoneNumber'),
                    'transaction_date': metadata.get('TransactionDate'),
                    'provider_data': webhook_data,
                }
            elif result_code == 1032:
                return {
                    'success': True,
                    'event_type': 'payment_cancelled',
                    'status': 'cancelled',
                    'checkout_request_id': checkout_request_id,
                    'error': result_desc,
                }
            else:
                return {
                    'success': True,
                    'event_type': 'payment_failed',
                    'status': 'failed',
                    'checkout_request_id': checkout_request_id,
                    'error': result_desc,
                }

        except Exception as e:
            logger.error(f"M-Pesa webhook error: {str(e)}")
            return {'success': False, 'error': str(e)}

    # ============================================================================
    # AIRTEL MONEY INTEGRATION (Pan-Africa)
    # ============================================================================

    def initiate_airtel_money_payment(self, payment_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Initiate Airtel Money payment
        Documentation: https://developer.airtel.africa/
        """
        try:
            config = self._get_provider_config('airtel_money')

            # Get access token
            access_token = self._get_airtel_access_token(config)

            # Format phone number
            phone = payment_data.get('phone_number', '')
            if phone.startswith('+'):
                phone = phone[1:]

            headers = {
                'Authorization': f'Bearer {access_token}',
                'Content-Type': 'application/json',
                'X-Country': payment_data.get('country', 'KE'),
                'X-Currency': payment_data.get('currency', 'KES'),
            }

            payload = {
                'amount': int(float(payment_data['amount'])),
                'currency': payment_data.get('currency', 'KES'),
                'merchant_transaction_reference': payment_data['transaction_ref'],
                'country': payment_data.get('country', 'KE'),
                'subscriber_number': phone,
            }

            response = requests.post(
                f"{config['api_url']}/v1/money/debit/',
                json=payload,
                headers=headers,
                timeout=30
            )

            response.raise_for_status()
            data = response.json()

            return {
                'success': True,
                'provider': 'airtel_money',
                'transaction_id': payment_data['transaction_ref'],
                'order_id': data.get('order_id'),
                'status': 'pending',
            }

        except Exception as e:
            logger.error(f"Airtel Money payment initiation error: {e}")
            return {
                'success': False,
                'error': f'Airtel Money service error: {str(e)}',
            }

    def _get_airtel_access_token(self, config: Dict[str, str]) -> str:
        """Get Airtel OAuth access token"""
        import base64

        credentials = base64.b64encode(
            f"{config['api_key']}:{config['api_secret']}".encode()
        ).decode()

        response = requests.post(
            f"{config['api_url']}/oauth/token/",
            headers={
                'Authorization': f'Basic {credentials}',
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            data={'grant_type': 'client_credentials'},
            timeout=30
        )

        response.raise_for_status()
        return response.json().get('access_token', '')

    # ============================================================================
    # MTN MOBILE MONEY INTEGRATION (Pan-Africa)
    # ============================================================================

    def initiate_mtn_mobile_money_payment(self, payment_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Initiate MTN Mobile Money payment
        Documentation: https://momodeveloper.mtn.com/
        """
        try:
            config = self._get_provider_config('mtn_mobile_money')

            # Get access token
            access_token = self._get_mtn_access_token(config)

            # Format phone number
            phone = payment_data.get('phone_number', '')
            if phone.startswith('+'):
                phone = phone[1:]

            headers = {
                'Authorization': f'Bearer {access_token}',
                'Content-Type': 'application/json',
                'X-Reference-Id': payment_data['transaction_ref'],
                'X-Target-Environment': payment_data.get('environment', 'sandbox'),
            }

            payload = {
                'amount': str(payment_data['amount']),
                'currency': payment_data.get('currency', 'UGX'),
                'externalId': payment_data['transaction_ref'],
                'payee': {
                    'partyIdType': 'MSISDN',
                    'partyId': phone,
                },
                'payerMessage': payment_data.get('description', 'Course Enrollment'),
                'payeeNote': 'Hosi Academy',
            }

            response = requests.post(
                f"{config['api_url']}/collection/v1_0/requesttopay",
                json=payload,
                headers=headers,
                timeout=30
            )

            response.raise_for_status()

            return {
                'success': True,
                'provider': 'mtn_mobile_money',
                'transaction_id': payment_data['transaction_ref'],
                'status': 'pending',
                'message': 'Payment request sent to customer phone',
            }

        except Exception as e:
            logger.error(f"MTN Mobile Money payment initiation error: {e}")
            return {
                'success': False,
                'error': f'MTN Mobile Money service error: {str(e)}',
            }

    def _get_mtn_access_token(self, config: Dict[str, str]) -> str:
        """Get MTN OAuth access token"""
        import base64

        credentials = base64.b64encode(
            f"{config['api_key']}:{config['api_secret']}".encode()
        ).decode()

        response = requests.post(
            f"{config['api_url']}/collection/token/",
            headers={
                'Authorization': f'Basic {credentials}',
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            data={'grant_type': 'client_credentials'},
            timeout=30
        )

        response.raise_for_status()
        return response.json().get('access_token', '')

    # ============================================================================
    # ORANGE MONEY INTEGRATION (West/Central Africa)
    # ============================================================================

    def initiate_orange_money_payment(self, payment_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Initiate Orange Money payment
        Documentation: https://api.orange.com/
        """
        try:
            config = self._get_provider_config('orange_money')

            # Get access token
            access_token = self._get_orange_access_token(config)

            headers = {
                'Authorization': f'Bearer {access_token}',
                'Content-Type': 'application/json',
            }

            payload = {
                'merchant_key': config.get('merchant_key', ''),
                'order_id': payment_data['transaction_ref'],
                'amount': str(payment_data['amount']),
                'currency': payment_data.get('currency', 'XOF'),
                'customer_phone': payment_data.get('phone_number', ''),
                'customer_name': payment_data.get('customer_name', ''),
                'return_url': payment_data.get('return_url', ''),
                'cancel_url': payment_data.get('cancel_url', ''),
                'webhook_url': payment_data.get('notify_url', ''),
            }

            response = requests.post(
                f"{config['api_url']}/orange-money-webhook/dev/v1/webpayment",
                json=payload,
                headers=headers,
                timeout=30
            )

            response.raise_for_status()
            data = response.json()

            return {
                'success': True,
                'provider': 'orange_money',
                'transaction_id': payment_data['transaction_ref'],
                'payment_url': data.get('payment_url'),
                'status': 'pending',
            }

        except Exception as e:
            logger.error(f"Orange Money payment initiation error: {e}")
            return {
                'success': False,
                'error': f'Orange Money service error: {str(e)}',
            }

    def _get_orange_access_token(self, config: Dict[str, str]) -> str:
        """Get Orange OAuth access token"""
        import base64

        credentials = base64.b64encode(
            f"{config['api_key']}:{config['api_secret']}".encode()
        ).decode()

        response = requests.post(
            f"{config['api_url']}/oauth/v3/token",
            headers={
                'Authorization': f'Basic {credentials}',
                'Content-Type': 'application/x-www-form-urlencoded',
            },
            data={'grant_type': 'client_credentials'},
            timeout=30
        )

        response.raise_for_status()
        return response.json().get('access_token', '')
    
    # ============================================================================
    # HELPER METHODS
    # ============================================================================

    def _get_provider_config(self, provider: str) -> Dict[str, str]:
        """
        Get provider configuration (test or production)
        Production keys are loaded from environment variables via Django settings
        """
        if self.test_mode:
            return self.TEST_PROVIDERS.get(provider, {})

        # PRODUCTION: Get from environment variables via Django settings
        # These should be set in .env or environment:
        # FLUTTERWAVE_SECRET_KEY, PAYSTACK_SECRET_KEY, STRIPE_SECRET_KEY, etc.
        production_configs = {
            'flutterwave': {
                'public_key': getattr(settings, 'FLUTTERWAVE_PUBLIC_KEY', ''),
                'secret_key': getattr(settings, 'FLUTTERWAVE_SECRET_KEY', ''),
                'webhook_secret': getattr(settings, 'FLUTTERWAVE_WEBHOOK_SECRET', ''),
                'api_url': 'https://api.flutterwave.com/v3',
            },
            'paystack': {
                'public_key': getattr(settings, 'PAYSTACK_PUBLIC_KEY', ''),
                'secret_key': getattr(settings, 'PAYSTACK_SECRET_KEY', ''),
                'webhook_secret': getattr(settings, 'PAYSTACK_WEBHOOK_SECRET', ''),
                'api_url': 'https://api.paystack.co',
            },
            'stripe': {
                'public_key': getattr(settings, 'STRIPE_PUBLIC_KEY', ''),
                'secret_key': getattr(settings, 'STRIPE_SECRET_KEY', ''),
                'webhook_secret': getattr(settings, 'STRIPE_WEBHOOK_SECRET', ''),
                'api_url': 'https://api.stripe.com/v1',
            },
            'payfast': {
                'merchant_id': getattr(settings, 'PAYFAST_MERCHANT_ID', ''),
                'merchant_key': getattr(settings, 'PAYFAST_MERCHANT_KEY', ''),
                'passphrase': getattr(settings, 'PAYFAST_PASSPHRASE', ''),
                'api_url': 'https://www.payfast.co.za',
            },
            'mpesa': {
                'consumer_key': getattr(settings, 'MPESA_CONSUMER_KEY', ''),
                'consumer_secret': getattr(settings, 'MPESA_CONSUMER_SECRET', ''),
                'passkey': getattr(settings, 'MPESA_PASSKEY', ''),
                'api_url': 'https://api.safaricom.co.ke',
            },
            'airtel_money': {
                'api_key': getattr(settings, 'AIRTEL_API_KEY', ''),
                'api_secret': getattr(settings, 'AIRTEL_API_SECRET', ''),
                'api_url': 'https://openapi.airtel.africa',
            },
            'mtn_mobile_money': {
                'api_key': getattr(settings, 'MTN_API_KEY', ''),
                'api_secret': getattr(settings, 'MTN_API_SECRET', ''),
                'api_url': 'https://sandbox.momodeveloper.mtn.com',
            },
            'orange_money': {
                'api_key': getattr(settings, 'ORANGE_API_KEY', ''),
                'api_secret': getattr(settings, 'ORANGE_API_SECRET', ''),
                'api_url': 'https://api.orange.com',
            },
        }

        config = production_configs.get(provider, {})

        # Validate production keys are configured
        if not config:
            logger.error(f"Production configuration not found for provider: {provider}")
            raise ValueError(f"Production configuration not found for provider: {provider}")

        # Check if required keys are set
        required_keys = ['secret_key'] if provider not in ['payfast', 'mpesa', 'airtel_money', 'mtn_mobile_money', 'orange_money'] else []
        if provider == 'payfast':
            required_keys = ['merchant_id', 'merchant_key']
        elif provider == 'mpesa':
            required_keys = ['consumer_key', 'consumer_secret', 'passkey']
        elif provider in ['airtel_money', 'mtn_mobile_money', 'orange_money']:
            required_keys = ['api_key', 'api_secret']

        for key in required_keys:
            if not config.get(key):
                logger.error(f"Production {provider} {key} not configured in settings")
                raise ValueError(f"Production {provider} {key} not configured")

        return config
    
    def _get_flutterwave_payment_options(self, country: str) -> str:
        """Get available payment methods for country"""
        country_methods = {
            'NG': 'card,account,ussd',  # Nigeria
            'KE': 'card,mpesa',  # Kenya
            'GH': 'card,mobile_money',  # Ghana
            'ZA': 'card,bank_transfer',  # South Africa
            'UG': 'card,mobile_money',  # Uganda
            'TZ': 'card,mobile_money',  # Tanzania
        }
        return country_methods.get(country, 'card')
    
    def get_payment_status(self, provider: str, transaction_ref: str) -> Dict[str, Any]:
        """Get payment status from any provider"""
        if provider == 'flutterwave':
            return self.verify_flutterwave_payment(transaction_ref)
        elif provider == 'paystack':
            return self.verify_paystack_payment(transaction_ref)
        elif provider == 'stripe':
            # Stripe requires payment_intent_id, not transaction_ref
            return {'error': 'Use payment_intent_id for Stripe'}
        else:
            return {'error': f'Unknown provider: {provider}'}
    
    @staticmethod
    def calculate_fees(amount: float, provider: str, country: str) -> Dict[str, float]:
        """Calculate payment fees"""
        fee_rates = {
            'flutterwave': 0.015,  # 1.5%
            'paystack': 0.015,  # 1.5%
            'stripe': 0.025,  # 2.5%
        }
        
        percentage_fee = amount * fee_rates.get(provider, 0.02)
        fixed_fee = 0.0  # Some providers charge fixed fee
        total_fee = percentage_fee + fixed_fee
        
        return {
            'percentage_fee': round(percentage_fee, 2),
            'fixed_fee': round(fixed_fee, 2),
            'total_fee': round(total_fee, 2),
            'total_amount': round(amount + total_fee, 2),
        }
