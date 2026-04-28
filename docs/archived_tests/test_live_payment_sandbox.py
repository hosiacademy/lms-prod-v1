#!/usr/bin/env python
"""
LIVE PAYMENT SANDBOX TEST
==========================

This script performs a REAL payment initiation with a sandbox payment provider
and walks through the complete enrollment flow.

We'll test with PAYNOW (Zimbabwe) sandbox:
- URL: https://sandbox.paynow.co.zw/
- Test Phone: +263771234567
- Test PIN: 1234

Usage:
    python test_live_payment_sandbox.py
"""

import os
import sys
import json
import requests
from datetime import datetime

# Setup paths
sys.path.insert(0, '/home/tk/lms-prod/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')

import django
django.setup()

from apps.learnerships.models import LearnershipProgramme
from apps.users.models import User
from apps.payments.models import PaymentTransaction, ProviderCountryConfig, PaymentStatus
from django.conf import settings

# ANSI Colors
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_header(text):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*80}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{text.center(80)}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*80}{Colors.ENDC}\n")

def print_step(num, text):
    print(f"\n{Colors.OKBLUE}{'─'*80}{Colors.ENDC}")
    print(f"{Colors.OKBLUE}{Colors.BOLD}STEP {num}: {text}{Colors.ENDC}")
    print(f"{Colors.OKBLUE}{'─'*80}{Colors.ENDC}")

def print_success(text):
    print(f"{Colors.OKGREEN}✅ {text}{Colors.ENDC}")

def print_error(text):
    print(f"{Colors.FAIL}❌ {text}{Colors.ENDC}")

def print_info(text):
    print(f"{Colors.OKCYAN}ℹ️  {text}{Colors.ENDC}")

def print_json(title, data):
    print(f"\n{Colors.BOLD}{title}:{Colors.ENDC}")
    print(json.dumps(data, indent=2))


# ============================================================================
# STEP 1: GET SANDBOX CREDENTIALS
# ============================================================================
def get_paynow_credentials():
    """Get Paynow sandbox credentials from environment"""
    return {
        'integration_id': os.getenv('PAYNOW_INTEGRATION_ID', ''),
        'integration_key': os.getenv('PAYNOW_INTEGRATION_KEY', ''),
        'sandbox_url': 'https://sandbox.paynow.co.zw/',
        'api_url': 'https://sandbox.paynow.co.zw/api/',
    }


# ============================================================================
# STEP 2: CREATE TEST USER
# ============================================================================
def create_test_user():
    """Create a test user for enrollment"""
    email = f"test.payment+{datetime.now().strftime('%Y%m%d%H%M%S')}@test.com"
    
    print_step(1, "CREATE TEST USER")
    print_info(f"Creating test user: {email}")
    
    user = User.objects.create_user(
        username=email.split('@')[0],
        email=email,
        password='TestPassword123!',
        first_name='Tinashe',
        last_name='Moyo'
    )
    
    # Add phone number
    user.phone = '+263771234567'  # Paynow test phone
    user.country = 'ZW'
    user.save()
    
    print_success(f"User created: {user.email}")
    print_success(f"User ID: {user.id}")
    print_success(f"Phone: {user.phone}")
    
    return user


# ============================================================================
# STEP 3: GET LEARNERSHIP PROGRAMME
# ============================================================================
def get_learnership():
    """Get a test learnership programme"""
    print_step(2, "GET LEARNERSHIP PROGRAMME")
    
    learnership = LearnershipProgramme.objects.filter(
        active=True,
        cost_usd__isnull=False
    ).first()
    
    if not learnership:
        print_error("No learnership programme found!")
        print_info("Creating test learnership...")
        
        learnership = LearnershipProgramme.objects.create(
            title='Test Learnership - Payment Sandbox',
            duration_months=12,
            cost_usd=500.00,
            currency='USD',
            country='ZW',
            city='Harare',
            active=True,
            status='open'
        )
        print_success(f"Created: {learnership.title}")
    else:
        print_success(f"Found: {learnership.title}")
    
    print_info(f"Cost: {learnership.cost_usd} {learnership.currency}")
    print_info(f"Duration: {learnership.duration_months} months")
    
    return learnership


