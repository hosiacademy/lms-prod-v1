#!/usr/bin/env python
"""
REAL LEARNERSHIP ENROLLMENT TEST
=================================

Enroll ACTUAL student Takunda Majojo into ACTUAL learnership
with ACTUAL instructor Takawira Mazando

Learnership: AI Developer / Machine Learning Engineer Learnership (ID: 7)
Instructor: Takawira Mazando (ID: 1)
Student: Takunda Majojo (to be created)
Payment: Paynow Sandbox (Zimbabwe USD)
"""

import os
import sys
from datetime import datetime, timedelta

sys.path.insert(0, '/home/tk/lms-prod/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')

import django
django.setup()

from django.utils import timezone
from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment, EnrollmentStatus
from apps.users.models import User
from apps.payments.models import PaymentTransaction, PaymentStatus
from apps.enrollments.models import ProvisionalEnrollment
from apps.localization.models import Country

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

def print_header(text):
    print(f"\n{Colors.HEADER}{Colors.BOLD}{'='*80}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{text:^80}{Colors.ENDC}")
    print(f"{Colors.HEADER}{Colors.BOLD}{'='*80}{Colors.ENDC}\n")

def print_step(num, text):
    print(f"\n{Colors.OKBLUE}{Colors.BOLD}STEP {num}: {text}{Colors.ENDC}")
    print(f"{Colors.OKBLUE}{'─'*80}{Colors.ENDC}")

def print_success(text):
    print(f"{Colors.OKGREEN}✅ {text}{Colors.ENDC}")

def print_info(text):
    print(f"{Colors.OKCYAN}ℹ️  {text}{Colors.ENDC}")

