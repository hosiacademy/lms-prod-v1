from django.db import models
from django.conf import settings
from apps.learnerships.models import LearnershipProgramme, LearnershipPhase, LearnershipEnrollment, LearnershipSchedule

class PlatformAnalytics(models.Model):
    """Platform-wide analytics"""
    date = models.DateField(unique=True)
    total_users = models.IntegerField(default=0)
    active_users = models.IntegerField(default=0)
    new_users = models.IntegerField(default=0)
    page_views = models.IntegerField(default=0)
    
    class Meta:
        verbose_name = "Platform Analytics"
        verbose_name_plural = "Platform Analytics"
        ordering = ['-date']
    
    def __str__(self):
        return f"Platform Analytics - {self.date}"


class CourseAnalytics(models.Model):
    """Analytics for AiCerts courses"""
    course = models.ForeignKey(
        'aicerts_courses.AiCertsCourse',
        on_delete=models.CASCADE,
        related_name='analytics'
    )
    date = models.DateField()
    views = models.IntegerField(default=0)
    enrollments = models.IntegerField(default=0)
    completions = models.IntegerField(default=0)
    
    class Meta:
        unique_together = ['course', 'date']
        ordering = ['-date']
    
    def __str__(self):
        return f"{self.course.title} - {self.date}"


class LearnershipAnalytics(models.Model):
    """Analytics for learnerships"""
    learnership = models.ForeignKey(
        LearnershipProgramme,  # <-- updated from Learnership
        on_delete=models.CASCADE,
        related_name='analytics'
    )
    date = models.DateField()
    views = models.IntegerField(default=0)
    enrollments = models.IntegerField(default=0)
    completions = models.IntegerField(default=0)
    
    class Meta:
        unique_together = ['learnership', 'date']
        ordering = ['-date']
    
    def __str__(self):
        return f"{self.learnership.title} - {self.date}"


class UserProgress(models.Model):
    """Tracks user progress through courses and learnerships"""
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='progress')
    course = models.ForeignKey(
        'aicerts_courses.AiCertsCourse',
        on_delete=models.CASCADE,
        null=True,
        blank=True
    )
    learnership = models.ForeignKey(
        LearnershipProgramme,  # <-- updated from Learnership
        on_delete=models.CASCADE,
        null=True,
        blank=True
    )
    progress_percentage = models.FloatField(default=0)
    last_accessed = models.DateTimeField(auto_now=True)
    
    class Meta:
        unique_together = [['user', 'course'], ['user', 'learnership']]
    
    def __str__(self):
        if self.course:
            return f"{self.user.email} - {self.course.title} ({self.progress_percentage}%)"
        elif self.learnership:
            return f"{self.user.email} - {self.learnership.title} ({self.progress_percentage}%)"
        else:
            return f"{self.user.email} - No progress item"

    def save(self, *args, **kwargs):
        # Ensure either course OR learnership is set, not both
        if self.course and self.learnership:
            raise ValueError("Cannot have both course and learnership set")
        super().save(*args, **kwargs)


class ActivityLog(models.Model):
    """Logs user activities"""
    ACTIVITY_TYPES = [
        ('course_view', 'Course View'),
        ('course_enroll', 'Course Enrollment'),
        ('course_complete', 'Course Completion'),
        ('learnership_view', 'Learnership View'),
        ('learnership_enroll', 'Learnership Enrollment'),
        ('learnership_complete', 'Learnership Completion'),
        ('login', 'User Login'),
        ('search', 'Search'),
    ]
    
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True)
    activity_type = models.CharField(max_length=50, choices=ACTIVITY_TYPES)
    course = models.ForeignKey(
        'aicerts_courses.AiCertsCourse',
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
    learnership = models.ForeignKey(
        LearnershipProgramme,  # <-- updated from Learnership
        on_delete=models.SET_NULL,
        null=True,
        blank=True
    )
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.TextField(blank=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-timestamp']
    
    def __str__(self):
        return f"{self.get_activity_type_display()} - {self.timestamp}"