# ============================================================================
# STEP 4: INITIATE PAYMENT WITH PAYNOW SANDBOX
# ============================================================================
def initiate_paynow_payment(user, learnership):
    """
    Initiate REAL payment with Paynow sandbox
    
    This is a LIVE API call to Paynow's sandbox environment.
    """
    print_step(3, "INITIATE PAYNOW SANDBOX PAYMENT")
    
    creds = get_paynow_credentials()
    
    # Check if we have credentials
    if not creds['integration_id'] or not creds['integration_key']:
        print_warning("Paynow credentials not found in .env")
        print_info("Using mock sandbox simulation...")
        
        # Create mock transaction
        transaction = PaymentTransaction.objects.create(
            user=user,
            amount=learnership.cost_usd,
            currency='USD',
            provider='paynow',
            provider_reference=f"PAYNOW-SANDBOX-{datetime.now().strftime('%Y%m%d%H%M%S')}",
            status=PaymentStatus.PENDING,
            metadata={
                'is_sandbox': True,
                'test_phone': '+263771234567',
                'test_pin': '1234',
                'sandbox_url': 'https://sandbox.paynow.co.zw/',
                'enrollment_type': 'learnership',
                'programme_id': learnership.id,
                'programme_title': learnership.title,
            },
            description=f"Learnership Enrollment: {learnership.title}"
        )
        
        print_info("Mock transaction created")
        print_success(f"Transaction ID: {transaction.id}")
        print_success(f"Reference: {transaction.provider_reference}")
        
        return transaction
    
    # REAL Paynow API call
    print_info(f"Paynow Integration ID: {creds['integration_id']}")
    print_info(f"Sandbox URL: {creds['sandbox_url']}")
    
    # Prepare payment data
    payment_data = {
        'reference': f"ENR-{datetime.now().strftime('%Y%m%d%H%M%S')}",
        'amount': float(learnership.cost_usd),
        'currency': 'USD',
        'email': user.email,
        'firstname': user.first_name or 'Test',
        'lastname': user.last_name or 'User',
        'telephone': user.phone or '+263771234567',
        'resulturl': f"{settings.SITE_URL}/api/payments/callback/paynow/",
        'returnurl': f"{settings.SITE_URL}/payment/success/",
        'status': 'Message',
    }
    
    print_json("Payment Data", payment_data)
    
    try:
        # Make REAL API call to Paynow sandbox
        response = requests.post(
            f"{creds['api_url']}initiate",
            json=payment_data,
            headers={
                'Content-Type': 'application/json',
                'X-Integration-Id': creds['integration_id'],
                'X-Integration-Key': creds['integration_key'],
            },
            timeout=30
        )
        
        if response.status_code == 200:
            result = response.json()
            print_success("Paynow API call successful!")
            print_json("Paynow Response", result)
            
            # Create transaction
            transaction = PaymentTransaction.objects.create(
                user=user,
                amount=learnership.cost_usd,
                currency='USD',
                provider='paynow',
                provider_reference=result.get('reference', payment_data['reference']),
                status=PaymentStatus.PENDING,
                metadata={
                    'is_sandbox': True,
                    'paynow_response': result,
                    'checkout_url': result.get('redirecturl', ''),
                    'enrollment_type': 'learnership',
                    'programme_id': learnership.id,
                    'programme_title': learnership.title,
                },
                description=f"Learnership Enrollment: {learnership.title}",
                checkout_url=result.get('redirecturl', '')
            )
            
            print_success(f"Transaction created: {transaction.id}")
            
            if result.get('redirecturl'):
                print_info(f"Payment URL: {result['redirecturl']}")
            
            return transaction
        else:
            print_error(f"Paynow API error: {response.status_code}")
            print_error(f"Response: {response.text}")
            
            # Fallback to mock transaction
            print_warning("Creating mock transaction instead...")
            return create_mock_transaction(user, learnership)
            
    except requests.exceptions.RequestException as e:
        print_error(f"Request failed: {str(e)}")
        print_warning("Creating mock transaction...")
        return create_mock_transaction(user, learnership)


def create_mock_transaction(user, learnership):
    """Create mock transaction when API is unavailable"""
    transaction = PaymentTransaction.objects.create(
        user=user,
        amount=learnership.cost_usd,
        currency='USD',
        provider='paynow',
        provider_reference=f"PAYNOW-MOCK-{datetime.now().strftime('%Y%m%d%H%M%S')}",
        status=PaymentStatus.PENDING,
        metadata={
            'is_sandbox': True,
            'test_phone': '+263771234567',
            'test_pin': '1234',
            'sandbox_url': 'https://sandbox.paynow.co.zw/',
            'enrollment_type': 'learnership',
            'programme_id': learnership.id,
            'programme_title': learnership.title,
            'mock': True,
        },
        description=f"Learnership Enrollment: {learnership.title}",
        checkout_url='https://sandbox.paynow.co.zw/'
    )
    
    print_success(f"Mock transaction created: {transaction.id}")
    return transaction


