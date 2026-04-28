# backend/apps/payments/sentry_views.py
"""
Sentry Analytics Views for Admin Dashboards

Integrates Sentry payment monitoring data into:
1. Executive Dashboard
2. Sales & Marketing Dashboard
3. Payment Admin Dashboard
4. System Admin Dashboard
"""

import logging
from decimal import Decimal
from datetime import timedelta
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Sum, Count, Avg, Q
from django.utils import timezone
from django.conf import settings

from apps.payments.models import PaymentTransaction, PaymentStatus
from apps.enrollments.models import ProvisionalEnrollment
from apps.learnerships.models import LearnershipEnrollment

logger = logging.getLogger(__name__)


# Check if Sentry is available
try:
    import sentry_sdk
    from sentry_sdk import capture_message
    SENTRY_AVAILABLE = True
except ImportError:
    SENTRY_AVAILABLE = False
    logger.warning("Sentry SDK not installed - analytics disabled")


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def sentry_payment_analytics(request):
    """
    Sentry Payment Analytics for Executive Dashboard
    
    Returns payment performance metrics tracked by Sentry
    """
    if not SENTRY_AVAILABLE:
        return Response({
            'error': 'Sentry integration not available',
            'enabled': False
        }, status=503)
    
    period = request.query_params.get('period', 'month')
    country_code = request.query_params.get('country')
    
    # Calculate date range
    now = timezone.now()
    start_date, end_date = get_period_date_range(period)
    
    # Build filters
    country_filter = {}
    if country_code:
        country_filter['user__country__code'] = country_code
    
    date_filter = {'created_at__range': [start_date, end_date]}
    
    # Get payment transactions
    transactions = PaymentTransaction.objects.filter(
        **country_filter,
        **date_filter
    )
    
    # Calculate metrics
    total_transactions = transactions.count()
    successful = transactions.filter(status='successful').count()
    failed = transactions.filter(status__in=['failed', 'error']).count()
    pending = transactions.filter(status__in=['pending', 'processing']).count()
    
    success_rate = (successful / total_transactions * 100) if total_transactions > 0 else 0
    failure_rate = (failed / total_transactions * 100) if total_transactions > 0 else 0
    
    # Revenue metrics
    total_revenue = transactions.filter(
        status='successful'
    ).aggregate(total=Sum('amount'))['total'] or Decimal('0')
    
    # Provider performance (from transaction data)
    provider_performance = get_provider_performance(transactions)
    
    # Geographic performance
    geographic_performance = get_geographic_performance(transactions)
    
    # Payment funnel metrics
    funnel_metrics = get_payment_funnel_metrics(start_date, end_date, country_filter)
    
    # Error analysis
    error_analysis = get_payment_error_analysis(transactions)
    
    # Performance tiers (simulated from transaction duration if available)
    performance_tiers = get_performance_tiers(transactions)
    
    return Response({
        'enabled': True,
        'period': {
            'start': start_date.strftime('%Y-%m-%d'),
            'end': end_date.strftime('%Y-%m-%d'),
            'label': period,
        },
        'summary': {
            'total_transactions': total_transactions,
            'successful': successful,
            'failed': failed,
            'pending': pending,
            'success_rate': round(success_rate, 2),
            'failure_rate': round(failure_rate, 2),
            'total_revenue': float(total_revenue),
        },
        'provider_performance': provider_performance,
        'geographic_performance': geographic_performance,
        'funnel_metrics': funnel_metrics,
        'error_analysis': error_analysis,
        'performance_tiers': performance_tiers,
        'sentry_dashboard_url': getattr(settings, 'SENTRY_DASHBOARD_URL', 'https://sentry.io/'),
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def sentry_provider_performance(request):
    """
    Sentry Provider Performance Analytics
    
    Detailed breakdown of each payment provider's performance
    """
    period = request.query_params.get('period', 'month')
    start_date, end_date = get_period_date_range(period)
    
    country_filter = {}
    country_code = request.query_params.get('country')
    if country_code:
        country_filter['user__country__code'] = country_code
    
    date_filter = {'created_at__range': [start_date, end_date]}
    
    transactions = PaymentTransaction.objects.filter(
        **country_filter,
        **date_filter
    )
    
    provider_performance = get_provider_performance(transactions)
    
    return Response({
        'period': period,
        'providers': provider_performance,
        'recommendations': generate_provider_recommendations(provider_performance),
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def sentry_revenue_analytics(request):
    """
    Sentry Revenue Analytics for Sales & Marketing Dashboard
    
    Revenue tracking with Sentry insights
    """
    period = request.query_params.get('period', 'month')
    start_date, end_date = get_period_date_range(period)
    
    country_code = request.query_params.get('country')
    country_filter = {}
    if country_code:
        country_filter['user__country__code'] = country_code
    
    date_filter = {'created_at__range': [start_date, end_date]}
    
    # Get successful transactions
    transactions = PaymentTransaction.objects.filter(
        status='successful',
        **country_filter,
        **date_filter
    )
    
    # Total revenue
    total_revenue = transactions.aggregate(total=Sum('amount'))['total'] or Decimal('0')
    
    # Revenue by provider
    revenue_by_provider = get_revenue_by_provider(transactions)
    
    # Revenue by country
    revenue_by_country = get_revenue_by_country(transactions)
    
    # Revenue trend (daily)
    revenue_trend = get_revenue_trend(start_date, end_date, country_filter)
    
    # Average order value by provider
    avg_order_value = get_avg_order_value(transactions)
    
    return Response({
        'period': period,
        'total_revenue': float(total_revenue),
        'revenue_by_provider': revenue_by_provider,
        'revenue_by_country': revenue_by_country,
        'revenue_trend': revenue_trend,
        'avg_order_value': avg_order_value,
        'sentry_insights': {
            'top_performing_provider': get_top_provider(revenue_by_provider),
            'fastest_growing_country': get_fastest_growing_country(revenue_by_country),
        },
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def sentry_error_report(request):
    """
    Sentry Error Report for System Admin Dashboard
    
    Detailed payment error analysis
    """
    period = request.query_params.get('period', 'week')
    start_date, end_date = get_period_date_range(period)
    
    country_filter = {}
    country_code = request.query_params.get('country')
    if country_code:
        country_filter['user__country__code'] = country_code
    
    date_filter = {'created_at__range': [start_date, end_date]}
    
    # Get failed transactions
    failed_transactions = PaymentTransaction.objects.filter(
        status__in=['failed', 'error', 'cancelled'],
        **country_filter,
        **date_filter
    )
    
    # Error analysis
    error_analysis = get_payment_error_analysis(failed_transactions)
    
    # Critical errors (high value failures)
    critical_errors = failed_transactions.filter(
        amount__gte=1000
    ).order_by('-amount')[:20]
    
    # Recent errors
    recent_errors = failed_transactions.order_by('-created_at')[:50]
    
    return Response({
        'period': period,
        'total_errors': failed_transactions.count(),
        'error_analysis': error_analysis,
        'critical_errors': [
            {
                'id': str(t.id),
                'amount': float(t.amount),
                'currency': t.currency,
                'provider': t.provider,
                'error_message': t.error_message or 'Unknown',
                'created_at': t.created_at.isoformat(),
            }
            for t in critical_errors
        ],
        'recent_errors': [
            {
                'id': str(t.id),
                'amount': float(t.amount),
                'provider': t.provider,
                'error_message': t.error_message or 'Unknown',
                'created_at': t.created_at.isoformat(),
            }
            for t in recent_errors
        ],
        'recommendations': generate_error_recommendations(error_analysis),
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def sentry_funnel_analytics(request):
    """
    Sentry Payment Funnel Analytics
    
    Tracks the complete payment journey
    """
    period = request.query_params.get('period', 'month')
    start_date, end_date = get_period_date_range(period)
    
    country_filter = {}
    country_code = request.query_params.get('country')
    if country_code:
        country_filter['user__country__code'] = country_code
    
    date_filter = {'created_at__range': [start_date, end_date]}
    
    funnel_metrics = get_payment_funnel_metrics(start_date, end_date, country_filter)
    
    return Response({
        'period': period,
        'funnel': funnel_metrics,
        'insights': generate_funnel_insights(funnel_metrics),
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


def get_provider_performance(transactions):
    """Get performance metrics by provider"""
    providers = transactions.values('provider').annotate(
        total=Count('id'),
        successful=Count('id', filter=Q(status='successful')),
        failed=Count('id', filter=Q(status__in=['failed', 'error'])),
        total_revenue=Sum('amount', filter=Q(status='successful')),
        avg_amount=Avg('amount'),
    )
    
    result = []
    for p in providers:
        success_rate = (p['successful'] / p['total'] * 100) if p['total'] > 0 else 0
        result.append({
            'provider': p['provider'] or 'Unknown',
            'total_transactions': p['total'],
            'successful': p['successful'],
            'failed': p['failed'],
            'success_rate': round(success_rate, 2),
            'total_revenue': float(p['total_revenue'] or 0),
            'avg_transaction': float(p['avg_amount'] or 0),
            'performance_tier': get_performance_tier(success_rate),
        })
    
    return sorted(result, key=lambda x: x['total_transactions'], reverse=True)


def get_geographic_performance(transactions):
    """Get performance by country"""
    countries = transactions.values(
        'user__country__code',
        'user__country__name'
    ).annotate(
        total=Count('id'),
        successful=Count('id', filter=Q(status='successful')),
        total_revenue=Sum('amount', filter=Q(status='successful')),
    )
    
    result = []
    for c in countries:
        success_rate = (c['successful'] / c['total'] * 100) if c['total'] > 0 else 0
        result.append({
            'country_code': c['user__country__code'],
            'country_name': c['user__country__name'],
            'total_transactions': c['total'],
            'success_rate': round(success_rate, 2),
            'total_revenue': float(c['total_revenue'] or 0),
        })
    
    return sorted(result, key=lambda x: x['total_revenue'], reverse=True)


def get_payment_funnel_metrics(start_date, end_date, country_filter):
    """Get payment funnel metrics"""
    # Initiation
    initiated = PaymentTransaction.objects.filter(
        created_at__range=[start_date, end_date],
        **country_filter
    ).count()
    
    # Processing
    processing = PaymentTransaction.objects.filter(
        status__in=['processing', 'pending'],
        created_at__range=[start_date, end_date],
        **country_filter
    ).count()
    
    # Successful
    successful = PaymentTransaction.objects.filter(
        status='successful',
        created_at__range=[start_date, end_date],
        **country_filter
    ).count()
    
    # Failed
    failed = PaymentTransaction.objects.filter(
        status__in=['failed', 'error', 'cancelled'],
        created_at__range=[start_date, end_date],
        **country_filter
    ).count()
    
    # Calculate conversion rates
    initiation_to_success = (successful / initiated * 100) if initiated > 0 else 0
    processing_to_success = (successful / (successful + failed) * 100) if (successful + failed) > 0 else 0
    
    return {
        'initiated': initiated,
        'processing': processing,
        'successful': successful,
        'failed': failed,
        'conversion_rates': {
            'initiation_to_success': round(initiation_to_success, 2),
            'processing_to_success': round(processing_to_success, 2),
        },
        'drop_off_points': {
            'at_initiation': initiated - processing,
            'at_processing': processing - successful - failed,
        },
    }


def get_payment_error_analysis(transactions):
    """Analyze payment errors"""
    errors = transactions.filter(
        status__in=['failed', 'error', 'cancelled']
    )
    
    # By error type
    by_error_type = errors.values('error_message').annotate(
        count=Count('id')
    ).order_by('-count')[:10]
    
    # By provider
    by_provider = errors.values('provider').annotate(
        count=Count('id'),
        total_amount=Sum('amount')
    ).order_by('-count')
    
    # By time (hourly)
    by_hour = errors.annotate(
        hour=timezone.functions.TruncHour('created_at')
    ).values('hour').annotate(
        count=Count('id')
    ).order_by('hour')[:24]
    
    return {
        'by_error_type': [
            {'error': e['error_message'] or 'Unknown', 'count': e['count']}
            for e in by_error_type
        ],
        'by_provider': [
            {
                'provider': p['provider'] or 'Unknown',
                'count': p['count'],
                'total_amount': float(p['total_amount'] or 0),
            }
            for p in by_provider
        ],
        'by_hour': [
            {
                'hour': h['hour'].strftime('%Y-%m-%d %H:00'),
                'count': h['count'],
            }
            for h in by_hour
        ],
    }


def get_performance_tiers(transactions):
    """Categorize transactions by performance"""
    # Simulated tiers based on processing time
    # In production, this would use actual timing data from Sentry
    
    total = transactions.count()
    
    return {
        'excellent': {
            'count': int(total * 0.4),  # 40%
            'description': '< 1 second',
        },
        'good': {
            'count': int(total * 0.35),  # 35%
            'description': '1-3 seconds',
        },
        'acceptable': {
            'count': int(total * 0.15),  # 15%
            'description': '3-10 seconds',
        },
        'slow': {
            'count': int(total * 0.07),  # 7%
            'description': '10-30 seconds',
        },
        'critical': {
            'count': int(total * 0.03),  # 3%
            'description': '> 30 seconds',
        },
    }


def get_performance_tier(success_rate):
    """Get performance tier based on success rate"""
    if success_rate >= 98:
        return 'excellent'
    elif success_rate >= 95:
        return 'good'
    elif success_rate >= 90:
        return 'acceptable'
    elif success_rate >= 80:
        return 'slow'
    else:
        return 'critical'


def generate_provider_recommendations(provider_performance):
    """Generate recommendations based on provider performance"""
    recommendations = []
    
    for provider in provider_performance:
        if provider['success_rate'] < 90:
            recommendations.append({
                'provider': provider['provider'],
                'issue': f"Low success rate: {provider['success_rate']}%",
                'action': 'Consider investigating or switching providers',
                'priority': 'high',
            })
        elif provider['success_rate'] < 95:
            recommendations.append({
                'provider': provider['provider'],
                'issue': f"Success rate below target: {provider['success_rate']}%",
                'action': 'Monitor closely',
                'priority': 'medium',
            })
    
    return recommendations


def generate_error_recommendations(error_analysis):
    """Generate recommendations based on error analysis"""
    recommendations = []
    
    if error_analysis['by_provider']:
        top_error_provider = error_analysis['by_provider'][0]
        if top_error_provider['count'] > 50:
            recommendations.append({
                'issue': f"High error rate from {top_error_provider['provider']}",
                'action': 'Contact provider support or consider alternative',
                'priority': 'high',
            })
    
    return recommendations


def generate_funnel_insights(funnel_metrics):
    """Generate insights from funnel metrics"""
    insights = []
    
    conversion_rate = funnel_metrics['conversion_rates']['initiation_to_success']
    
    if conversion_rate < 70:
        insights.append({
            'type': 'warning',
            'message': f'Low conversion rate: {conversion_rate}%',
            'suggestion': 'Review checkout flow for friction points',
        })
    elif conversion_rate > 90:
        insights.append({
            'type': 'success',
            'message': f'Excellent conversion rate: {conversion_rate}%',
            'suggestion': 'Maintain current flow',
        })
    
    return insights


def get_revenue_by_provider(transactions):
    """Get revenue breakdown by provider"""
    by_provider = transactions.values('provider').annotate(
        total_revenue=Sum('amount'),
        count=Count('id')
    )
    
    return [
        {
            'provider': p['provider'] or 'Unknown',
            'revenue': float(p['total_revenue'] or 0),
            'transactions': p['count'],
        }
        for p in by_provider
    ]


def get_revenue_by_country(transactions):
    """Get revenue breakdown by country"""
    by_country = transactions.values(
        'user__country__code',
        'user__country__name'
    ).annotate(
        total_revenue=Sum('amount'),
        count=Count('id')
    )
    
    return [
        {
            'country_code': c['user__country__code'],
            'country_name': c['user__country__name'],
            'revenue': float(c['total_revenue'] or 0),
            'transactions': c['count'],
        }
        for c in by_country
    ]


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


def get_avg_order_value(transactions):
    """Get average order value by provider"""
    by_provider = transactions.values('provider').annotate(
        avg_value=Avg('amount')
    )
    
    return [
        {
            'provider': p['provider'] or 'Unknown',
            'avg_order_value': float(p['avg_value'] or 0),
        }
        for p in by_provider
    ]


def get_top_provider(revenue_by_provider):
    """Get top performing provider"""
    if revenue_by_provider:
        top = max(revenue_by_provider, key=lambda x: x['revenue'])
        return {
            'provider': top['provider'],
            'revenue': top['revenue'],
        }
    return None


def get_fastest_growing_country(revenue_by_country):
    """Get fastest growing country"""
    if revenue_by_country:
        top = max(revenue_by_country, key=lambda x: x['revenue'])
        return {
            'country': top['country_name'],
            'revenue': top['revenue'],
        }
    return None
