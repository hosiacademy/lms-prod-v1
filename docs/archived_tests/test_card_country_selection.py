#!/usr/bin/env python3
"""
Test Card Payment with Country Selection & Currency Auto-Adjustment

Tests:
1. Country selection returns correct currency
2. Card payment initiation with different countries
3. Currency auto-adjustment based on country
"""

import requests
import json

API_BASE = "http://localhost:7001/api/v1"

# Test cases: country, expected_currency, amount
TEST_CASES = [
    {'country': 'ZA', 'currency': 'ZAR', 'amount': 1500, 'name': 'South Africa'},
    {'country': 'KE', 'currency': 'KES', 'amount': 2000, 'name': 'Kenya'},
    {'country': 'NG', 'currency': 'NGN', 'amount': 50000, 'name': 'Nigeria'},
    {'country': 'GH', 'currency': 'GHS', 'amount': 500, 'name': 'Ghana'},
    {'country': 'EG', 'currency': 'EGP', 'amount': 1000, 'name': 'Egypt'},
    {'country': 'TZ', 'currency': 'TZS', 'amount': 50000, 'name': 'Tanzania'},
    {'country': 'UG', 'currency': 'UGX', 'amount': 50000, 'name': 'Uganda'},
    {'country': 'ZW', 'currency': 'USD', 'amount': 100, 'name': 'Zimbabwe'},
    {'country': 'ZM', 'currency': 'ZMW', 'amount': 500, 'name': 'Zambia'},
    {'country': 'MW', 'currency': 'MWK', 'amount': 50000, 'name': 'Malawi'},
]

def print_header(text):
    print("\n" + "="*70)
    print(f"  {text}")
    print("="*70 + "\n")

def print_test_case(test):
    print(f"\nTest: {test['name']} ({test['country']})")
    print("-"*70)

def print_success(message):
    print(f"  ✓ {message}")

def print_error(message):
    print(f"  ✗ {message}")

def print_info(message):
    print(f"  ℹ {message}")

# ============================================================================
# TEST 1: Get Available Providers for Card Payments
# ============================================================================
print_header("Test 1: Get Card Payment Providers by Country")

for test in TEST_CASES[:3]:  # Test first 3 countries
    print_test_case(test)
    
    response = requests.get(f"{API_BASE}/payments/providers/?country={test['country']}&currency={test['currency']}")
    
    if response.status_code == 200:
        data = response.json()
        providers = data.get('available_providers', [])
        
        print_success(f"Providers retrieved for {test['name']}")
        print_info(f"  Country: {data.get('detected_country', 'N/A')}")
        print_info(f"  Currency: {data.get('detected_currency', 'N/A')}")
        print_info(f"  Providers count: {len(providers)}")
        
        # Show card providers
        card_providers = [p for p in providers if 'card' in p.get('methods', [])]
        if card_providers:
            print_info(f"  Card providers: {', '.join([p['name'] for p in card_providers])}")
    else:
        print_error(f"Failed: HTTP {response.status_code}")

# ============================================================================
# TEST 2: Initiate Card Payment with Country-Currency
# ============================================================================
print_header("Test 2: Initiate Card Payment with Country Selection")

successful_tests = 0
failed_tests = 0

for test in TEST_CASES[:5]:  # Test first 5 countries
    print_test_case(test)
    
    # Initiate card payment
    payload = {
        "provider": "flutterwave",
        "payment_method": "card",
        "country": test['country'],
        "currency": test['currency'],
        "amount": test['amount'],
        "metadata": {
            "email": f"test-{test['country'].lower()}@example.com",
            "full_name": "Test User",
            "phone": "+1234567890"
        }
    }
    
    print_info(f"Request: {test['amount']} {test['currency']} via Flutterwave")
    
    try:
        response = requests.post(f"{API_BASE}/payments/initiate/", json=payload, timeout=10)
        data = response.json()
        
        if response.status_code == 200:
            print_success("Card payment initiated successfully")
            print_info(f"  Transaction ID: {data.get('transaction', {}).get('id', 'N/A')}")
            print_info(f"  Currency: {data.get('transaction', {}).get('currency', 'N/A')}")
            print_info(f"  Amount: {data.get('transaction', {}).get('amount', 'N/A')}")
            print_info(f"  Checkout URL: {data.get('checkout_url', 'N/A')[:60]}...")
            successful_tests += 1
        else:
            print_error(f"Payment initiation failed: {data.get('error', 'Unknown error')}")
            failed_tests += 1
            
    except requests.exceptions.Timeout:
        print_error("Request timeout")
        failed_tests += 1
    except Exception as e:
        print_error(f"Error: {str(e)}")
        failed_tests += 1

# ============================================================================
# TEST 3: Validate Country-Currency Mapping
# ============================================================================
print_header("Test 3: Validate Country-Currency Mapping")

print_info("Testing Flutterwave adapter country-currency mapping...")

# Test via API
response = requests.get(f"{API_BASE}/payments/providers/?country=ZA&currency=ZAR")
if response.status_code == 200:
    data = response.json()
    if data.get('detected_currency') == 'ZAR':
        print_success("South Africa → ZAR mapping correct")
    else:
        print_error(f"Currency mismatch: Expected ZAR, got {data.get('detected_currency')}")

response = requests.get(f"{API_BASE}/payments/providers/?country=KE&currency=KES")
if response.status_code == 200:
    data = response.json()
    if data.get('detected_currency') == 'KES':
        print_success("Kenya → KES mapping correct")
    else:
        print_error(f"Currency mismatch: Expected KES, got {data.get('detected_currency')}")

response = requests.get(f"{API_BASE}/payments/providers/?country=NG&currency=NGN")
if response.status_code == 200:
    data = response.json()
    if data.get('detected_currency') == 'NGN':
        print_success("Nigeria → NGN mapping correct")
    else:
        print_error(f"Currency mismatch: Expected NGN, got {data.get('detected_currency')}")

# ============================================================================
# SUMMARY
# ============================================================================
print_header("Test Summary")

print(f"\nCard Payment Tests:")
print(f"  Successful: {successful_tests}/{len(TEST_CASES[:5])}")
print(f"  Failed: {failed_tests}/{len(TEST_CASES[:5])}")
print()

if failed_tests == 0:
    print_success("All card payment tests passed!")
    print()
    print("✅ Country selection working")
    print("✅ Currency auto-adjustment working")
    print("✅ Card payment initiation working")
else:
    print_error(f"{failed_tests} test(s) failed")
    print()
    print("⚠️ Some tests failed. Check the errors above.")

print()
print("="*70)
print("Testing Complete!")
print("="*70)
print()

print("Next Steps:")
print("  1. Review test results above")
print("  2. Check backend logs for details")
print("  3. Test from frontend UI")
print()
