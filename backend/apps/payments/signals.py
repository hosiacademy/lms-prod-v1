# apps/payments/signals.py
"""
Signals for payment-triggered AICERTS enrollment automation.

Handles:
- Automatic AICERTS course enrollment when payment is confirmed
- AICERTS user creation if needed
- Linking Hosi Academy enrollments to AICERTS enrollments
"""

from django.db.models.signals import post_save
from django.dispatch import receiver
from django.conf import settings
import logging

from .models import Enrollment, EnrollmentStatus, EnrollmentType
from apps.users.models import User
from apps.aicerts_courses.models import AiCertsCourse
from apps.aicerts_integration.models import AICertsEnrollment
from apps.aicerts_integration.services import SSOService

logger = logging.getLogger(__name__)


@receiver(post_save, sender=Enrollment)
def trigger_aicerts_enrollment_on_payment(sender, instance, created, **kwargs):
    """
    Automatically create AICERTS enrollment when payment is confirmed.
    
    This signal fires when:
    1. Enrollment status changes to ENROLLED (payment confirmed)
    2. Enrollment type is CUSTOM_SELECTION or INDUSTRY_TRAINING (AICERTS pathways)
    3. No existing AICERTS enrollment exists for this user/course
    """
    # Skip if not AICERTS pathway
    if instance.enrollment_type not in [EnrollmentType.CUSTOM_SELECTION, EnrollmentType.INDUSTRY_TRAINING]:
        return
    
    # Skip if payment not confirmed
    if instance.status != EnrollmentStatus.ENROLLED:
        return
    
    # Skip if already has AICERTS enrollment link
    if instance.aicerts_enrollment_id:
        logger.debug(f"Enrollment {instance.enrollment_id} already linked to AICERTS")
        return

    try:
        # Get the AICERTS course
        course = instance.content_object
        if not isinstance(course, AiCertsCourse):
            logger.warning(f"Enrollment {instance.enrollment_id} content_object is not AiCertsCourse: {type(course)}")
            return

        # Get user
        user = instance.user

        # Ensure user has AICERTS account
        if not user.aicerts_user_id:
            logger.info(f"Creating AICERTS account for {user.email} for enrollment {instance.enrollment_id}")
            
            # Extract first and last name from full name
            full_name = instance.learner_full_name.strip()
            name_parts = full_name.split()
            first_name = name_parts[0] if name_parts else ""
            last_name = " ".join(name_parts[1:]) if len(name_parts) > 1 else (name_parts[0] if name_parts else "")
            
            result = SSOService.create_user(
                email=user.email,
                first_name=first_name,
                last_name=last_name,
                username=user.email
            )
            user.aicerts_user_id = result.get('id')
            user.save(update_fields=['aicerts_user_id'])
            logger.info(f"Created AICERTS user for {user.email} (ID: {user.aicerts_user_id})")
        
        # Create AICertsEnrollment record
        aicerts_enrollment, created_aicerts = AICertsEnrollment.objects.get_or_create(
            user=user,
            course=course,
            defaults={
                'aicerts_enrollment_status': 'pending',
                'enrolled_at': instance.enrolled_at or instance.created_at
            }
        )
        
        if created_aicerts:
            logger.info(f"Created AICertsEnrollment record {aicerts_enrollment.id}")
        else:
            logger.debug(f"AICertsEnrollment already exists: {aicerts_enrollment.id}")
        
        # Sync enrollment to AICERTS platform
        if aicerts_enrollment.aicerts_enrollment_status != 'enrolled':
            try:
                result = SSOService.enroll_user(
                    aicerts_user_id=user.aicerts_user_id,
                    course_id=course.lms_course_id,
                    email=user.email
                )
                
                if result.get('status') == 'success':
                    aicerts_enrollment.mark_synced()
                    logger.info(f"Successfully enrolled {user.email} in AICERTS course {course.title}")
                else:
                    error_msg = result.get('message', 'Unknown error')
                    aicerts_enrollment.mark_failed(error_msg)
                    logger.error(f"Failed to enroll {user.email} in AICERTS: {error_msg}")
                    
            except Exception as e:
                error_msg = str(e)
                aicerts_enrollment.mark_failed(error_msg)
                logger.error(f"Exception enrolling {user.email} in AICERTS: {error_msg}")
        
        # Link the enrollment to AICERTS enrollment
        instance.aicerts_enrollment_id = aicerts_enrollment.id
        instance.save(update_fields=['aicerts_enrollment_id'])
        logger.info(f"Linked Enrollment {instance.enrollment_id} to AICertsEnrollment {aicerts_enrollment.id}")

    except Exception as e:
        logger.error(f"Failed to trigger AICERTS enrollment for Enrollment {instance.enrollment_id}: {e}")
        # Don't fail the enrollment if AICERTS sync fails
        # Payment was successful, user still has Hosi Academy access