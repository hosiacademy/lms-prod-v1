import os
import django
import uuid
from decimal import Decimal

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from django.utils import timezone
from django.contrib.contenttypes.models import ContentType
from apps.users.models import User
from apps.payments.models import Enrollment, PaymentTransaction, Order, EnrollmentType, EnrollmentStatus
from apps.masterclasses.models import Masterclass
from apps.notifications.services import NotificationService


def trigger_test_emails(email):
    user = User.objects.filter(email=email).first()
    if not user:
        print(f"[ERROR] User {email} not found")
        return

    print(f"[OK] Found user: {user.email} (ID: {user.id})")

    masterclass = Masterclass.objects.first()
    if not masterclass:
        print("[ERROR] No masterclasses found in the database.")
        return
    print(f"[OK] Using masterclass: {masterclass.title} (ID: {masterclass.id})")

    # ── 1. GET OR CREATE ORDER ─────────────────────────────────────────────
    order = Order.objects.filter(user=user, status='completed').first()
    if not order:
        order = Order.objects.create(
            user=user,
            tracking=f"TEST-ORD-{uuid.uuid4().hex[:8].upper()}",
            amount=Decimal('84.00'),
            currency='USD',
            status='completed',
            payment_method='smatpay',
            smatpay_fee_amount=Decimal('0.00'),
            smatpay_fee_percentage=Decimal('0.00'),
            metadata={},
        )
        print(f"[OK] Created order: {order.tracking}")
    else:
        print(f"[OK] Using existing order: {order.tracking}")

    # ── 2. GET OR CREATE ENROLLMENT ────────────────────────────────────────
    enrollment = Enrollment.objects.filter(user=user, order=order).first()
    if not enrollment:
        ct = ContentType.objects.get_for_model(masterclass)
        enrollment = Enrollment.objects.create(
            user=user,
            order=order,
            enrollment_type=EnrollmentType.MASTERCLASS,
            content_type=ct,
            object_id=masterclass.id,
            enrollment_code=f"TEST-ENR-{uuid.uuid4().hex[:8].upper()}",
            status=EnrollmentStatus.ENROLLED,
            learner_full_name=user.get_full_name() or "Maza Ndota Takawira",
            learner_email=user.email,
            learner_phone="+27 67 231 9200",
            learner_country="South Africa",
            currency="USD",
            final_amount=Decimal('84.00'),
            enrolled_at=timezone.now(),
        )
        print(f"[OK] Created enrollment: {enrollment.enrollment_code}")
    else:
        print(f"[OK] Using existing enrollment: {enrollment.enrollment_code}")

    # ── 3. GET OR CREATE PAYMENT TRANSACTION ───────────────────────────────
    transaction = PaymentTransaction.objects.filter(user=user, order=order).first()
    if not transaction:
        transaction = PaymentTransaction.objects.create(
            user=user,
            order=order,
            amount=Decimal('84.00'),
            currency='USD',
            status='successful',
            provider='smatpay',
            provider_reference=f"SMAT-{uuid.uuid4().hex[:8].upper()}",
            completed_at=timezone.now(),
            description=f"Payment for {masterclass.title}",
        )
        print(f"[OK] Created transaction: {transaction.provider_reference}")
    else:
        print(f"[OK] Using existing transaction: {transaction.provider_reference}")

    # ── 4. SEND EMAILS ─────────────────────────────────────────────────────

    print("\n--- [1/3] Testing Enrollment Success Email ---")
    try:
        NotificationService.send_enrollment_notifications(
            enrollment_id=enrollment.id,
            success=True,
        )
        print("✅ Enrollment Success email sent")
    except Exception as e:
        print(f"❌ Enrollment Success failed: {e}")

    print("\n--- [2/3] Testing Payment Confirmation Email ---")
    try:
        from apps.payments.tasks import send_payment_confirmation_email
        send_payment_confirmation_email(str(transaction.id))
        print("✅ Payment Confirmation email sent")
    except Exception as e:
        print(f"❌ Payment Confirmation failed: {e}")

    print("\n--- [3/3] Testing EFT Initiated Email ---")
    try:
        from apps.payments.tasks import send_eft_initiated_email
        send_eft_initiated_email(str(transaction.id))
        print("✅ EFT Initiated email sent")
    except Exception as e:
        print(f"❌ EFT Initiated failed: {e}")

    print("\n========================================")
    print(f"Test emails dispatched to: {email}")
    print("Check the inbox to verify branding, logo, and gradients.")
    print("========================================")


if __name__ == "__main__":
    trigger_test_emails('mazandotakawira@gmail.com')
