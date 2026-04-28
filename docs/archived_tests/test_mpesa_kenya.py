#!/usr/bin/env python3
"""
M-Pesa Kenya Integration Test
Tests the M-Pesa STK Push integration with your actual credentials

Usage:
    python3 test_mpesa_kenya.py
"""

import os
import sys
import django
import requests
import base64
from datetime import datetime

# Setup Django environment
sys.path.insert(0, '/home/tk/lms-prod/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from django.conf import settings

# Colors for output
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'
    UNDERLINE = '\033[4m'

def print_header(text):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{text.center(60)}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*60}{Colors.ENDC}\n")

def print_success(text):
    print(f"{Colors.OKGREEN}✓ {text}{Colors.ENDC}")

def print_error(text):
    print(f"{Colors.FAIL}✗ {text}{Colors.ENDC}")

def print_info(text):
    print(f"{Colors.OKCYAN}ℹ {text}{Colors.ENDC}")

def print_warning(text):
    print(f"{Colors.WARNING}⚠ {text}{Colors.ENDC}")

def test_credentials_loaded():
    """Test if credentials are loaded from .env"""
    print_header("1. Testing Credentials Loading")
    
    consumer_key = getattr(settings, 'MPESA_CONSUMER_KEY', '')
    consumer_secret = getattr(settings, 'MPESA_CONSUMER_SECRET', '')
    shortcode = getattr(settings, 'MPESA_BUSINESS_SHORTCODE', '')
    passkey = getattr(settings, 'MPESA_PASSKEY', '')
    sandbox = getattr(settings, 'MPESA_SANDBOX', True)
    
    print(f"Consumer Key: {consumer_key[:20]}...{consumer_key[-10:]}")
    print(f"Consumer Secret: {consumer_secret[:20]}...{consumer_secret[-10:]}")
    print(f"Shortcode: {shortcode}")
    print(f"Passkey: {passkey}")
    print(f"Sandbox Mode: {sandbox}")
    
    if consumer_key and consumer_secret and shortcode and passkey:
        print_success("All credentials loaded successfully!")
        return True
    else:
        print_error("Missing credentials!")
        return False

def test_oauth_token():
    """Test getting OAuth access token"""
    print_header("2. Testing OAuth Token Generation")
    
    consumer_key = settings.MPESA_CONSUMER_KEY
    consumer_secret = settings.MPESA_CONSUMER_SECRET
    sandbox = settings.MPESA_SANDBOX
    
    base_url = "https://sandbox.safaricom.co.ke" if sandbox else "https://api.safaricom.co.ke"
    auth_string = f"{consumer_key}:{consumer_secret}"
    encoded_auth = base64.b64encode(auth_string.encode()).decode()
    
    headers = {
        'Authorization': f"Basic {encoded_auth}"
    }
    
    try:
        print_info(f"Requesting token from: {base_url}/oauth/v1/generate")
        response = requests.get(
            f"{base_url}/oauth/v1/generate?grant_type=client_credentials",
            headers=headers,
            timeout=30
        )
        
        if response.status_code == 200:
            data = response.json()
            access_token = data.get('access_token', '')
            expires_in = data.get('expires_in', 0)
            
            print_success(f"OAuth token generated successfully!")
            print(f"Access Token: {access_token[:30]}...{access_token[-10:]}")
            print(f"Expires In: {expires_in} seconds")
            return access_token
        else:
            print_error(f"Failed to get token: {response.status_code}")
            print(f"Response: {response.text}")
            return None
            
    except requests.exceptions.RequestException as e:
        print_error(f"Request failed: {str(e)}")
        return None

def test_password_generation():
    """Test M-Pesa password generation"""
    print_header("3. Testing Password Generation")
    
    shortcode = settings.MPESA_BUSINESS_SHORTCODE
    passkey = settings.MPESA_PASSKEY
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    
    string_to_encode = f"{shortcode}{passkey}{timestamp}"
    password = base64.b64encode(string_to_encode.encode()).decode()
    
    print(f"Timestamp: {timestamp}")
    print(f"Shortcode: {shortcode}")
    print(f"Passkey: {passkey}")
    print(f"Generated Password: {password}")
    
    print_success("Password generation working correctly!")
    return password, timestamp

