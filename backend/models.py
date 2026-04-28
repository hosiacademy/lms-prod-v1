from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator

class AiCertsCourse(models.Model):
    """Raw course data directly synced from AICERTs public API."""

    PROVIDER_CHOICES = [
        ('aicerts', 'AICERTs'),
    ]

    provider = models.CharField(
        max_length=50,
        choices=PROVIDER_CHOICES,
        default='aicerts',
        db_index=True
    )

    external_id = models.IntegerField(unique=True, db_index=True)
    fullname = models.CharField(max_length=255)
    shortname = models.CharField(max_length=100, blank=True)
    summary = models.TextField(blank=True)
    category_name = models.CharField(max_length=500, blank=True)
    certificate_badge_url = models.URLField(blank=True)
    feature_image_url = models.URLField(blank=True)
    lms_course_id = models.CharField(max_length=100, blank=True, null=True)
    raw_data = models.JSONField(default=dict, blank=True)

    # Offering flags
    is_offered = models.BooleanField(default=False)
    is_self_paced = models.BooleanField(default=False)

    # Pricing
    price_individual = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(0)]
    )
    is_in_package = models.BooleanField(default=False)
    package_name = models.CharField(max_length=255, blank=True)
    price_package = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        null=True,
        blank=True,
        validators=[MinValueValidator(0)]
    )

    # Timestamps
    last_synced = models.DateTimeField(default=timezone.now, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-last_synced']

    def __str__(self):
        return self.fullname
