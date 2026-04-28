# apps/enrollments/models.py
from django.db import models
from django.conf import settings
from django.utils import timezone
from django.utils.translation import gettext_lazy as _
from datetime import timedelta
import random
import string


class ProvisionalEnrollment(models.Model):
    """
    Provisional enrollments for cash payments and learnership prerequisite verification.

    Used for:
    1. Cash payments - Status 'cash_pending', expires in 14 days
    2. Learnership prerequisite verification - Status 'provisional', expires in 7 days
    """

    ENROLLMENT_TYPES = [
        ('masterclass', 'Masterclass'),
        ('learnership', 'Learnership'),
        ('industry', 'Industry Training'),
        ('custom_selection', 'Custom Selection'),
    ]

    STATUS_CHOICES = [
        ('cash_pending', 'Cash Payment Pending'),
        ('provisional', 'Provisional (Awaiting Verification)'),
        ('confirmed', 'Confirmed'),
        ('rejected', 'Rejected'),
        ('refunded', 'Refunded'),
        ('expired', 'Expired'),
    ]

    # Core fields
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='provisional_enrollments',
        null=True,
        blank=True,
        verbose_name=_("User")
    )
    programme = models.ForeignKey(
        'learnerships.LearnershipProgramme',
        on_delete=models.CASCADE,
        related_name='provisional_enrollments',
        null=True,
        blank=True,
        verbose_name=_("Programme")
    )
    payment_transaction = models.ForeignKey(
        'payments.PaymentTransaction',
        on_delete=models.CASCADE,
        related_name='provisional_enrollments',
        null=True,
        blank=True,
        verbose_name=_("Payment Transaction")
    )

    # Enrollment context
    enrollment_type = models.CharField(
        max_length=20,
        choices=ENROLLMENT_TYPES,
        verbose_name=_("Enrollment Type")
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='provisional',
        verbose_name=_("Status")
    )

    # Expiry tracking
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Created At")
    )
    expires_at = models.DateTimeField(
        verbose_name=_("Expires At")
    )

    # Verification tracking (for learnerships)
    prerequisites_verified = models.BooleanField(
        default=False,
        verbose_name=_("Prerequisites Verified")
    )
    verification_notes = models.TextField(
        blank=True,
        verbose_name=_("Verification Notes")
    )
    verified_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='verified_provisional_enrollments',
        verbose_name=_("Verified By")
    )
    verified_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_("Verified At")
    )

    # Reference code (for cash payments)
    reference_code = models.CharField(
        max_length=20,
        unique=True,
        blank=True,
        verbose_name=_("Reference Code")
    )

    # Metadata
    metadata = models.JSONField(
        default=dict,
        blank=True,
        verbose_name=_("Metadata")
    )

    class Meta:
        db_table = 'provisional_enrollments'
        verbose_name = _("Provisional Enrollment")
        verbose_name_plural = _("Provisional Enrollments")
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['status', 'expires_at']),
            models.Index(fields=['reference_code']),
            models.Index(fields=['user', 'status']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.enrollment_type} - {self.status}"


    def get_enrolled_item(self):
        """Mock get_enrolled_item for ChatEnforcerService compat"""
        if self.enrollment_type == 'learnership':
            return self.programme
        elif self.enrollment_type == 'masterclass':
            m_id = self.metadata.get('training_id') or self.programme_id
            if m_id:
                from apps.masterclasses.models import Masterclass
                try:
                    return Masterclass.objects.get(id=m_id)
                except Exception:
                    pass
        elif self.enrollment_type == 'industry':
            i_id = self.metadata.get('training_id') or self.programme_id
            if i_id:
                from apps.industry_based_training.models import IndustryBasedTraining
                try:
                    return IndustryBasedTraining.objects.get(id=i_id)
                except Exception:
                    pass
        return None

    def save(self, *args, **kwargs):
        # Auto-set expiry if not set
        if not self.expires_at:
            if self.status == 'cash_pending':
                # Rule: Payment must be made at least 3 days before the Training.
                # If training is more than 14 days away, they have 14 days to pay.
                # If less, they have until 3 days before the training.
                default_expiry = timezone.now() + timedelta(days=14)
                training_start_date = None
                
                # Extract training start date based on enrollment_type
                if self.enrollment_type == 'learnership' and self.programme:
                    training_start_date = self.programme.start_date
                else:
                    # Dynamically get start date if possible from other models
                    try:
                        if self.enrollment_type == 'masterclass':
                            from apps.masterclasses.models import Masterclass
                            m_id = self.metadata.get('training_id') or self.programme_id
                            if m_id:
                                training_start_date = Masterclass.objects.get(id=m_id).start_date
                        elif self.enrollment_type == 'industry':
                            from apps.industry_based_training.models import IndustryBasedTraining
                            i_id = self.metadata.get('training_id') or self.programme_id
                            if i_id:
                                training_start_date = IndustryBasedTraining.objects.get(id=i_id).start_date
                    except Exception:
                        pass
                
                if training_start_date:
                    if isinstance(training_start_date, timezone.datetime):
                        training_start = training_start_date
                    else:
                        training_start = timezone.datetime.combine(training_start_date, timezone.datetime.min.time()).replace(tzinfo=timezone.utc)
                    
                    deadline_before_training = training_start - timedelta(days=3)
                    self.expires_at = min(default_expiry, deadline_before_training)
                else:
                    self.expires_at = default_expiry
                    
            elif self.enrollment_type == 'learnership' and self.status == 'provisional':
                self.expires_at = timezone.now() + timedelta(days=7)
            else:
                self.expires_at = timezone.now() + timedelta(days=30)  # Default

        # Generate reference code if missing
        if not self.reference_code:
            self.reference_code = self.generate_reference_code()

        super().save(*args, **kwargs)

    def generate_reference_code(self):
        """Generate unique reference code for cash payments"""
        while True:
            date_part = timezone.now().strftime('%Y%m%d')
            random_part = ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))
            code = f"PROV{date_part}{random_part}"

            # Check uniqueness
            if not ProvisionalEnrollment.objects.filter(reference_code=code).exists():
                return code

    @property
    def is_expired(self):
        """Check if enrollment has expired"""
        return timezone.now() > self.expires_at and self.status in ['provisional', 'cash_pending']

    def confirm_enrollment(self):
        """Convert provisional to confirmed and trigger AICERTS enrollment"""
        from apps.aicerts_integration.services import SSOService

        self.status = 'confirmed'
        self.save()

        # Trigger AICERTS enrollment
        if self.programme:
            sso_service = SSOService()
            # Get courses from programme phases
            courses = []
            for phase in self.programme.phases.all():
                courses.extend(phase.courses.all())

            for course in courses:
                try:
                    sso_service.enroll_user(self.user, course)
                except Exception as e:
                    import logging
                    logger = logging.getLogger(__name__)
                    logger.error(f"Failed to enroll user {self.user.email} in course {course.id}: {e}")

    def reject_and_refund(self, reason):
        """Reject enrollment and trigger refund"""
        from apps.payments.services.payment_service import payment_service

        self.status = 'rejected'
        self.verification_notes = reason
        self.save()

        # Trigger refund if payment was made
        if self.payment_transaction and self.payment_transaction.status == 'successful':
            try:
                payment_service.refund_payment(
                    transaction_id=str(self.payment_transaction.id),
                    amount=float(self.payment_transaction.amount),
                    reason=f"Prerequisite verification failed: {reason}"
                )

                self.status = 'refunded'
                self.save()
            except Exception as e:
                import logging
                logger = logging.getLogger(__name__)
                logger.error(f"Failed to refund payment transaction {self.payment_transaction.id}: {e}")
