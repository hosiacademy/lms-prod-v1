#!/usr/bin/env python
"""
Sentry Integration Test Script
Tests all Sentry tracking functionality

Run: docker compose exec backend python test_sentry_integration.py
"""

import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from django.conf import settings
from apps.payments.services.sentry_service import sentry_monitor, SENTRY_AVAILABLE
from apps.payments.models import PaymentTransaction
from django.contrib.auth import get_user_model

User = get_user_model()


def test_sentry_configuration():
    """Test 1: Sentry configuration"""
    print("\n" + "="*70)
    print("TEST 1: Sentry Configuration")
    print("="*70)

    print(f"\nSentry SDK installed: {SENTRY_AVAILABLE}")
    print(f"Sentry DSN configured: {bool(getattr(settings, 'SENTRY_DSN', None))}")
    print(f"Sentry enabled: {getattr(settings, 'SENTRY_ENABLED', False)}")
    print(f"DEBUG mode: {settings.DEBUG}")

    if hasattr(settings, 'SENTRY_DSN') and settings.SENTRY_DSN:
        dsn = settings.SENTRY_DSN
        print(f"DSN: {dsn[:30]}... (truncated for security)")

    if SENTRY_AVAILABLE and settings.SENTRY_DSN:
        print("\n✅ PASS: Sentry is configured")
        return True
    else:
        print("\n⚠️  WARNING: Sentry not configured")
        print("   Add SENTRY_DSN to your .env file")
        return False


def test_sentry_connection():
    """Test 2: Sentry connection"""
    print("\n" + "="*70)
    print("TEST 2: Sentry Connection")
    print("="*70)

    if not SENTRY_AVAILABLE:
        print("⏭️  SKIPPED: Sentry SDK not available")
        return False

    try:
        import sentry_sdk

        # Send test message
        event_id = sentry_sdk.capture_message(
            "🧪 Sentry test message from LMS",
            level='info'
        )

        if event_id:
            print(f"\n✅ PASS: Test message sent to Sentry")
            print(f"   Event ID: {event_id}")
            print(f"   Check: https://sentry.io/ → Issues")
            return True
        else:
            print("\n❌ FAIL: No event ID returned")
            return False

    except Exception as e:
        print(f"\n❌ FAIL: Error sending to Sentry: {e}")
        return False


def test_exception_capture():
    """Test 3: Exception capture"""
    print("\n" + "="*70)
    print("TEST 3: Exception Capture")
    print("="*70)

    if not SENTRY_AVAILABLE:
        print("⏭️  SKIPPED: Sentry SDK not available")
        return False

    try:
        import sentry_sdk

        # Trigger and capture test exception
        try:
            result = 1 / 0
        except ZeroDivisionError as e:
            event_id = sentry_sdk.capture_exception(e)

        if event_id:
            print(f"\n✅ PASS: Exception captured")
            print(f"   Event ID: {event_id}")
            print(f"   Check Sentry dashboard for details")
            return True
        else:
            print("\n❌ FAIL: Exception not captured")
            return False

    except Exception as e:
        print(f"\n❌ FAIL: Error capturing exception: {e}")
        return False


