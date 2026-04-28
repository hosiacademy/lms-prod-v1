# backend/apps/payments/executive_views.py - Simplified Executive Dashboard

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Sum, Count, Avg
from django.utils import timezone
from datetime import timedelta, datetime
from decimal import Decimal

from apps.enrollments.models import ProvisionalEnrollment
from apps.payments.models import PaymentTransaction, PaymentStatus, Enrollment
from apps.learnerships.models import LearnershipEnrollment
from apps.users.models import User
from apps.localization.models import Country
try:
    from apps.facilitators.models import Facilitator
except Exception:
    Facilitator = None

try:
    from apps.learner_portal.models import WishlistItem
except Exception:
    WishlistItem = None


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def executive_dashboard_analytics(request):
    """
    Simplified Executive Dashboard Analytics
    Country-based filtering with strategic KPIs
    """
    country_code = request.query_params.get('country')
    period = request.query_params.get('period', 'month')
    
    # Calculate date range
    now = timezone.now()
    start_date, end_date = get_period_date_range(period)
    
    # Get admin's allowed countries
    allowed_countries = get_admin_allowed_countries(request.user)
    
    # Validate country permission
    if country_code and allowed_countries:
        if country_code not in [c['code'] for c in allowed_countries]:
            return Response(
                {'error': 'Permission denied for this country'},
                status=status.HTTP_403_FORBIDDEN
            )
    elif allowed_countries and len(allowed_countries) == 1:
        country_code = allowed_countries[0]['code']
    
    # Build filters
    country_filter = {}
    if country_code:
        country_filter['user__country__code'] = country_code
    
    date_filter = {'created_at__range': [start_date, end_date]}
    
    # Strategic KPIs
    total_revenue = PaymentTransaction.objects.filter(
        status='successful',
        **country_filter,
        **date_filter
    ).aggregate(total=Sum('amount'))['total'] or Decimal('0')
    
    total_enrollments = Enrollment.objects.filter(
        **country_filter,
        **date_filter
    ).count()
    
    active_learners = Enrollment.objects.filter(
        status__in=['enrolled', 'in_progress'],
        **country_filter
    ).values('user').distinct().count()
    
    completed = Enrollment.objects.filter(
        status='completed',
        **country_filter,
        **date_filter
    ).count()
    
    completion_rate = (completed / total_enrollments * 100) if total_enrollments > 0 else 0
    
    total_customers = User.objects.filter(
        role_id=3,
        **country_filter,
        date_joined__lte=end_date
    ).count()
    
    new_customers = User.objects.filter(
        role_id=3,
        **country_filter,
        date_joined__range=[start_date, end_date]
    ).count()
    
    total_instructors = Facilitator.objects.filter(
        is_active=True,
        **country_filter
    ).count() if country_filter else Facilitator.objects.filter(is_active=True).count()
    
    pending_verifications = ProvisionalEnrollment.objects.filter(
        status__in=['cash_pending', 'provisional'],
        **country_filter
    ).count()
    
    # Revenue trend
    revenue_trend = get_revenue_trend(start_date, end_date, country_filter)
    
    # Enrollment by status
    enrollment_by_status = {
        'active': Enrollment.objects.filter(
            status__in=['enrolled', 'in_progress'],
            **country_filter
        ).count(),
        'pending': Enrollment.objects.filter(
            status='pending_payment',
            **country_filter
        ).count(),
        'completed': Enrollment.objects.filter(
            status='completed',
            **country_filter
        ).count(),
    }
    
    # Marketing funnel
    total_leads = WishlistItem.objects.filter(**country_filter).count()
    cart_conversions = WishlistItem.objects.filter(
        converted_to_cart=True,
        **country_filter
    ).count()
    enrollment_conversions = WishlistItem.objects.filter(
        converted_to_enrollment=True,
        **country_filter
    ).count()
    
    cart_conversion_rate = (cart_conversions / total_leads * 100) if total_leads > 0 else 0
    enrollment_conversion_rate = (enrollment_conversions / total_leads * 100) if total_leads > 0 else 0
    
    return Response({
        'strategic_kpis': {
            'revenue': {
                'total': float(total_revenue),
                'growth_rate': 0.0,  # Simplified
            },
            'customers': {
                'total': total_customers,
                'new': new_customers,
                'growth_rate': 0.0,
            },
            'enrollments': {
                'total': total_enrollments,
                'active_learners': active_learners,
                'completion_rate': round(completion_rate, 1),
            },
            'operations': {
                'total_courses': 0,  # Simplified
                'total_instructors': total_instructors,
                'pending_verifications': pending_verifications,
            },
        },
        'revenue_analytics': {
            'trend': revenue_trend,
            'by_course_type': [],
            'by_country': [],
            'by_payment_method': [],
        },
        'enrollment_analytics': {
            'trend': [],
            'by_status': enrollment_by_status,
            'by_course_type': [],
        },
        'top_performers': {
            'courses': [],
            'instructors': [],
        },
        'marketing_funnel': {
            'total_leads': total_leads,
            'cart_conversions': cart_conversions,
            'enrollment_conversions': enrollment_conversions,
            'cart_conversion_rate': round(cart_conversion_rate, 2),
            'enrollment_conversion_rate': round(enrollment_conversion_rate, 2),
        },
        'filters': {
            'country': country_code,
            'period': period,
            'start_date': start_date.strftime('%Y-%m-%d'),
            'end_date': end_date.strftime('%Y-%m-%d'),
            'allowed_countries': allowed_countries,
        },
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def executive_financial_insights(request):
    """Simplified financial insights"""
    period = request.query_params.get('period', 'month')
    start_date, end_date = get_period_date_range(period)
    
    country_code = request.query_params.get('country')
    country_filter = {'user__country__code': country_code} if country_code else {}
    date_filter = {'created_at__range': [start_date, end_date]}
    
    total_revenue = PaymentTransaction.objects.filter(
        status='successful',
        **country_filter,
        **date_filter
    ).aggregate(total=Sum('amount'))['total'] or Decimal('0')
    
    return Response({
        'revenue_streams': [],
        'total_revenue': float(total_revenue),
        'period': {
            'start': start_date.strftime('%Y-%m-%d'),
            'end': end_date.strftime('%Y-%m-%d'),
        },
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def executive_country_comparison(request):
    """Country comparison for multi-country admins"""
    allowed_countries = get_admin_allowed_countries(request.user)
    
    if not allowed_countries or len(allowed_countries) <= 1:
        return Response({
            'error': 'Country comparison requires multiple countries',
            'countries': allowed_countries,
        }, status=status.HTTP_400_BAD_REQUEST)
    
    period = request.query_params.get('period', 'month')
    start_date, end_date = get_period_date_range(period)
    date_filter = {'created_at__range': [start_date, end_date]}
    
    country_comparison = []
    
    for country in allowed_countries:
        country_code = country['code']
        country_filter = {'user__country__code': country_code}
        
        revenue = PaymentTransaction.objects.filter(
            status='successful',
            **country_filter,
            **date_filter
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0')
        
        enrollments = Enrollment.objects.filter(
            **country_filter,
            **date_filter
        ).count()
        
        country_comparison.append({
            'country_code': country_code,
            'country_name': country['name'],
            'revenue': float(revenue),
            'enrollments': enrollments,
        })
    
    country_comparison.sort(key=lambda x: x['revenue'], reverse=True)
    
    return Response({
        'countries': country_comparison,
        'period': period,
    })


# Helper Functions

def get_period_date_range(period):
    """Calculate date range for period"""
    now = timezone.now()
    
    if period == 'day':
        return now - timedelta(days=1), now
    elif period == 'week':
        return now - timedelta(days=7), now
    elif period == 'month':
        return now - timedelta(days=30), now
    elif period == 'quarter':
        return now - timedelta(days=90), now
    else:
        return now - timedelta(days=365), now


def get_admin_allowed_countries(user):
    """Get countries - simplified without RoleAssignment"""
    # Return all active countries for now
    countries = Country.objects.filter(is_active=True)[:20]
    return [{'code': c.code, 'name': c.name} for c in countries]


def get_revenue_trend(start_date, end_date, country_filter):
    """Get daily revenue trend"""
    from django.db.models.functions import TruncDate
    
    trend = PaymentTransaction.objects.filter(
        status='successful',
        created_at__range=[start_date, end_date],
        **country_filter
    ).annotate(date=TruncDate('created_at')).values('date').annotate(
        revenue=Sum('amount'),
        count=Count('id')
    ).order_by('date')
    
    return [
        {
            'date': item['date'].strftime('%Y-%m-%d'),
            'revenue': float(item['revenue'] or 0),
            'transactions': item['count'],
        }
        for item in trend
    ]
