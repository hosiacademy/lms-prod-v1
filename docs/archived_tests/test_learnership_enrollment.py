#!/usr/bin/env python
"""
Learnership Enrollment Sandbox Test Runner

This script helps you test the complete learnership enrollment flow
with payment sandbox integration for Kenya, Zimbabwe, and South Africa.

Usage:
    python test_learnership_enrollment.py --country=KE --payment=mpesa
    python test_learnership_enrollment.py --country=ZW --payment=cash
    python test_learnership_enrollment.py --country=ZA --payment=yoco
    python test_learnership_enrollment.py --list
"""

import os
import sys
import django
import requests
from datetime import datetime, timedelta

# Setup Django environment
sys.path.insert(0, '/home/tk/lms-prod/backend')
sys.path.insert(0, '/home/tk/lms-prod')

# Use correct settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment
from apps.enrollments.models import ProvisionalEnrollment
from apps.payments.models import PaymentTransaction, ProviderCountryConfig
from apps.users.models import User

# ANSI Color Codes
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
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*80}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{text.center(80)}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*80}{Colors.ENDC}\n")


def print_success(text):
    print(f"{Colors.OKGREEN}✅ {text}{Colors.ENDC}")


def print_warning(text):
    print(f"{Colors.WARNING}⚠️  {text}{Colors.ENDC}")


def print_error(text):
    print(f"{Colors.FAIL}❌ {text}{Colors.ENDC}")


def print_info(text):
    print(f"{Colors.OKCYAN}ℹ️  {text}{Colors.ENDC}")


def list_test_scenarios():
    """List all available test scenarios"""
    print_header("LEARNERSHIP ENROLLMENT - TEST SCENARIOS")
    
    scenarios = [
        {
            'id': 1,
            'country': '🇰🇪 Kenya',
            'payment': 'M-Pesa',
            'amount': 'KES 50,000',
            'test_phone': '+254708374166',
            'pin': '1234',
            'expected': '✅ Enrollment Confirmed'
        },
        {
            'id': 2,
            'country': '🇰🇪 Kenya',
            'payment': 'Cash at Office',
            'amount': 'KES 50,000',
            'test_phone': 'N/A',
            'pin': 'N/A',
            'expected': '⏳ Provisional (14 days)'
        },
        {
            'id': 3,
            'country': '🇿🇼 Zimbabwe',
            'payment': 'EcoCash',
            'amount': 'USD 500',
            'test_phone': '+263771234567',
            'pin': '1234',
            'expected': '✅ Enrollment Confirmed'
        },
        {
            'id': 4,
            'country': '🇿🇼 Zimbabwe',
            'payment': 'Cash at Office',
            'amount': 'USD 500',
            'test_phone': 'N/A',
            'pin': 'N/A',
            'expected': '⏳ Provisional (14 days)'
        },
        {
            'id': 5,
            'country': '🇿🇦 South Africa',
            'payment': 'Yoco Card',
            'amount': 'ZAR 10,000',
            'test_phone': 'N/A',
            'pin': 'N/A',
            'expected': '✅ Enrollment Confirmed'
        },
        {
            'id': 6,
            'country': '🇿🇦 South Africa',
            'payment': 'Cash at Office',
            'amount': 'ZAR 10,000',
            'test_phone': 'N/A',
            'pin': 'N/A',
            'expected': '⏳ Provisional (14 days)'
        },
        {
            'id': 7,
            'country': '🌍 Pan-African',
            'payment': 'Flutterwave Card',
            'amount': 'USD 500',
            'test_phone': 'N/A',
            'pin': 'N/A',
            'card': '5531 8866 5214 2950',
            'expected': '✅ Enrollment Confirmed'
        }
    ]
    
    print(f"{'ID':<4} {'Country':<15} {'Payment Method':<20} {'Amount':<15} {'Test Credentials':<25} {'Expected':<25}")
    print("-" * 110)
    
    for s in scenarios:
        credentials = s.get('test_phone', 'N/A')
        if s.get('card'):
            credentials = f"Card: {s['card']}"
        elif s.get('pin'):
            credentials = f"{credentials}, PIN: {s['pin']}"
        
        print(f"{s['id']:<4} {s['country']:<15} {s['payment']:<20} {s['amount']:<15} {credentials:<25} {s['expected']:<25}")
    
    print("\n" + "="*80)
    print("\nUsage:")
    print("  python test_learnership_enrollment.py --country=KE --payment=mpesa")
    print("  python test_learnership_enrollment.py --country=ZW --payment=cash")
    print("  python test_learnership_enrollment.py --country=ZA --payment=yoco")
    print("\nManual Testing:")
    print("  1. Open browser: http://localhost:8000/learnerships")
    print("  2. Select a learnership programme")
    print("  3. Click 'Enroll Now'")
    print("  4. Follow the multi-step enrollment process")
    print("  5. Use test credentials above for payment")


