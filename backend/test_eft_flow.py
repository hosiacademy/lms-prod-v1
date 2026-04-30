import os
import sys
import django

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from django.test import Client
from django.contrib.auth import get_user_model
import json

User = get_user_model()

def test_eft_flow():
    client = Client()
    user, _ = User.objects.get_or_create(email="testeft@example.com", defaults={"username": "testeft@example.com"})
    client.force_login(user)

    countries = [
        {"country": "KE", "currency": "KES", "amount": 15000},
        {"country": "ZA", "currency": "ZAR", "amount": 1500},
        {"country": "ZW", "currency": "USD", "amount": 100},
        {"country": "ZM", "currency": "ZMW", "amount": 2500},
    ]

    print("Testing EFT flow via unified initiate endpoint...")
    for c in countries:
        print(f"\n--- Testing {c['country']} ({c['currency']}) ---")
        payload = {
            "program_id": "1",
            "type": "masterclass",
            "amount": c["amount"],
            "currency": c["currency"],
            "country": c["country"],
            "provider": "eft",
            "payment_method": "eft",
            "metadata": {
                "email": user.email,
                "full_name": "Test User"
            }
        }
        
        response = client.post('/api/v1/payments/initiate/', json.dumps(payload), content_type='application/json')
        print(f"Status: {response.status_code}")
        try:
            data = response.json()
            if response.status_code == 200:
                print(f"Success! Provider: {data.get('provider_code')}, Transaction ID: {data.get('transaction', {}).get('id')}")
                if 'bank_details' in data:
                    print(f"Bank details included: {data['bank_details'].get('bank_name')}")
            else:
                print(f"Error: {data}")
        except Exception as e:
            print(f"Failed to parse JSON: {e}, Response: {response.content}")

if __name__ == "__main__":
    test_eft_flow()
