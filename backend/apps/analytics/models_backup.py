# apps/analytics/models.py

from django.db import models
from django.utils.translation import gettext_lazy as _
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType

# Direct import – the clean, reliable way to reference models in namespaced apps

from apps.courses.models import Course


class PlatformAnalytics(models.Model):
    """
    Daily platform-wide analytics snapshot.
    One row per day – perfect for dashboards and impact reports.
    """
    date = models.DateField(
        unique=True,
        verbose_name=_("Date"),
        help_text=_("Date of analytics snapshot")
    )
    active_users = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Daily Active Users"),
        help_text=_("Unique users who logged in or interacted")
    )
    new_registrations = models.PositiveIntegerField(
        default=0,
        verbose_name=_("New Registrations")
    )
    new_enrollments = models.PositiveIntegerField(
        default=0,
        verbose_name=_("New Course Enrollments")
    )
    certificates_issued = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Certificates Issued")
    )
    total_revenue = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0.0,
        verbose_name=_("Revenue Generated (Platform Currency)")
    )
    page_views = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Total Page Views")
    )
    mobile_users = models.PositiveIntegerField(
        default=0,
        verbose_name=_("Mobile Users"),
        help_text=_("Users accessing via mobile devices")
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'analytics_platform'  # ← Unique & clear
        verbose_name = _("Platform Analytics Snapshot")
        verbose_name_plural = _("Platform Analytics Snapshots")
        ordering = ['-date']
        indexes = [
            models.Index(fields=['date']),
        ]

    def __str__(self):
        return f"Analytics - {self.date} ({self.active_users} active users)"


class CourseAnalytics(models.Model):
    """
    Per-course performance metrics.
    Updated daily or on significant events.
    """
    course = models.OneToOneField(
        Course,  # ← Direct import – no string reference, no app_label issues
        on_delete=models.CASCADE,
        related_name='analytics',
        verbose_name=_("Course")
    )
    total_views = models.PositiveBigIntegerField(default=0, verbose_name=_("Total Views"))
    unique_visitors = models.PositiveIntegerField(default=0, verbose_name=_("Unique Visitors"))
    total_enrollments = models.PositiveIntegerField(default=0, verbose_name=_("Total Enrollments"))
    active_enrollments = models.PositiveIntegerField(default=0, verbose_name=_("Currently Active Enrollments"))
    completions = models.PositiveIntegerField(default=0, verbose_name=_("Course Completions"))
    completion_rate = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=0.0,
        verbose_name=_("Completion Rate (%)"),
        help_text=_("completions / total_enrollments * 100")
    )
    average_rating = models.DecimalField(max_digits=3, decimal_places=2, default=0.0, verbose_name=_("Average Rating"))
    total_revenue = models.DecimalField(max_digits=12, decimal_places=2, default=0.0, verbose_name=_("Revenue Generated"))
    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'analytics_course'  # ← Unique
        verbose_name = _("Course Analytics")
        verbose_name_plural = _("Course Analytics")

    def __str__(self):
        return f"{self.course.title} – {self.completion_rate}% completion"

    def save(self, *args, **kwargs):
        if self.total_enrollments > 0:
            self.completion_rate = round((self.completions / self.total_enrollments) * 100, 2)
        else:
            self.completion_rate = 0.0
        super().save(*args, **kwargs)


class UserProgress(models.Model):
    """
    Individual learner progress per course.
    Powers personalized dashboards and recommendations.
    """
    user = models.ForeignKey('users.User', on_delete=models.CASCADE, related_name='progress_records')
    course = models.ForeignKey(
        Course,  # ← Direct import – clean and reliable
        on_delete=models.CASCADE,
        related_name='user_progress'
    )
    enrolled_at = models.DateTimeField(auto_now_add=True)
    last_accessed = models.DateTimeField(auto_now=True)
    lessons_completed = models.PositiveIntegerField(default=0)
    total_lessons = models.PositiveIntegerField(default=0)
    quizzes_completed = models.PositiveIntegerField(default=0)
    average_quiz_score = models.DecimalField(max_digits=5, decimal_places=2, default=0.0)
    time_spent_minutes = models.PositiveIntegerField(default=0)
    completed = models.BooleanField(default=False)
    certificate_issued = models.BooleanField(default=False)
    certificate_issued_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'analytics_user_progress'  # ← Unique
        unique_together = ('user', 'course')
        verbose_name = _("User Progress")
        verbose_name_plural = _("User Progress Records")
        indexes = [
            models.Index(fields=['user', 'completed']),
            models.Index(fields=['course', 'completed']),
            models.Index(fields=['last_accessed']),
        ]

    def __str__(self):
        status = "Completed" if self.completed else "In Progress"
        return f"{self.user.name or self.user.email} – {self.course.title} ({status})"

    @property
    def progress_percentage(self):
        if self.total_lessons == 0:
            return 0
        return round((self.lessons_completed / self.total_lessons) * 100, 1)


class ActivityLog(models.Model):
    """
    Generic activity tracking for analytics.
    Can log views, clicks, engagement events.
    """
    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        related_name='analytics_activity_logs'
    )
    action = models.CharField(
        max_length=100,
        verbose_name=_("Action"),
        help_text=_("e.g., 'course_view', 'lesson_complete', 'quiz_submit'")
    )
    content_type = models.ForeignKey(ContentType, on_delete=models.CASCADE, null=True, blank=True)
    object_id = models.PositiveBigIntegerField(null=True, blank=True)
    content_object = GenericForeignKey('content_type', 'object_id')

    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'analytics_activity_log'
        verbose_name = _("Activity Log")
        verbose_name_plural = _("Activity Logs")
        ordering = ['-timestamp']
        indexes = [
            models.Index(fields=['action', 'timestamp']),
            models.Index(fields=['user', 'timestamp']),
            models.Index(fields=['timestamp']),
        ]

    def __str__(self):
        user = self.user.name or self.user.email if self.user else "Anonymous"
        return f"{user} – {self.action} – {self.timestamp.strftime('%Y-%m-%d %H:%M')}"