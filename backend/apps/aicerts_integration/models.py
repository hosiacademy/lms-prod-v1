# apps/aicerts_integration/models.py
"""
Models for AICERTs Partnership Integration

Tracks:
- Enrollment synchronization between Hosi Academy and AICERTs
- Instructor designations and authorizations
- Sync operations and logs
- SSO session tracking
"""

from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.utils import timezone


class AICertsEnrollment(models.Model):
    """
    Tracks course enrollments synchronized between Hosi Academy and AICERTs LMS.
    Ensures co-authentication: users enroll on Hosi, access courses on AICERTs.
    """

    STATUS_CHOICES = [
        ('pending', 'Pending Sync'),
        ('enrolled', 'Enrolled on AICERTs'),
        ('failed', 'Sync Failed'),
        ('unenrolled', 'Unenrolled'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='aicerts_enrollments',
        help_text=_("Hosi Academy user")
    )
    course = models.ForeignKey(
        'aicerts_courses.AiCertsCourse',
        on_delete=models.CASCADE,
        related_name='hosi_enrollments',
        help_text=_("AICERTs course")
    )
    aicerts_enrollment_status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending',
        help_text=_("Synchronization status with AICERTs")
    )
    aicerts_already_enrolled = models.BooleanField(
        default=False,
        help_text=_("Was user already enrolled when we tried to enroll?")
    )
    enrolled_at = models.DateTimeField(
        auto_now_add=True,
        help_text=_("When user enrolled on Hosi Academy")
    )
    synced_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text=_("When enrollment was synced to AICERTs")
    )
    last_sync_attempt = models.DateTimeField(
        blank=True,
        null=True,
        help_text=_("Last attempted sync (for retry tracking)")
    )
    sync_attempts = models.IntegerField(
        default=0,
        help_text=_("Number of sync attempts")
    )
    sync_error = models.TextField(
        blank=True,
        null=True,
        help_text=_("Error message from last sync attempt")
    )

    # Progress tracking (updated from AICERTs if available)
    progress_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0.00,
        help_text=_("Course completion percentage (0-100)")
    )
    last_accessed_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text=_("Last time user accessed course on AICERTs")
    )
    completed_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text=_("When user completed the course")
    )
    certificate_issued_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text=_("When certificate was issued")
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'aicerts_enrollments'
        unique_together = [('user', 'course')]
        verbose_name = _("AICERTs Enrollment")
        verbose_name_plural = _("AICERTs Enrollments")
        ordering = ['-enrolled_at']
        indexes = [
            models.Index(fields=['user', 'aicerts_enrollment_status']),
            models.Index(fields=['course', 'aicerts_enrollment_status']),
            models.Index(fields=['aicerts_enrollment_status', 'last_sync_attempt']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.course.title} ({self.aicerts_enrollment_status})"

    def mark_synced(self):
        """Mark enrollment as successfully synced to AICERTs"""
        self.aicerts_enrollment_status = 'enrolled'
        self.synced_at = timezone.now()
        self.sync_error = None
        self.save(update_fields=['aicerts_enrollment_status', 'synced_at', 'sync_error', 'updated_at'])

    def mark_failed(self, error_message: str):
        """Mark enrollment sync as failed"""
        self.aicerts_enrollment_status = 'failed'
        self.last_sync_attempt = timezone.now()
        self.sync_attempts += 1
        self.sync_error = error_message
        self.save(update_fields=['aicerts_enrollment_status', 'last_sync_attempt', 'sync_attempts', 'sync_error', 'updated_at'])

    @property
    def needs_retry(self):
        """Check if enrollment needs retry (failed and < 3 attempts)"""
        return self.aicerts_enrollment_status == 'failed' and self.sync_attempts < 3


class AICertsInstructorDesignation(models.Model):
    """
    Tracks which courses AICERTs instructors are authorized to teach.
    Enforces partnership rule: Only registered AICERTs instructors can teach AICERTs courses.
    """

    instructor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        limit_choices_to={'is_aicerts_instructor': True},
        related_name='aicerts_designations',
        help_text=_("AICERTs-registered instructor")
    )
    course = models.ForeignKey(
        'aicerts_courses.AiCertsCourse',
        on_delete=models.CASCADE,
        related_name='instructor_designations',
        help_text=_("Course instructor is authorized to teach")
    )
    aicerts_instructor_id = models.PositiveIntegerField(
        help_text=_("Instructor's user ID on AICERTs LMS")
    )
    designated_at = models.DateTimeField(
        auto_now_add=True,
        help_text=_("When instructor was designated for this course")
    )
    designated_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='aicerts_designations_made',
        help_text=_("Admin who made this designation")
    )
    is_active = models.BooleanField(
        default=True,
        help_text=_("Is this designation currently active?")
    )
    notes = models.TextField(
        blank=True,
        null=True,
        help_text=_("Admin notes about this designation")
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'aicerts_instructor_designations'
        unique_together = [('instructor', 'course')]
        verbose_name = _("AICERTs Instructor Designation")
        verbose_name_plural = _("AICERTs Instructor Designations")
        ordering = ['-designated_at']
        indexes = [
            models.Index(fields=['instructor', 'is_active']),
            models.Index(fields=['course', 'is_active']),
        ]

    def __str__(self):
        return f"{self.instructor.get_full_name()} → {self.course.title}"


class AICertsSyncLog(models.Model):
    """
    Logs all synchronization operations with AICERTs APIs.
    Used for debugging, monitoring, and audit trails.
    """

    OPERATION_TYPES = [
        ('course_sync', 'Course Data Sync'),
        ('user_create', 'User Creation'),
        ('user_enroll', 'User Enrollment'),
        ('user_auth', 'User Authentication'),
        ('progress_update', 'Progress Update'),
        ('instructor_sync', 'Instructor Sync'),
    ]

    STATUS_CHOICES = [
        ('success', 'Success'),
        ('failed', 'Failed'),
        ('partial', 'Partial Success'),
    ]

    operation_type = models.CharField(
        max_length=50,
        choices=OPERATION_TYPES,
        help_text=_("Type of sync operation")
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        help_text=_("Operation outcome")
    )
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='aicerts_sync_logs',
        help_text=_("User involved in operation (if applicable)")
    )
    course = models.ForeignKey(
        'aicerts_courses.AiCertsCourse',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='sync_logs',
        help_text=_("Course involved in operation (if applicable)")
    )
    request_data = models.JSONField(
        default=dict,
        blank=True,
        help_text=_("API request parameters (excluding sensitive data)")
    )
    response_data = models.JSONField(
        default=dict,
        blank=True,
        help_text=_("API response data")
    )
    error_message = models.TextField(
        blank=True,
        null=True,
        help_text=_("Error details if operation failed")
    )
    duration_ms = models.IntegerField(
        blank=True,
        null=True,
        help_text=_("API call duration in milliseconds")
    )
    records_processed = models.IntegerField(
        default=0,
        help_text=_("Number of records processed (for bulk operations)")
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'aicerts_sync_logs'
        verbose_name = _("AICERTs Sync Log")
        verbose_name_plural = _("AICERTs Sync Logs")
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['operation_type', 'status', '-created_at']),
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['course', '-created_at']),
        ]

    def __str__(self):
        return f"{self.get_operation_type_display()} - {self.status} ({self.created_at.strftime('%Y-%m-%d %H:%M')})"


