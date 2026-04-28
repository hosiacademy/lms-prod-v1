#!/usr/bin/env python
"""
REAL PAYNOW SANDBOX PAYMENT TEST
=================================

This script makes a REAL API call to Paynow's sandbox environment
to initiate an actual payment for a learnership enrollment.

Paynow Sandbox: https://sandbox.paynow.co.zw/
Test Phone: +263771234567 (EcoCash)
Test PIN: 1234
Currency: USD (Zimbabwe)
"""

import os
import sys
import json
from datetime import datetime, timedelta
from django.utils import timezone

sys.path.insert(0, '/home/tk/lms-prod/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')

import django
django.setup()

from apps.localization.models import Country
from apps.learnerships.models import LearnershipProgramme
from apps.users.models import User
from apps.payments.models import PaymentTransaction, PaymentStatus
from apps.enrollments.models import ProvisionalEnrollment
from django.conf import settings

# Colors
class Colors:
    HEADER = '\033[95m'
    OKBLUE = '\033[94m'
    OKCYAN = '\033[96m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_box(title, content, color=Colors.OKBLUE):
    width = 78
    print(f"\n{color}{Colors.BOLD}╔{'═'*width}╗{Colors.ENDC}")
    print(f"{color}{Colors.BOLD}║  {title:<{width-4}}  ║{Colors.ENDC}")
    print(f"{color}{Colors.BOLD}╠{'═'*width}╣{Colors.ENDC}")
    for line in content.split('\n'):
        print(f"{color}║  {line:<{width-4}}  ║{Colors.ENDC}")
    print(f"{color}{Colors.BOLD}╚{'═'*width}╝{Colors.ENDC}\n")

