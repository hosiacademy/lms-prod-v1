# apps/industry_based_training/models.py
from django.db import models
from django.utils import timezone
from django.conf import settings
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey


class Industry(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)

    def __str__(self):
        return self.name

    class Meta:
        verbose_name_plural = "Industries"


class AiCertsCourse(models.Model):
    # Link to raw course (optional)
    raw_course = models.ForeignKey(
        'aicerts_courses.AiCertsCourse',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='industry_versions'
    )

    # Course identification
    course_id = models.CharField(max_length=50, unique=True)  # API ID
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    categories = models.CharField(max_length=500, blank=True)
    certificate_badge_url = models.URLField(blank=True)
    feature_image_url = models.URLField(blank=True)

    # CHANGED: Made nullable
    lms_id = models.CharField(max_length=100, blank=True, null=True)  # Moodle LMS ID - can be NULL

    # Pricing (set manually in admin or via sync)
    price_usd = models.DecimalField(
        max_digits=10, decimal_places=2, null=True, blank=True,
        help_text="Course price in USD"
    )

    # Industry bucketing
    industry = models.ForeignKey(
        Industry,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='industry_courses'
    )

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    last_synced = models.DateTimeField(default=timezone.now)

    @property
    def price(self):
        """Return price_usd if set, then fall back to raw_course.price_individual."""
        if self.price_usd is not None:
            return self.price_usd
        if self.raw_course_id and self.raw_course and self.raw_course.price_individual:
            return self.raw_course.price_individual
        return None

    def __str__(self):
        return f"{self.title} ({self.industry.name if self.industry else 'No Industry'})"

    class Meta:
        db_table = 'industry_based_training_aicertscourse'
        ordering = ['-last_synced']


class Offering(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    industry = models.ForeignKey(Industry, on_delete=models.CASCADE, related_name='offerings')
    courses = models.ManyToManyField(AiCertsCourse, related_name='offerings')
    price_usd = models.DecimalField(max_digits=10, decimal_places=2)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.name} - ${self.price_usd}"


class IndustryTrainingEnrollment(models.Model):
    """
    Tracks enrollments in industry-based and role-based training.
    
    Supports:
    - Single course enrollment (industry_training)
    - Bundled offering enrollment (role_training)
    - AICerts LMS synchronization
    - Payment tracking
    """
    
    # Primary key - uses default 'id' BigAutoField
    
    ENROLLMENT_TYPE_CHOICES = [
        ('industry_training', 'Industry Training'),
        ('role_training', 'Role Training'),
    ]
    
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('enrolled', 'Enrolled'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
        ('dropped_out', 'Dropped Out'),
        ('refunded', 'Refunded'),
    ]
    
    PAYMENT_STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('paid', 'Paid'),
        ('partial', 'Partial Payment'),
        ('refunded', 'Refunded'),
        ('failed', 'Failed'),
    ]
    
    # User linkage
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='industry_training_enrollments',
        help_text="Enrolled learner"
    )
    
    # Training type
    enrollment_type = models.CharField(
        max_length=20,
        choices=ENROLLMENT_TYPE_CHOICES,
        help_text="Type of industry/role training"
    )
    
    # Content linkage (polymorphic via GenericForeignKey)
    # Can point to AiCertsCourse (industry_training) or Offering (role_training)
    content_type = models.ForeignKey(
        ContentType,
        on_delete=models.CASCADE
    )
    object_id = models.PositiveIntegerField()
    content_object = GenericForeignKey('content_type', 'object_id')
    
    # Payment linkage
    payment_transaction = models.ForeignKey(
        'payments.PaymentTransaction',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='industry_training_enrollments',
        help_text="Associated payment transaction"
    )
    
    # Status tracking
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending',
        help_text="Current enrollment status"
    )
    payment_status = models.CharField(
        max_length=20,
        choices=PAYMENT_STATUS_CHOICES,
        default='pending',
        help_text="Payment status"
    )
    
    # AICerts LMS tracking
    aicerts_user_id = models.PositiveIntegerField(
        null=True,
        blank=True,
        help_text="User ID on AICerts LMS"
    )
    aicerts_enrollment_ids = models.JSONField(
        default=list,
        blank=True,
        help_text="List of AICerts enrollment IDs for each course"
    )
    aicerts_already_enrolled = models.BooleanField(
        default=False,
        help_text="Was user already enrolled when we tried to enroll?"
    )
    
    # Progress tracking
    enrolled_at = models.DateTimeField(
        auto_now_add=True,
        help_text="When enrollment was created"
    )
    started_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When learner started the course"
    )
    completed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When learner completed the course"
    )
    last_accessed_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Last time learner accessed the course on AICerts"
    )
    
    # Sync tracking
    synced_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="When last synced with AICerts"
    )
    sync_attempts = models.PositiveIntegerField(
        default=0,
        help_text="Number of sync attempts"
    )
    sync_error = models.TextField(
        blank=True,
        null=True,
        help_text="Error message from last sync attempt"
    )
    
    # Financial tracking
    amount_paid = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        help_text="Amount paid for this enrollment"
    )
    currency = models.CharField(
        max_length=3,
        default='USD',
        help_text="Currency of payment"
    )
    
    # Metadata for additional data
    metadata = models.JSONField(
        default=dict,
        blank=True,
        help_text="Additional enrollment metadata"
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'industry_training_enrollments'
        verbose_name = "Industry Training Enrollment"
        verbose_name_plural = "Industry Training Enrollments"
        ordering = ['-enrolled_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['user', 'enrollment_type']),
            models.Index(fields=['content_type', 'object_id']),
            models.Index(fields=['status', 'enrolled_at']),
            models.Index(fields=['payment_transaction']),
        ]
    
    def __str__(self):
        content_title = str(self.content_object) if self.content_object else f"ID {self.object_id}"
        return f"{self.user.email} - {content_title} ({self.get_status_display()})"
    
    def get_enrolled_item(self):
        """Return the enrolled item for chat room setup compatibility"""
        return self.content_object
    
    @property
    def course_count(self):
        """Get number of courses in this enrollment"""
        if self.enrollment_type == 'role_training' and hasattr(self.content_object, 'courses'):
            return self.content_object.courses.count()
        return 1
    
    @property
    def needs_sync(self):
        """Check if enrollment needs to be synced with AICerts"""
        return self.status == 'enrolled' and (
            self.synced_at is None or 
            self.sync_error is not None
        )
    
    def mark_synced(self):
        """Mark enrollment as successfully synced to AICerts"""
        self.synced_at = timezone.now()
        self.sync_error = None
        self.save(update_fields=['synced_at', 'sync_error', 'updated_at'])
    
    def mark_sync_failed(self, error_message: str):
        """Mark enrollment sync as failed"""
        self.sync_attempts += 1
        self.sync_error = error_message
        self.save(update_fields=['sync_attempts', 'sync_error', 'updated_at'])
    
    def update_status(self, new_status: str):
        """Update enrollment status with validation"""
        valid_statuses = [choice[0] for choice in self.STATUS_CHOICES]
        if new_status not in valid_statuses:
            raise ValueError(f"Invalid status: {new_status}. Must be one of {valid_statuses}")
        self.status = new_status
        self.save(update_fields=['status', 'updated_at'])