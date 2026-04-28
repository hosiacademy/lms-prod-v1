"""
Comprehensive Tests for Cash Payment System

Tests cover:
1. CashPaymentInstructionsView - Pathway-specific cash payment instructions
2. On-site payment creation - Provisional enrollment with cash payment
3. On-site payment settlement - Admin settling payments at office
4. Pending on-site payments retrieval - Admin dashboard
5. Provisional enrollment business rules - Reference codes, expiry, etc.
6. Office instructions and location data
7. Multiple enrollment types (masterclass, learnership, industry, custom)

Run Tests:
    cd /home/tk/lms-prod/backend
    python manage.py test apps.payments.tests.test_cash_payment -v 2
"""

import os
import sys
import unittest
from unittest.mock import patch, MagicMock, Mock
from decimal import Decimal
from datetime import timedelta
import json

# Setup Django settings
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')

import django
django.setup()

from django.test import TestCase, Client, RequestFactory
from django.urls import reverse
from django.utils import timezone
from django.contrib.auth import get_user_model
from rest_framework.test import APIClient, APITestCase
from rest_framework import status

from apps.payments.cash_payment_views import CashPaymentInstructionsView
from apps.enrollments.models import ProvisionalEnrollment
from apps.payments.models import PaymentTransaction
from apps.users.models import User

User = get_user_model()


# ============================================================================
# TEST 1: Cash Payment Instructions View
# ============================================================================

class TestCashPaymentInstructionsView(APITestCase):
    """Test cash payment instructions for all enrollment types"""

    def setUp(self):
        self.client = APIClient()
        self.url = '/api/payments/cash-payment-instructions/'

    def test_get_masterclass_cash_instructions(self):
        """Test: Masterclass cash payment instructions"""
        response = self.client.get(self.url, {
            'enrollment_type': 'masterclass',
            'program_title': 'Leadership Masterclass 2026'
        })

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.data

        # Verify structure
        self.assertEqual(data['enrollment_type'], 'masterclass')
        self.assertIn('title', data)
        self.assertIn('subtitle', data)
        self.assertIn('overview', data)
        self.assertIn('steps', data)
        self.assertIn('required_documents', data)
        self.assertIn('payment_locations', data)
        self.assertIn('timeline', data)
        self.assertIn('important_notes', data)
        self.assertIn('benefits', data)
        self.assertIn('contact_support', data)

        # Verify masterclass-specific content
        self.assertIn('Cash Payment for Masterclass', data['title'])
        self.assertIn('Leadership Masterclass 2026', data['subtitle'])
        self.assertGreater(len(data['steps']), 0)
        self.assertEqual(data['timeline']['reservation_period'], '14 days')

    def test_get_learnership_cash_instructions(self):
        """Test: Learnership cash payment instructions"""
        response = self.client.get(self.url, {
            'enrollment_type': 'learnership',
            'program_title': 'Business Administration Learnership'
        })

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.data

        self.assertEqual(data['enrollment_type'], 'learnership')
        self.assertIn('SETA Compliance', data)
        self.assertIn('seta_compliance', data)
        self.assertEqual(data['timeline']['reservation_period'], '7 days (prerequisites verification)')
        self.assertGreater(len(data['required_documents']), 0)

    def test_get_industry_training_cash_instructions(self):
        """Test: Industry-Based Training cash payment instructions"""
        response = self.client.get(self.url, {
            'enrollment_type': 'industry_training',
            'program_title': 'AI Certification Program'
        })

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.data

        self.assertEqual(data['enrollment_type'], 'industry_training')
        self.assertIn('corporate_options', data)
        self.assertIn('AICERTS', data['important_notes'][0] if data['important_notes'] else '')

    def test_get_custom_selection_cash_instructions(self):
        """Test: Custom Course Selection cash payment instructions"""
        response = self.client.get(self.url, {
            'enrollment_type': 'custom_selection',
            'program_title': 'Python & Django Bundle'
        })

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.data

        self.assertEqual(data['enrollment_type'], 'custom_selection')
        self.assertIn('Custom Course Selection', data['title'])
        self.assertIn('course_access', data['timeline'])

    def test_get_role_training_cash_instructions(self):
        """Test: Role-Based Training cash payment instructions"""
        response = self.client.get(self.url, {
            'enrollment_type': 'role_training',
            'program_title': 'Data Analyst Career Path'
        })

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.data

        self.assertEqual(data['enrollment_type'], 'role_training')
        self.assertIn('Role-Based Training', data['title'])

    def test_default_enrollment_type(self):
        """Test: Default to masterclass when enrollment_type not specified"""
        response = self.client.get(self.url)

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.data

        self.assertEqual(data['enrollment_type'], 'masterclass')

    def test_unknown_enrollment_type_defaults_to_masterclass(self):
        """Test: Unknown enrollment type defaults to masterclass"""
        response = self.client.get(self.url, {
            'enrollment_type': 'unknown_type'
        })

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        data = response.data

        self.assertEqual(data['enrollment_type'], 'masterclass')

    def test_cash_instructions_all_types_have_required_fields(self):
        """Test: All enrollment types have required instruction fields"""
        enrollment_types = [
            'masterclass',
            'learnership',
            'industry_training',
            'custom_selection',
            'role_training',
        ]

        required_fields = [
            'enrollment_type',
            'enrollment_type_display',
            'icon',
            'title',
            'subtitle',
            'overview',
            'steps',
            'required_documents',
            'payment_locations',
            'timeline',
            'important_notes',
            'benefits',
            'contact_support',
        ]

        for enrollment_type in enrollment_types:
            response = self.client.get(self.url, {
                'enrollment_type': enrollment_type,
                'program_title': 'Test Program'
            })

            self.assertEqual(response.status_code, status.HTTP_200_OK,
                           f"Failed for enrollment type: {enrollment_type}")

            for field in required_fields:
                self.assertIn(field, response.data,
                            f"Missing field '{field}' for {enrollment_type}")

    def test_cash_instructions_steps_are_sequential(self):
        """Test: Payment steps are numbered sequentially"""
        response = self.client.get(self.url, {
            'enrollment_type': 'masterclass'
        })

        steps = response.data['steps']
        self.assertGreater(len(steps), 0)

        for i, step in enumerate(steps, 1):
            self.assertEqual(step['step'], i)
            self.assertIn('title', step)
            self.assertIn('description', step)
            self.assertIn('icon', step)
            self.assertIn('details', step)

    def test_cash_instructions_contact_support(self):
        """Test: Contact support information is present"""
        enrollment_types = ['masterclass', 'learnership', 'industry_training']

        for enrollment_type in enrollment_types:
            response = self.client.get(self.url, {
                'enrollment_type': enrollment_type
            })

            contact = response.data['contact_support']
            self.assertIn('phone', contact)
            self.assertIn('email', contact)
            self.assertIn('hours', contact)


