# apps/bbb_integration/models.py
"""
BigBlueButton Integration Models
Handles live session scheduling, management, and recording
"""

from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _
import secrets
import uuid


class BBBServer(models.Model):
    """BigBlueButton server instance for load balancing"""
    name = models.CharField(max_length=255, help_text=_("Server name for identification"))
    api_url = models.URLField(help_text=_("BBB API base URL (e.g., https://bbb.example.com/bigbluebutton/api/)"))
    secret = models.CharField(max_length=255, help_text=_("BBB server secret key"))
    is_active = models.BooleanField(default=True, help_text=_("Is this server available for new sessions"))
    max_load = models.IntegerField(default=100, help_text=_("Maximum concurrent sessions"))
    current_load = models.IntegerField(default=0, help_text=_("Current active sessions"))
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'bbb_servers'
        verbose_name = _('BBB Server')
        verbose_name_plural = _('BBB Servers')

    def __str__(self):
        return f"{self.name} ({'Active' if self.is_active else 'Inactive'})"

    @property
    def load_percentage(self):
        """Calculate current load percentage"""
        if self.max_load == 0:
            return 0
        return (self.current_load / self.max_load) * 100


class LiveSession(models.Model):
    """Live class session"""

    STATUS_CHOICES = [
        ('scheduled', _('Scheduled')),
        ('live', _('Live')),
        ('ended', _('Ended')),
        ('cancelled', _('Cancelled')),
    ]

    # Primary identifiers
    session_id = models.CharField(max_length=255, unique=True, editable=False)
    meeting_id = models.CharField(max_length=255, unique=True, help_text=_("BBB meeting ID"))

    # Relationships
    course_id = models.IntegerField(help_text=_("Course ID (generic reference)"))
    course_type = models.CharField(max_length=50, default='course', help_text=_("Type: course, masterclass, learnership"))
    phase_id = models.IntegerField(null=True, blank=True, help_text=_("Learnership phase ID (optional)"))
    cohort_info = models.JSONField(default=dict, blank=True, help_text=_("Extra context: phase name, NQF level, location, cohort details"))
    instructor = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='taught_sessions',
        help_text=_("Session instructor/moderator")
    )

    # Session details
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, help_text=_("Session description or agenda"))

    # Scheduling
    scheduled_start = models.DateTimeField(help_text=_("Scheduled start time"))
    scheduled_end = models.DateTimeField(help_text=_("Scheduled end time"))
    actual_start = models.DateTimeField(null=True, blank=True, help_text=_("Actual start time"))
    actual_end = models.DateTimeField(null=True, blank=True, help_text=_("Actual end time"))

    # Status
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')

    # BBB configuration
    bbb_server = models.ForeignKey(BBBServer, on_delete=models.PROTECT, related_name='sessions')
    moderator_password = models.CharField(max_length=255, editable=False)
    attendee_password = models.CharField(max_length=255, editable=False)

    # Settings
    record = models.BooleanField(default=True, help_text=_("Record this session"))
    auto_start_recording = models.BooleanField(default=True, help_text=_("Start recording automatically"))
    max_participants = models.IntegerField(default=100, help_text=_("Maximum participants"))
    allow_start_stop_recording = models.BooleanField(default=True)

    # Recording status
    has_recording = models.BooleanField(default=False, help_text=_("Recording is available"))

    # Metadata
    welcome_message = models.TextField(blank=True, help_text=_("Welcome message shown when joining"))
    logout_url = models.URLField(blank=True, help_text=_("Redirect URL after leaving session"))

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'live_sessions'
        verbose_name = _('Live Session')
        verbose_name_plural = _('Live Sessions')
        ordering = ['-scheduled_start']
        indexes = [
            models.Index(fields=['status', 'scheduled_start']),
            models.Index(fields=['instructor', 'status']),
            models.Index(fields=['course_id', 'course_type']),
        ]

    def __str__(self):
        return f"{self.title} - {self.get_status_display()}"

    def save(self, *args, **kwargs):
        # Generate session_id and meeting_id if not set
        if not self.session_id:
            self.session_id = f"session-{uuid.uuid4().hex[:12]}"
        if not self.meeting_id:
            self.meeting_id = f"course-{self.course_id}-{secrets.token_hex(8)}"

        # Generate passwords if not set
        if not self.moderator_password:
            self.moderator_password = secrets.token_urlsafe(16)
        if not self.attendee_password:
            self.attendee_password = secrets.token_urlsafe(16)

        super().save(*args, **kwargs)

    @property
    def duration_minutes(self):
        """Scheduled duration in minutes"""
        if self.scheduled_start and self.scheduled_end:
            delta = self.scheduled_end - self.scheduled_start
            return int(delta.total_seconds() / 60)
        return 0

    @property
    def is_upcoming(self):
        """Check if session is upcoming"""
        from django.utils import timezone
        return self.status == 'scheduled' and self.scheduled_start > timezone.now()

    @property
    def is_live_now(self):
        """Check if session is currently live"""
        return self.status == 'live'


