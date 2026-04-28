# apps/learnerships/models.py
from django.db import models
from django.utils import timezone
from apps.users.models import User

# -----------------------------------
# Learnership Programme & Phases
# -----------------------------------

class LearnershipProgramme(models.Model):
    title = models.CharField(max_length=255)
    role = models.CharField(max_length=255, blank=True)
    slug = models.SlugField(unique=True, null=True, blank=True, max_length=500)
    specialization = models.CharField(max_length=255, blank=True)
    nqf_level = models.CharField(max_length=50, blank=True)
    duration_months = models.PositiveIntegerField(default=12)
    duration_weeks = models.PositiveIntegerField(blank=True, null=True)
    description = models.TextField(blank=True)
    focus = models.TextField(blank=True)
    prerequisites = models.JSONField(default=list, blank=True)
    entry_requirements = models.TextField(blank=True)
    career_outcomes = models.TextField(blank=True)
    target_audience = models.TextField(blank=True)
    category = models.CharField(max_length=100, blank=True)
    status = models.CharField(max_length=20, default='open')
    max_participants = models.PositiveIntegerField(default=35)
    current_participants = models.PositiveIntegerField(default=0)
    enrollment_deadline = models.DateField(null=True, blank=True)
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)
    provider = models.CharField(max_length=255, default='Hosi Academy')
    accreditation_body = models.CharField(max_length=255, blank=True)
    certificate = models.CharField(max_length=255, blank=True)
    delivery_mode = models.CharField(max_length=20, default='hybrid')
    location = models.CharField(max_length=255, blank=True)
    country = models.CharField(max_length=100, blank=True)
    city = models.CharField(max_length=100, blank=True)
    stipend_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    currency = models.CharField(max_length=3, default='ZAR')
    is_funded = models.BooleanField(default=False)
    is_featured = models.BooleanField(default=False)
    active = models.BooleanField(default=True)
    is_offered = models.BooleanField(default=True, help_text="Whether this learnership is currently offered to the public. If False, hidden from frontend but still selectable in backend.")
    image_url = models.URLField(blank=True, null=True)
    skills = models.JSONField(default=list, blank=True)
    modules = models.JSONField(default=list, blank=True)
    cost_usd = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    intake_frequency = models.CharField(max_length=50, blank=True)
    
    # Instructor assignment
    instructor = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_learnerships',
        verbose_name="Assigned Instructor",
        help_text="The instructor assigned to teach this learnership programme"
    )
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Learnership Programme"
        verbose_name_plural = "Learnership Programmes"
        ordering = ['title']

    def __str__(self):
        return self.title


class LearnershipPhase(models.Model):
    programme = models.ForeignKey(LearnershipProgramme, on_delete=models.CASCADE, related_name='phases')
    name = models.CharField(max_length=255)
    order = models.PositiveIntegerField(default=1)
    start_date = models.DateField()
    end_date = models.DateField()
    duration_weeks = models.PositiveIntegerField()
    description = models.TextField(blank=True)

    class Meta:
        ordering = ['programme', 'order']
        verbose_name = "Learnership Phase"
        verbose_name_plural = "Learnership Phases"

    def __str__(self):
        return f"{self.programme.title} - {self.name}"


# -----------------------------------
# Generic Courses (can be AiCerts or other providers)
# -----------------------------------

class CourseProvider(models.Model):
    name = models.CharField(max_length=255)
    website = models.URLField(blank=True)
    active = models.BooleanField(default=True)

    def __str__(self):
        return self.name


class Course(models.Model):
    provider = models.ForeignKey(CourseProvider, on_delete=models.CASCADE, related_name="courses")
    external_id = models.CharField(max_length=255, blank=True, null=True)
    title = models.CharField(max_length=255)
    shortname = models.CharField(max_length=100, blank=True)
    summary = models.TextField(blank=True)
    category_name = models.CharField(max_length=255, blank=True)
    last_synced = models.DateTimeField(default=timezone.now)
    active = models.BooleanField(default=True)

    def __str__(self):
        return f"{self.title} ({self.provider.name})"


# -----------------------------------
# Link courses to Learnership Phases
# -----------------------------------

