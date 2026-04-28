#!/usr/bin/env python
"""
Quick Test Script for Payment SMS System
Run in Docker container: docker compose exec backend python test_payment_sms.py
"""

import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from apps.payments.services.sms_service import sms_service, sms_template
from apps.payments.tasks import send_payment_notifications
from apps.payments.models import PaymentTransaction
from django.contrib.auth import get_user_model

User = get_user_model()


def test_sms_template():
    """Test 1: SMS template generation"""
    print("\n" + "="*60)
    print("TEST 1: SMS Template Generation")
    print("="*60)

    message = sms_template.payment_success(
        amount=150.00,
        currency='ZAR',
        reference='TXN123456',
        description='Python Mastery Course'
    )

    print("\nGenerated SMS Message:")
    print("-" * 40)
    print(message)
    print("-" * 40)
    print(f"Length: {len(message)} characters")

    if len(message) <= 160:
        print("✅ PASS: Message fits in single SMS")
    else:
        print("⚠️  WARNING: Message requires multiple SMS")

    return True


def test_sms_service():
    """Test 2: SMS service initialization"""
    print("\n" + "="*60)
    print("TEST 2: SMS Service Initialization")
    print("="*60)

    if sms_service.enabled:
        print("✅ PASS: Twilio service initialized")
        print(f"   Account SID: {sms_service.account_sid[:10]}...")
        print(f"   From Number: {sms_service.from_number}")
    else:
        print("❌ FAIL: Twilio service not configured")
        print("   Check your TWILIO_* environment variables")
        return False

    return True


def test_send_sms(phone_number=None):
    """Test 3: Send test SMS (optional - costs money!)"""
    print("\n" + "="*60)
    print("TEST 3: Send Test SMS")
    print("="*60)

    if not phone_number:
        print("⏭️  SKIPPED: No phone number provided")
        print("   To test SMS sending, run:")
        print('   python test_payment_sms.py --send +27123456789')
        return True

    print(f"Sending test SMS to: {phone_number}")

    message = sms_template.payment_success(
        amount=99.99,
        currency='ZAR',
        reference='TEST123',
        description='Test Payment'
    )

    result = sms_service.send_sms(
        to_number=phone_number,
        message=message
    )

    if result['success']:
        print(f"✅ PASS: SMS sent successfully")
        print(f"   Message SID: {result['message_sid']}")
        print(f"   Status: {result.get('status', 'unknown')}")
    else:
        print(f"❌ FAIL: SMS sending failed")
        print(f"   Error: {result['error']}")
        return False

    return True


def test_celery_tasks():
    """Test 4: Celery task availability"""
    print("\n" + "="*60)
    print("TEST 4: Celery Tasks")
    print("="*60)

    try:
        from celery import current_app

        # Check if tasks are registered
        tasks = current_app.tasks
        payment_tasks = [
            t for t in tasks.keys()
            if 'payment' in t.lower() and 'apps.payments' in t
        ]

        print(f"Found {len(payment_tasks)} payment-related tasks:")
        for task in payment_tasks:
            print(f"   - {task}")

        required_tasks = [
            'apps.payments.tasks.send_payment_confirmation_email',
            'apps.payments.tasks.send_payment_confirmation_sms',
            'apps.payments.tasks.send_payment_notifications',
        ]

        all_present = all(task in tasks for task in required_tasks)

        if all_present:
            print("✅ PASS: All required tasks registered")
        else:
            print("❌ FAIL: Some tasks missing")
            return False

    except Exception as e:
        print(f"❌ FAIL: Error checking tasks: {e}")
        return False

    return True


