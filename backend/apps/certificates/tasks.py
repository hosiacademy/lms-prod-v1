from celery import shared_task
from .services import CertificateGenerator
from apps.payments.models import Enrollment

@shared_task
def generate_certificate_task(enrollment_id):
    """Async certificate generation"""
    try:
        enrollment = Enrollment.objects.get(id=enrollment_id)
        
        generator = CertificateGenerator()
        certificate = generator.generate(enrollment)
        
        # Send notification (stubbed for now to avoid errors if notification app is not ready)
        try:
            from apps.notifications.services import NotificationService
            NotificationService.send_certificate_email(
                user=enrollment.user,
                certificate=certificate,
            )
        except (ImportError, Exception):
            pass
        
        return {
            'certificate_id': str(certificate.certificate_id),
            'pdf_url': certificate.pdf_url,
        }
    except Enrollment.DoesNotExist:
        return {'error': 'Enrollment not found'}
    except Exception as e:
        return {'error': str(e)}
