# apps/payments/subscription_models.py
"""
Subscription and Payment Management Models for LMS

Critical Business Logic:
- Monthly subscriptions for Learnerships
- 5-day grace period before suspension
- Suspended learners CAN:
  * Log into portal
  * Access Community chat
  * Access completed/old course materials (always accessible)
- Suspended learners CANNOT:
  * Access current/active course materials
  * Proceed with active Learnerships
  * Access course-specific chats for active enrollments
  * Access partners' (AICERTS) learning material for active courses

Important: Completed courses are ALWAYS accessible regardless of subscription status.
Partners' content (Industry Training/AICERTS) is also subject to paywall for active enrollments.
"""

from django.db import models
from django.conf import settings
from django.utils import timezone
from datetime import timedelta


class SubscriptionPlan(models.Model):
    """Subscription plans for different learning programmes"""

    PLAN_TYPES = [
        ('masterclass', 'Masterclass'),
        ('learnership', 'Learnership'),
        ('industry_training', 'Industry Training'),
        ('bundle', 'Bundle'),
    ]

    BILLING_CYCLES = [
        ('monthly', 'Monthly'),
        ('quarterly', 'Quarterly'),
        ('annual', 'Annual'),
        ('one_time', 'One-Time Payment'),
    ]

    name = models.CharField(max_length=255)
    plan_type = models.CharField(max_length=50, choices=PLAN_TYPES)
    billing_cycle = models.CharField(max_length=20, choices=BILLING_CYCLES, default='monthly')
    price = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3, default='USD')
    grace_period_days = models.IntegerField(
        default=5,
        help_text="Days before access suspension after payment failure"
    )
    active = models.BooleanField(default=True)
    description = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Subscription Plan"
        verbose_name_plural = "Subscription Plans"
        ordering = ['plan_type', 'billing_cycle']

    def __str__(self):
        return f"{self.name} - {self.get_billing_cycle_display()}"


class StudentSubscription(models.Model):
    """Learner's subscription to a specific programme/course"""

    STATUS_CHOICES = [
        ('active', 'Active'),
        ('grace_period', 'Grace Period'),
        ('suspended', 'Suspended'),
        ('cancelled', 'Cancelled'),
        ('expired', 'Expired'),
    ]

    learner = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='subscriptions'
    )
    plan = models.ForeignKey(
        SubscriptionPlan,
        on_delete=models.PROTECT,
        related_name='subscriptions'
    )

    # Link to specific content
    masterclass = models.ForeignKey(
        'masterclasses.Masterclass',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='subscriptions'
    )
    learnership = models.ForeignKey(
        'learnerships.LearnershipProgramme',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='subscriptions'
    )
    industry_course = models.ForeignKey(
        'industry_based_training.AiCertsCourse',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='subscriptions'
    )

    # Subscription status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='active')
    start_date = models.DateTimeField(default=timezone.now)
    end_date = models.DateTimeField(null=True, blank=True)
    next_billing_date = models.DateTimeField()
    last_payment_date = models.DateTimeField(null=True, blank=True)

    # Grace period tracking
    grace_period_start = models.DateTimeField(null=True, blank=True)
    grace_period_end = models.DateTimeField(null=True, blank=True)
    suspension_date = models.DateTimeField(null=True, blank=True)

    # Payment tracking
    total_paid = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    payment_failures = models.IntegerField(default=0)

    # Auto-renewal
    auto_renew = models.BooleanField(default=True)

    # Metadata
    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = "Learner Subscription"
        verbose_name_plural = "Learner Subscriptions"
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['learner', 'status']),
            models.Index(fields=['next_billing_date']),
            models.Index(fields=['status']),
        ]

    def __str__(self):
        content = self.masterclass or self.learnership or self.industry_course
        return f"{self.learner.email} - {content} ({self.get_status_display()})"

    def save(self, *args, **kwargs):
        """Ensure only one content type is linked"""
        content_count = sum([
            bool(self.masterclass),
            bool(self.learnership),
            bool(self.industry_course)
        ])
        if content_count != 1:
            raise ValueError("Subscription must be linked to exactly one content type")
        super().save(*args, **kwargs)

    @property
    def is_active(self):
        """Check if subscription allows access to content"""
        return self.status in ['active', 'grace_period']

    @property
    def is_suspended(self):
        """Check if subscription is suspended"""
        return self.status == 'suspended'

    @property
    def days_until_suspension(self):
        """Calculate days remaining in grace period"""
        if self.status == 'grace_period' and self.grace_period_end:
            remaining = self.grace_period_end - timezone.now()
            return max(0, remaining.days)
        return None

    @property
    def can_access_course_material(self):
        """
        Determine if learner can access course materials for ACTIVE enrollments.

        Note: This only applies to active/in-progress courses.
        Completed courses are ALWAYS accessible regardless of subscription status.
        Frontend/API should check enrollment completion status separately.
        """
        return self.is_active

    @property
    def can_access_course_chat(self):
        """
        Determine if learner can access course-specific chats for ACTIVE enrollments.

        Note: This only applies to active/in-progress courses.
        Community chat is always accessible.
        """
        return self.is_active

    @property
    def can_access_community_chat(self):
        """Learners can ALWAYS access community chat, even when suspended"""
        return True

    def can_access_enrollment(self, enrollment):
        """
        Check if learner can access a specific enrollment/course.

        Args:
            enrollment: Object with 'is_completed' or 'status' attribute

        Returns:
            bool: True if learner can access the enrollment

        Business Rules:
        - Completed courses: ALWAYS accessible (even if subscription suspended)
        - Active courses: Only accessible if subscription is active or in grace_period
        - Applies to ALL content types: Masterclasses, Learnerships, Industry Training
        """
        # Check if enrollment is completed
        is_completed = getattr(enrollment, 'is_completed', False)
        if is_completed:
            return True

        # For active enrollments, check subscription status
        return self.is_active

    def initiate_grace_period(self):
        """Start grace period after payment failure"""
        if self.status != 'grace_period':
            self.status = 'grace_period'
            self.grace_period_start = timezone.now()
            self.grace_period_end = timezone.now() + timedelta(days=self.plan.grace_period_days)
            self.save()

    def suspend(self):
        """Suspend subscription after grace period expires"""
        if self.status != 'suspended':
            self.status = 'suspended'
            self.suspension_date = timezone.now()
            self.save()

    def reactivate(self):
        """Reactivate subscription after successful payment"""
        if self.status in ['grace_period', 'suspended']:
            self.status = 'active'
            self.grace_period_start = None
            self.grace_period_end = None
            self.suspension_date = None
            self.last_payment_date = timezone.now()
            self.next_billing_date = self._calculate_next_billing_date()
            self.payment_failures = 0
            self.save()

    def _calculate_next_billing_date(self):
        """Calculate next billing date based on billing cycle"""
        now = timezone.now()
        if self.plan.billing_cycle == 'monthly':
            return now + timedelta(days=30)
        elif self.plan.billing_cycle == 'quarterly':
            return now + timedelta(days=90)
        elif self.plan.billing_cycle == 'annual':
            return now + timedelta(days=365)
        else:  # one_time
            return None


