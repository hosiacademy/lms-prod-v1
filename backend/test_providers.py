import os
import sys
import django

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from django.test import Client
import json

def test_providers():
    client = Client()
    countries = [
        {"country": "KE", "currency": "KES", "amount": 15000},
        {"country": "ZA", "currency": "ZAR", "amount": 1500},
        {"country": "ZW", "currency": "USD", "amount": 100},
        {"country": "ZM", "currency": "ZMW", "amount": 2500},
    ]

    print("Fetching available providers...")
    for c in countries:
        url = f"/api/v1/payments/providers-list/?country={c['country']}&amount={c['amount']}&currency={c['currency']}"
        response = client.get(url)
        try:
            data = response.json()
            providers = data.get('providers', [])
            print(f"\n--- {c['country']} Providers ---")
            for p in providers:
                print(f" - {p.get('name')} (Code: {p.get('code')}, Type: {p.get('type')})")
        except Exception as e:
            print(f"Error for {c['country']}: {response.status_code} - {e}")

if __name__ == "__main__":
    test_providers()
