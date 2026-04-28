"""
Tests for role-based dashboard with multi-country support.
Tests HR Admin, Payment Admin, Executive Admin, and System Admin access patterns.
All admin roles except System Admin (superuser) can be assigned to multiple countries.
"""
from django.test import TestCase
from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework.test import APIClient
from rest_framework import status

from apps.localization.models import Country
from apps.payments.models import AdminRole, AdminCountryAccess

User = get_user_model()


class MultiCountryDashboardTest(TestCase):
    """Test multi-country dashboard access for all admin roles"""
    
    def setUp(self):
        self.client = APIClient()
        
        # Create test countries
        self.country_za = Country.objects.create(code='ZA', name='South Africa', native='South Africa', is_active=True)
        self.country_ke = Country.objects.create(code='KE', name='Kenya', native='Kenya', is_active=True)
        self.country_ng = Country.objects.create(code='NG', name='Nigeria', native='Nigeria', is_active=True)
        self.country_gh = Country.objects.create(code='GH', name='Ghana', native='Ghana', is_active=True)
        
        # Create HR Admin with access to multiple countries (ZA, KE)
        self.hr_admin_multi = User.objects.create_user(
            username='hr_admin_multi',
            email='hr.multi@hosi.academy',
            password='TestPass123!',
            role_id=1,
            name='HR Admin Multi-Country'
        )
        self.hr_role = AdminRole.objects.create(
            user=self.hr_admin_multi,
            role_type='hr_admin',
            is_active=True
        )
        AdminCountryAccess.objects.create(admin_role=self.hr_role, country=self.country_za, is_active=True)
        AdminCountryAccess.objects.create(admin_role=self.hr_role, country=self.country_ke, is_active=True)
        
        # Create HR Admin with access to single country (NG)
        self.hr_admin_single = User.objects.create_user(
            username='hr_admin_ng',
            email='hr.ng@hosi.academy',
            password='TestPass123!',
            role_id=1,
            name='HR Admin Nigeria'
        )
        self.hr_role_ng = AdminRole.objects.create(
            user=self.hr_admin_single,
            role_type='hr_admin',
            is_active=True
        )
        AdminCountryAccess.objects.create(admin_role=self.hr_role_ng, country=self.country_ng, is_active=True)
        
        # Create Payment Admin with access to all African countries
        self.payment_admin = User.objects.create_user(
            username='payment_admin',
            email='payment@hosi.academy',
            password='TestPass123!',
            role_id=1,
            name='Payment Admin'
        )
        self.payment_role = AdminRole.objects.create(
            user=self.payment_admin,
            role_type='payment_admin',
            is_active=True
        )
        AdminCountryAccess.objects.create(admin_role=self.payment_role, country=self.country_za, is_active=True)
        AdminCountryAccess.objects.create(admin_role=self.payment_role, country=self.country_ke, is_active=True)
        AdminCountryAccess.objects.create(admin_role=self.payment_role, country=self.country_ng, is_active=True)
        AdminCountryAccess.objects.create(admin_role=self.payment_role, country=self.country_gh, is_active=True)
        
        # Create Executive Admin with NO country restrictions (all countries by default)
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
        # No AdminCountryAccess entries = access to all countries
        
        # Create System Admin (superuser)
        self.system_admin = User.objects.create_superuser(
            username='system_admin',
            email='system@hosi.academy',
            password='TestPass123!',
            role_id=1,
            name='System Admin'
        )
        
        # Create regular student
        self.student = User.objects.create_user(
            username='student',
            email='student@hosi.academy',
            password='TestPass123!',
            role_id=3,
            country=self.country_za,
            name='Test Student'
        )
    
    def test_hr_admin_multi_country_dashboard(self):
        """Test HR Admin with multiple countries can access dashboard"""
        self.client.force_authenticate(user=self.hr_admin_multi)
        url = reverse('users:dashboard')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['role'], 'admin')
        self.assertTrue(response.data['country_context']['is_multi_country'])
        self.assertEqual(len(response.data['country_context']['allowed_countries']), 2)
    
    def test_hr_admin_multi_country_can_select_country(self):
        """Test HR Admin with multiple countries can select specific country"""
        self.client.force_authenticate(user=self.hr_admin_multi)
        url = reverse('users:dashboard')
        
        # Select Kenya
        response = self.client.get(url, {'country': self.country_ke.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['country_context']['country_id'], self.country_ke.id)
        self.assertEqual(response.data['country_context']['country_name'], 'Kenya')
    
    def test_hr_admin_multi_country_cannot_access_unassigned_country(self):
        """Test HR Admin cannot access country not assigned to them"""
        self.client.force_authenticate(user=self.hr_admin_multi)
        url = reverse('users:dashboard')
        
        # Try to access Nigeria (not assigned)
        response = self.client.get(url, {'country': self.country_ng.id})
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_hr_admin_single_country_dashboard(self):
        """Test HR Admin with single country access"""
        self.client.force_authenticate(user=self.hr_admin_single)
        url = reverse('users:dashboard')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data['country_context']['is_multi_country'])
        self.assertEqual(len(response.data['country_context']['allowed_countries']), 1)
        self.assertEqual(response.data['country_context']['allowed_countries'][0]['id'], self.country_ng.id)
    
    def test_payment_admin_multi_country_dashboard(self):
        """Test Payment Admin with multiple countries"""
        self.client.force_authenticate(user=self.payment_admin)
        url = reverse('users:dashboard-payment-admin')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['country_context']['is_multi_country'])
        self.assertEqual(len(response.data['country_context']['allowed_countries']), 4)
    
    def test_payment_admin_can_select_country(self):
        """Test Payment Admin can select specific country"""
        self.client.force_authenticate(user=self.payment_admin)
        url = reverse('users:dashboard-payment-admin')
        
        # Select Ghana
        response = self.client.get(url, {'country': self.country_gh.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['country_context']['country_id'], self.country_gh.id)
    
    def test_executive_admin_no_country_restrictions(self):
        """Test Executive Admin with no country restrictions sees all countries"""
        self.client.force_authenticate(user=self.exec_admin)
        url = reverse('users:dashboard-executive')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertFalse(response.data['country_context']['restricted'])
        self.assertTrue(response.data['country_context']['can_view_all_countries'])
    
    def test_system_admin_unrestricted_access(self):
        """Test System Admin (superuser) has unrestricted access"""
        self.client.force_authenticate(user=self.system_admin)
        url = reverse('users:dashboard')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['user_role']['is_system_admin'])
        self.assertTrue(response.data['user_role']['is_superuser'])
        self.assertFalse(response.data['country_context']['restricted'])
        self.assertTrue(response.data['country_context']['can_view_all_countries'])
    
    def test_system_admin_can_view_any_country(self):
        """Test System Admin can view any country"""
        self.client.force_authenticate(user=self.system_admin)
        url = reverse('users:dashboard')
        
        # View any country
        response = self.client.get(url, {'country': self.country_za.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        
        response = self.client.get(url, {'country': self.country_ng.id})
        self.assertEqual(response.status_code, status.HTTP_200_OK)
    
    def test_student_cannot_access_admin_dashboards(self):
        """Test regular student cannot access admin-specific dashboards"""
        self.client.force_authenticate(user=self.student)
        
        # HR Admin endpoint
        url = reverse('users:dashboard-hr-admin')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        
        # Payment Admin endpoint
        url = reverse('users:dashboard-payment-admin')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
        
        # Executive endpoint
        url = reverse('users:dashboard-executive')
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_country_access_info_endpoint(self):
        """Test country access info returns correct data for multi-country admin"""
        self.client.force_authenticate(user=self.hr_admin_multi)
        url = reverse('users:dashboard-country-access')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['country_access']['is_multi_country'])
        self.assertEqual(len(response.data['allowed_countries']), 2)
        
        # Check role-specific countries
        self.assertIn('hr_admin', response.data['role_countries'])
        hr_countries = [c['id'] for c in response.data['role_countries']['hr_admin']]
        self.assertIn(self.country_za.id, hr_countries)
        self.assertIn(self.country_ke.id, hr_countries)
    
    def test_country_selection_endpoint(self):
        """Test country selection validation endpoint"""
        self.client.force_authenticate(user=self.hr_admin_multi)
        
        # Valid country selection
        url = reverse('users:dashboard-country-selection', kwargs={'country_id': self.country_za.id})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['has_access'])
        
        # Invalid country selection (not assigned)
        url = reverse('users:dashboard-country-selection', kwargs={'country_id': self.country_ng.id})
        response = self.client.get(url)
        self.assertEqual(response.status_code, status.HTTP_403_FORBIDDEN)
    
    def test_admin_role_without_country_access_has_all_countries(self):
        """Test admin role without specific country assignments has access to all"""
        # Create new admin without country assignments
        admin_no_countries = User.objects.create_user(
            username='admin_no_countries',
            email='admin.no.countries@hosi.academy',
            password='TestPass123!',
            role_id=1,
            name='Admin No Countries'
        )
        AdminRole.objects.create(
            user=admin_no_countries,
            role_type='executive_admin',
            is_active=True
        )
        
        self.client.force_authenticate(user=admin_no_countries)
        url = reverse('users:dashboard-executive')
        response = self.client.get(url)
        
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        # Should have access to all countries (not restricted)
        self.assertFalse(response.data['country_context']['restricted'])
        self.assertTrue(response.data['country_context']['can_view_all_countries'])