class PaymentTransaction(models.Model):
    """Track all payment transactions"""

    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('processing', 'Processing'),
        ('completed', 'Completed'),
        ('failed', 'Failed'),
        ('refunded', 'Refunded'),
    ]

    PAYMENT_METHODS = [
        ('credit_card', 'Credit Card'),
        ('debit_card', 'Debit Card'),
        ('paypal', 'PayPal'),
        ('bank_transfer', 'Bank Transfer'),
        ('mobile_money', 'Mobile Money'),
        ('other', 'Other'),
    ]

    subscription = models.ForeignKey(
        StudentSubscription,
        on_delete=models.PROTECT,
        related_name='transactions'
    )
    transaction_id = models.CharField(max_length=255, unique=True)
    amount = models.DecimalField(max_digits=10, decimal_places=2)
    currency = models.CharField(max_length=3, default='USD')

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    payment_method = models.CharField(max_length=50, choices=PAYMENT_METHODS)
    payment_gateway = models.CharField(max_length=100, blank=True)

    # Gateway response
    gateway_response = models.JSONField(default=dict, blank=True)
    failure_reason = models.TextField(blank=True)

    # Timestamps
    initiated_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        verbose_name = "Payment Transaction"
        verbose_name_plural = "Payment Transactions"
        ordering = ['-initiated_at']
        indexes = [
            models.Index(fields=['subscription', 'status']),
            models.Index(fields=['transaction_id']),
        ]

    def __str__(self):
        return f"Transaction {self.transaction_id} - {self.get_status_display()}"


class SubscriptionNotification(models.Model):
    """Track notifications sent to learners about subscription status"""

    NOTIFICATION_TYPES = [
        ('payment_due', 'Payment Due'),
        ('payment_failed', 'Payment Failed'),
        ('grace_period_started', 'Grace Period Started'),
        ('grace_period_warning', 'Grace Period Warning'),
        ('suspension_notice', 'Suspension Notice'),
        ('suspended', 'Suspended'),
        ('reactivated', 'Reactivated'),
    ]

    subscription = models.ForeignKey(
        StudentSubscription,
        on_delete=models.CASCADE,
        related_name='notifications'
    )
    notification_type = models.CharField(max_length=50, choices=NOTIFICATION_TYPES)
    title = models.CharField(max_length=255)
    message = models.TextField()
    sent_at = models.DateTimeField(auto_now_add=True)
    read_at = models.DateTimeField(null=True, blank=True)
    is_read = models.BooleanField(default=False)

    class Meta:
        verbose_name = "Subscription Notification"
        verbose_name_plural = "Subscription Notifications"
        ordering = ['-sent_at']

    def __str__(self):
        return f"{self.get_notification_type_display()} - {self.subscription.learner.email}"

    def mark_as_read(self):
        """Mark notification as read"""
        if not self.is_read:
            self.is_read = True
            self.read_at = timezone.now()
            self.save()