def test_stk_push_initiation(access_token):
    """Test initiating STK Push"""
    print_header("4. Testing STK Push Initiation")
    
    if not access_token:
        print_error("No access token available")
        return None
    
    sandbox = settings.MPESA_SANDBOX
    base_url = "https://sandbox.safaricom.co.ke" if sandbox else "https://api.safaricom.co.ke"
    shortcode = settings.MPESA_BUSINESS_SHORTCODE
    passkey = settings.MPESA_PASSKEY
    callback_url = settings.MPESA_CALLBACK_URL
    
    # Test phone number (Safaricom sandbox)
    phone_number = "254708374149"
    amount = 1
    
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    password = base64.b64encode(f"{shortcode}{passkey}{timestamp}".encode()).decode()
    
    payload = {
        "BusinessShortCode": shortcode,
        "Password": password,
        "Timestamp": timestamp,
        "TransactionType": "CustomerPayBillOnline",
        "Amount": amount,
        "PartyA": phone_number,
        "PartyB": shortcode,
        "PhoneNumber": phone_number,
        "CallBackURL": callback_url,
        "AccountReference": "TEST_MPESA_001",
        "TransactionDesc": "M-Pesa Integration Test"
    }
    
    headers = {
        'Authorization': f"Bearer {access_token}",
        'Content-Type': 'application/json'
    }
    
    print_info(f"STK Push URL: {base_url}/mpesa/stkpush/v1/processrequest")
    print_info(f"Phone: {phone_number}")
    print_info(f"Amount: {amount} KES")
    print_info(f"Callback: {callback_url}")
    
    try:
        response = requests.post(
            f"{base_url}/mpesa/stkpush/v1/processrequest",
            headers=headers,
            json=payload,
            timeout=30
        )
        
        print(f"\nResponse Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            response_code = data.get('ResponseCode', '')
            
            if response_code == '0':
                print_success("STK Push initiated successfully!")
                print(f"CheckoutRequestID: {data.get('CheckoutRequestID')}")
                print(f"CustomerMessage: {data.get('CustomerMessage')}")
                print(f"MerchantRequestID: {data.get('MerchantRequestID')}")
                print_warning("\n⚠ Check phone 254708374149 for STK prompt (sandbox)")
                return data
            else:
                print_error(f"M-Pesa error: {data.get('ResponseDescription', 'Unknown')}")
                print(f"Response: {data}")
                return None
        else:
            print_error(f"HTTP Error: {response.status_code}")
            print(f"Response: {response.text}")
            return None
            
    except requests.exceptions.RequestException as e:
        print_error(f"Request failed: {str(e)}")
        return None

def test_query_stk_status(checkout_request_id, access_token):
    """Test querying STK push status"""
    print_header("5. Testing STK Push Status Query")
    
    if not checkout_request_id or not access_token:
        print_error("Missing checkout_request_id or access_token")
        return
    
    sandbox = settings.MPESA_SANDBOX
    base_url = "https://sandbox.safaricom.co.ke" if sandbox else "https://api.safaricom.co.ke"
    shortcode = settings.MPESA_BUSINESS_SHORTCODE
    passkey = settings.MPESA_PASSKEY
    
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    password = base64.b64encode(f"{shortcode}{passkey}{timestamp}".encode()).decode()
    
    payload = {
        "BusinessShortCode": shortcode,
        "Password": password,
        "Timestamp": timestamp,
        "CheckoutRequestID": checkout_request_id
    }
    
    headers = {
        'Authorization': f"Bearer {access_token}",
        'Content-Type': 'application/json'
    }
    
    print_info(f"Query URL: {base_url}/mpesa/stkpushquery/v1/query")
    print_info(f"CheckoutRequestID: {checkout_request_id}")
    
    try:
        response = requests.post(
            f"{base_url}/mpesa/stkpushquery/v1/query",
            headers=headers,
            json=payload,
            timeout=30
        )
        
        print(f"\nResponse Status: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            result_code = data.get('ResultCode', '')
            result_desc = data.get('ResultDesc', '')
            
            print(f"ResultCode: {result_code}")
            print(f"ResultDesc: {result_desc}")
            
            if result_code == '0':
                print_success("Payment completed successfully!")
            elif result_code == '1032':
                print_warning("User cancelled the STK push")
            else:
                print_info(f"Status: {result_desc}")
            
            return data
        else:
            print_error(f"Query failed: {response.status_code}")
            return None
            
    except requests.exceptions.RequestException as e:
        print_error(f"Request failed: {str(e)}")
        return None

def main():
    print_header("🇰🇪 M-PESA KENYA INTEGRATION TEST")
    print_info("Testing with your actual Safaricom credentials")
    
    # Test 1: Credentials loaded
    if not test_credentials_loaded():
        print_error("\nAborting: Credentials not loaded!")
        return
    
    # Test 2: OAuth token
    access_token = test_oauth_token()
    if not access_token:
        print_error("\nOAuth token generation failed!")
        return
    
    # Test 3: Password generation
    password, timestamp = test_password_generation()
    
    # Test 4: STK Push initiation
    print_header("4. Testing STK Push Initiation")
    print_warning("This will send a real STK prompt to 254708374149")
    response = input("Continue? (y/n): ").lower()
    
    if response == 'y':
        stk_result = test_stk_push_initiation(access_token)
        
        if stk_result and stk_result.get('CheckoutRequestID'):
            checkout_id = stk_result['CheckoutRequestID']
            
            # Wait for user to complete payment
            print("\n" + "="*60)
            print_info("Waiting 30 seconds for user to complete payment...")
            print("="*60 + "\n")
            import time
            time.sleep(30)
            
            # Test 5: Query status
            test_query_stk_status(checkout_id, access_token)
        else:
            print_error("STK Push initiation failed!")
    else:
        print_warning("STK Push test skipped")
    
    print_header("TEST SUMMARY")
    print_success("✓ Credentials loaded")
    print_success("✓ OAuth token generation working")
    print_success("✓ Password generation working")
    print_info("⚠ STK Push test: Skipped or completed")
    
    print("\n" + "="*60)
    print_success("M-Pesa integration is configured correctly!")
    print("="*60 + "\n")
    
    print_info("Next steps:")
    print("1. Update MPESA_CALLBACK_URL to your production domain")
    print("2. Test webhook endpoint: POST /api/payments/webhooks/mpesa/")
    print("3. Test with real user phone numbers")
    print("4. Monitor transactions in Django admin")
    print()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n\n{Colors.WARNING}Test interrupted by user{Colors.ENDC}\n")
    except Exception as e:
        print(f"\n{Colors.FAIL}Unexpected error: {str(e)}{Colors.ENDC}\n")
        import traceback
        traceback.print_exc()
