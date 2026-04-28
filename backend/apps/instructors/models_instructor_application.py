# apps/instructors/models_instructor_application.py

from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
from django.core.validators import MaxValueValidator
import uuid
import os


def instructor_application_directory(instance, filename):
    """Generate upload directory for instructor application files."""
    ext = os.path.splitext(filename)[1]
    return f'instructor_applications/{instance.applicant_email}/{uuid.uuid4()}{ext}'


class InstructorApplication(models.Model):
    """
    Instructor application model for tracking prospective instructors.
    Created when someone submits the "Apply to Teach" form.
    """
    
    # Application Status Choices
    STATUS_CHOICES = [
        ('pending', _('Pending Review')),
        ('under_review', _('Under Review')),
        ('interview_scheduled', _('Interview Scheduled')),
        ('interview_completed', _('Interview Completed')),
        ('approved', _('Approved')),
        ('rejected', _('Rejected')),
        ('withdrawn', _('Withdrawn')),
    ]
    
    # Interview Status
    INTERVIEW_STATUS_CHOICES = [
        ('not_scheduled', _('Not Scheduled')),
        ('scheduled', _('Scheduled')),
        ('completed', _('Completed')),
        ('cancelled', _('Cancelled')),
        ('rescheduled', _('Rescheduled')),
    ]
    
    # Application ID
    application_id = models.CharField(
        max_length=50,
        unique=True,
        editable=False,
        verbose_name=_("Application ID")
    )
    
    # Applicant Information
    applicant_name = models.CharField(
        max_length=255,
        verbose_name=_("Full Name")
    )
    
    applicant_email = models.EmailField(
        verbose_name=_("Email Address")
    )
    
    applicant_phone = models.CharField(
        max_length=50,
        verbose_name=_("Phone Number")
    )
    
    # Professional Information
    professional_headline = models.CharField(
        max_length=255,
        verbose_name=_("Professional Headline")
    )
    
    areas_of_expertise = models.TextField(
        verbose_name=_("Areas of Expertise"),
        help_text=_("Comma-separated list of expertise areas")
    )
    
    top_qualifications = models.TextField(
        verbose_name=_("Top Qualifications")
    )
    
    years_of_experience = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Years of Experience")
    )
    
    # Motivation Letter
    motivation_letter = models.TextField(
        verbose_name=_("Motivation Letter"),
        help_text=_("Why do you want to teach at Hosi Academy?")
    )
    
    # Attachments
    cv_file = models.FileField(
        upload_to=instructor_application_directory,
        verbose_name=_("CV/Resume")
    )
    
    certificates_file = models.FileField(
        upload_to=instructor_application_directory,
        blank=True,
        null=True,
        verbose_name=_("Certificates")
    )
    
    # Additional attachments (max 5)
    additional_attachment_1 = models.FileField(
        upload_to=instructor_application_directory,
        blank=True,
        null=True,
        verbose_name=_("Additional Document 1")
    )
    
    additional_attachment_2 = models.FileField(
        upload_to=instructor_application_directory,
        blank=True,
        null=True,
        verbose_name=_("Additional Document 2")
    )
    
    additional_attachment_3 = models.FileField(
        upload_to=instructor_application_directory,
        blank=True,
        null=True,
        verbose_name=_("Additional Document 3")
    )
    
    additional_attachment_4 = models.FileField(
        upload_to=instructor_application_directory,
        blank=True,
        null=True,
        verbose_name=_("Additional Document 4")
    )
    
    additional_attachment_5 = models.FileField(
        upload_to=instructor_application_directory,
        blank=True,
        null=True,
        verbose_name=_("Additional Document 5")
    )
    
    # Teaching Interests & Streams (Added in April 2026 update)
    main_streams = models.JSONField(
        default=list,
        blank=True,
        verbose_name=_("Main Streams (Cybersecurity/AI & Blockchain)")
    )
    
    interested_masterclasses = models.JSONField(
        default=list,
        blank=True,
        verbose_name=_("Interested Masterclasses")
    )
    
    interested_learnerships = models.JSONField(
        default=list,
        blank=True,
        verbose_name=_("Interested Learnerships")
    )
    
    interested_custom_courses = models.JSONField(
        default=list,
        blank=True,
        verbose_name=_("Interested Custom Courses")
    )
    
    interested_industry_courses = models.JSONField(
        default=list,
        blank=True,
        verbose_name=_("Interested Industry/Role Based Courses")
    )

    # Application Status
    status = models.CharField(
        max_length=30,
        choices=STATUS_CHOICES,
        default='pending',
        verbose_name=_("Application Status")
    )
    
    # HR Admin Processing
    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='reviewed_instructor_applications',
        verbose_name=_("Reviewed By (HR Admin)")
    )
    
    # Country assignment (for HR Admin filtering)
    country = models.ForeignKey(
        'localization.Country',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='instructor_applications',
        verbose_name=_("Country")
    )
    
    # Interview Details
    interview_status = models.CharField(
        max_length=30,
        choices=INTERVIEW_STATUS_CHOICES,
        default='not_scheduled',
        verbose_name=_("Interview Status")
    )
    
    interview_datetime = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name=_("Scheduled Interview Date/Time")
    )
    
    interview_notes = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Interview Notes")
    )
    
    # BBB Integration for Interview
    bbb_meeting_id = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        verbose_name=_("BBB Meeting ID")
    )
    
    bbb_moderator_password = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        verbose_name=_("BBB Moderator Password")
    )
    
    bbb_attendee_password = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        verbose_name=_("BBB Attendee Password")
    )
    
    # Decision
    rejection_reason = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Rejection Reason")
    )
    
    approval_notes = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Approval Notes")
    )
    
    # Timestamps
    submitted_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Submitted At")
    )
    
    reviewed_at = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name=_("Reviewed At")
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Created At")
    )
    
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_("Updated At")
    )
    
    class Meta:
        db_table = 'instructor_applications'
        verbose_name = _('Instructor Application')
        verbose_name_plural = _('Instructor Applications')
        ordering = ['-submitted_at']
        indexes = [
            models.Index(fields=['status', 'submitted_at']),
            models.Index(fields=['country', 'status']),
            models.Index(fields=['interview_status']),
        ]
    
    def __str__(self):
        return f"{self.applicant_name} - {self.get_status_display()}"
    
    def save(self, *args, **kwargs):
        if not self.application_id:
            self.application_id = f"INST-APP-{uuid.uuid4().hex[:8].upper()}"
        super().save(*args, **kwargs)
    
    @property
    def get_additional_attachments(self):
        """Return list of additional attachments."""
        attachments = []
        for i in range(1, 6):
            field = getattr(self, f'additional_attachment_{i}')
            if field:
                attachments.append({
                    'number': i,
                    'url': field.url,
                    'name': os.path.basename(field.name)
                })
        return attachments
    
    @property
    def total_attachments_count(self):
        """Count total number of attachments."""
        count = 1 if self.cv_file else 0
        count += 1 if self.certificates_file else 0
        for i in range(1, 6):
            if getattr(self, f'additional_attachment_{i}'):
                count += 1
        return count


