import requests
import time
import re
import os
import sys

BASE_URL = "http://127.0.0.1:8000/api/v1"
TEST_EMAIL = "instructor.za@hosiacademy.com"
TEST_PASSWORD = "SecurePassword123!"

def setup_test_user():
    pass

def test_password_login():
    print(f"\n--- Testing Password Login ---")
    res = requests.post(f"{BASE_URL}/auth/login/", json={
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD
    })
    
    if res.status_code == 200 and "access" in res.json():
        print("OK: Password login SUCCESS")
        return True
    else:
        print(f"FAIL: Password login FAILED: {res.status_code} {res.text}")
        return False

def test_otp_flow():
    print(f"\n--- Testing OTP Flow ---")
    print(f"1. Requesting OTP for {TEST_EMAIL}...")
    
    endpoints_to_try = [
        f"{BASE_URL}/auth/otp/send/", 
    ]
    
    sent = False
    for ep in endpoints_to_try:
        res = requests.post(ep, json={"email": TEST_EMAIL, "identifier": TEST_EMAIL})
        if res.status_code == 200:
            print(f"OK: OTP Requested successfully via {ep}")
            sent = True
            break
        else:
            print(f"WARN: Failed via {ep}: {res.status_code} {res.text}")
            
    if not sent:
        print("FAIL: Could not request OTP")
        return False
        
    print("2. Reading OTP from server.log...")
    time.sleep(2) 
    
    try:
        with open("server.log", "r", encoding="utf-16le") as f:
            log_content = f.read()
    except Exception as e:
        print(f"FAIL: Failed to read server.log: {e}")
        return False
        
    matches = re.findall(r'OTP for.*?(\d{6})', log_content)
    if not matches:
        print("FAIL: Could not find OTP in logs. Ensure DEBUG=True and console backend is active.")
        return False
        
    otp = matches[-1] 
    print(f"OK: Found OTP in logs: {otp}")
    
    print(f"3. Verifying OTP...")
    endpoints_to_try = [
        f"{BASE_URL}/auth/otp/login/",
    ]
    
    verified = False
    for ep in endpoints_to_try:
        res = requests.post(ep, json={"email": TEST_EMAIL, "identifier": TEST_EMAIL, "otp": otp})
        if res.status_code == 200 and "access" in res.json():
            print(f"OK: OTP Login SUCCESS via {ep}")
            verified = True
            break
        else:
            print(f"WARN: Failed via {ep}: {res.status_code} {res.text}")
            
    if not verified:
        print("FAIL: OTP Login FAILED")
        return False
        
    return True

if __name__ == "__main__":
    setup_test_user()
    test_password_login()
    test_otp_flow()
