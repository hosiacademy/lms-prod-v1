"""
Celery Tasks for Payment Notifications and Provisioning
Handles async email, SMS delivery, and enrollment provisioning
"""
import logging
from celery import shared_task
from django.core.mail import send_mail
from django.conf import settings
from django.utils import timezone
from datetime import timedelta
import requests

# Import Sentry monitoring
from apps.payments.services.sentry_service import sentry_monitor

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def provision_enrollment_async(self, transaction_id: str):
    """
    Async task to provision enrollment after successful payment.
    
    This decouples the financial transaction (payment success) from fulfillment (enrollment).
    If external APIs (AICerts, Moodle, email) fail, the payment remains successful,
    and this task retries automatically.
    
    Args:
        transaction_id: UUID of the payment transaction
        
    Retries: 3 times with 5-minute delay. After max retries, logs error for manual review.
    """
    from apps.payments.models import PaymentTransaction, PaymentStatus
    from apps.payments.services.payment_service import payment_service
    
    try:
        # Get transaction with select_for_update to prevent race conditions
        transaction = PaymentTransaction.objects.select_for_update().get(id=transaction_id)
        
        # Idempotency check: Skip if already provisioned
        if transaction.metadata.get('provisioning_completed'):
            logger.info(f"Provisioning already completed for transaction {transaction_id}")
            return {'success': True, 'skipped': True, 'reason': 'Already provisioned'}
        
        # Check if payment is actually successful
        if transaction.status != PaymentStatus.SUCCESSFUL:
            logger.warning(f"Payment not successful for transaction {transaction_id}, status={transaction.status}")
            return {'success': False, 'error': 'Payment not successful'}
        
        # Provision enrollment
        enrollment_type = transaction.enrollment_type or transaction.metadata.get('enrollment_type')
        program_id = transaction.metadata.get('program_id')
        
        has_content = program_id or (
            enrollment_type == 'custom_selection' and 
            transaction.metadata.get('course_ids', [])
        )
        
        if enrollment_type and has_content:
            payment_service._provision_enrollment(
                user=transaction.user,
                enrollment_type=enrollment_type,
                program_id=program_id,
                transaction=transaction
            )
            
            # Mark provisioning as completed
            transaction.metadata['provisioning_completed'] = True
            transaction.metadata['provisioning_completed_at'] = timezone.now().isoformat()
            transaction.save(update_fields=['metadata'])
            
            logger.info(
                f"Enrollment provisioned successfully for transaction {transaction_id}",
                extra={
                    'user_email': transaction.user.email if transaction.user else 'unknown',
                    'enrollment_type': enrollment_type,
                }
            )
            
            # Track in Sentry
            sentry_monitor.track_webhook_processed(
                transaction_id=str(transaction_id),
                success=True
            )
            
            return {'success': True, 'enrollment_type': enrollment_type}
        else:
            logger.warning(f"No enrollment data for transaction {transaction_id}")
            return {'success': False, 'error': 'No enrollment data'}
            
    except Exception as e:
        error_msg = f"Provisioning failed for transaction {transaction_id}: {str(e)}"
        logger.error(error_msg, exc_info=True)
        
        # Track failure in Sentry
        sentry_monitor.track_webhook_processed(
            transaction_id=str(transaction_id),
            success=False,
            error=str(e)
        )
        
        # Retry on failure (Celery will handle retries based on decorator)
        raise self.retry(exc=e, countdown=self.request.retries * 300)


