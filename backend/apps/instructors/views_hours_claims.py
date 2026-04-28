# apps/instructors/views_hours_claims.py
"""
Views for Instructor Hours Claims Management

Provides endpoints for:
- Instructors to submit hours claims
- HR Admin to review and approve claims
- Payroll summary generation
"""

from rest_framework import viewsets, status, permissions, decorators
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.db.models import Count, Sum, Avg, Q, F
from django.db.models.functions import TruncMonth
from django.conf import settings
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.html import strip_tags
import logging

from .models_hours_claims import (
    InstructorHoursClaim,
    InstructorOvertime,
    InstructorPayrollSummary
)
from .models import Instructor
from .serializers_hours_claims import (
    InstructorHoursClaimSerializer,
    InstructorHoursClaimCreateSerializer,
    InstructorHoursClaimSubmitSerializer,
    InstructorHoursClaimReviewSerializer,
    InstructorOvertimeSerializer,
    InstructorOvertimeCreateSerializer,
    InstructorPayrollSummarySerializer
)
from apps.bbb_integration.models import LiveSession
from apps.users.permissions import IsHrAdmin

logger = logging.getLogger(__name__)


class InstructorHoursClaimViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing instructor hours claims.
    
    Instructors can:
    - Create draft claims
    - Submit claims for review
    - View their own claims
    
    HR Admin can:
    - View all claims
    - Review and approve/reject claims
    - Generate payroll summaries
    """
    queryset = InstructorHoursClaim.objects.all().select_related(
        'instructor__user', 'reviewed_by'
    )
    serializer_class = InstructorHoursClaimSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get_serializer_class(self):
        if self.action == 'create':
            return InstructorHoursClaimCreateSerializer
        return InstructorHoursClaimSerializer

    def get_queryset(self):
        queryset = super().get_queryset()

        # HR Admin can see all claims
        if self.request.user.is_superuser or (
            hasattr(self.request.user, 'admin_roles') and
            self.request.user.admin_roles.filter(
                role_type='hr_admin',
                is_active=True
            ).exists()
        ):
            # Filter by status
            status_param = self.request.query_params.get('status', None)
            if status_param:
                queryset = queryset.filter(status=status_param)

            # Filter by month/year
            month = self.request.query_params.get('month', None)
            year = self.request.query_params.get('year', None)
            if month:
                queryset = queryset.filter(month=month)
            if year:
                queryset = queryset.filter(year=year)

            # Filter by instructor
            instructor_id = self.request.query_params.get('instructor_id', None)
            if instructor_id:
                queryset = queryset.filter(instructor_id=instructor_id)

            return queryset.order_by('-created_at')

        # Regular instructors can only see their own claims
        try:
            instructor = self.request.user.instructor
            return queryset.filter(instructor=instructor).order_by('-created_at')
        except Instructor.DoesNotExist:
            return queryset.none()

    def create(self, request, *args, **kwargs):
        """Create a new hours claim (draft)."""
        try:
            instructor = request.user.instructor
        except Instructor.DoesNotExist:
            return Response(
                {'error': 'User is not an instructor'},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = self.get_serializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)

        headers = self.get_success_headers(serializer.data)
        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED,
            headers=headers
        )

    @decorators.action(detail=True, methods=['post'])
    def submit_claim(self, request, pk=None):
        """
        Instructor submits hours claim for HR review.
        Includes session IDs for verification.
        """
        claim = self.get_object()

        # Only instructor can submit their own claim
        if claim.instructor.user != request.user:
            return Response(
                {'error': 'You can only submit your own claims'},
                status=status.HTTP_403_FORBIDDEN
            )

        if claim.status != 'draft':
            return Response(
                {'error': 'Only draft claims can be submitted'},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = InstructorHoursClaimSubmitSerializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)

        # Get session data
        session_ids = serializer.validated_data['session_ids']
        sessions = LiveSession.objects.filter(
            id__in=session_ids,
            instructor=claim.instructor,
            status='completed'
        )

        # Calculate regular hours from sessions
        total_minutes = sum(s.duration_minutes for s in sessions)
        regular_hours = total_minutes / 60.0

        # Update claim
        claim.regular_hours = regular_hours
        claim.session_ids = session_ids
        claim.session_breakdown = [
            {
                'session_id': s.id,
                'title': s.title,
                'date': s.scheduled_start.isoformat(),
                'duration_minutes': s.duration_minutes,
            }
            for s in sessions
        ]
        claim.status = 'pending'
        claim.submitted_at = timezone.now()
        claim.save()

        # Notify HR Admin
        self._notify_hr_admin_of_submission(claim)

        return Response(
            InstructorHoursClaimSerializer(claim).data,
            status=status.HTTP_200_OK
        )

    @decorators.action(detail=True, methods=['post'])
    def review_claim(self, request, pk=None):
        """
        HR Admin reviews and approves/rejects hours claim.
        """
        if not (request.user.is_superuser or IsHrAdmin().has_permission(request, self)):
            return Response(
                {'error': 'HR Admin permission required'},
                status=status.HTTP_403_FORBIDDEN
            )

        claim = self.get_object()
        serializer = InstructorHoursClaimReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        validated_data = serializer.validated_data
        new_status = validated_data['status']

        # Update claim status
        old_status = claim.status
        claim.status = new_status

        # Handle approval
        if new_status == 'approved':
            claim.approval_notes = validated_data.get('approval_notes', '')
            claim.payment_reference = validated_data.get('payment_reference', '')
            claim.reviewed_by = request.user
            claim.reviewed_at = timezone.now()

            # Send approval email
            self._send_approval_email(claim)

        # Handle rejection
        elif new_status == 'rejected':
            claim.rejection_reason = validated_data.get('rejection_reason', '')
            claim.reviewed_by = request.user
            claim.reviewed_at = timezone.now()

            # Send rejection email
            self._send_rejection_email(claim)

        claim.save()

        # Log status change
        logger.info(
            f"Hours claim {claim.claim_id} status changed from {old_status} "
            f"to {new_status} by {request.user.email}"
        )

        return Response(
            InstructorHoursClaimSerializer(claim).data,
            status=status.HTTP_200_OK
        )

    @decorators.action(detail=False, methods=['get'])
    def my_claims(self, request):
        """Get current instructor's hours claims."""
        try:
            instructor = request.user.instructor
            claims = InstructorHoursClaim.objects.filter(
                instructor=instructor
            ).order_by('-created_at')

            page = self.paginate_queryset(claims)
            if page is not None:
                serializer = self.get_serializer(page, many=True)
                return self.get_paginated_response(serializer.data)

            serializer = self.get_serializer(claims, many=True)
            return Response(serializer.data)
        except Instructor.DoesNotExist:
            return Response(
                {'error': 'User is not an instructor'},
                status=status.HTTP_400_BAD_REQUEST
            )

    @decorators.action(detail=False, methods=['get'])
    def pending_claims(self, request):
        """Get pending claims for HR Admin review."""
        if not (request.user.is_superuser or IsHrAdmin().has_permission(request, self)):
            return Response(
                {'error': 'HR Admin permission required'},
                status=status.HTTP_403_FORBIDDEN
            )

        claims = InstructorHoursClaim.objects.filter(
            status__in=['pending', 'under_review']
        ).select_related('instructor__user').order_by('-submitted_at')

        page = self.paginate_queryset(claims)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(claims, many=True)
        return Response(serializer.data)

    @decorators.action(detail=False, methods=['get'])
    def payroll_summary(self, request):
        """Get payroll summary for a specific month/year."""
        if not (request.user.is_superuser or IsHrAdmin().has_permission(request, self)):
            return Response(
                {'error': 'HR Admin permission required'},
                status=status.HTTP_403_FORBIDDEN
            )

        month = request.query_params.get('month')
        year = request.query_params.get('year')

        if not month or not year:
            # Return current month summary
            month = timezone.now().month
            year = timezone.now().year

        try:
            summary = InstructorPayrollSummary.objects.get(
                month=month,
                year=year
            )
            serializer = InstructorPayrollSummarySerializer(summary)
            return Response(serializer.data)
        except InstructorPayrollSummary.DoesNotExist:
            # Generate summary
            summary = self._generate_payroll_summary(int(month), int(year))
            serializer = InstructorPayrollSummarySerializer(summary)
            return Response(serializer.data)

    def _generate_payroll_summary(self, month, year):
        """Generate payroll summary for a given month/year."""
        claims = InstructorHoursClaim.objects.filter(
            month=month,
            year=year
        )

        total_instructors = claims.values('instructor').distinct().count()
        total_regular_hours = claims.aggregate(Sum('regular_hours'))['regular_hours__sum'] or 0
        total_overtime_hours = claims.aggregate(Sum('overtime_hours'))['overtime_hours__sum'] or 0
        total_payroll_amount = claims.aggregate(Sum('total_claim_amount'))['total_claim_amount__sum'] or 0
        total_paid_amount = claims.filter(
            status='paid'
        ).aggregate(Sum('total_claim_amount'))['total_claim_amount__sum'] or 0
        total_pending_amount = claims.filter(
            status__in=['pending', 'under_review', 'approved']
        ).aggregate(Sum('total_claim_amount'))['total_claim_amount__sum'] or 0

        summary = InstructorPayrollSummary.objects.create(
            month=month,
            year=year,
            total_instructors=total_instructors,
            total_regular_hours=total_regular_hours,
            total_overtime_hours=total_overtime_hours,
            total_payroll_amount=total_payroll_amount,
            total_paid_amount=total_paid_amount,
            total_pending_amount=total_pending_amount,
            total_claims=claims.count(),
            approved_claims=claims.filter(status='approved').count(),
            pending_claims=claims.filter(status__in=['pending', 'under_review']).count(),
        )

        return summary

    def _notify_hr_admin_of_submission(self, claim):
        """Notify HR Admin of new claim submission."""
        # Find HR Admin users
        from apps.payments.models import AdminRole
        hr_admins = User.objects.filter(
            admin_roles__role_type='hr_admin',
            admin_roles__is_active=True
        )

        subject = f"New Hours Claim Submitted - {claim.instructor.user.name}"
        
        html_message = render_to_string('emails/hours_claim_submission.html', {
            'claim': claim,
            'instructor': claim.instructor.user,
        })
        
        plain_message = strip_tags(html_message)

        for admin in hr_admins:
            send_mail(
                subject,
                plain_message,
                settings.DEFAULT_FROM_EMAIL,
                [admin.email],
                html_message=html_message,
                fail_silently=True,
            )

    def _send_approval_email(self, claim):
        """Send approval email to instructor."""
        subject = f"Hours Claim Approved - {claim.get_month_year_label}"
        
        html_message = render_to_string('emails/hours_claim_approved.html', {
            'claim': claim,
            'instructor': claim.instructor.user,
        })
        
        plain_message = strip_tags(html_message)

        send_mail(
            subject,
            plain_message,
            settings.DEFAULT_FROM_EMAIL,
            [claim.instructor.user.email],
            html_message=html_message,
            fail_silently=True,
        )

    def _send_rejection_email(self, claim):
        """Send rejection email to instructor."""
        subject = f"Hours Claim Update - {claim.get_month_year_label}"
        
        html_message = render_to_string('emails/hours_claim_rejected.html', {
            'claim': claim,
            'instructor': claim.instructor.user,
        })
        
        plain_message = strip_tags(html_message)

        send_mail(
            subject,
            plain_message,
            settings.DEFAULT_FROM_EMAIL,
            [claim.instructor.user.email],
            html_message=html_message,
            fail_silently=True,
        )


class InstructorOvertimeViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing individual overtime requests.
    """
    queryset = InstructorOvertime.objects.all().select_related(
        'instructor__user', 'reviewed_by', 'hours_claim'
    )
    serializer_class = InstructorOvertimeSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

    def get_serializer_class(self):
        if self.action == 'create':
            return InstructorOvertimeCreateSerializer
        return InstructorOvertimeSerializer

    def get_queryset(self):
        queryset = super().get_queryset()

        # HR Admin can see all overtime requests
        if self.request.user.is_superuser or IsHrAdmin().has_permission(self.request, self):
            # Filter by status
            status_param = self.request.query_params.get('status', None)
            if status_param:
                queryset = queryset.filter(status=status_param)

            return queryset.order_by('-overtime_date')

        # Regular instructors can only see their own requests
        try:
            instructor = self.request.user.instructor
            return queryset.filter(instructor=instructor).order_by('-overtime_date')
        except Instructor.DoesNotExist:
            return queryset.none()

    def create(self, request, *args, **kwargs):
        """Create a new overtime request."""
        try:
            instructor = request.user.instructor
        except Instructor.DoesNotExist:
            return Response(
                {'error': 'User is not an instructor'},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = self.get_serializer(
            data=request.data,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)

        headers = self.get_success_headers(serializer.data)
        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED,
            headers=headers
        )

    @decorators.action(detail=True, methods=['post'])
    def review_request(self, request, pk=None):
        """HR Admin reviews overtime request."""
        if not (request.user.is_superuser or IsHrAdmin().has_permission(request, self)):
            return Response(
                {'error': 'HR Admin permission required'},
                status=status.HTTP_403_FORBIDDEN
            )

        overtime = self.get_object()
        new_status = request.data.get('status')

        if new_status not in ['approved', 'rejected']:
            return Response(
                {'error': 'Status must be approved or rejected'},
                status=status.HTTP_400_BAD_REQUEST
            )

        overtime.status = new_status
        overtime.reviewed_by = request.user
        overtime.reviewed_at = timezone.now()

        if new_status == 'approved':
            overtime.approval_notes = request.data.get('approval_notes', '')
        else:
            overtime.rejection_reason = request.data.get('rejection_reason', '')

        overtime.save()

        return Response(
            InstructorOvertimeSerializer(overtime).data,
            status=status.HTTP_200_OK
        )
