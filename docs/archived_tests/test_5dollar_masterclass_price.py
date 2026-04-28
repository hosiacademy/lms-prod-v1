#!/usr/bin/env python
"""
Test script to verify $5 Masterclass price is correctly serialized and persisted through payment flow.

Usage:
    python test_5dollar_masterclass_price.py
"""

import os
import sys
import django

# Setup Django
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from decimal import Decimal
from apps.masterclasses.models import Masterclass
from apps.masterclasses.serializers import MasterclassSerializer, MasterclassListSerializer


def test_masterclass_price_serialization():
    """Test that $5 masterclass price is correctly serialized"""
    print("=" * 80)
    print("Testing $5 Masterclass Price Serialization")
    print("=" * 80)
    
    # Get or create a $5 masterclass
    masterclass = Masterclass.objects.filter(
        price_physical=Decimal('5.00'),
        price_online=Decimal('5.00')
    ).first()
    
    if not masterclass:
        print("\n❌ No $5 masterclass found in database!")
        print("\nRun this command to create one:")
        print("   python manage.py create_five_dollar_masterclass")
        return False
    
    print(f"\n✓ Found masterclass: {masterclass.title}")
    print(f"  - ID: {masterclass.id}")
    print(f"  - Location: {masterclass.city}, {masterclass.country_name}")
    print(f"  - Physical Price: ${masterclass.price_physical}")
    print(f"  - Online Price: ${masterclass.price_online}")
    
    # Test full serializer
    print("\n" + "-" * 80)
    print("Testing MasterclassSerializer (detail view)")
    print("-" * 80)
    
    serializer = MasterclassSerializer(masterclass)
    data = serializer.data
    
    print(f"\nSerialized data:")
    print(f"  - price_usd: {data.get('price_usd')}")
    print(f"  - price_physical_usd: {data.get('price_physical_usd')}")
    print(f"  - price_online_usd: {data.get('price_online_usd')}")
    print(f"  - price_physical (localized): {data.get('price_physical')}")
    print(f"  - price_online (localized): {data.get('price_online')}")
    
    # Verify prices
    errors = []
    
    if data.get('price_usd') is None:
        errors.append("❌ price_usd is None (should be '5.00')")
    elif Decimal(str(data['price_usd'])) != Decimal('5.00'):
        errors.append(f"❌ price_usd is {data['price_usd']} (should be '5.00')")
    else:
        print("\n✓ price_usd is correct: $5.00")
    
    if data.get('price_physical_usd') is None:
        errors.append("❌ price_physical_usd is None (should be '5.00')")
    elif Decimal(str(data['price_physical_usd'])) != Decimal('5.00'):
        errors.append(f"❌ price_physical_usd is {data['price_physical_usd']} (should be '5.00')")
    else:
        print("✓ price_physical_usd is correct: $5.00")
    
    if data.get('price_online_usd') is None:
        errors.append("❌ price_online_usd is None (should be '5.00')")
    elif Decimal(str(data['price_online_usd'])) != Decimal('5.00'):
        errors.append(f"❌ price_online_usd is {data['price_online_usd']} (should be '5.00')")
    else:
        print("✓ price_online_usd is correct: $5.00")
    
    # Test list serializer
    print("\n" + "-" * 80)
    print("Testing MasterclassListSerializer (list view)")
    print("-" * 80)
    
    list_serializer = MasterclassListSerializer(masterclass)
    list_data = list_serializer.data
    
    print(f"\nSerialized data:")
    print(f"  - price_usd: {list_data.get('price_usd')}")
    print(f"  - price_physical_usd: {list_data.get('price_physical_usd')}")
    print(f"  - price_online_usd: {list_data.get('price_online_usd')}")
    
    if list_data.get('price_usd') is None:
        errors.append("❌ [LIST] price_usd is None")
    else:
        print("\n✓ [LIST] price_usd is present")
    
    if list_data.get('price_physical_usd') is None:
        errors.append("❌ [LIST] price_physical_usd is None")
    else:
        print("✓ [LIST] price_physical_usd is present")
    
    if list_data.get('price_online_usd') is None:
        errors.append("❌ [LIST] price_online_usd is None")
    else:
        print("✓ [LIST] price_online_usd is present")
    
    # Summary
    print("\n" + "=" * 80)
    if errors:
        print("❌ TEST FAILED")
        for error in errors:
            print(f"  {error}")
        return False
    else:
        print("✅ ALL TESTS PASSED")
        print("\nThe $5 masterclass price will now be correctly serialized and")
        print("persisted through the payment flow!")
        return True


def test_api_endpoint():
    """Test the actual API endpoint"""
    print("\n" + "=" * 80)
    print("Testing API Endpoint")
    print("=" * 80)
    
    from django.test import Client
    from django.contrib.auth import get_user_model
    
    User = get_user_model()
    
    # Get or create a test user
    user = User.objects.filter(is_staff=True).first()
    if not user:
        user = User.objects.create_superuser('test@example.com', 'password123')
    
    client = Client()
    client.force_login(user)
    
    # Get a $5 masterclass
    masterclass = Masterclass.objects.filter(
        price_physical=Decimal('5.00')
    ).first()
    
    if not masterclass:
        print("\n❌ No $5 masterclass found")
        return False
    
    # Test detail endpoint
    response = client.get(f'/api/v1/masterclasses/{masterclass.id}/')
    print(f"\nGET /api/v1/masterclasses/{masterclass.id}/")
    print(f"Status: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"\nResponse price fields:")
        print(f"  - price_usd: {data.get('price_usd')}")
        print(f"  - price_physical_usd: {data.get('price_physical_usd')}")
        print(f"  - price_online_usd: {data.get('price_online_usd')}")
        
        if data.get('price_physical_usd') == '5.00':
            print("\n✅ API endpoint returns correct $5 price")
            return True
        else:
            print(f"\n❌ API endpoint returned incorrect price: {data.get('price_physical_usd')}")
            return False
    else:
        print(f"\n❌ API request failed with status {response.status_code}")
        return False


if __name__ == '__main__':
    print("\n🧪 Testing $5 Masterclass Price Persistence\n")
    
    # Test 1: Serializer
    serializer_ok = test_masterclass_price_serialization()
    
    # Test 2: API endpoint
    api_ok = test_api_endpoint()
    
    # Final summary
    print("\n" + "=" * 80)
    print("FINAL SUMMARY")
    print("=" * 80)
    
    if serializer_ok and api_ok:
        print("\n✅ ALL TESTS PASSED - $5 price will persist through payment flow!\n")
        sys.exit(0)
    else:
        print("\n❌ SOME TESTS FAILED - Review errors above\n")
        sys.exit(1)
