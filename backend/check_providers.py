import os
import sys
import django

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from apps.payments.models import ProviderCountryConfig

def check_db():
    print("\n=== Provider Country Configs ===")
    configs = ProviderCountryConfig.objects.all().select_related('provider')
    for c in configs:
        print(f"Country: {c.country_code}, Provider: {c.provider.code}, Methods: {c.supported_methods}, Active: {c.is_active}")

if __name__ == "__main__":
    check_db()
