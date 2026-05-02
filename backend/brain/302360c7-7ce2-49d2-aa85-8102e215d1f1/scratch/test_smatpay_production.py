import requests
import json
import sys

# Ensure UTF-8 output for emojis on Windows
if sys.platform == "win32":
    import codecs
    sys.stdout = codecs.getwriter("utf-8")(sys.stdout.detach())

BASE_URL = "http://localhost:7001/api/v1/payments/initiate/"

def test_payment(method, wallet_name):
    print(f"\n--- Testing {method} ({wallet_name}) ---")
    payload = {
        "amount": 10.0,
        "currency": "USD",
        "country": "ZW",
        "provider": "smatpay",
        "payment_method": method,
        "email": "test@hosiacademy.com",
        "metadata": {
            "training_type": "masterclass",
            "program_id": 1,
            "individual_details": {
                "full_name": "Test User",
                "email": "test@hosiacademy.com",
                "phone": "+263771234567"
            }
        }
    }
    
    try:
        response = requests.post(BASE_URL, json=payload)
        print(f"Status Code: {response.status_code}")
        try:
            data = response.json()
            print(f"Response Body: {json.dumps(data, indent=2)}")
        except:
            print(f"Response Raw: {response.text}")
            
        if response.status_code == 200:
            print(f"✅ Success!")
        else:
            print(f"❌ Failed")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    # Test Visa
    test_payment("visa", "Visa")
    # Test Mastercard
    test_payment("mastercard", "Mastercard")
    # Test ZimSwitch
    test_payment("zimswitch", "ZimSwitch")