def check_prerequisites():
    """Check if all prerequisites are met for testing"""
    print_header("CHECKING PREREQUISITES")
    
    all_good = True
    
    # Check 1: Learnership Programmes
    learnership_count = LearnershipProgramme.objects.filter(active=True).count()
    if learnership_count > 0:
        print_success(f"Learnership programmes available: {learnership_count}")
    else:
        print_error("No learnership programmes found!")
        print_info("Create a test learnership:")
        print("  python manage.py shell")
        print("  >>> from apps.learnerships.models import LearnershipProgramme")
        print("  >>> LearnershipProgramme.objects.create(")
        print("  ...     title='Test Learnership',")
        print("  ...     duration_months=12,")
        print("  ...     cost_usd=500,")
        print("  ...     country='KE',")
        print("  ...     active=True")
        print("  ... )")
        all_good = False
    
    # Check 2: Payment Providers
    provider_count = ProviderCountryConfig.objects.filter(is_active=True).count()
    if provider_count > 0:
        print_success(f"Payment providers configured: {provider_count}")
    else:
        print_error("No payment providers configured!")
        print_info("Run: python manage.py seed_country_providers")
        all_good = False
    
    # Check 3: Sandbox Mode
    from django.conf import settings
    sandbox_mode = getattr(settings, 'PAYMENT_SANDBOX_MODE', False)
    if sandbox_mode:
        print_success("Sandbox mode is ENABLED")
    else:
        print_warning("Sandbox mode may not be enabled")
        print_info("Check .env file: PAYMENT_SANDBOX_MODE=True")
    
    # Check 4: Backend URL
    backend_url = getattr(settings, 'SITE_URL', 'http://localhost:8000')
    print_info(f"Backend URL: {backend_url}")
    
    # Check 5: Test API endpoint
    try:
        response = requests.get(f"{backend_url}/api/v1/payments/providers/?country=KE", timeout=5)
        if response.status_code == 200:
            print_success("Backend API is accessible")
        else:
            print_warning(f"Backend API returned status: {response.status_code}")
    except Exception as e:
        print_error(f"Cannot reach backend API: {str(e)}")
        print_info("Make sure backend is running: python manage.py runserver")
        all_good = False
    
    print("\n" + "="*80)
    if all_good:
        print_success("All prerequisites met! Ready for testing.")
    else:
        print_warning("Some prerequisites missing. Please fix them before testing.")
    
    return all_good


