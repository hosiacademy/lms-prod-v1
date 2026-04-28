
import requests
import subprocess
import json
import time

BASE_URL = "http://127.0.0.1:7001"
TEST_EMAIL = "hosimonorepo@gmail.com"

import re

def get_auth_otp():
    cmd = f'.\\venv_windows\\Scripts\\python.exe manage.py shell -c "from apps.users.models import AuthOTP; print(AuthOTP.objects.filter(identifier=\'{TEST_EMAIL}\').latest(\'created_at\').otp)"'
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        match = re.search(r'\b(\d{6})\b', result.stdout)
        if match:
            return match.group(1)
    return None

def get_contact_otp():
    cmd = f'.\\venv_windows\\Scripts\\python.exe manage.py shell -c "from apps.payments.models import ContactVerificationOTP; print(ContactVerificationOTP.objects.filter(contact=\'{TEST_EMAIL}\').latest(\'created_at\').otp)"'
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        match = re.search(r'\b(\d{6})\b', result.stdout)
        if match:
            return match.group(1)
    return None

def test_auth_flow():
    print(f"\n[1] TESTING AUTH OTP (LOGIN) for {TEST_EMAIL}")
    
    # 1. Send OTP
    print("Sending OTP...")
    resp = requests.post(f"{BASE_URL}/api/v1/auth/otp/send/", json={"email": TEST_EMAIL})
    print(f"Send Resp: {resp.status_code}")
    if resp.status_code != 200:
        print(f"FAILED: {resp.text[:500]}")
        return

    otp = get_auth_otp()
    print(f"Retrieved OTP: {otp}")
    if not otp:
        print("FAILED: Could not retrieve OTP from DB")
        return

    print("Verifying OTP...")
    resp = requests.post(f"{BASE_URL}/api/v1/auth/otp/login/", json={"email": TEST_EMAIL, "otp": otp})
    print(f"Verify Resp: {resp.status_code}")
    if resp.status_code == 200:
        print("SUCCESS: Auth OTP verified.")
        print(f"Token: {resp.json().get('access')[:20]}...")
    else:
        print(f"FAILED: {resp.text[:500]}")

def test_enrollment_flow():
    print(f"\n[2] TESTING ENROLLMENT OTP (CONTACT VERIFICATION) for {TEST_EMAIL}")
    
    # 1. Send OTP
    print("Sending Contact OTP...")
    resp = requests.post(f"{BASE_URL}/api/v1/payments/contact-otp/send/", json={
        "contact": TEST_EMAIL,
        "contact_type": "email"
    })
    print(f"Send Resp: {resp.status_code}")
    
    if resp.status_code != 200:
        print(f"Note: {resp.text}")
    
    # 2. Fetch OTP from DB
    otp = get_contact_otp()
    if not otp:
        print("FAILED: Could not retrieve Contact OTP from DB")
        return
    print(f"Retrieved OTP: {otp}")
    
    # 3. Verify OTP
    print("Verifying Contact OTP...")
    resp = requests.post(f"{BASE_URL}/api/v1/payments/contact-otp/verify/", json={
        "contact": TEST_EMAIL,
        "contact_type": "email",
        "otp": otp
    })
    print(f"Verify Resp: {resp.status_code}")
    if resp.status_code == 200:
        print("SUCCESS: Contact OTP verified.")
    else:
        print(f"FAILED: {resp.text}")

if __name__ == "__main__":
    test_auth_flow()
    test_enrollment_flow()
