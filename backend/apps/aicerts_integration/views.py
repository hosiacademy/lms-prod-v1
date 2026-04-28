# apps/aicerts_integration/views.py
"""
Views for AICERTs Partnership Integration

Handles:
- Course enrollment with dual sync (Hosi + AICERTs)
- SSO redirect generation for course access
- Instructor validation for course assignments
- Enrollment status tracking
"""

from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.views import APIView
from django.shortcuts import redirect, get_object_or_404
from django.http import JsonResponse
from django.utils import timezone
from django.db import transaction
from django.conf import settings
import logging
import secrets
from datetime import timedelta

from .models import (
    AICertsEnrollment,
    AICertsInstructorDesignation,
    AICertsSyncLog,
    AICertsSSOSession
)
from .services import (
    SSOService,
    EnrollmentSyncService,
    InstructorValidationService,
    AICERTsAPIError,
    AICERTsEnrollmentError
)
from .serializers import (
    AICertsEnrollmentSerializer,
    AICertsInstructorDesignationSerializer,
    AICertsSyncLogSerializer,
    EnrollUserSerializer,
    GenerateSSOSerializer
)
from apps.aicerts_courses.models import AiCertsCourse

logger = logging.getLogger(__name__)


class AICertsEnrollmentViewSet(viewsets.ModelViewSet):
    """
    API endpoint for AICERTs course enrollments.

    Features:
    - List user's enrollments
    - Create new enrollment (with auto-sync to AICERTs)
    - Check enrollment status
    - Retry failed enrollments
    """

    serializer_class = AICertsEnrollmentSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """Users can only see their own enrollments"""
        if self.request.user.is_staff:
            return AICertsEnrollment.objects.all()
        return AICertsEnrollment.objects.filter(user=self.request.user)

    def list(self, request, *args, **kwargs):
        """
        Return enrollment list and trigger background sync for any unsynced
        enrollments — this fires automatically when the Student Portal loads.
        """
        response = super().list(request, *args, **kwargs)

        # Fire-and-forget: sync any locally-enrolled courses that haven't been
        # pushed to AICerts yet (e.g. created via payment webhook or admin).
        user = request.user
        if (
            not user.is_staff
            and getattr(user, 'aicerts_user_id', None)
            and AICertsEnrollment.objects.filter(
                user=user,
                aicerts_enrollment_status='enrolled',
                synced_at__isnull=True,
            ).exists()
        ):
            from .tasks import sync_user_enrollments_task
            sync_user_enrollments_task.delay(user.id)

        return response

    @action(detail=False, methods=['post'], url_path='enroll')
    def enroll_user(self, request):
        """
        Enroll authenticated user in an AICERTs course.

        Request body:
        {
            "course_id": 123
        }

        Response:
        {
            "success": true,
            "enrollment_id": 456,
            "message": "Successfully enrolled in course",
            "sso_url": "https://learn.aicerts.io/..."
        }
        """
        serializer = EnrollUserSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        course_id = serializer.validated_data['course_id']
        course = get_object_or_404(AiCertsCourse, id=course_id)

        try:
            # Use enrollment sync service for dual enrollment
            enrollment, aicerts_result = EnrollmentSyncService.enroll_user_in_course(
                user=request.user,
                course=course,
                create_aicerts_user=settings.AICERTS_AUTO_CREATE_USERS
            )

            # Generate SSO URL for immediate course access (use Moodle lms_course_id, not Django PK)
            sso_url = SSOService.generate_sso_url(
                email=request.user.email,
                course_id=course.lms_course_id
            )

            # Log successful enrollment
            AICertsSyncLog.objects.create(
                operation_type='user_enroll',
                status='success',
                user=request.user,
                course=course,
                response_data=aicerts_result
            )

            return Response({
                'success': True,
                'enrollment_id': enrollment.id,
                'message': 'Successfully enrolled in course',
                'sso_url': sso_url,
                'already_enrolled': enrollment.aicerts_already_enrolled
            }, status=status.HTTP_201_CREATED)

        except AICERTsEnrollmentError as e:
            logger.error(f"Enrollment failed for user {request.user.email} in course {course_id}: {e}")

            # Log failed enrollment
            AICertsSyncLog.objects.create(
                operation_type='user_enroll',
                status='failed',
                user=request.user,
                course=course,
                error_message=str(e)
            )

            return Response({
                'success': False,
                'error': 'Enrollment failed',
                'details': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=True, methods=['post'], url_path='retry-sync')
    def retry_sync(self, request, pk=None):
        """
        Retry failed enrollment sync with AICERTs.

        Only works for enrollments with status='failed' and < 3 attempts.
        """
        enrollment = self.get_object()

        if enrollment.aicerts_enrollment_status != 'failed':
            return Response({
                'success': False,
                'error': 'Can only retry failed enrollments'
            }, status=status.HTTP_400_BAD_REQUEST)

        if enrollment.sync_attempts >= 3:
            return Response({
                'success': False,
                'error': 'Maximum retry attempts exceeded'
            }, status=status.HTTP_400_BAD_REQUEST)

        try:
            # Retry enrollment (use lms_course_id, not Django PK)
            aicerts_result = SSOService.enroll_user(
                aicerts_user_id=enrollment.user.aicerts_user_id,
                course_id=enrollment.course.lms_course_id,
                email=enrollment.user.email
            )

            enrollment.mark_synced()

            return Response({
                'success': True,
                'message': 'Enrollment synced successfully'
            })

        except AICERTsEnrollmentError as e:
            enrollment.mark_failed(str(e))

            return Response({
                'success': False,
                'error': 'Retry failed',
                'details': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    @action(detail=True, methods=['get'], url_path='sso-url')
    def get_sso_url(self, request, pk=None):
        """
        Generate SSO URL for this specific enrollment.
        Ensures the enrollment is pushed to AICerts before generating the URL
        so the student always has access once they land on learn.aicerts.io.
        """
        enrollment = self.get_object()

        if enrollment.aicerts_enrollment_status != 'enrolled':
            return Response({
                'success': False,
                'error': 'User not enrolled in this course'
            }, status=status.HTTP_403_FORBIDDEN)

        # Lazy-sync: if the enrollment exists locally but was never pushed to
        # AICerts, do it now (synchronous so the SSO URL is immediately usable).
        if enrollment.synced_at is None:
            aicerts_user_id = getattr(enrollment.user, 'aicerts_user_id', None)
            if aicerts_user_id:
                try:
                    result = SSOService.enroll_user(
                        aicerts_user_id=aicerts_user_id,
                        course_id=enrollment.course.lms_course_id,
                        email=enrollment.user.email,
                    )
                    enrollment.mark_synced()
                    AICertsSyncLog.objects.create(
                        operation_type='user_enroll',
                        status='success',
                        user=enrollment.user,
                        course=enrollment.course,
                        response_data=result,
                    )
                    logger.info(
                        f"Lazy-synced enrollment {enrollment.id} on SSO request: "
                        f"{enrollment.user.email} → {enrollment.course.title}"
                    )
                except Exception as sync_err:
                    # Log but do NOT block SSO — the student may already be enrolled
                    # on the AICerts side even if we have no local sync record.
                    logger.warning(
                        f"Lazy-sync failed for enrollment {enrollment.id}: {sync_err}. "
                        f"Proceeding with SSO generation."
                    )

        try:
            sso_url = SSOService.generate_sso_url(
                email=enrollment.user.email,
                course_id=enrollment.course.lms_course_id
            )
            return Response({
                'success': True,
                'sso_url': sso_url
            })
        except Exception as e:
            return Response({
                'success': False,
                'error': 'Failed to generate SSO URL',
                'details': str(e)
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class SSORedirectView(APIView):
    """
    Generate SSO URL and redirect user to AICERTs LMS for course access.

    GET /api/aicerts/sso/redirect/?course_id=123

    Redirects to AICERTs LMS with authenticated session.
    """

    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        """Generate SSO URL and redirect"""
        serializer = GenerateSSOSerializer(data=request.query_params)
        serializer.is_valid(raise_exception=True)

        course_id = serializer.validated_data.get('course_id')
        user_id = serializer.validated_data.get('user_id')
        
        # Staff can generate SSO for other users (for support/testing)
        if user_id and request.user.is_staff:
            target_user = get_object_or_404(User, id=user_id)
        else:
            target_user = request.user

        # Check if user is synced with AICERTs
        if not target_user.is_synced_with_aicerts():
            return JsonResponse({
                'success': False,
                'error': 'User account not synced with AICERTs',
                'message': f'User {target_user.email} not synced with AICERTs'
            }, status=400)

        # Check if user is enrolled (if course_id provided)
        if course_id:
            enrollment = AICertsEnrollment.objects.filter(
                user=target_user,
                course_id=course_id,
                aicerts_enrollment_status='enrolled'
            ).first()

            if not enrollment:
                return JsonResponse({
                    'success': False,
                    'error': 'Not enrolled in this course',
                    'message': 'Please enroll in the course first'
                }, status=403)

        try:
            # Generate SSO URL (resolve lms_course_id from Django PK for Moodle)
            course = None
            moodle_course_id = None
            if course_id:
                course = AiCertsCourse.objects.filter(id=course_id).first()
                moodle_course_id = course.lms_course_id if course else None
            sso_url = SSOService.generate_sso_url(
                email=target_user.email,
                course_id=moodle_course_id
            )

            # Create SSO session record

            sso_session = AICertsSSOSession.objects.create(
                user=target_user,
                course=course,
                sso_url=sso_url[:500],  # Truncate for DB storage
                session_token=secrets.token_urlsafe(32),
                ip_address=request.META.get('REMOTE_ADDR'),
                user_agent=request.META.get('HTTP_USER_AGENT', '')[:500],
                expires_at=timezone.now() + timedelta(hours=1)
            )

            # Log SSO generation
            AICertsSyncLog.objects.create(
                operation_type='user_auth',
                status='success',
                user=target_user,
                course=course,
                response_data={'session_token': sso_session.session_token, 'impersonated_by': request.user.id if user_id else None}
            )

            # Redirect to AICERTs
            return redirect(sso_url)

        except Exception as e:
            logger.error(f"SSO generation failed for user {target_user.email}: {e}")

            AICertsSyncLog.objects.create(
                operation_type='user_auth',
                status='failed',
                user=target_user,
                error_message=str(e)
            )

            return JsonResponse({
                'success': False,
                'error': 'SSO generation failed',
                'details': str(e)
            }, status=500)


class InstructorValidationView(APIView):
    """
    Validate instructor eligibility for AICERTs courses.

    GET /api/aicerts/instructor/validate/?user_id=123&course_id=456

    Returns:
    {
        "is_aicerts_instructor": true,
        "can_instruct_course": true,
        "designated_courses": [...]
    }
    """

    permission_classes = [permissions.IsAdminUser]

    def get(self, request):
        """Check if user can instruct specific course"""
        user_id = request.query_params.get('user_id')
        course_id = request.query_params.get('course_id')

        if not user_id:
            return Response({
                'error': 'user_id required'
            }, status=status.HTTP_400_BAD_REQUEST)

        from apps.users.models import User
        user = get_object_or_404(User, id=user_id)

        response_data = {
            'user_id': user.id,
            'email': user.email,
            'is_aicerts_instructor': user.is_aicerts_instructor,
            'can_instruct_course': False,
            'designated_courses': []
        }

        if user.is_aicerts_instructor:
            # Get designated courses
            designated_courses = InstructorValidationService.get_instructor_courses(user)
            response_data['designated_courses'] = [
                {
                    'id': course.id,
                    'title': course.title,
                    'shortname': course.shortname
                }
                for course in designated_courses
            ]

            # Check specific course if provided
            if course_id:
                course = get_object_or_404(AiCertsCourse, id=course_id)
                response_data['can_instruct_course'] = InstructorValidationService.can_instruct_course(user, course)
                response_data['course'] = {
                    'id': course.id,
                    'title': course.title
                }

        return Response(response_data)


class AICertsInstructorDesignationViewSet(viewsets.ModelViewSet):
    """
    API endpoint for managing instructor designations.

    Only admins can create/update/delete designations.
    """

    serializer_class = AICertsInstructorDesignationSerializer
    permission_classes = [permissions.IsAdminUser]
    queryset = AICertsInstructorDesignation.objects.all()

    def perform_create(self, serializer):
        """Record who made the designation"""
        serializer.save(designated_by=self.request.user)


class AICertsSyncLogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint for viewing sync logs (read-only).

    Admins can see all logs, users can see their own.
    """

    serializer_class = AICertsSyncLogSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        """Filter logs based on user permissions"""
        if self.request.user.is_staff:
            return AICertsSyncLog.objects.all()
        return AICertsSyncLog.objects.filter(user=self.request.user)

    @action(detail=False, methods=['get'], url_path='stats')
    def get_stats(self, request):
        """
        Get sync statistics.

        Returns counts by operation type and status.
        """
        from django.db.models import Count

        stats = AICertsSyncLog.objects.values('operation_type', 'status').annotate(
            count=Count('id')
        ).order_by('operation_type', 'status')

        return Response({
            'stats': list(stats)
        })
