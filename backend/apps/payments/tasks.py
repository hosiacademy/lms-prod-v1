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

        return {'success': True, 'transaction_id': str(transaction_id)}

    except Exception as e:
        logger.error(
            f"Provisioning failed for transaction {transaction_id}: {str(e)}",
            exc_info=True
        )
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
def send_payment_confirmation_email(self, transaction_id: str, target_user_id: int = None):
    """
    Send premium payment confirmation email (async)
    """
    try:
        from apps.payments.models import PaymentTransaction, Enrollment
        from django.core.mail import EmailMultiAlternatives
        from django.template.loader import render_to_string
        from django.utils.html import strip_tags
        from django.contrib.auth import get_user_model

        # Get transaction
        transaction = PaymentTransaction.objects.get(id=transaction_id)
        User = get_user_model()
        
        if target_user_id:
            try:
                user = User.objects.get(id=target_user_id)
            except User.DoesNotExist:
                logger.error(f"Target user {target_user_id} not found")
                return {'success': False, 'error': 'User not found'}
        else:
            user = transaction.user

        if not user or not user.email:
            logger.error(f"No user/email for transaction {transaction_id}")
            return {'success': False, 'error': 'No email found'}

        # Find linked enrollment for details specific to this user
        enrollment = Enrollment.objects.filter(order=transaction.order, user=user).first()
        if not enrollment:
            # Try by transaction link directly
            enrollment = Enrollment.objects.filter(payment_transaction=transaction, user=user).first()
            
        # Fallback to any enrollment if somehow the above fails (e.g. payer not enrolled but is the sponsor)
        if not enrollment and not target_user_id:
             enrollment = Enrollment.objects.filter(order=transaction.order).first()

        # Prepare context
        context = {
            'user_name': user.get_full_name() or user.username,
            'reference': transaction.provider_reference,
            'amount': float(transaction.amount),
            'currency': transaction.currency,
            'date': transaction.completed_at or timezone.now(),
            'payment_method': transaction.provider.title(),
            'company_name': 'Hosi Academy',
            'company_tagline': 'The Future of Learning',
            'logo_url': 'http://154.66.211.3:7000/assets/assets/images/logo.png',
            'website_url': 'https://www.hosiacademy.africa',
            'support_email': getattr(settings, 'SUPPORT_EMAIL', 'academy@hosiafrica.com'),
            'support_phone': getattr(settings, 'SUPPORT_PHONE', '+27 67 231 9200'),
            'is_corporate_learner': user.id != transaction.user.id,
        }

        if enrollment:
            program_object = enrollment.content_object
            program_title = getattr(program_object, 'title', str(program_object))
            
            context['enrollment'] = {
                'program_title': program_title,
                'enrollment_code': enrollment.enrollment_code,
                'learner_name': enrollment.learner_full_name,
            }
            
            from apps.payments.models import EnrollmentType
            
            # ✅ LEARNERSHIP SPECIFIC: Handle breakdown and phases
            template_name = 'notifications/emails/payment_confirmation.html' # Default
            if enrollment.enrollment_type == EnrollmentType.LEARNERSHIP:
                # Use learnership-specific template
                template_name = 'users/emails/cybersecurity_enrollment.html'
                
                # Fetch breakdown from metadata (populated during provisioning)
                context.update({
                    'learnership_title': program_title,
                    'platform_cost': enrollment.metadata.get('platform_cost', 0),
                    'instructor_cost': enrollment.metadata.get('instructor_cost', 0),
                    'total_cert_cost': enrollment.metadata.get('total_cert_cost', 0),
                    'total_cost': enrollment.metadata.get('total_programme_cost', transaction.amount),
                    'currency_symbol': '$' if transaction.currency == 'USD' else 'R',
                    'instructor_name': 'Senior Cybersecurity Lead', # Default
                    'instructor_email': 'academy@hosiafrica.com',
                    'lms_url': 'https://portal.hosiacademy.africa',
                    'currency': transaction.currency,
                })
                
                # Try to fetch actual phases from track if linked
                track_id = enrollment.metadata.get('certification_track_id')
                if track_id:
                    try:
                        from apps.learnerships.models import CertificationTrack
                        track = CertificationTrack.objects.get(id=track_id)
                        
                        phases = {}
                        for item in track.certifications.all():
                            phase_key = item.phase
                            if phase_key not in phases:
                                phases[phase_key] = {
                                    'name': item.get_phase_display(),
                                    'certifications': [],
                                    'phase_total': 0
                                }
                            
                            phases[phase_key]['certifications'].append({
                                'name': item.name,
                                'description': item.description,
                                'cost': float(item.cert_cost)
                            })
                            phases[phase_key]['phase_total'] += float(item.cert_cost)
                        
                        context['phases'] = phases
                    except Exception as e:
                        logger.error(f"Failed to fetch track phases for email: {e}")
            
            if enrollment.enrollment_type in [EnrollmentType.CUSTOM_SELECTION, EnrollmentType.INDUSTRY_TRAINING]:
                try:
                    from apps.aicerts_integration.services import SSOService
                    course = enrollment.content_object
                    # Extract lms_course_id, it might be on course.raw_course
                    if hasattr(course, 'lms_course_id') and course.lms_course_id:
                        lms_id = course.lms_course_id
                    elif hasattr(course, 'raw_course') and course.raw_course and hasattr(course.raw_course, 'lms_course_id'):
                        lms_id = course.raw_course.lms_course_id
                    else:
                        lms_id = None
                        
                    if lms_id:
                        sso_url = SSOService.generate_sso_url(user.email, lms_id)
                        context['aicerts_link'] = sso_url
                        context['aicerts_email'] = user.email
                except Exception as e:
                    logger.error(f"Failed to generate AICerts SSO URL for email context: {e}")

        # Render email
        html_content = render_to_string(
            template_name if 'template_name' in locals() else 'notifications/emails/payment_confirmation.html',
            context
        )
        text_content = strip_tags(html_content)

        # Send email
        subject = f"Payment Confirmed - {transaction.provider_reference}"
        email = EmailMultiAlternatives(
            subject=subject,
            body=text_content,
            from_email=settings.DEFAULT_FROM_EMAIL,
            to=[user.email],
        )
        email.attach_alternative(html_content, "text/html")
        email.send(fail_silently=False)

        # Auto-generate chat messages if enrollment exists
        if enrollment:
            try:
                from apps.communication.services import ChatEnforcerService
                ChatEnforcerService.enforce_enrollment_chats(enrollment)
            except Exception as e:
                logger.error(f"Failed to generate chat messages: {e}")

        logger.info(f"Premium payment confirmation email sent to {user.email}")
        return {'success': True, 'email': user.email}

    except PaymentTransaction.DoesNotExist:
        logger.error(f"Transaction {transaction_id} not found")
        return {'success': False, 'error': 'Transaction not found'}

    except Exception as e:
        logger.error(f"Failed to send payment email: {str(e)}", exc_info=True)
        try:
            raise self.retry(exc=e)
        except self.MaxRetriesExceededError:
            return {'success': False, 'error': str(e)}