class CountryFilterUtilityTest(TestCase):
    """Test country filter utility functions with multi-country support"""
    
    def setUp(self):
        self.country_za = Country.objects.create(code='ZA', name='South Africa', native='South Africa', is_active=True)
        self.country_ke = Country.objects.create(code='KE', name='Kenya', native='Kenya', is_active=True)
        self.country_ng = Country.objects.create(code='NG', name='Nigeria', native='Nigeria', is_active=True)
        
        # Create HR Admin with multiple countries
        self.hr_admin = User.objects.create_user(
            username='hr_test',
            email='hr.test@hosi.academy',
            password='TestPass123!',
            role_id=1,
            name='HR Test'
        )
        self.hr_role = AdminRole.objects.create(
            user=self.hr_admin,
            role_type='hr_admin',
            is_active=True
        )
        AdminCountryAccess.objects.create(admin_role=self.hr_role, country=self.country_za, is_active=True)
        AdminCountryAccess.objects.create(admin_role=self.hr_role, country=self.country_ke, is_active=True)
        
        # Create System Admin
        self.system_admin = User.objects.create_superuser(
            username='system_test',
            email='system.test@hosi.academy',
            password='TestPass123!',
            name='System Test'
        )
    
    def test_get_user_country_filter_multi_country(self):
        """Test country filter for multi-country HR Admin"""
        from apps.users.filters import get_user_country_filter
        from django.db.models import Q
        
        filter_q = get_user_country_filter(self.hr_admin)
        
        # Should return a Q object with multiple country IDs
        self.assertIsNotNone(filter_q)
    
    def test_get_user_country_filter_with_selection(self):
        """Test country filter with specific country selection"""
        from apps.users.filters import get_user_country_filter
        
        filter_q = get_user_country_filter(self.hr_admin, selected_country_id=self.country_za.id)
        
        # Should filter to selected country
        self.assertIsNotNone(filter_q)
    
    def test_get_user_country_filter_system_admin(self):
        """Test country filter for System Admin (should be empty Q)"""
        from apps.users.filters import get_user_country_filter
        from django.db.models import Q
        
        filter_q = get_user_country_filter(self.system_admin)
        
        # System admin gets empty Q (no filter, all data)
        self.assertEqual(filter_q, Q())
    
    def test_get_allowed_countries_multi_country(self):
        """Test allowed countries for multi-country admin"""
        from apps.users.filters import get_allowed_countries
        
        countries = get_allowed_countries(self.hr_admin)
        
        # Should have access to assigned countries
        self.assertEqual(countries.count(), 2)
        country_ids = list(countries.values_list('id', flat=True))
        self.assertIn(self.country_za.id, country_ids)
        self.assertIn(self.country_ke.id, country_ids)
    
    def test_get_allowed_countries_system_admin(self):
        """Test allowed countries for System Admin"""
        from apps.users.filters import get_allowed_countries
        
        countries = get_allowed_countries(self.system_admin)
        
        # Should have access to all active countries
        self.assertGreater(countries.count(), 0)
    
    def test_can_user_access_country(self):
        """Test country access check"""
        from apps.users.filters import can_user_access_country
        
        # HR Admin should have access to ZA
        self.assertTrue(can_user_access_country(self.hr_admin, self.country_za.id))
        
        # HR Admin should NOT have access to NG
        self.assertFalse(can_user_access_country(self.hr_admin, self.country_ng.id))
        
        # System Admin should have access to all
        self.assertTrue(can_user_access_country(self.system_admin, self.country_za.id))
        self.assertTrue(can_user_access_country(self.system_admin, self.country_ng.id))
    
    def test_get_admin_role_countries(self):
        """Test getting countries for specific admin role"""
        from apps.users.filters import get_admin_role_countries
        
        countries = get_admin_role_countries(self.hr_admin, 'hr_admin')
        
        self.assertEqual(countries.count(), 2)
        
        # Non-existent role should return empty
        countries = get_admin_role_countries(self.hr_admin, 'payment_admin')
        self.assertEqual(countries.count(), 0)
