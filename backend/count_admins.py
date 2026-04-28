import os
import sys
import django

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from apps.payments.models import AdminRole, AdminCountryAccess
from django.db.models import Count

def count():
    # Group by country
    countries = {}
    universal_count = 0
    
    roles = AdminRole.objects.all()
    for role in roles:
        accesses = role.country_accesses.all()
        if not accesses.exists():
            universal_count += 1
        else:
            for acc in accesses:
                c_name = acc.country.name
                countries[c_name] = countries.get(c_name, 0) + 1
    
    print(f"Universal Admins: {universal_count}")
    print("\nRegional Admins:")
    # Sort by count desc
    for c, count in sorted(countries.items(), key=lambda x: x[1], reverse=True):
        print(f" - {c}: {count}")

if __name__ == "__main__":
    count()
