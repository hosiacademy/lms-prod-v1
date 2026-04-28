# apps/instructors/models.py

from django.db import models
from django.utils.translation import gettext_lazy as _
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from django.conf import settings
import uuid


# Helper functions for default values (Django can serialize these)
def generate_instructor_id():
    return f"FAC-{uuid.uuid4().hex[:8].upper()}"

def generate_assignment_id():
    return f"ASSIGN-{uuid.uuid4().hex[:8].upper()}"

def generate_appraisal_id():
    return f"APPRAISAL-{uuid.uuid4().hex[:8].upper()}"


class Instructor(models.Model):
    """
    Extended profile for instructors/trainers with performance tracking.
    Linked to the User model for authentication.
    """
    INSTRUCTOR_TYPES = [
        ('facilitator', _('Facilitator')),
        ('trainer', _('Trainer')),
        ('assessor', _('Assessor')),
        ('moderator', _('Moderator')),
        ('coach', _('Coach')),
        ('mentor', _('Mentor')),
    ]

    PERFORMANCE_RATINGS = [
        ('excellent', _('Excellent (90-100%)')),
        ('good', _('Good (75-89%)')),
        ('satisfactory', _('Satisfactory (60-74%)')),
        ('needs_improvement', _('Needs Improvement (40-59%)')),
        ('poor', _('Poor (<40%)')),
    ]

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='facilitator_profile',
        verbose_name=_("User Account"),
    )

    instructor_id = models.CharField(
        max_length=50,
        unique=True,
        default=generate_instructor_id,
        verbose_name=_("Instructor ID")
    )

    instructor_type = models.CharField(
        max_length=20,
        choices=INSTRUCTOR_TYPES,
        default='facilitator',
        verbose_name=_("Instructor Type")
    )

    # Professional Information
    employee_number = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("Employee/Staff Number")
    )

    department = models.CharField(
        max_length=200,
        blank=True,
        null=True,
        verbose_name=_("Department")
    )

    specialization = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Area of Specialization"),
        help_text=_("Subject areas or skills this instructor specializes in")
    )

    qualifications = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Qualifications"),
        help_text=_("Educational and professional qualifications")
    )

    years_experience = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Years of Experience")
    )

    # Contact Information (Professional)
    work_phone = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("Work Phone")
    )

    work_email = models.EmailField(
        blank=True,
        null=True,
        verbose_name=_("Work Email")
    )

    office_location = models.CharField(
        max_length=200,
        blank=True,
        null=True,
        verbose_name=_("Office/Location")
    )

    # Availability
    is_available = models.BooleanField(
        default=True,
        verbose_name=_("Available for Assignments"),
        help_text=_("Indicates if instructor is currently available for new course assignments")
    )

    max_courses = models.PositiveIntegerField(
        default=5,
        verbose_name=_("Maximum Concurrent Courses"),
        help_text=_("Maximum number of courses this instructor can handle simultaneously")
    )

    availability_notes = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Availability Notes"),
        help_text=_("Notes about availability, preferences, or constraints")
    )

    # Performance Metrics
    overall_rating = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(100.0)],
        verbose_name=_("Overall Performance Rating")
    )

    performance_band = models.CharField(
        max_length=30,
        choices=PERFORMANCE_RATINGS,
        blank=True,
        null=True,
        verbose_name=_("Performance Band")
    )

    total_courses_taught = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Total Courses Taught")
    )

    total_students_taught = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Total Students Taught")
    )

    average_student_rating = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(5.0)],
        verbose_name=_("Average Student Rating")
    )

    completion_rate = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(100.0)],
        verbose_name=_("Average Course Completion Rate")
    )

    last_performance_review = models.DateField(
        blank=True,
        null=True,
        verbose_name=_("Last Performance Review")
    )

    # Administrative
    date_hired = models.DateField(
        blank=True,
        null=True,
        verbose_name=_("Date Hired/Appointed")
    )

    contract_expiry = models.DateField(
        blank=True,
        null=True,
        verbose_name=_("Contract Expiry Date")
    )

    is_active = models.BooleanField(
        default=True,
        verbose_name=_("Active Instructor")
    )

    # HR Admin Assignment Fields
    hr_admin = models.ForeignKey(
        'payments.AdminRole',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_instructors',
        verbose_name=_("HR Admin"),
        help_text=_("HR Administrator responsible for this instructor")
    )

    assignment_date = models.DateField(
        blank=True,
        null=True,
        default=timezone.now,
        verbose_name=_("Assignment Date"),
        help_text=_("Date when instructor was assigned to HR Admin")
    )

    assignment_type = models.CharField(
        max_length=50,
        choices=[
            ('country_based', _('Country-Based')),
            ('specialization', _('Specialization-Based')),
            ('performance', _('Performance-Based')),
            ('manual', _('Manual Assignment')),
            ('auto', _('Auto-Assigned')),
        ],
        default='country_based',
        verbose_name=_("Assignment Type"),
        help_text=_("How this instructor was assigned to HR Admin")
    )

    assignment_country = models.ForeignKey(
        'localization.Country',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='assigned_instructors',
        verbose_name=_("Assignment Country"),
        help_text=_("Primary country this instructor is assigned to")
    )

    assignment_notes = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Assignment Notes"),
        help_text=_("Notes about the instructor assignment")
    )

    # Provider relationship (for self-paced courses)
    provider = models.ForeignKey(
        'organizations.Company',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='instructors',
        verbose_name=_("Provider"),
        help_text=_("Company/provider this instructor works for")
    )

    # Legacy field mapping (for existing database)
    instructor_user_id = models.BigIntegerField(
        blank=True,
        null=True,
        verbose_name=_("Instructor User ID (Legacy)"),
        help_text=_("Legacy user ID field - use user field instead")
    )

    notes = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Administrative Notes")
    )

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'instructors'
        verbose_name = _("Instructor")
        verbose_name_plural = _("Instructors")
        ordering = ['user__name', 'instructor_id']

    def __str__(self):
        return f"{self.user.name or self.user.username} ({self.instructor_id})"

    @property
    def current_course_count(self):
        """Number of currently assigned active courses."""
        return self.course_assignments.filter(
            status__in=['assigned', 'ongoing']
        ).count()

    @property
    def utilization_rate(self):
        """Percentage of capacity being utilized."""
        if self.max_courses == 0:
            return 0
        return (self.current_course_count / self.max_courses) * 100

    def get_status_display(self):
        """Get a human-readable status."""
        if not self.is_active:
            return _("Inactive")
        if not self.is_available:
            return _("Unavailable")
        return _("Active & Available")


