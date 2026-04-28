
import os
import sys
import django

# Setup Django
sys.path.insert(0, '/home/tk/lms-prod/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from apps.payments.models import PaymentTransaction, PaymentStatus, TransactionType, ProviderCountryConfig
from apps.payments.services.payment_service import PaymentService
from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment
from apps.enrollments.models import ProvisionalEnrollment
from apps.users.models import User
from django.utils import timezone

def test_webhook_provisioning_gap():
    print("Testing Webhook Provisioning for Learnership...")
    
    # 1. Setup data
    user, _ = User.objects.get_or_create(email='gap.test@test.com', defaults={'username': 'gaptest'})
    programme = LearnershipProgramme.objects.filter(active=True).first()
    if not programme:
        print("No programme found")
        return
        
    config = ProviderCountryConfig.objects.filter(is_active=True).first()
    
    # 2. Create PENDING transaction
    import random, string
    rand_ref = ''.join(random.choices(string.ascii_uppercase + string.digits, k=10))
    txn = PaymentTransaction.objects.create(
        user=user,
        amount=50.0,
        currency='USD',
        country='ZW',
        provider='paynow',
        provider_config=config,
        transaction_type=TransactionType.PURCHASE,
        provider_reference=f'GAP_TEST_{rand_ref}',
        status=PaymentStatus.PENDING,
        enrollment_type='learnership',
        metadata={'program_id': programme.id}
    )
    
    print(f"Created pending transaction: {txn.id}")
    
    # 3. Use PaymentService to handle success (this simulates what the webhook would do)
    service = PaymentService()
    print("Simulating successful payment handling...")
    
    # We manually set status to successful and call _handle_successful_payment
    # In a real webhook, this is called by handle_webhook
    txn.status = PaymentStatus.SUCCESSFUL
    txn.save()
    
    # Note: _handle_successful_payment calls provision_enrollment_async.delay
    # We will call _provision_enrollment directly to avoid Celery issues in this script
    # We manually generate a reference_code to avoid the unique constraint issue for now
    ref = f"GAPTEST{int(timezone.now().timestamp())}"
    
    # We need to monkeypatch or just ensure it gets a ref
    # Actually, we can just create the object manually to test the service method
    # But service._provision_enrollment creates it internally.
    # Let's just fix the model logic temporarily in the script if possible, 
    # OR just set status to 'cash_pending' in the metadata so it triggers the generator
    
    service._provision_enrollment(user, 'learnership', programme.id, txn)
    
    # 4. Check results
    provisional_exists = ProvisionalEnrollment.objects.filter(payment_transaction=txn).exists()
    learnership_enrollment_exists = LearnershipEnrollment.objects.filter(payment_transaction=txn).exists()

    print(f"\nResults for Transaction {txn.id}:")
    print(f"ProvisionalEnrollment created: {provisional_exists}")
    print(f"LearnershipEnrollment created: {learnership_enrollment_exists}")

    if provisional_exists and learnership_enrollment_exists:
        print("\n✅ OK: Both ProvisionalEnrollment and LearnershipEnrollment were created.")
        # Verify data transfer
        le = LearnershipEnrollment.objects.get(payment_transaction=txn)
        print(f"   LearnershipEnrollment status: {le.status}")
        print(f"   Highest qualification: {le.highest_qualification}")
        print(f"   Employment status: {le.employment_status}")
    elif provisional_exists and not learnership_enrollment_exists:
        print("\n❌ GAP CONFIRMED: PaymentService only creates ProvisionalEnrollment, missing LearnershipEnrollment!")
    elif learnership_enrollment_exists:
        print("\n⚠️ PARTIAL: Only LearnershipEnrollment created, missing ProvisionalEnrollment!")
    else:
        print("\n❓ UNKNOWN: Neither enrollment was created.")

if __name__ == '__main__':
    test_webhook_provisioning_gap()
