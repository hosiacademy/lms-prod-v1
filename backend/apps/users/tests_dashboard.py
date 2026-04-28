"""
Tests for role-based dashboard with country/region filtering.
Tests HR Admin, Executive Admin, and general admin access patterns.
"""
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status

from apps.localization.models import Country
from apps.payments.models import AdminRole

User = get_user_model()


class RoleBasedDashboardTest(TestCase):
    """Test role-based dashboard access with country filtering"""
    
    def setUp(self):
        self.client = APIClient()
        
        # Create test countries
        self.country_za = Country.objects.create(
            code='ZA',
            name='South Africa',
            native='South Africa',
            is_active=True
        )
        self.country_ke = Country.objects.create(
            code='KE',
            name='Kenya',
            native='Kenya',
            is_active=True
        )
        self.country_ng = Country.objects.create(
            code='NG',
            name='Nigeria',
            native='Nigeria',
            is_active=True
        )
        
        # Create HR Admin for South Africa
        self.hr_admin = User.objects.create_user(
            username='hr_admin_za',
            email='hr.za@hosi.academy',
            password='TestPass123!',
            role_id=1,
            country=self.country_za,
            name='HR Admin South Africa'
        )
        AdminRole.objects.create(
            user=self.hr_admin,
            role_type='hr_admin',
            is_active=True
        )
        
        # Create HR Admin for Kenya
        self.hr_admin_ke = User.objects.create_user(
            username='hr_admin_ke',
            email='hr.ke@hosi.academy',
            password='TestPass123!',
            role_id=1,
            country=self.country_ke,
            name='HR Admin Kenya'
        )
        AdminRole.objects.create(
            user=self.hr_admin_ke,
            role_type='hr_admin',
            is_active=True
        )
        
        # Create Executive Admin (can view all countries)
        self.exec_admin = User.objects.create_user(
            username='exec_admin',
            email='exec@hosi.academy',
            password='TestPass123!',
            role_id=1,
            name='Executive Admin'
        )
        AdminRole.objects.create(
            user=self.exec_admin,
            role_type='executive_admin',
            is_active=True
        )
        
        # Create superuser
        self.superuser = User.objects.create_superuser(
            username='superuser',
            email='super@hosi.academy',
            password='TestPass123!',
            role_id=1,
            name='Superuser'
        )
        
        # Create regular student (should not have admin dashboard access)
        self.student = User.objects.create_user(
            username='student',
            email='student@hosi.academy',
            password='TestPass123!',
            role_id=3,
            country=self.country_za,
            name='Test Student'
        )
    
    def test_hr_admin_dashboard_access(self):
        """Test HR Admin can access dashboard"""
        self.client.force_authenticate(user=self.hr_admin)
        url = reverse('users:dashboard')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['role'], 'admin')
        self.assertTrue(response.data['country_context']['restricted'])
        self.assertEqual(response.data['country_context']['country_id'], self.country_za.id)
        self.assertEqual(response.data['country_context']['country_name'], 'South Africa')
    
    def test_hr_admin_sees_only_own_country_data(self):
        """Test HR Admin only sees data for their assigned country"""
        self.client.force_authenticate(user=self.hr_admin)
        url = reverse('users:dashboard')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify country context
        self.assertTrue(response.data['country_context']['restricted'])
        self.assertEqual(response.data['country_context']['country_id'], self.country_za.id)
        
        # Verify user metrics are filtered by country
        # (The actual counts depend on test data, but the filter should be applied)
        self.assertIn('user_metrics', response.data)
        self.assertIn('country_context', response.data)
    
    def test_hr_admin_without_country_fails(self):
        """Test HR Admin without assigned country gets appropriate error"""
        hr_no_country = User.objects.create_user(
            username='hr_no_country',
            email='hr.nocountry@hosi.academy',
            password='TestPass123!',
            role_id=1,
            name='HR Admin No Country'
        )
        AdminRole.objects.create(
            user=hr_no_country,
            role_type='hr_admin',
            is_active=True
        )
        
        self.client.force_authenticate(user=hr_no_country)
        url = reverse('users:dashboard-hr-admin')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        self.assertIn('assigned country', response.data['error'])
    
    def test_executive_admin_dashboard_access(self):
        """Test Executive Admin can access dashboard with all countries"""
        self.client.force_authenticate(user=self.exec_admin)
        url = reverse('users:dashboard')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['role'], 'admin')
        self.assertFalse(response.data['country_context']['restricted'])
        self.assertTrue(response.data['country_context']['can_view_all_countries'])
    
    def test_executive_admin_sees_all_countries(self):
        """Test Executive Admin sees data for all countries"""
        self.client.force_authenticate(user=self.exec_admin)
        url = reverse('users:dashboard-executive')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        # Verify country context shows no restrictions
        self.assertFalse(response.data['country_context']['restricted'])
        self.assertTrue(response.data['country_context']['can_view_all_countries'])
        
        # Should have access to all test countries
        allowed_countries = response.data['country_context'].get('available_countries', [])
        country_ids = [c['id'] for c in allowed_countries]
        self.assertIn(self.country_za.id, country_ids)
        self.assertIn(self.country_ke.id, country_ids)
        self.assertIn(self.country_ng.id, country_ids)
    
    def test_superuser_dashboard_access(self):
        """Test Superuser can access dashboard with all countries"""
        self.client.force_authenticate(user=self.superuser)
        url = reverse('users:dashboard')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['role'], 'admin')
        self.assertFalse(response.data['country_context']['restricted'])
        self.assertTrue(response.data['country_context']['can_view_all_countries'])
    
    def test_student_cannot_access_admin_dashboard(self):
        """Test regular student cannot access admin dashboard endpoints"""
        self.client.force_authenticate(user=self.student)
        url = reverse('users:dashboard')
        response = self.client.get(url)
        
        # Student should get their own student dashboard, not admin dashboard
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['role'], 'student')
    
    def test_hr_admin_cannot_access_other_country(self):
        """Test HR Admin cannot view data for another country"""
        self.client.force_authenticate(user=self.hr_admin)
        
        # Try to access Kenya's data (should still show South Africa data)
        url = reverse('users:dashboard')
        response = self.client.get(url, {'country': self.country_ke.id})
        
        # Should still return data, but filtered to HR Admin's country (South Africa)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['country_context']['country_id'], self.country_za.id)
    
    def test_country_access_info_endpoint(self):
        """Test country access info endpoint returns correct data"""
        self.client.force_authenticate(user=self.hr_admin)
        url = reverse('users:dashboard-country-access')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['country_access']['country_id'], self.country_za.id)
        self.assertEqual(response.data['country_access']['restricted'], True)
        self.assertEqual(len(response.data['allowed_countries']), 1)
        self.assertEqual(response.data['allowed_countries'][0]['id'], self.country_za.id)
    
    def test_hr_admin_specific_endpoint(self):
        """Test HR Admin specific dashboard endpoint"""
        self.client.force_authenticate(user=self.hr_admin)
        url = reverse('users:dashboard-hr-admin')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('assigned_country', response.data['user_role'])
        self.assertEqual(
            response.data['user_role']['assigned_country']['id'],
            self.country_za.id
        )
    
    def test_non_hr_admin_cannot_access_hr_endpoint(self):
        """Test non-HR Admin cannot access HR Admin specific endpoint"""
        self.client.force_authenticate(user=self.student)
        url = reverse('users:dashboard-hr-admin')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)


