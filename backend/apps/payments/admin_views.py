# apps/payments/admin_views.py
import json
from decimal import Decimal
from datetime import timedelta
from django.http import JsonResponse
from django.db.models import Q, Sum, Count, Avg
from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated

from apps.payments.decorators import require_payment_admin, require_hr_admin, require_executive_admin
from apps.payments.models import (
    PaymentReference, PaymentTransaction, PaymentStatus,
    Enrollment, EnrollmentStatus, Order
)
from apps.enrollments.models import ProvisionalEnrollment
from apps.organizations.models import Company, CompanyLearner
from apps.learner_portal.models import Wishlist, CourseCart

User = get_user_model()


# ==================== PAYMENT ADMIN ENDPOINTS ====================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@require_payment_admin
def get_admin_payments(request):
    """Get payments for admin review - includes EFT, Cash, and Card payments"""
    status_filter = request.GET.get('status')  # pending, verified, rejected
    filter_type = request.GET.get('filter')  # all, today, week, overdue
    search = request.GET.get('search', '')
    payment_method = request.GET.get('payment_method', 'all')  # all, eft, cash, card

    # Base query - get all payment references
    queryset = PaymentReference.objects.all()

    # Apply status filter
    if status_filter:
        queryset = queryset.filter(status=status_filter)

    # Apply time filter
    now = timezone.now()
    if filter_type == 'today':
        queryset = queryset.filter(created_at__date=now.date())
    elif filter_type == 'week':
        week_ago = now - timedelta(days=7)
        queryset = queryset.filter(created_at__gte=week_ago)
    elif filter_type == 'overdue':
        queryset = queryset.filter(
            status='pending',
            payment_deadline__lt=now
        )

    # Apply search
    if search:
        queryset = queryset.filter(
            Q(reference__icontains=search) |
            Q(learner_name__icontains=search) |
            Q(learner_email__icontains=search) |
            Q(training_title__icontains=search)
        )

    # Group by status
    pending = []
    verified = []
    rejected = []

    for payment in queryset.order_by('-created_at'):
        payment_data = {
            'id': str(payment.id),
            'reference': payment.reference,
            'learner_name': payment.learner_name,
            'learner_email': payment.learner_email,
            'training_title': payment.training_title,
            'training_type': payment.training_type,
            'amount': float(payment.amount),
            'currency': payment.currency,
            'payment_deadline': payment.payment_deadline.isoformat() if payment.payment_deadline else None,
            'submitted_at': payment.generated_at.isoformat(),
            'days_remaining': payment.days_until_deadline,
            'company_name': payment.company_name or '',
            'payment_method': 'cash',  # PaymentReference is for cash/on-site payments
        }

        if payment.status == 'pending':
            pending.append(payment_data)
        elif payment.status == 'verified':
            verified.append(payment_data)
        elif payment.status in ['cancelled', 'rejected']:
            rejected.append(payment_data)

    # Include EFT Payments if requested
    if payment_method in ['all', 'eft']:
        eft_queryset = PaymentTransaction.objects.filter(
            provider='eft'
        ).select_related('user').order_by('-created_at')

        # Apply status filter to EFT
        if status_filter:
            if status_filter == 'pending':
                eft_queryset = eft_queryset.filter(status=PaymentStatus.PENDING)
            elif status_filter == 'verified':
                eft_queryset = eft_queryset.filter(status=PaymentStatus.SUCCESSFUL)
            elif status_filter in ['rejected', 'cancelled']:
                eft_queryset = eft_queryset.filter(status=PaymentStatus.FAILED)

        # Apply time filter to EFT
        if filter_type == 'today':
            eft_queryset = eft_queryset.filter(created_at__date=now.date())
        elif filter_type == 'week':
            week_ago = now - timedelta(days=7)
            eft_queryset = eft_queryset.filter(created_at__gte=week_ago)

        # Apply search to EFT
        if search:
            eft_queryset = eft_queryset.filter(
                Q(provider_reference__icontains=search) |
                Q(individual_email__icontains=search) |
                Q(individual_name__icontains=search) |
                Q(company_name__icontains=search)
            )

        for txn in eft_queryset[:100]:  # Limit to 100 for performance
            # Get enrollment if exists
            enrollment = None
            try:
                enrollment = ProvisionalEnrollment.objects.get(payment_transaction=txn)
            except ProvisionalEnrollment.DoesNotExist:
                pass

            eft_data = {
                'id': f'eft_{txn.id}',
                'reference': txn.provider_reference,
                'learner_name': txn.individual_name or txn.company_name or 'N/A',
                'learner_email': txn.individual_email or txn.company_email or 'N/A',
                'training_title': txn.metadata.get('program_title', 'N/A') if txn.metadata else 'N/A',
                'training_type': txn.metadata.get('program_type', 'N/A') if txn.metadata else 'N/A',
                'amount': float(txn.amount),
                'currency': txn.currency,
                'payment_deadline': enrollment.expires_at.isoformat() if enrollment and enrollment.expires_at else None,
                'submitted_at': txn.created_at.isoformat(),
                'days_remaining': None,
                'company_name': txn.company_name or '',
                'payment_method': 'eft',
                'bank_details_submitted': txn.metadata and 'customer_bank_details' in txn.metadata,
                'proof_of_payment_uploaded': txn.metadata and 'proof_of_payment' in txn.metadata,
            }

            if txn.status == PaymentStatus.PENDING:
                pending.append(eft_data)
            elif txn.status == PaymentStatus.SUCCESSFUL:
                verified.append(eft_data)
            elif txn.status == PaymentStatus.FAILED:
                rejected.append(eft_data)

    # Include Card/Online Payments if requested
    if payment_method in ['all', 'card']:
        card_queryset = PaymentTransaction.objects.filter(
            provider__in=['flutterwave', 'paystack', 'stripe', 'mpesa', 'paynow']
        ).select_related('user').order_by('-created_at')

        # Apply status filter to Card
        if status_filter:
            if status_filter == 'pending':
                card_queryset = card_queryset.filter(status=PaymentStatus.PENDING)
            elif status_filter == 'verified':
                card_queryset = card_queryset.filter(status=PaymentStatus.SUCCESSFUL)
            elif status_filter in ['rejected', 'cancelled']:
                card_queryset = card_queryset.filter(status=PaymentStatus.FAILED)

        # Apply time filter to Card
        if filter_type == 'today':
            card_queryset = card_queryset.filter(created_at__date=now.date())
        elif filter_type == 'week':
            week_ago = now - timedelta(days=7)
            card_queryset = card_queryset.filter(created_at__gte=week_ago)

        for txn in card_queryset[:100]:  # Limit to 100 for performance
            card_data = {
                'id': f'card_{txn.id}',
                'reference': txn.provider_reference,
                'learner_name': txn.individual_name or txn.company_name or 'N/A',
                'learner_email': txn.individual_email or txn.company_email or 'N/A',
                'training_title': txn.metadata.get('program_title', 'N/A') if txn.metadata else 'N/A',
                'training_type': txn.metadata.get('program_type', 'N/A') if txn.metadata else 'N/A',
                'amount': float(txn.amount),
                'currency': txn.currency,
                'payment_deadline': None,
                'submitted_at': txn.created_at.isoformat(),
                'days_remaining': None,
                'company_name': txn.company_name or '',
                'payment_method': txn.provider,  # flutterwave, paystack, mpesa, etc.
            }

            if txn.status == PaymentStatus.PENDING:
                pending.append(card_data)
            elif txn.status == PaymentStatus.SUCCESSFUL:
                verified.append(card_data)
            elif txn.status == PaymentStatus.FAILED:
                rejected.append(card_data)

    return JsonResponse({
        'pending': pending,
        'verified': verified,
        'rejected': rejected,
        'summary': {
            'total_pending': len(pending),
            'total_verified': len(verified),
            'total_rejected': len(rejected),
        }
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@require_payment_admin
def verify_payment(request, payment_id):
    """Verify or reject a payment - supports EFT, Cash, and Card payments"""
    try:
        # Use DRF request.data which handles JSON parsing
        data = request.data
        status = data.get('status')  # 'verified' or 'rejected'
        notes = data.get('notes', '')
        payment_method = data.get('payment_method', 'cash')  # eft, cash, card

        # Handle EFT Payments
        if payment_method == 'eft' or (isinstance(payment_id, str) and payment_id.startswith('eft_')):
            # Extract actual ID if prefixed
            actual_id = payment_id.replace('eft_', '') if isinstance(payment_id, str) and payment_id.startswith('eft_') else payment_id
            
            try:
                # Find transaction by ID or reference
                if actual_id.isdigit():
                    transaction = PaymentTransaction.objects.get(id=int(actual_id), provider='eft')
                else:
                    transaction = PaymentTransaction.objects.get(provider_reference=actual_id, provider='eft')
            except PaymentTransaction.DoesNotExist:
                return JsonResponse({'error': 'EFT transaction not found'}, status=404)

            if status == 'verified':
                transaction.status = PaymentStatus.SUCCESSFUL
                transaction.completed_at = timezone.now()
                transaction.reconciled = True
                transaction.reconciliation_date = timezone.now().date()
                
                metadata = transaction.metadata or {}
                metadata['verified_by'] = {
                    'user_id': request.user.id,
                    'user_email': request.user.email,
                    'verified_at': timezone.now().isoformat(),
                    'notes': notes,
                }
                transaction.metadata = metadata
                transaction.save()

                # Update enrollment
                try:
                    enrollment = ProvisionalEnrollment.objects.get(payment_transaction=transaction)
                    enrollment.status = 'confirmed'
                    enrollment.verified_by = request.user
                    enrollment.verified_at = timezone.now()
                    enrollment.save()
                except ProvisionalEnrollment.DoesNotExist:
                    pass

                return JsonResponse({
                    'success': True,
                    'message': 'EFT payment verified',
                    'reference': transaction.provider_reference,
                })

            elif status == 'rejected':
                transaction.status = PaymentStatus.FAILED
                transaction.completed_at = timezone.now()
                
                metadata = transaction.metadata or {}
                metadata['rejected_by'] = {
                    'user_id': request.user.id,
                    'user_email': request.user.email,
                    'rejected_at': timezone.now().isoformat(),
                    'reason': notes,
                }
                transaction.metadata = metadata
                transaction.save()

                # Update enrollment
                try:
                    enrollment = ProvisionalEnrollment.objects.get(payment_transaction=transaction)
                    enrollment.status = 'rejected'
                    enrollment.verified_by = request.user
                    enrollment.verified_at = timezone.now()
                    enrollment.rejection_reason = notes
                    enrollment.save()
                except ProvisionalEnrollment.DoesNotExist:
                    pass

                return JsonResponse({
                    'success': True,
                    'message': 'EFT payment rejected',
                    'reference': transaction.provider_reference,
                })

        # Handle Cash/On-site Payments (existing logic)
        # Get payment reference
        try:
            payment_ref = PaymentReference.objects.get(id=payment_id)
        except PaymentReference.DoesNotExist:
            return JsonResponse({'error': 'Payment not found'}, status=404)

        # Get associated provisional enrollment
        provisional = ProvisionalEnrollment.objects.filter(
            reference_code=payment_ref.reference,
            status='cash_pending'
        ).first()

        if status == 'verified':
            # Update payment reference
            payment_ref.status = 'verified'
            payment_ref.save()

            # Update provisional enrollment
            if provisional:
                provisional.status = 'confirmed'
                provisional.verified_by = request.user
                provisional.verified_at = timezone.now()
                provisional.verification_notes = notes
                provisional.save()

                # For learnerships, update LearnershipEnrollment as well
                if provisional.enrollment_type == 'learnership':
                    from apps.learnerships.models import LearnershipEnrollment, EnrollmentStatus as LearnershipEnrollmentStatus
                    learnership_enrollment = LearnershipEnrollment.objects.filter(
                        payment_transaction=provisional.payment_transaction
                    ).first()
                    
                    if learnership_enrollment:
                        # Payment verified - update payment status
                        learnership_enrollment.payment_status = 'paid'
                        learnership_enrollment.amount_paid = provisional.payment_transaction.amount if provisional.payment_transaction else 0
                        # Keep status as provisional until prerequisites verified
                        learnership_enrollment.save()

                # Activate the main enrollment if it exists
                enrollment = Enrollment.objects.filter(
                    learner_email=payment_ref.learner_email,
                    status=EnrollmentStatus.PENDING_PAYMENT
                ).first()

                if enrollment:
                    enrollment.status = EnrollmentStatus.ENROLLED
                    enrollment.enrolled_at = timezone.now()
                    enrollment.save()

            return JsonResponse({
                'success': True,
                'message': 'Payment verified successfully',
                'enrollment_status': 'active'
            })

        elif status == 'rejected':
            # Update payment reference
            payment_ref.status = 'cancelled'
            payment_ref.save()

            # Update provisional enrollment
            if provisional:
                provisional.status = 'rejected'
                provisional.verified_by = request.user
                provisional.verified_at = timezone.now()
                provisional.verification_notes = notes
                provisional.save()

                # For learnerships, update LearnershipEnrollment as well
                if provisional.enrollment_type == 'learnership':
                    from apps.learnerships.models import LearnershipEnrollment, EnrollmentStatus as LearnershipEnrollmentStatus
                    learnership_enrollment = LearnershipEnrollment.objects.filter(
                        payment_transaction=provisional.payment_transaction
                    ).first()
                    
                    if learnership_enrollment:
                        learnership_enrollment.status = LearnershipEnrollmentStatus.REJECTED
                        learnership_enrollment.payment_status = 'refunded'
                        learnership_enrollment.verified_by = request.user
                        learnership_enrollment.verified_at = timezone.now()
                        learnership_enrollment.verification_notes = notes
                        learnership_enrollment.save()

                # Cancel the main enrollment
                enrollment = Enrollment.objects.filter(
                    learner_email=payment_ref.learner_email,
                    status=EnrollmentStatus.PENDING_PAYMENT
                ).first()

                if enrollment:
                    enrollment.status = EnrollmentStatus.CANCELLED
                    enrollment.save()

            return JsonResponse({
                'success': True,
                'message': 'Payment rejected',
                'enrollment_status': 'cancelled'
            })

        else:
            return JsonResponse({'error': 'Invalid status'}, status=400)

    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


# ==================== ENROLLMENT & OPERATIONS (PAYMENT ADMIN) ====================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@require_payment_admin
def get_operational_admin_data(request):
    """Get Operational data - enrollments, learners, certificates. Previously misattributed to HR."""
    search = request.GET.get('search', '')

    # Get enrollments
    enrollments_qs = Enrollment.objects.select_related('user').all()

    if search:
        enrollments_qs = enrollments_qs.filter(
            Q(learner_full_name__icontains=search) |
            Q(learner_email__icontains=search) |
            Q(learner_phone__icontains=search)
        )

    enrollments = []
    for e in enrollments_qs[:100]:
        try:
            enrolled_item = e.get_enrolled_item()
            training_title = getattr(enrolled_item, 'title', None) or getattr(enrolled_item, 'name', 'N/A')
        except:
            training_title = 'N/A'

        enrollments.append({
            'id': str(e.id),
            'learner_name': e.learner_full_name,
            'training_title': training_title,
            'status': e.status,
            'enrollment_date': e.created_at.isoformat(),
        })

    # Get learners (unique users with enrollments)
    learners_qs = User.objects.filter(enrollments__isnull=False).annotate(
        total_enrollments=Count('enrollments')
    ).distinct()

    if search:
        learners_qs = learners_qs.filter(
            Q(first_name__icontains=search) |
            Q(last_name__icontains=search) |
            Q(email__icontains=search)
        )

    learners = []
    for u in learners_qs[:100]:
        learners.append({
            'id': str(u.id),
            'full_name': f"{u.first_name} {u.last_name}".strip() or u.username,
            'email': u.email,
            'phone': getattr(u, 'phone', 'N/A') or 'N/A',
            'total_enrollments': u.total_enrollments,
        })

    # Get certificates (placeholder - will be implemented when certificate model is ready)
    certificates = []

    # Try to get certificates if the model exists
    try:
        from apps.certificates.models import Certificate
        certs_qs = Certificate.objects.select_related('user').all()

        if search:
            certs_qs = certs_qs.filter(
                Q(user__first_name__icontains=search) |
                Q(user__last_name__icontains=search) |
                Q(user__email__icontains=search)
            )

        for cert in certs_qs[:100]:
            certificates.append({
                'id': str(cert.id),
                'learner_name': f"{cert.user.first_name} {cert.user.last_name}".strip() or cert.user.username,
                'training_title': getattr(cert, 'course_title', 'N/A'),
                'certificate_number': getattr(cert, 'certificate_number', 'N/A'),
                'issue_date': cert.created_at.date().isoformat() if hasattr(cert, 'created_at') else 'N/A',
            })
    except ImportError:
        # Certificate model doesn't exist yet
        pass

    return JsonResponse({
        'enrollments': enrollments,
        'learners': learners,
        'certificates': certificates,
        'companies': list(Company.objects.all().values('id', 'name', 'registration_number', 'is_verified', 'email', 'phone', 'city', 'country'))[:100],
        'provisional_enrollments': list(ProvisionalEnrollment.objects.filter(status='provisional').values(
            'id', 'user__email', 'enrollment_type', 'status', 'created_at', 'reference_code', 'programme__title'
        ))[:100]
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@require_payment_admin
def verify_provisional_enrollment(request, enrollment_id):
    """Verify or reject a provisional enrollment (e.g. for learnership prerequisites)"""
    try:
        data = request.data
        status = data.get('status')  # 'confirmed' or 'rejected'
        notes = data.get('notes', '')

        enrollment = ProvisionalEnrollment.objects.get(id=enrollment_id)

        if status == 'confirmed':
            enrollment.status = 'confirmed'
            enrollment.verified_by = request.user
            enrollment.verified_at = timezone.now()
            enrollment.verification_notes = notes
            enrollment.prerequisites_verified = True
            
            # Also update LearnershipEnrollment if it exists
            if enrollment.enrollment_type == 'learnership':
                from apps.learnerships.models import LearnershipEnrollment, EnrollmentStatus as LearnershipEnrollmentStatus
                learnership_enrollment = LearnershipEnrollment.objects.filter(
                    payment_transaction=enrollment.payment_transaction
                ).first()
                
                if learnership_enrollment:
                    learnership_enrollment.status = LearnershipEnrollmentStatus.CONFIRMED
                    learnership_enrollment.prerequisites_verified = True
                    learnership_enrollment.verified_by = request.user
                    learnership_enrollment.verified_at = timezone.now()
                    learnership_enrollment.verification_notes = notes
                    learnership_enrollment.confirmed_at = timezone.now()
                    learnership_enrollment.save()
            
            enrollment.confirm_enrollment() # This triggers AICERTS enrollment
            enrollment.save()

            return JsonResponse({'success': True, 'message': 'Enrollment confirmed and learner enrolled.'})

        elif status == 'rejected':
            enrollment.status = 'rejected'
            enrollment.verified_by = request.user
            enrollment.verified_at = timezone.now()
            enrollment.verification_notes = notes
            
            # Also update LearnershipEnrollment if it exists
            if enrollment.enrollment_type == 'learnership':
                from apps.learnerships.models import LearnershipEnrollment, EnrollmentStatus as LearnershipEnrollmentStatus
                learnership_enrollment = LearnershipEnrollment.objects.filter(
                    payment_transaction=enrollment.payment_transaction
                ).first()
                
                if learnership_enrollment:
                    learnership_enrollment.status = LearnershipEnrollmentStatus.REJECTED
                    learnership_enrollment.verified_by = request.user
                    learnership_enrollment.verified_at = timezone.now()
                    learnership_enrollment.verification_notes = notes
                    learnership_enrollment.save()
            
            enrollment.save()

            return JsonResponse({'success': True, 'message': 'Enrollment rejected.'})

        return JsonResponse({'error': 'Invalid status'}, status=400)

    except ProvisionalEnrollment.DoesNotExist:
        return JsonResponse({'error': 'Enrollment not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


# ==================== EXECUTIVE ADMIN ENDPOINTS ====================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@require_executive_admin
def get_executive_analytics(request):
    """Get executive analytics and insights"""
    period = request.GET.get('period', 'month')  # day, week, month, quarter, year

    # Calculate date range
    now = timezone.now()
    if period == 'day':
        start_date = now - timedelta(days=1)
    elif period == 'week':
        start_date = now - timedelta(days=7)
    elif period == 'month':
        start_date = now - timedelta(days=30)
    elif period == 'quarter':
        start_date = now - timedelta(days=90)
    else:  # year
        start_date = now - timedelta(days=365)

    # Get payment transactions in period
    transactions = PaymentTransaction.objects.filter(
        status=PaymentStatus.SUCCESSFUL,
        created_at__gte=start_date
    )

    # Calculate KPIs
    total_revenue = transactions.aggregate(total=Sum('amount'))['total'] or Decimal('0')

    total_enrollments = Enrollment.objects.filter(
        created_at__gte=start_date
    ).count()

    active_learners = Enrollment.objects.filter(
        status=EnrollmentStatus.ENROLLED,
        created_at__gte=start_date
    ).values('user').distinct().count()

    completed = Enrollment.objects.filter(
        status=EnrollmentStatus.COMPLETED,
        created_at__gte=start_date
    ).count()

    completion_rate = (completed / total_enrollments * 100) if total_enrollments > 0 else 0

    pending_payments = PaymentReference.objects.filter(
        status='pending'
    ).count()

    # Revenue chart data (weekly breakdown)
    revenue_chart = []
    current_date = start_date
    while current_date <= now:
        week_end = current_date + timedelta(days=7)
        week_revenue = PaymentTransaction.objects.filter(
            status=PaymentStatus.SUCCESSFUL,
            created_at__gte=current_date,
            created_at__lt=week_end
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0')

        revenue_chart.append({
            'date': current_date.strftime('%Y-%m-%d'),
            'amount': float(week_revenue)
        })
        current_date = week_end

    # Enrollment stats
    enrollment_stats = {
        'active': Enrollment.objects.filter(status=EnrollmentStatus.ENROLLED).count(),
        'pending': Enrollment.objects.filter(status=EnrollmentStatus.PENDING_PAYMENT).count(),
        'completed': Enrollment.objects.filter(status=EnrollmentStatus.COMPLETED).count(),
        'cancelled': Enrollment.objects.filter(status=EnrollmentStatus.CANCELLED).count(),
    }

    # Top programs - group by enrollment type
    top_programs = []
    enrollment_by_type = Enrollment.objects.filter(
        created_at__gte=start_date,
        status=EnrollmentStatus.ENROLLED
    ).values('enrollment_type').annotate(
        enrollments=Count('id'),
        revenue=Sum('final_amount')
    ).order_by('-enrollments')[:5]

    for prog in enrollment_by_type:
        top_programs.append({
            'title': prog['enrollment_type'].replace('_', ' ').title(),
            'enrollments': prog['enrollments'],
            'revenue': float(prog['revenue'] or 0),
        })

    # Payment methods breakdown
    payment_methods = []
    methods_stats = PaymentTransaction.objects.filter(
        status=PaymentStatus.SUCCESSFUL,
        created_at__gte=start_date
    ).values('provider_method').annotate(
        count=Count('id')
    )

    total_transactions = sum(m['count'] for m in methods_stats)

    for method in methods_stats:
        percentage = (method['count'] / total_transactions * 100) if total_transactions > 0 else 0
        payment_methods.append({
            'name': method['provider_method'].replace('_', ' ').title() if method['provider_method'] else 'Unknown',
            'count': method['count'],
            'percentage': round(percentage, 1),
        })

    # Recent activity
    recent_activity = []

    # Recent enrollments
    recent_enrollments = Enrollment.objects.filter(
        status=EnrollmentStatus.ENROLLED
    ).order_by('-enrolled_at')[:5]

    for enrollment in recent_enrollments:
        recent_activity.append({
            'type': 'enrollment',
            'description': f'New enrollment: {enrollment.learner_full_name}',
            'timestamp': enrollment.enrolled_at.isoformat() if enrollment.enrolled_at else enrollment.created_at.isoformat(),
        })

    # Recent payments
    recent_payments = PaymentTransaction.objects.filter(
        status=PaymentStatus.SUCCESSFUL
    ).order_by('-completed_at')[:5]

    for payment in recent_payments:
        recent_activity.append({
            'type': 'payment',
            'description': f'Payment received: {payment.amount} {payment.currency}',
            'timestamp': payment.completed_at.isoformat() if payment.completed_at else payment.created_at.isoformat(),
        })

    # Sort recent activity by timestamp
    recent_activity.sort(key=lambda x: x['timestamp'], reverse=True)
    recent_activity = recent_activity[:10]

    return JsonResponse({
        'total_revenue': float(total_revenue),
        'total_enrollments': total_enrollments,
        'active_learners': active_learners,
        'completion_rate': round(completion_rate, 1),
        'pending_payments': pending_payments,
        'revenue_chart': revenue_chart,
        'enrollment_stats': enrollment_stats,
        'top_programs': top_programs,
        'payment_methods': payment_methods,
        'recent_activity': recent_activity,
        'enrollment_distribution': [
            {'name': 'Masterclass', 'value': Enrollment.objects.filter(enrollment_type='masterclass').count()},
            {'name': 'Learnership', 'value': Enrollment.objects.filter(enrollment_type='learnership').count()},
            {'name': 'Industry', 'value': Enrollment.objects.filter(enrollment_type='industry').count()},
            {'name': 'Custom', 'value': Enrollment.objects.filter(enrollment_type='custom_selection').count()},
        ]
    })


# ==================== SALES & MARKETING ENDPOINTS ====================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@require_payment_admin  # Sales & Marketing also needs high-level access
def get_sales_marketing_analytics(request):
    """Get sales and marketing specific analytics"""
    period = request.GET.get('period', 'month')
    
    # Calculate date range
    now = timezone.now()
    if period == 'day':
        start_date = now - timedelta(days=1)
    elif period == 'week':
        start_date = now - timedelta(days=7)
    elif period == 'month':
        start_date = now - timedelta(days=30)
    else:
        start_date = now - timedelta(days=365)

    # 1. Wishlist Stats
    total_wishlist_items = Wishlist.objects.count()
    new_wishlist_items = Wishlist.objects.filter(created_at__gte=start_date).count()
    converted_wishlist = Wishlist.objects.filter(converted_to_enrollment=True).count()
    conversion_rate = (converted_wishlist / total_wishlist_items * 100) if total_wishlist_items > 0 else 0

    wishlist_by_type = Wishlist.objects.values('training_type').annotate(count=Count('id')).order_by('-count')

    # 2. Cart Stats
    active_carts = CourseCart.objects.filter(status='active').count()
    abandoned_carts = CourseCart.objects.filter(status='abandoned').count()
    checkout_carts = CourseCart.objects.filter(status='checkout').count()
    completed_carts = CourseCart.objects.filter(status='completed').count()

    # 3. Sales Trends (Daily/Weekly based on period)
    sales_trend = []
    # Simplified trend for now
    for i in range(7):
        date = (now - timedelta(days=i)).date()
        daily_sales = PaymentTransaction.objects.filter(
            status=PaymentStatus.SUCCESSFUL,
            created_at__date=date
        ).aggregate(total=Sum('amount'))['total'] or 0
        sales_trend.append({
            'date': date.isoformat(),
            'amount': float(daily_sales)
        })

    # 4. Top Leads
    # We need to manually construct this list to avoid complex serializer logic for now
    # Or just use values()
    top_leads_qs = Wishlist.objects.filter(
        interest_level='high', 
        converted_to_enrollment=False
    ).select_related('user').order_by('-created_at')[:10]
    
    top_leads = []
    for lead in top_leads_qs:
        top_leads.append({
            'user__name': lead.user.get_full_name() or lead.user.username,
            'user__email': lead.user.email,
            'training_type': lead.training_type,
            'created_at': lead.created_at.isoformat(),
        })

    return JsonResponse({
        'wishlist': {
            'total': total_wishlist_items,
            'new': new_wishlist_items,
            'conversion_rate': round(conversion_rate, 1),
            'by_type': list(wishlist_by_type)
        },
        'cart': {
            'active': active_carts,
            'abandoned': abandoned_carts,
            'checkout': checkout_carts,
            'completed': completed_carts
        },
        'sales_trend': sales_trend,
        'top_leads': top_leads
    })


# ==================== FAILED PROVISIONING ADMIN ENDPOINTS ====================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@require_payment_admin
def get_failed_provisioning_data(request):
    """
    Get failed provisioning data for admin review.
    
    Shows transactions where payment was successful but enrollment provisioning failed
    after max retries. Allows manual review and retry.
    """
    status_filter = request.GET.get('status', 'all')  # all, pending_review, retry_failed, resolved
    days_filter = request.GET.get('days', '30')  # 7, 30, 90, all
    
    # Calculate date range
    now = timezone.now()
    if days_filter == '7':
        start_date = now - timedelta(days=7)
    elif days_filter == '30':
        start_date = now - timedelta(days=30)
    elif days_filter == '90':
        start_date = now - timedelta(days=90)
    else:
        start_date = now - timedelta(days=365)  # Default to 1 year
    
    # Base query: successful payments with provisioning metadata
    transactions_qs = PaymentTransaction.objects.filter(
        status=PaymentStatus.SUCCESSFUL,
        created_at__gte=start_date,
    ).filter(
        Q(metadata__has_key='provisioning_completed') |  # Already provisioned
        Q(metadata__has_key='provisioning_failed') |     # Failed provisioning
        ~Q(metadata__has_key='provisioning_completed')   # Never attempted
    ).select_related('user').order_by('-completed_at')
    
    # Apply status filter
    if status_filter == 'pending_review':
        # Successful payment but no provisioning completed
        transactions_qs = transactions_qs.filter(
            Q(metadata__has_key='provisioning_failed') |
            ~Q(metadata__has_key='provisioning_completed')
        )
    elif status_filter == 'retry_failed':
        # Explicitly marked as failed after retries
        transactions_qs = transactions_qs.filter(
            metadata__provisioning_failed=True
        )
    elif status_filter == 'resolved':
        # Successfully provisioned
        transactions_qs = transactions_qs.filter(
            metadata__provisioning_completed=True
        )
    
    # Build response data
    failed_provisioning = []
    for txn in transactions_qs[:200]:  # Limit to 200 for performance
        # Check provisioning status
        provisioning_completed = txn.metadata.get('provisioning_completed', False)
        provisioning_failed = txn.metadata.get('provisioning_failed', False)
        provisioning_error = txn.metadata.get('provisioning_error', '')
        provisioning_attempts = txn.metadata.get('provisioning_attempts', 0)
        
        # Determine status
        if provisioning_completed:
            txn_status = 'resolved'
        elif provisioning_failed:
            txn_status = 'retry_failed'
        else:
            txn_status = 'pending_review'
        
        # Get enrollment type and program info
        enrollment_type = txn.enrollment_type or txn.metadata.get('enrollment_type', 'Unknown')
        program_id = txn.metadata.get('program_id', 'N/A')
        
        # Get user info
        user_email = txn.user.email if txn.user else (txn.individual_email or txn.company_email or 'N/A')
        user_name = txn.user.get_full_name() if txn.user else (txn.individual_name or txn.company_name or 'N/A')
        
        failed_provisioning.append({
            'id': str(txn.id),
            'transaction_id': txn.provider_reference,
            'order_tracking': txn.order.tracking if txn.order else 'N/A',
            'user_email': user_email,
            'user_name': user_name,
            'amount': float(txn.amount),
            'currency': txn.currency,
            'enrollment_type': enrollment_type,
            'program_id': program_id,
            'payment_completed_at': txn.completed_at.isoformat() if txn.completed_at else txn.created_at.isoformat(),
            'provisioning_status': txn_status,
            'provisioning_completed': provisioning_completed,
            'provisioning_failed': provisioning_failed,
            'provisioning_error': provisioning_error,
            'provisioning_attempts': provisioning_attempts,
            'last_attempt_at': txn.metadata.get('last_provisioning_attempt', ''),
        })
    
    # Summary statistics
    total_successful_payments = PaymentTransaction.objects.filter(
        status=PaymentStatus.SUCCESSFUL,
        created_at__gte=start_date,
    ).count()
    
    total_provisioned = PaymentTransaction.objects.filter(
        status=PaymentStatus.SUCCESSFUL,
        created_at__gte=start_date,
        metadata__provisioning_completed=True,
    ).count()
    
    total_failed = PaymentTransaction.objects.filter(
        status=PaymentStatus.SUCCESSFUL,
        created_at__gte=start_date,
        metadata__provisioning_failed=True,
    ).count()
    
    pending_review = total_successful_payments - total_provisioned - total_failed
    
    return JsonResponse({
        'failed_provisioning': failed_provisioning,
        'summary': {
            'total_successful_payments': total_successful_payments,
            'total_provisioned': total_provisioned,
            'total_failed': total_failed,
            'pending_review': pending_review,
            'success_rate': round((total_provisioned / total_successful_payments * 100) if total_successful_payments > 0 else 0, 2),
            'failure_rate': round((total_failed / total_successful_payments * 100) if total_successful_payments > 0 else 0, 2),
        },
        'filters': {
            'status': status_filter,
            'days': days_filter,
        },
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@require_payment_admin
def retry_provisioning(request, transaction_id):
    """
    Manually retry provisioning for a failed transaction.
    
    This is used when automatic retries have failed and admin has reviewed the case.
    """
    try:
        data = request.data
        notes = data.get('notes', '')
        
        # Get transaction
        try:
            transaction = PaymentTransaction.objects.select_related('user').get(id=transaction_id)
        except PaymentTransaction.DoesNotExist:
            return JsonResponse({'error': 'Transaction not found'}, status=404)
        
        # Verify payment was successful
        if transaction.status != PaymentStatus.SUCCESSFUL:
            return JsonResponse({
                'error': 'Cannot retry provisioning for non-successful payment'
            }, status=400)
        
        # Check if already provisioned
        if transaction.metadata.get('provisioning_completed'):
            return JsonResponse({
                'error': 'Provisioning already completed for this transaction',
                'already_completed': True,
            }, status=400)
        
        # Get enrollment data
        enrollment_type = transaction.enrollment_type or transaction.metadata.get('enrollment_type')
        program_id = transaction.metadata.get('program_id')
        
        if not enrollment_type:
            return JsonResponse({
                'error': 'No enrollment type found in transaction'
            }, status=400)
        
        # Retry provisioning using payment service
        from apps.payments.services.payment_service import payment_service
        
        try:
            payment_service._provision_enrollment(
                user=transaction.user,
                enrollment_type=enrollment_type,
                program_id=program_id,
                transaction=transaction,
                is_manual_retry=True,
                manual_retry_notes=notes,
            )
            
            # Mark as completed
            transaction.metadata['provisioning_completed'] = True
            transaction.metadata['provisioning_completed_at'] = timezone.now().isoformat()
            transaction.metadata['provisioning_completed_manually'] = True
            transaction.metadata['manual_retry_notes'] = notes
            transaction.metadata['manual_retry_by'] = request.user.email
            transaction.save(update_fields=['metadata'])
            
            return JsonResponse({
                'success': True,
                'message': 'Provisioning completed successfully',
                'transaction_id': str(transaction.id),
            })
            
        except Exception as e:
            # Log the error
            transaction.metadata['provisioning_error'] = str(e)
            transaction.metadata['last_manual_retry_at'] = timezone.now().isoformat()
            transaction.metadata['last_manual_retry_by'] = request.user.email
            transaction.metadata['last_manual_retry_error'] = str(e)
            transaction.save(update_fields=['metadata'])
            
            return JsonResponse({
                'success': False,
                'error': f'Provisioning failed: {str(e)}',
                'transaction_id': str(transaction.id),
            }, status=400)
        
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@require_payment_admin
def mark_provisioning_resolved(request, transaction_id):
    """
    Manually mark provisioning as resolved (for cases where external enrollment was done manually).
    """
    try:
        data = request.data
        notes = data.get('notes', '')
        
        transaction = PaymentTransaction.objects.get(id=transaction_id)
        
        # Mark as resolved
        transaction.metadata['provisioning_completed'] = True
        transaction.metadata['provisioning_completed_at'] = timezone.now().isoformat()
        transaction.metadata['provisioning_resolved_manually'] = True
        transaction.metadata['manual_resolution_notes'] = notes
        transaction.metadata['resolved_by'] = request.user.email
        transaction.save(update_fields=['metadata'])
        
        return JsonResponse({
            'success': True,
            'message': 'Provisioning marked as resolved',
        })
        
    except PaymentTransaction.DoesNotExist:
        return JsonResponse({'error': 'Transaction not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


# ==================== HR ADMIN (PERSONNEL & INSTRUCTORS) ====================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@require_hr_admin
def get_hr_dashboard_data(request):
    """Get HR specific dashboard data - instructors, overtime, attendance stats"""
    from apps.instructors.models import Instructor

    # Try importing optional models, handle if they don't exist (deleted in migration 0008)
    OvertimeRequest = None
    FacilitatorAttendance = None
    EarningsAccrual = None
    
    try:
        from apps.instructors.models import OvertimeRequest
    except ImportError:
        pass
        
    try:
        from apps.instructors.models import FacilitatorAttendance
    except ImportError:
        pass

    try:
        from apps.instructors.models import EarningsAccrual
    except ImportError:
        pass
    
    now = timezone.now()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)

    # 1. Instructor Stats
    total_instructors = User.objects.filter(role_id=2).count()
    # Check if is_suspended field exists on Instructor (removed in migration 0008)
    # If removed, we can't filter by it.
    try:
        active_instructors = Instructor.objects.filter(is_active=True).count()
        # Fallback logic if is_suspended was removed
        suspended_instructors = 0 
    except Exception:
         active_instructors = 0
         suspended_instructors = 0
    
    # 2. Recruitment/Applications
    pending_applications = Instructor.objects.filter(is_active=False).count()

    # 3. Attendance Today
    today_clock_ins = 0
    active_sessions = 0
    if FacilitatorAttendance:
        today_clock_ins = FacilitatorAttendance.objects.filter(clock_in__gte=today_start).count()
        active_sessions = FacilitatorAttendance.objects.filter(status='active').count()

    # 4. Overtime Requests
    pending_overtime = 0
    if OvertimeRequest:
        pending_overtime = OvertimeRequest.objects.filter(status='pending').count()
    
    # 5. Monthly Payroll Summary
    monthly_accruals = 0
    if EarningsAccrual:
        monthly_accruals = EarningsAccrual.objects.filter(accrued_at__gte=month_start).aggregate(total=Sum('total_amount'))['total'] or 0

    # Get allowed countries for the current user
    from .api_views import get_admin_allowed_countries
    allowed_countries = get_admin_allowed_countries(request.user)

    return JsonResponse({
        'allowed_countries': allowed_countries,
        'instructors': {
            'total': total_instructors,
            'active': active_instructors,
            'suspended': suspended_instructors,
            'pending_apps': pending_applications
        },
        'attendance': {
            'today_count': today_clock_ins,
            'active_now': active_sessions
        },
        'overtime': {
            'pending_count': pending_overtime
        },
        'payroll': {
            'monthly_total': float(monthly_accruals)
        }
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
@require_hr_admin
def get_instructor_payroll_data(request):
    """Get all instructors and their current rates/hours"""
    from apps.instructors.models import Instructor
    instructors = User.objects.filter(role_id=2).select_related('facilitator_profile')  # Assuming related_name exists
    
    data = []
    for instructor in instructors:
        is_suspended = False
        try:
            # Check if has attribute first, as migration might have removed it
            if hasattr(instructor.facilitator_profile, 'is_suspended'):
                is_suspended = instructor.facilitator_profile.is_suspended
        except:
            # Fallback if profile doesn't exist
            pass
            
        data.append({
            'id': instructor.id,
            'name': instructor.get_full_name(),
            'email': instructor.email,
            'hourly_rate': float(instructor.hourly_rate),
            'balance': instructor.balance,
            'status': 'Suspended' if is_suspended else ('Active' if instructor.is_active else 'Inactive'),
            'is_suspended': is_suspended,
            'bank_name': instructor.bank_name or 'N/A',
            'account_number': instructor.bank_account_number or 'N/A',
        })
    
    return JsonResponse({'instructors': data})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@require_hr_admin
def update_instructor_rate(request, user_id):
    """Update an instructor's hourly rate"""
    try:
        data = request.data
        new_rate = data.get('hourly_rate')
        
        if new_rate is None:
            return JsonResponse({'error': 'hourly_rate is required'}, status=400)

        instructor = User.objects.get(id=user_id, role_id=2)
        instructor.hourly_rate = Decimal(str(new_rate))
        instructor.save()

        return JsonResponse({
            'success': True,
            'message': 'Rate updated successfully',
            'new_rate': float(instructor.hourly_rate)
        })
    except User.DoesNotExist:
        return JsonResponse({'error': 'Instructor not found'}, status=404)
    except Exception as e:
        return JsonResponse({'error': str(e)}, status=500)


# ==================== EFT ADMIN VERIFICATION ENDPOINTS ====================

@api_view(['GET'])
@permission_classes([IsAuthenticated])
@require_payment_admin
def get_eft_verification_dashboard(request):
    """
    Get EFT verification dashboard data for admin interface.
    
    Returns summary statistics and pending EFT payments list.
    """
    try:
        # Get statistics
        total_pending = PaymentTransaction.objects.filter(
            provider='eft',
            status=PaymentStatus.PENDING
        ).count()
        
        total_pending_amount = PaymentTransaction.objects.filter(
            provider='eft',
            status=PaymentStatus.PENDING
        ).aggregate(total=Sum('amount'))['total'] or 0
        
        today = timezone.now().date()
        total_verified_today = PaymentTransaction.objects.filter(
            provider='eft',
            status=PaymentStatus.SUCCESSFUL,
            completed_at__date=today
        ).count()
        
        total_rejected_today = PaymentTransaction.objects.filter(
            provider='eft',
            status=PaymentStatus.FAILED,
            completed_at__date=today
        ).count()
        
        # Get pending EFT payments (last 100)
        pending_payments = PaymentTransaction.objects.filter(
            provider='eft',
            status=PaymentStatus.PENDING
        ).select_related('user').order_by('-created_at')[:100]
        
        pending_list = []
        for txn in pending_payments:
            # Get enrollment
            enrollment = None
            try:
                enrollment = ProvisionalEnrollment.objects.get(
                    payment_transaction=txn
                )
            except ProvisionalEnrollment.DoesNotExist:
                pass
            
            # Get proof of payment
            pop_uploaded = False
            pop_url = None
            if txn.metadata and 'proof_of_payment' in txn.metadata:
                pop_uploaded = True
                pop_url = txn.metadata['proof_of_payment'].get('file_url')
            
            # Calculate time remaining
            time_remaining = None
            is_expired = False
            if enrollment and enrollment.expires_at:
                if timezone.now() > enrollment.expires_at:
                    is_expired = True
                else:
                    time_diff = enrollment.expires_at - timezone.now()
                    hours = int(time_diff.total_seconds() / 3600)
                    time_remaining = f"{hours} hours"
            
            pending_list.append({
                'id': txn.id,
                'reference': txn.provider_reference,
                'amount': float(txn.amount),
                'currency': txn.currency,
                'customer_name': txn.individual_name or txn.company_name,
                'customer_email': txn.individual_email or txn.company_email,
                'customer_phone': txn.individual_phone or txn.company_phone,
                'program_type': txn.metadata.get('program_type') if txn.metadata else None,
                'program_id': txn.metadata.get('program_id') if txn.metadata else None,
                'program_title': txn.metadata.get('program_title') if txn.metadata else None,
                'created_at': txn.created_at.isoformat(),
                'expires_at': enrollment.expires_at.isoformat() if enrollment and enrollment.expires_at else None,
                'time_remaining': time_remaining,
                'is_expired': is_expired,
                'bank_details_submitted': txn.metadata and 'customer_bank_details' in txn.metadata,
                'proof_of_payment_uploaded': pop_uploaded,
                'proof_of_payment_url': pop_url,
            })
        
        return JsonResponse({
            'statistics': {
                'total_pending': total_pending,
                'total_pending_amount': float(total_pending_amount),
                'total_verified_today': total_verified_today,
                'total_rejected_today': total_rejected_today,
            },
            'pending_payments': pending_list,
        })
        
    except Exception as e:
        return JsonResponse(
            {'error': f'Failed to fetch EFT verification data: {str(e)}'},
            status=500
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@require_payment_admin
def admin_verify_eft_payment(request, reference):
    """
    Admin action to verify an EFT payment.
    
    POST /api/v1/payments/admin/eft/verify/<reference>/
    
    Request body:
    {
        "notes": "Verified against bank statement"  // optional
    }
    """
    try:
        data = request.data
        notes = data.get('notes', '')
        
        # Find transaction
        try:
            transaction = PaymentTransaction.objects.get(
                provider_reference=reference,
                provider='eft'
            )
        except PaymentTransaction.DoesNotExist:
            return JsonResponse(
                {'error': 'Transaction not found'},
                status=404
            )
        
        # Check if already verified
        if transaction.status == PaymentStatus.SUCCESSFUL:
            return JsonResponse(
                {'error': 'Payment already verified'},
                status=400
            )
        
        # Update transaction
        transaction.status = PaymentStatus.SUCCESSFUL
        transaction.completed_at = timezone.now()
        transaction.reconciled = True
        transaction.reconciliation_date = timezone.now().date()
        
        metadata = transaction.metadata or {}
        metadata['verified_by'] = {
            'user_id': request.user.id,
            'user_email': request.user.email,
            'verified_at': timezone.now().isoformat(),
            'notes': notes,
        }
        transaction.metadata = metadata
        transaction.save()
        
        # Update enrollment
        enrollment_id = None
        try:
            enrollment = ProvisionalEnrollment.objects.get(
                payment_transaction=transaction
            )
            enrollment.status = 'confirmed'
            enrollment.verified_by = request.user
            enrollment.verified_at = timezone.now()
            enrollment.save()
            enrollment_id = enrollment.id
        except ProvisionalEnrollment.DoesNotExist:
            pass
        
        return JsonResponse({
            'success': True,
            'message': 'Payment verified successfully',
            'reference': reference,
            'enrollment_id': enrollment_id,
        })
        
    except Exception as e:
        return JsonResponse(
            {'error': f'Failed to verify payment: {str(e)}'},
            status=500
        )


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@require_payment_admin
def admin_reject_eft_payment(request, reference):
    """
    Admin action to reject an EFT payment.
    
    POST /api/v1/payments/admin/eft/reject/<reference>/
    
    Request body:
    {
        "reason": "Amount does not match"  // required
    }
    """
    try:
        data = request.data
        rejection_reason = data.get('reason', '')
        
        if not rejection_reason:
            return JsonResponse(
                {'error': 'Rejection reason is required'},
                status=400
            )
        
        # Find transaction
        try:
            transaction = PaymentTransaction.objects.get(
                provider_reference=reference,
                provider='eft'
            )
        except PaymentTransaction.DoesNotExist:
            return JsonResponse(
                {'error': 'Transaction not found'},
                status=404
            )
        
        # Update transaction
        transaction.status = PaymentStatus.FAILED
        transaction.completed_at = timezone.now()
        
        metadata = transaction.metadata or {}
        metadata['rejected_by'] = {
            'user_id': request.user.id,
            'user_email': request.user.email,
            'rejected_at': timezone.now().isoformat(),
            'reason': rejection_reason,
        }
        transaction.metadata = metadata
        transaction.save()
        
        # Update enrollment
        try:
            enrollment = ProvisionalEnrollment.objects.get(
                payment_transaction=transaction
            )
            enrollment.status = 'rejected'
            enrollment.verified_by = request.user
            enrollment.verified_at = timezone.now()
            enrollment.rejection_reason = rejection_reason
            enrollment.save()
        except ProvisionalEnrollment.DoesNotExist:
            pass
        
        return JsonResponse({
            'success': True,
            'message': 'Payment rejected',
            'reference': reference,
        })
        
    except Exception as e:
        return JsonResponse(
            {'error': f'Failed to reject payment: {str(e)}'},
            status=500
        )


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_admin_role_assignment(request):
    """
    Returns the admin role and allowed countries for the current user.
    Used by various admin portals for role-based UI rendering.
    """
    user = request.user
    
    from .models import AdminRole
    
    # Get all role types
    roles_qs = AdminRole.objects.filter(user=user, is_active=True)
    role_types = list(roles_qs.values_list('role_type', flat=True))
    
    if user.is_superuser or user.is_staff:
        if 'system_admin' not in role_types:
            role_types.append('system_admin')
    
    if not role_types:
        role_type = 'student'
    else:
        role_type = role_types[0] # For backward compatibility
    
    # Get allowed countries
    from .api_views import get_admin_allowed_countries
    allowed_countries = get_admin_allowed_countries(user)
    
    from rest_framework.response import Response
    return Response({
        'role': role_type,
        'roles': role_types,
        'allowed_countries': allowed_countries,
        'is_admin': len(role_types) > 0,
        'user_id': user.id,
        'email': user.email,
        'full_name': user.get_full_name()
    })


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_staff_directory(request):
    """
    Get a directory of staff members for chat/collaboration.
    Filtered by name/email/role.
    """
    from rest_framework.response import Response
    search = request.query_params.get('search', '').strip()
    
    # Staff are superusers or have an AdminRole
    from .models import AdminRole
    admin_users_ids = AdminRole.objects.filter(is_active=True).values_list('user_id', flat=True)
    
    staff_qs = User.objects.filter(
        Q(id__in=admin_users_ids) | Q(is_superuser=True) | Q(is_staff=True)
    ).distinct().order_by('first_name', 'last_name')
    
    if search:
        staff_qs = staff_qs.filter(
            Q(first_name__icontains=search) |
            Q(last_name__icontains=search) |
            Q(email__icontains=search)
        )
    
    directory = []
    for staff in staff_qs[:100]:
        # Get role
        role = 'Staff'
        if staff.is_superuser:
            role = 'System Admin'
        else:
            admin_role = AdminRole.objects.filter(user=staff, is_active=True).first()
            if admin_role:
                role = admin_role.get_role_type_display()
        
        directory.append({
            'id': staff.id,
            'name': staff.get_full_name() or staff.username,
            'email': staff.email,
            'role': role,
            'avatar': None,
            'is_online': False
        })
    
    return Response({'directory': directory, 'total': staff_qs.count()})