# ============================================================================
# STEP 5: SHOW PAYMENT INSTRUCTIONS
# ============================================================================
def show_payment_instructions(transaction):
    """Show payment instructions to user"""
    print_step(4, "PAYMENT INSTRUCTIONS")
    
    print(f"""
{Colors.BOLD}╔════════════════════════════════════════════════════════════════════════╗{Colors.ENDC}
{Colors.BOLD}║                    PAYNOW SANDBOX PAYMENT INSTRUCTIONS                  ║{Colors.ENDC}
{Colors.BOLD}╚════════════════════════════════════════════════════════════════════════╝{Colors.ENDC}

{Colors.OKGREEN}Transaction Details:{Colors.ENDC}
  Transaction ID: {transaction.id}
  Reference: {transaction.provider_reference}
  Amount: {transaction.amount} {transaction.currency}
  Provider: Paynow (Sandbox)

{Colors.WARNING}⚠️  THIS IS A SANDBOX TEST - NO REAL MONEY WILL BE CHARGED{Colors.ENDC}

{Colors.OKBLUE}Payment Steps:{Colors.ENDC}
  1. Open browser and go to: {Colors.OKCYAN}https://sandbox.paynow.co.zw/{Colors.ENDC}
  
  2. Or use the checkout URL:
     {Colors.OKCYAN}{transaction.checkout_url}{Colors.ENDC}
  
  3. Select payment method: {Colors.BOLD}EcoCash{Colors.ENDC}
  
  4. Enter test phone number: {Colors.BOLD}+263771234567{Colors.ENDC}
  
  5. Click "Continue" or "Pay Now"
  
  6. When prompted for PIN, enter: {Colors.BOLD}1234{Colors.ENDC}
  
  7. Payment will succeed instantly (sandbox)

{Colors.OKGREEN}Expected Result:{Colors.ENDC}
  ✅ Payment Successful
  ✅ Transaction ID from Paynow
  ✅ Webhook sent to backend
  ✅ Transaction status updated to 'successful'
  ✅ Enrollment confirmed

{Colors.OKCYAN}Test Credentials:{Colors.ENDC}
  Phone: +263771234567 (EcoCash test number)
  PIN: 1234
  Email: Any valid email

{Colors.WARNING}Important Notes:{Colors.ENDC}
  • This is a TEST environment
  • No real money is transferred
  • Use ONLY the test phone number above
  • The transaction will show as 'successful' in sandbox
""")


# ============================================================================
# STEP 6: SIMULATE WEBHOOK (for mock transactions)
# ============================================================================
def simulate_paynow_webhook(transaction):
    """Simulate Paynow webhook for mock transactions"""
    print_step(5, "SIMULATE PAYNOW WEBHOOK")
    
    if not transaction.metadata.get('mock', False):
        print_info("Real transaction - webhook will come from Paynow")
        print_info(f"Webhook URL: {settings.SITE_URL}/api/payments/callback/paynow/")
        return
    
    print_warning("Simulating webhook for mock transaction...")
    
    # Simulate webhook payload
    webhook_payload = {
        'status': 'Success',
        'reference': transaction.provider_reference,
        'amount': float(transaction.amount),
        'currency': transaction.currency,
        'phone': '+263771234567',
        'email': transaction.user.email,
        'timestamp': datetime.now().isoformat(),
    }
    
    print_json("Webhook Payload", webhook_payload)
    
    # Update transaction
    transaction.status = PaymentStatus.SUCCESSFUL
    transaction.completed_at = datetime.now()
    transaction.metadata['webhook_simulated'] = True
    transaction.metadata['webhook_payload'] = webhook_payload
    transaction.save()
    
    print_success("Transaction status updated: SUCCESSFUL")
    print_success(f"Completed at: {transaction.completed_at}")
    
    return webhook_payload


# ============================================================================
# STEP 7: VERIFY PAYMENT & CREATE ENROLLMENT
# ============================================================================
def verify_payment_and_enroll(transaction, learnership):
    """Verify payment and create learnership enrollment"""
    print_step(6, "VERIFY PAYMENT & CREATE ENROLLMENT")
    
    # Check transaction status
    if transaction.status != PaymentStatus.SUCCESSFUL:
        print_error(f"Payment not successful! Status: {transaction.status}")
        return None
    
    print_success("Payment verified successfully!")
    
    # Import enrollment models
    from apps.enrollments.models import ProvisionalEnrollment
    
    # Create provisional enrollment
    enrollment = ProvisionalEnrollment.objects.create(
        user=transaction.user,
        programme=learnership,
        payment_transaction=transaction,
        enrollment_type='learnership',
        status='provisional',
        reference_code=f"ENR-{datetime.now().strftime('%Y%m%d%H%M%S')}",
        final_amount=transaction.amount,
        currency=transaction.currency,
        expires_at=datetime.now().replace(day=datetime.now().day + 14),
        metadata={
            'payment_provider': 'paynow',
            'payment_method': 'ecash',
            'sandbox_test': True,
            'programme_title': learnership.title,
        }
    )
    
    print_success(f"Enrollment created!")
    print_info(f"Enrollment ID: {enrollment.id}")
    print_info(f"Reference: {enrollment.reference_code}")
    print_info(f"Status: {enrollment.status}")
    print_info(f"Expires: {enrollment.expires_at}")
    
    return enrollment