class PhaseCourse(models.Model):
    phase = models.ForeignKey(LearnershipPhase, on_delete=models.CASCADE, related_name="courses")
    course = models.ForeignKey(Course, on_delete=models.CASCADE)
    order = models.PositiveIntegerField(default=1)  # order in the phase

    class Meta:
        unique_together = ('phase', 'course')
        ordering = ['phase', 'order']

    def __str__(self):
        return f"{self.phase.name} - {self.course.title}"


# -----------------------------------
# Enrollments
# -----------------------------------

class EnrollmentStatus(models.TextChoices):
    """Status choices for Learnership Enrollment"""
    PROVISIONAL = 'provisional', 'Provisional (Payment Pending)'
    PAYMENT_PENDING = 'payment_pending', 'Payment Pending (Cash Promise)'
    PAYMENT_PARTIAL = 'payment_partial', 'Partial Payment Made (Debit Order Setup)'
    PAYMENT_COMPLETE = 'payment_complete', 'Payment Complete'
    PENDING_EVIDENCE = 'pending_evidence', 'Pending Evidence Upload'
    EVIDENCE_SUBMITTED = 'evidence_submitted', 'Evidence Submitted'
    UNDER_REVIEW = 'under_review', 'Under Review'
    CONFIRMED = 'confirmed', 'Confirmed (Payment + Prerequisites Met)'
    REJECTED = 'rejected', 'Rejected (Prerequisites Not Met)'
    REFUNDED = 'refunded', 'Refunded'
    EXPIRED = 'expired', 'Expired'


# -----------------------------------
# Certification Tracks (Blue Teamer, Bug Hunter, etc.)
# -----------------------------------

class CertificationTrack(models.Model):
    """Certification tracks like Blue Teamer, Bug Hunter"""
    TRACK_TYPES = [
        ('blue_teamer', 'Blue Teamer'),
        ('bug_hunter', 'Bug Hunter'),
        ('ai_security', 'AI Security Specialist'),
        ('cloud_security', 'Cloud Security Engineer'),
    ]
    
    name = models.CharField(max_length=255, unique=True)
    track_type = models.CharField(max_length=50, choices=TRACK_TYPES)
    description = models.TextField(blank=True)
    total_cert_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    platform_cost = models.DecimalField(max_digits=10, decimal_places=2, default=240)  # $20×12
    instructor_cost = models.DecimalField(max_digits=10, decimal_places=2, default=600)  # $50×12
    total_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    sales_price = models.DecimalField(max_digits=10, decimal_places=2, default=0)  # 50% markup
    monthly_price = models.DecimalField(max_digits=10, decimal_places=2, default=0)  # ÷12
    gross_margin = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        verbose_name = "Certification Track"
        verbose_name_plural = "Certification Tracks"
        ordering = ['name']
    
    def __str__(self):
        return self.name
    
    def calculate_pricing(self):
        """Calculate all pricing fields"""
        self.total_cost = self.total_cert_cost + self.platform_cost + self.instructor_cost
        self.sales_price = self.total_cost * 1.5  # 50% markup
        self.monthly_price = self.sales_price / 12
        self.gross_margin = self.sales_price - self.total_cost
        self.save()


class CertificationItem(models.Model):
    """Individual certifications within a track"""
    PHASE_CHOICES = [
        ('phase_1_foundation', 'Phase 1 – Foundation'),
        ('phase_2_vendor_spec', 'Phase 2 – Vendor Spec'),
        ('phase_3_practical', 'Phase 3 – Practical/Readiness'),
    ]
    
    track = models.ForeignKey(CertificationTrack, on_delete=models.CASCADE, related_name='certifications')
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    phase = models.CharField(max_length=50, choices=PHASE_CHOICES)
    cert_cost = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    order = models.PositiveIntegerField(default=1)
    active = models.BooleanField(default=True)
    
    class Meta:
        verbose_name = "Certification Item"
        verbose_name_plural = "Certification Items"
        ordering = ['track', 'phase', 'order']
    
    def __str__(self):
        return f"{self.track.name} - {self.name}"
    ACTIVE = 'active', 'Active (Learning in Progress)'
    COMPLETED = 'completed', 'Completed'
    DROPPED_OUT = 'dropped_out', 'Dropped Out'
    DEBIT_ORDER_PENDING = 'debit_order_pending', 'Debit Order Setup Pending'