@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def send_payment_confirmation_sms(self, transaction_id: str):
    """
    Send payment confirmation SMS notification
    """
        # SMS disabled globally
        return {'success': False, 'error': 'SMS disabled'}

        message = (
            f"Hosi Academy: Payment confirmed! "
            f"Ref: {transaction.provider_reference}. "
            f"Amount: {transaction.currency} {float(transaction.amount):.2f}. "
            f"Your enrollment is now being processed. "
            f"Check your email for access details."
        )

        result = sms_service.send_sms(to_number=phone_number, message=message)
        
        if result['success']:
            logger.info(f"Payment confirmation SMS sent to {phone_number}")
        
        return result

    except PaymentTransaction.DoesNotExist:
        logger.error(f"Transaction {transaction_id} not found")
        return {'success': False, 'error': 'Transaction not found'}

    except Exception as e:
        logger.error(f"Failed to send payment SMS: {str(e)}", exc_info=True)
        try:
            raise self.retry(exc=e)
        except self.MaxRetriesExceededError:
            return {'success': False, 'error': str(e)}


@shared_task(bind=True, max_retries=3, default_retry_delay=300)
def send_payment_failed_sms(self, transaction_id: str, reason: str = None):
    """
    Send payment failure SMS notification

    Args:
        transaction_id: UUID of the payment transaction
        reason: Failure reason
    """
        # SMS disabled globally
        return {'success': False, 'error': 'SMS disabled'}

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
        # SMS disabled globally
        return {'success': False, 'error': 'SMS disabled'}

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
    # SMS disabled globally by user request
    if include_sms and False: # Force disabled
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
            'support_email': getattr(settings, 'SUPPORT_EMAIL', 'academy@hosiafrica.com'),
            'support_phone': getattr(settings, 'SUPPORT_PHONE', '+27 67 231 9200'),
            'company_name': 'Hosi Academy',
            'company_tagline': 'The Future of Learning',
            'logo_url': 'http://154.66.211.3:7000/assets/assets/images/logo.png',
            'website_url': 'https://www.hosiacademy.africa',
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
        # SMS disabled globally
        return {'success': False, 'error': 'SMS disabled'}

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
            'support_email': getattr(settings, 'SUPPORT_EMAIL', 'academy@hosiafrica.com'),
            'company_name': 'Hosi Academy',
            'company_tagline': 'The Future of Learning',
            'logo_url': 'http://154.66.211.3:7000/assets/assets/images/logo.png',
            'website_url': 'https://www.hosiacademy.africa',
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
            'support_email': getattr(settings, 'SUPPORT_EMAIL', 'academy@hosiafrica.com'),
            'support_phone': getattr(settings, 'SUPPORT_PHONE', '+27 67 231 9200'),
            'company_name': 'Hosi Academy',
            'company_tagline': 'The Future of Learning',
            'logo_url': 'http://154.66.211.3:7000/assets/assets/images/logo.png',
            'website_url': 'https://www.hosiacademy.africa',
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