def test_user_phone_numbers():
    """Test 5: Check if users have phone numbers"""
    print("\n" + "="*60)
    print("TEST 5: User Phone Numbers")
    print("="*60)

    total_users = User.objects.count()
    users_with_phone = User.objects.exclude(
        phone_number__isnull=True
    ).exclude(phone_number='').count()

    print(f"Total users: {total_users}")
    print(f"Users with phone numbers: {users_with_phone}")
    print(f"Coverage: {users_with_phone/total_users*100:.1f}%")

    if users_with_phone > 0:
        print("✅ PASS: Some users have phone numbers")

        # Show sample
        sample_user = User.objects.exclude(
            phone_number__isnull=True
        ).exclude(phone_number='').first()

        if sample_user:
            print(f"\nSample user: {sample_user.email}")
            print(f"Phone: {sample_user.phone_number}")
    else:
        print("⚠️  WARNING: No users have phone numbers")
        print("   SMS will not be sent until users add phone numbers")

    return True


def test_payment_transaction():
    """Test 6: Check payment transactions"""
    print("\n" + "="*60)
    print("TEST 6: Payment Transactions")
    print("="*60)

    total_transactions = PaymentTransaction.objects.count()
    successful_transactions = PaymentTransaction.objects.filter(
        status='successful'
    ).count()

    print(f"Total transactions: {total_transactions}")
    print(f"Successful transactions: {successful_transactions}")

    if successful_transactions > 0:
        print("✅ PASS: Successful transactions found")

        # Show latest successful transaction
        latest = PaymentTransaction.objects.filter(
            status='successful'
        ).order_by('-completed_at').first()

        if latest:
            print(f"\nLatest successful payment:")
            print(f"   ID: {latest.id}")
            print(f"   Amount: {latest.amount} {latest.currency}")
            print(f"   User: {latest.user.email}")
            print(f"   Date: {latest.completed_at}")

            # Check if user has phone
            if hasattr(latest.user, 'phone_number') and latest.user.phone_number:
                print(f"   Phone: {latest.user.phone_number}")
                print("   ✅ This user would receive SMS")
            else:
                print("   ⚠️  No phone number - SMS would be skipped")
    else:
        print("ℹ️  INFO: No successful transactions yet")
        print("   Make a test payment to see SMS notifications")

    return True


def run_all_tests(send_sms_to=None):
    """Run all tests"""
    print("\n" + "="*70)
    print("🧪 PAYMENT SMS SYSTEM - TEST SUITE")
    print("="*70)

    tests = [
        ("SMS Template", test_sms_template),
        ("SMS Service", test_sms_service),
        ("Celery Tasks", test_celery_tasks),
        ("User Phone Numbers", test_user_phone_numbers),
        ("Payment Transactions", test_payment_transaction),
    ]

    results = []
    for name, test_func in tests:
        try:
            if test_func == test_send_sms:
                passed = test_func(send_sms_to)
            else:
                passed = test_func()
            results.append((name, passed))
        except Exception as e:
            print(f"\n❌ ERROR in {name}: {e}")
            results.append((name, False))

    # Optional: Send test SMS
    if send_sms_to:
        try:
            passed = test_send_sms(send_sms_to)
            results.append(("Send Test SMS", passed))
        except Exception as e:
            print(f"\n❌ ERROR sending SMS: {e}")
            results.append(("Send Test SMS", False))

    # Summary
    print("\n" + "="*70)
    print("📊 TEST SUMMARY")
    print("="*70)

    passed = sum(1 for _, result in results if result)
    total = len(results)

    for name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status}: {name}")

    print("\n" + "-"*70)
    print(f"Results: {passed}/{total} tests passed")

    if passed == total:
        print("🎉 ALL TESTS PASSED! System ready for deployment.")
    else:
        print("⚠️  Some tests failed. Check configuration and try again.")

    print("="*70 + "\n")


if __name__ == '__main__':
    import sys

    # Check for --send flag with phone number
    send_to = None
    if len(sys.argv) > 2 and sys.argv[1] == '--send':
        send_to = sys.argv[2]
        print(f"⚠️  WARNING: This will send a real SMS to {send_to}")
        print("This will cost money! Press Ctrl+C to cancel.\n")
        import time
        time.sleep(3)

    run_all_tests(send_to)