class LearnershipEnrollment(models.Model):
    """
    Dedicated Learnership Enrollment model.
    
    Unlike Masterclasses, Learnerships require:
    1. Prerequisite verification before confirmation
    2. Evidence upload and admin approval
    3. Phase and schedule assignment
    4. Corporate enrollment support with company details
    """
    programme = models.ForeignKey(
        LearnershipProgramme,
        on_delete=models.PROTECT,
        related_name='enrollments'
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='learnership_enrollments'
    )
    
    # Enrollment Status Tracking
    status = models.CharField(
        max_length=20,
        choices=EnrollmentStatus.choices,
        default=EnrollmentStatus.PROVISIONAL,
        help_text="Current enrollment status in the learnership pathway"
    )
    
    # Enrollment Type
    enrollment_type = models.CharField(
        max_length=20,
        choices=[
            ('individual', 'Individual Enrollment'),
            ('corporate', 'Corporate Enrollment'),
        ],
        default='individual'
    )
    
    # Corporate Enrollment Fields
    company_name = models.CharField(max_length=255, blank=True)
    company_registration_number = models.CharField(max_length=100, blank=True)
    company_tax_number = models.CharField(max_length=100, blank=True)
    company_contact_person = models.CharField(max_length=255, blank=True)
    company_email = models.EmailField(blank=True)
    company_phone = models.CharField(max_length=50, blank=True)
    company_address = models.TextField(blank=True)
    company_country = models.ForeignKey(
        'localization.Country',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='corporate_learnership_enrollments'
    )
    
    # Payment Tracking
    payment_transaction = models.ForeignKey(
        'payments.PaymentTransaction',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='learnership_enrollments'
    )
    payment_status = models.CharField(
        max_length=30,
        default='pending',
        choices=[
            ('pending', 'Pending'),
            ('cash_promise', 'Cash Promise (To Pay at Office)'),
            ('partial_paid', 'Partially Paid (Deposit + Debit Order)'),
            ('paid', 'Paid in Full'),
            ('refunded', 'Refunded'),
            ('failed', 'Failed'),
            ('debit_order_active', 'Debit Order Active'),
        ]
    )
    amount_paid = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True
    )
    currency = models.CharField(max_length=3, default='USD')
    
    # Debit Order Information (for installment payments)
    debit_order_reference = models.CharField(max_length=100, blank=True)
    debit_order_start_date = models.DateField(null=True, blank=True)
    debit_order_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Monthly debit order amount"
    )
    debit_order_active = models.BooleanField(default=False)
    
    # Cash Payment Tracking (for cash at office)
    cash_payment_reference = models.CharField(max_length=100, blank=True)
    cash_payment_due_date = models.DateField(null=True, blank=True)
    cash_payment_office = models.CharField(
        max_length=255,
        blank=True,
        help_text="Office location where cash payment should be made"
    )
    
    # Payment Plan Details
    payment_plan_type = models.CharField(
        max_length=30,
        default='full',
        choices=[
            ('full', 'Full Payment'),
            ('deposit_debit', 'Deposit + Debit Order'),
            ('cash_office', 'Cash at Office'),
        ]
    )
    total_amount = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    deposit_paid = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    installments_remaining = models.PositiveIntegerField(default=0)
    
    # Prerequisites Verification
    prerequisites_verified = models.BooleanField(default=False)
    verification_notes = models.TextField(
        blank=True,
        help_text="Admin notes on prerequisite verification"
    )
    verified_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='verified_learnership_enrollments'
    )
    verified_at = models.DateTimeField(null=True, blank=True)
    
    # Timeline
    enrolled_at = models.DateTimeField(auto_now_add=True)
    confirmed_at = models.DateTimeField(null=True, blank=True)
    started_at = models.DateTimeField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    dropped_out_at = models.DateTimeField(null=True, blank=True)

    # Active flag (legacy support)
    active = models.BooleanField(default=True)

    # ===== ACADEMIC & EMPLOYMENT INFORMATION (For SETA Compliance) =====
    highest_qualification = models.CharField(max_length=255, blank=True)
    qualification_institution = models.CharField(max_length=255, blank=True)
    qualification_year = models.CharField(max_length=10, blank=True)
    education_level = models.CharField(max_length=100, blank=True)
    employer = models.CharField(max_length=255, blank=True)
    job_title = models.CharField(max_length=255, blank=True)
    employment_status = models.CharField(
        max_length=50,
        blank=True,
        choices=[
            ('employed', 'Employed'),
            ('unemployed', 'Unemployed'),
            ('student', 'Student'),
            ('self_employed', 'Self Employed'),
        ]
    )
    monthly_income = models.CharField(max_length=50, blank=True, help_text='For SETA reporting')
    existing_skills = models.TextField(blank=True)

    # ===== DEMOGRAPHICS (For SETA/Employment Equity Reporting) =====
    race = models.CharField(max_length=50, blank=True)
    disability = models.CharField(
        max_length=10,
        blank=True,
        choices=[('yes', 'Yes'), ('no', 'No')]
    )
    nationality = models.CharField(max_length=100, blank=True)

    # ===== NEXT OF KIN =====
    next_of_kin_name = models.CharField(max_length=255, blank=True)
    next_of_kin_phone = models.CharField(max_length=50, blank=True)
    next_of_kin_relationship = models.CharField(max_length=100, blank=True)
    next_of_kin_email = models.EmailField(blank=True, max_length=254)
    next_of_kin_address = models.TextField(blank=True)

    # ===== MEDICAL & ACCESSIBILITY =====
    medical_conditions = models.TextField(blank=True)
    allergies = models.TextField(blank=True)
    medications = models.TextField(blank=True)
    accessibility_needs = models.TextField(blank=True)

    # ===== LEARNING SUPPORT =====
    requires_learning_support = models.CharField(
        max_length=10,
        blank=True,
        choices=[('yes', 'Yes'), ('no', 'No')]
    )
    learning_support_details = models.TextField(blank=True)
    has_previous_learnership_experience = models.CharField(
        max_length=10,
        blank=True,
        choices=[('yes', 'Yes'), ('no', 'No')]
    )
    previous_learnership_details = models.TextField(blank=True)

    # ===== DOCUMENTATION CHECKLIST =====
    has_id_copy = models.BooleanField(default=False)
    has_qualification_certificates = models.BooleanField(default=False)
    has_proof_of_residence = models.BooleanField(default=False)
    has_cv = models.BooleanField(default=False)
    has_motivational_letter = models.BooleanField(default=False)

    # ===== PAYMENT & FUNDING =====
    funding_source = models.CharField(
        max_length=50,
        blank=True,
        choices=[
            ('self_funded', 'Self Funded'),
            ('company_funded', 'Company Funded'),
            ('seta', 'SETA'),
            ('nsfas', 'NSFAS'),
            ('other', 'Other'),
        ]
    )
    company_vat_number = models.CharField(max_length=100, blank=True)
    purchase_order_number = models.CharField(max_length=100, blank=True)

    # ===== DEBIT ORDER DETAILS =====
    requires_debit_order = models.CharField(
        max_length=10,
        blank=True,
        choices=[('yes', 'Yes'), ('no', 'No')]
    )
    bank_name = models.CharField(max_length=100, blank=True)
    bank_account_number = models.CharField(max_length=50, blank=True)
    bank_branch_code = models.CharField(max_length=20, blank=True)
    bank_account_type = models.CharField(
        max_length=20,
        blank=True,
        choices=[
            ('savings', 'Savings'),
            ('cheque', 'Cheque/Current'),
        ]
    )
    bank_account_holder_name = models.CharField(max_length=255, blank=True)

    # ===== DECLARATIONS =====
    terms_accepted = models.BooleanField(default=False)
    data_protection_accepted = models.BooleanField(default=False)
    certification_declaration_accepted = models.BooleanField(default=False)
    seta_declaration_accepted = models.BooleanField(default=False)

    # ===== ADDITIONAL =====
    referral_source = models.CharField(max_length=255, blank=True, help_text='How did you hear about us')

    # Student profile linkage
    student_id = models.BigIntegerField(null=True, blank=True, help_text="FK to learner_portal_studentprofile.id")

    # Payment gateway details
    payment_gateway = models.CharField(max_length=100, blank=True, null=True)
    payment_gateway_metadata = models.JSONField(default=dict, null=True, blank=True)

    # Metadata for additional data
    metadata = models.JSONField(default=dict, blank=True)

    class Meta:
        verbose_name = "Learnership Enrollment"
        verbose_name_plural = "Learnership Enrollments"
        ordering = ['-enrolled_at']
        unique_together = ('programme', 'user')
        indexes = [
            models.Index(fields=['status', 'enrolled_at']),
            models.Index(fields=['user', 'status']),
            models.Index(fields=['programme', 'status']),
        ]

    def __str__(self):
        return f"{self.user.display_name} - {self.programme.title} ({self.get_status_display()})"

    def get_enrolled_item(self):
        """Return the enrolled item (programme) for chat room setup"""
        return self.programme

    @property
    def has_all_evidence_submitted(self):
        """Check if all prerequisite evidence has been submitted"""
        if not self.programme.prerequisites:
            return True
        submitted_count = self.prerequisite_evidences.filter(
            status__in=['submitted', 'approved']
        ).count()
        return submitted_count >= len(self.programme.prerequisites)

    @property
    def has_all_evidence_approved(self):
        """Check if all prerequisite evidence has been approved"""
        if not self.programme.prerequisites:
            return True
        approved_count = self.prerequisite_evidences.filter(
            status='approved'
        ).count()
        return approved_count >= len(self.programme.prerequisites)

    @property
    def pending_evidence_count(self):
        """Get count of evidence still pending submission"""
        if not self.programme.prerequisites:
            return 0
        submitted_keys = set(
            self.prerequisite_evidences.values_list('prerequisite_key', flat=True)
        )
        return len(self.programme.prerequisites) - len(submitted_keys)

    def auto_update_status(self):
        """
        Automatically update enrollment status based on payment AND evidence.
        
        Business Logic:
        - Payment must be honoured (paid OR debit order active)
        - Prerequisites must be validated
        - Both conditions are INDEPENDENT - student can upload evidence before payment is honoured
        - Full enrollment (CONFIRMED) requires BOTH conditions met
        """
        old_status = self.status
        
        # Check payment status
        paymentHonoured = self._is_payment_honoured()
        
        # Check prerequisites status
        prerequisitesMet = self.has_all_evidence_approved
        
        # Determine status based on both conditions
        if paymentHonoured and prerequisitesMet:
            # BOTH conditions met - full enrollment confirmed
            if self.status != EnrollmentStatus.CONFIRMED:
                self.status = EnrollmentStatus.CONFIRMED
                self.confirmed_at = timezone.now()
                if not self.prerequisites_verified:
                    self.prerequisites_verified = True
        elif paymentHonoured and not prerequisitesMet:
            # Payment OK but prerequisites pending
            if not self.has_all_evidence_submitted:
                self.status = EnrollmentStatus.PENDING_EVIDENCE
            elif not self.has_all_evidence_approved:
                if self.prerequisite_evidences.filter(status='pending_review').exists():
                    self.status = EnrollmentStatus.UNDER_REVIEW
                else:
                    self.status = EnrollmentStatus.EVIDENCE_SUBMITTED
        elif not paymentHonoured and prerequisitesMet:
            # Prerequisites OK but payment pending
            if self.payment_status == 'cash_promise':
                self.status = EnrollmentStatus.PAYMENT_PENDING
            elif self.payment_status == 'partial_paid' or not self.debit_order_active:
                self.status = EnrollmentStatus.DEBIT_ORDER_PENDING
            else:
                self.status = EnrollmentStatus.PROVISIONAL
        else:
            # Neither condition met
            if self.payment_status == 'cash_promise':
                self.status = EnrollmentStatus.PAYMENT_PENDING
            else:
                self.status = EnrollmentStatus.PROVISIONAL

        # Log status change if it happened
        if old_status != self.status:
            EnrollmentStatusHistory.objects.create(
                enrollment=self,
                from_status=old_status,
                to_status=self.status,
                reason='Auto-updated based on payment and evidence status'
            )
    
    def _is_payment_honoured(self):
        """
        Check if payment is honoured.
        
        Payment is honoured if:
        - Paid in full, OR
        - Debit order is active (deposit + debit order arrangement), OR
        - Cash payment has been received (not just promised)
        """
        if self.payment_status == 'paid':
            return True
        if self.payment_status == 'debit_order_active' and self.debit_order_active:
            return True
        return False

    def confirm_enrollment(self, verified_by=None, reason=''):
        """
        Manually confirm enrollment after prerequisite verification.
        """
        self.status = EnrollmentStatus.CONFIRMED
        self.prerequisites_verified = True
        self.verified_by = verified_by
        self.verified_at = timezone.now()
        self.verification_notes = reason
        self.confirmed_at = timezone.now()
        self.save()

        EnrollmentStatusHistory.objects.create(
            enrollment=self,
            from_status=self.status,
            to_status=EnrollmentStatus.CONFIRMED,
            changed_by=verified_by,
            reason=reason or 'Prerequisites verified and approved'
        )

    def reject_enrollment(self, verified_by=None, reason=''):
        """
        Reject enrollment due to prerequisites not being met.
        Triggers refund process.
        """
        old_status = self.status
        self.status = EnrollmentStatus.REJECTED
        self.prerequisites_verified = False
        self.verified_by = verified_by
        self.verified_at = timezone.now()
        self.verification_notes = reason
        self.save()

        EnrollmentStatusHistory.objects.create(
            enrollment=self,
            from_status=old_status,
            to_status=EnrollmentStatus.REJECTED,
            changed_by=verified_by,
            reason=reason or 'Prerequisites not met'
        )

        # Trigger refund if payment was made
        if self.payment_transaction and self.payment_transaction.status == 'successful':
            self._trigger_refund(reason)

    def _trigger_refund(self, reason):
        """Trigger refund process for rejected enrollment"""
        try:
            from apps.payments.services.payment_service import payment_service
            payment_service.refund_payment(
                transaction_id=str(self.payment_transaction.id),
                amount=float(self.payment_transaction.amount),
                reason=f"Learnership prerequisites not met: {reason}"
            )
            self.payment_status = 'refunded'
            self.status = EnrollmentStatus.REFUNDED
            self.save()
        except Exception as e:
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Failed to refund enrollment {self.id}: {e}")