class AICertsSSOSession(models.Model):
    """
    Tracks SSO sessions for AICERTs authentication.
    Helps monitor user access patterns and troubleshoot SSO issues.
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='aicerts_sso_sessions',
        help_text=_("User who initiated SSO")
    )
    course = models.ForeignKey(
        'aicerts_courses.AiCertsCourse',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='sso_sessions',
        help_text=_("Target course (if SSO was for specific course)")
    )
    sso_url = models.TextField(
        help_text=_("Generated SSO URL (signature excluded for security)")
    )
    session_token = models.CharField(
        max_length=255,
        unique=True,
        help_text=_("Unique token for this SSO session")
    )
    ip_address = models.GenericIPAddressField(
        blank=True,
        null=True,
        help_text=_("User's IP address")
    )
    user_agent = models.TextField(
        blank=True,
        null=True,
        help_text=_("User's browser/device information")
    )
    successful = models.BooleanField(
        default=False,
        help_text=_("Was SSO authentication successful?")
    )
    accessed_at = models.DateTimeField(
        blank=True,
        null=True,
        help_text=_("When user accessed AICERTs via SSO")
    )
    expires_at = models.DateTimeField(
        help_text=_("When SSO session expires")
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'aicerts_sso_sessions'
        verbose_name = _("AICERTs SSO Session")
        verbose_name_plural = _("AICERTs SSO Sessions")
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['session_token']),
            models.Index(fields=['successful', '-created_at']),
        ]

    def __str__(self):
        return f"SSO: {self.user.email} → {self.course.title if self.course else 'Dashboard'}"

    @property
    def is_expired(self):
        """Check if SSO session has expired"""
        return timezone.now() > self.expires_at
