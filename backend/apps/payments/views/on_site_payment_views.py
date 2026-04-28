# backend/apps/payments/views/on_site_payment_views.py
"""
On-Site / In-Person Payment Views

Handles cash payments and on-site payment settlements at physical offices.
Uses Provisional Enrollment + Reference Code system to bridge online registration
with offline payment settlement.

BUSINESS RULES:
1. Reference code auto-generated when user selects on-site payment
2. Reference code linked to: Training + Amount + Selected Office
3. Logged in Payment Admin AND Sales Admin dashboards immediately
4. Office selection defaults to user's country (from IP address)
5. Payment deadline: EARLIER of:
   - 14 days from commitment date, OR
   - 3 days before training starts
6. If training is < 17 days away, deadline = training_date - 3 days
7. On-site payment commitment triggers Provisional Enrollment immediately

Flow:
1. User selects "On-Site Payment" / "Cash" at checkout
2. System detects user country from IP (or user selection)
3. System auto-generates reference code linked to training + amount
4. Provisional enrollment created immediately (status: cash_pending)
5. Logged in Payment Admin + Sales Admin dashboards
6. User receives reference code + assigned office + payment deadline
7. User visits physical office with reference code
8. Admin/agent looks up enrollment using reference code
9. User pays via Cash, POS/Swipe, or guided transfer
10. Admin marks payment as settled in system
11. Backend finalizes enrollment from "Provisional" to "Enrolled"
"""

import logging
from datetime import timedelta
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Q
from django.utils import timezone
from django.db import transaction as db_transaction
from decimal import Decimal

from apps.enrollments.models import ProvisionalEnrollment
from apps.payments.models import PaymentTransaction, PaymentStatus, PaymentProvider
from apps.learnerships.models import LearnershipEnrollment, EnrollmentStatus as LearnershipEnrollmentStatus
from apps.masterclasses.models import Masterclass
from apps.industry_based_training.models import AiCertsCourse
from apps.courses.models import Course

logger = logging.getLogger(__name__)


