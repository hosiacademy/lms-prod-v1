
import requests
import json
import subprocess
import re

BASE_URL = "http://127.0.0.1:7001"
TEST_EMAIL = "hosimonorepo@gmail.com"

def get_auth_otp():
    cmd = f'.\\venv_windows\\Scripts\\python.exe manage.py shell -c "from apps.users.models import AuthOTP; print(AuthOTP.objects.filter(identifier=\'{TEST_EMAIL}\').latest(\'created_at\').otp)"'
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode == 0:
        match = re.search(r'\b(\d{6})\b', result.stdout)
        if match:
            return match.group(1)
    return None

print(f"Testing Auth OTP send for {TEST_EMAIL}...")
resp = requests.post(f"{BASE_URL}/api/v1/auth/otp/send/", json={"email": TEST_EMAIL})
if resp.status_code != 200:
    print(f"Send failed: {resp.status_code}")
    exit()

otp = get_auth_otp()
print(f"Retrieved OTP: {otp}")

print("Testing Auth OTP login...")
resp = requests.post(f"{BASE_URL}/api/v1/auth/otp/login/", json={"email": TEST_EMAIL, "otp": otp})
print(f"Login Status: {resp.status_code}")
if resp.status_code != 200:
    with open("error_full.html", "w", encoding="utf-8") as f:
        f.write(resp.text)
    print("Full error written to error_full.html")
else:
    print("Login Success!")
