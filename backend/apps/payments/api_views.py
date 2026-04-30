# backend/apps/payments/api_views.py - Payment Admin API Views

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Sum, Count, Q, F, Avg
from django.utils import timezone
from datetime import timedelta, datetime
from django.contrib.auth import get_user_model

from apps.enrollments.models import ProvisionalEnrollment
from apps.learnerships.models import LearnershipEnrollment
from apps.masterclasses.models import MasterclassEnrollment
from apps.industry_based_training.models import IndustryTrainingEnrollment
from apps.payments.models import PaymentTransaction, PaymentMethod
from apps.learner_portal.models import Wishlist  # Fixed: was WishlistItem
from apps.users.models import User
from apps.localization.models import Country

User = get_user_model()


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def payment_admin_operations_data(request):
    """
    Comprehensive data for Payment Admin Dashboard
    Filtered by country based on role assignment
    """
    # Get country filter from query params
    country_code = request.query_params.get('country')
    start_date_str = request.query_params.get('start_date')
    end_date_str = request.query_params.get('end_date')
    
    # Parse dates
    start_date = None
    end_date = None
    if start_date_str and end_date_str:
        try:
            start_date = datetime.strptime(start_date_str, '%Y-%m-%d')
            end_date = datetime.strptime(end_date_str, '%Y-%m-%d')
            end_date = end_date.replace(hour=23, minute=59, second=59)
        except ValueError:
            pass
    
    # Get admin's allowed countries from role assignment
    allowed_countries = get_admin_allowed_countries(request.user)
    
    # If country filter provided, validate it's in allowed countries
    if country_code:
        if allowed_countries and country_code not in [c['code'] for c in allowed_countries]:
            return Response(
                {'error': 'You do not have permission to view this country'},
                status=status.HTTP_403_FORBIDDEN
            )
    elif allowed_countries and len(allowed_countries) == 1:
        # Default to single allowed country
        country_code = allowed_countries[0]['code']
    
    # Build country filter
    country_filter = {}
    if country_code:
        country_filter['user__country__code'] = country_code
    
    # Build date filter
    date_filter = {}
    if start_date and end_date:
        date_filter['created_at__range'] = [start_date, end_date]
    elif start_date:
        date_filter['created_at__gte'] = start_date
    elif end_date:
        date_filter['created_at__lte'] = end_date
    
    # Get provisional enrollments (cash pending)
    cash_pending = ProvisionalEnrollment.objects.filter(
        status='cash_pending',
        **country_filter,
        **date_filter
    ).select_related('user', 'payment_transaction').order_by('-created_at')
    
    # Get provisional enrollments awaiting verification (learnerships)
    provisional_verification = ProvisionalEnrollment.objects.filter(
        status='provisional',
        **country_filter,
        **date_filter
    ).select_related('user', 'programme').order_by('-created_at')
    
    # Get verified enrollments
    verified = ProvisionalEnrollment.objects.filter(
        status='confirmed',
        **country_filter,
        **date_filter
    ).select_related('user', 'verified_by').order_by('-verified_at')
    
    # Get rejected enrollments
    rejected = ProvisionalEnrollment.objects.filter(
        status__in=['rejected', 'refunded'],
        **country_filter,
        **date_filter
    ).select_related('user').order_by('-updated_at')
    
    # Calculate summary statistics
    total_revenue = PaymentTransaction.objects.filter(
        status='successful',
        **country_filter,
        **date_filter
    ).aggregate(total=Sum('amount'))['total'] or 0
    
    pending_cash_count = cash_pending.count()
    pending_cash_amount = cash_pending.aggregate(
        total=Sum('payment_transaction__amount')
    )['total'] or 0
    
    pending_verification_count = provisional_verification.count()
    verified_count = verified.count()
    rejected_count = rejected.count()
    
    # Get gateway transactions (successful digital payments)
    gateway_transactions = PaymentTransaction.objects.filter(
        status__in=['successful', 'completed'],
        **country_filter,
        **date_filter
    ).exclude(provider__in=['cash', 'eft', 'bank_transfer']).select_related('user').order_by('-created_at')

    return Response({
        'cash_payments': [serialize_cash_payment(p) for p in cash_pending[:50]],
        'gateway_transactions': [serialize_transaction(t) for t in gateway_transactions[:100]],
        'provisional_enrollments': [
            serialize_provisional_enrollment(p) for p in provisional_verification[:50]
        ],
        'verified_enrollments': [
            serialize_verified_enrollment(p) for p in verified[:50]
        ],
        'rejected_enrollments': [
            serialize_rejected_enrollment(p) for p in rejected[:50]
        ],
        'summary': {
            'total_revenue': float(total_revenue),
            'pending_cash_count': pending_cash_count,
            'pending_cash_amount': float(pending_cash_amount),
            'gateway_transaction_count': gateway_transactions.count(),
            'pending_verification_count': pending_verification_count,
            'verified_count': verified_count,
            'rejected_count': rejected_count,
            'active_enrollments': verified_count,
        },
        'allowed_countries': allowed_countries,
        'selected_country': country_code,
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def payment_admin_marketing_analytics(request):
    """
    Marketing analytics for Payment Admin Dashboard
    Includes wishlist leads, conversion tracking
    Filtered by country
    """
    country_code = request.query_params.get('country')
    limit = int(request.query_params.get('limit', 50))
    
    # Validate country permission
    allowed_countries = get_admin_allowed_countries(request.user)
    if country_code and allowed_countries:
        if country_code not in [c['code'] for c in allowed_countries]:
            return Response(
                {'error': 'Permission denied for this country'},
                status=status.HTTP_403_FORBIDDEN
            )
    
    # Build country filter
    if country_code:
        q_filter = Q(country__code=country_code) | Q(user__country__code=country_code, country__isnull=True)
    elif allowed_countries:
        codes = [c['code'] for c in allowed_countries]
        q_filter = Q(country__code__in=codes) | Q(user__country__code__in=codes, country__isnull=True)
    else:
        q_filter = Q()

    # Get wishlist items
    wishlist_items = Wishlist.objects.filter(
        q_filter
    ).select_related('user', 'country').order_by('-created_at')[:limit]

    # Calculate marketing stats
    total_leads = wishlist_items.count()
    
    # High priority: added > 7 days ago, not converted
    seven_days_ago = timezone.now() - timedelta(days=7)
    high_priority = wishlist_items.filter(
        created_at__lt=seven_days_ago,
        converted_to_cart=False,
        converted_to_enrollment=False
    )
    high_priority_count = high_priority.count()
    
    # Cart conversions
    cart_conversions = wishlist_items.filter(
        converted_to_cart=True,
        converted_to_enrollment=False
    ).count()
    
    # Enrollment conversions
    enrollment_conversions = wishlist_items.filter(
        converted_to_enrollment=True
    ).count()
    
    # Conversion rates
    cart_conversion_rate = (cart_conversions / total_leads * 100) if total_leads > 0 else 0
    enrollment_conversion_rate = (enrollment_conversions / total_leads * 100) if total_leads > 0 else 0
    
    # Recent conversions (last 7 days)
    recent_conversions = wishlist_items.filter(
        converted_to_enrollment=True,
        updated_at__gte=timezone.now() - timedelta(days=7)
    ).select_related('user', 'course')[:20]
    
    # Breakdown by training type
    by_training_type = wishlist_items.values('training_type').annotate(
        count=Count('id')
    ).order_by('-count')
    
    return Response({
        'stats': {
            'total_leads': total_leads,
            'high_priority_leads': high_priority_count,
            'cart_conversions': cart_conversions,
            'enrollment_conversions': enrollment_conversions,
            'cart_conversion_rate': round(cart_conversion_rate, 2),
            'enrollment_conversion_rate': round(enrollment_conversion_rate, 2),
        },
        'high_priority_leads': [
            serialize_wishlist_lead(w) for w in high_priority[:20]
        ],
        'recent_conversions': [
            serialize_conversion(c) for c in recent_conversions
        ],
        'by_training_type': [
            {'type': item['training_type'], 'count': item['count']}
            for item in by_training_type
        ],
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def payment_admin_sales_analytics(request):
    """
    Sales analytics for Payment Admin Dashboard
    Revenue breakdown by country, course type, payment method
    Filtered by country and date range
    """
    country_code = request.query_params.get('country')
    start_date_str = request.query_params.get('start_date')
    end_date_str = request.query_params.get('end_date')
    
    # Parse dates
    start_date = None
    end_date = None
    if start_date_str and end_date_str:
        try:
            start_date = datetime.strptime(start_date_str, '%Y-%m-%d')
            end_date = datetime.strptime(end_date_str, '%Y-%m-%d')
            end_date = end_date.replace(hour=23, minute=59, second=59)
        except ValueError:
            pass
    
    # Validate country permission
    allowed_countries = get_admin_allowed_countries(request.user)
    if country_code and allowed_countries:
        if country_code not in [c['code'] for c in allowed_countries]:
            return Response(
                {'error': 'Permission denied for this country'},
                status=status.HTTP_403_FORBIDDEN
            )
    
    country_filter = {}
    if country_code:
        country_filter['user__country__code'] = country_code
    
    date_filter = {}
    if start_date and end_date:
        date_filter['created_at__range'] = [start_date, end_date]
    elif start_date:
        date_filter['created_at__gte'] = start_date
    elif end_date:
        date_filter['created_at__lte'] = end_date
    
    # Get successful transactions
    transactions = PaymentTransaction.objects.filter(
        status='successful',
        **country_filter,
        **date_filter
    )
    
    # Total revenue
    total_revenue = transactions.aggregate(total=Sum('amount'))['total'] or 0
    total_transactions = transactions.count()
    
    # Average order value
    avg_order_value = transactions.aggregate(avg=Avg('amount'))['avg'] or 0
    
    # Refund rate
    refunded = PaymentTransaction.objects.filter(
        status='refunded',
        **country_filter,
        **date_filter
    ).count()
    refund_rate = (refunded / total_transactions * 100) if total_transactions > 0 else 0
    
    # Revenue by country
    revenue_by_country = PaymentTransaction.objects.filter(
        status='successful',
        **date_filter
    ).values(
        'user__country__code',
        'user__country__name'
    ).annotate(
        revenue=Sum('amount'),
        count=Count('id')
    ).order_by('-revenue')
    
    # If country filter applied, show breakdown by state/province
    if country_code:
        revenue_by_country = PaymentTransaction.objects.filter(
            status='successful',
            user__country__code=country_code,
            **date_filter
        ).values(
            'user__state__name'
        ).annotate(
            revenue=Sum('amount'),
            count=Count('id')
        ).order_by('-revenue')
    
    # Revenue by course type
    revenue_by_type = []

    # Masterclass revenue
    masterclass_revenue = MasterclassEnrollment.objects.filter(
        payment_transaction__status='successful',
        payment_transaction__in=transactions
    ).aggregate(revenue=Sum('payment_transaction__amount'))['revenue'] or 0

    revenue_by_type.append({
        'type': 'Masterclass',
        'revenue': float(masterclass_revenue),
        'percentage': round((masterclass_revenue / total_revenue * 100) if total_revenue > 0 else 0, 1)
    })
    
    # Learnership revenue
    learnership_revenue = LearnershipEnrollment.objects.filter(
        payment_transaction__status='successful',
        payment_transaction__in=transactions
    ).aggregate(revenue=Sum('payment_transaction__amount'))['revenue'] or 0
    
    revenue_by_type.append({
        'type': 'Learnership',
        'revenue': float(learnership_revenue),
        'percentage': round((learnership_revenue / total_revenue * 100) if total_revenue > 0 else 0, 1)
    })

    # Industry Training revenue
    industry_revenue = IndustryTrainingEnrollment.objects.filter(
        payment_transaction__status='successful',
        payment_transaction__in=transactions
    ).aggregate(revenue=Sum('payment_transaction__amount'))['revenue'] or 0

    revenue_by_type.append({
        'type': 'Industry Training',
        'revenue': float(industry_revenue),
        'percentage': round((industry_revenue / total_revenue * 100) if total_revenue > 0 else 0, 1)
    })
    
    # Payment method breakdown
    payment_method_breakdown = transactions.values(
        'payment_method'
    ).annotate(
        count=Count('id'),
        revenue=Sum('amount')
    ).order_by('-count')
    
    # Revenue trend (last 30 days)
    revenue_trend = []
    if start_date and end_date:
        days = (end_date - start_date).days + 1
        for i in range(min(days, 30)):
            date = start_date + timedelta(days=i)
            day_revenue = transactions.filter(
                created_at__date=date
            ).aggregate(revenue=Sum('amount'))['revenue'] or 0
            revenue_trend.append({
                'date': date.strftime('%Y-%m-%d'),
                'amount': float(day_revenue),
            })
    
    return Response({
        'stats': {
            'total_revenue': float(total_revenue),
            'total_transactions': total_transactions,
            'avg_order_value': float(avg_order_value),
            'refund_rate': round(refund_rate, 2),
        },
        'revenue_by_country': [
            {
                'country_code': item.get('user__country__code') or item.get('user__state__name', 'Unknown'),
                'country_name': item.get('user__country__name') or item.get('user__state__name', 'Unknown'),
                'revenue': float(item['revenue']),
                'count': item['count'],
                'percentage': round((item['revenue'] / total_revenue * 100) if total_revenue > 0 else 0, 1)
            }
            for item in revenue_by_country
        ],
        'revenue_by_course_type': revenue_by_type,
        'payment_method_breakdown': [
            {
                'method': item['payment_method'],
                'count': item['count'],
                'revenue': float(item['revenue']),
            }
            for item in payment_method_breakdown
        ],
        'revenue_chart': revenue_trend,
    })


# Helper Functions

def get_admin_allowed_countries(user):
    """
    Get countries that admin is allowed to operate in based on role assignment
    """
    if not user or not user.is_authenticated:
        return []

    # Superusers have access to all countries
    if user.is_superuser:
        from apps.localization.models import Country
        return [{'code': c.code, 'name': c.name} for c in Country.objects.filter(is_active=True)]

    # Check AdminRole model
    from apps.payments.models import AdminRole
    roles = AdminRole.objects.filter(user=user, is_active=True)
    
    if not roles.exists():
        return []

    # Combine allowed countries from all roles
    allowed_countries_codes = set()
    is_universal = False

    for role in roles:
        # Check if this role is universal (no specific country accesses)
        if not role.country_accesses.filter(is_active=True).exists():
            is_universal = True
            break
        
        # Add specific countries
        countries = role.country_accesses.filter(is_active=True).values_list('country__code', 'country__name')
        for code, name in countries:
            allowed_countries_codes.add((code, name))

    if is_universal:
        from apps.localization.models import Country
        return [{'code': c.code, 'name': c.name} for c in Country.objects.filter(is_active=True)]
    
    return [{'code': code, 'name': name} for code, name in allowed_countries_codes]


def serialize_cash_payment(payment):
    """Serialize cash pending payment"""
    return {
        'id': payment.id,
        'reference_code': payment.reference_code,
        'learner_name': payment.user.get_full_name() if payment.user else 'Unknown',
        'email': payment.user.email if payment.user else 'N/A',
        'phone': payment.user.phone if payment.user else 'N/A',
        'course_title': payment.get_enrolled_item().title if payment.get_enrolled_item() else 'N/A',
        'amount': float(payment.payment_transaction.amount) if payment.payment_transaction else 0,
        'created_at': payment.created_at.isoformat() if payment.created_at else None,
        'expires_at': payment.expires_at.isoformat() if payment.expires_at else None,
        'country': payment.user.country.name if payment.user and payment.user.country else 'Unknown',
        'metadata': payment.metadata,
    }


def serialize_provisional_enrollment(enrollment):
    """Serialize provisional enrollment awaiting verification"""
    return {
        'id': enrollment.id,
        'enrollment_type': enrollment.enrollment_type,
        'learner_name': enrollment.user.get_full_name() if enrollment.user else 'Unknown',
        'email': enrollment.user.email if enrollment.user else 'N/A',
        'course_title': enrollment.get_enrolled_item().title if enrollment.get_enrolled_item() else 'N/A',
        'status': enrollment.status,
        'created_at': enrollment.created_at.isoformat() if enrollment.created_at else None,
        'expires_at': enrollment.expires_at.isoformat() if enrollment.expires_at else None,
        'verification_notes': enrollment.verification_notes,
        'prerequisites_verified': enrollment.prerequisites_verified,
        'country': enrollment.user.country.name if enrollment.user and enrollment.user.country else 'Unknown',
    }


def serialize_verified_enrollment(enrollment):
    """Serialize verified enrollment"""
    return {
        'id': enrollment.id,
        'learner_name': enrollment.user.get_full_name() if enrollment.user else 'Unknown',
        'email': enrollment.user.email if enrollment.user else 'N/A',
        'course_title': enrollment.get_enrolled_item().title if enrollment.get_enrolled_item() else 'N/A',
        'verified_at': enrollment.verified_at.isoformat() if enrollment.verified_at else None,
        'verified_by': enrollment.verified_by.get_full_name() if enrollment.verified_by else 'System',
        'country': enrollment.user.country.name if enrollment.user and enrollment.user.country else 'Unknown',
    }


def serialize_rejected_enrollment(enrollment):
    """Serialize rejected enrollment"""
    return {
        'id': enrollment.id,
        'learner_name': enrollment.user.get_full_name() if enrollment.user else 'Unknown',
        'email': enrollment.user.email if enrollment.user else 'N/A',
        'course_title': enrollment.get_enrolled_item().title if enrollment.get_enrolled_item() else 'N/A',
        'status': enrollment.status,
        'verification_notes': enrollment.verification_notes,
        'rejected_at': enrollment.updated_at.isoformat() if enrollment.updated_at else None,
    }


def serialize_wishlist_lead(wishlist):
    """Serialize wishlist lead"""
    return {
        'id': wishlist.id,
        'learner_name': wishlist.user.get_full_name() if wishlist.user else 'Unknown',
        'email': wishlist.user.email if wishlist.user else 'N/A',
        'course_title': wishlist.title or (wishlist.course.title if wishlist.course and hasattr(wishlist.course, 'title') else 'N/A'),
        'training_type': wishlist.training_type,
        'interest_level': wishlist.interest_level,
        'intended_start': wishlist.intended_start,
        'created_at': wishlist.created_at.isoformat() if wishlist.created_at else None,
        'days_waiting': (timezone.now() - wishlist.created_at).days,
        'converted_to_cart': wishlist.converted_to_cart,
        'converted_to_enrollment': wishlist.converted_to_enrollment,
    }


def serialize_conversion(wishlist):
    """Serialize converted wishlist"""
    return {
        'id': wishlist.id,
        'learner_name': wishlist.user.get_full_name() if wishlist.user else 'Unknown',
        'course_title': wishlist.title or (wishlist.course.title if wishlist.course and hasattr(wishlist.course, 'title') else 'N/A'),
        'training_type': wishlist.training_type,
        'converted_at': wishlist.updated_at.isoformat() if wishlist.updated_at else None,
        'days_in_funnel': (wishlist.updated_at - wishlist.created_at).days if wishlist.created_at else 0,
    }


def serialize_transaction(transaction):
    """Serialize successful gateway transaction"""
    return {
        'id': transaction.id,
        'reference': transaction.provider_reference,
        'learner_name': transaction.user.get_full_name() if transaction.user else 'Guest',
        'email': transaction.user.email if transaction.user else 'N/A',
        'provider': transaction.provider,
        'amount': float(transaction.amount),
        'currency': transaction.currency,
        'amount_usd': float(transaction.metadata.get('amount_usd', transaction.amount)) if transaction.metadata else float(transaction.amount),
        'created_at': transaction.created_at.isoformat() if transaction.created_at else None,
        'status': transaction.status,
    }

