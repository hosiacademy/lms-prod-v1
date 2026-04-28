# apps/learnerships/signals.py
"""
Auto-send emails when enrollments are created
"""
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import LearnershipEnrollment


@receiver(post_save, sender=LearnershipEnrollment)
def send_enrollment_confirmation_email(sender, instance, created, **kwargs):
    """
    Automatically send enrollment confirmation email when new enrollment is created
    Detects cybersecurity learnerships and sends with cost breakdown
    """
    if not created:
        return  # Only send on creation

    try:
        from apps.users.services.email_service import EmailService
        
        programme = instance.programme
        programme_title_lower = programme.title.lower() if programme else ''
        
        # Check if it's a cybersecurity learnership
        is_cybersecurity = any(keyword in programme_title_lower for keyword in [
            'cybersecurity', 'soc', 'security engineer', 'security consultant',
            'red team', 'blue team', 'bug hunter', 'penetration', 'ethical hacker'
        ])
        
        if is_cybersecurity:
            # Send with cost breakdown (ZAR for South Africa)
            EmailService.send_cybersecurity_enrollment(instance, currency='ZAR')
        else:
            # Send generic enrollment email
            EmailService.send_enrollment_confirmation(instance)
            
    except Exception as e:
        import logging
        logger = logging.getLogger(__name__)
        logger.error(f'Failed to send enrollment confirmation email: {str(e)}')
