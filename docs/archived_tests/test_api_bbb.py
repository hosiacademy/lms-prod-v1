import requests
import json
import sys

# 1. Login to get token
login_url = "http://127.0.0.1:8000/api/v1/auth/login/"
login_data = {
    "email": "takawira.mazando@hosiacademy.co.za",
    "password": "Instructor@2026!"
}

session = requests.Session()
response = session.post(login_url, json=login_data)

if response.status_code != 200:
    print(f"Login failed: {response.status_code} {response.text}")
    sys.exit(1)

tokens = response.json()
access_token = tokens.get("access", tokens.get("token"))

if not access_token:
    print(f"No access token found in response: {tokens}")
    sys.exit(1)

# 2. Call my_sessions
headers = {
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}

bbb_url = "http://127.0.0.1:8000/api/v1/bbb/sessions/my_sessions/"
bbb_response = session.get(bbb_url, headers=headers)

print(f"Status Code: {bbb_response.status_code}")
try:
    print(json.dumps(bbb_response.json(), indent=2))
except Exception as e:
    print(f"Failed to parse JSON: {e}")
    print(bbb_response.text)
