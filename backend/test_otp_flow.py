
import os
import django
import sys
import requests
import json
import time

# Set up Django environment
sys.path.append('c:\\lms-prod\\backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from apps.users.models import AuthOTP, User
from apps.payments.models import ContactVerificationOTP
from django.utils import timezone

BASE_URL = "http://127.0.0.1:7001"
TEST_EMAIL = "hosimonorepo@gmail.com"

def test_auth_otp():
    print(f"\n--- Testing Auth OTP (Login) for {TEST_EMAIL} ---")
    
    # 1. Ensure user exists
    user, created = User.objects.get_or_create(
        email=TEST_EMAIL,
        defaults={'username': TEST_EMAIL, 'first_name': 'Hosi', 'last_name': 'Tester'}
    )
    if created:
        print(f"Created test user: {TEST_EMAIL}")
    
    # 2. Request OTP
    print("Requesting OTP...")
    response = requests.post(f"{BASE_URL}/api/v1/auth/otp/send/", json={"email": TEST_EMAIL})
    print(f"Response: {response.status_code} - {response.text}")
    
    if response.status_code != 200:
        print("Failed to request OTP")
        return

    # 3. Get OTP from DB
    otp_record = AuthOTP.objects.filter(identifier=TEST_EMAIL, is_used=False).order_by('-created_at').first()
    if not otp_record:
        print("No OTP record found in DB")
        return
    
    print(f"Found OTP in DB: {otp_record.otp}")
    
    # 4. Verify OTP
    print("Verifying OTP...")
    response = requests.post(f"{BASE_URL}/api/v1/auth/otp/login/", json={
        "email": TEST_EMAIL,
        "otp": otp_record.otp
    })
    print(f"Response: {response.status_code}")
    if response.status_code == 200:
        data = response.json()
        print("SUCCESS: Login successful")
        print(f"Access Token: {data['access'][:20]}...")
    else:
        print(f"FAILURE: {response.text}")

def test_enrollment_contact_otp():
    print(f"\n--- Testing Contact OTP (Enrollment) for {TEST_EMAIL} ---")
    
    # 1. Request OTP
    print("Requesting Contact OTP...")
    response = requests.post(f"{BASE_URL}/api/v1/payments/contact-otp/send/", json={
        "contact": TEST_EMAIL,
        "contact_type": "email"
    })
    print(f"Response: {response.status_code} - {response.text}")
    
    if response.status_code != 200:
        # Check if it's rate limited
        if response.status_code == 429:
            print("Rate limited. Skipping wait and fetching last OTP from DB anyway.")
        else:
            print("Failed to request Contact OTP")
            return

    # 2. Get OTP from DB
    otp_record = ContactVerificationOTP.objects.filter(contact=TEST_EMAIL, verified=False, is_valid=True).order_by('-created_at').first()
    if not otp_record:
        print("No Contact OTP record found in DB")
        return
    
    print(f"Found Contact OTP in DB: {otp_record.otp}")
    
    # 3. Verify OTP
    print("Verifying Contact OTP...")
    response = requests.post(f"{BASE_URL}/api/v1/payments/contact-otp/verify/", json={
        "contact": TEST_EMAIL,
        "contact_type": "email",
        "otp": otp_record.otp
    })
    print(f"Response: {response.status_code}")
    if response.status_code == 200:
        print("SUCCESS: Contact verification successful")
    else:
        print(f"FAILURE: {response.text}")

if __name__ == "__main__":
    try:
        test_auth_otp()
        test_enrollment_contact_otp()
    except Exception as e:
        print(f"Error during testing: {e}")