class CourseAssignment(models.Model):
    """
    Assignment of instructors to courses.
    """
    ASSIGNMENT_STATUS = [
        ('pending', _('Pending')),
        ('assigned', _('Assigned')),
        ('ongoing', _('Ongoing')),
        ('completed', _('Completed')),
        ('cancelled', _('Cancelled')),
    ]

    assignment_id = models.CharField(
        max_length=50,
        unique=True,
        default=generate_assignment_id,
        verbose_name=_("Assignment ID")
    )

    instructor = models.ForeignKey(Instructor, null=True, blank=True,
        on_delete=models.CASCADE,
        related_name='course_assignments',
        verbose_name=_("Instructor")
    )

    course = models.ForeignKey(
        'courses.Course',
        on_delete=models.CASCADE,
        related_name='instructor_assignments',
        verbose_name=_("Course")
    )

    status = models.CharField(
        max_length=20,
        choices=ASSIGNMENT_STATUS,
        default='pending',
        verbose_name=_("Assignment Status")
    )

    # Assignment details
    assigned_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='assignments_made',
        verbose_name=_("Assigned By"),
    )

    assigned_date = models.DateField(
        default=timezone.now,
        verbose_name=_("Date Assigned")
    )

    start_date = models.DateField(
        verbose_name=_("Start Date")
    )

    expected_end_date = models.DateField(
        verbose_name=_("Expected End Date")
    )

    actual_end_date = models.DateField(
        blank=True,
        null=True,
        verbose_name=_("Actual End Date")
    )

    assignment_notes = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Assignment Notes"),
        help_text=_("Notes about this specific assignment")
    )

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'course_assignments'
        verbose_name = _("Course Assignment")
        verbose_name_plural = _("Course Assignments")
        ordering = ['-assigned_date']

    def __str__(self):
        return f"{self.instructor} - {self.course.title}"

    def get_status_display(self):
        """Override to get translated status."""
        return dict(self.ASSIGNMENT_STATUS).get(self.status, self.status)