@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def fetch_exchange_rates(self):
    """
    Fetch exchange rates from external API and cache them.
    Runs daily via Celery Beat.
    
    Uses exchangerate-api.com (free tier: 1500 requests/month)
    Alternative: exchangeratesapi.io, openexchangerates.org
    """
    from apps.payments.exchange_rate_models import ExchangeRate, ExchangeRateLog
    
    # African currencies to fetch
    AFRICAN_CURRENCIES = {
        'ZAR': ('South African Rand', 'R', 'ZA', 'South Africa'),
        'KES': ('Kenyan Shilling', 'KSh', 'KE', 'Kenya'),
        'NGN': ('Nigerian Naira', '₦', 'NG', 'Nigeria'),
        'GHS': ('Ghanaian Cedi', 'GH₵', 'GH', 'Ghana'),
        'TZS': ('Tanzanian Shilling', 'TSh', 'TZ', 'Tanzania'),
        'UGX': ('Ugandan Shilling', 'USh', 'UG', 'Uganda'),
        'ETB': ('Ethiopian Birr', 'Br', 'ET', 'Ethiopia'),
        'RWF': ('Rwandan Franc', 'FRw', 'RW', 'Rwanda'),
        'ZMW': ('Zambian Kwacha', 'ZK', 'ZM', 'Zambia'),
        'ZWL': ('Zimbabwean Dollar', 'Z$', 'ZW', 'Zimbabwe'),
        'BWP': ('Botswana Pula', 'P', 'BW', 'Botswana'),
        'MZN': ('Mozambican Metical', 'MT', 'MZ', 'Mozambique'),
        'MWK': ('Malawian Kwacha', 'MK', 'MW', 'Malawi'),
        'NAD': ('Namibian Dollar', 'N$', 'NA', 'Namibia'),
        'SZL': ('Swazi Lilangeni', 'E', 'SZ', 'Eswatini'),
        'LSL': ('Lesotho Loti', 'L', 'LS', 'Lesotho'),
        'EGP': ('Egyptian Pound', '£', 'EG', 'Egypt'),
        'MAD': ('Moroccan Dirham', 'DH', 'MA', 'Morocco'),
        'TND': ('Tunisian Dinar', 'د.ت', 'TN', 'Tunisia'),
        'DZD': ('Algerian Dinar', 'د.ج', 'DZ', 'Algeria'),
        'XOF': ('West African CFA Franc', 'CFA', 'SN', 'Senegal'),
        'XAF': ('Central African CFA Franc', 'FCFA', 'CM', 'Cameroon'),
        'CDF': ('Congolese Franc', 'FC', 'CD', 'DR Congo'),
        'BIF': ('Burundian Franc', 'FBu', 'BI', 'Burundi'),
        'GNF': ('Guinean Franc', 'FG', 'GN', 'Guinea'),
        'LRD': ('Liberian Dollar', 'L$', 'LR', 'Liberia'),
        'SLL': ('Sierra Leonean Leone', 'Le', 'SL', 'Sierra Leone'),
        'AOA': ('Angolan Kwanza', 'Kz', 'AO', 'Angola'),
        'MGA': ('Malagasy Ariary', 'Ar', 'MG', 'Madagascar'),
        'MUR': ('Mauritian Rupee', '₨', 'MU', 'Mauritius'),
        'SCR': ('Seychellois Rupee', '₨', 'SC', 'Seychelles'),
        'SDG': ('Sudanese Pound', 'ج.س.', 'SD', 'Sudan'),
        'SOS': ('Somali Shilling', 'S', 'SO', 'Somalia'),
        'DJF': ('Djiboutian Franc', 'Fdj', 'DJ', 'Djibouti'),
        'MRU': ('Mauritanian Ouguiya', 'UM', 'MR', 'Mauritania'),
        'GMD': ('Gambian Dalasi', 'D', 'GM', 'Gambia'),
    }
    
    try:
        # Use free API - no key required for base endpoint
        API_URL = "https://api.exchangerate-api.com/v4/latest/USD"
        
        logger.info(f"Fetching exchange rates from {API_URL}")
        
        response = requests.get(API_URL, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        rates = data.get('rates', {})
        
        if not rates:
            raise Exception("No rates in API response")
        
        rates_count = 0
        for currency_code, rate in rates.items():
            if currency_code in AFRICAN_CURRENCIES:
                currency_name, symbol, country_code, country_name = AFRICAN_CURRENCIES[currency_code]
                
                ExchangeRate.objects.update_or_create(
                    currency_code=currency_code,
                    defaults={
                        'rate': rate,
                        'currency_name': currency_name,
                        'currency_symbol': symbol,
                        'country_code': country_code,
                        'country_name': country_name,
                        'expires_at': timezone.now() + timedelta(hours=24),
                        'source': 'exchangerate-api',
                        'is_active': True,
                    }
                )
                rates_count += 1
        
        # Log success
        ExchangeRateLog.objects.create(
            source='exchangerate-api',
            status='success',
            rates_fetched=rates_count,
            raw_response={'base': data.get('base'), 'date': data.get('date')}
        )
        
        logger.info(f"Successfully fetched {rates_count} exchange rates")
        
        return {
            'success': True,
            'rates_fetched': rates_count,
            'timestamp': timezone.now().isoformat()
        }
        
    except requests.exceptions.RequestException as e:
        error_msg = f"API request failed: {str(e)}"
        logger.error(error_msg, exc_info=True)
        
        ExchangeRateLog.objects.create(
            source='exchangerate-api',
            status='failed',
            error_message=error_msg
        )
        
        raise self.retry(exc=e)
        
    except Exception as e:
        error_msg = f"Failed to fetch exchange rates: {str(e)}"
        logger.error(error_msg, exc_info=True)
        
        ExchangeRateLog.objects.create(
            source='exchangerate-api',
            status='failed',
            error_message=error_msg
        )
        
        raise self.retry(exc=e)


@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def send_payment_confirmation_email(self, transaction_id: str):
    """
    Send payment confirmation email (async)

    Args:
        transaction_id: UUID of the payment transaction

    Retries: 3 times with 5-minute delay
    """
    try:
        from apps.payments.models import PaymentTransaction

        # Get transaction
        transaction = PaymentTransaction.objects.get(id=transaction_id)

        # Prepare email
        subject = "Payment Confirmation - Hosi Academy"
        message = f"""
Dear {transaction.user.first_name or transaction.user.username},

Your payment of {transaction.amount} {transaction.currency} has been confirmed.

Transaction Details:
- Amount: {transaction.amount} {transaction.currency}
- Reference: {transaction.provider_reference}
- Date: {transaction.completed_at or timezone.now()}
- Description: {transaction.description or 'Course Payment'}

Thank you for your purchase!

If you have any questions, please contact our support team.

Best regards,
Hosi Academy Team
"""


        # Auto-generate chat messages
        try:
            from apps.enrollments.models import Enrollment
            enrollment = Enrollment.objects.filter(payment_transaction=transaction).first()
            if enrollment:
                from apps.communication.services import ChatEnforcerService
                ChatEnforcerService.enforce_enrollment_chats(enrollment)
        except Exception as e:
            logger.error(f"Failed to generate chat messages: {e}")
            
        # Send email

        send_mail(
            subject,
            message,
            settings.DEFAULT_FROM_EMAIL,
            [transaction.user.email],
            fail_silently=False,
        )

        logger.info(
            f"Payment confirmation email sent to {transaction.user.email}",
            extra={
                'transaction_id': str(transaction_id),
                'user_email': transaction.user.email,
                'amount': float(transaction.amount),
            }
        )

        # Track email success in Sentry
        sentry_monitor.track_email_sent(
            transaction_id=str(transaction_id),
            email=transaction.user.email,
            success=True
        )

        return {'success': True, 'email': transaction.user.email}

    except PaymentTransaction.DoesNotExist:
        logger.error(f"Transaction {transaction_id} not found")
        return {'success': False, 'error': 'Transaction not found'}

    except Exception as e:
        logger.error(
            f"Failed to send payment email for transaction {transaction_id}: {str(e)}",
            exc_info=True
        )

        # Track email failure in Sentry
        try:
            from apps.payments.models import PaymentTransaction
            transaction = PaymentTransaction.objects.get(id=transaction_id)
            sentry_monitor.track_email_sent(
                transaction_id=str(transaction_id),
                email=transaction.user.email,
                success=False,
                error=str(e)
            )
        except Exception:
            pass  # Don't fail if tracking fails

        # Retry on failure
        try:
            raise self.retry(exc=e)
        except self.MaxRetriesExceededError:
            logger.error(f"Max retries exceeded for email {transaction_id}")
            return {'success': False, 'error': str(e)}


@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def send_payment_confirmation_sms(self, transaction_id: str):
    """
    Send payment confirmation SMS (async)

    Args:
        transaction_id: UUID of the payment transaction

    Retries: 3 times with 5-minute delay
    """
    try:
        from apps.payments.models import PaymentTransaction
        from apps.payments.services.sms_service import sms_service, sms_template

        # Get transaction
        transaction = PaymentTransaction.objects.get(id=transaction_id)

        # Check if user has phone number
        phone_number = getattr(transaction.user, 'phone_number', None)
        if not phone_number:
            logger.warning(
                f"No phone number for user {transaction.user.id} - skipping SMS"
            )
            return {'success': False, 'error': 'No phone number'}

        # Generate SMS message
        message = sms_template.payment_success(
            amount=float(transaction.amount),
            currency=transaction.currency,
            reference=transaction.provider_reference or str(transaction.id)[:8],
            description=transaction.description
        )

        # Send SMS
        result = sms_service.send_sms(
            to_number=phone_number,
            message=message
        )

        if result['success']:
            logger.info(
                f"Payment SMS sent to {phone_number}",
                extra={
                    'transaction_id': str(transaction_id),
                    'phone_number': phone_number,
                    'message_sid': result['message_sid'],
                }
            )
        else:
            logger.warning(
                f"Failed to send SMS: {result['error']}",
                extra={'transaction_id': str(transaction_id)}
            )

        # Track SMS delivery in Sentry
        sentry_monitor.track_sms_sent(
            transaction_id=str(transaction_id),
            phone_number=phone_number,
            success=result['success'],
            error=result.get('error')
        )

        return result

    except PaymentTransaction.DoesNotExist:
        logger.error(f"Transaction {transaction_id} not found")
        return {'success': False, 'error': 'Transaction not found'}

    except Exception as e:
        logger.error(
            f"Failed to send payment SMS for transaction {transaction_id}: {str(e)}",
            exc_info=True
        )

        # Retry on failure
        try:
            raise self.retry(exc=e)
        except self.MaxRetriesExceededError:
            logger.error(f"Max retries exceeded for SMS {transaction_id}")
            return {'success': False, 'error': str(e)}


@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def send_payment_failed_sms(self, transaction_id: str, reason: str = None):
    """
    Send payment failure SMS notification

    Args:
        transaction_id: UUID of the payment transaction
        reason: Failure reason
    """
    try:
        from apps.payments.models import PaymentTransaction
        from apps.payments.services.sms_service import sms_service, sms_template

        transaction = PaymentTransaction.objects.get(id=transaction_id)
        phone_number = getattr(transaction.user, 'phone_number', None)

        if not phone_number:
            return {'success': False, 'error': 'No phone number'}

        message = sms_template.payment_failed(
            amount=float(transaction.amount),
            currency=transaction.currency,
            reason=reason
        )

        result = sms_service.send_sms(to_number=phone_number, message=message)

        logger.info(f"Payment failure SMS sent to {phone_number}")
        return result

    except Exception as e:
        logger.error(f"Failed to send failure SMS: {str(e)}")
        try:
            raise self.retry(exc=e)
        except self.MaxRetriesExceededError:
            return {'success': False, 'error': str(e)}


@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def send_refund_confirmation_sms(self, transaction_id: str):
    """
    Send refund confirmation SMS

    Args:
        transaction_id: UUID of the refund transaction
    """
    try:
        from apps.payments.models import PaymentRefund
        from apps.payments.services.sms_service import sms_service, sms_template

        refund = PaymentRefund.objects.get(id=transaction_id)
        phone_number = getattr(refund.original_transaction.user, 'phone_number', None)

        if not phone_number:
            return {'success': False, 'error': 'No phone number'}

        message = sms_template.refund_success(
            amount=float(refund.refund_amount),
            currency=refund.original_transaction.currency,
            reference=refund.provider_refund_id or str(refund.id)[:8]
        )

        result = sms_service.send_sms(to_number=phone_number, message=message)

        logger.info(f"Refund SMS sent to {phone_number}")
        return result

    except Exception as e:
        logger.error(f"Failed to send refund SMS: {str(e)}")
        try:
            raise self.retry(exc=e)
        except self.MaxRetriesExceededError:
            return {'success': False, 'error': str(e)}


@shared_task
def send_payment_notifications(transaction_id: str, include_sms: bool = True):
    """
    Send both email and SMS notifications for payment (parallel execution)

    Args:
        transaction_id: UUID of the payment transaction
        include_sms: Whether to send SMS (default: True)
    """
    # Trigger both tasks in parallel
    send_payment_confirmation_email.delay(transaction_id)

    if include_sms:
        send_payment_confirmation_sms.delay(transaction_id)

    logger.info(
        f"Payment notifications queued for transaction {transaction_id}",
        extra={'include_sms': include_sms}
    )


# ============================================================================
# EFT PAYMENT NOTIFICATION TASKS
# ============================================================================

@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def send_eft_initiated_email(self, transaction_id: str):
    """
    Send email notification when EFT payment is initiated.
    Includes bank details and payment instructions.

    Args:
        transaction_id: UUID of the payment transaction
    """
    try:
        from apps.payments.models import PaymentTransaction
        from django.core.mail import EmailMultiAlternatives
        from django.template.loader import render_to_string
        from django.utils.html import strip_tags

        # Get transaction
        transaction = PaymentTransaction.objects.get(id=transaction_id)

        # Get user details
        user_email = transaction.individual_email or (transaction.user.email if transaction.user else None)
        user_name = transaction.individual_name or (transaction.user.get_full_name() if transaction.user else 'Valued Customer')

        if not user_email:
            logger.warning(f"No email for transaction {transaction_id} - skipping EFT initiated email")
            return {'success': False, 'error': 'No email address'}

        # Get bank details from settings
        bank_details = {
            'bank_name': getattr(settings, 'COMPANY_BANK_NAME', 'FNB Business'),
            'account_number': getattr(settings, 'COMPANY_ACCOUNT_NUMBER', '123456789'),
            'account_name': getattr(settings, 'COMPANY_ACCOUNT_NAME', 'HosiTech LMS (Pty) Ltd'),
            'branch_code': getattr(settings, 'COMPANY_BRANCH_CODE', '250655'),
            'account_type': getattr(settings, 'COMPANY_ACCOUNT_TYPE', 'Current Account'),
            'reference': transaction.provider_reference,
        }

        # Prepare email context
        context = {
            'user_name': user_name,
            'reference': transaction.provider_reference,
            'amount': float(transaction.amount),
            'currency': transaction.currency,
            'bank_details': bank_details,
            'program_type': transaction.metadata.get('program_type', 'Program'),
            'program_title': transaction.metadata.get('program_title', 'Selected Program'),
            'expires_at': timezone.now() + timedelta(hours=72),
            'support_email': settings.DEFAULT_FROM_EMAIL,
            'support_phone': getattr(settings, 'SUPPORT_PHONE', '+27 11 234 5678'),
        }

        # Render email template
        html_content = render_to_string(
            'notifications/emails/eft_initiated.html',
            context
        )
        text_content = strip_tags(html_content)

        # Create email
        subject = f"EFT Payment Instructions - Reference: {transaction.provider_reference}"
        email = EmailMultiAlternatives(
            subject=subject,
            body=text_content,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[user_email],
        )
        email.attach_alternative(html_content, "text/html")
        email.send(fail_silently=False)

        logger.info(
            f"EFT initiated email sent to {user_email}",
            extra={
                'transaction_id': str(transaction_id),
                'reference': transaction.provider_reference,
            }
        )

        return {'success': True, 'email': user_email}

    except PaymentTransaction.DoesNotExist:
        logger.error(f"Transaction {transaction_id} not found")
        return {'success': False, 'error': 'Transaction not found'}

    except Exception as e:
        logger.error(f"Failed to send EFT initiated email: {str(e)}", exc_info=True)
        try:
            raise self.retry(exc=e)
        except self.MaxRetriesExceededError:
            logger.error(f"Max retries exceeded for EFT email {transaction_id}")
            return {'success': False, 'error': str(e)}


@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def send_eft_initiated_sms(self, transaction_id: str):
    """
    Send SMS notification when EFT payment is initiated.

    Args:
        transaction_id: UUID of the payment transaction
    """
    try:
        from apps.payments.models import PaymentTransaction
        from apps.payments.services.sms_service import sms_service

        # Get transaction
        transaction = PaymentTransaction.objects.get(id=transaction_id)

        # Get phone number
        phone_number = transaction.individual_phone or (getattr(transaction.user, 'phone_number', None) if transaction.user else None)

        if not phone_number:
            logger.warning(f"No phone number for transaction {transaction_id} - skipping SMS")
            return {'success': False, 'error': 'No phone number'}

        # Prepare SMS message
        message = (
            f"Hosi Academy: EFT Payment initiated. "
            f"Ref: {transaction.provider_reference}. "
            f"Amount: {transaction.currency} {float(transaction.amount):.2f}. "
            f"Bank details sent to your email. "
            f"Payment due within 72 hours. "
            f"Questions? Call +27 11 234 5678"
        )

        # Send SMS
        result = sms_service.send_sms(to_number=phone_number, message=message)

        if result['success']:
            logger.info(
                f"EFT initiated SMS sent to {phone_number}",
                extra={
                    'transaction_id': str(transaction_id),
                    'reference': transaction.provider_reference,
                }
            )
        else:
            logger.warning(f"Failed to send EFT SMS: {result['error']}")

        return result

    except PaymentTransaction.DoesNotExist:
        logger.error(f"Transaction {transaction_id} not found")
        return {'success': False, 'error': 'Transaction not found'}

    except Exception as e:
        logger.error(f"Failed to send EFT initiated SMS: {str(e)}", exc_info=True)
        try:
            raise self.retry(exc=e)
        except self.MaxRetriesExceededError:
            logger.error(f"Max retries exceeded for EFT SMS {transaction_id}")
            return {'success': False, 'error': str(e)}


@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def send_eft_verified_email(self, transaction_id: str):
    """
    Send email notification when EFT payment is verified.

    Args:
        transaction_id: UUID of the payment transaction
    """
    try:
        from apps.payments.models import PaymentTransaction
        from django.core.mail import EmailMultiAlternatives
        from django.template.loader import render_to_string
        from django.utils.html import strip_tags

        transaction = PaymentTransaction.objects.get(id=transaction_id)

        user_email = transaction.individual_email or (transaction.user.email if transaction.user else None)
        user_name = transaction.individual_name or (transaction.user.get_full_name() if transaction.user else 'Valued Customer')

        if not user_email:
            return {'success': False, 'error': 'No email address'}

        context = {
            'user_name': user_name,
            'reference': transaction.provider_reference,
            'amount': float(transaction.amount),
            'currency': transaction.currency,
            'verified_at': transaction.completed_at,
            'program_type': transaction.metadata.get('program_type', 'Program'),
            'program_title': transaction.metadata.get('program_title', 'Selected Program'),
            'support_email': settings.DEFAULT_FROM_EMAIL,
        }

        html_content = render_to_string(
            'notifications/emails/eft_verified.html',
            context
        )
        text_content = strip_tags(html_content)

        subject = f"✅ Payment Verified - {transaction.provider_reference}"
        email = EmailMultiAlternatives(
            subject=subject,
            body=text_content,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[user_email],
        )
        email.attach_alternative(html_content, "text/html")
        email.send(fail_silently=False)

        logger.info(f"EFT verified email sent to {user_email}", extra={'transaction_id': str(transaction_id)})
        return {'success': True, 'email': user_email}

    except Exception as e:
        logger.error(f"Failed to send EFT verified email: {str(e)}", exc_info=True)
        try:
            raise self.retry(exc=e)
        except self.MaxRetriesExceededError:
            return {'success': False, 'error': str(e)}


@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def send_eft_verified_sms(self, transaction_id: str):
    """
    Send SMS notification when EFT payment is verified.

    Args:
        transaction_id: UUID of the payment transaction
    """
    try:
        from apps.payments.models import PaymentTransaction
        from apps.payments.services.sms_service import sms_service

        transaction = PaymentTransaction.objects.get(id=transaction_id)
        phone_number = transaction.individual_phone or (getattr(transaction.user, 'phone_number', None) if transaction.user else None)

        if not phone_number:
            return {'success': False, 'error': 'No phone number'}

        message = (
            f"Hosi Academy: Payment verified! "
            f"Ref: {transaction.provider_reference}. "
            f"Amount: {transaction.currency} {float(transaction.amount):.2f}. "
            f"Your enrollment is now confirmed. "
            f"Access your course at portal.hosiacademy.africa"
        )

        result = sms_service.send_sms(to_number=phone_number, message=message)

        if result['success']:
            logger.info(f"EFT verified SMS sent to {phone_number}", extra={'transaction_id': str(transaction_id)})

        return result

    except Exception as e:
        logger.error(f"Failed to send EFT verified SMS: {str(e)}", exc_info=True)
        try:
            raise self.retry(exc=e)
        except self.MaxRetriesExceededError:
            return {'success': False, 'error': str(e)}


@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def send_eft_rejected_email(self, transaction_id: str, rejection_reason: str):
    """
    Send email notification when EFT payment is rejected.

    Args:
        transaction_id: UUID of the payment transaction
        rejection_reason: Reason for rejection
    """
    try:
        from apps.payments.models import PaymentTransaction
        from django.core.mail import EmailMultiAlternatives
        from django.template.loader import render_to_string
        from django.utils.html import strip_tags

        transaction = PaymentTransaction.objects.get(id=transaction_id)

        user_email = transaction.individual_email or (transaction.user.email if transaction.user else None)
        user_name = transaction.individual_name or (transaction.user.get_full_name() if transaction.user else 'Valued Customer')

        if not user_email:
            return {'success': False, 'error': 'No email address'}

        context = {
            'user_name': user_name,
            'reference': transaction.provider_reference,
            'amount': float(transaction.amount),
            'currency': transaction.currency,
            'rejection_reason': rejection_reason,
            'support_email': settings.DEFAULT_FROM_EMAIL,
            'support_phone': getattr(settings, 'SUPPORT_PHONE', '+27 11 234 5678'),
        }

        html_content = render_to_string(
            'notifications/emails/eft_rejected.html',
            context
        )
        text_content = strip_tags(html_content)

        subject = f"⚠️ Payment Issue - {transaction.provider_reference}"
        email = EmailMultiAlternatives(
            subject=subject,
            body=text_content,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[user_email],
        )
        email.attach_alternative(html_content, "text/html")
        email.send(fail_silently=False)

        logger.info(f"EFT rejected email sent to {user_email}", extra={'transaction_id': str(transaction_id)})
        return {'success': True, 'email': user_email}

    except Exception as e:
        logger.error(f"Failed to send EFT rejected email: {str(e)}", exc_info=True)
        try:
            raise self.retry(exc=e)
        except self.MaxRetriesExceededError:
            return {'success': False, 'error': str(e)}


@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def send_eft_rejected_sms(self, transaction_id: str, rejection_reason: str):
    """
    Send SMS notification when EFT payment is rejected.

    Args:
        transaction_id: UUID of the payment transaction
        rejection_reason: Reason for rejection
    """
    try:
        from apps.payments.models import PaymentTransaction
        from apps.payments.services.sms_service import sms_service

        transaction = PaymentTransaction.objects.get(id=transaction_id)
        phone_number = transaction.individual_phone or (getattr(transaction.user, 'phone_number', None) if transaction.user else None)

        if not phone_number:
            return {'success': False, 'error': 'No phone number'}

        message = (
            f"Hosi Academy: Payment issue. "
            f"Ref: {transaction.provider_reference}. "
            f"Reason: {rejection_reason[:50]}. "
            f"Please contact support: +27 11 234 5678"
        )

        result = sms_service.send_sms(to_number=phone_number, message=message)

        if result['success']:
            logger.info(f"EFT rejected SMS sent to {phone_number}", extra={'transaction_id': str(transaction_id)})

        return result

    except Exception as e:
        logger.error(f"Failed to send EFT rejected SMS: {str(e)}", exc_info=True)
        try:
            raise self.retry(exc=e)
        except self.MaxRetriesExceededError:
            return {'success': False, 'error': str(e)}


@shared_task
def send_eft_notifications(transaction_id: str, notification_type: str, rejection_reason: str = None):
    """
    Send EFT notifications (email + SMS) based on notification type.

    Args:
        transaction_id: UUID of the payment transaction
        notification_type: One of 'initiated', 'verified', 'rejected'
        rejection_reason: Required if notification_type is 'rejected'
    """
    if notification_type == 'initiated':
        send_eft_initiated_email.delay(transaction_id)
        send_eft_initiated_sms.delay(transaction_id)
    elif notification_type == 'verified':
        send_eft_verified_email.delay(transaction_id)
        send_eft_verified_sms.delay(transaction_id)
    elif notification_type == 'rejected':
        if not rejection_reason:
            logger.error(f"Rejection reason required for rejected notification {transaction_id}")
            return
        send_eft_rejected_email.delay(transaction_id, rejection_reason)
        send_eft_rejected_sms.delay(transaction_id, rejection_reason)
    else:
        logger.error(f"Unknown notification type: {notification_type}")

    logger.info(
        f"EFT notifications queued for transaction {transaction_id}",
        extra={'notification_type': notification_type}
    )

