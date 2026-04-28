# apps/instructors/views_instructor_application.py

from rest_framework import viewsets, status, permissions, decorators
from rest_framework.response import Response
from rest_framework.parsers import MultiPartParser, FormParser
from django.shortcuts import get_object_or_404
from django.utils import timezone
from django.db.models import Count, Avg, Q, Sum
from django.conf import settings
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.html import strip_tags
import logging

from .models_instructor_application import (
    InstructorApplication,
    InstructorStatusLog
)
from .models import InstructorAnalytics
from .serializers_instructor_application import (
    InstructorApplicationSerializer,
    InstructorApplicationCreateSerializer,
    InstructorApplicationReviewSerializer,
    InstructorStatusLogSerializer,
    InstructorAnalyticsSerializer,
    InstructorAnalyticsSummarySerializer
)
from apps.bbb_integration.services import BBBService
from apps.localization.models import Country
from apps.payments.models import AdminRole

logger = logging.getLogger(__name__)


class InstructorApplicationViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing instructor applications.
    """
    queryset = InstructorApplication.objects.all().select_related(
        'country', 'reviewed_by'
    )
    serializer_class = InstructorApplicationSerializer
    permission_classes = [permissions.AllowAny]  # Allow public submission
    parser_classes = [MultiPartParser, FormParser]
    
    def get_serializer_class(self):
        if self.action == 'create':
            return InstructorApplicationCreateSerializer
        return InstructorApplicationSerializer
    
    def get_queryset(self):
        user = self.request.user
        queryset = InstructorApplication.objects.all().select_related(
            'country', 'reviewed_by'
        )
        
        # Universal Admins and Superusers see everything
        if user.is_superuser or AdminRole.is_system_admin(user):
            pass
        elif hasattr(user, 'admin_role') and user.admin_role.role_type in ['hr_admin', 'executive_admin']:
            # Regional HR Admins see applications from their allowed countries
            allowed_countries = user.admin_role.get_allowed_countries()
            queryset = queryset.filter(country__in=allowed_countries)
        elif not user.is_staff:
            # Applicants can only see their own application
            queryset = queryset.filter(email=user.email)

        # Filter by status
        status_param = self.request.query_params.get('status', None)
        if status_param:
            queryset = queryset.filter(status=status_param)
        
        # Filter by country (explicit override)
        country_param = self.request.query_params.get('country', None)
        if country_param:
            queryset = queryset.filter(country_id=country_param)
        
        # Filter by interview status
        interview_status = self.request.query_params.get('interview_status', None)
        if interview_status:
            queryset = queryset.filter(interview_status=interview_status)
        
        # Filter by date range
        date_from = self.request.query_params.get('date_from', None)
        date_to = self.request.query_params.get('date_to', None)
        if date_from:
            queryset = queryset.filter(submitted_at__gte=date_from)
        if date_to:
            queryset = queryset.filter(submitted_at__lte=date_to)
        
        return queryset
    
    def create(self, request, *args, **kwargs):
        """Create a new instructor application."""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        
        headers = self.get_success_headers(serializer.data)
        return Response(
            serializer.data,
            status=status.HTTP_201_CREATED,
            headers=headers
        )
    
    @decorators.action(detail=True, methods=['post'])
    def review_application(self, request, pk=None):
        """
        HR Admin reviews an instructor application.
        Can update status, schedule interview, approve, or reject.
        """
        if not request.user.is_staff or not request.user.is_authenticated:
            return Response(
                {'error': 'Authentication required'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        application = self.get_object()
        serializer = InstructorApplicationReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        validated_data = serializer.validated_data
        
        # Update status
        old_status = application.status
        new_status = validated_data.get('status', old_status)
        application.status = new_status
        
        # Update country assignment
        if 'country' in validated_data:
            application.country_id = validated_data['country']
        
        # Update interview details
        if 'interview_datetime' in validated_data:
            application.interview_datetime = validated_data['interview_datetime']
            application.interview_status = 'scheduled'
            application.status = 'interview_scheduled'
            
            # Create BBB meeting for interview
            self._create_bbb_interview_meeting(application, request.user)
        
        if 'interview_notes' in validated_data:
            application.interview_notes = validated_data['interview_notes']
        
        # Handle approval
        if new_status == 'approved':
            application.approval_notes = validated_data.get('approval_notes', '')
            application.reviewed_by = request.user
            application.reviewed_at = timezone.now()
            
            # Create or update user account
            self._create_instructor_account(application)
            
            # Send success email
            self._send_approval_email(application)
        
        # Handle rejection
        if new_status == 'rejected':
            application.rejection_reason = validated_data.get('rejection_reason', '')
            application.reviewed_by = request.user
            application.reviewed_at = timezone.now()
            
            # Send rejection email
            self._send_rejection_email(application)
        
        application.save()
        
        # Log status change if needed
        if old_status != new_status:
            logger.info(
                f"Application {application.application_id} status changed "
                f"from {old_status} to {new_status} by {request.user.email}"
            )
        
        return Response(self.get_serializer(application).data)
    
    @decorators.action(detail=True, methods=['post'])
    def schedule_interview(self, request, pk=None):
        """
        HR Admin schedules an interview for an application.
        Creates BBB meeting link.
        """
        if not request.user.is_staff or not request.user.is_authenticated:
            return Response(
                {'error': 'Authentication required'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        application = self.get_object()
        interview_datetime = request.data.get('interview_datetime')
        
        if not interview_datetime:
            return Response(
                {'error': 'interview_datetime is required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        application.interview_datetime = interview_datetime
        application.interview_status = 'scheduled'
        application.status = 'interview_scheduled'
        
        # Create BBB meeting
        bbb_result = self._create_bbb_interview_meeting(application, request.user)
        
        application.save()
        
        # Send interview invitation email
        self._send_interview_invitation_email(application, bbb_result)
        
        return Response(self.get_serializer(application).data)
    
    @decorators.action(detail=False, methods=['get'])
    def hr_performance_insights(self, request):
        """
        Universal HR Admin view of performance across all regions.
        """
        if not AdminRole.is_system_admin(request.user) and not request.user.is_superuser:
            return Response(
                {'error': 'Access denied. Universal admin privileges required.'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        countries = Country.objects.all()
        performance_data = []
        
        for country in countries:
            apps = InstructorApplication.objects.filter(country=country)
            total = apps.count()
            if total == 0:
                continue
                
            performance_data.append({
                'country_id': country.id,
                'country_name': country.name,
                'total_applications': total,
                'pending': apps.filter(status='pending').count(),
                'interviewing': apps.filter(status='interview_scheduled').count(),
                'approved': apps.filter(status='approved').count(),
                'rejected': apps.filter(status='rejected').count(),
                'approval_rate': (apps.filter(status='approved').count() / total) * 100
            })
            
        return Response(performance_data)
    

    @decorators.action(detail=True, methods=['get'])
    def join_interview(self, request, pk=None):
        """Get join URL for scheduled interview."""
        if not request.user.is_staff or not request.user.is_authenticated:
            return Response(
                {'error': 'Authentication required'},
                status=status.HTTP_403_FORBIDDEN
            )

        application = self.get_object()
        
        if application.interview_status != 'scheduled' or not application.bbb_meeting_id:
            return Response(
                {'error': 'No active interview scheduled'},
                status=status.HTTP_400_BAD_REQUEST
            )
            
        try:
            from apps.bbb_integration.services import BBBService
            service = BBBService()
            user_name = request.user.get_full_name() or request.user.email
            
            # HR Admin joins as moderator
            params = {
                'fullName': user_name,
                'meetingID': application.bbb_meeting_id,
                'password': application.bbb_moderator_password,
                'redirect': 'true',
            }
            
            join_url = service._build_url('join', params)
            
            return Response({
                'join_url': join_url,
                'meeting_id': application.bbb_meeting_id
            })
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to generate interview join URL: {e}")
            return Response(
                {'error': 'Failed to generate join URL'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

    @decorators.action(detail=True, methods=['post'])
    def update_interview_status(self, request, pk=None):
        """Update interview status after completion."""
        if not request.user.is_staff or not request.user.is_authenticated:
            return Response(
                {'error': 'Authentication required'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        application = self.get_object()
        interview_status = request.data.get('interview_status')
        interview_notes = request.data.get('interview_notes', '')
        
        if interview_status not in ['completed', 'cancelled', 'rescheduled']:
            return Response(
                {'error': 'Invalid interview status'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        application.interview_status = interview_status
        application.interview_notes = interview_notes
        
        if interview_status == 'completed':
            application.status = 'interview_completed'
        
        application.save()
        
        return Response(self.get_serializer(application).data)
    
    def _create_bbb_interview_meeting(self, application, hr_admin):
        """Create BBB meeting for instructor interview."""
        try:
            bbb_service = BBBService()
            
            meeting_name = f"Instructor Interview - {application.applicant_name}"
            duration_minutes = 60  # 1 hour interview
            
            # Create meeting
            meeting_result = bbb_service.create_meeting(
                name=meeting_name,
                meeting_id=f"interview-{application.application_id}",
                duration=duration_minutes,
                moderator_name=hr_admin.name or hr_admin.email,
                moderator_password=None,  # Will be generated
                attendee_password=None,  # Will be generated
            )
            
            if meeting_result.get('success'):
                application.bbb_meeting_id = meeting_result.get('meeting_id')
                application.bbb_moderator_password = meeting_result.get('moderator_password')
                application.bbb_attendee_password = meeting_result.get('attendee_password')
                
                logger.info(
                    f"BBB meeting created for interview: {application.application_id}"
                )
            
            return meeting_result
            
        except Exception as e:
            logger.error(f"Failed to create BBB meeting: {e}")
            return {'success': False, 'error': str(e)}
    
    def _create_instructor_account(self, application):
        """Create user account for approved instructor."""
        try:
            # Check if user already exists
            if User.objects.filter(email=application.applicant_email).exists():
                user = User.objects.get(email=application.applicant_email)
                user.role_id = 2  # Instructor role
                user.save()
            else:
                # Create new user
                user = User.objects.create_user(
                    username=application.applicant_email,
                    email=application.applicant_email,
                    name=application.applicant_name,
                    role_id=2,  # Instructor role
                    headline=application.professional_headline,
                    phone=application.applicant_phone,
                    about=application.motivation_letter,
                    is_active=True
                )
            
            # Create facilitator profile
            from .models import FacilitatorProfile
            FacilitatorProfile.objects.get_or_create(
                user=user,
                defaults={
                    'facilitator_type': 'trainer',
                    'specialization': application.areas_of_expertise,
                    'qualifications': application.top_qualifications,
                    'years_experience': application.years_of_experience,
                    'is_active': True,
                    'is_available': True,
                }
            )
            
            logger.info(f"Instructor account created: {user.email}")
            return user
            
        except Exception as e:
            logger.error(f"Failed to create instructor account: {e}")
            return None
    
    def _send_approval_email(self, application):
        """Send approval email to new instructor."""
        try:
            subject = "Welcome to Hosi Academy - Instructor Application Approved!"
            
            context = {
                'applicant_name': application.applicant_name,
                'application_id': application.application_id,
                'approval_notes': application.approval_notes,
            }
            
            html_message = render_to_string(
                'emails/instructor_approval.html',
                context
            )
            
            plain_message = strip_tags(html_message)
            
            send_mail(
                subject,
                plain_message,
                settings.DEFAULT_FROM_EMAIL,
                [application.applicant_email],
                html_message=html_message,
                fail_silently=False,
            )
            
            logger.info(f"Approval email sent to: {application.applicant_email}")
            
        except Exception as e:
            logger.error(f"Failed to send approval email: {e}")
    
    def _send_rejection_email(self, application):
        """Send rejection email to applicant."""
        try:
            subject = "Instructor Application Update - Hosi Academy"
            
            context = {
                'applicant_name': application.applicant_name,
                'application_id': application.application_id,
                'rejection_reason': application.rejection_reason,
            }
            
            html_message = render_to_string(
                'emails/instructor_rejection.html',
                context
            )
            
            plain_message = strip_tags(html_message)
            
            send_mail(
                subject,
                plain_message,
                settings.DEFAULT_FROM_EMAIL,
                [application.applicant_email],
                html_message=html_message,
                fail_silently=False,
            )
            
            logger.info(f"Rejection email sent to: {application.applicant_email}")
            
        except Exception as e:
            logger.error(f"Failed to send rejection email: {e}")
    
    def _send_interview_invitation_email(self, application, bbb_result):
        """Send interview invitation email with BBB link."""
        try:
            subject = "Interview Invitation - Hosi Academy Instructor Position"
            
            context = {
                'applicant_name': application.applicant_name,
                'interview_datetime': application.interview_datetime,
                'bbb_join_url': bbb_result.get('attendee_join_url', ''),
                'moderator_join_url': bbb_result.get('moderator_join_url', ''),
                'application_id': application.application_id,
            }
            
            html_message = render_to_string(
                'emails/interview_invitation.html',
                context
            )
            
            plain_message = strip_tags(html_message)
            
            send_mail(
                subject,
                plain_message,
                settings.DEFAULT_FROM_EMAIL,
                [application.applicant_email],
                html_message=html_message,
                fail_silently=False,
            )
            
            logger.info(f"Interview invitation sent to: {application.applicant_email}")
            
        except Exception as e:
            logger.error(f"Failed to send interview invitation: {e}")


class InstructorStatusViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing instructor status changes.
    HR Admin can set instructors as active, inactive, or suspended.
    """
    queryset = InstructorStatusLog.objects.all().select_related(
        'instructor', 'changed_by'
    )
    serializer_class = InstructorStatusLogSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        queryset = super().get_queryset()
        
        # Filter by instructor
        instructor_id = self.request.query_params.get('instructor_id', None)
        if instructor_id:
            queryset = queryset.filter(instructor_id=instructor_id)
        
        # Filter by country (for HR Admin)
        if hasattr(self.request.user, 'country') and self.request.user.country:
            queryset = queryset.filter(
                instructor__country=self.request.user.country
            )
        
        return queryset
    
    def create(self, request, *args, **kwargs):
        """Change instructor status."""
        from .models import FacilitatorProfile
        
        instructor_id = request.data.get('instructor_id')
        new_status = request.data.get('new_status')
        reason = request.data.get('reason')
        
        if not instructor_id or not new_status:
            return Response(
                {'error': 'instructor_id and new_status are required'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if new_status in ['inactive', 'suspended'] and not reason:
            return Response(
                {'error': 'Reason is required for inactive/suspended status'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            instructor = User.objects.get(id=instructor_id)
            
            # Get previous status
            facilitator_profile = FacilitatorProfile.objects.filter(
                user=instructor
            ).first()
            
            previous_status = 'active'
            if facilitator_profile and not facilitator_profile.is_active:
                previous_status = 'inactive'
            
            # Update facilitator profile
            if facilitator_profile:
                if new_status == 'active':
                    facilitator_profile.is_active = True
                    facilitator_profile.is_available = True
                elif new_status in ['inactive', 'suspended']:
                    facilitator_profile.is_active = False
                    facilitator_profile.is_available = False
                
                facilitator_profile.save()
            
            # Create status log
            status_log = InstructorStatusLog.objects.create(
                instructor=instructor,
                previous_status=previous_status,
                new_status=new_status,
                reason=reason,
                changed_by=request.user
            )
            
            return Response(
                InstructorStatusLogSerializer(status_log).data,
                status=status.HTTP_201_CREATED
            )
            
        except User.DoesNotExist:
            return Response(
                {'error': 'Instructor not found'},
                status=status.HTTP_404_NOT_FOUND
            )
        except Exception as e:
            logger.error(f"Failed to update instructor status: {e}")
            return Response(
                {'error': str(e)},
                status=status.HTTP_400_BAD_REQUEST
            )


class InstructorAnalyticsViewSet(viewsets.ViewSet):
    """
    ViewSet for instructor analytics.
    """
    permission_classes = [permissions.IsAuthenticated]
    
    @decorators.action(detail=False, methods=['get'])
    def summary(self, request):
        """Get instructor analytics summary."""
        # Get country filter from HR Admin's country
        country_id = request.query_params.get('country', None)
        
        if not country_id and hasattr(request.user, 'country') and request.user.country:
            country_id = request.user.country.id
        
        if country_id:
            countries = Country.objects.filter(id=country_id)
        else:
            countries = Country.objects.all()
        
        summaries = []
        for country in countries:
            analytics = InstructorAnalytics.objects.filter(
                country=country
            ).order_by('-period_end')
            
            if analytics.exists():
                latest_analytics = analytics.first()
                summaries.append({
                    'country': country.id,
                    'country_name': country.name,
                    'total_instructors': analytics.count(),
                    'active_instructors': analytics.filter(status='active').count(),
                    'inactive_instructors': analytics.filter(status='inactive').count(),
                    'suspended_instructors': analytics.filter(status='suspended').count(),
                    'average_rating': latest_analytics.average_rating,
                    'total_courses': latest_analytics.total_courses_taught,
                    'total_students': latest_analytics.total_students_taught,
                    'total_earnings': latest_analytics.total_earnings,
                })
        
        return Response(summaries)
    
    @decorators.action(detail=False, methods=['get'])
    def detailed(self, request):
        """Get detailed instructor analytics."""
        country_id = request.query_params.get('country', None)
        
        if not country_id and hasattr(request.user, 'country') and request.user.country:
            country_id = request.user.country.id
        
        queryset = InstructorAnalytics.objects.all().select_related(
            'instructor', 'country'
        )
        
        if country_id:
            queryset = queryset.filter(country_id=country_id)
        
        serializer = InstructorAnalyticsSerializer(queryset, many=True)
        return Response(serializer.data)