class InstructorRating(models.Model):
    """
    Ratings and reviews for instructors by students.
    """
    instructor = models.ForeignKey(Instructor, null=True, blank=True,
        on_delete=models.CASCADE,
        related_name='ratings',
        verbose_name=_("Instructor")
    )

    course = models.ForeignKey(
        'courses.Course',
        on_delete=models.CASCADE,
        related_name='instructor_ratings',
        verbose_name=_("Course")
    )

    student = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='instructor_ratings_given',
        verbose_name=_("Student"),
    )

    rating = models.FloatField(
        validators=[MinValueValidator(0.0), MaxValueValidator(5.0)],
        verbose_name=_("Rating (0-5)")
    )

    review = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Review/Comment")
    )

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'instructor_ratings'
        verbose_name = _("Instructor Rating")
        verbose_name_plural = _("Instructor Ratings")
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.student.name or self.student.username}: {self.rating}/5 for {self.instructor}"


class InstructorActivityLog(models.Model):
    """
    Log of activities performed by instructors (teaching, content creation, etc.)
    """
    ACTIVITY_TYPES = [
        ('course_creation', _('Course Created')),
        ('content_upload', _('Content Uploaded')),
        ('assessment_created', _('Assessment Created')),
        ('live_session', _('Live Session Conducted')),
        ('student_feedback', _('Student Feedback Provided')),
        ('grading', _('Grading Completed')),
        ('forum_participation', _('Forum Participation')),
        ('announcement', _('Announcement Posted')),
        ('resource_shared', _('Resource Shared')),
        ('meeting_attended', _('Meeting Attended')),
        ('training_completed', _('Training Completed')),
        ('other', _('Other Activity')),
    ]

    instructor = models.ForeignKey(Instructor, null=True, blank=True,
        on_delete=models.CASCADE,
        related_name='activities',
        verbose_name=_("Instructor")
    )

    activity_type = models.CharField(
        max_length=50,
        choices=ACTIVITY_TYPES,
        verbose_name=_("Activity Type")
    )

    description = models.TextField(
        verbose_name=_("Activity Description")
    )

    course = models.ForeignKey(
        'courses.Course',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='instructor_activities',
        verbose_name=_("Course (if applicable)")
    )

    activity_date = models.DateTimeField(
        default=timezone.now,
        verbose_name=_("Activity Date/Time")
    )

    duration_minutes = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Duration (minutes)")
    )

    is_verified = models.BooleanField(
        default=False,
        verbose_name=_("Verified Activity")
    )

    verification_notes = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Verification Notes")
    )

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'instructor_activity_logs'
        verbose_name = _("Instructor Activity Log")
        verbose_name_plural = _("Instructor Activity Logs")
        ordering = ['-activity_date']

    def __str__(self):
        return f"{self.instructor} - {self.get_activity_type_display()} - {self.activity_date}"


