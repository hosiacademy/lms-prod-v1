from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator


class AiCertsCourse(models.Model):
    """
    Enhanced model to store full course data synced from AICERTs public API.
    Fully aligned with https://www.aicerts.ai/wp-json/aicerts-api/v1/courses (list) 
    and /course/{id} (detail) endpoints as per API Documentation v1.1 (2025).
    
    Supports rich fields: title, certificate badge, categories array, full HTML description,
    pricing, availability flags, visuals, and raw API data for future-proofing.
    """

    PROVIDER_CHOICES = [
        ('aicerts', 'AICERTs'),
    ]

    # Provider & Identification
    provider = models.CharField(
        max_length=50,
        choices=PROVIDER_CHOICES,
        default='aicerts',
        db_index=True,
        help_text="Source platform (currently only AICERTs)"
    )
    external_id = models.IntegerField(
        unique=True,
        db_index=True,
        help_text="Unique course ID from AICERTs API"
    )

    # Core Course Info (matches real API)
    title = models.CharField(
        max_length=1000000,
        help_text="Full course title (maps to 'title' in API)"
    )
    shortname = models.CharField(
        max_length=10000,
        blank=True,
        help_text="Short/abbreviated name"
    )
    description = models.TextField(
        blank=True,
        null=True,
        help_text="Full course description (HTML allowed, from API)"
    )
    summary = models.TextField(
        blank=True,
        help_text="Short excerpt/fallback summary"
    )

    # Categories (store as comma-separated, but expose as array via serializer)
    category_name = models.CharField(
        max_length=1000000,
        blank=True,
        help_text="Comma-separated category names (e.g. 'AI Healthcare,AI Professional')"
    )

    # Visuals & Certificates (critical for matching real API)
    certificate_badge_url = models.URLField(
        blank=True,
        help_text="URL to certificate badge image (SVG) — from list endpoint"
    )
    certificate_image_jpg_url = models.URLField(
        blank=True,
        help_text="JPG version of certificate badge via wsrv.nl — from list endpoint"
    )
    feature_image_url = models.URLField(
        blank=True,
        help_text="URL to featured course image (SVG) — from detail endpoint"
    )
    feature_image_jpg_url = models.URLField(
        blank=True,
        help_text="JPG version of feature image via wsrv.nl — from detail endpoint"
    )
    ai_tools = models.JSONField(
        default=list,
        blank=True,
        help_text="AI tools list from detail endpoint: [{name, image}]"
    )

    # LMS Integration
    lms_course_id = models.CharField(
        max_length=10000,
        blank=True,
        null=True,
        help_text="Moodle/LMS course ID (if synced)"
    )

    # Offering & Availability (matches API flags)
    is_offered = models.BooleanField(
        default=False,
        help_text="Actively offered on the platform?"
    )
    is_self_paced = models.BooleanField(
        default=False,
        help_text="Self-paced course?"
    )

    # ===== INSTRUCTOR =====
    instructor = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='taught_aicerts_courses',
        verbose_name="Assigned Instructor",
        help_text="The instructor assigned to teach this AICERTS course"
    )
    stream_type = models.CharField(
        max_length=20,
        choices=[('technical', 'Technical'), ('professional', 'Professional')],
        default='professional',
        db_index=True,
        help_text="Stream type for pricing: Technical ($420) or Professional ($250)"
    )

    # Pricing Information (full support)
    price_individual = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(0)],
        help_text="Individual enrollment price"
    )
    is_in_package = models.BooleanField(
        default=False,
        help_text="Part of a package/bundle?"
    )
    package_name = models.CharField(
        max_length=1000000,
        blank=True,
        help_text="Package/bundle name"
    )
    price_package = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(0)],
        help_text="Price when bought in package"
    )

    # Full raw API data (future-proof for new fields like modules, prerequisites, tools)
    raw_data = models.JSONField(
        default=dict,
        blank=True,
        help_text="Complete JSON from list and detail endpoints (for new fields)"
    )

    # Sync & Timestamps
    last_synced = models.DateTimeField(
        default=timezone.now,
        db_index=True,
        help_text="Last sync time from AICERTs API"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Creation time in local DB"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="Last update time"
    )

    class Meta:
        ordering = ['-last_synced']
        verbose_name = "AICERTs Course"
        verbose_name_plural = "AICERTs Courses"
        indexes = [
            models.Index(fields=['provider', 'external_id']),
            models.Index(fields=['is_offered']),
            models.Index(fields=['last_synced']),
        ]

    def __str__(self):
        return f"{self.title} ({self.external_id})"

    @property
    def has_description(self):
        return bool(self.description and len(self.description.strip()) > 20)

    def save(self, *args, **kwargs):
        """Auto-fill summary from description if empty"""
        if not self.summary and self.description:
            self.summary = self.description[:200] + '...' if len(self.description) > 200 else self.description
        super().save(*args, **kwargs)