class SessionRecording(models.Model):
    """Recording of a live session"""

    # Primary identifiers
    record_id = models.CharField(max_length=255, unique=True, help_text=_("BBB recording ID"))
    session = models.ForeignKey(LiveSession, on_delete=models.CASCADE, related_name='recordings')

    # Recording details
    name = models.CharField(max_length=255)
    published = models.BooleanField(default=False, help_text=_("Is recording published/visible"))

    # Timing
    start_time = models.DateTimeField()
    end_time = models.DateTimeField()
    duration_minutes = models.IntegerField(help_text=_("Recording duration in minutes"))

    # Playback
    playback_url = models.URLField(help_text=_("BBB playback URL"))
    playback_format = models.CharField(max_length=50, default='presentation', help_text=_("Format: presentation, video"))

    # Metadata
    size_bytes = models.BigIntegerField(default=0, help_text=_("Recording file size in bytes"))
    thumbnail_url = models.URLField(blank=True, null=True, help_text=_("Recording thumbnail"))
    metadata = models.JSONField(default=dict, blank=True, help_text=_("Additional recording metadata"))

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'session_recordings'
        verbose_name = _('Session Recording')
        verbose_name_plural = _('Session Recordings')
        ordering = ['-start_time']
        indexes = [
            models.Index(fields=['session', 'published']),
            models.Index(fields=['start_time']),
        ]

    def __str__(self):
        return f"Recording: {self.name}"

    @property
    def size_mb(self):
        """Size in megabytes"""
        return round(self.size_bytes / (1024 * 1024), 2)


class SessionAttendance(models.Model):
    """Track user attendance in live sessions"""

    session = models.ForeignKey(LiveSession, on_delete=models.CASCADE, related_name='attendances')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='session_attendances')

    # Attendance tracking
    joined_at = models.DateTimeField(auto_now_add=True)
    left_at = models.DateTimeField(null=True, blank=True)
    duration_minutes = models.IntegerField(default=0, help_text=_("Time spent in session (minutes)"))

    # Role
    joined_as_moderator = models.BooleanField(default=False)

    class Meta:
        db_table = 'session_attendances'
        verbose_name = _('Session Attendance')
        verbose_name_plural = _('Session Attendances')
        unique_together = [['session', 'user']]
        indexes = [
            models.Index(fields=['session', 'user']),
            models.Index(fields=['user', 'joined_at']),
        ]

    def __str__(self):
        return f"{self.user.get_full_name()} - {self.session.title}"

    def update_duration(self):
        """Update duration based on join/leave times"""
        if self.joined_at and self.left_at:
            delta = self.left_at - self.joined_at
            self.duration_minutes = int(delta.total_seconds() / 60)
            self.save()


class SessionInvitation(models.Model):
    """Email invitation for students to join a BBB session"""

    STATUS_CHOICES = [
        ('pending', _('Pending')),
        ('sent', _('Sent')),
        ('opened', _('Opened')),
        ('joined', _('Joined')),
        ('expired', _('Expired')),
    ]

    session = models.ForeignKey(
        LiveSession,
        on_delete=models.CASCADE,
        related_name='invitations'
    )
    email = models.EmailField(help_text=_("Student email address"))
    student_name = models.CharField(max_length=255, help_text=_("Student name"))
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')

    # Invitation tracking
    invitation_token = models.CharField(max_length=255, unique=True, editable=False)
    sent_at = models.DateTimeField(null=True, blank=True)
    opened_at = models.DateTimeField(null=True, blank=True)
    joined_at = models.DateTimeField(null=True, blank=True)

    # Chat invitation
    chat_invitation_sent = models.BooleanField(default=False, help_text=_("Whether 1-on-1 chat invite was sent"))
    chat_invitation_accepted = models.BooleanField(default=False, help_text=_("Whether student accepted chat invite"))

    # Metadata
    metadata = models.JSONField(default=dict, blank=True, help_text=_("Additional invitation metadata"))
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'session_invitations'
        verbose_name = _('Session Invitation')
        verbose_name_plural = _('Session Invitations')
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['session', 'status']),
            models.Index(fields=['email', 'status']),
            models.Index(fields=['invitation_token']),
        ]

    def __str__(self):
        return f"{self.student_name} ({self.email}) - {self.session.title}"

    def save(self, *args, **kwargs):
        # Generate invitation token if not set
        if not self.invitation_token:
            self.invitation_token = secrets.token_urlsafe(32)
        super().save(*args, **kwargs)

    @property
    def is_expired(self):
        """Check if invitation has expired (24 hours after session end)"""
        from django.utils import timezone
        if self.session.scheduled_end:
            expiry = self.session.scheduled_end + timezone.timedelta(hours=24)
            return timezone.now() > expiry
        return False

    def mark_as_joined(self):
        """Mark invitation as joined"""
        self.status = 'joined'
        self.joined_at = timezone.now()
        self.save()

    def mark_as_opened(self):
        """Mark invitation as opened"""
        if self.status == 'sent':
            self.status = 'opened'
            self.opened_at = timezone.now()
            self.save()
