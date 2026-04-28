from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils import timezone
from .models import BBBServer, LiveSession, SessionRecording, SessionAttendance, SessionInvitation
from .services import InstructorSessionManager


@admin.register(BBBServer)
class BBBServerAdmin(admin.ModelAdmin):
    """Admin interface for BBB servers"""
    list_display = ['name', 'api_url', 'is_active', 'load_status', 'created_at']
    list_filter = ['is_active', 'created_at']
    search_fields = ['name', 'api_url']
    readonly_fields = ['created_at', 'updated_at', 'load_percentage']

    fieldsets = [
        ('Server Information', {
            'fields': ['name', 'api_url', 'secret', 'is_active']
        }),
        ('Capacity', {
            'fields': ['max_load', 'current_load', 'load_percentage']
        }),
        ('Timestamps', {
            'fields': ['created_at', 'updated_at'],
            'classes': ['collapse']
        }),
    ]

    def load_status(self, obj):
        """Display load percentage with color coding"""
        percentage = obj.load_percentage
        if percentage >= 90:
            color = 'red'
        elif percentage >= 70:
            color = 'orange'
        else:
            color = 'green'
        return format_html(
            '<span style="color: {}; font-weight: bold;">{:.1f}%</span>',
            color, percentage
        )
    load_status.short_description = 'Load Status'


@admin.register(LiveSession)
class LiveSessionAdmin(admin.ModelAdmin):
    """Admin interface for live sessions - Full instructor control"""
    list_display = [
        'title', 'instructor', 'status_badge', 'course_info',
        'scheduled_start', 'duration_display', 'participant_count', 'recording_status'
    ]
    list_filter = ['status', 'course_type', 'record', 'scheduled_start', 'bbb_server']
    search_fields = ['title', 'description', 'instructor__email', 'instructor__first_name', 'instructor__last_name']
    date_hierarchy = 'scheduled_start'
    readonly_fields = [
        'session_id', 'meeting_id', 'moderator_password', 'attendee_password',
        'actual_start', 'actual_end', 'created_at', 'updated_at', 'duration_minutes'
    ]
    autocomplete_fields = ['instructor']

    fieldsets = [
        ('Basic Information', {
            'fields': ['title', 'description', 'instructor', 'status']
        }),
        ('Course Association', {
            'fields': ['course_id', 'course_type']
        }),
        ('Schedule', {
            'fields': ['scheduled_start', 'scheduled_end', 'actual_start', 'actual_end', 'duration_minutes'],
            'description': 'Set when the session will start and end'
        }),
        ('BBB Configuration', {
            'fields': ['bbb_server', 'session_id', 'meeting_id', 'moderator_password', 'attendee_password']
        }),
        ('Session Settings', {
            'fields': [
                'record', 'auto_start_recording', 'allow_start_stop_recording',
                'max_participants', 'has_recording'
            ],
            'description': 'Configure recording and participant limits'
        }),
        ('Customization', {
            'fields': ['welcome_message', 'logout_url'],
            'classes': ['collapse']
        }),
        ('Timestamps', {
            'fields': ['created_at', 'updated_at'],
            'classes': ['collapse']
        }),
    ]

    actions = ['mark_as_live', 'mark_as_ended', 'cancel_sessions', 'auto_invite_students']

    def status_badge(self, obj):
        """Display status with color coding"""
        colors = {
            'scheduled': 'blue',
            'live': 'green',
            'ended': 'gray',
            'cancelled': 'red'
        }
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{}</span>',
            colors.get(obj.status, 'gray'),
            obj.get_status_display()
        )
    status_badge.short_description = 'Status'

    def course_info(self, obj):
        """Display course information"""
        return f"{obj.course_type.title()} #{obj.course_id}"
    course_info.short_description = 'Course'

    def duration_display(self, obj):
        """Display scheduled duration"""
        return f"{obj.duration_minutes} min"
    duration_display.short_description = 'Duration'

    def participant_count(self, obj):
        """Display number of participants"""
        count = obj.attendances.count()
        return format_html('<strong>{}</strong> / {}', count, obj.max_participants)
    participant_count.short_description = 'Participants'

    def recording_status(self, obj):
        """Display recording status"""
        if obj.has_recording:
            count = obj.recordings.filter(published=True).count()
            return format_html(
                '<span style="color: green;">✓</span> {} recording(s)',
                count
            )
        return format_html('<span style="color: gray;">No recording</span>')
    recording_status.short_description = 'Recordings'

    def mark_as_live(self, request, queryset):
        """Mark sessions as live"""
        queryset.update(status='live', actual_start=timezone.now())
        self.message_user(request, f"{queryset.count()} session(s) marked as live")
    mark_as_live.short_description = "Mark selected as Live"

    def mark_as_ended(self, request, queryset):
        """Mark sessions as ended"""
        queryset.update(status='ended', actual_end=timezone.now())
        self.message_user(request, f"{queryset.count()} session(s) marked as ended")
    mark_as_ended.short_description = "Mark selected as Ended"

    def cancel_sessions(self, request, queryset):
        """Cancel sessions"""
        queryset.update(status='cancelled')
        self.message_user(request, f"{queryset.count()} session(s) cancelled")
    cancel_sessions.short_description = "Cancel selected sessions"

    def auto_invite_students(self, request, queryset):
        """Auto-invite enrolled students to sessions"""
        count = 0
        for session in queryset:
            try:
                sent = InstructorSessionManager.auto_invite_enrolled_students(session)
                count += sent
            except Exception as e:
                self.message_user(request, f"Failed to invite for {session.title}: {e}", level='error')
        
        self.message_user(request, f"{count} invitation(s) sent across {queryset.count()} session(s)")
    auto_invite_students.short_description = "Auto-invite enrolled students"


