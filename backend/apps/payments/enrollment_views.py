# apps/payments/enrollment_views.py
"""
Views for handling enrollment forms before payment.
Implements mandatory enrollment information collection.
"""

from rest_framework import viewsets, views, status
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, AllowAny
from django.contrib.contenttypes.models import ContentType
from django.shortcuts import get_object_or_404
from django.db import transaction

from .models import (
    Enrollment, BulkEnrollment, EnrollmentType, EnrollmentStatus,
    Order, Currency
)
from .enrollment_serializers import (
    EnrollmentSerializer, BulkEnrollmentSerializer, EnrollmentListSerializer
)
from apps.organizations.models import Company
from django.conf import settings
import logging

logger = logging.getLogger(__name__)


logger = logging.getLogger(__name__)


class FinalizeEnrollmentView(views.APIView):
    """
    POST /api/enrollments/finalize/
    
    Finalize enrollment after successful payment.
    Use this endpoint to submit the full enrollment payload ONLY after payment is confirmed.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            reference = request.data.get('reference') # Order tracking ID
            metadata = request.data.get('metadata', {})
            
            if not reference:
                return Response({'error': 'Payment reference required'}, status=status.HTTP_400_BAD_REQUEST)

            # 1. Verify Order matches User and is Paid
            order = get_object_or_404(Order, tracking=reference, user=request.user)
            
            # Allow 'completed' or 'processing' (some providers take time but are guaranteed)
            if order.status not in ['completed', 'processing']:
                 return Response({
                     'error': f'Payment not confirmed. Current status: {order.status}'
                 }, status=status.HTTP_400_BAD_REQUEST)

            # 2. Check if enrollment already exists for this order
            if Enrollment.objects.filter(order=order).exists():
                enrollment = Enrollment.objects.get(order=order)
                return Response({
                    'message': 'Enrollment already finalized',
                    'enrollment_code': enrollment.enrollment_code
                }, status=status.HTTP_200_OK)

            # 3. Construct Data for EnrollmentSerializer
            # The metadata from frontend contains 'learners' list, etc.
            # We need to map this to the serializer's expected format.
            
            # Default to single learner format if bulk not specified
            # (Assuming single enrollment for now based on MultiStepEnrollmentModal)
            
            enrollment_data = {
                'enrollment_type': metadata.get('enrollment_type', 'masterclass'),
                'training_id': metadata.get('program_id') or order.metadata.get('program_id'),
                'payment_method': order.payment_method or 'online',
                'currency': order.currency,
                'is_corporate': metadata.get('is_corporate', False),
            }
            
            # Extract learner data
            learners = metadata.get('learners', [])
            if learners:
                main_learner = learners[0]
                enrollment_data.update({
                    'learner_full_name': main_learner.get('full_name'),
                    'learner_email': main_learner.get('email'),
                    'learner_phone': main_learner.get('phone'),
                    'learner_id_number': main_learner.get('id_number'),
                    # Add other fields as needed by your serializer
                    # Address, etc.
                })
            
            # Create Enrollment
            serializer = EnrollmentSerializer(data=enrollment_data, context={'request': request})
            if serializer.is_valid():
                with transaction.atomic():
                    enrollment = serializer.save(order=order) # Link the paid order
                    
                    # Force status to ENROLLED since paid
                    enrollment.status = EnrollmentStatus.ENROLLED
                    enrollment.save()
                    
                    # Send notifications
                    self._send_enrollment_notifications(enrollment, success=True)
                
                return Response({
                    'message': 'Enrollment finalized successfully',
                    'enrollment_code': enrollment.enrollment_code,
                    'sso_url': f"/api/enrollments/{enrollment.id}/get_sso_url/"
                }, status=status.HTTP_201_CREATED)
            else:
                return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        except Exception as e:
            logger.error(f"Finalize enrollment failed: {str(e)}", exc_info=True)
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    def _send_enrollment_notifications(self, enrollment, success=True, failure_reason=None):
        """Helper method to trigger enrollment notifications"""
        try:
            notification_enabled = getattr(settings, 'NOTIFICATION_CONFIG', {}).get('ENABLE_EMAIL', True)
            async_notifications = getattr(settings, 'NOTIFICATION_CONFIG', {}).get('ASYNC_NOTIFICATIONS', True)

            if not notification_enabled:
                return

            if async_notifications:
                # Send notifications asynchronously using Celery
                from apps.notifications.tasks import send_enrollment_notifications_task
                send_enrollment_notifications_task.delay(
                    enrollment_id=enrollment.id,
                    success=success,
                    failure_reason=failure_reason
                )
                logger.info(f"Queued async notifications for enrollment {enrollment.id}")
            else:
                # Send notifications synchronously
                from apps.notifications.services import NotificationService
                result = NotificationService.send_enrollment_notifications(
                    enrollment_id=enrollment.id,
                    success=success,
                    failure_reason=failure_reason
                )
                logger.info(f"Sent sync notifications for enrollment {enrollment.id}: {result}")

        except Exception as e:
            logger.error(f"Failed to send enrollment notifications: {str(e)}")
            # Don't fail the enrollment if notifications fail



class EnrollmentViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing enrollments.

    Endpoints:
    - POST /api/enrollments/ - Create new enrollment (requires auth)
    - GET /api/enrollments/ - List user's enrollments
    - GET /api/enrollments/{id}/ - Get enrollment details
    - PATCH /api/enrollments/{id}/ - Update enrollment info
    - POST /api/enrollments/{id}/proceed-to-payment/ - Proceed to payment
    """

    permission_classes = [IsAuthenticated]
    serializer_class = EnrollmentSerializer

    def get_queryset(self):
        """Get enrollments for current user"""
        user = self.request.user
        if user.is_authenticated and user.is_admin:
            # Admins can see all enrollments
            return Enrollment.objects.all()
        return Enrollment.objects.filter(user=user)

    def get_serializer_class(self):
        """Return appropriate serializer based on action"""
        if self.action == 'list':
            return EnrollmentListSerializer
        return EnrollmentSerializer

    def create(self, request, *args, **kwargs):
        """
        Create new enrollment.
        This is the mandatory step before payment.
        Sets student_id, instructor_id, and pathway-specific FK columns.
        """
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            
            # Save enrollment first
            enrollment = serializer.save()
            
            # Populate pathway linkage fields
            self._populate_enrollment_linkage(enrollment, request.data)
            
            # Send enrollment success notifications (email + SMS)
            self._send_enrollment_notifications(enrollment, success=True)

            # Return enrollment details with next steps
            response_serializer = self.get_serializer(enrollment)
            return Response({
                'message': 'Enrollment information saved successfully',
                'enrollment': response_serializer.data,
                'next_step': 'proceed_to_payment' if enrollment.final_amount > 0 else 'enrolled',
                'payment_url': f'/api/enrollments/{enrollment.id}/proceed-to-payment/' if enrollment.final_amount > 0 else None,
                'enrollment_code': enrollment.enrollment_code
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            logger.error(f"Enrollment creation failed: {str(e)}")

            # Attempt to send failure notification if we have user info
            try:
                user_email = request.data.get('learner_email')
                user_name = request.data.get('learner_full_name', 'Learner')
                program_name = "the selected program"  # We may not have this info

                if user_email:
                    self._send_failure_notification(
                        user_email=user_email,
                        user_name=user_name,
                        program_name=program_name,
                        failure_reason=str(e)
                    )
            except:
                pass  # Don't fail completely if notification fails

            # Re-raise the original exception
            raise

    def _populate_enrollment_linkage(self, enrollment, data):
        """
        Populate student_id, instructor_id, and pathway-specific FK columns.
        Links enrollment to the correct pathway table and instructor.
        """
        from django.contrib.contenttypes.models import ContentType
        from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment
        from apps.masterclasses.models import Masterclass
        from apps.aicerts_courses.models import AiCertsCourse
        
        training_id = data.get('training_id')
        enrollment_type = data.get('enrollment_type')
        
        if not training_id or not enrollment_type:
            return
        
        # Get the course/programme to find instructor
        course = None
        instructor_id = None
        
        try:
            if enrollment_type == 'learnership':
                course = LearnershipProgramme.objects.get(id=training_id)
                instructor_id = course.instructor_id
                # Link to learnership enrollment if exists
                learner_enroll = LearnershipEnrollment.objects.filter(
                    programme=course, user=enrollment.user
                ).first()
                if learner_enroll:
                    enrollment.learnership_enrollment_id = learner_enroll.id
                    enrollment.student_id = learner_enroll.student_id
                    
            elif enrollment_type == 'masterclass':
                course = Masterclass.objects.get(id=training_id)
                instructor_id = course.instructor_id
                
            elif enrollment_type in ('industry_training', 'role_training'):
                course = AiCertsCourse.objects.get(id=training_id)
                instructor_id = course.instructor_id
            
            # Set instructor_id if found
            if instructor_id:
                enrollment.instructor_id = instructor_id
                enrollment.save(update_fields=[
                    'instructor_id', 'student_id',
                    'learnership_enrollment_id', 'masterclass_enrollment_id',
                    'aicerts_enrollment_id', 'industry_enrollment_id'
                ])
                
        except Exception as e:
            logger.warning(f"Failed to populate enrollment linkage: {e}")

    def _send_enrollment_notifications(self, enrollment, success=True, failure_reason=None):
        """Helper method to trigger enrollment notifications"""
        try:
            notification_enabled = getattr(settings, 'NOTIFICATION_CONFIG', {}).get('ENABLE_EMAIL', True)
            async_notifications = getattr(settings, 'NOTIFICATION_CONFIG', {}).get('ASYNC_NOTIFICATIONS', True)

            if not notification_enabled:
                return

            if async_notifications:
                # Send notifications asynchronously using Celery
                from apps.notifications.tasks import send_enrollment_notifications_task
                send_enrollment_notifications_task.delay(
                    enrollment_id=enrollment.id,
                    success=success,
                    failure_reason=failure_reason
                )
                logger.info(f"Queued async notifications for enrollment {enrollment.id}")
            else:
                # Send notifications synchronously
                from apps.notifications.services import NotificationService
                result = NotificationService.send_enrollment_notifications(
                    enrollment_id=enrollment.id,
                    success=success,
                    failure_reason=failure_reason
                )
                logger.info(f"Sent sync notifications for enrollment {enrollment.id}: {result}")

        except Exception as e:
            logger.error(f"Failed to send enrollment notifications: {str(e)}")
            # Don't fail the enrollment if notifications fail

    def _send_failure_notification(self, user_email, user_name, program_name, failure_reason):
        """Send failure notification via email"""
        try:
            from apps.notifications.services import EmailService
            EmailService.send_enrollment_failure(
                user_email=user_email,
                user_name=user_name,
                program_name=program_name,
                program_type='enrollment',
                failure_reason=failure_reason
            )
        except Exception as e:
            logger.error(f"Failed to send failure notification: {str(e)}")

    @action(detail=True, methods=['post'])
    def proceed_to_payment(self, request, pk=None):
        """
        Proceed to payment after enrollment form is completed.
        Creates an order and returns payment details.
        """
        enrollment = self.get_object()

        # Validate enrollment is ready for payment
        if enrollment.status not in [EnrollmentStatus.PENDING_INFO, EnrollmentStatus.PENDING_PAYMENT]:
            return Response({
                'error': 'Enrollment is not in a valid state for payment'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Check if order already exists
        if enrollment.order:
            return Response({
                'message': 'Order already exists for this enrollment',
                'order_id': enrollment.order.tracking,
                'payment_url': f'/api/payments/checkout/{enrollment.order.tracking}/'
            })

        # Create order
        with transaction.atomic():
            import uuid
            order = Order.objects.create(
                user=enrollment.user,
                tracking=f"ORD-{uuid.uuid4().hex[:12].upper()}",
                amount=enrollment.final_amount,
                currency=enrollment.currency,
                status='pending',
                payment_method='',
                metadata={
                    'enrollment_id': enrollment.id,
                    'enrollment_code': enrollment.enrollment_code,
                    'enrollment_type': enrollment.enrollment_type,
                    'company_id': enrollment.company_id if enrollment.company else None,
                }
            )

            # Link order to enrollment
            enrollment.order = order
            enrollment.status = EnrollmentStatus.PENDING_PAYMENT
            enrollment.save()

        return Response({
            'message': 'Order created successfully',
            'order_id': order.tracking,
            'amount': float(order.amount),
            'currency': order.currency,
            'payment_url': f'/api/payments/checkout/{order.tracking}/',
            'enrollment_code': enrollment.enrollment_code
        }, status=status.HTTP_200_OK)

    @action(detail=False, methods=['get'])
    def my_enrollments(self, request):
        """Get current user's enrollments"""
        enrollments = self.get_queryset()
        serializer = EnrollmentListSerializer(enrollments, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def get_sso_url(self, request, pk=None):
        """
        Generate a secure SSO URL for the enrolled AICerts course.
        """
        from apps.aicerts_integration.services import SSOService, EnrollmentSyncService
        from apps.aicerts_courses.models import AiCertsCourse

        enrollment = self.get_object()
        user = request.user

        if enrollment.status != EnrollmentStatus.ENROLLED:
            return Response({
                'error': 'Course access is not active. Please complete payment or verification.'
            }, status=status.HTTP_403_FORBIDDEN)

        # Ensure user has an AICerts account, creating one on-demand if needed
        if not user.aicerts_user_id:
            try:
                result = SSOService.create_user(
                    email=user.email,
                    first_name=user.first_name or user.username,
                    last_name=user.last_name or '',
                    username=user.email
                )
                user.aicerts_user_id = result.get('id')
                user.save(update_fields=['aicerts_user_id'])
            except Exception as e:
                logger.error(f"Failed to sync user with AICerts for SSO: {e}")
                return Response({'error': 'Failed to synchronize with learning platform.'}, status=500)

        # Resolve the AiCertsCourse and get its Moodle lms_course_id for the SSO link.
        # SSO must use lms_course_id (Moodle ID), NOT external_id (WordPress product ID).
        item = enrollment.get_enrolled_item()
        lms_course_id = None

        if enrollment.enrollment_type == EnrollmentType.MASTERCLASS:
            provider_course = item.provider_courses.first()
            if provider_course:
                lms_course_id = provider_course.lms_course_id

        elif enrollment.enrollment_type == EnrollmentType.CUSTOM_SELECTION:
            # item IS an AiCertsCourse for custom_selection enrollments
            if isinstance(item, AiCertsCourse):
                lms_course_id = item.lms_course_id
            elif hasattr(item, 'lms_course_id'):
                lms_course_id = item.lms_course_id

        elif enrollment.enrollment_type == EnrollmentType.INDUSTRY_TRAINING:
            # item is an AiCertsCourse; use its lms_course_id
            if hasattr(item, 'lms_course_id'):
                lms_course_id = item.lms_course_id

        elif enrollment.enrollment_type == EnrollmentType.ROLE_TRAINING:
            course = getattr(item, 'course', None) or item
            if hasattr(course, 'lms_course_id'):
                lms_course_id = course.lms_course_id

        elif enrollment.enrollment_type == EnrollmentType.LEARNERSHIP:
            phase = item.phases.first()
            if phase:
                course = phase.courses.first()
                if course and hasattr(course, 'lms_course_id'):
                    lms_course_id = course.lms_course_id

        if not lms_course_id:
            return Response({'error': 'No specific learning material found for this enrollment.'}, status=404)

        try:
            sso_url = SSOService.generate_sso_url(user.email, lms_course_id)
            return Response({'sso_url': sso_url})
        except Exception as e:
            logger.error(f"SSO URL generation failed: {e}")
            return Response({'error': 'Failed to generate access link.'}, status=500)


class BulkEnrollmentViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing bulk company enrollments.

    Endpoints:
    - POST /api/bulk-enrollments/ - Create bulk enrollment
    - GET /api/bulk-enrollments/ - List company's bulk enrollments
    - GET /api/bulk-enrollments/{id}/ - Get bulk enrollment details
    - POST /api/bulk-enrollments/{id}/proceed-to-payment/ - Proceed to payment for all learners
    """

    permission_classes = [IsAuthenticated]
    serializer_class = BulkEnrollmentSerializer

    def get_queryset(self):
        """Get bulk enrollments for user's companies"""
        user = self.request.user
        if user.is_authenticated and user.is_admin:
            return BulkEnrollment.objects.all()

        # Get companies where user is a member or created bulk enrollments
        from apps.organizations.models import CompanyLearner
        company_ids = CompanyLearner.objects.filter(user=user, is_active=True).values_list('company_id', flat=True)

        return BulkEnrollment.objects.filter(
            models.Q(company_id__in=company_ids) | models.Q(created_by=user)
        )

    def create(self, request, *args, **kwargs):
        """Create bulk enrollment for company"""
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            bulk_enrollment = serializer.save()

            # Send notifications to all enrolled learners
            self._send_bulk_enrollment_notifications(bulk_enrollment)

            return Response({
                'message': f'Bulk enrollment created successfully for {bulk_enrollment.total_learners} learners',
                'bulk_enrollment': BulkEnrollmentSerializer(bulk_enrollment).data,
                'next_step': 'proceed_to_payment' if bulk_enrollment.total_amount > 0 else 'enrolled',
                'payment_url': f'/api/bulk-enrollments/{bulk_enrollment.id}/proceed-to-payment/' if bulk_enrollment.total_amount > 0 else None,
                'bulk_code': bulk_enrollment.bulk_code
            }, status=status.HTTP_201_CREATED)

        except Exception as e:
            logger.error(f"Bulk enrollment creation failed: {str(e)}")
            raise

    def _send_bulk_enrollment_notifications(self, bulk_enrollment):
        """Helper method to send notifications for all learners in bulk enrollment"""
        try:
            notification_enabled = getattr(settings, 'NOTIFICATION_CONFIG', {}).get('ENABLE_EMAIL', True)
            async_notifications = getattr(settings, 'NOTIFICATION_CONFIG', {}).get('ASYNC_NOTIFICATIONS', True)

            if not notification_enabled:
                return

            if async_notifications:
                # Send bulk notifications asynchronously
                from apps.notifications.tasks import send_bulk_enrollment_notifications_task
                send_bulk_enrollment_notifications_task.delay(
                    bulk_enrollment_id=bulk_enrollment.id,
                    success=True
                )
                logger.info(f"Queued async notifications for bulk enrollment {bulk_enrollment.id}")
            else:
                # Send notifications synchronously to all learners
                from apps.notifications.services import NotificationService
                individual_enrollments = Enrollment.objects.filter(bulk_enrollment=bulk_enrollment)

                for enrollment in individual_enrollments:
                    try:
                        NotificationService.send_enrollment_notifications(
                            enrollment_id=enrollment.id,
                            success=True
                        )
                    except Exception as e:
                        logger.error(f"Failed to send notification for enrollment {enrollment.id}: {str(e)}")

                logger.info(f"Sent sync notifications for bulk enrollment {bulk_enrollment.id}")

        except Exception as e:
            logger.error(f"Failed to send bulk enrollment notifications: {str(e)}")
            # Don't fail the enrollment if notifications fail

    @action(detail=True, methods=['post'])
    def proceed_to_payment(self, request, pk=None):
        """Proceed to payment for bulk enrollment"""
        bulk_enrollment = self.get_object()

        # Check if order already exists
        if bulk_enrollment.order:
            return Response({
                'message': 'Order already exists for this bulk enrollment',
                'order_id': bulk_enrollment.order.tracking,
                'payment_url': f'/api/payments/checkout/{bulk_enrollment.order.tracking}/'
            })

        # Create order
        with transaction.atomic():
            import uuid
            order = Order.objects.create(
                user=request.user,
                tracking=f"ORD-{uuid.uuid4().hex[:12].upper()}",
                amount=bulk_enrollment.total_amount,
                currency=bulk_enrollment.currency,
                status='pending',
                payment_method='',
                metadata={
                    'bulk_enrollment_id': bulk_enrollment.id,
                    'bulk_code': bulk_enrollment.bulk_code,
                    'enrollment_type': bulk_enrollment.enrollment_type,
                    'company_id': bulk_enrollment.company_id,
                    'total_learners': bulk_enrollment.total_learners,
                }
            )

            # Link order to bulk enrollment
            bulk_enrollment.order = order
            bulk_enrollment.status = 'pending_payment'
            bulk_enrollment.save()

        return Response({
            'message': 'Order created for bulk enrollment',
            'order_id': order.tracking,
            'amount': float(order.amount),
            'currency': order.currency,
            'total_learners': bulk_enrollment.total_learners,
            'payment_url': f'/api/payments/checkout/{order.tracking}/',
            'bulk_code': bulk_enrollment.bulk_code
        }, status=status.HTTP_200_OK)

    @action(detail=True, methods=['get'])
    def learners(self, request, pk=None):
        """Get list of learners in this bulk enrollment"""
        bulk_enrollment = self.get_object()
        enrollments = bulk_enrollment.enrollments_list
        serializer = EnrollmentListSerializer(enrollments, many=True)
        return Response(serializer.data)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_enrollment_form_config(request, enrollment_type, item_id):
    """
    Get configuration for enrollment form including required fields and pricing.

    Args:
        enrollment_type: Type of enrollment (masterclass, learnership, etc.)
        item_id: ID of the specific item (masterclass ID, learnership ID, etc.)

    Returns:
        Form configuration with required fields, pricing, and item details
    """

    # Map enrollment types to models
    model_map = {
        'masterclass': ('masterclasses', 'Masterclass'),
        'learnership': ('learnerships', 'LearnershipProgramme'),
        'industry_training': ('industry_based_training', 'AiCertsCourse'),
        'role_training': ('industry_based_training', 'Offering'),
    }

    if enrollment_type not in model_map:
        return Response({
            'error': 'Invalid enrollment type'
        }, status=status.HTTP_400_BAD_REQUEST)

    app_label, model_name = model_map[enrollment_type]

    try:
        content_type = ContentType.objects.get(app_label=app_label, model=model_name.lower())
        model_class = content_type.model_class()
        item = model_class.objects.get(pk=item_id)
    except (ContentType.DoesNotExist, model_class.DoesNotExist):
        return Response({
            'error': 'Training not found'
        }, status=status.HTTP_404_NOT_FOUND)

    # Extract pricing
    if hasattr(item, 'price'):
        price = float(item.price)
        currency = getattr(item, 'currency', 'USD')
    elif hasattr(item, 'cost_usd'):
        price = float(item.cost_usd)
        currency = 'USD'
    elif hasattr(item, 'our_price_usd'):
        price = float(item.our_price_usd)
        currency = 'USD'
    else:
        price = 0.00
        currency = 'USD'

    # Extract item details
    item_details = {
        'id': item.id,
        'title': getattr(item, 'title', getattr(item, 'name', str(item))),
        'description': getattr(item, 'description', ''),
        'price': price,
        'currency': currency,
    }

    # Add specific fields based on type
    if enrollment_type == 'masterclass':
        item_details.update({
            'start_date': str(item.start_date) if hasattr(item, 'start_date') else None,
            'end_date': str(item.end_date) if hasattr(item, 'end_date') else None,
            'location': item.location_display if hasattr(item, 'location_display') else None,
            'seats_remaining': item.seats_remaining if hasattr(item, 'seats_remaining') else None,
        })
    elif enrollment_type == 'learnership':
        item_details.update({
            'duration_months': item.duration_months if hasattr(item, 'duration_months') else None,
            'role': item.get_role_display() if hasattr(item, 'get_role_display') else None,
        })

    # Required fields configuration - COMPLETE USER INFORMATION
    # All fields required for User model validation
    required_fields = [
        # === SECTION 1: PERSONAL INFORMATION (REQUIRED) ===
        {
            'name': 'learner_full_name',
            'type': 'text',
            'label': 'Full Name',
            'required': True,
            'placeholder': 'e.g., John Smith',
            'validation': {'minLength': 2, 'maxLength': 191},
            'section': 'personal',
            'help_text': 'Your full legal name as it appears on official documents'
        },
        {
            'name': 'learner_email',
            'type': 'email',
            'label': 'Email Address',
            'required': True,
            'placeholder': 'e.g., john.smith@example.com',
            'validation': {'email': True},
            'section': 'personal',
            'help_text': 'This will be your login username'
        },
        {
            'name': 'learner_phone',
            'type': 'tel',
            'label': 'Phone Number',
            'required': True,
            'placeholder': 'e.g., +27 12 345 6789',
            'validation': {'minLength': 10, 'maxLength': 20},
            'section': 'personal',
            'help_text': 'Include country code for international numbers'
        },
        {
            'name': 'learner_id_number',
            'type': 'text',
            'label': 'ID/Passport Number',
            'required': True,
            'placeholder': 'e.g., 8501015800086',
            'validation': {'minLength': 5, 'maxLength': 50},
            'section': 'personal',
            'help_text': 'National ID or Passport number for verification'
        },
        {
            'name': 'learner_dob',
            'type': 'date',
            'label': 'Date of Birth',
            'required': True,
            'placeholder': 'YYYY-MM-DD',
            'validation': {'date': True, 'minAge': 16},
            'section': 'personal',
            'help_text': 'You must be at least 16 years old to enroll'
        },
        {
            'name': 'learner_gender',
            'type': 'select',
            'label': 'Gender',
            'required': True,
            'options': [
                {'value': 'male', 'label': 'Male'},
                {'value': 'female', 'label': 'Female'},
                {'value': 'other', 'label': 'Other'},
                {'value': 'prefer_not_to_say', 'label': 'Prefer not to say'}
            ],
            'section': 'personal'
        },

        # === SECTION 2: ADDRESS INFORMATION (REQUIRED) ===
        {
            'name': 'learner_address',
            'type': 'textarea',
            'label': 'Physical Address',
            'required': True,
            'placeholder': 'e.g., 123 Main Street, Apartment 4B',
            'validation': {'minLength': 10, 'maxLength': 500},
            'section': 'address',
            'help_text': 'Your complete street address'
        },
        {
            'name': 'learner_city',
            'type': 'text',
            'label': 'City',
            'required': True,
            'placeholder': 'e.g., Johannesburg',
            'validation': {'minLength': 2, 'maxLength': 100},
            'section': 'address'
        },
        {
            'name': 'learner_country',
            'type': 'select',
            'label': 'Country',
            'required': True,
            'section': 'address',
            'help_text': 'Select your country of residence'
        },
        {
            'name': 'learner_postal_code',
            'type': 'text',
            'label': 'Postal/ZIP Code',
            'required': True,
            'placeholder': 'e.g., 2000',
            'validation': {'minLength': 3, 'maxLength': 20},
            'section': 'address'
        },

        # === SECTION 3: PROFESSIONAL/EDUCATIONAL BACKGROUND (REQUIRED) ===
        {
            'name': 'current_occupation',
            'type': 'text',
            'label': 'Current Occupation',
            'required': True,
            'placeholder': 'e.g., Software Developer, Student, Manager',
            'validation': {'minLength': 2, 'maxLength': 255},
            'section': 'professional',
            'help_text': 'Your current job title or occupation'
        },
        {
            'name': 'education_level',
            'type': 'select',
            'label': 'Highest Education Level',
            'required': True,
            'options': [
                {'value': 'high_school', 'label': 'High School / Matric'},
                {'value': 'diploma', 'label': 'Diploma / Certificate'},
                {'value': 'bachelors', 'label': "Bachelor's Degree"},
                {'value': 'honours', 'label': 'Honours Degree'},
                {'value': 'masters', 'label': "Master's Degree"},
                {'value': 'doctorate', 'label': 'Doctorate / PhD'},
                {'value': 'other', 'label': 'Other'}
            ],
            'section': 'professional',
            'help_text': 'Your highest completed level of education'
        },
        {
            'name': 'institution',
            'type': 'text',
            'label': 'Current Institution/Company',
            'required': True,
            'placeholder': 'e.g., University of Cape Town, Acme Corporation',
            'validation': {'minLength': 2, 'maxLength': 255},
            'section': 'professional',
            'help_text': 'Name of your current employer or educational institution'
        },

        # === SECTION 4: EMERGENCY CONTACT (REQUIRED) ===
        {
            'name': 'emergency_contact_name',
            'type': 'text',
            'label': 'Emergency Contact Full Name',
            'required': True,
            'placeholder': 'e.g., Jane Smith',
            'validation': {'minLength': 2, 'maxLength': 255},
            'section': 'emergency',
            'help_text': 'Person to contact in case of emergency'
        },
        {
            'name': 'emergency_contact_phone',
            'type': 'tel',
            'label': 'Emergency Contact Phone',
            'required': True,
            'placeholder': 'e.g., +27 12 345 6789',
            'validation': {'minLength': 10, 'maxLength': 20},
            'section': 'emergency'
        },
        {
            'name': 'emergency_contact_relationship',
            'type': 'select',
            'label': 'Relationship to Emergency Contact',
            'required': True,
            'options': [
                {'value': 'spouse', 'label': 'Spouse/Partner'},
                {'value': 'parent', 'label': 'Parent'},
                {'value': 'sibling', 'label': 'Sibling'},
                {'value': 'child', 'label': 'Child'},
                {'value': 'friend', 'label': 'Friend'},
                {'value': 'colleague', 'label': 'Colleague'},
                {'value': 'other', 'label': 'Other'}
            ],
            'section': 'emergency'
        },

        # === SECTION 5: ADDITIONAL INFORMATION (OPTIONAL FOR MASTERCLASSES) ===
        {
            'name': 'dietary_requirements',
            'type': 'textarea',
            'label': 'Dietary Requirements',
            'required': False,
            'placeholder': 'e.g., Vegetarian, Halal, Food allergies',
            'validation': {'maxLength': 500},
            'section': 'additional',
            'help_text': 'Required for in-person masterclasses with catering'
        },
        {
            'name': 'accessibility_needs',
            'type': 'textarea',
            'label': 'Accessibility/Special Needs',
            'required': False,
            'placeholder': 'e.g., Wheelchair access, Sign language interpreter',
            'validation': {'maxLength': 500},
            'section': 'additional',
            'help_text': 'Let us know how we can accommodate you'
        },
        {
            'name': 'additional_notes',
            'type': 'textarea',
            'label': 'Additional Notes',
            'required': False,
            'placeholder': 'Any other information you would like to share',
            'validation': {'maxLength': 1000},
            'section': 'additional'
        },

        # === SECTION 6: TERMS AND CONDITIONS (REQUIRED) ===
        {
            'name': 'terms_accepted',
            'type': 'checkbox',
            'label': 'I accept the terms and conditions, privacy policy, and agree to receive course-related communications',
            'required': True,
            'section': 'terms',
            'validation': {'mustBeTrue': True}
        },
    ]

    return Response({
        'enrollment_type': enrollment_type,
        'item': item_details,
        'required_fields': required_fields,
        'supports_bulk': True,  # All types support bulk enrollments
        'supports_company': True,
    })


@api_view(['POST'])
@permission_classes([AllowAny])
def quick_enroll(request, enrollment_type, item_id):
    """
    Quick enrollment endpoint - combines form submission and payment creation.
    Used when user wants to enroll and pay in one step.
    """

    # Create enrollment
    serializer = EnrollmentSerializer(data={
        **request.data,
        'enrollment_type': enrollment_type,
        'training_id': item_id
    }, context={'request': request})

    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    enrollment = serializer.save()

    # Immediately create order
    import uuid
    order = Order.objects.create(
        user=enrollment.user,
        tracking=f"ORD-{uuid.uuid4().hex[:12].upper()}",
        amount=enrollment.final_amount,
        currency=enrollment.currency,
        status='pending',
        payment_method='',
        metadata={
            'enrollment_id': enrollment.id,
            'enrollment_code': enrollment.enrollment_code,
            'enrollment_type': enrollment.enrollment_type,
        }
    )

    enrollment.order = order
    enrollment.status = EnrollmentStatus.PENDING_PAYMENT
    enrollment.save()

    return Response({
        'message': 'Enrollment created successfully',
        'enrollment_code': enrollment.enrollment_code,
        'order_id': order.tracking,
        'redirect_to_payment': True,
        'payment_url': f'/api/payments/checkout/{order.tracking}/'
    }, status=status.HTTP_201_CREATED)
