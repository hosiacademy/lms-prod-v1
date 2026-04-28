# apps/notifications/admin.py

from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse

from .models import Notification, ActivityLog, Message


@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    """
    Admin interface for user notifications (from notifications table).
    Shows which users have unread notifications and links to related content.
    """
    list_display = (
        'user_link', 'message_preview', 'course_link',
        'is_read', 'created_at'
    )
    list_filter = ('status', 'created_at')
    search_fields = (
        'user__name', 'user__email', 'user__username',
        'message_id', 'course_comment_id', 'course_review_id'
    )
    readonly_fields = ('created_at', 'updated_at')
    ordering = ('-created_at',)

    def user_link(self, obj):
        if obj.user:
            url = reverse("admin:users_user_change", args=[obj.user.id])
            return format_html('<a href="{}">{}</a>', url, obj.user.name or obj.user.email)
        return "-"
    user_link.short_description = "User"

    def course_link(self, obj):
        if obj.course:
            url = reverse("admin:courses_course_change", args=[obj.course.id])
            return format_html('<a href="{}">{}</a>', url, obj.course.title)
        return "-"
    course_link.short_description = "Related Course"

    def message_preview(self, obj):
        # Simple preview - can be enhanced based on type
        if obj.message_id:
            return "New Message"
        if obj.course_comment_id:
            return "New Comment"
        if obj.course_review_id:
            return "New Review"
        if obj.course_enrolled_id:
            return "Enrollment Confirmed"
        return "System Notification"
    message_preview.short_description = "Type"

    def is_read(self, obj):
        return not obj.status  # status=False means unread in original schema
    is_read.boolean = True
    is_read.short_description = "Read"

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('user', 'course')


@admin.register(ActivityLog)
class ActivityLogAdmin(admin.ModelAdmin):
    """
    Admin interface for system activity logs (Spatie-like activity log).
    Useful for auditing user and admin actions.
    """
    list_display = ('description', 'causer_link', 'subject_info', 'log_name', 'created_at')
    list_filter = ('log_name', 'created_at')
    search_fields = ('description', 'causer__name', 'causer__email')
    readonly_fields = ('created_at', 'updated_at')
    ordering = ('-created_at',)

    def causer_link(self, obj):
        if obj.causer_id and obj.causer_type:
            # Assuming causer_type is User model path
            if obj.causer:
                url = reverse("admin:users_user_change", args=[obj.causer.id])
                return format_html('<a href="{}">{}</a>', url, obj.causer.name or obj.causer.email)
        return "System"
    causer_link.short_description = "Performed By"

    def subject_info(self, obj):
        if obj.subject_id and obj.subject_type:
            return f"{obj.subject_type} #{obj.subject_id}"
        return "-"
    subject_info.short_description = "Subject"

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('causer')


@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    """
    Admin interface for private messages between users (instructors ↔ students).
    """
    list_display = (
        'sender_link', 'receiver_link', 'message_preview',
        'type_display', 'seen', 'created_at'
    )
    list_filter = ('type', 'seen', 'created_at')
    search_fields = (
        'sender__name', 'sender__email',
        'reciever__name', 'reciever__email',
        'message'
    )
    readonly_fields = ('created_at', 'updated_at')
    ordering = ('-created_at',)

    def sender_link(self, obj):
        if obj.sender:
            url = reverse("admin:users_user_change", args=[obj.sender.id])
            return format_html('<a href="{}">{}</a>', url, obj.sender.name or obj.sender.email)
        return "-"
    sender_link.short_description = "From"

    def receiver_link(self, obj):
        if obj.reciever:
            url = reverse("admin:users_user_change", args=[obj.reciever.id])
            return format_html('<a href="{}">{}</a>', url, obj.reciever.name or obj.reciever.email)
        return "-"
    receiver_link.short_description = "To"

    def message_preview(self, obj):
        return (obj.message[:60] + '...') if len(obj.message) > 60 else obj.message
    message_preview.short_description = "Message"

    def type_display(self, obj):
        return "Direct" if obj.type else "System"
    type_display.short_description = "Type"

    def get_queryset(self, request):
        return super().get_queryset(request).select_related('sender', 'reciever')