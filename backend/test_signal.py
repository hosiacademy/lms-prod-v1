import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from unittest.mock import patch, MagicMock
from apps.payments.models import EnrollmentStatus, EnrollmentType
from apps.payments.signals import trigger_aicerts_enrollment_on_payment
from apps.aicerts_courses.models import AiCertsCourse
from apps.aicerts_integration.services import SSOService

def test_signal_directly():
    print('Testing signal directly without DB...')
    
    # 1. Create mock instances
    mock_user = MagicMock()
    mock_user.aicerts_user_id = None
    mock_user.email = 'test@example.com'
    
    mock_course = MagicMock(spec=AiCertsCourse)
    mock_course.lms_course_id = 999
    mock_course.title = 'Test Course'
    
    mock_enrollment = MagicMock()
    mock_enrollment.enrollment_id = 'ENR-123'
    mock_enrollment.enrollment_type = EnrollmentType.INDUSTRY_TRAINING
    mock_enrollment.status = EnrollmentStatus.ENROLLED
    mock_enrollment.aicerts_enrollment_id = None
    mock_enrollment.content_object = mock_course
    mock_enrollment.user = mock_user
    mock_enrollment.learner_full_name = 'John Doe'
    mock_enrollment.enrolled_at = None
    mock_enrollment.created_at = None
    
    # 2. Mock SSOService and AICertsEnrollment.objects.get_or_create
    with patch.object(SSOService, 'create_user', return_value={'id': 12345, 'status': 'success'}) as mock_create_user, \
         patch.object(SSOService, 'enroll_user', return_value={'status': 'success'}) as mock_enroll_user, \
         patch('apps.payments.signals.AICertsEnrollment.objects.get_or_create') as mock_get_or_create:
         
         mock_aicerts_enrollment = MagicMock()
         mock_aicerts_enrollment.id = 777
         mock_aicerts_enrollment.aicerts_enrollment_status = 'pending'
         mock_get_or_create.return_value = (mock_aicerts_enrollment, True)
         
         # 3. Call signal
         trigger_aicerts_enrollment_on_payment(sender=None, instance=mock_enrollment, created=False)
         
         # 4. Verify results
         print('create_user called:', mock_create_user.called)
         print('enroll_user called:', mock_enroll_user.called)
         
         if mock_enroll_user.called:
             print('SUCCESS: AiCerts partner enrollment was triggered correctly by the backend!')
         else:
             print('FAILED: Signal did not trigger AiCerts partner enrollment.')

test_signal_directly()
