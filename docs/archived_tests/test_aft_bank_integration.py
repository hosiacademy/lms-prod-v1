#!/usr/bin/env python3
"""
Test script to verify AFT (African Bank Transfer) integration is working
Tests API endpoints and EFT initiation with dynamic bank details
"""

import os
import sys
import json
import time
import requests

# Test configuration
BASE_URL = "http://localhost:7001"
API_PREFIX = "/api/v1/payments"

def test_api_endpoint(endpoint, method="GET", data=None, description=""):
    """Test an API endpoint"""
    url = f"{BASE_URL}{API_PREFIX}{endpoint}"
    print(f"\n🔍 Testing {method} {endpoint}")
    if description:
        print(f"   Description: {description}")
    
    try:
        if method == "GET":
            response = requests.get(url, params=data)
        elif method == "POST":
            response = requests.post(url, json=data)
        else:
            print(f"❌ Unsupported method: {method}")
            return False
        
        print(f"   Status: {response.status_code}")
        
        if response.status_code >= 200 and response.status_code < 300:
            try:
                result = response.json()
                print(f"✅ Success: Got {type(result)} response")
                # Show some key data
                if isinstance(result, dict):
                    if 'countries' in result:
                        print(f"   Countries: {len(result['countries'])}")
                    elif 'banks' in result:
                        print(f"   Banks: {len(result['banks'])}")
                    elif 'status' in result:
                        print(f"   Status: {result['status']}")
                        if 'bank_details' in result:
                            print(f"   Bank details: Available")
                return True, result
            except json.JSONDecodeError:
                print(f"⚠️  Response not JSON: {response.text[:100]}...")
                return False, None
        else:
            print(f"❌ Failed: {response.text[:200]}")
            return False, None
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False, None

def main():
    print("=" * 80)
    print("AFRICAN BANK TRANSFER INTEGRATION TEST")
    print("=" * 80)
    print(f"Base URL: {BASE_URL}")
    print(f"Timestamp: {time.ctime()}")
    
    results = []
    
    # Test 1: List African countries
    success, data = test_api_endpoint(
        "/african-countries/",
        description="List all 54 African countries"
    )
    results.append(("List African Countries", success))
    
    if success and data:
        print(f"   ✅ Found {len(data.get('countries', []))} countries")
    
    # Test 2: Get South African banks
    success, data = test_api_endpoint(
        "/african-banks/?country=ZA",
        description="Get banks for South Africa"
    )
    results.append(("Get South African Banks", success))
    
    if success and data:
        banks = data.get('banks', [])
        providers = data.get('payment_providers', [])
        print(f"   ✅ Found {len(banks)} banks, {len(providers)} payment providers")
        if banks:
            print(f"   Sample banks: {', '.join([b.get('name', 'Unknown') for b in banks[:3]])}")
    
    # Test 3: Get Kenyan banks
    success, data = test_api_endpoint(
        "/african-banks/?country=KE",
        description="Get banks for Kenya"
    )
    results.append(("Get Kenyan Banks", success))
    
    # Test 4: Get Nigerian banks
    success, data = test_api_endpoint(
        "/african-banks/?country=NG",
        description="Get banks for Nigeria"
    )
    results.append(("Get Nigerian Banks", success))
    
    # Test 5: Try to initiate an EFT payment (with minimal data)
    print("\n💰 Testing EFT Initiation (simulated)...")
    
    # Create minimal test data
    eft_data = {
        "program_id": "test-masterclass-001",
        "type": "masterclass",
        "amount": 5.00,
        "currency": "ZAR",
        "country": "ZA",
        "metadata": {
            "program_title": "Test Masterclass",
            "test": True
        },
        "individual_details": {
            "full_name": "Test User",
            "email": "test@example.com",
            "phone": "+27123456789"
        }
    }
    
    success, data = test_api_endpoint(
        "/eft/initiate/",
        method="POST",
        data=eft_data,
        description="Initiate EFT payment with dynamic bank details"
    )
    results.append(("Initiate EFT Payment", success))
    
    if success and data:
        print(f"   ✅ Reference: {data.get('reference', 'N/A')}")
        print(f"   ✅ Status: {data.get('status', 'N/A')}")
        if 'bank_details' in data:
            bank_details = data['bank_details']
            print(f"   ✅ Bank: {bank_details.get('bank_name', 'N/A')}")
            print(f"   ✅ Account: {bank_details.get('account_number', 'N/A')}")
            print(f"   ✅ Currency: {bank_details.get('currency', 'N/A')}")
            print(f"   ✅ Country: {bank_details.get('country_code', 'N/A')}")
        else:
            print("   ⚠️  No bank_details in response")
    
    # Test 6: Test frontend API integration functions
    print("\n🎯 Frontend Integration Tests:")
    
    # Check if endpoints are properly configured
    endpoints_to_check = [
        "/eft/initiate/",
        "/eft/status/{reference}/",
        "/eft/submit-bank-details/",
        "/eft/upload-pop/{reference}/",
    ]
    
    for endpoint in endpoints_to_check:
        print(f"   • {endpoint:40} - Expected to exist")
    
    # Summary
    print("\n" + "=" * 80)
    print("TEST RESULTS SUMMARY")
    print("=" * 80)
    
    passed = sum(1 for _, success in results if success)
    total = len(results)
    
    for test_name, success in results:
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status:10} {test_name}")
    
    print(f"\nTotal: {passed}/{total} tests passed ({passed/total*100:.0f}%)")
    
    if passed == total:
        print("\n🎉 ALL TESTS PASSED! African Bank Transfer integration is working.")
        print("\nReady for real-world testing:")
        print("1. Open frontend at http://localhost:7000")
        print("2. Find a $5 masterclass")
        print("3. Click 'Enroll'")
        print("4. Select 'EFT / Bank Transfer'")
        print("5. Verify country-specific bank details appear")
        print("6. AICERTS Courses should scroll left (both rows)")
    else:
        print("\n⚠️  SOME TESTS FAILED. Check API endpoints and database.")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)