class InstructorStatusLog(models.Model):
    """
    Log for tracking instructor status changes.
    Used for audit trail when HR Admin changes status.
    """
    
    STATUS_CHANGE_CHOICES = [
        ('active', _('Active')),
        ('inactive', _('Inactive')),
        ('suspended', _('Suspended')),
    ]
    
    instructor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='status_change_logs',
        verbose_name=_("Instructor")
    )
    
    previous_status = models.CharField(
        max_length=30,
        blank=True,
        null=True,
        verbose_name=_("Previous Status")
    )
    
    new_status = models.CharField(
        max_length=30,
        choices=STATUS_CHANGE_CHOICES,
        verbose_name=_("New Status")
    )
    
    reason = models.TextField(
        verbose_name=_("Reason for Status Change"),
        help_text=_("Required for inactive/suspended status")
    )
    
    changed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='instructor_status_changes_made',
        verbose_name=_("Changed By (HR Admin)")
    )
    
    changed_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Changed At")
    )
    
    class Meta:
        db_table = 'instructor_status_logs'
        verbose_name = _('Instructor Status Log')
        verbose_name_plural = _('Instructor Status Logs')
        ordering = ['-changed_at']

    def __str__(self):
        return f"{self.instructor.name} - {self.new_status} ({self.changed_at})"


# Note: InstructorAnalytics removed - duplicate model already defined in models.py
# The main models.py file has the canonical InstructorAnalytics class
