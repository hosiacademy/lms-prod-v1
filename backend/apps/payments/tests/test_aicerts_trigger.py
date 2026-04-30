from django.test import TestCase
from unittest.mock import patch
from apps.users.models import User
from apps.aicerts_courses.models import AiCertsCourse
from apps.payments.models import Enrollment, EnrollmentStatus, EnrollmentType
from apps.aicerts_integration.services import SSOService

class AiCertsTriggerTest(TestCase):
    def test_aicerts_trigger_on_payment(self):
        print('\nStarting test within Django Test DB...')
        user = User.objects.create(email='test_trigger@example.com', username='test_trigger', first_name='Test', last_name='User')
        course = AiCertsCourse.objects.create(lms_course_id=999, title='Test AiCerts Course', external_id=9999)
        
        enrollment = Enrollment.objects.create(
            user=user,
            content_object=course,
            enrollment_type=EnrollmentType.INDUSTRY_TRAINING,
            status=EnrollmentStatus.PENDING_PAYMENT,
            learner_full_name='Test User'
        )
        
        with patch.object(SSOService, 'create_user', return_value={'id': 12345, 'status': 'success'}) as mock_create_user, \
             patch.object(SSOService, 'enroll_user', return_value={'status': 'success'}) as mock_enroll_user:
             
            enrollment.status = EnrollmentStatus.ENROLLED
            enrollment.save()
            
            user.refresh_from_db()
            self.assertEqual(user.aicerts_user_id, 12345)
            self.assertTrue(mock_create_user.called)
            self.assertTrue(mock_enroll_user.called)
            print('SUCCESS: AiCerts partner enrollment was triggered!')