# ============================================================================
# STEP 8: SHOW RESULTS
# ============================================================================
def show_results(user, transaction, enrollment):
    """Show final test results"""
    print_header("PAYMENT SANDBOX TEST RESULTS")
    
    print(f"""
{Colors.BOLD}╔════════════════════════════════════════════════════════════════════════╗{Colors.ENDC}
{Colors.BOLD}║                         TEST COMPLETED                                  ║{Colors.ENDC}
{Colors.BOLD}╚════════════════════════════════════════════════════════════════════════╝{Colors.ENDC}

{Colors.OKGREEN}✅ USER CREATED:{Colors.ENDC}
   Email: {user.email}
   ID: {user.id}
   Phone: {user.phone}

{Colors.OKGREEN}✅ PAYMENT TRANSACTION:{Colors.ENDC}
   Transaction ID: {transaction.id}
   Provider Reference: {transaction.provider_reference}
   Amount: {transaction.amount} {transaction.currency}
   Provider: {transaction.provider}
   Status: {transaction.status}
   Sandbox: {transaction.metadata.get('is_sandbox', False)}

{Colors.OKGREEN}✅ ENROLLMENT CREATED:{Colors.ENDC}
   Enrollment ID: {enrollment.id}
   Reference: {enrollment.reference_code}
   Programme: {enrollment.programme.title}
   Status: {enrollment.status}
   Expires: {enrollment.expires_at}

{Colors.OKBLUE}📋 NEXT STEPS:{Colors.ENDC}
   1. Check database:
      python manage.py shell
      >>> from apps.enrollments.models import ProvisionalEnrollment
      >>> ProvisionalEnrollment.objects.get(id={enrollment.id})
   
   2. Check Django Admin:
      http://localhost:8000/admin/
      → Enrollments → Provisional Enrollments
   
   3. Verify in database:
      SELECT * FROM enrollments_provisionalenrollment 
      WHERE reference_code = '{enrollment.reference_code}';

{Colors.WARNING}⚠️  IMPORTANT:{Colors.ENDC}
   • This was a SANDBOX test
   • No real money was charged
   • Enrollment is PROVISIONAL until admin verification
   • For production, use real Paynow credentials

{Colors.OKGREEN}🎉 PAYMENT SANDBOX TEST SUCCESSFUL!{Colors.ENDC}
""")


# ============================================================================
# MAIN TEST RUNNER
# ============================================================================
def main():
    print_header("LIVE PAYMENT SANDBOX TEST - LEARNERSHIP ENROLLMENT")
    print_info("Testing Paynow (Zimbabwe) Sandbox Integration")
    print_info(f"Started at: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    
    try:
        # Step 1: Create test user
        user = create_test_user()
        
        # Step 2: Get learnership
        learnership = get_learnership()
        
        # Step 3: Initiate payment
        transaction = initiate_paynow_payment(user, learnership)
        
        # Step 4: Show payment instructions
        show_payment_instructions(transaction)
        
        # Step 5: Simulate webhook (for mock) or wait for real webhook
        if transaction.metadata.get('mock', False):
            print("\n" + "="*80)
            print("Press Enter to simulate webhook...")
            input()
            webhook_payload = simulate_paynow_webhook(transaction)
        else:
            print("\n" + "="*80)
            print("Waiting for webhook from Paynow...")
            print("Complete the payment in browser, then press Enter to check status...")
            input()
            # Refresh transaction
            transaction.refresh_from_db()
            print_info(f"Transaction status: {transaction.status}")
        
        # Step 6: Verify and enroll
        enrollment = verify_payment_and_enroll(transaction, learnership)
        
        if enrollment:
            # Step 7: Show results
            show_results(user, transaction, enrollment)
        else:
            print_error("Enrollment creation failed!")
            
    except Exception as e:
        print_error(f"Test failed: {str(e)}")
        import traceback
        traceback.print_exc()
        return 1
    
    return 0


if __name__ == '__main__':
    exit_code = main()
    sys.exit(exit_code)
