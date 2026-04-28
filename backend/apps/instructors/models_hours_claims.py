# apps/instructors/models_hours_claims.py
"""
Instructor Hours Claims Management

Models for tracking instructor teaching hours, overtime claims, and payroll processing.
Integrated with BBB session data for automatic hours calculation.
"""

from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
import uuid


class InstructorHoursClaim(models.Model):
    """
    Monthly hours claim submitted by instructors for payment processing.
    Automatically populates regular hours from completed BBB sessions.
    """

    STATUS_CHOICES = [
        ('draft', 'Draft'),
        ('pending', 'Pending Review'),
        ('under_review', 'Under Review'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
        ('paid', 'Paid'),
    ]

    # Claim ID
    claim_id = models.CharField(
        max_length=50,
        unique=True,
        editable=False,
        verbose_name=_("Claim ID")
    )

    # Instructor
    instructor = models.ForeignKey(
        'instructors.Instructor',
        on_delete=models.CASCADE,
        related_name='hours_claims',
        verbose_name=_("Instructor")
    )

    # Claim Period
    month = models.PositiveIntegerField(
        choices=[
            (1, 'January'), (2, 'February'), (3, 'March'), (4, 'April'),
            (5, 'May'), (6, 'June'), (7, 'July'), (8, 'August'),
            (9, 'September'), (10, 'October'), (11, 'November'), (12, 'December')
        ],
        verbose_name=_("Month")
    )

    year = models.PositiveIntegerField(
        verbose_name=_("Year")
    )

    # Hours Breakdown
    regular_hours = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        default=0.00,
        verbose_name=_("Regular Hours")
    )

    overtime_hours = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        default=0.00,
        verbose_name=_("Overtime Hours")
    )

    total_hours = models.DecimalField(
        max_digits=8,
        decimal_places=2,
        editable=False,
        verbose_name=_("Total Hours")
    )

    # Payment Details
    hourly_rate = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name=_("Hourly Rate")
    )

    overtime_rate_multiplier = models.DecimalField(
        max_digits=3,
        decimal_places=2,
        default=1.50,
        verbose_name=_("Overtime Rate Multiplier"),
        help_text=_("Overtime pay multiplier (default 1.5x)")
    )

    regular_pay = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        editable=False,
        verbose_name=_("Regular Pay")
    )

    overtime_pay = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        editable=False,
        verbose_name=_("Overtime Pay")
    )

    total_claim_amount = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        editable=False,
        verbose_name=_("Total Claim Amount")
    )

    # Session Details (auto-populated from BBB)
    session_ids = models.JSONField(
        default=list,
        verbose_name=_("Session IDs"),
        help_text=_("List of BBB session IDs included in this claim")
    )

    session_breakdown = models.JSONField(
        default=list,
        verbose_name=_("Session Breakdown"),
        help_text=_("Detailed breakdown of sessions with dates and durations")
    )

    # Overtime Justification
    overtime_justification = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Overtime Justification"),
        help_text=_("Reason for overtime hours claimed")
    )

    overtime_supporting_documents = models.FileField(
        upload_to='instructor_overtime_supporting/',
        blank=True,
        null=True,
        verbose_name=_("Supporting Documents")
    )

    # Status & Processing
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='draft',
        verbose_name=_("Status")
    )

    # HR Admin Processing
    submitted_at = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name=_("Submitted At")
    )

    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_hours_claims',
        verbose_name=_("Reviewed By (HR Admin)")
    )

    reviewed_at = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name=_("Reviewed At")
    )

    approval_notes = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Approval Notes")
    )

    rejection_reason = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Rejection Reason")
    )

    # Payment Processing
    paid_at = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name=_("Paid At")
    )

    payment_reference = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        verbose_name=_("Payment Reference")
    )

    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Created At")
    )

    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_("Updated At")
    )

    class Meta:
        db_table = 'instructor_hours_claims'
        verbose_name = _('Instructor Hours Claim')
        verbose_name_plural = _('Instructor Hours Claims')
        ordering = ['-year', '-month', '-created_at']
        indexes = [
            models.Index(fields=['instructor', 'year', 'month']),
            models.Index(fields=['status', 'submitted_at']),
            models.Index(fields=['year', 'month']),
        ]

    def __str__(self):
        return f"{self.instructor.name} - {self.get_month_display()} {self.year} ({self.claim_id})"

    def save(self, *args, **kwargs):
        # Generate claim ID if new
        if not self.claim_id:
            self.claim_id = f"HRS-CLM-{uuid.uuid4().hex[:8].upper()}"

        # Calculate total hours
        self.total_hours = self.regular_hours + self.overtime_hours

        # Calculate pay amounts
        self.regular_pay = self.regular_hours * self.hourly_rate
        self.overtime_pay = self.overtime_hours * self.hourly_rate * self.overtime_rate_multiplier
        self.total_claim_amount = self.regular_pay + self.overtime_pay

        super().save(*args, **kwargs)

    @property
    def get_month_year_label(self):
        """Get formatted month/year label"""
        return f"{self.get_month_display()} {self.year}"

    @property
    def session_count(self):
        """Get number of sessions in this claim"""
        return len(self.session_ids) if self.session_ids else 0

    @property
    def average_session_duration(self):
        """Calculate average session duration in minutes"""
        if not self.session_breakdown:
            return 0
        total_minutes = sum(s.get('duration_minutes', 0) for s in self.session_breakdown)
        return total_minutes / len(self.session_breakdown) if self.session_breakdown else 0

    def can_submit(self):
        """Check if claim can be submitted"""
        return self.status == 'draft' and self.regular_hours > 0

    def can_review(self):
        """Check if claim can be reviewed by HR"""
        return self.status in ['pending', 'under_review']

    def can_approve(self):
        """Check if claim can be approved"""
        return self.status in ['pending', 'under_review']

    def can_reject(self):
        """Check if claim can be rejected"""
        return self.status in ['pending', 'under_review']


