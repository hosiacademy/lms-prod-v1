# apps/payments/services/payment_service.py
import json  # <-- Add this import
import logging
from typing import Dict, Any, Optional, List
from django.conf import settings
from django.db import transaction as db_transaction
from django.utils import timezone
from ..models import (
    PaymentTransaction, PaymentProvider, PaymentStatus, TransactionType,
    ProviderCountryConfig, CountryPaymentLandscape, PaymentProviderIntegration,
    Order
)
from ..adapters import get_adapter, ADAPTER_REGISTRY, PaymentError, SignatureVerificationError

# Import Sentry monitoring
from .sentry_service import sentry_monitor, monitor_payment_performance
from apps.enrollments.models import ProvisionalEnrollment
from apps.masterclasses.models import Masterclass
from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment, EnrollmentStatus

# Import Payment Routing Service for unified payment flow
from .payment_routing_service import PaymentRoutingService

logger = logging.getLogger(__name__)


class PaymentService:
    """
    Main service for orchestrating payments across all providers
    """
    
    def __init__(self):
        self.adapters = {}  # Cache for adapter instances
    
    def validate_payment_routing(self, country: str, payment_method: str, 
                                provider_code: str, training_type: str = None) -> tuple:
        """
        Validate payment routing based on country, method, and provider.
        Enforces SmatPay exclusivity for card payments.
        
        Args:
            country: ISO country code
            payment_method: 'card', 'eft', 'cash'
            provider_code: Provider code (e.g., 'smatpay', 'paynow')
            training_type: Optional training type for validation
            
        Returns:
            Tuple of (is_valid: bool, error_message: str or None, correct_provider: str or None)
        """
        try:
            # Validate payment method is available for country/training_type
            is_valid, error = PaymentRoutingService.validate_payment_method(
                country_code=country,
                payment_method=payment_method,
                training_type=training_type
            )
            
            if not is_valid:
                return False, error, None
            
            # Get the correct provider for this method
            correct_provider = PaymentRoutingService.get_payment_provider(
                country_code=country,
                payment_method=payment_method
            )
            
            # Validate that requested provider matches routing
            # Card payments MUST go to SmatPay (exclusivity enforcement)
            if payment_method.lower() == 'card':
                if provider_code.lower() != 'smatpay':
                    logger.warning(
                        f"Card payment requested with {provider_code}, enforcing SmatPay. "
                        f"Country: {country}, Training: {training_type}"
                    )
                    return False, f"Card payments must use SmatPay. Provider {provider_code} not allowed.", correct_provider
            else:
                # For non-card payments, verify provider matches routing
                if provider_code.lower() != correct_provider.lower():
                    logger.warning(
                        f"Payment routing mismatch. Requested: {provider_code}, "
                        f"Correct: {correct_provider}. Country: {country}, Method: {payment_method}"
                    )
                    return False, f"Provider {provider_code} not configured for {payment_method} in {country}. Use {correct_provider}.", correct_provider
            
            return True, None, correct_provider
            
        except Exception as e:
            logger.error(f"Error validating payment routing: {str(e)}")
            return False, f"Routing validation failed: {str(e)}", None

    
    def get_adapter_for_provider(self, provider_code: str, 
                                provider_config: ProviderCountryConfig = None):
        """Get or create adapter instance for provider"""
        if provider_code not in self.adapters:
            self.adapters[provider_code] = get_adapter(provider_code, provider_config)
        return self.adapters[provider_code]
    
    def get_available_providers(self, country: str, amount: float = None,
                               currency: str = None) -> List[Dict[str, Any]]:
        """
        Get available payment providers for a country

        Args:
            country: Country code (ISO 3166-1 alpha-2)
            amount: Transaction amount (for validation)
            currency: Preferred currency

        Returns:
            List of available providers with details
        """
        providers = []
        # SPECIAL CASE: Zimbabwe - SmatPay is the EXCLUSIVE provider
        if country.upper() == 'ZW':
            logger.info("Zimbabwe detected - returning SmatPay as exclusive provider")
            try:
                providers.append({
                    'code': 'smatpay',
                    'name': 'SmatPay Zimbabwe',
                    'category': 'card',
                    'methods': ['card', 'zimswitch', 'mobile_money'],
                    'currencies': ['USD'],
                    'is_recommended': True,
                    'priority': 1,
                    'description': 'Secure payments via SmatPay (Visa, Mastercard, ZimSwitch, EcoCash)',
                    'is_exclusive': True,
                })
            except Exception as e:
                logger.error(f"Error getting SmatPay for Zimbabwe: {e}")
            return providers

        # Get country landscape
        try:
            landscape = CountryPaymentLandscape.objects.get(country_code=country)
        except CountryPaymentLandscape.DoesNotExist:
            landscape = None

        # Get active provider configs for country
        configs = ProviderCountryConfig.objects.filter(
            country=country,
            is_active=True,
            provider__is_active=True,
        ).select_related('provider')
        
        for config in configs:
            try:
                adapter = self.get_adapter_for_provider(config.provider.code, config)
                
                # Check if adapter supports country
                supported_countries = adapter.get_supported_countries()
                if '*' not in supported_countries and country not in supported_countries:
                    continue
                
                # Check currency support
                supported_currencies = adapter.get_supported_currencies()
                if '*' not in supported_currencies and currency and currency not in supported_currencies:
                    continue
                
                # Validate amount if provided
                if amount:
                    is_valid, message = adapter.validate_amount(amount, currency or config.supported_currencies[0])
                    if not is_valid:
                        continue
                
                # Get integration status
                integration = PaymentProviderIntegration.objects.filter(
                    provider=config.provider
                ).first()
                
                providers.append({
                    'code': config.provider.code,
                    'name': config.provider.name,
                    'category': config.provider.category,
                    'methods': adapter.get_supported_methods(),
                    'currencies': adapter.get_supported_currencies(),
                    'min_amount': float(config.min_amount),
                    'max_amount': float(config.max_amount),
                    'fee_percentage': float(config.fee_percentage),
                    'fixed_fee': float(config.fixed_fee),
                    'integration_status': integration.integration_status if integration else 'not_started',
                    'is_recommended': config.provider.is_recommended,
                    'priority': config.provider.priority,
                })
                
            except Exception as e:
                logger.error(f"Error getting provider {config.provider.code}: {e}")
                continue
        
        # Ensure SmatPay is included as a global card provider (Visa/Mastercard everywhere)
        if not any(p['code'] == 'smatpay' for p in providers):
            try:
                providers.append({
                    'code': 'smatpay',
                    'name': 'Card Payment (SmatPay)',
                    'category': 'card',
                    'methods': ['card', 'zimswitch', 'mobile_money'],
                    'currencies': ['USD', 'ZAR', 'KES', 'GHS', 'NGN', 'ZMW', 'BWP', 'EUR', 'GBP'],
                    'is_recommended': True,
                    'priority': 1,
                    'description': 'Secure card payment via SmatPay (Visa, Mastercard globally)',
                })
            except Exception as e:
                logger.error(f"Error adding default SmatPay: {e}")

        # Sort by priority and recommendation
        providers.sort(key=lambda x: (-x['priority'], -x['is_recommended'], x['name']))
        
        return providers
    
    @db_transaction.atomic
    def initiate_payment(self, user, amount: float, currency: str, country: str,
                        provider_code: str, description: str = "", 
                        metadata: Dict[str, Any] = None, **kwargs) -> Dict[str, Any]:
        """
        Initiate a payment with specified provider
        
        ENFORCES PAYMENT ROUTING:
        - Card payments MUST go to SmatPay (exclusively)
        - EFT payments go to country-specific bank providers
        - Cash payments go to office payment system
        
        Args:
            user: User making payment
            amount: Payment amount
            currency: Currency code
            country: Country code
            provider_code: Payment provider code
            description: Payment description
            metadata: Additional metadata
            **kwargs: Provider-specific parameters
            
        Returns:
            Dict with payment initiation result
        """
        # VALIDATION 1: Validate payment routing
        payment_method = kwargs.get('payment_method', 'card').lower()
        training_type = metadata.get('training_type') if metadata else None
        
        is_valid, error, correct_provider = self.validate_payment_routing(
            country=country,
            payment_method=payment_method,
            provider_code=provider_code,
            training_type=training_type
        )
        
        if not is_valid:
            # Log security event: someone tried to bypass routing
            logger.warning(
                f"Payment routing validation failed. User: {user.id}, "
                f"Attempted: {provider_code}, Correct: {correct_provider}, "
                f"Country: {country}, Method: {payment_method}"
            )
            raise PaymentError(f"Invalid payment configuration: {error}")
        
        # If a different provider is correct, use it instead
        if correct_provider and provider_code.lower() != correct_provider.lower():
            logger.info(
                f"Auto-correcting provider from {provider_code} to {correct_provider}"
            )
            provider_code = correct_provider
        
        # Get provider config - special handling for EFT
        try:
            provider_config = ProviderCountryConfig.objects.get(
                provider__code=provider_code,
                country=country,
                is_active=True,
            )
        except ProviderCountryConfig.DoesNotExist:
            # Special case for EFT/Bank Transfer
            if provider_code == 'eft':
                try:
                    # Get or create EFT provider
                    from apps.payments.models import PaymentProviderModel
                    eft_provider, created = PaymentProviderModel.objects.get_or_create(
                        code='eft',
                        defaults={
                            'name': 'EFT / Bank Transfer',
                            'category': 'manual',
                            'is_active': True,
                        }
                    )
                    
                    # Create provider config for this country
                    provider_config, created = ProviderCountryConfig.objects.get_or_create(
                        provider=eft_provider,
                        country=country,
                        defaults={
                            'is_active': True,
                            'is_sandbox': False,
                            'min_amount': 1.00,
                            'max_amount': 1000000.00,
                            'fee_percentage': 0.0,
                            'fixed_fee': 0,
                            'supported_currencies': ['ZAR', 'USD', 'EUR'],
                            'supported_methods': ['bank_transfer'],
                        }
                    )
                except Exception as e:
                    raise PaymentError(f"Failed to setup EFT provider: {str(e)}")
            else:
                raise PaymentError(f"Provider {provider_code} not available for country {country}")
        
        # Validate amount limits
        if amount < float(provider_config.min_amount):
            raise PaymentError(f"Amount below minimum: {provider_config.min_amount}")
        if amount > float(provider_config.max_amount):
            raise PaymentError(f"Amount above maximum: {provider_config.max_amount}")
        
        # Extract details for guest/user
        is_corporate = kwargs.get('is_corporate', False)
        corp_details = kwargs.get('corporate_details', {})
        indiv_details = kwargs.get('individual_details', {})

        # Create payment transaction
        payment_transaction = PaymentTransaction.objects.create(
            user=user,
            order=metadata.get('order_id') if isinstance(metadata.get('order_id'), Order) else Order.objects.filter(id=metadata.get('order_id')).first() if metadata.get('order_id') else None,
            amount=amount,
            currency=currency,
            country=country,
            provider=provider_code,
            provider_config=provider_config,
            transaction_type=TransactionType.PURCHASE,
            provider_reference=self._generate_reference(provider_code),
            description=description or f"Payment of {amount} {currency}",
            status=PaymentStatus.PENDING,
            metadata=metadata or {},
            ip_address=kwargs.get('ip_address'),
            user_agent=kwargs.get('user_agent'),
            callback_url=kwargs.get('callback_url'),
            redirect_url=kwargs.get('redirect_url'),
            
            # Populate additional fields
            is_corporate=is_corporate,
            company_name=corp_details.get('company_name'),
            company_email=corp_details.get('contact_email'),
            company_phone=corp_details.get('contact_phone'),
            individual_name=indiv_details.get('full_name') or indiv_details.get('name'),
            individual_email=indiv_details.get('email'),
            individual_phone=indiv_details.get('phone'),
            enrollment_type=metadata.get('enrollment_type'),
        )

        # Track payment initiation in Sentry
        sentry_monitor.track_payment_initiation(payment_transaction)

        try:
            # Get adapter and initiate payment
            adapter = self.get_adapter_for_provider(provider_code, provider_config)

            # Fallback to Flutterwave for bank APIs without dedicated adapters
            if adapter is None:
                logger.info(f"No adapter for {provider_code}, using Flutterwave fallback")
                adapter = self.get_adapter_for_provider('flutterwave', None)
            
            if adapter is None:
                raise PaymentError(f"No payment adapter available for provider {provider_code}")

            # Validate amount with adapter
            is_valid, message = adapter.validate_amount(amount, currency)
            if not is_valid:
                payment_transaction.status = PaymentStatus.FAILED
                payment_transaction.metadata['validation_error'] = message
                payment_transaction.save()
                raise PaymentError(message)
            
            # Initiate payment with provider
            # Prepare kwargs for adapter - remove fields we pass explicitly
            adapter_kwargs = kwargs.copy()
            adapter_kwargs.pop('callback_url', None)
            adapter_kwargs.pop('redirect_url', None)

            result = adapter.initiate_payment(
                transaction=payment_transaction,
                callback_url=kwargs.get('callback_url') or 
                           f"{settings.SITE_URL}/api/v1/payments/callback/{payment_transaction.id}/",
                **adapter_kwargs
            )
            
            # Update transaction with provider response
            payment_transaction.metadata['provider_response'] = result
            payment_transaction.save()
            
            logger.info(
                f"Payment initiated: {payment_transaction.provider_reference} "
                f"via {provider_code} for {amount} {currency}",
                extra={
                    'transaction_id': str(payment_transaction.id),
                    'provider': provider_code,
                    'amount': amount,
                    'currency': currency,
                }
            )
            
            return {
                'transaction': payment_transaction,
                'checkout_url': result.get('checkout_url'),
                'requires_redirect': result.get('requires_redirect', False),
                'requires_stk_push': result.get('requires_stk_push', False),
                'provider_reference': result.get('provider_reference'),
                'additional_data': result.get('additional_data', {}),
            }
            
        except Exception as e:
            payment_transaction.status = PaymentStatus.FAILED
            payment_transaction.metadata['error'] = str(e)
            payment_transaction.save()

            # Track failure in Sentry with full context
            sentry_monitor.capture_payment_exception(
                exception=e,
                transaction=payment_transaction,
                context={
                    'operation': 'payment_initiation',
                    'provider': provider_code,
                    'error_message': str(e),
                }
            )

            logger.error(
                f"Payment initiation failed: {str(e)}",
                extra={
                    'transaction_id': str(payment_transaction.id),
                    'provider': provider_code,
                    'error': str(e),
                }
            )
            raise PaymentError(f"Payment initiation failed: {str(e)}")
    
    def handle_webhook(self, provider_code: str, payload: Dict[str, Any],
                      headers: Dict[str, str], raw_body: bytes = None) -> PaymentTransaction:
        """
        Handle incoming webhook from payment provider
        
        CRITICAL FIXES APPLIED:
        1. Idempotency: Checks if order already successful before processing
        2. Row locking: Uses select_for_update() to prevent race conditions
        3. Raw body: Accepts raw body for proper signature verification

        Args:
            provider_code: Provider code
            payload: Webhook payload
            headers: Webhook headers
            raw_body: Raw request body (bytes) for signature verification

        Returns:
            Updated payment transaction
        """
        # Track webhook reception in Sentry
        sentry_monitor.track_webhook_received(
            provider=provider_code,
            event_type=payload.get('event', 'unknown'),
            payload=payload
        )

        try:
            # Get adapter without config first for signature verification
            adapter = self.get_adapter_for_provider(provider_code)

            # CRITICAL FIX #4: Verify signature using RAW body if provided
            # This prevents signature verification failures due to JSON serialization differences
            body_for_verification = raw_body if raw_body else json.dumps(payload, sort_keys=True).encode('utf-8')
            
            if not adapter.verify_webhook_signature(body_for_verification, headers):
                raise SignatureVerificationError("Invalid webhook signature")

            # Parse webhook data
            webhook_data = adapter.parse_webhook(payload)
            reference = webhook_data.get('reference')

            if not reference:
                raise PaymentError("No reference found in webhook")

            # CRITICAL FIX #3: Use select_for_update() to prevent race conditions
            # This ensures only one webhook/process can update the transaction at a time
            with db_transaction.atomic():
                try:
                    transaction = PaymentTransaction.objects.select_for_update().get(
                        provider_reference=reference,
                        provider=provider_code,
                    )
                except PaymentTransaction.DoesNotExist:
                    # Try to find by checkout ID or other reference
                    transaction = PaymentTransaction.objects.select_for_update().filter(
                        metadata__contains={'checkout_id': reference}
                    ).first()

                    if not transaction:
                        raise PaymentError(f"Transaction not found for reference: {reference}")

                # CRITICAL FIX #2: IDEMPOTENCY CHECK
                # If transaction is already successful, skip processing but return OK
                # This handles webhook retries from payment gateways
                if transaction.status == PaymentStatus.SUCCESSFUL:
                    logger.info(
                        f"Webhook idempotency: Transaction {reference} already successful, skipping",
                        extra={
                            'transaction_id': str(transaction.id),
                            'provider': provider_code,
                        }
                    )
                    # Still update webhook metadata for audit trail
                    transaction.metadata['webhook_received'] = {
                        'payload': payload,
                        'headers': headers,
                        'parsed_data': webhook_data,
                        'received_at': timezone.now().isoformat(),
                    }
                    transaction.webhook_received = True
                    transaction.webhook_processed_at = timezone.now()
                    transaction.save(update_fields=['metadata', 'webhook_received', 'webhook_processed_at'])
                    return transaction

                # Update transaction based on webhook
                transaction.metadata['webhook_received'] = {
                    'payload': payload,
                    'headers': headers,
                    'parsed_data': webhook_data,
                    'received_at': timezone.now().isoformat(),
                }
                transaction.webhook_received = True
                transaction.webhook_processed_at = timezone.now()

                # Update status based on webhook event
                event = webhook_data.get('event', '')
                status = webhook_data.get('status', '')

                if 'success' in event.lower() or 'success' in status.lower():
                    transaction.status = PaymentStatus.SUCCESSFUL
                    transaction.completed_at = timezone.now()

                    # Track success in Sentry
                    sentry_monitor.track_payment_success(transaction)

                    # Trigger post-payment actions (now async)
                    self._handle_successful_payment(transaction)

                elif 'fail' in event.lower() or 'fail' in status.lower():
                    transaction.status = PaymentStatus.FAILED

                    # Track failure in Sentry
                    error_message = webhook_data.get('error_message', status)
                    sentry_monitor.track_payment_failure(transaction, error_message)

                elif 'cancel' in event.lower():
                    transaction.status = PaymentStatus.CANCELLED

                elif 'refund' in event.lower():
                    transaction.status = PaymentStatus.REFUNDED

                transaction.save()

                # Log webhook processing
                logger.info(
                    f"Webhook processed: {reference} -> {transaction.status}",
                    extra={
                        'transaction_id': str(transaction.id),
                        'provider': provider_code,
                        'event': event,
                        'status': transaction.status,
                    }
                )

                return transaction

        except Exception as e:
            logger.error(
                f"Webhook processing failed: {str(e)}",
                extra={
                    'provider': provider_code,
                    'payload': payload,
                    'error': str(e),
                }
            )
            raise PaymentError(f"Webhook processing failed: {str(e)}")
    
    def verify_payment(self, transaction_id: str) -> Dict[str, Any]:
        """
        Verify payment status with provider
        
        Args:
            transaction_id: Transaction ID or provider reference
            
        Returns:
            Verification result
        """
        try:
            # Find transaction
            try:
                transaction = PaymentTransaction.objects.get(id=transaction_id)
            except (PaymentTransaction.DoesNotExist, ValueError):
                # Try provider reference
                transaction = PaymentTransaction.objects.get(
                    provider_reference=transaction_id
                )
            
            # Get adapter and verify
            adapter = self.get_adapter_for_provider(
                transaction.provider,
                transaction.provider_config
            )
            
            result = adapter.verify_payment(transaction.provider_reference)
            
            # Update transaction if status changed
            if result.get('status') and result['status'] != transaction.status:
                transaction.status = result['status']
                if result['status'] == PaymentStatus.SUCCESSFUL:
                    transaction.completed_at = timezone.now()
                    self._handle_successful_payment(transaction)
                transaction.save()
            
            return {
                'transaction': transaction,
                'status': result['status'],
                'provider_data': result.get('provider_data', {}),
                'verified_at': timezone.now(),
            }
            
        except Exception as e:
            logger.error(f"Payment verification failed: {str(e)}")
            raise PaymentError(f"Payment verification failed: {str(e)}")
    
    def refund_payment(self, transaction_id: str, amount: float = None, 
                      reason: str = "") -> Dict[str, Any]:
        """
        Process refund for transaction
        
        Args:
            transaction_id: Original transaction ID
            amount: Refund amount (None = full amount)
            reason: Refund reason
            
        Returns:
            Refund result
        """
        try:
            # Find transaction
            transaction = PaymentTransaction.objects.get(id=transaction_id)
            
            # Validate transaction can be refunded
            if transaction.status != PaymentStatus.SUCCESSFUL:
                raise PaymentError("Only successful transactions can be refunded")
            
            if transaction.metadata.get('refunded'):
                raise PaymentError("Transaction already refunded")
            
            # Get adapter and process refund
            adapter = self.get_adapter_for_provider(
                transaction.provider,
                transaction.provider_config
            )
            
            result = adapter.refund_payment(
                transaction=transaction,
                amount=amount,
                reason=reason,
            )
            
            # Create refund record
            from ..models import PaymentRefund
            refund = PaymentRefund.objects.create(
                original_transaction=transaction,
                refund_amount=amount or transaction.amount,
                refund_reason=reason,
                refund_reference=result.get('refund_id') or self._generate_reference('REFUND'),
                status='completed' if result.get('status') == 'success' else 'failed',
                provider_response=result.get('provider_data', {}),
                provider_refund_id=result.get('refund_id'),
                provider_config=transaction.provider_config,
                initiated_by=transaction.user,
                completed_at=timezone.now(),
            )
            
            # Update original transaction
            transaction.status = PaymentStatus.REFUNDED
            transaction.metadata['refunded'] = True
            transaction.metadata['refund_id'] = str(refund.id)
            transaction.save()
            
            logger.info(
                f"Refund processed: {refund.refund_reference} for {transaction.provider_reference}",
                extra={
                    'transaction_id': str(transaction.id),
                    'refund_id': str(refund.id),
                    'amount': refund.refund_amount,
                    'provider': transaction.provider,
                }
            )
            
            return {
                'refund': refund,
                'transaction': transaction,
                'provider_data': result.get('provider_data', {}),
            }
            
        except Exception as e:
            logger.error(f"Refund failed: {str(e)}")
            raise PaymentError(f"Refund failed: {str(e)}")
    
    def _generate_reference(self, prefix: str = "HOSI") -> str:
        """Generate unique reference"""
        import uuid
        import time
        timestamp = int(time.time())
        unique_id = uuid.uuid4().hex[:8].upper()
        return f"{prefix}_{timestamp}_{unique_id}"
    
    def _handle_successful_payment(self, transaction: PaymentTransaction):
        """
        Handle post-payment actions.
        CRITICAL: Only updates financial state. Provisioning is done async via Celery.
        
        This ensures:
        1. Payment is marked SUCCESSFUL even if external APIs fail
        2. External API calls (AICerts, Moodle, email) are retried automatically
        3. No database rollback due to external service failures
        """
        from apps.payments.tasks import (
            provision_enrollment_async,
            send_payment_confirmation_email,
            send_payment_confirmation_sms,
        )
        
        # === 1. GUEST USER CREATION ===
        user = transaction.user
        if not user:
            # Create user from transaction details
            from django.contrib.auth import get_user_model
            User = get_user_model()

            # Try to get email from transaction fields or metadata
            email = (transaction.individual_email or
                     transaction.company_email or
                     transaction.metadata.get('individual_details', {}).get('email') or
                     transaction.metadata.get('corporate_details', {}).get('contact_email') or
                     transaction.metadata.get('email'))

            if not email:
                logger.error(f"Cannot create user for transaction {transaction.id}: No email found")
                return # Can't proceed without email

            try:
                user = User.objects.get(email=email)
            except User.DoesNotExist:
                # Create new user
                username = email.split('@')[0]
                base_username = username
                counter = 1
                while User.objects.filter(username=username).exists():
                    username = f"{base_username}{counter}"
                    counter += 1

                # Determine name
                full_name = transaction.individual_name or transaction.company_name or ""
                first_name = ""
                last_name = ""
                if full_name:
                    parts = full_name.split(' ')
                    first_name = parts[0]
                    if len(parts) > 1:
                        last_name = ' '.join(parts[1:])

                user = User.objects.create_user(
                    username=username,
                    email=email,
                    first_name=first_name,
                    last_name=last_name
                )
                # Set a random password they can reset
                import secrets
                user.set_password(secrets.token_urlsafe(12))
                user.country = transaction.country
                user.save()
                logger.info(f"Created new user {user.email} after successful payment")

            # Link user to transaction
            transaction.user = user
            transaction.save()

        # === 2. ORDER LINKING & UPDATING ===
        order = transaction.order
        if order:
            if not order.user:
                order.user = user
            order.status = 'completed'
            # Support both payment_status and status fields for safety
            if hasattr(order, 'payment_status'):
                order.payment_status = PaymentStatus.SUCCESSFUL
            order.save()
            logger.info(f"Order {order.tracking} marked as completed for user {user.email}")

        # === 3. ASYNC ENROLLMENT PROVISIONING ===
        # Trigger Celery task instead of synchronous provisioning
        # This decouples financial success from fulfillment
        enrollment_type = transaction.enrollment_type or transaction.metadata.get('enrollment_type')
        program_id = transaction.metadata.get('program_id')
        course_ids = transaction.metadata.get('course_ids', [])

        has_content = (
            program_id or
            (enrollment_type == 'custom_selection' and course_ids) or
            (enrollment_type in ['industry_training', 'role_training'] and course_ids)
        )

        if enrollment_type and has_content:
            # Queue async provisioning task with automatic retries
            provision_enrollment_async.delay(str(transaction.id))
            logger.info(
                f"Queued async provisioning for transaction {transaction.id}",
                extra={
                    'user_email': user.email if user else 'unknown',
                    'enrollment_type': enrollment_type,
                }
            )
        else:
            logger.warning(
                f"No enrollment data for transaction {transaction.id}, skipping provisioning",
                extra={'enrollment_type': enrollment_type}
            )

        # === 4. ASYNC NOTIFICATIONS ===
        # Send email and SMS notifications in parallel via Celery
        try:
            send_payment_confirmation_email.delay(str(transaction.id))
            send_payment_confirmation_sms.delay(str(transaction.id))
            logger.info(f"Queued payment notifications for transaction {transaction.id}")
        except Exception as e:
            logger.error(f"Failed to queue notifications: {str(e)}")
            # Don't fail - notifications are not critical

        # === 5. UPDATE INSTRUCTOR REVENUE ===
        # This is internal, can remain synchronous
        self._update_instructor_revenue(transaction)

    def _provision_enrollment(self, user, enrollment_type, program_id, transaction):
        """
        Provision enrollment based on type.
        """
        from apps.aicerts_integration.services import EnrollmentSyncService
        from apps.aicerts_courses.models import AiCertsCourse

        logger.info(f"Provisioning {enrollment_type} for user {user.email}")

        if enrollment_type == 'masterclass':
            # Enroll directly in masterclass and its linked AICerts courses
            try:
                masterclass = Masterclass.objects.get(id=program_id)

                for course in masterclass.provider_courses.all():
                    try:
                        EnrollmentSyncService.enroll_user_in_course(user, course)
                        logger.info(f"Enrolled {user.email} in AICerts course {course.title} (Masterclass)")
                    except Exception as e:
                        logger.error(f"Failed to enroll {user.email} in course {course.id}: {e}")

                masterclass.current_participants += 1
                masterclass.save()

            except Masterclass.DoesNotExist:
                logger.error(f"Masterclass {program_id} not found for provisioning")

        elif enrollment_type == 'custom_selection':
            # Student paid for individual AICerts courses via the catalog cart.
            # metadata['course_ids'] are the object_id values from CartItem (AiCertsCourse PKs).
            course_ids = transaction.metadata.get('course_ids', [])
            if not course_ids:
                logger.error(f"custom_selection enrollment has no course_ids in metadata for tx {transaction.id}")
                return

            from apps.payments.models import Enrollment as GenericEnrollment, EnrollmentType, EnrollmentStatus as GenericEnrollmentStatus
            from django.contrib.contenttypes.models import ContentType
            import uuid

            # Extract demographic data sent from the enrollment form
            individual_details = transaction.metadata.get('individual_details', {})
            terms_accepted_flag = transaction.metadata.get('terms_accepted', True)

            # Parse date of birth safely
            dob_value = None
            dob_raw = individual_details.get('date_of_birth', '')
            if dob_raw:
                try:
                    from datetime import datetime
                    dob_value = datetime.strptime(dob_raw, '%d/%m/%Y').date()
                except (ValueError, TypeError):
                    try:
                        from datetime import date
                        dob_value = date.fromisoformat(dob_raw)
                    except (ValueError, TypeError):
                        pass

            for course_id in course_ids:
                try:
                    course = AiCertsCourse.objects.get(id=course_id)

                    # Enroll on AICerts (creates AICertsEnrollment)
                    aicerts_enrollment, aicerts_result = EnrollmentSyncService.enroll_user_in_course(user, course)
                    logger.info(f"Enrolled {user.email} in AICerts course {course.title} (custom_selection)")

                    # Create generic Enrollment record for unified tracking
                    try:
                        GenericEnrollment.objects.create(
                            enrollment_type=EnrollmentType.CUSTOM_SELECTION,
                            content_type=ContentType.objects.get_for_model(course),
                            object_id=course.id,
                            enrollment_code=f"CUSTOM_{uuid.uuid4().hex[:8].upper()}",
                            user=user,
                            status=GenericEnrollmentStatus.ENROLLED,
                            aicerts_enrollment_id=aicerts_enrollment.id,
                            learner_full_name=individual_details.get('full_name') or user.get_full_name() or user.username,
                            learner_email=individual_details.get('email') or user.email,
                            learner_phone=individual_details.get('phone') or getattr(user, 'phone', '') or '+1234567890',
                            learner_id_number=individual_details.get('id_number') or None,
                            learner_dob=dob_value,
                            learner_gender=individual_details.get('gender') or None,
                            learner_address=individual_details.get('address') or None,
                            learner_city=individual_details.get('city') or None,
                            learner_country=individual_details.get('country_id') and str(individual_details['country_id']) or transaction.country,
                            learner_postal_code=individual_details.get('postal_code') or None,
                            current_occupation=individual_details.get('occupation') or None,
                            education_level=individual_details.get('education_level') or None,
                            institution=individual_details.get('institution') or None,
                            emergency_contact_name=individual_details.get('emergency_name') or None,
                            emergency_contact_phone=individual_details.get('emergency_phone') or None,
                            emergency_contact_relationship=individual_details.get('emergency_relationship') or None,
                            dietary_requirements=individual_details.get('dietary_requirements') or None,
                            accessibility_needs=individual_details.get('accessibility_requirements') or None,
                            additional_notes=individual_details.get('additional_notes') or None,
                            final_amount=transaction.amount,
                            currency=transaction.currency,
                            order=transaction.order,
                            terms_accepted=terms_accepted_flag,
                            terms_accepted_at=timezone.now() if terms_accepted_flag else None,
                            enrolled_at=timezone.now(),
                            enrollment_data={
                                'transaction_id': str(transaction.id),
                                'provider_reference': transaction.provider_reference,
                                'payment_status': transaction.status,
                                'stream_type': transaction.metadata.get('stream_type'),
                                'ai_tools': individual_details.get('ai_tools_interested', []),
                            }
                        )
                        logger.info(f"Created generic Enrollment for course {course.title}")
                    except Exception as e:
                        logger.error(f"Failed to create generic Enrollment: {e}")
                        import traceback
                        traceback.print_exc()

                except AiCertsCourse.DoesNotExist:
                    logger.error(f"AiCertsCourse id={course_id} not found (custom_selection tx {transaction.id})")
                except Exception as e:
                    logger.error(f"Failed to enroll {user.email} in course {course_id}: {e}")
                    import traceback
                    traceback.print_exc()

        elif enrollment_type == 'learnership':
            # Create both ProvisionalEnrollment and LearnershipEnrollment
            # ProvisionalEnrollment is the source of truth for Sales Admin workflow
            # LearnershipEnrollment holds SETA compliance data
            try:
                programme = LearnershipProgramme.objects.get(id=program_id)
                
                # Extract SETA/demographic data from transaction metadata
                # This data is collected during checkout and stored in metadata
                metadata = transaction.metadata or {}
                individual_details = metadata.get('individual_details', {})
                demographics = metadata.get('demographics', {})
                employment = metadata.get('employment', {})
                next_of_kin = metadata.get('next_of_kin', {})
                medical = metadata.get('medical', {})
                learning_support = metadata.get('learning_support', {})
                banking = metadata.get('banking', {})
                declarations = metadata.get('declarations', {})
                
                # Create ProvisionalEnrollment FIRST - this is what Sales Admin uses
                # Status 'provisional' indicates pending prerequisite verification
                provisional = ProvisionalEnrollment.objects.create(
                    user=user,
                    programme=programme,
                    payment_transaction=transaction,
                    enrollment_type='learnership',
                    status='provisional',  # Pending prerequisite verification
                    metadata=metadata
                )
                
                # Create LearnershipEnrollment with SETA compliance data
                # This is linked to ProvisionalEnrollment via payment_transaction
                # Status is set to PROVISIONAL pending admin verification
                learnership_enrollment = LearnershipEnrollment.objects.create(
                    programme=programme,
                    user=user,
                    payment_transaction=transaction,
                    enrollment_type='individual',  # Default to individual, can be updated
                    status=EnrollmentStatus.PROVISIONAL,  # Pending verification
                    payment_status='pending',
                    
                    # Personal details from checkout
                    highest_qualification=individual_details.get('highest_qualification', ''),
                    qualification_institution=individual_details.get('qualification_institution', ''),
                    qualification_year=individual_details.get('qualification_year', ''),
                    education_level=individual_details.get('education_level', ''),
                    
                    # Employment information
                    employer=employment.get('employer', ''),
                    job_title=employment.get('job_title', ''),
                    employment_status=employment.get('employment_status', ''),
                    monthly_income=employment.get('monthly_income', ''),
                    existing_skills=employment.get('existing_skills', ''),
                    
                    # Demographics for SETA reporting
                    race=demographics.get('race', ''),
                    disability=demographics.get('disability', ''),
                    nationality=demographics.get('nationality', ''),
                    
                    # Next of kin
                    next_of_kin_name=next_of_kin.get('name', ''),
                    next_of_kin_phone=next_of_kin.get('phone', ''),
                    next_of_kin_relationship=next_of_kin.get('relationship', ''),
                    next_of_kin_email=next_of_kin.get('email', ''),
                    next_of_kin_address=next_of_kin.get('address', ''),
                    
                    # Medical & accessibility
                    medical_conditions=medical.get('medical_conditions', ''),
                    allergies=medical.get('allergies', ''),
                    medications=medical.get('medications', ''),
                    accessibility_needs=medical.get('accessibility_needs', ''),
                    
                    # Learning support
                    requires_learning_support=learning_support.get('requires_learning_support', ''),
                    learning_support_details=learning_support.get('learning_support_details', ''),
                    has_previous_learnership_experience=learning_support.get('has_previous_learnership_experience', ''),
                    previous_learnership_details=learning_support.get('previous_learnership_details', ''),
                    
                    # Banking details for debit orders
                    requires_debit_order=banking.get('requires_debit_order', ''),
                    bank_name=banking.get('bank_name', ''),
                    bank_account_number=banking.get('bank_account_number', ''),
                    bank_branch_code=banking.get('bank_branch_code', ''),
                    bank_account_type=banking.get('bank_account_type', ''),
                    bank_account_holder_name=banking.get('bank_account_holder_name', ''),
                    
                    # Declarations
                    terms_accepted=declarations.get('terms_accepted', False),
                    data_protection_accepted=declarations.get('data_protection_accepted', False),
                    certification_declaration_accepted=declarations.get('certification_declaration_accepted', False),
                    seta_declaration_accepted=declarations.get('seta_declaration_accepted', False),
                    
                    # Payment tracking
                    total_amount=transaction.amount,
                    currency=transaction.currency,
                    amount_paid=transaction.amount if transaction.status == PaymentStatus.SUCCESSFUL else 0,
                    
                    # Metadata for additional data
                    metadata=metadata
                )
                
                logger.info(
                    f"Created learnership enrollment (provisional) for user {user.email}: "
                    f"ProvisionalEnrollment={provisional.id}, LearnershipEnrollment={learnership_enrollment.id}"
                )
                
            except LearnershipProgramme.DoesNotExist:
                logger.error(f"LearnershipProgramme {program_id} not found")

        elif enrollment_type in ['industry_training', 'role_training']:
            # Student paid for industry-specific or role-based training
            # Creates IndustryTrainingEnrollment and generic Enrollment record
            # Enrolls user in AICerts LMS using first name and surname
            from apps.industry_based_training.models import (
                IndustryTrainingEnrollment,
                AiCertsCourse as IndustryCourse,
                Offering
            )
            from apps.payments.models import Enrollment as GenericEnrollment, EnrollmentType as GenericEnrollmentType
            from django.contrib.contenttypes.models import ContentType
            import uuid

            program_id = transaction.metadata.get('program_id')
            course_ids = transaction.metadata.get('course_ids', [])

            # Extract demographic data from enrollment form
            individual_details = transaction.metadata.get('individual_details', {})
            terms_accepted_flag = transaction.metadata.get('terms_accepted', True)

            # Parse date of birth safely
            it_dob_value = None
            it_dob_raw = individual_details.get('date_of_birth', '')
            if it_dob_raw:
                try:
                    from datetime import datetime as _dt
                    it_dob_value = _dt.strptime(it_dob_raw, '%d/%m/%Y').date()
                except (ValueError, TypeError):
                    try:
                        from datetime import date as _d
                        it_dob_value = _d.fromisoformat(it_dob_raw)
                    except (ValueError, TypeError):
                        pass
            
            # Determine content based on enrollment type
            offering = None
            courses = []
            content_object = None
            
            if enrollment_type == 'role_training' and program_id:
                # Enroll in Offering (bundle of courses)
                try:
                    offering = Offering.objects.get(id=program_id)
                    courses = list(offering.courses.all())
                    content_object = offering
                    logger.info(f"Role training: Found offering '{offering.name}' with {len(courses)} courses")
                except Offering.DoesNotExist:
                    logger.error(f"Offering {program_id} not found for role_training")
                    return
            
            elif enrollment_type == 'industry_training' and course_ids:
                # Enroll in specific industry courses
                courses = list(IndustryCourse.objects.filter(id__in=course_ids))
                if courses:
                    content_object = courses[0]  # Use first course for generic enrollment
                    logger.info(f"Industry training: Found {len(courses)} courses")
                else:
                    logger.error(f"No industry courses found for course_ids {course_ids}")
                    return
            
            else:
                logger.error(f"No content found for {enrollment_type} tx {transaction.id}")
                return
            
            if not content_object:
                logger.error(f"No content object for {enrollment_type} tx {transaction.id}")
                return
            
            # Create industry training enrollment
            industry_enrollment = IndustryTrainingEnrollment.objects.create(
                user=user,
                enrollment_type=enrollment_type,
                content_type=ContentType.objects.get_for_model(content_object),
                object_id=content_object.id,
                payment_transaction=transaction,
                status='enrolled',
                payment_status='paid' if transaction.status == PaymentStatus.SUCCESSFUL else 'pending',
                amount_paid=transaction.amount,
                currency=transaction.currency,
                metadata=transaction.metadata or {}
            )
            
            # Enroll in each course on AICerts
            enrolled_count = 0
            for course in courses:
                # Use raw_course for AICerts enrollment (has lms_course_id)
                aicerts_course = course.raw_course if course.raw_course else course
                if not hasattr(aicerts_course, 'lms_course_id') or not aicerts_course.lms_course_id:
                    logger.warning(f"Course {course.title} has no lms_course_id - skipping AICerts enrollment")
                    continue
                
                try:
                    # EnrollmentSyncService handles user creation and enrollment
                    # Uses user.first_name and user.last_name for AICerts API
                    aicerts_enrollment, aicerts_result = EnrollmentSyncService.enroll_user_in_course(
                        user, 
                        aicerts_course
                    )
                    industry_enrollment.aicerts_enrollment_ids.append(aicerts_enrollment.id)
                    if aicerts_result.get('isUserAlreadyEnrolled') == '1':
                        industry_enrollment.aicerts_already_enrolled = True
                    enrolled_count += 1
                    logger.info(f"Enrolled {user.email} in AICerts course {aicerts_course.title}")
                except Exception as e:
                    logger.error(f"Failed to enroll {user.email} in course {course.title}: {e}")
            
            industry_enrollment.save()
            
            # Create generic Enrollment record for Sales Admin tracking
            # Build learner list: primary learner + any additional from metadata
            learners_data = transaction.metadata.get('learners', [])
            primary_details = individual_details if individual_details else (learners_data[0] if learners_data else {})
            all_learner_details = [primary_details] + (learners_data[1:] if len(learners_data) > 1 else [])

            for idx, ldata in enumerate(all_learner_details if all_learner_details else [{}]):
                try:
                    l_dob_value = it_dob_value if idx == 0 else None
                    l_dob_raw = ldata.get('date_of_birth', '')
                    if l_dob_raw and idx > 0:
                        try:
                            from datetime import datetime as _dt2
                            l_dob_value = _dt2.strptime(l_dob_raw, '%d/%m/%Y').date()
                        except (ValueError, TypeError):
                            pass

                    GenericEnrollment.objects.create(
                        enrollment_type=GenericEnrollmentType.INDUSTRY_TRAINING if enrollment_type == 'industry_training' else GenericEnrollmentType.ROLE_TRAINING,
                        content_type=ContentType.objects.get_for_model(content_object),
                        object_id=content_object.id,
                        enrollment_code=f"INDUSTRY_{uuid.uuid4().hex[:8].upper()}",
                        user=user,
                        status=GenericEnrollmentStatus.ENROLLED,
                        industry_enrollment_id=industry_enrollment.id,
                        learner_full_name=ldata.get('full_name') or user.get_full_name() or user.username,
                        learner_email=ldata.get('email') or user.email,
                        learner_phone=ldata.get('phone') or getattr(user, 'phone', '') or '+1234567890',
                        learner_id_number=ldata.get('id_number') or None,
                        learner_dob=l_dob_value,
                        learner_gender=ldata.get('gender') or None,
                        learner_address=ldata.get('address') or None,
                        learner_city=ldata.get('city') or None,
                        learner_country=ldata.get('country_id') and str(ldata['country_id']) or transaction.country,
                        learner_postal_code=ldata.get('postal_code') or None,
                        current_occupation=ldata.get('occupation') or None,
                        education_level=ldata.get('education_level') or None,
                        institution=ldata.get('institution') or None,
                        emergency_contact_name=ldata.get('emergency_name') or None,
                        emergency_contact_phone=ldata.get('emergency_phone') or None,
                        emergency_contact_relationship=ldata.get('emergency_relationship') or None,
                        dietary_requirements=ldata.get('dietary_requirements') or None,
                        accessibility_needs=ldata.get('accessibility_requirements') or None,
                        additional_notes=ldata.get('additional_notes') or None,
                        final_amount=transaction.amount,
                        currency=transaction.currency,
                        order=transaction.order,
                        terms_accepted=terms_accepted_flag,
                        terms_accepted_at=timezone.now() if terms_accepted_flag else None,
                        enrolled_at=timezone.now(),
                        enrollment_data={
                            'transaction_id': str(transaction.id),
                            'provider_reference': transaction.provider_reference,
                            'payment_status': transaction.status,
                            'industry_enrollment_id': industry_enrollment.id,
                            'enrolled_courses_count': enrolled_count,
                            'learner_index': idx,
                        }
                    )
                    logger.info(f"Created generic Enrollment [{idx}] for {enrollment_type} - {content_object}")
                except Exception as e:
                    logger.error(f"Failed to create generic Enrollment [{idx}]: {e}")
                    import traceback
                    traceback.print_exc()
            
            logger.info(
                f"Created industry training enrollment for {user.email}: "
                f"IndustryTrainingEnrollment={industry_enrollment.id}, enrolled in {enrolled_count} AICerts courses"
            )

    def _enroll_user_in_course(self, user, course_id):
        """Enroll user in single course (legacy handler)"""
        from apps.aicerts_integration.services import SSOService
        from apps.aicerts_courses.models import AiCertsCourse
        
        try:
            course = AiCertsCourse.objects.get(id=course_id)
            sso_service = SSOService()
            sso_service.enroll_user(user, course)
            logger.info(f"Successfully enrolled user {user.email} in course {course.title}")
        except Exception as e:
            logger.error(f"Failed to enroll user in course {course_id}: {str(e)}")
    
    def _send_payment_notifications(self, transaction: PaymentTransaction):
        """
        Send async payment notifications (email + SMS)

        Uses Celery to send notifications asynchronously:
        - Email confirmation
        - SMS confirmation (if phone number available)

        Args:
            transaction: Successful payment transaction
        """
        try:
            # Import Celery task
            from ..tasks import send_payment_notifications

            # Queue notifications (async via Celery)
            send_payment_notifications.delay(
                transaction_id=str(transaction.id),
                include_sms=True
            )

            logger.info(
                f"Payment notifications queued for transaction {transaction.id}",
                extra={
                    'transaction_id': str(transaction.id),
                    'user_id': transaction.user.id,
                    'amount': float(transaction.amount),
                }
            )

        except Exception as e:
            logger.error(
                f"Failed to queue payment notifications: {str(e)}",
                extra={'transaction_id': str(transaction.id)}
            )
            # Fallback to synchronous email if Celery fails
            self._send_payment_confirmation_fallback(transaction)

    def _send_payment_confirmation_fallback(self, transaction: PaymentTransaction):
        """
        Fallback method to send email synchronously if Celery is unavailable

        Args:
            transaction: Payment transaction
        """
        from django.core.mail import send_mail

        try:
            subject = f"Payment Confirmation - Hosi Academy"
            message = f"""
Dear {transaction.user.get_full_name() or transaction.user.email},

Your payment of {transaction.amount} {transaction.currency} has been confirmed.
Transaction Reference: {transaction.provider_reference}

Thank you for your purchase!

Best regards,
Hosi Academy Team
            """

            send_mail(
                subject,
                message,
                settings.DEFAULT_FROM_EMAIL,
                [transaction.user.email],
                fail_silently=True,
            )

            logger.warning(
                f"Sent payment email via fallback (Celery unavailable)",
                extra={'transaction_id': str(transaction.id)}
            )

        except Exception as e:
            logger.error(f"Fallback email also failed: {str(e)}")
    
    def _update_instructor_revenue(self, transaction: PaymentTransaction):
        """Update instructor revenue after successful payment"""
        try:
            from ..models import InstructorPayout
            
            # Get instructor ID from metadata or order items
            instructor_id = transaction.metadata.get('instructor_id')
            if not instructor_id and transaction.order:
                # Get from first order item
                item = transaction.order.items.first()
                if item:
                    instructor_id = item.instructor_id
            
            if instructor_id:
                payout, created = InstructorPayout.objects.get_or_create(
                    instructor_id=instructor_id,
                )
                payout.revenue += transaction.amount
                payout.pending_amount += transaction.amount * 0.7  # 70% to instructor
                payout.save()
                
        except Exception as e:
            logger.error(f"Failed to update instructor revenue: {str(e)}")
    
    def reconcile_payments(self, provider_code: str, date=None):
        """
        Reconcile payments for provider
        
        Args:
            provider_code: Provider code
            date: Reconciliation date (defaults to yesterday)
        """
        from ..models import PaymentReconciliation
        from datetime import datetime, timedelta
        
        try:
            if not date:
                date = (datetime.now() - timedelta(days=1)).date()
            
            # Get provider configs
            configs = ProviderCountryConfig.objects.filter(
                provider__code=provider_code,
                is_active=True,
            )
            
            for config in configs:
                # Create reconciliation record
                reconciliation = PaymentReconciliation.objects.create(
                    provider_config=config,
                    reconciliation_date=date,
                    currency=config.supported_currencies[0] if config.supported_currencies else 'USD',
                    status='processing',
                    started_at=timezone.now(),
                )
                
                try:
                    # Get transactions for date
                    transactions = PaymentTransaction.objects.filter(
                        provider_config=config,
                        created_at__date=date,
                        reconciled=False,
                    )
                    
                    # Get adapter for fetching provider statement
                    adapter = self.get_adapter_for_provider(provider_code, config)
                    
                    # Fetch provider statement (implementation depends on provider)
                    # provider_data = adapter.fetch_statement(date)
                    
                    # Match transactions
                    matched = 0
                    total_amount = 0
                    
                    for tx in transactions:
                        # Try to match with provider data
                        # if self._match_transaction(tx, provider_data):
                        #     tx.reconciled = True
                        #     tx.reconciliation_date = date
                        #     tx.save()
                        #     matched += 1
                        total_amount += float(tx.amount)
                    
                    # Update reconciliation
                    reconciliation.total_transactions = transactions.count()
                    reconciliation.matched_transactions = matched
                    reconciliation.unmatched_transactions = transactions.count() - matched
                    reconciliation.total_amount = total_amount
                    reconciliation.matched_amount = total_amount  # Simplified
                    reconciliation.status = 'completed'
                    reconciliation.completed_at = timezone.now()
                    reconciliation.save()
                    
                    logger.info(
                        f"Reconciliation completed for {provider_code} on {date}: "
                        f"{matched}/{transactions.count()} matched",
                        extra={
                            'provider': provider_code,
                            'date': date.isoformat(),
                            'matched': matched,
                            'total': transactions.count(),
                        }
                    )
                    
                except Exception as e:
                    reconciliation.status = 'failed'
                    reconciliation.notes = str(e)
                    reconciliation.save()
                    logger.error(f"Reconciliation failed: {str(e)}")
                    
        except Exception as e:
            logger.error(f"Reconciliation process failed: {str(e)}")
            raise PaymentError(f"Reconciliation failed: {str(e)}")


# Singleton instance
payment_service = PaymentService()