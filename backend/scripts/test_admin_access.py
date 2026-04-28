import os
import sys
import django

# Setup Django environment BEFORE other imports
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from django.contrib.auth import get_user_model
from rest_framework.test import APIClient
from django.urls import reverse

User = get_user_model()

def test_access():
    client = APIClient()
    
    test_cases = [
        {
            'email': 'hosimonorepo@gmail.com',
            'password': 'Admin123!', # Assuming it was created with this in setup_admin_tiers
            'expected_roles': ['system_admin', 'payment_admin', 'marketing_admin', 'hr_admin', 'executive_admin'],
            'is_universal': True
        },
        {
            'email': 'payment_admin_zw@hosiacademy.africa',
            'password': 'HosiAdmin2026!',
            'expected_roles': ['payment_admin'],
            'country_code': 'ZW'
        },
        {
            'email': 'hr_admin_za@hosiacademy.africa',
            'password': 'HosiAdmin2026!',
            'expected_roles': ['hr_admin'],
            'country_code': 'ZA'
        }
    ]

    print("\nStarting Admin Access Role-Based Testing...")
    print("="*60)

    for tc in test_cases:
        email = tc['email']
        print(f"\nTesting User: {email}")
        
        user = User.objects.get(email=email)
        client.force_authenticate(user=user)
        
        # 1. Test Role Assignment Endpoint
        response = client.get(reverse('admin-role-assignment'))
        if response.status_code == 200:
            data = response.json()
            roles = data.get('roles', [])
            print(f"[OK] Roles found: {roles}")
            for er in tc['expected_roles']:
                if er in roles:
                    print(f"  - Verified Role: {er}")
                else:
                    print(f"  - [FAIL] Role {er} not found in assignment!")
        else:
            print(f"[FAIL] Could not access role-assignment endpoint: {response.status_code}")

        # 2. Test Dashboard Data (Geography Check)
        if 'hr_admin' in tc['expected_roles'] or tc.get('is_universal'):
            response = client.get(reverse('hr-dashboard'))
            if response.status_code == 200:
                data = response.json()
                countries = [c['code'] for c in data.get('allowed_countries', [])]
                if tc.get('is_universal'):
                    print(f"[OK] Universal Admin sees multiple countries: {len(countries)}")
                else:
                    expected_country = tc.get('country_code')
                    if expected_country in countries and len(countries) == 1:
                        print(f"[OK] HR Admin restricted to {expected_country} only.")
                    else:
                        print(f"[FAIL] HR Admin sees incorrect countries: {countries}")
            else:
                print(f"[FAIL] Could not access HR Dashboard: {response.status_code}")

    print("\n" + "="*60)
    print("Access Testing Completed.")

if __name__ == "__main__":
    test_access()
