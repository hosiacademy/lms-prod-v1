"""
Sentry Integration for Payment System
Provides comprehensive error tracking, performance monitoring, and debugging

Features:
- Payment transaction performance monitoring
- Payment funnel analysis (initiation → completion)
- Error tracking with full payment context
- Provider performance comparison
- Revenue tracking and alerts
- User experience monitoring
- Webhook delivery tracking
- SMS/Email notification monitoring
"""
import logging
import time
from typing import Dict, Optional, Any, Callable
from functools import wraps
from decimal import Decimal
from django.conf import settings
from django.utils import timezone

logger = logging.getLogger(__name__)

# Check if Sentry is available
try:
    import sentry_sdk
    from sentry_sdk import (
        capture_exception, capture_message, set_context, set_tag, 
        set_user, add_breadcrumb, start_transaction, start_span
    )
    from sentry_sdk.tracing import Transaction
    SENTRY_AVAILABLE = True
except ImportError:
    SENTRY_AVAILABLE = False
    logger.warning("Sentry SDK not installed - error tracking disabled")


class SentryPaymentMonitor:
    """
    Custom Sentry integration for payment monitoring

    Features:
    - Transaction performance tracking
    - Payment event breadcrumbs
    - Custom context for debugging
    - User identification
    - Tag-based filtering
    """

    def __init__(self):
        self.enabled = SENTRY_AVAILABLE and hasattr(settings, 'SENTRY_DSN') and settings.SENTRY_DSN

        if self.enabled:
            logger.info("Sentry payment monitoring enabled")
        else:
            logger.warning("Sentry payment monitoring disabled")

    def track_payment_initiation(self, transaction):
        """Track when a payment is initiated"""
        if not self.enabled:
            return

        try:
            # Add breadcrumb
            sentry_sdk.add_breadcrumb(
                category='payment',
                message='Payment initiated',
                level='info',
                data={
                    'transaction_id': str(transaction.id),
                    'amount': float(transaction.amount),
                    'currency': transaction.currency,
                    'provider': transaction.provider,
                    'country': transaction.country,
                }
            )

            # Set context
            set_context('payment_initiation', {
                'transaction_id': str(transaction.id),
                'amount': float(transaction.amount),
                'currency': transaction.currency,
                'provider': transaction.provider,
                'country': transaction.country,
                'description': transaction.description,
            })

            # Set tags for filtering
            set_tag('payment.provider', transaction.provider)
            set_tag('payment.currency', transaction.currency)
            set_tag('payment.country', transaction.country)

            # Set user context
            if transaction.user:
                set_user({
                    'id': str(transaction.user.id),
                    'email': transaction.user.email,
                    'username': transaction.user.username,
                })

        except Exception as e:
            logger.error(f"Error tracking payment initiation in Sentry: {e}")

    def track_payment_success(self, transaction):
        """Track successful payment"""
        if not self.enabled:
            return

        try:
            # Add breadcrumb
            sentry_sdk.add_breadcrumb(
                category='payment',
                message='Payment successful',
                level='info',
                data={
                    'transaction_id': str(transaction.id),
                    'amount': float(transaction.amount),
                    'currency': transaction.currency,
                    'provider_reference': transaction.provider_reference,
                }
            )

            # Set tags
            set_tag('payment.status', 'successful')
            set_tag('payment.amount_range', self._get_amount_range(float(transaction.amount)))

            # Capture message for analytics
            capture_message(
                f"Payment successful: {transaction.currency} {transaction.amount}",
                level='info'
            )

        except Exception as e:
            logger.error(f"Error tracking payment success in Sentry: {e}")

    def track_payment_failure(self, transaction, error_message: str = None):
        """Track failed payment"""
        if not self.enabled:
            return

        try:
            # Add breadcrumb
            sentry_sdk.add_breadcrumb(
                category='payment',
                message='Payment failed',
                level='error',
                data={
                    'transaction_id': str(transaction.id),
                    'amount': float(transaction.amount),
                    'currency': transaction.currency,
                    'error': error_message,
                }
            )

            # Set tags
            set_tag('payment.status', 'failed')

            # Set failure context
            set_context('payment_failure', {
                'transaction_id': str(transaction.id),
                'error_message': error_message,
                'provider': transaction.provider,
                'amount': float(transaction.amount),
            })

            # Capture the failure
            capture_message(
                f"Payment failed: {error_message or 'Unknown error'}",
                level='error'
            )

        except Exception as e:
            logger.error(f"Error tracking payment failure in Sentry: {e}")

    def track_webhook_received(self, provider: str, event_type: str, payload: Dict):
        """Track webhook reception"""
        if not self.enabled:
            return

        try:
            # Add breadcrumb
            sentry_sdk.add_breadcrumb(
                category='webhook',
                message=f'Webhook received: {event_type}',
                level='info',
                data={
                    'provider': provider,
                    'event_type': event_type,
                    'payload_size': len(str(payload)),
                }
            )

            # Set tags
            set_tag('webhook.provider', provider)
            set_tag('webhook.event_type', event_type)

        except Exception as e:
            logger.error(f"Error tracking webhook in Sentry: {e}")

    def track_sms_sent(self, transaction_id: str, phone_number: str, success: bool, error: str = None):
        """Track SMS delivery"""
        if not self.enabled:
            return

        try:
            # Add breadcrumb
            sentry_sdk.add_breadcrumb(
                category='notification',
                message=f'SMS {"sent" if success else "failed"}',
                level='info' if success else 'warning',
                data={
                    'transaction_id': transaction_id,
                    'phone_number': phone_number[-4:],  # Only last 4 digits for privacy
                    'success': success,
                    'error': error,
                }
            )

            # Set tags
            set_tag('notification.type', 'sms')
            set_tag('notification.success', str(success))

            # Capture failure
            if not success:
                capture_message(
                    f"SMS delivery failed: {error}",
                    level='warning'
                )

        except Exception as e:
            logger.error(f"Error tracking SMS in Sentry: {e}")

    def track_email_sent(self, transaction_id: str, email: str, success: bool, error: str = None):
        """Track email delivery"""
        if not self.enabled:
            return

        try:
            # Add breadcrumb
            sentry_sdk.add_breadcrumb(
                category='notification',
                message=f'Email {"sent" if success else "failed"}',
                level='info' if success else 'warning',
                data={
                    'transaction_id': transaction_id,
                    'email': email,
                    'success': success,
                    'error': error,
                }
            )

            # Set tags
            set_tag('notification.type', 'email')
            set_tag('notification.success', str(success))

            # Capture failure
            if not success:
                capture_message(
                    f"Email delivery failed: {error}",
                    level='warning'
                )

        except Exception as e:
            logger.error(f"Error tracking email in Sentry: {e}")

    def capture_payment_exception(
        self,
        exception: Exception,
        transaction=None,
        context: Dict[str, Any] = None
    ):
        """
        Capture payment-related exception with full context

        Args:
            exception: The exception to capture
            transaction: Optional payment transaction object
            context: Additional context dictionary
        """
        if not self.enabled:
            return

        try:
            # Add transaction context if available
            if transaction:
                set_context('transaction', {
                    'id': str(transaction.id),
                    'amount': float(transaction.amount),
                    'currency': transaction.currency,
                    'provider': transaction.provider,
                    'status': transaction.status,
                    'user_id': str(transaction.user.id) if transaction.user else None,
                })

                # Set tags
                set_tag('payment.provider', transaction.provider)
                set_tag('payment.status', transaction.status)

            # Add custom context
            if context:
                set_context('custom', context)

            # Capture the exception
            capture_exception(exception)

            logger.error(
                f"Payment exception captured in Sentry: {str(exception)}",
                extra={
                    'transaction_id': str(transaction.id) if transaction else None,
                    'exception_type': type(exception).__name__,
                }
            )

        except Exception as e:
            logger.error(f"Error capturing exception in Sentry: {e}")

    def start_transaction(self, name: str, op: str) -> Optional[Any]:
        """
        Start a Sentry transaction for performance monitoring

        Args:
            name: Transaction name (e.g., "payment.initiate")
            op: Operation type (e.g., "payment", "webhook")

        Returns:
            Transaction object or None
        """
        if not self.enabled:
            return None

        try:
            return sentry_sdk.start_transaction(
                name=name,
                op=op,
            )
        except Exception as e:
            logger.error(f"Error starting Sentry transaction: {e}")
            return None

    def _get_amount_range(self, amount: float) -> str:
        """Categorize transaction amount for filtering"""
        if amount < 50:
            return 'micro'
        elif amount < 200:
            return 'small'
        elif amount < 1000:
            return 'medium'
        elif amount < 5000:
            return 'large'
        else:
            return 'enterprise'