@api_view(['POST'])
@permission_classes([AllowAny])  # Allow without auth - user may not have account yet
def create_on_site_enrollment(request):
    """
    Create provisional enrollment for on-site/cash payment.
    
    BUSINESS RULES (from ProvisionalEnrollment.save()):
    1. Reference code auto-generated when status='cash_pending'
    2. Expiry calculated as: MIN(14 days from now, training_date - 3 days)
    3. If training is < 17 days away, deadline = training_date - 3 days
    4. Office defaults to user's country (from IP or selection)
    5. Logged in Payment Admin AND Sales Admin dashboards immediately
    6. Provisional enrollment created IMMEDIATELY on commitment
    
    This is called when user selects "Pay at Office" / "Cash Payment" option.
    Delegates to existing apps/enrollments/views.py create_provisional_enrollment()
    which implements all business rules correctly.
    """
    try:
        data = request.data
        
        enrollment_type = data.get('enrollment_type')
        program_id = data.get('program_id')
        amount = Decimal(str(data.get('amount', 0)))
        currency = data.get('currency', 'ZAR')
        user_data = data.get('user_data', {})
        metadata = data.get('metadata', {})
        selected_office_country = data.get('selected_office_country')  # User can override default
        
        # Validate required fields
        if not enrollment_type or not program_id:
            return Response({
                'error': 'Enrollment type and program ID are required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if amount <= 0:
            return Response({
                'error': 'Invalid amount'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get or create user
        from apps.users.models import User
        
        email = user_data.get('email')
        if not email:
            return Response({
                'error': 'User email is required'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Get or create user
        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'username': email,
                'first_name': user_data.get('first_name', ''),
                'last_name': user_data.get('last_name', ''),
                'phone': user_data.get('phone', ''),
            }
        )
        
        # Update user details if provided
        if user_data.get('first_name'):
            user.first_name = user_data.get('first_name')
        if user_data.get('last_name'):
            user.last_name = user_data.get('last_name')
        if user_data.get('phone'):
            user.phone = user_data.get('phone')
        
        # Set country from IP detection or user selection
        # Priority: 1) User selection, 2) IP detection, 3) Default to existing user country
        # user.country is a ForeignKey to localization.Country — must assign an object, not a string
        from apps.localization.models import Country as LocalizationCountry

        def _resolve_country(code):
            """Return Country instance for a 2-letter code, or None if not found."""
            if not code:
                return None
            try:
                return LocalizationCountry.objects.get(code=code.upper())
            except LocalizationCountry.DoesNotExist:
                return None

        if selected_office_country:
            country_obj = _resolve_country(selected_office_country)
            if country_obj:
                user.country = country_obj
        elif user_data.get('country'):
            country_obj = _resolve_country(user_data.get('country'))
            if country_obj:
                user.country = country_obj
        elif not user.country:
            country_obj = _resolve_country('ZW')
            if country_obj:
                user.country = country_obj

        # Derive plain code string for metadata / instructions (Country obj or None)
        country_code = user.country.code if user.country else (selected_office_country or 'ZW')
        user.save()
        
        from apps.enrollments.models import ProvisionalEnrollment
        
        # Determine training start date for expiry calculation
        training_start_date = _get_training_start_date(enrollment_type, program_id)
        
        # Create provisional enrollment (save() will apply business rules)
        provisional = ProvisionalEnrollment.objects.create(
            user=user,
            enrollment_type=enrollment_type,
            status='cash_pending',  # This triggers the business rules in save()
            metadata={
                **metadata,
                'program_id': program_id,
                'payment_method': 'on_site',
                'selected_office_country': country_code,
                'office_payment_pending': True,
                'training_start_date': training_start_date.isoformat() if training_start_date else None,
            }
        )
        
        # Create payment transaction to link with the enrollment
        with db_transaction.atomic():
            transaction = PaymentTransaction.objects.create(
                user=user,
                amount=amount,
                currency=currency,
                status='pending',
                provider='cash',
                provider_reference=provisional.reference_code,
                description=f'On-site payment for {enrollment_type}',
                metadata={
                    **metadata,
                    'payment_method': 'on_site',
                    'reference_code': provisional.reference_code,
                    'provisional_enrollment_id': provisional.id,
                    'selected_office_country': country_code,
                }
            )

            # Link transaction to provisional enrollment
            provisional.payment_transaction = transaction
            provisional.save()

        # Get office locations and instructions for the SELECTED country
        office_instructions = get_office_instructions(country_code)

        # Calculate days until deadline
        days_until_deadline = (provisional.expires_at - timezone.now()).days

        return Response({
            'success': True,
            'reference_code': provisional.reference_code,
            'expires_at': provisional.expires_at.isoformat(),
            'amount': float(amount),
            'currency': currency,
            'enrollment_type': enrollment_type,
            'program_id': program_id,
            'selected_office_country': country_code,
            'days_until_deadline': days_until_deadline,
            'business_rules_applied': {
                'status': 'cash_pending',
                'default_expiry_days': 14,
                'minimum_days_before_training': 3,
                'calculated_expiry': provisional.expires_at.isoformat(),
                'reference_code_generated': True,
                'logged_to_admin_dashboards': True,
            },
            'instructions': office_instructions,
            'next_steps': [
                f'Save your reference code: {provisional.reference_code}',
                f'Visit our office in {office_instructions["country_name"]} with this reference code',
                'Pay via Cash, POS/Swipe, or Bank Transfer',
                'Your enrollment will be confirmed immediately after payment',
                f'Payment deadline: {provisional.expires_at.strftime("%Y-%m-%d")} ({days_until_deadline} days remaining)',
                f'Deadline is 3 days before training starts',
            ],
            'admin_dashboard_links': {
                'payment_admin': '/admin/payments/on-site/pending/',
                'sales_admin': '/admin/sales/provisional-enrollments/',
            }
        }, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        logger.error(f"Error creating on-site enrollment: {e}")
        import traceback
        traceback.print_exc()
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


def _get_training_start_date(enrollment_type, program_id):
    """Get training start date for expiry calculation"""
    try:
        if enrollment_type == 'learnership':
            from apps.learnerships.models import LearnershipProgramme
            programme = LearnershipProgramme.objects.get(id=program_id)
            return programme.start_date
        elif enrollment_type == 'masterclass':
            masterclass = Masterclass.objects.get(id=program_id)
            return masterclass.start_date
        elif enrollment_type == 'industry':
            industry_course = AiCertsCourse.objects.get(id=program_id)
            # Industry courses may not have start date
            return getattr(industry_course, 'start_date', None)
    except Exception:
        logger.warning(f"Could not get training start date for {enrollment_type}/{program_id}")
    return None


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_on_site_enrollment(request, reference_code):
    """
    Get on-site enrollment details by reference code
    
    Used by admin/agent to look up enrollment when user arrives at office.
    """
    try:
        provisional = ProvisionalEnrollment.objects.select_related(
            'user', 'payment_transaction'
        ).get(reference_code=reference_code)
        
        # Check if expired
        if provisional.status == 'cash_pending' and provisional.expires_at < timezone.now():
            provisional.status = 'expired'
            provisional.save()
            return Response({
                'error': 'This reference code has expired',
                'expired': True,
                'expires_at': provisional.expires_at.isoformat()
            }, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if already paid
        if provisional.status in ['confirmed', 'rejected']:
            return Response({
                'already_settled': True,
                'status': provisional.status,
                'settled_at': provisional.verified_at.isoformat() if provisional.verified_at else None,
            })
        
        # Get enrollment details
        item = provisional.get_enrolled_item()
        
        return Response({
            'reference_code': provisional.reference_code,
            'status': provisional.status,
            'enrollment_type': provisional.enrollment_type,
            'user': {
                'name': provisional.user.get_full_name() if provisional.user else 'Unknown',
                'email': provisional.user.email if provisional.user else 'N/A',
                'phone': provisional.user.phone if provisional.user else 'N/A',
            },
            'program': {
                'title': item.title if item else 'N/A',
                'id': provisional.metadata.get('program_id'),
            },
            'amount': float(provisional.payment_transaction.amount) if provisional.payment_transaction else 0,
            'currency': provisional.payment_transaction.currency if provisional.payment_transaction else 'ZAR',
            'created_at': provisional.created_at.isoformat(),
            'expires_at': provisional.expires_at.isoformat(),
            'days_remaining': (provisional.expires_at - timezone.now()).days,
            'metadata': provisional.metadata,
        })
        
    except ProvisionalEnrollment.DoesNotExist:
        return Response({
            'error': 'Reference code not found'
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        logger.error(f"Error getting on-site enrollment: {e}")
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def settle_on_site_payment(request, reference_code):
    """
    Settle on-site payment at office
    
    Called by admin/agent when user completes payment at office.
    Supports Cash, POS/Swipe, and Bank Transfer payment methods.
    
    Request:
    {
        "payment_method": "cash|pos|bank_transfer",
        "amount_paid": 1500.00,
        "notes": "Paid via POS - Standard Bank",
        // Optional for POS:
        "pos_reference": "POS123456",
        // Optional for bank transfer:
        "bank_name": "Standard Bank",
        "transaction_date": "2026-03-17"
    }
    """
    try:
        data = request.data
        
        payment_method = data.get('payment_method', 'cash')
        amount_paid = Decimal(str(data.get('amount_paid', 0)))
        notes = data.get('notes', '')
        
        if payment_method not in ['cash', 'pos', 'bank_transfer']:
            return Response({
                'error': 'Invalid payment method. Must be: cash, pos, or bank_transfer'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        with db_transaction.atomic():
            # Get provisional enrollment
            provisional = ProvisionalEnrollment.objects.select_related(
                'payment_transaction'
            ).get(reference_code=reference_code)
            
            # Check if already settled
            if provisional.status in ['confirmed', 'rejected', 'expired']:
                return Response({
                    'error': f'Enrollment already {provisional.status}'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Update payment transaction
            transaction = provisional.payment_transaction
            if transaction:
                transaction.status = 'successful'
                transaction.provider = 'cash'
                transaction.metadata = {
                    **transaction.metadata,
                    'settled_at_office': True,
                    'office_payment_method': payment_method,
                    'settled_by': request.user.email if request.user else 'system',
                    'settled_at': timezone.now().isoformat(),
                    'pos_reference': data.get('pos_reference'),
                    'bank_name': data.get('bank_name'),
                    'notes': notes,
                }
                if amount_paid > 0:
                    transaction.amount_paid = amount_paid
                transaction.save()
            
            # Update provisional enrollment
            provisional.status = 'confirmed'
            provisional.verified_by = request.user
            provisional.verified_at = timezone.now()
            provisional.verification_notes = f'Office payment settled via {payment_method}. {notes}'
            provisional.metadata = {
                **provisional.metadata,
                'payment_settled': True,
                'payment_method': payment_method,
                'settled_at': timezone.now().isoformat(),
            }
            provisional.save()
            
            # Create final enrollment based on type
            if provisional.enrollment_type == 'learnership' and provisional.programme:
                _create_learnership_enrollment(provisional, transaction)
            elif provisional.enrollment_type == 'masterclass':
                _create_masterclass_enrollment(provisional, transaction)
            elif provisional.enrollment_type == 'industry':
                _create_industry_enrollment(provisional, transaction)
            elif provisional.enrollment_type == 'custom_selection':
                _create_custom_selection_enrollment(provisional, transaction)
        
        logger.info(f"On-site payment settled: {reference_code} via {payment_method}")
        
        return Response({
            'success': True,
            'message': f'Payment settled successfully via {payment_method}',
            'reference_code': reference_code,
            'enrollment_status': 'confirmed',
            'payment_method': payment_method,
            'settled_at': timezone.now().isoformat(),
        })
        
    except ProvisionalEnrollment.DoesNotExist:
        return Response({
            'error': 'Reference code not found'
        }, status=status.HTTP_404_NOT_FOUND)
    
    except Exception as e:
        logger.error(f"Error settling on-site payment: {e}")
        import traceback
        traceback.print_exc()
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_pending_on_site_payments(request):
    """
    Get all pending on-site payments for admin dashboard
    """
    try:
        country = request.query_params.get('country')
        
        # Base query
        pending = ProvisionalEnrollment.objects.filter(
            status='cash_pending'
        ).select_related('user', 'payment_transaction').order_by('-created_at')
        
        # Filter by country if provided
        if country:
            pending = pending.filter(user__country=country)
        
        # Check for expired
        now = timezone.now()
        expired_count = pending.filter(expires_at__lt=now).count()
        active_count = pending.filter(expires_at__gte=now).count()
        
        # Serialize
        pending_list = []
        for p in pending[:100]:  # Limit to 100
            item = p.get_enrolled_item()
            pending_list.append({
                'id': p.id,
                'reference_code': p.reference_code,
                'user_name': p.user.get_full_name() if p.user else 'Unknown',
                'user_email': p.user.email if p.user else 'N/A',
                'user_phone': p.user.phone if p.user else 'N/A',
                'program_title': item.title if item else 'N/A',
                'enrollment_type': p.enrollment_type,
                'amount': float(p.payment_transaction.amount) if p.payment_transaction else 0,
                'currency': p.payment_transaction.currency if p.payment_transaction else 'ZAR',
                'created_at': p.created_at.isoformat(),
                'expires_at': p.expires_at.isoformat(),
                'days_remaining': max(0, (p.expires_at - now).days),
                'country': p.user.country.name if p.user and p.user.country else 'Unknown',
            })
        
        return Response({
            'pending': pending_list,
            'summary': {
                'total': len(pending_list),
                'active': active_count,
                'expired': expired_count,
            }
        })
        
    except Exception as e:
        logger.error(f"Error getting pending on-site payments: {e}")
        return Response({
            'error': str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# Helper Functions

def generate_reference_code(enrollment_type):
    """Generate unique reference code"""
    prefix = 'HOSI'
    type_code = {
        'masterclass': 'M',
        'learnership': 'L',
        'industry': 'I',
        'custom_selection': 'C',
    }.get(enrollment_type, 'X')
    
    # Generate random 8-digit code
    import random
    random_code = ''.join(random.choices(string.digits, k=8))
    
    return f"{prefix}-{type_code}-{random_code}"


def get_office_instructions(country_code):
    """Get office locations and payment instructions for country"""
    # This would typically come from a database or config
    # For now, return static instructions
    
    offices = {
        'ZA': {
            'country_name': 'South Africa',
            'locations': [
                {
                    'city': 'Johannesburg',
                    'address': '123 Sandton Street, Sandton, Johannesburg',
                    'phone': '+27 11 123 4567',
                    'hours': 'Mon-Fri: 9AM-5PM, Sat: 9AM-1PM',
                    'landmark': 'Next to Sandton City Mall',
                },
                {
                    'city': 'Cape Town',
                    'address': '456 Long Street, Cape Town City Centre',
                    'phone': '+27 21 123 4567',
                    'hours': 'Mon-Fri: 9AM-5PM',
                    'landmark': 'Near Cape Town Station',
                },
            ],
            'payment_methods': [
                {'method': 'cash', 'name': 'Cash', 'fee': 0},
                {'method': 'pos', 'name': 'POS/Swipe Card', 'fee': 0, 'cards': ['Visa', 'Mastercard', 'Amex']},
                {'method': 'bank_transfer', 'name': 'Instant EFT', 'fee': 0},
            ],
        },
        'KE': {
            'country_name': 'Kenya',
            'locations': [
                {
                    'city': 'Nairobi',
                    'address': 'The Oval House, Ring Road, Westlands, 2nd floor',
                    'phone': '+254 20 123 4567',
                    'hours': 'Mon-Fri: 8AM-5PM, Sat: 9AM-1PM',
                    'landmark': 'Ring Road Westlands',
                },
            ],
            'payment_methods': [
                {'method': 'cash', 'name': 'Cash (KES)', 'fee': 0},
                {'method': 'pos', 'name': 'POS/Swipe Card', 'fee': 0},
                {'method': 'mpesa', 'name': 'M-Pesa at Office', 'fee': 0},
            ],
        },
        'ZW': {
            'country_name': 'Zimbabwe',
            'locations': [
                {
                    'city': 'Harare',
                    'address': '100 Liberation Legacy Way, Harare',
                    'phone': '+263 24 123 4567',
                    'hours': 'Mon-Fri: 8:30AM-4:30PM',
                    'landmark': 'Liberation Legacy Way',
                },
            ],
            'payment_methods': [
                {'method': 'cash', 'name': 'Cash (USD/ZWL)', 'fee': 0},
                {'method': 'pos', 'name': 'POS/Swipe Card', 'fee': 0},
                {'method': 'ecocash', 'name': 'EcoCash at Office', 'fee': 0},
            ],
        },
    }
    
    # Default to South Africa if country not found
    if country_code not in offices:
        country_code = 'ZA'
    
    office_data = offices.get(country_code, offices['ZA'])
    
    return {
        **office_data,
        'support': {
            'phone': '+27 11 123 4567',
            'email': 'payments@hosiacademy.africa',
            'whatsapp': '+27 12 345 6789',
        },
        'what_to_bring': [
            'Reference code (digital or printed)',
            'Valid ID/Passport',
            'Payment method (Cash/Card)',
        ],
        'important_notes': [
            'Payment must be made within 14 days',
            'Reference code expires after 14 days',
            'Enrollment confirmed immediately after payment',
            'You will receive confirmation email/SMS',
        ],
    }


def _create_learnership_enrollment(provisional, transaction):
    """Create learnership enrollment after payment"""
    try:
        from apps.learnerships.models import LearnershipEnrollment, EnrollmentStatus
        
        # Check if already exists
        existing = LearnershipEnrollment.objects.filter(
            payment_transaction=transaction
        ).first()
        
        if existing:
            # Update existing
            existing.status = EnrollmentStatus.ENROLLED
            existing.payment_status = 'paid'
            existing.save()
            return existing
        
        # Create new
        return LearnershipEnrollment.objects.create(
            programme=provisional.programme,
            user=provisional.user,
            payment_transaction=transaction,
            enrollment_type='individual',
            status=EnrollmentStatus.ENROLLED,
            payment_status='paid',
            metadata=provisional.metadata,
        )
    except Exception as e:
        logger.error(f"Error creating learnership enrollment: {e}")
        raise


def _create_masterclass_enrollment(provisional, transaction):
    """Create masterclass enrollment after payment"""
    try:
        from apps.masterclasses.models import MasterclassEnrollment
        
        program_id = provisional.metadata.get('program_id')
        if not program_id:
            raise ValueError("Program ID not found in metadata")
        
        masterclass = Masterclass.objects.get(id=program_id)
        
        return MasterclassEnrollment.objects.create(
            masterclass=masterclass,
            user=provisional.user,
            payment_transaction=transaction,
            status='enrolled',
            payment_status='paid',
            metadata=provisional.metadata,
        )
    except Exception as e:
        logger.error(f"Error creating masterclass enrollment: {e}")
        raise


def _create_industry_enrollment(provisional, transaction):
    """Create industry training enrollment after payment"""
    try:
        program_id = provisional.metadata.get('program_id')
        if not program_id:
            raise ValueError("Program ID not found in metadata")
        
        industry_course = AiCertsCourse.objects.get(id=program_id)
        
        # Create enrollment (model may vary)
        return {
            'program': industry_course,
            'user': provisional.user,
            'status': 'enrolled',
        }
    except Exception as e:
        logger.error(f"Error creating industry enrollment: {e}")
        raise


def _create_custom_selection_enrollment(provisional, transaction):
    """Create custom selection enrollment after payment"""
    try:
        from apps.courses.models import Course
        from apps.enrollments.models import GenericEnrollment, EnrollmentType
        from django.contrib.contenttypes.models import ContentType
        
        program_id = provisional.metadata.get('program_id')
        if not program_id:
            raise ValueError("Program ID not found in metadata")
        
        course = Course.objects.get(id=program_id)
        
        return GenericEnrollment.objects.create(
            enrollment_type=EnrollmentType.CUSTOM_SELECTION,
            content_type=ContentType.objects.get_for_model(course),
            object_id=course.id,
            user=provisional.user,
            status='enrolled',
            payment_transaction=transaction,
            metadata=provisional.metadata,
        )
    except Exception as e:
        logger.error(f"Error creating custom selection enrollment: {e}")
        raise


# Import string module for reference code generation
import string