def main():
    print_header("REAL LEARNERSHIP ENROLLMENT - TAKUNDA MAJOJO")
    
    # =========================================================================
    # STEP 1: Get Actual Learnership Programme
    # =========================================================================
    print_step(1, "GET ACTUAL LEARNERSHIP PROGRAMME")
    
    # Use ACTUAL learnership with Takawira Mazando as instructor
    learnership = LearnershipProgramme.objects.get(id=7)
    
    print_success(f"Found: {learnership.title}")
    print_info(f"Role: {learnership.role}")
    print_info(f"Duration: {learnership.duration_months} months")
    print_info(f"Country: {learnership.country}")
    print_info(f"Status: {learnership.status}")
    
    if learnership.instructor:
        print_success(f"Instructor: {learnership.instructor.get_full_name()} (ID: {learnership.instructor.id})")
    else:
        print_info("No instructor assigned yet")
    
    # =========================================================================
    # STEP 2: Get/Create Zimbabwe Country
    # =========================================================================
    print_step(2, "GET ZIMBABWE COUNTRY")
    
    zw = Country.objects.filter(code='ZW').first()
    if not zw:
        zw = Country.objects.create(
            code='ZW',
            name='Zimbabwe',
            currency_code='USD',
            is_active=True
        )
        print_success("Zimbabwe created")
    else:
        print_success(f"Zimbabwe found: {zw.name}")
    
    # =========================================================================
    # STEP 3: Create Student Takunda Majojo
    # =========================================================================
    print_step(3, "CREATE STUDENT: TAKUNDA MAJOJO")
    
    timestamp = datetime.now().strftime('%Y%m%d%H%M%S')
    email = f"takunda.majojo+{timestamp}@test.com"
    
    takunda = User.objects.create_user(
        username=f"takunda.majojo.{timestamp}",
        email=email,
        password='Takunda2026!',
        first_name='Takunda',
        last_name='Majojo'
    )
    
    takunda.phone = '+263771234567'  # Zimbabwe test phone
    takunda.country = zw
    takunda.save()
    
    print_success(f"Student created: {takunda.get_full_name()}")
    print_info(f"User ID: {takunda.id}")
    print_info(f"Email: {takunda.email}")
    print_info(f"Phone: {takunda.phone}")
    print_info(f"Country: {takunda.country.name}")
    
    # =========================================================================
    # STEP 4: Create Payment Transaction (Paynow Sandbox)
    # =========================================================================
    print_step(4, "CREATE PAYMENT TRANSACTION (PAYNOW SANDBOX)")
    
    # For learnerships without cost, use a nominal enrollment fee
    amount = 50.00  # USD enrollment fee
    
    transaction = PaymentTransaction.objects.create(
        user=takunda,
        amount=amount,
        currency='USD',
        provider='paynow',
        provider_reference=f"PAYNOW-ENR-{timestamp}",
        status=PaymentStatus.PENDING,
        metadata={
            'is_sandbox': True,
            'test_phone': '+263771234567',
            'test_pin': '1234',
            'sandbox_url': 'https://sandbox.paynow.co.zw/',
            'enrollment_type': 'learnership',
            'programme_id': learnership.id,
            'programme_title': learnership.title,
            'instructor_id': learnership.instructor.id if learnership.instructor else None,
            'instructor_name': learnership.instructor.get_full_name() if learnership.instructor else None,
            'student_name': takunda.get_full_name(),
            'mock': True,
        },
        description=f"Learnership Enrollment: {learnership.title}"
    )
    
    print_success(f"Transaction created: {transaction.id}")
    print_info(f"Amount: ${amount} USD")
    print_info(f"Provider: Paynow (EcoCash)")
    
    # Simulate payment success (webhook)
    print_info("Simulating payment success (webhook received)...")
    
    transaction.status = PaymentStatus.SUCCESSFUL
    transaction.completed_at = timezone.now()
    transaction.metadata['webhook_simulated'] = True
    transaction.metadata['webhook_payload'] = {
        'status': 'Success',
        'reference': transaction.provider_reference,
        'amount': amount,
        'currency': 'USD',
        'timestamp': timezone.now().isoformat(),
    }
    transaction.save()
    
    print_success(f"Payment status: {transaction.status}")
    
    # =========================================================================
    # STEP 5: Create Learnership Enrollment (NOT Provisional)
    # =========================================================================
    print_step(5, "CREATE LEARNERSHIP ENROLLMENT")
    
    # Create ACTUAL LearnershipEnrollment (not ProvisionalEnrollment)
    enrollment = LearnershipEnrollment.objects.create(
        programme=learnership,
        user=takunda,
        status=EnrollmentStatus.PROVISIONAL,
        enrollment_type='individual',
        payment_transaction=transaction,
        payment_status='paid',  # Since payment is successful
        amount_paid=amount,
        currency='USD',
        total_amount=amount,
        payment_plan_type='full',
        
        # Personal Information (SETA compliance)
        highest_qualification='Bachelor\'s Degree',
        qualification_institution='University of Zimbabwe',
        qualification_year='2020',
        employment_status='unemployed',
        nationality='Zimbabwean',
        race='Black African',
        
        # Next of Kin
        next_of_kin_name='Mai Majojo',
        next_of_kin_phone='+263772345678',
        next_of_kin_relationship='Mother',
        
        # Prerequisites
        prerequisites_verified=False,  # Needs admin verification
        verified_by=None,
        verified_at=None,
        
        # Timeline
        enrolled_at=timezone.now(),
    )
    
    print_success(f"Learnership Enrollment created!")
    print_info(f"Enrollment ID: {enrollment.id}")
    print_info(f"Status: {enrollment.status}")
    print_info(f"Programme: {enrollment.programme.title}")
    print_info(f"Student: {enrollment.user.get_full_name()}")
    print_info(f"Instructor: {enrollment.programme.instructor.get_full_name() if enrollment.programme.instructor else 'Not assigned'}")
    print_info(f"Payment: ${enrollment.amount_paid} {enrollment.currency}")
    
    # =========================================================================
    # STEP 6: Create Provisional Enrollment (for payment tracking)
    # =========================================================================
    print_step(6, "CREATE PROVISIONAL ENROLLMENT (PAYMENT TRACKING)")
    
    provisional = ProvisionalEnrollment.objects.create(
        user=takunda,
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
            'instructor_name': learnership.instructor.get_full_name() if learnership.instructor else None,
            'student_name': takunda.get_full_name(),
            'test_phone': '+263771234567',
            'test_pin': '1234',
            'amount': str(amount),
            'currency': 'USD',
            'learnership_enrollment_id': enrollment.id,
        }
    )
    
    print_success(f"Provisional enrollment created!")
    print_info(f"ID: {provisional.id}")
    print_info(f"Reference: {provisional.reference_code}")
    print_info(f"Expires: {provisional.expires_at}")
    
    # =========================================================================
    # FINAL RESULTS
    # =========================================================================
    print_header("ENROLLMENT COMPLETE - SUMMARY")
    
    print(f"""
{Colors.OKGREEN}✅ STUDENT:{Colors.ENDC}
   Name: {takunda.get_full_name()}
   ID: {takunda.id}
   Email: {takunda.email}
   Phone: {takunda.phone}
   Country: {takunda.country.name}

{Colors.OKGREEN}✅ LEARNERSHIP PROGRAMME:{Colors.ENDC}
   ID: {learnership.id}
   Title: {learnership.title}
   Role: {learnership.role}
   Duration: {learnership.duration_months} months
   Instructor: {learnership.instructor.get_full_name() if learnership.instructor else 'Not assigned'} (ID: {learnership.instructor.id if learnership.instructor else 'N/A'})

{Colors.OKGREEN}✅ LEARNERSHIP ENROLLMENT:{Colors.ENDC}
   ID: {enrollment.id}
   Status: {enrollment.status}
   Payment Status: {enrollment.payment_status}
   Amount Paid: ${enrollment.amount_paid} {enrollment.currency}
   Prerequisites Verified: {enrollment.prerequisites_verified}
   Enrolled At: {enrollment.enrolled_at}

{Colors.OKGREEN}✅ PAYMENT TRANSACTION:{Colors.ENDC}
   ID: {transaction.id}
   Provider: {transaction.provider}
   Status: {transaction.status}
   Amount: ${transaction.amount} {transaction.currency}
   Reference: {transaction.provider_reference}
   Sandbox: {transaction.metadata.get('is_sandbox', False)}

{Colors.OKGREEN}✅ PROVISIONAL ENROLLMENT:{Colors.ENDC}
   ID: {provisional.id}
   Reference: {provisional.reference_code}
   Status: {provisional.status}
   Expires: {provisional.expires_at}

{Colors.OKCYAN}📋 NEXT STEPS:{Colors.ENDC}
   1. Admin verifies prerequisites (uploaded documents)
   2. Admin marks enrollment as confirmed
   3. Student gets access to learning platform
   4. AICerts courses enrolled
   5. Instructor (Takawira Mazando) can see student in dashboard

{Colors.WARNING}⚠️  IMPORTANT:{Colors.ENDC}
   • This was a SANDBOX test
   • No real money was charged
   • Enrollment is PROVISIONAL until admin verification
   • Payment of $50 USD is enrollment fee (learnership is free)

{Colors.OKGREEN}{'🎉 TAKUNDA MAJOJO SUCCESSFULLY ENROLLED!':^80}{Colors.ENDC}
""")
    
    # =========================================================================
    # DATABASE VERIFICATION
    # =========================================================================
    print_header("VERIFY IN DATABASE")
    
    print(f"""
Run these commands to verify:

cd /home/tk/lms-prod/backend
source venv_linux/bin/activate
python manage.py shell

# Verify Student
>>> from apps.users.models import User
>>> takunda = User.objects.get(email__startswith='takunda.majojo+')
>>> print(f"Student: {{takunda.get_full_name()}}")
>>> print(f"Email: {{takunda.email}}")

# Verify Enrollment
>>> from apps.learnerships.models import LearnershipEnrollment
>>> enrollment = LearnershipEnrollment.objects.get(user=takunda)
>>> print(f"Programme: {{enrollment.programme.title}}")
>>> print(f"Instructor: {{enrollment.programme.instructor.get_full_name()}}")
>>> print(f"Status: {{enrollment.status}}")

# Verify Payment
>>> from apps.payments.models import PaymentTransaction
>>> txn = PaymentTransaction.objects.get(user=takunda)
>>> print(f"Transaction: {{txn.id}}")
>>> print(f"Status: {{txn.status}}")
>>> print(f"Amount: ${{txn.amount}}")
""")


if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        print(f"{Colors.FAIL}❌ Test failed: {str(e)}{Colors.ENDC}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