# -----------------------------------
# Prerequisite Evidence Tracking
# -----------------------------------

class PrerequisiteEvidenceStatus(models.TextChoices):
    """Status choices for prerequisite evidence"""
    PENDING_SUBMISSION = 'pending_submission', 'Pending Submission'
    SUBMITTED = 'submitted', 'Submitted'
    PENDING_REVIEW = 'pending_review', 'Pending Review'
    APPROVED = 'approved', 'Approved'
    REJECTED = 'rejected', 'Rejected (Resubmission Required)'


class PrerequisiteEvidence(models.Model):
    """
    Tracks evidence uploaded by learners to prove they meet prerequisites.
    
    Example: For "Bachelor's Degree in Computer Science" prerequisite,
    learner uploads their degree certificate as evidence.
    """
    enrollment = models.ForeignKey(
        LearnershipEnrollment,
        on_delete=models.CASCADE,
        related_name='prerequisite_evidences'
    )
    
    # Which prerequisite this evidence is for
    prerequisite_key = models.CharField(
        max_length=100,
        help_text="Index or key of the prerequisite in programme.prerequisites list"
    )
    prerequisite_name = models.CharField(
        max_length=255,
        help_text="Human-readable name of the prerequisite"
    )
    
    # Evidence file
    evidence_file = models.FileField(
        upload_to='learnerships/evidence/%Y/%m/%d/',
        help_text="Uploaded document proving prerequisite completion"
    )
    file_type = models.CharField(max_length=50, blank=True)
    file_size = models.PositiveIntegerField(blank=True, null=True)
    
    # Description from learner
    evidence_description = models.TextField(
        blank=True,
        help_text="Learner's description of the uploaded evidence"
    )
    
    # Status tracking
    status = models.CharField(
        max_length=20,
        choices=PrerequisiteEvidenceStatus.choices,
        default=PrerequisiteEvidenceStatus.PENDING_SUBMISSION
    )
    
    # Review tracking
    reviewed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_evidences'
    )
    reviewed_at = models.DateTimeField(null=True, blank=True)
    review_notes = models.TextField(
        blank=True,
        help_text="Admin notes on why evidence was approved/rejected"
    )
    
    # Timestamps
    uploaded_at = models.DateTimeField(auto_now_add=True)
    resubmission_count = models.PositiveIntegerField(default=0)

    class Meta:
        verbose_name = "Prerequisite Evidence"
        verbose_name_plural = "Prerequisite Evidences"
        ordering = ['enrollment', 'prerequisite_key']
        unique_together = ('enrollment', 'prerequisite_key')

    def __str__(self):
        return f"{self.enrollment.user.display_name} - {self.prerequisite_name} ({self.get_status_display()})"

    def approve(self, reviewed_by=None, notes=''):
        """Approve this evidence"""
        self.status = PrerequisiteEvidenceStatus.APPROVED
        self.reviewed_by = reviewed_by
        self.reviewed_at = timezone.now()
        self.review_notes = notes
        self.save()

        # Update parent enrollment status
        self.enrollment.auto_update_status()

    def reject(self, reviewed_by=None, notes=''):
        """Reject this evidence (requires resubmission)"""
        self.status = PrerequisiteEvidenceStatus.REJECTED
        self.reviewed_by = reviewed_by
        self.reviewed_at = timezone.now()
        self.review_notes = notes
        self.resubmission_count += 1
        self.save()

        # Update parent enrollment status
        self.enrollment.auto_update_status()

    def submit(self):
        """Mark evidence as submitted"""
        self.status = PrerequisiteEvidenceStatus.SUBMITTED
        self.save()

        # Update parent enrollment status
        self.enrollment.auto_update_status()