def get_test_data(country_code):
    """Get test user data based on country"""
    test_data = {
        'KE': {
            'full_name': 'John Kamau Mwangi',
            'email': f'john.kamau+{datetime.now().strftime("%Y%m%d%H%M%S")}@test.com',
            'phone': '+254708374166',  # M-Pesa test number
            'id_number': '12345678',
            'dob': '1990-05-15',
            'gender': 'Male',
            'address': '123 Moi Avenue',
            'city': 'Nairobi',
            'county': 'Nairobi',
            'country': 'Kenya',
            'postal_code': '00100',
            'occupation': 'Software Developer',
            'employment_status': 'employed',
            'employer': 'Tech Solutions Ltd',
            'job_title': 'Junior Developer',
            'education_level': 'Bachelor\'s Degree',
            'institution': 'University of Nairobi',
            'qualification_year': '2015',
            'emergency_contact_name': 'Jane Kamau',
            'emergency_contact_phone': '+254722123456',
            'emergency_contact_relationship': 'Spouse',
            'currency': 'KES',
            'amount': 50000,
        },
        'ZW': {
            'full_name': 'Tinashe Moyo',
            'email': f'tinashe.moyo+{datetime.now().strftime("%Y%m%d%H%M%S")}@test.com',
            'phone': '+263771234567',  # EcoCash test number
            'id_number': 'ZW123456A',
            'dob': '1992-08-20',
            'gender': 'Female',
            'address': '45 Samora Machel Avenue',
            'city': 'Harare',
            'county': 'Harare',
            'country': 'Zimbabwe',
            'postal_code': '263',
            'occupation': 'Business Analyst',
            'employment_status': 'employed',
            'employer': 'ZimTech Corp',
            'job_title': 'Senior Analyst',
            'education_level': 'Master\'s Degree',
            'institution': 'University of Zimbabwe',
            'qualification_year': '2016',
            'emergency_contact_name': 'Tendai Moyo',
            'emergency_contact_phone': '+263772345678',
            'emergency_contact_relationship': 'Spouse',
            'currency': 'USD',
            'amount': 500,
        },
        'ZA': {
            'full_name': 'Thabo Mbeki',
            'email': f'thabo.mbeki+{datetime.now().strftime("%Y%m%d%H%M%S")}@test.com',
            'phone': '+27123456789',
            'id_number': '9001015000080',
            'dob': '1990-01-01',
            'gender': 'Male',
            'address': '789 Nelson Mandela Boulevard',
            'city': 'Johannesburg',
            'county': 'Gauteng',
            'country': 'South Africa',
            'postal_code': '2000',
            'occupation': 'Project Manager',
            'employment_status': 'employed',
            'employer': 'SA Projects Ltd',
            'job_title': 'Senior PM',
            'education_level': 'Bachelor\'s Degree',
            'institution': 'University of Cape Town',
            'qualification_year': '2012',
            'emergency_contact_name': 'Nomsa Mbeki',
            'emergency_contact_phone': '+27821234567',
            'emergency_contact_relationship': 'Spouse',
            'currency': 'ZAR',
            'amount': 10000,
        }
    }
    
    return test_data.get(country_code, test_data['KE'])


def test_api_enrollment(country_code='KE', payment_method='mpesa'):
    """Test enrollment via API"""
    print_header(f"TESTING API ENROLLMENT - {country_code} / {payment_method.upper()}")
    
    # Get test data
    test_data = get_test_data(country_code)
    
    # Get a learnership programme
    learnership = LearnershipProgramme.objects.filter(active=True).first()
    if not learnership:
        print_error("No learnership programme available!")
        return
    
    print_info(f"Selected Learnership: {learnership.title}")
    print_info(f"Cost: {learnership.cost_usd} USD")
    
    # Prepare enrollment payload
    payload = {
        'enrollment_type': 'learnership',
        'training_id': learnership.id,
        'is_corporate': False,
        'payment_plan_type': 'full',
        'payment_option': 'upfront',
        'payment_method': payment_method,
        'payment_status': 'pending',
        'amount_paid': test_data['amount'],
        'total_amount': test_data['amount'],
        'currency': test_data['currency'],
        'user': test_data,
        'evidence': []  # Would include file paths in real test
    }
    
    print("\n📋 Enrollment Payload:")
    print(f"  Student: {test_data['full_name']}")
    print(f"  Email: {test_data['email']}")
    print(f"  Phone: {test_data['phone']}")
    print(f"  Programme: {learnership.title}")
    print(f"  Amount: {test_data['amount']} {test_data['currency']}")
    print(f"  Payment Method: {payment_method}")
    
    print("\n⚠️  NOTE: API enrollment test requires:")
    print("  1. Files uploaded for prerequisites")
    print("  2. Payment gateway sandbox credentials")
    print("  3. Webhook endpoints configured")
    print("\n💡 For complete testing, use the web interface:")
    print(f"  → http://localhost:8000/learnerships/{learnership.id}/")
    