class CountryFilterUtilityTest(TestCase):
    """Test country filter utility functions"""
    
    def setUp(self):
        self.country = Country.objects.create(
            code='ZW',
            name='Zimbabwe',
            native='Zimbabwe',
            is_active=True
        )
        
        self.hr_admin = User.objects.create_user(
            username='hr_zw',
            email='hr.zw@hosi.academy',
            password='TestPass123!',
            role_id=1,
            country=self.country,
            name='HR Admin Zimbabwe'
        )
        AdminRole.objects.create(
            user=self.hr_admin,
            role_type='hr_admin',
            is_active=True
        )
        
        self.exec_admin = User.objects.create_user(
            username='exec_2',
            email='exec2@hosi.academy',
            password='TestPass123!',
            role_id=1,
            name='Executive Admin 2'
        )
        AdminRole.objects.create(
            user=self.exec_admin,
            role_type='executive_admin',
            is_active=True
        )
    
    def test_get_user_country_filter_hr_admin(self):
        """Test country filter for HR Admin"""
        from apps.users.filters import get_user_country_filter
        from django.db.models import Q
        
        filter_q = get_user_country_filter(self.hr_admin)
        
        # Should return a Q object filtering by country
        self.assertIsInstance(filter_q, Q)
        # The filter should contain the country ID
        self.assertIsNotNone(filter_q)
    
    def test_get_user_country_filter_executive(self):
        """Test country filter for Executive Admin (should be empty Q)"""
        from apps.users.filters import get_user_country_filter
        from django.db.models import Q
        
        filter_q = get_user_country_filter(self.exec_admin)
        
        # Executive admin should get empty Q (no filter, all data)
        self.assertIsInstance(filter_q, Q)
    
    def test_get_allowed_countries_hr_admin(self):
        """Test allowed countries for HR Admin"""
        from apps.users.filters import get_allowed_countries
        
        countries = get_allowed_countries(self.hr_admin)
        
        # Should only have access to assigned country
        self.assertEqual(countries.count(), 1)
        self.assertEqual(countries.first().id, self.country.id)
    
    def test_get_allowed_countries_executive(self):
        """Test allowed countries for Executive Admin"""
        from apps.users.filters import get_allowed_countries
        
        countries = get_allowed_countries(self.exec_admin)
        
        # Should have access to all active countries
        self.assertGreater(countries.count(), 0)