class PerformanceAppraisal(models.Model):
    """
    Performance appraisal records for instructors.
    """
    APPRAISAL_TYPES = [
        ('quarterly', _('Quarterly Review')),
        ('mid_year', _('Mid-Year Review')),
        ('annual', _('Annual Review')),
        ('probation', _('Probation Review')),
        ('promotion', _('Promotion Review')),
        ('special', _('Special Review')),
    ]

    APPRAISAL_STATUS = [
        ('draft', _('Draft')),
        ('scheduled', _('Scheduled')),
        ('in_progress', _('In Progress')),
        ('completed', _('Completed')),
        ('archived', _('Archived')),
    ]

    appraisal_id = models.CharField(
        max_length=50,
        unique=True,
        default=generate_appraisal_id,
        verbose_name=_("Appraisal ID")
    )

    instructor = models.ForeignKey(Instructor, null=True, blank=True,
        on_delete=models.CASCADE,
        related_name='appraisals',
        verbose_name=_("Instructor")
    )

    appraisal_type = models.CharField(
        max_length=20,
        choices=APPRAISAL_TYPES,
        verbose_name=_("Appraisal Type")
    )

    status = models.CharField(
        max_length=20,
        choices=APPRAISAL_STATUS,
        default='draft',
        verbose_name=_("Status")
    )

    appraisal_period_start = models.DateField(
        verbose_name=_("Appraisal Period Start")
    )

    appraisal_period_end = models.DateField(
        verbose_name=_("Appraisal Period End")
    )

    scheduled_date = models.DateField(
        verbose_name=_("Scheduled Date")
    )

    # Appraisal metrics
    overall_score = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(100.0)],
        verbose_name=_("Overall Score")
    )

    knowledge_expertise = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(10.0)],
        verbose_name=_("Knowledge & Expertise")
    )

    teaching_effectiveness = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(10.0)],
        verbose_name=_("Teaching Effectiveness")
    )

    student_engagement = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(10.0)],
        verbose_name=_("Student Engagement")
    )

    communication_skills = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(10.0)],
        verbose_name=_("Communication Skills")
    )

    professionalism = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(10.0)],
        verbose_name=_("Professionalism")
    )

    # Qualitative feedback
    strengths = models.TextField(
        verbose_name=_("Strengths"),
        help_text=_("Key strengths demonstrated during the appraisal period")
    )

    areas_for_improvement = models.TextField(
        verbose_name=_("Areas for Improvement"),
        help_text=_("Areas where improvement is needed")
    )

    development_plan = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Development Plan"),
        help_text=_("Specific development plan for the next period")
    )

    # Reviewers
    reviewed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='instructor_appraisals_conducted',
        verbose_name=_("Reviewed By"),
    )

    review_date = models.DateField(
        blank=True,
        null=True,
        verbose_name=_("Review Date")
    )

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'performance_appraisals'
        verbose_name = _("Performance Appraisal")
        verbose_name_plural = _("Performance Appraisals")
        ordering = ['-scheduled_date']

    def __str__(self):
        return f"{self.instructor} - {self.get_appraisal_type_display()} - {self.appraisal_period_start}"


class InstructorAnalytics(models.Model):
    """
    Analytics data for instructors (aggregated periodically).
    """
    instructor = models.ForeignKey(Instructor, null=True, blank=True,
        on_delete=models.CASCADE,
        related_name='analytics',
        verbose_name=_("Instructor")
    )

    period_start = models.DateField(
        verbose_name=_("Period Start")
    )

    period_end = models.DateField(
        verbose_name=_("Period End")
    )

    # Analytics metrics
    courses_completed = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Courses Completed")
    )

    courses_ongoing = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Courses Ongoing")
    )

    total_students = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Total Students")
    )

    average_rating = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(5.0)],
        verbose_name=_("Average Rating")
    )

    completion_rate = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(100.0)],
        verbose_name=_("Completion Rate")
    )

    student_retention = models.FloatField(
        default=0.0,
        validators=[MinValueValidator(0.0), MaxValueValidator(100.0)],
        verbose_name=_("Student Retention Rate")
    )

    activity_hours = models.FloatField(
        default=0.0,
        verbose_name=_("Total Activity Hours")
    )

    content_created = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Content Items Created")
    )

    assessments_created = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Assessments Created")
    )

    # Flags
    is_current = models.BooleanField(
        default=False,
        verbose_name=_("Current Period Analytics")
    )

    # Metadata
    calculated_at = models.DateTimeField(auto_now_add=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'instructor_analytics'
        verbose_name = _("Instructor Analytics")
        verbose_name_plural = _("Instructor Analytics")
        ordering = ['-period_end']
        unique_together = ['instructor', 'period_start', 'period_end']

    def __str__(self):
        return f"{self.instructor} Analytics ({self.period_start} to {self.period_end})"


# Import instructor application models
# Note: InstructorAnalytics is defined in this file (models.py)
# models_instructor_application.py has a duplicate that we don't import
from .models_instructor_application import (
    InstructorApplication,
    InstructorStatusLog,
)

# Import hours claims models
from .models_hours_claims import (
    InstructorHoursClaim,
    InstructorOvertime,
    InstructorPayrollSummary,
)