class InstructorOvertime(models.Model):
    """
    Individual overtime request/claim.
    Can be standalone or part of a monthly hours claim.
    """

    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('approved', 'Approved'),
        ('rejected', 'Rejected'),
    ]

    # Overtime ID
    overtime_id = models.CharField(
        max_length=50,
        unique=True,
        editable=False,
        verbose_name=_("Overtime ID")
    )

    # Instructor
    instructor = models.ForeignKey(
        'instructors.Instructor',
        on_delete=models.CASCADE,
        related_name='overtime_requests',
        verbose_name=_("Instructor")
    )

    # Overtime Details
    overtime_date = models.DateField(
        verbose_name=_("Overtime Date")
    )

    hours_requested = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        verbose_name=_("Hours Requested")
    )

    reason = models.TextField(
        verbose_name=_("Reason for Overtime")
    )

    supporting_document = models.FileField(
        upload_to='instructor_overtime/',
        blank=True,
        null=True,
        verbose_name=_("Supporting Document")
    )

    # Linked Hours Claim (optional)
    hours_claim = models.ForeignKey(
        InstructorHoursClaim,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='overtime_requests',
        verbose_name=_("Linked Hours Claim")
    )

    # Status & Processing
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending',
        verbose_name=_("Status")
    )

    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_overtime_requests',
        verbose_name=_("Reviewed By")
    )

    reviewed_at = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name=_("Reviewed At")
    )

    approval_notes = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Approval Notes")
    )

    rejection_reason = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Rejection Reason")
    )

    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Created At")
    )

    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_("Updated At")
    )

    class Meta:
        db_table = 'instructor_overtime'
        verbose_name = _('Instructor Overtime Request')
        verbose_name_plural = _('Instructor Overtime Requests')
        ordering = ['-overtime_date', '-created_at']
        indexes = [
            models.Index(fields=['instructor', 'status']),
            models.Index(fields=['overtime_date']),
        ]

    def __str__(self):
        return f"{self.instructor.name} - {self.overtime_date} ({self.hours_requested}h)"

    def save(self, *args, **kwargs):
        if not self.overtime_id:
            self.overtime_id = f"OT-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)


class InstructorPayrollSummary(models.Model):
    """
    Monthly payroll summary for all instructors.
    Aggregated data for accounting and reporting.
    """

    # Period
    month = models.PositiveIntegerField(verbose_name=_("Month"))
    year = models.PositiveIntegerField(verbose_name=_("Year"))

    # Totals
    total_instructors = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Total Instructors")
    )

    total_regular_hours = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0.00,
        verbose_name=_("Total Regular Hours")
    )

    total_overtime_hours = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=0.00,
        verbose_name=_("Total Overtime Hours")
    )

    total_payroll_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0.00,
        verbose_name=_("Total Payroll Amount")
    )

    total_paid_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0.00,
        verbose_name=_("Total Paid Amount")
    )

    total_pending_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0.00,
        verbose_name=_("Total Pending Amount")
    )

    # Claims Count
    total_claims = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Total Claims")
    )

    approved_claims = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Approved Claims")
    )

    pending_claims = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Pending Claims")
    )

    # Processed By
    processed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='processed_payroll_summaries',
        verbose_name=_("Processed By (HR Admin)")
    )

    processed_at = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name=_("Processed At")
    )

    # Timestamps
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Created At")
    )

    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_("Updated At")
    )

    class Meta:
        db_table = 'instructor_payroll_summaries'
        verbose_name = _('Instructor Payroll Summary')
        verbose_name_plural = _('Instructor Payroll Summaries')
        unique_together = ['month', 'year']
        ordering = ['-year', '-month']

    def __str__(self):
        return f"Payroll Summary - {self.get_month_display()} {self.year}"
