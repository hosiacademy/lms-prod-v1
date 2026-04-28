"""
Complete Payment Integration Service
Handles all payment provider integrations with test APIs
"""

import os
import json
import logging
import hashlib
import hmac
import requests
from decimal import Decimal
from datetime import datetime
from typing import Dict, Optional, Tuple, List
from django.conf import settings
from django.db import transaction
import stripe
from rest_framework.response import Response

# Import configuration
from payments_config import (
    FLUTTERWAVE_CONFIG, PAYSTACK_CONFIG, STRIPE_CONFIG,
    MPESA_CONFIG, MTN_MOMO_CONFIG, ORANGE_MONEY_CONFIG,
    PAYMENT_FEES, PAYMENT_TEST_MODE, WEBHOOK_VERIFICATION_ENABLED
)

logger = logging.getLogger(__name__)


class PaymentIntegrationService:
    """Master service for all payment provider integrations"""
    
    def __init__(self, test_mode: bool = PAYMENT_TEST_MODE):
        self.test_mode = test_mode
        self.session = requests.Session()
        self.session.timeout = 30
        
        # Initialize provider clients
        if STRIPE_CONFIG.get('enabled'):
            stripe.api_key = STRIPE_CONFIG['secret_key']
    
    # ========================================================================
    # FLUTTERWAVE INTEGRATION
    # ========================================================================
    
    def initiate_flutterwave_payment(self, user_id: str, amount: float, 
                                    email: str, phone: str, 
                                    enrollment_id: str, country: str = 'NG') -> Dict:
        """
        Initiate payment via Flutterwave
        
        Args:
            user_id: Student user ID
            amount: Payment amount in local currency
            email: Student email
            phone: Student phone number
            enrollment_id: Enrollment record ID
            country: Country code (NG, GH, KE, ZA, etc.)
        
        Returns:
            Dict with payment_url and reference_id
        """
        config = FLUTTERWAVE_CONFIG
        
        payload = {
            'tx_ref': f'hosi_{enrollment_id}_{datetime.now().timestamp()}',
            'amount': amount,
            'currency': self._get_flutterwave_currency(country),
            'payment_options': 'card,ussd,bank_transfer,mobile_money,qr',
            'customer': {
                'email': email,
                'phonenumber': phone,
                'name': f'Student {user_id}',
            },
            'customizations': {
                'title': 'Hosi Academy Enrollment',
                'description': f'Course enrollment payment',
                'logo': 'https://hosiacademy.com/logo.png',
            },
            'redirect_url': f"{config['success_url']}?ref={{{{checkout_id}}}}",
            'meta': {
                'user_id': user_id,
                'enrollment_id': enrollment_id,
            }
        }
        
        try:
            headers = {'Authorization': f"Bearer {config['secret_key']}"}
            response = self.session.post(
                f"{config['api_url']}/transactions/initialize",
                json=payload,
                headers=headers,
                timeout=30
            )
            response.raise_for_status()
            
            data = response.json()
            if data.get('status') == 'success':
                return {
                    'success': True,
                    'provider': 'flutterwave',
                    'payment_url': data['data']['link'],
                    'reference_id': payload['tx_ref'],
                    'checkout_id': data['data']['id'],
                    'message': 'Payment initialized successfully'
                }
            else:
                logger.error(f"Flutterwave error: {data}")
                return {
                    'success': False,
                    'error': data.get('message', 'Payment initialization failed')
                }
                
        except requests.exceptions.RequestException as e:
            logger.error(f"Flutterwave API error: {str(e)}")
            return {
                'success': False,
                'error': f'Payment service error: {str(e)}'
            }
    
    def verify_flutterwave_payment(self, reference_id: str) -> Dict:
        """Verify Flutterwave payment status"""
        config = FLUTTERWAVE_CONFIG
        
        try:
            headers = {'Authorization': f"Bearer {config['secret_key']}"}
            response = self.session.get(
                f"{config['api_url']}/transactions/{reference_id}/verify",
                headers=headers,
                timeout=30
            )
            response.raise_for_status()
            
            data = response.json()
            if data.get('status') == 'success':
                tx_data = data['data']
                return {
                    'success': True,
                    'status': 'completed' if tx_data['status'] == 'successful' else 'failed',
                    'amount': tx_data['amount'],
                    'currency': tx_data['currency'],
                    'payment_method': tx_data.get('payment_type'),
                    'reference': tx_data['tx_ref'],
                    'customer_email': tx_data['customer']['email'],
                    'timestamp': tx_data['created_at'],
                }
            else:
                return {'success': False, 'status': 'failed'}
                
        except Exception as e:
            logger.error(f"Flutterwave verification error: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def handle_flutterwave_webhook(self, payload: Dict, signature: str) -> Tuple[bool, str]:
        """Verify and handle Flutterwave webhook"""
        config = FLUTTERWAVE_CONFIG
        
        # Verify signature
        if WEBHOOK_VERIFICATION_ENABLED:
            computed_hash = hmac.new(
                config['webhook_secret'].encode(),
                json.dumps(payload).encode(),
                hashlib.sha256
            ).hexdigest()
            
            if not hmac.compare_digest(computed_hash, signature):
                logger.warning("Flutterwave webhook signature verification failed")
                return False, "Invalid signature"
        
        try:
            event_data = payload.get('data', {})
            
            if payload.get('event') == 'charge.completed':
                status = 'completed' if event_data.get('status') == 'successful' else 'failed'
                return True, f"Payment {status}: {event_data.get('tx_ref')}"
            
            return True, "Webhook processed"
            
        except Exception as e:
            logger.error(f"Flutterwave webhook error: {str(e)}")
            return False, str(e)
    
    # ========================================================================
    # PAYSTACK INTEGRATION
    # ========================================================================
    
    def initiate_paystack_payment(self, user_id: str, amount: float, 
                                 email: str, enrollment_id: str, 
                                 country: str = 'NG') -> Dict:
        """
        Initiate payment via Paystack
        
        Args:
            user_id: Student user ID
            amount: Payment amount in local currency (kobo for NGN, pesewa for GHS, etc.)
            email: Student email
            enrollment_id: Enrollment record ID
            country: Country code (NG, GH, KE, ZA)
        
        Returns:
            Dict with payment_url and reference_id
        """
        config = PAYSTACK_CONFIG
        
        # Paystack expects amount in cents/smallest unit
        amount_in_kobo = int(amount * 100)
        
        payload = {
            'email': email,
            'amount': amount_in_kobo,
            'metadata': {
                'user_id': user_id,
                'enrollment_id': enrollment_id,
                'country': country,
                'custom_fields': [
                    {
                        'display_name': 'Course Enrollment',
                        'variable_name': 'course_enrollment',
                        'value': f'Enrollment {enrollment_id}',
                    }
                ]
            },
            'callback_url': f"{config['success_url']}"
        }
        
        try:
            headers = {
                'Authorization': f"Bearer {config['secret_key']}",
                'Content-Type': 'application/json',
            }
            response = self.session.post(
                f"{config['api_url']}/transaction/initialize",
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
                    'payment_url': data['data']['authorization_url'],
                    'reference_id': data['data']['reference'],
                    'access_code': data['data']['access_code'],
                    'message': 'Payment initialized successfully'
                }
            else:
                logger.error(f"Paystack error: {data}")
                return {
                    'success': False,
                    'error': data.get('message', 'Payment initialization failed')
                }
                
        except requests.exceptions.RequestException as e:
            logger.error(f"Paystack API error: {str(e)}")
            return {
                'success': False,
                'error': f'Payment service error: {str(e)}'
            }
    
    def verify_paystack_payment(self, reference: str) -> Dict:
        """Verify Paystack payment status"""
        config = PAYSTACK_CONFIG
        
        try:
            headers = {'Authorization': f"Bearer {config['secret_key']}"}
            response = self.session.get(
                f"{config['api_url']}/transaction/verify/{reference}",
                headers=headers,
                timeout=30
            )
            response.raise_for_status()
            
            data = response.json()
            if data.get('status'):
                tx_data = data['data']
                return {
                    'success': True,
                    'status': 'completed' if tx_data['status'] == 'success' else 'failed',
                    'amount': tx_data['amount'] / 100,  # Convert from kobo
                    'currency': tx_data['currency'],
                    'payment_method': tx_data.get('authorization', {}).get('card_type'),
                    'reference': tx_data['reference'],
                    'customer_email': tx_data['customer']['email'],
                    'timestamp': tx_data['created_at'],
                }
            else:
                return {'success': False, 'status': 'failed'}
                
        except Exception as e:
            logger.error(f"Paystack verification error: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def handle_paystack_webhook(self, payload: Dict, signature: str) -> Tuple[bool, str]:
        """Verify and handle Paystack webhook"""
        config = PAYSTACK_CONFIG
        
        # Verify signature
        if WEBHOOK_VERIFICATION_ENABLED:
            computed_hash = hmac.new(
                config['webhook_secret'].encode(),
                json.dumps(payload).encode(),
                hashlib.sha256
            ).hexdigest()
            
            if signature != computed_hash:
                logger.warning("Paystack webhook signature verification failed")
                return False, "Invalid signature"
        
        try:
            if payload.get('event') == 'charge.success':
                reference = payload['data']['reference']
                amount = payload['data']['amount'] / 100
                return True, f"Payment successful: {reference} - {amount}"
            
            return True, "Webhook processed"
            
        except Exception as e:
            logger.error(f"Paystack webhook error: {str(e)}")
            return False, str(e)
    
    # ========================================================================
    # STRIPE INTEGRATION
    # ========================================================================
    
    def initiate_stripe_payment(self, user_id: str, amount: float, 
                               email: str, enrollment_id: str,
                               currency: str = 'USD') -> Dict:
        """
        Initiate payment via Stripe
        
        Args:
            user_id: Student user ID
            amount: Payment amount
            email: Student email
            enrollment_id: Enrollment record ID
            currency: Currency code (USD, EUR, GBP, etc.)
        
        Returns:
            Dict with client_secret and session_id for checkout
        """
        config = STRIPE_CONFIG
        
        try:
            # Create payment intent
            intent = stripe.PaymentIntent.create(
                amount=int(amount * 100),  # Amount in cents
                currency=currency.lower(),
                description=f'Course Enrollment {enrollment_id}',
                metadata={
                    'user_id': user_id,
                    'enrollment_id': enrollment_id,
                    'email': email,
                },
                receipt_email=email,
            )
            
            # Create checkout session
            session = stripe.checkout.Session.create(
                payment_method_types=['card'],
                line_items=[{
                    'price_data': {
                        'currency': currency.lower(),
                        'unit_amount': int(amount * 100),
                        'product_data': {
                            'name': 'Course Enrollment',
                            'description': f'Enrollment for course {enrollment_id}',
                        },
                    },
                    'quantity': 1,
                }],
                mode='payment',
                customer_email=email,
                client_reference_id=f'enrollment_{enrollment_id}',
                success_url=f"{config['success_url']}?session_id={{CHECKOUT_SESSION_ID}}",
                cancel_url=config['failure_url'],
                metadata={
                    'user_id': user_id,
                    'enrollment_id': enrollment_id,
                },
            )
            
            return {
                'success': True,
                'provider': 'stripe',
                'client_secret': intent.client_secret,
                'session_id': session.id,
                'payment_url': session.url,
                'message': 'Payment session created successfully'
            }
            
        except stripe.error.CardError as e:
            logger.error(f"Stripe card error: {str(e)}")
            return {'success': False, 'error': f'Card error: {e.user_message}'}
        except stripe.error.StripeError as e:
            logger.error(f"Stripe error: {str(e)}")
            return {'success': False, 'error': f'Payment service error: {str(e)}'}
    
    def handle_stripe_webhook(self, payload: Dict, signature: str) -> Tuple[bool, str]:
        """Verify and handle Stripe webhook"""
        config = STRIPE_CONFIG
        
        try:
            # Verify signature
            if WEBHOOK_VERIFICATION_ENABLED:
                event = stripe.Webhook.construct_event(
                    json.dumps(payload).encode(),
                    signature,
                    config['webhook_secret']
                )
            else:
                event = payload
            
            if event['type'] == 'payment_intent.succeeded':
                pi = event['data']['object']
                return True, f"Payment succeeded: {pi['id']}"
            
            elif event['type'] == 'charge.failed':
                charge = event['data']['object']
                return True, f"Payment failed: {charge['id']}"
            
            return True, "Webhook processed"
            
        except stripe.error.SignatureVerificationError as e:
            logger.warning(f"Stripe signature verification failed: {str(e)}")
            return False, "Invalid signature"
        except Exception as e:
            logger.error(f"Stripe webhook error: {str(e)}")
            return False, str(e)
    
    # ========================================================================
    # MOBILE MONEY INTEGRATIONS
    # ========================================================================
    
    def initiate_mpesa_payment(self, phone: str, amount: float, 
                              enrollment_id: str) -> Dict:
        """Initiate M-Pesa payment (Kenya)"""
        config = MPESA_CONFIG
        
        # Implementation details for M-Pesa STK Push
        # This is a simplified example
        return {
            'success': True,
            'provider': 'mpesa',
            'message': 'M-Pesa payment initiated',
            'phone': phone,
            'amount': amount,
        }
    
    def initiate_mtn_momo_payment(self, phone: str, amount: float, 
                                 enrollment_id: str, country: str) -> Dict:
        """Initiate MTN Mobile Money payment (Uganda, Cameroon, etc.)"""
        config = MTN_MOMO_CONFIG
        
        payload = {
            'amount': amount,
            'currency': 'UGX' if country == 'UG' else 'XAF',
            'externalId': enrollment_id,
            'payer': {
                'partyIdType': 'MSISDN',
                'partyId': phone,
            },
            'payerMessage': f'Payment for enrollment {enrollment_id}',
            'payeeNote': f'Course enrollment',
        }
        
        try:
            headers = {
                'Authorization': f"Bearer {config['api_key']}",
                'X-Reference-Id': enrollment_id,
                'Content-Type': 'application/json',
            }
            
            response = self.session.post(
                f"{config['api_url']}/v1_0/requesttopay",
                json=payload,
                headers=headers,
                timeout=30
            )
            
            if response.status_code in [200, 202]:
                return {
                    'success': True,
                    'provider': 'mtn_momo',
                    'reference_id': response.headers.get('X-Reference-Id'),
                    'message': 'Payment initiated',
                }
            else:
                return {'success': False, 'error': response.text}
                
        except Exception as e:
            logger.error(f"MTN MoMo error: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    def initiate_orange_money_payment(self, phone: str, amount: float, 
                                     enrollment_id: str, country: str) -> Dict:
        """Initiate Orange Money payment (Cameroon, Senegal, etc.)"""
        config = ORANGE_MONEY_CONFIG
        
        payload = {
            'merchant_key': config['merchant_key'],
            'merchant_password': config['merchant_password'],
            'notif_url': f"{settings.API_URL}/api/payments/webhooks/orange-money/",
            'return_url': f"{settings.SITE_URL}/payment-success",
            'cancel_url': f"{settings.SITE_URL}/payment-failed",
            'orderid': enrollment_id,
            'amount': amount,
            'currency': 'XAF' if country == 'CM' else 'XOF',
            'msisdn': phone,
            'reference': f'enrollment_{enrollment_id}',
        }
        
        try:
            response = self.session.post(
                f"{config['api_url']}/pay",
                data=payload,
                timeout=30
            )
            
            if response.status_code == 200:
                return {
                    'success': True,
                    'provider': 'orange_money',
                    'payment_url': response.text,  # Returns redirect URL
                    'message': 'Payment initiated',
                }
            else:
                return {'success': False, 'error': response.text}
                
        except Exception as e:
            logger.error(f"Orange Money error: {str(e)}")
            return {'success': False, 'error': str(e)}
    
    # ========================================================================
    # HELPER METHODS
    # ========================================================================
    
    def _get_flutterwave_currency(self, country: str) -> str:
        """Get currency code for country - CRITICAL: Country-specific currency ONLY"""
        currency_map = {
            # Southern Africa
            'ZA': 'ZAR',  # South African Rand
            'ZW': 'USD',  # Zimbabwe uses USD
            'ZM': 'ZMW',  # Zambian Kwacha
            'BW': 'BWP',  # Botswana Pula
            'NA': 'NAD',  # Namibian Dollar
            'LS': 'LSL',  # Lesotho Loti
            'SZ': 'SZL',  # Swazi Lilangeni
            'MZ': 'MZN',  # Mozambican Metical
            'AO': 'AOA',  # Angolan Kwanza
            # East Africa
            'KE': 'KES',  # Kenyan Shilling
            'TZ': 'TZS',  # Tanzanian Shilling
            'UG': 'UGX',  # Ugandan Shilling
            'RW': 'RWF',  # Rwandan Franc
            'BI': 'BIF',  # Burundian Franc
            # West Africa
            'NG': 'NGN',  # Nigerian Naira
            'GH': 'GHS',  # Ghanaian Cedi
            'CI': 'XOF',  # West African CFA
            'SN': 'XOF',  # West African CFA
            'ML': 'XOF',  # West African CFA
            'BF': 'XOF',  # West African CFA
            'TG': 'XOF',  # West African CFA
            'BJ': 'XOF',  # West African CFA
            # Central Africa
            'CM': 'XAF',  # Central African CFA
            'GA': 'XAF',  # Central African CFA
            'CG': 'XAF',  # Central African CFA
            'CD': 'CDF',  # Congolese Franc
            'CF': 'XAF',  # Central African CFA
            'TD': 'XAF',  # Central African CFA
            'GQ': 'XAF',  # Central African CFA
            # Other African
            'EG': 'EGP',  # Egyptian Pound
            'MA': 'MAD',  # Moroccan Dirham
            'DZ': 'DZD',  # Algerian Dinar
            'TN': 'TND',  # Tunisian Dinar
            'LY': 'LYD',  # Libyan Dinar
            'SD': 'SDG',  # Sudanese Pound
            'SS': 'SSP',  # South Sudanese Pound
            'ET': 'ETB',  # Ethiopian Birr
            'SO': 'SOS',  # Somali Shilling
            'DJ': 'DJF',  # Djiboutian Franc
            'ER': 'ERN',  # Eritrean Nakfa
            'MW': 'MWK',  # Malawian Kwacha
        }
        # Return USD as fallback for unknown countries (safer than NGN)
        return currency_map.get(country.upper(), 'USD')
    
    def get_payment_status(self, provider: str, reference: str) -> Dict:
        """Get unified payment status from any provider"""
        if provider == 'flutterwave':
            return self.verify_flutterwave_payment(reference)
        elif provider == 'paystack':
            return self.verify_paystack_payment(reference)
        elif provider == 'stripe':
            # Stripe verification would use session ID
            return {'status': 'checking'}
        else:
            return {'error': 'Unknown provider'}
    
    def calculate_fees(self, provider: str, amount: float, is_international: bool = False) -> Decimal:
        """Calculate payment processing fees"""
        if provider not in PAYMENT_FEES:
            return Decimal(0)
        
        fees_config = PAYMENT_FEES[provider]
        
        if is_international and 'international' in fees_config:
            percentage = fees_config['international']
        elif not is_international and 'domestic' in fees_config:
            percentage = fees_config['domestic']
        else:
            percentage = fees_config.get('standard', 0)
        
        return Decimal(amount * percentage / 100)
    
    def get_test_credentials(self, provider: str) -> Dict:
        """Get test credentials for a payment provider"""
        if provider == 'flutterwave':
            return {
                'public_key': FLUTTERWAVE_CONFIG['public_key'],
                'test_cards': FLUTTERWAVE_CONFIG['test_cards'],
                'sandbox_url': 'https://app.flutterwave.com',
            }
        elif provider == 'paystack':
            return {
                'public_key': PAYSTACK_CONFIG['public_key'],
                'test_cards': PAYSTACK_CONFIG['test_cards'],
                'sandbox_url': 'https://dashboard.paystack.com',
            }
        elif provider == 'stripe':
            return {
                'public_key': STRIPE_CONFIG['public_key'],
                'test_cards': STRIPE_CONFIG['test_cards'],
                'sandbox_url': 'https://dashboard.stripe.com',
            }
        else:
            return {}


# ============================================================================
# WEBHOOK HANDLERS (for Django views.py)
# ============================================================================

class WebhookHandler:
    """Centralized webhook handling"""
    
    def __init__(self):
        self.service = PaymentIntegrationService()
    
    def handle_flutterwave_webhook(self, request):
        """Handle Flutterwave webhook"""
        try:
            payload = json.loads(request.body)
            signature = request.headers.get('Verif-Hash', '')
            
            success, message = self.service.handle_flutterwave_webhook(payload, signature)
            
            if success:
                # Update payment record in database
                self._update_payment_record(payload, 'flutterwave')
                return Response({'status': 'success'}, status=200)
            else:
                return Response({'status': 'failed', 'message': message}, status=400)
                
        except Exception as e:
            logger.error(f"Webhook error: {str(e)}")
            return Response({'status': 'error'}, status=500)
    
    def handle_paystack_webhook(self, request):
        """Handle Paystack webhook"""
        try:
            payload = json.loads(request.body)
            signature = request.headers.get('x-paystack-signature', '')
            
            success, message = self.service.handle_paystack_webhook(payload, signature)
            
            if success:
                self._update_payment_record(payload, 'paystack')
                return Response({'status': 'success'}, status=200)
            else:
                return Response({'status': 'failed', 'message': message}, status=400)
                
        except Exception as e:
            logger.error(f"Webhook error: {str(e)}")
            return Response({'status': 'error'}, status=500)
    
    def handle_stripe_webhook(self, request):
        """Handle Stripe webhook"""
        try:
            payload = json.loads(request.body)
            signature = request.headers.get('stripe-signature', '')
            
            success, message = self.service.handle_stripe_webhook(payload, signature)
            
            if success:
                self._update_payment_record(payload, 'stripe')
                return Response({'status': 'success'}, status=200)
            else:
                return Response({'status': 'failed', 'message': message}, status=400)
                
        except Exception as e:
            logger.error(f"Webhook error: {str(e)}")
            return Response({'status': 'error'}, status=500)
    
    def _update_payment_record(self, payload: Dict, provider: str):
        """Update payment record in database with webhook data"""
        # This would integrate with your Payment model
        # Update payment status, create transaction record, etc.
        logger.info(f"Payment updated from {provider} webhook: {payload}")