# Decorator for automatic Sentry transaction monitoring
def monitor_payment_performance(operation_name: str):
    """
    Decorator to automatically monitor function performance in Sentry

    Usage:
        @monitor_payment_performance('payment.initiate')
        def initiate_payment(transaction):
            ...
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            if not SENTRY_AVAILABLE:
                return func(*args, **kwargs)

            # Start transaction
            with sentry_sdk.start_transaction(
                op='payment',
                name=operation_name
            ) as transaction:
                try:
                    # Execute function
                    result = func(*args, **kwargs)

                    # Mark as successful
                    transaction.set_status('ok')

                    return result

                except Exception as e:
                    # Mark as failed
                    transaction.set_status('internal_error')

                    # Capture exception
                    capture_exception(e)

                    # Re-raise
                    raise

        return wrapper
    return decorator


# Singleton instance
sentry_monitor = SentryPaymentMonitor()


# ============================================================
# PAYMENT FLOW MONITORING - Full Stack Integration
# ============================================================

class PaymentFlowTracker:
    """
    Comprehensive payment flow tracking with Sentry
    
    Tracks the entire payment journey:
    1. User clicks "Pay Now"
    2. Payment initiation
    3. Redirect to gateway (if applicable)
    4. Payment processing
    5. Webhook/callback received
    6. Payment completion/failure
    7. Enrollment confirmation
    """
    
    def __init__(self):
        self.monitor = sentry_monitor
    
    def track_payment_funnel(self, func: Callable) -> Callable:
        """
        Decorator to track payment funnel metrics
        
        Usage:
            @track_payment_funnel
            def initiate_payment(request):
                ...
        """
        @wraps(func)
        def wrapper(*args, **kwargs):
            if not SENTRY_AVAILABLE:
                return func(*args, **kwargs)
            
            # Start transaction
            transaction = start_transaction(
                op="payment.funnel",
                name="payment.initiate_to_complete"
            )
            
            try:
                # Set initial tags
                transaction.set_tag("payment.stage", "initiation")
                
                # Execute function
                result = func(*args, **kwargs)
                
                # Mark success
                transaction.set_tag("payment.success", "true")
                transaction.set_status("ok")
                
                return result
                
            except Exception as e:
                # Mark failure
                transaction.set_tag("payment.success", "false")
                transaction.set_status("internal_error")
                capture_exception(e)
                raise
                
            finally:
                transaction.finish()
        
        return wrapper
    
    def start_payment_span(self, provider: str, amount: Decimal, currency: str) -> Optional[Transaction]:
        """
        Start a payment tracking span
        
        Returns transaction object for manual control
        """
        if not SENTRY_AVAILABLE:
            return None
        
        transaction = start_transaction(
            op="payment.processing",
            name=f"payment.{provider}"
        )
        
        # Set payment details
        transaction.set_tag("payment.provider", provider)
        transaction.set_tag("payment.amount", str(amount))
        transaction.set_tag("payment.currency", currency)
        transaction.set_data("payment.amount_float", float(amount))
        
        return transaction
    
    def track_provider_performance(self, provider: str, duration_ms: float, success: bool):
        """
        Track payment provider performance metrics
        
        This helps identify slow or unreliable providers
        """
        if not SENTRY_AVAILABLE:
            return
        
        # Add breadcrumb for tracking
        add_breadcrumb(
            category="payment.performance",
            message=f"{provider} payment {'successful' if success else 'failed'}",
            level="info" if success else "warning",
            data={
                "provider": provider,
                "duration_ms": duration_ms,
                "success": success,
                "performance_tier": self._get_performance_tier(duration_ms),
            }
        )
        
        # Set metrics as tags
        set_tag(f"provider.{provider}.duration_ms", str(duration_ms))
        set_tag(f"provider.{provider}.success", str(success))
    
    def track_revenue(self, amount: Decimal, currency: str, provider: str, country: str):
        """
        Track revenue metrics in Sentry
        
        Useful for business analytics and alerts
        """
        if not SENTRY_AVAILABLE:
            return
        
        # Add revenue breadcrumb
        add_breadcrumb(
            category="payment.revenue",
            message=f"Revenue: {currency} {amount}",
            level="info",
            data={
                "amount": str(amount),
                "currency": currency,
                "provider": provider,
                "country": country,
                "amount_usd": self._convert_to_usd(float(amount), currency),
            }
        )
        
        # Set revenue tags
        set_tag("revenue.currency", currency)
        set_tag("revenue.provider", provider)
        set_tag("revenue.country", country)
    
    def track_checkout_redirect(self, provider: str, checkout_url: str, success: bool):
        """
        Track redirect to payment gateway checkout
        
        Important for identifying redirect failures
        """
        if not SENTRY_AVAILABLE:
            return
        
        add_breadcrumb(
            category="payment.redirect",
            message=f"Redirect to {provider} {'successful' if success else 'failed'}",
            level="info" if success else "error",
            data={
                "provider": provider,
                "checkout_url": checkout_url[:50] + "..." if len(checkout_url) > 50 else checkout_url,
                "success": success,
            }
        )
        
        set_tag("checkout.provider", provider)
        set_tag("checkout.success", str(success))
    
    def track_webhook_processing(self, provider: str, event_type: str, processing_time_ms: float, success: bool):
        """
        Track webhook processing performance
        
        Helps identify webhook delivery issues
        """
        if not SENTRY_AVAILABLE:
            return
        
        add_breadcrumb(
            category="payment.webhook",
            message=f"Webhook {event_type} processed in {processing_time_ms}ms",
            level="info" if success else "warning",
            data={
                "provider": provider,
                "event_type": event_type,
                "processing_time_ms": processing_time_ms,
                "success": success,
            }
        )
        
        set_tag("webhook.provider", provider)
        set_tag("webhook.event_type", event_type)
        set_tag("webhook.processing_time_ms", str(processing_time_ms))
    
    def track_enrollment_confirmation(self, enrollment_id: str, program_type: str, payment_provider: str):
        """
        Track successful enrollment confirmation after payment
        
        Final step in the payment funnel
        """
        if not SENTRY_AVAILABLE:
            return
        
        add_breadcrumb(
            category="payment.enrollment",
            message=f"Enrollment confirmed: {enrollment_id}",
            level="info",
            data={
                "enrollment_id": enrollment_id,
                "program_type": program_type,
                "payment_provider": payment_provider,
            }
        )
        
        set_tag("enrollment.program_type", program_type)
        set_tag("enrollment.provider", payment_provider)
        
        # Capture confirmation message
        capture_message(
            f"Enrollment confirmed via {payment_provider}: {enrollment_id}",
            level="info"
        )
    
    def _get_performance_tier(self, duration_ms: float) -> str:
        """Categorize payment processing time"""
        if duration_ms < 1000:
            return "excellent"
        elif duration_ms < 3000:
            return "good"
        elif duration_ms < 10000:
            return "acceptable"
        elif duration_ms < 30000:
            return "slow"
        else:
            return "critical"
    
    def _convert_to_usd(self, amount: float, currency: str) -> float:
        """Rough USD conversion for reporting"""
        # Simplified conversion rates (in production, use real-time rates)
        rates = {
            'USD': 1.0,
            'ZAR': 0.053,
            'KES': 0.0077,
            'NGN': 0.0012,
            'GHS': 0.083,
            'EGP': 0.032,
            'TZS': 0.00038,
            'ZWL': 0.0031,
        }
        return amount * rates.get(currency.upper(), 0.05)


# Decorator for payment flow tracking
payment_flow_tracker = PaymentFlowTracker()


def track_payment_flow(operation_name: str):
    """
    Decorator to track complete payment flow in Sentry
    
    Usage:
        @track_payment_flow('initiate_payment')
        def initiate_payment(request):
            ...
    """
    def decorator(func: Callable) -> Callable:
        @wraps(func)
        def wrapper(*args, **kwargs):
            if not SENTRY_AVAILABLE:
                return func(*args, **kwargs)
            
            # Start transaction
            with start_transaction(
                op="payment.flow",
                name=f"payment.{operation_name}"
            ) as transaction:
                start_time = time.time()
                
                try:
                    # Execute function
                    result = func(*args, **kwargs)
                    
                    # Track success
                    duration_ms = (time.time() - start_time) * 1000
                    transaction.set_tag("payment.duration_ms", str(duration_ms))
                    transaction.set_tag("payment.success", "true")
                    transaction.set_status("ok")
                    
                    # Add success breadcrumb
                    add_breadcrumb(
                        category="payment.flow",
                        message=f"{operation_name} completed in {duration_ms:.2f}ms",
                        level="info",
                        data={
                            "operation": operation_name,
                            "duration_ms": duration_ms,
                        }
                    )
                    
                    return result
                    
                except Exception as e:
                    # Track failure
                    duration_ms = (time.time() - start_time) * 1000
                    transaction.set_tag("payment.duration_ms", str(duration_ms))
                    transaction.set_tag("payment.success", "false")
                    transaction.set_status("internal_error")
                    
                    # Add failure breadcrumb
                    add_breadcrumb(
                        category="payment.flow",
                        message=f"{operation_name} failed after {duration_ms:.2f}ms",
                        level="error",
                        data={
                            "operation": operation_name,
                            "duration_ms": duration_ms,
                            "error": str(e),
                        }
                    )
                    
                    # Capture exception
                    capture_exception(e)
                    raise
        
        return wrapper
    return decorator