# -----------------------------------
# Enrollment Status History (Audit Trail)
# -----------------------------------

class EnrollmentStatusHistory(models.Model):
    """
    Audit trail for enrollment status changes.
    Tracks who changed the status and why.
    """
    enrollment = models.ForeignKey(
        LearnershipEnrollment,
        on_delete=models.CASCADE,
        related_name='status_history'
    )
    from_status = models.CharField(max_length=20)
    to_status = models.CharField(max_length=20)
    changed_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
    reason = models.TextField(blank=True)
    changed_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = "Enrollment Status History"
        verbose_name_plural = "Enrollment Status Histories"
        ordering = ['-changed_at']

    def __str__(self):
        return f"{self.enrollment.user.display_name}: {self.from_status} → {self.to_status} ({self.changed_at})"


class LearnershipSchedule(models.Model):
    enrollment = models.ForeignKey(LearnershipEnrollment, on_delete=models.CASCADE, related_name='schedules')
    phase = models.ForeignKey(LearnershipPhase, on_delete=models.PROTECT, related_name='schedules')
    start_date = models.DateField()
    end_date = models.DateField()
    country = models.ForeignKey('localization.Country', on_delete=models.SET_NULL, null=True, blank=True)
    state = models.ForeignKey('localization.State', on_delete=models.SET_NULL, null=True, blank=True)
    location = models.ForeignKey('localization.City', on_delete=models.SET_NULL, null=True, blank=True, verbose_name="City/Location")
    venue = models.CharField(max_length=200, default='TBA')
    max_participants = models.PositiveIntegerField(default=35)
    current_participants = models.PositiveIntegerField(default=0)
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ['start_date']

    def __str__(self):
        return f"{self.enrollment.user.display_name} - {self.phase.name}"

    @property
    def seats_remaining(self):
        return max(0, self.max_participants - self.current_participants)

    @property
    def is_full(self):
        return self.current_participants >= self.max_participants

    @property
    def duration_days(self):
        return (self.end_date - self.start_date).days + 1