@admin.register(SessionRecording)
class SessionRecordingAdmin(admin.ModelAdmin):
    """Admin interface for session recordings"""
    list_display = [
        'name', 'session', 'published_status', 'duration_display',
        'size_display', 'start_time', 'playback_link'
    ]
    list_filter = ['published', 'playback_format', 'start_time']
    search_fields = ['name', 'session__title', 'record_id']
    date_hierarchy = 'start_time'
    readonly_fields = [
        'record_id', 'start_time', 'end_time', 'duration_minutes',
        'playback_url', 'size_bytes', 'created_at', 'updated_at'
    ]

    fieldsets = [
        ('Recording Information', {
            'fields': ['name', 'session', 'record_id', 'published']
        }),
        ('Timing', {
            'fields': ['start_time', 'end_time', 'duration_minutes']
        }),
        ('Playback', {
            'fields': ['playback_url', 'playback_format', 'thumbnail_url']
        }),
        ('Metadata', {
            'fields': ['size_bytes', 'metadata'],
            'classes': ['collapse']
        }),
        ('Timestamps', {
            'fields': ['created_at', 'updated_at'],
            'classes': ['collapse']
        }),
    ]

    def published_status(self, obj):
        """Display published status"""
        if obj.published:
            return format_html('<span style="color: green;">✓ Published</span>')
        return format_html('<span style="color: orange;">⊗ Unpublished</span>')
    published_status.short_description = 'Status'

    def duration_display(self, obj):
        """Display duration"""
        return f"{obj.duration_minutes} min"
    duration_display.short_description = 'Duration'

    def size_display(self, obj):
        """Display file size"""
        return f"{obj.size_mb} MB"
    size_display.short_description = 'Size'

    def playback_link(self, obj):
        """Display playback link"""
        if obj.playback_url:
            return format_html(
                '<a href="{}" target="_blank" style="color: blue;">▶ Play</a>',
                obj.playback_url
            )
        return '-'
    playback_link.short_description = 'Playback'


@admin.register(SessionAttendance)
class SessionAttendanceAdmin(admin.ModelAdmin):
    """Admin interface for session attendance"""
    list_display = [
        'user', 'session', 'role_badge', 'joined_at',
        'duration_display', 'status'
    ]
    list_filter = ['joined_as_moderator', 'joined_at']
    search_fields = [
        'user__email', 'user__first_name', 'user__last_name',
        'session__title'
    ]
    date_hierarchy = 'joined_at'
    readonly_fields = ['joined_at', 'left_at', 'duration_minutes']
    autocomplete_fields = ['user', 'session']

    fieldsets = [
        ('Attendance Information', {
            'fields': ['session', 'user', 'joined_as_moderator']
        }),
        ('Timing', {
            'fields': ['joined_at', 'left_at', 'duration_minutes']
        }),
    ]

    def role_badge(self, obj):
        """Display user role"""
        if obj.joined_as_moderator:
            return format_html(
                '<span style="background-color: purple; color: white; padding: 2px 6px; border-radius: 3px;">Moderator</span>'
            )
        return format_html(
            '<span style="background-color: blue; color: white; padding: 2px 6px; border-radius: 3px;">Attendee</span>'
        )
    role_badge.short_description = 'Role'

    def duration_display(self, obj):
        """Display attendance duration"""
        if obj.duration_minutes:
            return f"{obj.duration_minutes} min"
        return "In session"
    duration_display.short_description = 'Duration'

    def status(self, obj):
        """Display attendance status"""
        if obj.left_at:
            return format_html('<span style="color: gray;">Left</span>')
        return format_html('<span style="color: green;">Active</span>')
    status.short_description = 'Status'