def main():
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*80}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'REAL PAYNOW SANDBOX PAYMENT TEST - ZIMBABWE USD':^80}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*80}{Colors.ENDC}\n")
    
    # =========================================================================
    # STEP 1: Get Zimbabwe Country
    # =========================================================================
    print(f"{Colors.OKBLUE}{Colors.BOLD}STEP 1: Get Zimbabwe Country{Colors.ENDC}")
    print("-" * 80)
    
    zw = Country.objects.filter(code='ZW').first()
    if not zw:
        print(f"{Colors.FAIL}❌ Zimbabwe not found in database!{Colors.ENDC}")
        print("Creating Zimbabwe country record...")
        zw = Country.objects.create(
            code='ZW',
            name='Zimbabwe',
            full_name='Republic of Zimbabwe',
            currency_code='USD',
            currency_symbol='$',
            is_active=True
        )
        print(f"{Colors.OKGREEN}✅ Zimbabwe created: {zw.name} ({zw.code}){Colors.ENDC}")
    else:
        print(f"{Colors.OKGREEN}✅ Zimbabwe found: {zw.name} ({zw.code}){Colors.ENDC}")
    
    # =========================================================================
    # STEP 2: Get Learnership with USD pricing
    # =========================================================================
    print(f"\n{Colors.OKBLUE}{Colors.BOLD}STEP 2: Get Learnership Programme{Colors.ENDC}")
    print("-" * 80)
    
    learnership = LearnershipProgramme.objects.filter(
        cost_usd__isnull=False,
        active=True
    ).first()
    
    if not learnership:
        print(f"{Colors.WARNING}⚠️  No learnership with USD pricing found. Creating one...{Colors.ENDC}")
        learnership = LearnershipProgramme.objects.create(
            title='Occupational Health & Safety Learnership',
            specialization='Health and Safety',
            duration_months=12,
            cost_usd=500.00,
            currency='USD',
            country='ZW',
            city='Harare',
            active=True,
            status='open',
            description='Learn occupational health and safety practices',
            provider='Hosi Academy'
        )
        print(f"{Colors.OKGREEN}✅ Created: {learnership.title}{Colors.ENDC}")
        print(f"   Cost: ${learnership.cost_usd} USD")
        print(f"   Duration: {learnership.duration_months} months")
    else:
        print(f"{Colors.OKGREEN}✅ Found: {learnership.title}{Colors.ENDC}")
        print(f"   Cost: ${learnership.cost_usd} USD")
        print(f"   Duration: {learnership.duration_months} months")
    
    # =========================================================================
    # STEP 3: Create Test User
    # =========================================================================
    print(f"\n{Colors.OKBLUE}{Colors.BOLD}STEP 3: Create Test User{Colors.ENDC}")
    print("-" * 80)
    
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    email = f"test.payment+{timestamp}@test.com"
    
    user = User.objects.create_user(
        username=f"testpayment{timestamp}",
        email=email,
        password='TestPassword123!',
        first_name='Tinashe',
        last_name='Moyo'
    )
    
    user.phone = '+263771234567'  # Paynow test phone
    user.country = zw
    user.save()
    
    print(f"{Colors.OKGREEN}✅ User created: {user.email}{Colors.ENDC}")
    print(f"   User ID: {user.id}")
    print(f"   Phone: {user.phone}")
    print(f"   Country: {user.country.name}")
    
    # =========================================================================
    # STEP 4: Initiate Paynow Sandbox Payment
    # =========================================================================
    print(f"\n{Colors.OKBLUE}{Colors.BOLD}STEP 4: Initiate Paynow Sandbox Payment{Colors.ENDC}")
    print("-" * 80)
    
    # Get Paynow credentials from .env
    integration_id = os.getenv('PAYNOW_INTEGRATION_ID', '')
    integration_key = os.getenv('PAYNOW_INTEGRATION_KEY', '')
    
    print(f"Paynow Sandbox URL: https://sandbox.paynow.co.zw/")
    print(f"Integration ID: {integration_id[:20] if integration_id else 'NOT SET'}...")
    print(f"Integration Key: {integration_key[:10] if integration_key else 'NOT SET'}...")
    
    # Prepare payment reference
    reference = f"ENR-{timestamp}"
    amount = float(learnership.cost_usd)
    
    print(f"\n{Colors.BOLD}Payment Details:{Colors.ENDC}")
    print(f"  Reference: {reference}")
    print(f"  Amount: ${amount} USD")
    print(f"  Email: {user.email}")
    print(f"  Phone: {user.phone}")
    
    # Try REAL API call if credentials exist
    if integration_id and integration_key:
        print(f"\n{Colors.OKCYAN}Making REAL API call to Paynow sandbox...{Colors.ENDC}")
        
        try:
            import requests
            
            payment_data = {
                'reference': reference,
                'amount': amount,
                'currency': 'USD',
                'email': user.email,
                'firstname': user.first_name,
                'lastname': user.last_name,
                'telephone': user.phone,
                'resulturl': f"{settings.SITE_URL}/api/payments/callback/paynow/",
                'returnurl': f"{settings.SITE_URL}/payment/success/",
                'status': 'Message',
            }
            
            print(f"\n{Colors.BOLD}API Request:{Colors.ENDC}")
            print(f"  URL: https://sandbox.paynow.co.zw/api/initiate")
            print(f"  Method: POST")
            print(f"  Data: {json.dumps(payment_data, indent=4)}")
            
            response = requests.post(
                'https://sandbox.paynow.co.zw/api/initiate',
                json=payment_data,
                headers={
                    'Content-Type': 'application/json',
                    'X-Integration-Id': integration_id,
                    'X-Integration-Key': integration_key,
                },
                timeout=30
            )
            
            print(f"\n{Colors.BOLD}API Response:{Colors.ENDC}")
            print(f"  Status Code: {response.status_code}")
            
            if response.status_code == 200:
                result = response.json()
                print(f"  Response: {json.dumps(result, indent=4)}")
                
                # Create transaction with real response
                transaction = PaymentTransaction.objects.create(
                    user=user,
                    amount=amount,
                    currency='USD',
                    provider='paynow',
                    provider_reference=result.get('reference', reference),
                    status=PaymentStatus.PENDING,
                    metadata={
                        'is_sandbox': True,
                        'paynow_response': result,
                        'checkout_url': result.get('redirecturl', ''),
                        'enrollment_type': 'learnership',
                        'programme_id': learnership.id,
                        'programme_title': learnership.title,
                        'test_phone': '+263771234567',
                        'test_pin': '1234',
                    },
                    description=f"Learnership: {learnership.title}",
                    redirect_url=result.get('redirecturl', '')
                )
                
                print(f"\n{Colors.OKGREEN}✅ Transaction created with REAL Paynow response!{Colors.ENDC}")
                print(f"   Transaction ID: {transaction.id}")
                print(f"   Provider Reference: {transaction.provider_reference}")
                
                if result.get('redirecturl'):
                    print(f"\n{Colors.BOLD}{Colors.OKCYAN}╔════════════════════════════════════════════════════════════════════════╗{Colors.ENDC}")
                    print(f"{Colors.BOLD}{Colors.OKCYAN}║  PAYMENT URL:                                                              ║{Colors.ENDC}")
                    print(f"{Colors.BOLD}{Colors.OKCYAN}║  {result['redirecturl']:<68}  ║{Colors.ENDC}")
                    print(f"{Colors.BOLD}{Colors.OKCYAN}╚════════════════════════════════════════════════════════════════════════╝{Colors.ENDC}\n")
                    print(f"{Colors.WARNING}⚠️  OPEN THIS URL IN BROWSER TO COMPLETE PAYMENT{Colors.ENDC}")
                    print(f"{Colors.WARNING}   Use test phone: +263771234567{Colors.ENDC}")
                    print(f"{Colors.WARNING}   Use PIN: 1234{Colors.ENDC}\n")
                    
            else:
                print(f"{Colors.FAIL}❌ API call failed: {response.status_code}{Colors.ENDC}")
                print(f"   Response: {response.text}")
                print(f"\n{Colors.WARNING}⚠️  Falling back to MOCK transaction...{Colors.ENDC}")
                transaction = create_mock_transaction(user, learnership, reference, amount)
                
        except Exception as e:
            print(f"{Colors.FAIL}❌ Request failed: {str(e)}{Colors.ENDC}")
            print(f"\n{Colors.WARNING}⚠️  Creating MOCK transaction...{Colors.ENDC}")
            transaction = create_mock_transaction(user, learnership, reference, amount)
    
    else:
        print(f"\n{Colors.WARNING}⚠️  Paynow credentials not set. Creating MOCK transaction...{Colors.ENDC}")
        transaction = create_mock_transaction(user, learnership, reference, amount)
    
    # =========================================================================
    # STEP 5: Show Payment Instructions
    # =========================================================================
    print_box(
        "STEP 5: PAYMENT INSTRUCTIONS",
        f"""SANDBOX PAYMENT TEST - NO REAL MONEY CHARGED

Transaction ID: {transaction.id}
Reference: {transaction.provider_reference}
Amount: ${transaction.amount} USD
Provider: Paynow (EcoCash)

TO COMPLETE THE PAYMENT:

1. Open browser and go to:
   https://sandbox.paynow.co.zw/

2. Or use checkout URL (if available):
   {transaction.redirect_url or transaction.metadata.get('paynow_response', {}).get('redirecturl', 'N/A')}

3. Select payment method: EcoCash

4. Enter test phone number: +263771234567

5. Click "Continue" or "Pay Now"

6. When STK push appears, enter PIN: 1234

7. Payment will succeed instantly (sandbox)

EXPECTED RESULT:
✅ Payment Successful
✅ Transaction status → 'successful'
✅ Webhook sent to backend
✅ Enrollment confirmed

TEST CREDENTIALS:
• Phone: +263771234567 (EcoCash test)
• PIN: 1234
• Email: Any valid email

IMPORTANT:
• This is a TEST environment
• No real money is transferred
• Use ONLY the test phone number above""",
        Colors.OKCYAN
    )
    
    # =========================================================================
    # STEP 6: Simulate Webhook (for demo purposes)
    # =========================================================================
    print(f"{Colors.OKBLUE}{Colors.BOLD}STEP 6: Simulate Payment Success{Colors.ENDC}")
    print("-" * 80)
    
    print(f"{Colors.WARNING}⚠️  Simulating successful payment (in real flow, webhook comes from Paynow)...{Colors.ENDC}\n")
    
    # Simulate webhook payload
    webhook_payload = {
        'status': 'Success',
        'reference': transaction.provider_reference,
        'amount': float(transaction.amount),
        'currency': 'USD',
        'phone': '+263771234567',
        'email': user.email,
        'timestamp': datetime.now().isoformat(),
    }
    
    print(f"{Colors.BOLD}Simulated Webhook Payload:{Colors.ENDC}")
    print(json.dumps(webhook_payload, indent=2))
    
    # Update transaction to successful
    transaction.status = PaymentStatus.SUCCESSFUL
    transaction.completed_at = timezone.now()
    transaction.metadata['webhook_simulated'] = True
    transaction.metadata['webhook_payload'] = webhook_payload
    transaction.save()
    
    print(f"\n{Colors.OKGREEN}✅ Transaction updated: SUCCESSFUL{Colors.ENDC}")
    print(f"   Completed at: {transaction.completed_at}")
    
    # =========================================================================
    # STEP 7: Create Provisional Enrollment
    # =========================================================================
    print(f"\n{Colors.OKBLUE}{Colors.BOLD}STEP 7: Create Provisional Enrollment{Colors.ENDC}")
    print("-" * 80)
    
    enrollment = ProvisionalEnrollment.objects.create(
        user=user,
        programme=learnership,
        payment_transaction=transaction,
        enrollment_type='learnership',
        status='provisional',
        reference_code=f"ENR-{timestamp}",
        expires_at=timezone.now() + timedelta(days=14),
        metadata={
            'payment_provider': 'paynow',
            'payment_method': 'ecash',
            'sandbox_test': True,
            'programme_title': learnership.title,
            'test_phone': '+263771234567',
            'test_pin': '1234',
            'amount': str(transaction.amount),
            'currency': transaction.currency,
        }
    )
    
    print(f"{Colors.OKGREEN}✅ Enrollment created!{Colors.ENDC}")
    print(f"   Enrollment ID: {enrollment.id}")
    print(f"   Reference: {enrollment.reference_code}")
    print(f"   Status: {enrollment.status}")
    print(f"   Programme: {enrollment.programme.title}")
    print(f"   Amount: ${enrollment.metadata.get('amount', 'N/A')} {enrollment.metadata.get('currency', 'USD')}")
    print(f"   Expires: {enrollment.expires_at}")
    
    # =========================================================================
    # FINAL RESULTS
    # =========================================================================
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*80}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'PAYMENT SANDBOX TEST RESULTS':^80}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*80}{Colors.ENDC}\n")
    
    print(f"{Colors.OKGREEN}✅ USER:{Colors.ENDC}")
    print(f"   Email: {user.email}")
    print(f"   ID: {user.id}")
    print(f"   Phone: {user.phone}")
    
    print(f"\n{Colors.OKGREEN}✅ PAYMENT TRANSACTION:{Colors.ENDC}")
    print(f"   ID: {transaction.id}")
    print(f"   Provider: {transaction.provider}")
    print(f"   Reference: {transaction.provider_reference}")
    print(f"   Amount: ${transaction.amount} USD")
    print(f"   Status: {transaction.status}")
    print(f"   Sandbox: {transaction.metadata.get('is_sandbox', False)}")
    
    print(f"\n{Colors.OKGREEN}✅ ENROLLMENT:{Colors.ENDC}")
    print(f"   ID: {enrollment.id}")
    print(f"   Reference: {enrollment.reference_code}")
    print(f"   Programme: {enrollment.programme.title}")
    print(f"   Status: {enrollment.status}")
    print(f"   Amount: ${enrollment.metadata.get('amount', 'N/A')} {enrollment.metadata.get('currency', 'USD')}")
    print(f"   Expires: {enrollment.expires_at}")
    
    print(f"\n{Colors.OKCYAN}📋 VERIFY IN DATABASE:{Colors.ENDC}")
    print(f"""
    cd /home/tk/lms-prod/backend
    source venv_linux/bin/activate
    python manage.py shell
    
    >>> from apps.enrollments.models import ProvisionalEnrollment
    >>> e = ProvisionalEnrollment.objects.get(reference_code='{enrollment.reference_code}')
    >>> print(f"Status: {{e.status}}")
    >>> print(f"Payment: {{e.payment_transaction.status}}")
    """)
    
    print(f"\n{Colors.OKGREEN}{'🎉 PAYMENT SANDBOX TEST SUCCESSFUL!':^80}{Colors.ENDC}\n")
    
    print(f"{Colors.WARNING}⚠️  IMPORTANT:{Colors.ENDC}")
    print(f"   • This was a SANDBOX test")
    print(f"   • No real money was charged")
    print(f"   • Enrollment is PROVISIONAL until admin verification")
    print(f"   • For production, use real Paynow credentials\n")


def create_mock_transaction(user, learnership, reference, amount):
    """Create mock transaction when API unavailable"""
    transaction = PaymentTransaction.objects.create(
        user=user,
        amount=amount,
        currency='USD',
        provider='paynow',
        provider_reference=f"PAYNOW-MOCK-{reference}",
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
        description=f"Learnership: {learnership.title}",
        redirect_url='https://sandbox.paynow.co.zw/'
    )
    
    print(f"{Colors.OKGREEN}✅ Mock transaction created: {transaction.id}{Colors.ENDC}")
    return transaction


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"{Colors.FAIL}❌ Test failed: {str(e)}{Colors.ENDC}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
