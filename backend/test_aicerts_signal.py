import os
import django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from unittest.mock import patch
from apps.users.models import User
from apps.aicerts_courses.models import AiCertsCourse
from apps.payments.models import Enrollment, EnrollmentStatus, EnrollmentType
from apps.aicerts_integration.services import SSOService

def test_aicerts_trigger():
    print('Starting test...')
    # 1. Setup Data
    user, _ = User.objects.get_or_create(email='test_aicerts_trigger@example.com', defaults={'first_name': 'Test', 'last_name': 'User', 'username': 'test_aicerts_trigger'})
    course, _ = AiCertsCourse.objects.get_or_create(lms_course_id=999, defaults={'title': 'Test AiCerts Course', 'external_id': 9999})
    
    enrollment = Enrollment.objects.create(
        user=user,
        content_object=course,
        enrollment_type=EnrollmentType.INDUSTRY_TRAINING,
        status=EnrollmentStatus.PENDING_PAYMENT,
        learner_full_name='Test User'
    )
    
    print('Created enrollment, triggering payment...')
    # 2. Mock SSOService
    with patch.object(SSOService, 'create_user', return_value={'id': 12345, 'status': 'success'}) as mock_create_user, \
         patch.object(SSOService, 'enroll_user', return_value={'status': 'success'}) as mock_enroll_user:
         
        # 3. Trigger signal by changing status to ENROLLED
        enrollment.status = EnrollmentStatus.ENROLLED
        enrollment.save()
        
        # 4. Assertions
        user.refresh_from_db()
        print('User AiCerts ID:', user.aicerts_user_id)
        print('Mock create_user called:', mock_create_user.called)
        print('Mock enroll_user called:', mock_enroll_user.called)
        
        if mock_enroll_user.called:
            print('SUCCESS: AiCerts partner enrollment was triggered!')
        else:
            print('FAILED: AiCerts partner enrollment was NOT triggered.')

test_aicerts_trigger()