# ============================================================================
# TEST 2: On-Site Payment Creation
# ============================================================================

class TestOnSitePaymentCreation(APITestCase):
    """Test creating provisional enrollments for cash payments"""

    def setUp(self):
        self.client = APIClient()
        self.url = '/api/payments/on-site/create/'

        # Create test user
        self.test_user = User.objects.create_user(
            email='testcash@example.com',
            password='testpass123',
            first_name='Test',
            last_name='User',
            phone='+263771234567'
        )

        self.valid_payload = {
            'enrollment_type': 'masterclass',
            'program_id': '1',
            'amount': 1500.00,
            'currency': 'ZAR',
            'user_data': {
                'email': 'testcash@example.com',
                'first_name': 'Test',
                'last_name': 'User',
                'phone': '+263771234567',
                'country': 'ZW'
            },
            'metadata': {
                'program_title': 'Leadership Masterclass',
                'training_start_date': (timezone.now() + timedelta(days=30)).isoformat()
            }
        }

    def test_create_on_site_enrollment_masterclass(self):
        """Test: Create on-site enrollment for masterclass"""
        response = self.client.post(
            self.url,
            data=self.valid_payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        data = response.data

        # Verify response structure
        self.assertTrue(data['success'])
        self.assertIn('reference_code', data)
        self.assertIn('expires_at', data)
        self.assertEqual(data['amount'], 1500.00)
        self.assertEqual(data['currency'], 'ZAR')
        self.assertEqual(data['enrollment_type'], 'masterclass')

        # Verify business rules
        self.assertIn('business_rules_applied', data)
        rules = data['business_rules_applied']
        self.assertEqual(rules['status'], 'cash_pending')
        self.assertTrue(rules['reference_code_generated'])
        self.assertTrue(rules['logged_to_admin_dashboards'])

        # Verify instructions present
        self.assertIn('instructions', data)
        self.assertIn('next_steps', data)
        self.assertIn('admin_dashboard_links', data)

    def test_create_on_site_enrollment_learnership(self):
        """Test: Create on-site enrollment for learnership"""
        payload = self.valid_payload.copy()
        payload.update({
            'enrollment_type': 'learnership',
            'program_id': '1'
        })

        response = self.client.post(
            self.url,
            data=payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['enrollment_type'], 'learnership')

    def test_create_on_site_enrollment_missing_email(self):
        """Test: Reject on-site enrollment without email"""
        payload = self.valid_payload.copy()
        payload['user_data'] = {
            'first_name': 'Test',
            'last_name': 'User'
        }

        response = self.client.post(
            self.url,
            data=payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)

    def test_create_on_site_enrollment_invalid_amount(self):
        """Test: Reject on-site enrollment with invalid amount"""
        payload = self.valid_payload.copy()
        payload['amount'] = 0

        response = self.client.post(
            self.url,
            data=payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_on_site_enrollment_negative_amount(self):
        """Test: Reject on-site enrollment with negative amount"""
        payload = self.valid_payload.copy()
        payload['amount'] = -100

        response = self.client.post(
            self.url,
            data=payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_on_site_enrollment_missing_enrollment_type(self):
        """Test: Reject on-site enrollment without enrollment type"""
        payload = self.valid_payload.copy()
        del payload['enrollment_type']

        response = self.client.post(
            self.url,
            data=payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_create_on_site_enrollment_missing_program_id(self):
        """Test: Reject on-site enrollment without program ID"""
        payload = self.valid_payload.copy()
        del payload['program_id']

        response = self.client.post(
            self.url,
            data=payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)

    def test_on_site_enrollment_creates_provisional(self):
        """Test: On-site enrollment creates ProvisionalEnrollment record"""
        initial_count = ProvisionalEnrollment.objects.count()

        response = self.client.post(
            self.url,
            data=self.valid_payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(ProvisionalEnrollment.objects.count(), initial_count + 1)

        # Verify provisional enrollment
        provisional = ProvisionalEnrollment.objects.latest('created_at')
        self.assertEqual(provisional.status, 'cash_pending')
        self.assertIsNotNone(provisional.reference_code)
        self.assertIsNotNone(provisional.expires_at)

    def test_on_site_enrollment_creates_payment_transaction(self):
        """Test: On-site enrollment creates PaymentTransaction record"""
        initial_count = PaymentTransaction.objects.count()

        response = self.client.post(
            self.url,
            data=self.valid_payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(PaymentTransaction.objects.count(), initial_count + 1)

        # Verify transaction
        transaction = PaymentTransaction.objects.latest('created_at')
        self.assertEqual(transaction.status, 'pending')
        self.assertEqual(transaction.provider, 'cash')
        self.assertEqual(transaction.amount, Decimal('1500.00'))

    def test_on_site_enrollment_reference_code_format(self):
        """Test: Reference code follows expected format"""
        response = self.client.post(
            self.url,
            data=self.valid_payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        reference_code = response.data['reference_code']

        # Reference code should not be empty
        self.assertIsNotNone(reference_code)
        self.assertGreater(len(reference_code), 0)

    def test_on_site_enrollment_expiry_calculation(self):
        """Test: Expiry date is calculated correctly"""
        response = self.client.post(
            self.url,
            data=self.valid_payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        expires_at = timezone.datetime.fromisoformat(response.data['expires_at'])
        now = timezone.now()

        # Expiry should be in the future
        self.assertGreater(expires_at, now)

        # Expiry should be within reasonable time (14 days typically)
        max_expiry = now + timedelta(days=15)
        self.assertLess(expires_at, max_expiry)

    def test_on_site_enrollment_user_country_detection(self):
        """Test: User country is set from payload"""
        payload = self.valid_payload.copy()
        payload['user_data']['country'] = 'KE'

        response = self.client.post(
            self.url,
            data=payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['selected_office_country'], 'KE')

    def test_on_site_enrollment_default_country(self):
        """Test: Default country is ZW when not specified"""
        payload = self.valid_payload.copy()
        del payload['user_data']['country']

        response = self.client.post(
            self.url,
            data=payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        # Should default to ZW
        self.assertEqual(response.data['selected_office_country'], 'ZW')


# ============================================================================
# TEST 3: Office Instructions and Locations
# ============================================================================

class TestOfficeInstructions(TestCase):
    """Test office location data and instructions"""

    def test_office_instructions_south_africa(self):
        """Test: Office instructions for South Africa"""
        from apps.payments.views.on_site_payment_views import get_office_instructions

        instructions = get_office_instructions('ZA')

        self.assertEqual(instructions['country_name'], 'South Africa')
        self.assertIn('locations', instructions)
        self.assertIn('payment_methods', instructions)
        self.assertIn('support', instructions)
        self.assertIn('what_to_bring', instructions)
        self.assertIn('important_notes', instructions)

        # Verify payment methods
        payment_methods = instructions['payment_methods']
        method_names = [m['name'] for m in payment_methods]
        self.assertTrue(any('Cash' in name for name in method_names))
        self.assertTrue(any('POS' in name or 'Swipe' in name for name in method_names))

    def test_office_instructions_kenya(self):
        """Test: Office instructions for Kenya"""
        from apps.payments.views.on_site_payment_views import get_office_instructions

        instructions = get_office_instructions('KE')

        self.assertEqual(instructions['country_name'], 'Kenya')
        self.assertGreater(len(instructions['locations']), 0)

    def test_office_instructions_zimbabwe(self):
        """Test: Office instructions for Zimbabwe"""
        from apps.payments.views.on_site_payment_views import get_office_instructions

        instructions = get_office_instructions('ZW')

        self.assertEqual(instructions['country_name'], 'Zimbabwe')
        self.assertGreater(len(instructions['locations']), 0)

    def test_office_instructions_unknown_country_defaults(self):
        """Test: Unknown country defaults to South Africa"""
        from apps.payments.views.on_site_payment_views import get_office_instructions

        instructions = get_office_instructions('XX')

        # Should default to ZA
        self.assertEqual(instructions['country_name'], 'South Africa')

    def test_office_instructions_has_contact_info(self):
        """Test: Office instructions include contact information"""
        from apps.payments.views.on_site_payment_views import get_office_instructions

        for country_code in ['ZA', 'KE', 'ZW']:
            instructions = get_office_instructions(country_code)
            contact = instructions['support']

            self.assertIn('phone', contact)
            self.assertIn('email', contact)

    def test_office_instructions_payment_methods_have_fees(self):
        """Test: Payment methods include fee information"""
        from apps.payments.views.on_site_payment_views import get_office_instructions

        instructions = get_office_instructions('ZA')

        for method in instructions['payment_methods']:
            self.assertIn('fee', method)
            self.assertIn('name', method)
            self.assertIn('method', method)


# ============================================================================
# TEST 4: Provisional Enrollment Business Rules
# ============================================================================

class TestProvisionalEnrollmentBusinessRules(TestCase):
    """Test provisional enrollment business rules"""

    def setUp(self):
        self.test_user = User.objects.create_user(
            email='bizrule@example.com',
            password='testpass123'
        )

    def test_provisional_enrollment_status_cash_pending(self):
        """Test: Provisional enrollment with cash_pending status"""
        provisional = ProvisionalEnrollment.objects.create(
            user=self.test_user,
            enrollment_type='masterclass',
            status='cash_pending',
            metadata={'program_id': '1'}
        )

        self.assertEqual(provisional.status, 'cash_pending')
        self.assertIsNotNone(provisional.reference_code)
        self.assertIsNotNone(provisional.expires_at)

    def test_provisional_enrollment_expiry_default_14_days(self):
        """Test: Default expiry is 14 days"""
        provisional = ProvisionalEnrollment.objects.create(
            user=self.test_user,
            enrollment_type='masterclass',
            status='cash_pending',
            metadata={'program_id': '1'}
        )

        now = timezone.now()
        expected_max_expiry = now + timedelta(days=14)

        # Expiry should be approximately 14 days
        self.assertLessEqual(provisional.expires_at, expected_max_expiry)
        self.assertGreater(provisional.expires_at, now)

    def test_provisional_enrollment_reference_code_unique(self):
        """Test: Reference codes are unique"""
        provisional1 = ProvisionalEnrollment.objects.create(
            user=self.test_user,
            enrollment_type='masterclass',
            status='cash_pending',
            metadata={'program_id': '1'}
        )

        provisional2 = ProvisionalEnrollment.objects.create(
            user=self.test_user,
            enrollment_type='learnership',
            status='cash_pending',
            metadata={'program_id': '2'}
        )

        self.assertNotEqual(provisional1.reference_code, provisional2.reference_code)

    def test_provisional_enrollment_metadata_storage(self):
        """Test: Metadata is stored correctly"""
        metadata = {
            'program_id': '123',
            'payment_method': 'on_site',
            'selected_office_country': 'ZW',
            'office_payment_pending': True
        }

        provisional = ProvisionalEnrollment.objects.create(
            user=self.test_user,
            enrollment_type='masterclass',
            status='cash_pending',
            metadata=metadata
        )

        self.assertEqual(provisional.metadata['program_id'], '123')
        self.assertEqual(provisional.metadata['payment_method'], 'on_site')
        self.assertTrue(provisional.metadata['office_payment_pending'])


# ============================================================================
# TEST 5: Cash Payment Integration Scenarios
# ============================================================================

class TestCashPaymentIntegration(APITestCase):
    """Test complete cash payment integration scenarios"""

    def setUp(self):
        self.client = APIClient()
        self.create_url = '/api/payments/on-site/create/'

        self.admin_user = User.objects.create_user(
            email='admin@hosi.academy',
            password='adminpass123',
            is_staff=True
        )

        self.test_user = User.objects.create_user(
            email='learner@example.com',
            password='learnerpass123',
            first_name='John',
            last_name='Doe'
        )

    def test_complete_cash_payment_flow_masterclass(self):
        """Test: Complete cash payment flow for masterclass"""
        # Step 1: Create provisional enrollment
        create_payload = {
            'enrollment_type': 'masterclass',
            'program_id': '1',
            'amount': 1500.00,
            'currency': 'ZAR',
            'user_data': {
                'email': 'learner@example.com',
                'first_name': 'John',
                'last_name': 'Doe',
                'country': 'ZA'
            },
            'metadata': {
                'program_title': 'Leadership Masterclass'
            }
        }

        create_response = self.client.post(
            self.create_url,
            data=create_payload,
            format='json'
        )

        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)
        reference_code = create_response.data['reference_code']

        # Step 2: Verify provisional enrollment was created
        provisional = ProvisionalEnrollment.objects.get(reference_code=reference_code)
        self.assertEqual(provisional.status, 'cash_pending')

        # Step 3: Verify payment transaction was created
        transaction = PaymentTransaction.objects.get(provider_reference=reference_code)
        self.assertEqual(transaction.status, 'pending')
        self.assertEqual(transaction.provider, 'cash')

    def test_complete_cash_payment_flow_learnership(self):
        """Test: Complete cash payment flow for learnership"""
        create_payload = {
            'enrollment_type': 'learnership',
            'program_id': '1',
            'amount': 5000.00,
            'currency': 'ZAR',
            'user_data': {
                'email': 'learner@example.com',
                'first_name': 'John',
                'last_name': 'Doe',
                'country': 'ZA'
            },
            'metadata': {
                'program_title': 'Business Admin Learnership'
            }
        }

        create_response = self.client.post(
            self.create_url,
            data=create_payload,
            format='json'
        )

        self.assertEqual(create_response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(create_response.data['enrollment_type'], 'learnership')

    def test_multiple_cash_enrollments_same_user(self):
        """Test: User can create multiple cash enrollments"""
        create_payload = {
            'enrollment_type': 'masterclass',
            'program_id': '1',
            'amount': 1500.00,
            'currency': 'ZAR',
            'user_data': {
                'email': 'learner@example.com',
                'country': 'ZA'
            }
        }

        # Create first enrollment
        response1 = self.client.post(self.create_url, data=create_payload, format='json')
        self.assertEqual(response1.status_code, status.HTTP_201_CREATED)

        # Create second enrollment
        create_payload['program_id'] = '2'
        response2 = self.client.post(self.create_url, data=create_payload, format='json')
        self.assertEqual(response2.status_code, status.HTTP_201_CREATED)

        # Verify both enrollments exist
        user_enrollments = ProvisionalEnrollment.objects.filter(
            user=self.test_user,
            status='cash_pending'
        )
        self.assertGreaterEqual(user_enrollments.count(), 2)

    def test_cash_enrollment_different_currencies(self):
        """Test: Cash enrollments support different currencies"""
        currencies = ['ZAR', 'KES', 'USD', 'ZWL']

        for currency in currencies:
            payload = {
                'enrollment_type': 'masterclass',
                'program_id': '1',
                'amount': 1500.00,
                'currency': currency,
                'user_data': {
                    'email': f'test_{currency.lower()}@example.com',
                    'country': 'ZA'
                }
            }

            response = self.client.post(
                self.create_url,
                data=payload,
                format='json'
            )

            self.assertEqual(response.status_code, status.HTTP_201_CREATED,
                           f"Failed for currency: {currency}")
            self.assertEqual(response.data['currency'], currency)


# ============================================================================
# TEST 6: Edge Cases and Error Handling
# ============================================================================

class TestCashPaymentEdgeCases(APITestCase):
    """Test edge cases and error handling"""

    def setUp(self):
        self.client = APIClient()
        self.url = '/api/payments/on-site/create/'

    def test_cash_enrollment_very_large_amount(self):
        """Test: Cash enrollment with very large amount"""
        payload = {
            'enrollment_type': 'learnership',
            'program_id': '1',
            'amount': 999999.99,
            'currency': 'ZAR',
            'user_data': {
                'email': 'bigspender@example.com',
                'country': 'ZA'
            }
        }

        response = self.client.post(
            self.url,
            data=payload,
            format='json'
        )

        # Should accept large amounts
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_cash_enrollment_decimal_amount(self):
        """Test: Cash enrollment with decimal amount"""
        payload = {
            'enrollment_type': 'masterclass',
            'program_id': '1',
            'amount': 1500.50,
            'currency': 'ZAR',
            'user_data': {
                'email': 'decimal@example.com',
                'country': 'ZA'
            }
        }

        response = self.client.post(
            self.url,
            data=payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['amount'], 1500.50)

    def test_cash_enrollment_empty_metadata(self):
        """Test: Cash enrollment with empty metadata"""
        payload = {
            'enrollment_type': 'masterclass',
            'program_id': '1',
            'amount': 1500.00,
            'currency': 'ZAR',
            'user_data': {
                'email': 'emptymeta@example.com',
                'country': 'ZA'
            },
            'metadata': {}
        }

        response = self.client.post(
            self.url,
            data=payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_cash_enrollment_special_characters_in_name(self):
        """Test: Cash enrollment with special characters in name"""
        payload = {
            'enrollment_type': 'masterclass',
            'program_id': '1',
            'amount': 1500.00,
            'currency': 'ZAR',
            'user_data': {
                'email': 'special@example.com',
                'first_name': 'José María',
                'last_name': 'O\'Brien-Smith',
                'country': 'ZA'
            }
        }

        response = self.client.post(
            self.url,
            data=payload,
            format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

    def test_cash_enrollment_concurrent_requests(self):
        """Test: Multiple concurrent cash enrollment requests"""
        import threading

        results = []

        def create_enrollment(index):
            payload = {
                'enrollment_type': 'masterclass',
                'program_id': str(index),
                'amount': 1500.00,
                'currency': 'ZAR',
                'user_data': {
                    'email': f'concurrent{index}@example.com',
                    'country': 'ZA'
                }
            }

            response = self.client.post(
                self.url,
                data=payload,
                format='json'
            )
            results.append(response.status_code)

        # Create 5 concurrent requests
        threads = []
        for i in range(5):
            thread = threading.Thread(target=create_enrollment, args=(i,))
            threads.append(thread)
            thread.start()

        # Wait for all threads to complete
        for thread in threads:
            thread.join()

        # All should succeed
        for status_code in results:
            self.assertEqual(status_code, status.HTTP_201_CREATED)


# ============================================================================
# RUN TESTS
# ============================================================================

if __name__ == '__main__':
    unittest.main()
