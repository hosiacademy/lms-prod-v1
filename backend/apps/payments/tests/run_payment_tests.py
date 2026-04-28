#!/usr/bin/env python3
"""
Payment Providers Test Runner

Runs all tests for the 11 payment providers:
✅ ESSENTIAL (6): Flutterwave, M-Pesa, Vodacom M-Pesa, Paynow, Fawry, Stripe
⚠️ OPTIONAL (5): Paystack, PayPal, MTN MoMo, Airtel Money, Orange Money

Usage:
    python run_payment_tests.py                    # Run all tests
    python run_payment_tests.py --provider stripe  # Run specific provider
    python run_payment_tests.py --essential        # Run essential providers only
    python run_payment_tests.py --optional         # Run optional providers only
    python run_payment_tests.py --coverage         # Run with coverage report
"""

import sys
import os
import unittest
import argparse
from datetime import datetime

# Add backend and parent directories to path
BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
PROJECT_ROOT = os.path.dirname(BACKEND_DIR)
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

print(f"Backend Dir: {BACKEND_DIR}")
print(f"Project Root: {PROJECT_ROOT}")
print(f"Python Path: {sys.path[:3]}...")

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
import django
try:
    django.setup()
    print("Django setup successful")
except Exception as e:
    print(f"Warning: Django setup failed: {e}")
    print("Tests will run but may have limited functionality")

# Import test modules
from test_all_payment_providers import (
    # Essential Providers
    TestFlutterwaveProvider,
    TestMpesaProvider,
    TestVodacomMpesaProvider,
    TestPaynowProvider,
    TestFawryProvider,
    TestStripeProvider,
    
    # Optional Providers
    TestPaystackProvider,
    TestPayPalProvider,
    TestMTNMoMoProvider,
    TestAirtelMoneyProvider,
    TestOrangeMoneyProvider,
    
    # Integration & Security
    TestPaymentProviderIntegration,
    TestPaymentSecurity,
    TestPaymentErrorHandling,
)


# ============================================================================
# TEST CONFIGURATION
# ============================================================================

ESSENTIAL_PROVIDERS = {
    'flutterwave': TestFlutterwaveProvider,
    'mpesa': TestMpesaProvider,
    'vodacom_mpesa': TestVodacomMpesaProvider,
    'paynow': TestPaynowProvider,
    'fawry': TestFawryProvider,
    'stripe': TestStripeProvider,
}

OPTIONAL_PROVIDERS = {
    'paystack': TestPaystackProvider,
    'paypal': TestPayPalProvider,
    'mtn_momo': TestMTNMoMoProvider,
    'airtel_money': TestAirtelMoneyProvider,
    'orange_money': TestOrangeMoneyProvider,
}

ALL_PROVIDERS = {**ESSENTIAL_PROVIDERS, **OPTIONAL_PROVIDERS}


# ============================================================================
# TEST RUNNER
# ============================================================================

def run_tests(providers=None, run_essential=False, run_optional=False, verbosity=2):
    """
    Run payment provider tests
    
    Args:
        providers: List of specific provider codes to test
        run_essential: Run all essential providers
        run_optional: Run all optional providers
        verbosity: Test output verbosity (1, 2, or 3)
    
    Returns:
        TestResult object
    """
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()
    
    # Determine which tests to run
    test_classes = []
    
    if providers:
        # Run specific providers
        for provider in providers:
            provider_lower = provider.lower().strip()
            if provider_lower in ALL_PROVIDERS:
                test_classes.append(ALL_PROVIDERS[provider_lower])
                print(f"✓ Added tests for: {provider_lower}")
            else:
                print(f"✗ Unknown provider: {provider_lower}")
                print(f"  Available: {', '.join(ALL_PROVIDERS.keys())}")
    
    elif run_essential:
        # Run essential providers only
        print("Running ESSENTIAL providers only (6)")
        test_classes.extend(ESSENTIAL_PROVIDERS.values())
        test_classes.append(TestPaymentProviderIntegration)
        test_classes.append(TestPaymentSecurity)
    
    elif run_optional:
        # Run optional providers only
        print("Running OPTIONAL providers only (5)")
        test_classes.extend(OPTIONAL_PROVIDERS.values())
        test_classes.append(TestPaymentProviderIntegration)
    
    else:
        # Run all providers
        print("Running ALL payment provider tests (11)")
        test_classes.extend(ALL_PROVIDERS.values())
        test_classes.append(TestPaymentProviderIntegration)
        test_classes.append(TestPaymentSecurity)
        test_classes.append(TestPaymentErrorHandling)
    
    # Add tests to suite
    for test_class in test_classes:
        tests = loader.loadTestsFromTestCase(test_class)
        suite.addTests(tests)
    
    # Run tests
    print(f"\n{'='*70}")
    print(f"Payment Provider Test Suite")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"{'='*70}\n")
    
    runner = unittest.TextTestRunner(verbosity=verbosity)
    result = runner.run(suite)
    
    # Print summary
    print(f"\n{'='*70}")
    print(f"Test Summary")
    print(f"{'='*70}")
    print(f"Total Tests:     {result.testsRun}")
    print(f"Failures:        {len(result.failures)}")
    print(f"Errors:          {len(result.errors)}")
    print(f"Skipped:         {len(result.skipped)}")
    print(f"Success Rate:    {(result.testsRun - len(result.failures) - len(result.errors)) / result.testsRun * 100:.1f}%")
    print(f"{'='*70}\n")
    
    # Print detailed failures
    if result.failures:
        print("\n❌ FAILURES:")
        for test, traceback in result.failures:
            print(f"  - {test}")
    
    if result.errors:
        print("\n❌ ERRORS:")
        for test, traceback in result.errors:
            print(f"  - {test}")
    
    if result.skipped:
        print("\n⚠️  SKIPPED:")
        for test, reason in result.skipped:
            print(f"  - {test}: {reason}")
    
    return result


# ============================================================================
# MAIN
# ============================================================================

def main():
    parser = argparse.ArgumentParser(
        description='Run payment provider tests',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python run_payment_tests.py                     # Run all tests
  python run_payment_tests.py --provider stripe   # Test Stripe only
  python run_payment_tests.py --essential         # Test 6 essential providers
  python run_payment_tests.py --optional          # Test 5 optional providers
  python run_payment_tests.py -p flutterwave mpesa  # Test multiple providers
        """
    )
    
    parser.add_argument(
        '-p', '--provider',
        nargs='+',
        help='Specific provider(s) to test'
    )
    parser.add_argument(
        '--essential',
        action='store_true',
        help='Run essential providers only (6)'
    )
    parser.add_argument(
        '--optional',
        action='store_true',
        help='Run optional providers only (5)'
    )
    parser.add_argument(
        '-v', '--verbosity',
        type=int,
        default=2,
        choices=[1, 2, 3],
        help='Verbosity level (1=quiet, 2=normal, 3=verbose)'
    )
    parser.add_argument(
        '--coverage',
        action='store_true',
        help='Run with coverage report (requires coverage package)'
    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if args.provider and (args.essential or args.optional):
        print("Error: Cannot specify both --provider and --essential/--optional")
        sys.exit(1)
    
    # Run tests
    result = run_tests(
        providers=args.provider,
        run_essential=args.essential,
        run_optional=args.optional,
        verbosity=args.verbosity,
    )
    
    # Exit with appropriate code
    if result.wasSuccessful():
        print("✅ All tests passed!")
        sys.exit(0)
    else:
        print("❌ Some tests failed")
        sys.exit(1)


if __name__ == '__main__':
    main()
