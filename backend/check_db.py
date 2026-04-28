import os
import sys
import django

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from apps.payments.models import AdminRole, AdminCountryAccess
from apps.localization.models import Country
from django.contrib.auth import get_user_model

User = get_user_model()

def check():
    email = 'hosimonorepo@gmail.com'
    try:
        user = User.objects.get(email=email)
        print(f"User: {user.email}")
        roles = AdminRole.objects.filter(user=user)
        print(f"Roles Count: {roles.count()}")
        for r in roles:
            countries = list(r.country_accesses.values_list('country__code', flat=True))
            print(f"  - {r.role_type}: {countries if countries else 'Universal'}")
    except User.DoesNotExist:
        print(f"User {email} not found!")

    active_countries = Country.objects.filter(is_active=True)
    print(f"Active Countries ({active_countries.count()}): {list(active_countries.values_list('code', flat=True))}")

if __name__ == "__main__":
    check()