def test_payment_tracking():
    """Test 4: Payment tracking"""
    print("\n" + "="*70)
    print("TEST 4: Payment Tracking")
    print("="*70)

    if not sentry_monitor.enabled:
        print("⚠️  WARNING: Sentry monitor not enabled")
        print("   Tracking will not work until Sentry is configured")
        return False

    # Get or create test transaction
    try:
        transaction = PaymentTransaction.objects.first()

        if not transaction:
            print("ℹ️  INFO: No transactions found")
            print("   Create a test payment to verify tracking")
            return True

        print(f"\nUsing transaction: {transaction.id}")
        print(f"Amount: {transaction.amount} {transaction.currency}")
        print(f"Status: {transaction.status}")

        # Test tracking methods
        print("\nTesting tracking methods...")

        # 1. Track initiation
        sentry_monitor.track_payment_initiation(transaction)
        print("   ✓ track_payment_initiation()")

        # 2. Track success
        sentry_monitor.track_payment_success(transaction)
        print("   ✓ track_payment_success()")

        # 3. Track failure
        sentry_monitor.track_payment_failure(transaction, "Test failure")
        print("   ✓ track_payment_failure()")

        # 4. Track webhook
        sentry_monitor.track_webhook_received(
            provider=transaction.provider,
            event_type='test.event',
            payload={'test': True}
        )
        print("   ✓ track_webhook_received()")

        print("\n✅ PASS: All payment tracking methods work")
        print("   Check Sentry → Issues → Search for 'payment'")
        return True

    except Exception as e:
        print(f"\n❌ FAIL: Error in payment tracking: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_notification_tracking():
    """Test 5: Notification tracking"""
    print("\n" + "="*70)
    print("TEST 5: Notification Tracking")
    print("="*70)

    if not sentry_monitor.enabled:
        print("⏭️  SKIPPED: Sentry monitor not enabled")
        return False

    try:
        # Test SMS tracking
        sentry_monitor.track_sms_sent(
            transaction_id='test-123',
            phone_number='+27123456789',
            success=True
        )
        print("   ✓ track_sms_sent() - success")

        sentry_monitor.track_sms_sent(
            transaction_id='test-456',
            phone_number='+27987654321',
            success=False,
            error='Test error'
        )
        print("   ✓ track_sms_sent() - failure")

        # Test email tracking
        sentry_monitor.track_email_sent(
            transaction_id='test-123',
            email='test@example.com',
            success=True
        )
        print("   ✓ track_email_sent() - success")

        sentry_monitor.track_email_sent(
            transaction_id='test-456',
            email='test@example.com',
            success=False,
            error='SMTP error'
        )
        print("   ✓ track_email_sent() - failure")

        print("\n✅ PASS: All notification tracking methods work")
        print("   Check Sentry → Search for 'SMS' or 'Email'")
        return True

    except Exception as e:
        print(f"\n❌ FAIL: Error in notification tracking: {e}")
        return False


def test_context_and_tags():
    """Test 6: Context and tags"""
    print("\n" + "="*70)
    print("TEST 6: Context and Tags")
    print("="*70)

    if not SENTRY_AVAILABLE:
        print("⏭️  SKIPPED: Sentry SDK not available")
        return False

    try:
        import sentry_sdk
        from sentry_sdk import set_context, set_tag, set_user

        # Set custom context
        set_context('test_context', {
            'feature': 'payment_tracking',
            'test_type': 'integration',
            'version': '1.0.0'
        })
        print("   ✓ set_context()")

        # Set tags
        set_tag('payment.provider', 'test_provider')
        set_tag('payment.currency', 'ZAR')
        set_tag('test', 'true')
        print("   ✓ set_tag()")

        # Set user
        set_user({
            'id': 'test-user-123',
            'email': 'test@example.com',
            'username': 'testuser'
        })
        print("   ✓ set_user()")

        # Send event with all context
        sentry_sdk.capture_message(
            "Test message with context and tags",
            level='info'
        )

        print("\n✅ PASS: Context and tags set successfully")
        print("   Check Sentry event details for custom data")
        return True

    except Exception as e:
        print(f"\n❌ FAIL: Error setting context/tags: {e}")
        return False


def test_breadcrumbs():
    """Test 7: Breadcrumbs"""
    print("\n" + "="*70)
    print("TEST 7: Breadcrumbs")
    print("="*70)

    if not SENTRY_AVAILABLE:
        print("⏭️  SKIPPED: Sentry SDK not available")
        return False

    try:
        import sentry_sdk

        # Add breadcrumbs
        sentry_sdk.add_breadcrumb(
            category='test',
            message='Step 1: Initialize test',
            level='info'
        )
        print("   ✓ Breadcrumb 1 added")

        sentry_sdk.add_breadcrumb(
            category='test',
            message='Step 2: Process payment',
            level='info',
            data={'amount': 100.00}
        )
        print("   ✓ Breadcrumb 2 added")

        sentry_sdk.add_breadcrumb(
            category='test',
            message='Step 3: Send notification',
            level='info'
        )
        print("   ✓ Breadcrumb 3 added")

        # Trigger event to show breadcrumbs
        sentry_sdk.capture_message(
            "Test message with breadcrumbs",
            level='info'
        )

        print("\n✅ PASS: Breadcrumbs added successfully")
        print("   Check Sentry event → Breadcrumbs section")
        return True

    except Exception as e:
        print(f"\n❌ FAIL: Error adding breadcrumbs: {e}")
        return False


def test_performance_transaction():
    """Test 8: Performance transaction"""
    print("\n" + "="*70)
    print("TEST 8: Performance Transaction")
    print("="*70)

    if not SENTRY_AVAILABLE:
        print("⏭️  SKIPPED: Sentry SDK not available")
        return False

    try:
        import sentry_sdk
        import time

        # Start transaction
        with sentry_sdk.start_transaction(
            op="test",
            name="test_payment_operation"
        ) as transaction:

            # Simulate work with spans
            with sentry_sdk.start_span(op="db", description="Query database"):
                time.sleep(0.1)  # Simulate DB query

            with sentry_sdk.start_span(op="http", description="Call payment API"):
                time.sleep(0.2)  # Simulate API call

            with sentry_sdk.start_span(op="task", description="Send SMS"):
                time.sleep(0.05)  # Simulate SMS sending

            transaction.set_status("ok")

        print("\n✅ PASS: Performance transaction recorded")
        print("   Check Sentry → Performance tab")
        return True

    except Exception as e:
        print(f"\n❌ FAIL: Error in performance tracking: {e}")
        return False


def test_custom_exception_with_context():
    """Test 9: Custom exception with full context"""
    print("\n" + "="*70)
    print("TEST 9: Custom Exception with Context")
    print("="*70)

    if not sentry_monitor.enabled:
        print("⏭️  SKIPPED: Sentry monitor not enabled")
        return False

    try:
        # Get test transaction
        transaction = PaymentTransaction.objects.first()

        if not transaction:
            print("ℹ️  INFO: No transaction available for testing")
            return True

        # Create test exception
        try:
            raise ValueError("Test payment processing error")
        except ValueError as e:
            # Capture with full context
            sentry_monitor.capture_payment_exception(
                exception=e,
                transaction=transaction,
                context={
                    'test': True,
                    'operation': 'payment_processing',
                    'step': 'verification',
                    'provider_response': {'status': 'failed'}
                }
            )

        print("\n✅ PASS: Exception captured with custom context")
        print("   Check Sentry → Issues → View exception details")
        print("   Look for 'transaction' and 'custom' context")
        return True

    except Exception as e:
        print(f"\n❌ FAIL: Error capturing exception: {e}")
        return False


def run_all_tests():
    """Run all Sentry tests"""
    print("\n" + "="*70)
    print("🔍 SENTRY INTEGRATION - TEST SUITE")
    print("="*70)

    tests = [
        ("Configuration", test_sentry_configuration),
        ("Connection", test_sentry_connection),
        ("Exception Capture", test_exception_capture),
        ("Payment Tracking", test_payment_tracking),
        ("Notification Tracking", test_notification_tracking),
        ("Context & Tags", test_context_and_tags),
        ("Breadcrumbs", test_breadcrumbs),
        ("Performance Transaction", test_performance_transaction),
        ("Custom Exception", test_custom_exception_with_context),
    ]

    results = []
    for name, test_func in tests:
        try:
            passed = test_func()
            results.append((name, passed))
        except Exception as e:
            print(f"\n❌ ERROR in {name}: {e}")
            import traceback
            traceback.print_exc()
            results.append((name, False))

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
        print("\n🎉 ALL TESTS PASSED!")
        print("\nNext Steps:")
        print("1. Check Sentry dashboard: https://sentry.io/")
        print("2. Look for test events in Issues tab")
        print("3. Check Performance tab for transactions")
        print("4. Set up alerts for production")
    else:
        print("\n⚠️  Some tests failed.")
        print("\nTroubleshooting:")
        print("1. Ensure SENTRY_DSN is set in .env")
        print("2. Check Sentry is enabled: SENTRY_ENABLED=True")
        print("3. If DEBUG=True, set SENTRY_DEBUG_MODE=True")
        print("4. Check network connectivity to sentry.io")

    print("="*70 + "\n")

    # Final instructions
    if SENTRY_AVAILABLE and settings.SENTRY_DSN:
        print("🔗 View Results:")
        print(f"   Dashboard: https://sentry.io/")
        print(f"   Environment: {settings.ENVIRONMENT}")
        print(f"   Look for events from the last few minutes")
        print()


if __name__ == '__main__':
    run_all_tests()