def show_payment_instructions(country_code, payment_method):
    """Show payment instructions for specific country/payment"""
    print_header(f"PAYMENT INSTRUCTIONS - {country_code} / {payment_method.upper()}")
    
    instructions = {
        ('KE', 'mpesa'): """
🇰🇪 KENYA - M-PESA PAYMENT
━━━━━━━━━━━━━━━━━━━━━━━━━

Test Credentials:
  Phone Number: +254708374166  ← USE THIS EXACT NUMBER
  PIN: 1234

Steps:
  1. Select M-Pesa as payment method
  2. Enter phone number: +254708374166
  3. STK Push will be sent to simulator
  4. Enter PIN: 1234
  5. Payment succeeds instantly

Expected Result:
  ✅ Payment Successful
  ✅ Transaction ID: MGHxxxxxxxxx
  ✅ Enrollment created
  ✅ Email/SMS sent
        """,
        
        ('ZW', 'ecash'): """
🇿🇼 ZIMBABWE - ECOCASH PAYMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Test Credentials:
  Phone Number: +263771234567  ← USE THIS EXACT NUMBER
  PIN: 1234

Steps:
  1. Select EcoCash as payment method
  2. Enter phone number: +263771234567
  3. Paynow sandbox will process payment
  4. Enter PIN: 1234
  5. Payment succeeds

Expected Result:
  ✅ Payment Successful
  ✅ Transaction ID: PAYxxxxxxxxx
  ✅ Enrollment created
  ✅ Email/SMS sent
        """,
        
        ('ZW', 'cash'): """
🇿🇼 ZIMBABWE - CASH PAYMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━

Steps:
  1. Select "Cash / In-Person Payment"
  2. Read comprehensive instructions
  3. Click "I'll Visit Office"
  4. Provisional enrollment created

You'll Receive:
  📧 Email with payment reference
  📱 SMS with reference code
  ⏰ 14 days to complete payment

Payment Reference:
  Format: PROV20260309XXXXX
  Valid for: 14 days
  
Payment Locations:
  • Harare (Main Office)
  • Bulawayo (Regional Office)

Important:
  ⚠️ Seat NOT secured until payment
  ⚠️ Bring ID and reference code
  ⚠️ Enrollment expires after 14 days
        """,
        
        ('ZA', 'yoco'): """
🇿🇦 SOUTH AFRICA - YOCO CARD PAYMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Test Credentials:
  Card Number: 4111 1111 1111 1111
  CVV: 123
  Expiry: 12/2030
  Cardholder: Any name

Steps:
  1. Select Yoco as payment method
  2. Enter test card details
  3. Click "Pay"
  4. Payment succeeds (sandbox)

Expected Result:
  ✅ Payment Successful
  ✅ Transaction ID: YCO-xxxxxxxxx
  ✅ Enrollment created
  ✅ Email/SMS sent
        """,
        
        ('KE', 'cash'): """
🇰🇪 KENYA - CASH PAYMENT
━━━━━━━━━━━━━━━━━━━━━━━━

Same process as Zimbabwe cash payment.

Payment Locations:
  • Nairobi (Head Office)
  • Mombasa (Regional)
  • Kisumu (Regional)
        """,
        
        ('ZA', 'cash'): """
🇿🇦 SOUTH AFRICA - CASH PAYMENT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Same process as Zimbabwe cash payment.

Payment Locations:
  • Johannesburg (Main Office)
  • Cape Town (Regional)
  • Durban (Regional)
        """
    }
    
    key = (country_code, payment_method.lower())
    instruction = instructions.get(key, "Instructions not available for this combination.")
    
    print(instruction)