@admin.register(SessionInvitation)
class SessionInvitationAdmin(admin.ModelAdmin):
    """Admin interface for session invitations"""
    list_display = [
        'student_name', 'email', 'session', 'status_badge',
        'chat_status', 'sent_at', 'joined_at_display'
    ]
    list_filter = ['status', 'chat_invitation_sent', 'chat_invitation_accepted', 'sent_at']
    search_fields = ['email', 'student_name', 'session__title']
    date_hierarchy = 'created_at'
    readonly_fields = [
        'invitation_token', 'sent_at', 'opened_at', 'joined_at',
        'created_at', 'updated_at'
    ]
    autocomplete_fields = ['session']

    fieldsets = [
        ('Invitation Information', {
            'fields': ['session', 'email', 'student_name', 'status']
        }),
        ('Invitation Tracking', {
            'fields': ['invitation_token', 'sent_at', 'opened_at', 'joined_at']
        }),
        ('Chat Invitation', {
            'fields': ['chat_invitation_sent', 'chat_invitation_accepted']
        }),
        ('Metadata', {
            'fields': ['metadata'],
            'classes': ['collapse']
        }),
        ('Timestamps', {
            'fields': ['created_at', 'updated_at'],
            'classes': ['collapse']
        }),
    ]

    actions = [
        'resend_invitations',
        'send_chat_invitations',
        'mark_as_sent',
    ]

    def status_badge(self, obj):
        """Display invitation status with color coding"""
        colors = {
            'pending': 'gray',
            'sent': 'blue',
            'opened': 'orange',
            'joined': 'green',
            'expired': 'red'
        }
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 8px; border-radius: 3px;">{}</span>',
            colors.get(obj.status, 'gray'),
            obj.get_status_display()
        )
    status_badge.short_description = 'Status'

    def chat_status(self, obj):
        """Display chat invitation status"""
        if obj.chat_invitation_accepted:
            return format_html('<span style="color: green;">✓ Accepted</span>')
        elif obj.chat_invitation_sent:
            return format_html('<span style="color: orange;">⊗ Sent</span>')
        return format_html('<span style="color: gray;">Not sent</span>')
    chat_status.short_description = 'Chat Invite'

    def joined_at_display(self, obj):
        """Display joined at time"""
        if obj.joined_at:
            return obj.joined_at.strftime('%Y-%m-%d %H:%M')
        return '-'
    joined_at_display.short_description = 'Joined At'

    def resend_invitations(self, request, queryset):
        """Resend invitations to selected students"""
        from .email_service import BBBSessionEmailService
        
        count = 0
        for invitation in queryset:
            try:
                BBBSessionEmailService.send_session_invitation(invitation, invitation.session)
                count += 1
            except Exception as e:
                self.message_user(request, f"Failed to send to {invitation.email}: {e}", level='error')
        
        self.message_user(request, f"{count} invitation(s) resent successfully")
    resend_invitations.short_description = "Resend selected invitations"

    def send_chat_invitations(self, request, queryset):
        """Send chat invitations to selected students"""
        from .email_service import BBBSessionEmailService
        
        count = 0
        for invitation in queryset:
            if not invitation.chat_invitation_sent:
                try:
                    BBBSessionEmailService.send_chat_invitation(invitation, invitation.session)
                    count += 1
                except Exception as e:
                    self.message_user(request, f"Failed to send chat invite to {invitation.email}: {e}", level='error')
        
        self.message_user(request, f"{count} chat invitation(s) sent successfully")
    send_chat_invitations.short_description = "Send chat invitations"

    def mark_as_sent(self, request, queryset):
        """Mark pending invitations as sent"""
        count = queryset.filter(status='pending').update(status='sent', sent_at=timezone.now())
        self.message_user(request, f"{count} invitation(s) marked as sent")
    mark_as_sent.short_description = "Mark selected as sent"
