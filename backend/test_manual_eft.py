import os
import sys
import django
import json
from decimal import Decimal

# Setup Django
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from django.test import Client
from django.contrib.auth import get_user_model
from apps.payments.models import PaymentTransaction, PaymentStatus
from apps.enrollments.models import ProvisionalEnrollment

User = get_user_model()

def test_manual_eft_lifecycle():
    client = Client()
    # 1. Setup Test User
    user, _ = User.objects.get_or_create(
        email="eft_tester@example.com", 
        defaults={"username": "eft_tester_123", "first_name": "EFT", "last_name": "Tester"}
    )
    client.force_login(user)

    # 2. Initiate EFT Payment
    print("Step 1: Initiating EFT Payment...")
    payload = {
        "program_id": "1",
        "type": "masterclass",
        "amount": 1200,
        "currency": "ZAR",
        "country": "ZA",
        "individual_details": {
            "full_name": "EFT Tester",
            "email": "eft_tester@example.com",
            "phone": "+27123456789"
        }
    }
    
    response = client.post('/api/v1/payments/eft/initiate/', data=json.dumps(payload), content_type='application/json')
    if response.status_code != 200:
        print(f"FAILED to initiate: {response.content}")
        return
    
    data = response.json()
    reference = data['reference']
    print(f"SUCCESS: Reference generated: {reference}")
    print(f"Bank Account: {data['bank_details']['account_number']}")

    # 3. Check Status (Should be Pending)
    print("\nStep 2: Checking Status...")
    response = client.get(f'/api/v1/payments/eft/status/{reference}/')
    status_data = response.json()
    print(f"Current Status: {status_data['status']}")
    if status_data['status'] != 'pending':
        print(f"Error: Expected pending status, got {status_data['status']}")
        return

    # 4. Admin Verification
    print("\nStep 3: Simulating Admin Verification...")
    # Get an admin user
    admin_user = User.objects.filter(is_superuser=True).first()
    if not admin_user:
        # Create one if not exists
        admin_user = User.objects.create_superuser('admin_test_eft', 'admin_eft@test.com', 'password123')
    
    client.force_login(admin_user)
    verify_payload = {
        "reference": reference,
        "notes": "Verified against statement #123"
    }
    response = client.post('/api/v1/payments/eft/admin/verify/', data=json.dumps(verify_payload), content_type='application/json')
    
    if response.status_code == 200:
        print("SUCCESS: Payment verified by admin!")
    else:
        print(f"FAILED to verify: {response.content}")
        return

    # 5. Final Status Check
    print("\nStep 4: Verifying Final State...")
    response = client.get(f'/api/v1/payments/eft/status/{reference}/')
    final_data = response.json()
    print(f"Final Payment Status: {final_data['status']}")
    print(f"Final Enrollment Status: {final_data['enrollment_status']}")
    
    if final_data['status'] == 'successful' and final_data['enrollment_status'] == 'confirmed':
        print("\n--- EFT LIFECYCLE TEST PASSED ---")
    else:
        print("\n--- EFT LIFECYCLE TEST FAILED ---")

if __name__ == "__main__":
    test_manual_eft_lifecycle()