def check_enrollment_status(email_pattern=None):
    """Check enrollment status in database"""
    print_header("CHECKING ENROLLMENT STATUS")
    
    # Get recent enrollments
    if email_pattern:
        enrollments = LearnershipEnrollment.objects.filter(
            user__email__icontains=email_pattern
        ).select_related('user', 'programme')[:10]
    else:
        enrollments = LearnershipEnrollment.objects.select_related(
            'user', 'programme'
        ).order_by('-enrolled_at')[:10]
    
    if not enrollments:
        print_warning("No enrollments found!")
        return
    
    print(f"\nFound {enrollments.count()} enrollment(s):\n")
    
    for e in enrollments:
        print(f"{'─'*70}")
        print(f"Student: {e.user.get_full_name()}")
        print(f"Email: {e.user.email}")
        print(f"Phone: {e.user.phone}")
        print(f"Programme: {e.programme.title}")
        print(f"Status: {e.status}")
        print(f"Payment Status: {e.payment_status}")
        print(f"Payment Plan: {e.payment_plan_type}")
        print(f"Amount Paid: {e.amount_paid} {e.currency}")
        print(f"Total: {e.total_amount} {e.currency}")
        print(f"Enrollment Type: {e.enrollment_type}")
        print(f"Prerequisites Verified: {e.prerequisites_verified}")
        print(f"Created: {e.enrolled_at}")
        
        if e.payment_transaction:
            print(f"Payment Provider: {e.payment_transaction.provider}")
            print(f"Transaction Status: {e.payment_transaction.status}")
    
    print(f"{'─'*70}\n")
    
    # Check provisional enrollments
    print("\n📋 Provisional Enrollments (Cash Payments):")
    provisional = ProvisionalEnrollment.objects.filter(
        enrollment_type='learnership'
    ).select_related('user', 'programme').order_by('-created_at')[:5]
    
    if provisional:
        for p in provisional:
            days_left = (p.expires_at - datetime.now()).days
            print(f"\n  Reference: {p.reference_code}")
            print(f"  Student: {p.user.get_full_name()}")
            print(f"  Programme: {p.programme.title}")
            print(f"  Status: {p.status}")
            print(f"  Amount: {p.final_amount} {p.currency}")
            print(f"  Expires: {p.expires_at} ({days_left} days remaining)")
    else:
        print("  No provisional enrollments found.")


def main():
    import argparse
    
    parser = argparse.ArgumentParser(
        description='Learnership Enrollment Sandbox Test Runner',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python test_learnership_enrollment.py --list
  python test_learnership_enrollment.py --check
  python test_learnership_enrollment.py --country=KE --payment=mpesa
  python test_learnership_enrollment.py --country=ZW --payment=cash
  python test_learnership_enrollment.py --status
        """
    )
    
    parser.add_argument('--list', action='store_true', help='List all test scenarios')
    parser.add_argument('--check', action='store_true', help='Check prerequisites')
    parser.add_argument('--country', type=str, help='Country code (KE, ZW, ZA)')
    parser.add_argument('--payment', type=str, help='Payment method (mpesa, ecash, cash, yoco)')
    parser.add_argument('--status', action='store_true', help='Check enrollment status')
    parser.add_argument('--email', type=str, help='Filter enrollments by email pattern')
    
    args = parser.parse_args()
    
    if args.list:
        list_test_scenarios()
    elif args.check:
        check_prerequisites()
    elif args.status or args.email:
        check_enrollment_status(args.email)
    elif args.country and args.payment:
        test_api_enrollment(args.country.upper(), args.payment.lower())
        show_payment_instructions(args.country.upper(), args.payment.lower())
    else:
        parser.print_help()
        print("\n" + "="*80)
        print_info("Quick Start:")
        print("  1. Check prerequisites: python test_learnership_enrollment.py --check")
        print("  2. List test scenarios: python test_learnership_enrollment.py --list")
        print("  3. Test specific country: python test_learnership_enrollment.py --country=KE --payment=mpesa")
        print("  4. Manual testing: Open http://localhost:8000/learnerships")


if __name__ == '__main__':
    main()
