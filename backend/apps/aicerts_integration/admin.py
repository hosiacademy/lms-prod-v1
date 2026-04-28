# apps/aicerts_integration/admin.py
"""
Django Admin for AICERTs Partnership Integration
"""

from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from django.utils.safestring import mark_safe
from .models import (
    AICertsEnrollment,
    AICertsInstructorDesignation,
    AICertsSyncLog,
    AICertsSSOSession
)


@admin.register(AICertsEnrollment)
class AICertsEnrollmentAdmin(admin.ModelAdmin):
    """Admin for AICERTs enrollment tracking"""

    list_display = [
        'id',
        'user_link',
        'course_link',
        'status_badge',
        'progress_bar',
        'enrolled_at',
        'synced_at',
        'sync_attempts',
        'direct_access_link',
        'actions_column'
    ]
    list_filter = [
        'aicerts_enrollment_status',
        ('enrolled_at', admin.DateFieldListFilter),
        ('synced_at', admin.DateFieldListFilter),
        'aicerts_already_enrolled'
    ]
    search_fields = [
        'user__email',
        'user__first_name',
        'user__last_name',
        'course__title',
        'course__shortname'
    ]
    readonly_fields = [
        'enrolled_at',
        'synced_at',
        'last_sync_attempt',
        'sync_attempts',
        'created_at',
        'updated_at'
    ]
    fieldsets = (
        ('Basic Information', {
            'fields': ('user', 'course')
        }),
        ('Sync Status', {
            'fields': (
                'aicerts_enrollment_status',
                'aicerts_already_enrolled',
                'synced_at',
                'last_sync_attempt',
                'sync_attempts',
                'sync_error'
            )
        }),
        ('Progress Tracking', {
            'fields': (
                'progress_percentage',
                'last_accessed_at',
                'completed_at',
                'certificate_issued_at'
            )
        }),
        ('Timestamps', {
            'fields': ('enrolled_at', 'created_at', 'updated_at'),
            'classes': ('collapse',)
        })
    )

    def user_link(self, obj):
        """Link to user in admin"""
        url = reverse('admin:users_user_change', args=[obj.user.id])
        return format_html('<a href="{}">{}</a>', url, obj.user.email)
    user_link.short_description = 'User'

    def course_link(self, obj):
        """Link to course in admin"""
        url = reverse('admin:aicerts_courses_aicertscourse_change', args=[obj.course.id])
        return format_html('<a href="{}">{}</a>', url, obj.course.title[:50])
    course_link.short_description = 'Course'

    def status_badge(self, obj):
        """Color-coded status badge"""
        colors = {
            'pending': 'orange',
            'enrolled': 'green',
            'failed': 'red',
            'unenrolled': 'gray'
        }
        color = colors.get(obj.aicerts_enrollment_status, 'gray')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 3px;">{}</span>',
            color,
            obj.get_aicerts_enrollment_status_display()
        )
    status_badge.short_description = 'Status'

    def progress_bar(self, obj):
        """Visual progress bar"""
        percentage = float(obj.progress_percentage)
        color = 'green' if percentage >= 80 else 'orange' if percentage >= 50 else 'red'
        return format_html(
            '<div style="width: 100px; background-color: #f0f0f0; border-radius: 3px;">'
            '<div style="width: {}%; background-color: {}; height: 20px; border-radius: 3px; text-align: center; color: white; font-size: 12px; line-height: 20px;">'
            '{}%</div></div>',
            percentage,
            color,
            int(percentage)
        )
    progress_bar.short_description = 'Progress'

    def direct_access_link(self, obj):
        """SSO link for direct access to course on AICERTs"""
        if obj.aicerts_enrollment_status == 'enrolled':
            url = reverse('aicerts_integration:sso-redirect') + f"?course_id={obj.course.id}&user_id={obj.user.id}"
            # Note: This will use the current logged-in user for SSO if they click it,
            # but as an admin, we might want to represent the student.
            # However, the SSORedirectView uses request.user.
            # To get Richard's access specifically, we'd need his token or something.
            # But the user said "I click Richard's courses I am supposed to get access".
            return format_html(
                '<a class="button" href="{}" target="_blank" style="background-color: #d4af37; color: #1a365d; padding: 5px 10px; text-decoration: none; border-radius: 3px; font-weight: bold;">Launch LMS</a>',
                url
            )
        return '-'
    direct_access_link.short_description = 'LMS Access'

    def actions_column(self, obj):
        """Action buttons"""
        if obj.aicerts_enrollment_status == 'failed' and obj.needs_retry:
            return format_html(
                '<a class="button" href="{}?enrollment_id={}" style="background-color: orange; color: white; padding: 5px 10px; text-decoration: none; border-radius: 3px;">Retry Sync</a>',
                reverse('admin:aicerts_integration_aicertsenrollment_changelist'),
                obj.id
            )
        return '-'
    actions_column.short_description = 'Actions'

    actions = ['retry_failed_enrollments']

    def retry_failed_enrollments(self, request, queryset):
        """Admin action to retry failed enrollments"""
        from .services import SSOService, AICERTsEnrollmentError

        success_count = 0
        failed_count = 0

        for enrollment in queryset.filter(aicerts_enrollment_status='failed'):
            if enrollment.sync_attempts >= 3:
                continue

            try:
                SSOService.enroll_user(
                    aicerts_user_id=enrollment.user.aicerts_user_id,
                    course_id=enrollment.course.lms_course_id,  # Use Moodle course ID, not Django PK
                    email=enrollment.user.email
                )
                enrollment.mark_synced()
                success_count += 1
            except AICERTsEnrollmentError as e:
                enrollment.mark_failed(str(e))
                failed_count += 1

        self.message_user(
            request,
            f"Successfully synced {success_count} enrollments. {failed_count} failed."
        )
    retry_failed_enrollments.short_description = "Retry failed enrollment syncs"


@admin.register(AICertsInstructorDesignation)
class AICertsInstructorDesignationAdmin(admin.ModelAdmin):
    """Admin for instructor designations"""

    list_display = [
        'id',
        'instructor_link',
        'course_link',
        'aicerts_instructor_id',
        'active_badge',
        'designated_at',
        'designated_by_link'
    ]
    list_filter = [
        'is_active',
        ('designated_at', admin.DateFieldListFilter)
    ]
    search_fields = [
        'instructor__email',
        'instructor__first_name',
        'instructor__last_name',
        'course__title',
        'notes'
    ]
    readonly_fields = ['designated_at', 'designated_by', 'created_at', 'updated_at']

    def instructor_link(self, obj):
        """Link to instructor user"""
        url = reverse('admin:users_user_change', args=[obj.instructor.id])
        return format_html('<a href="{}">{}</a>', url, obj.instructor.get_full_name())
    instructor_link.short_description = 'Instructor'

    def course_link(self, obj):
        """Link to course"""
        url = reverse('admin:aicerts_courses_aicertscourse_change', args=[obj.course.id])
        return format_html('<a href="{}">{}</a>', url, obj.course.title[:50])
    course_link.short_description = 'Course'

    def designated_by_link(self, obj):
        """Link to admin who designated"""
        if obj.designated_by:
            url = reverse('admin:users_user_change', args=[obj.designated_by.id])
            return format_html('<a href="{}">{}</a>', url, obj.designated_by.get_full_name())
        return '-'
    designated_by_link.short_description = 'Designated By'

    def active_badge(self, obj):
        """Active status badge"""
        if obj.is_active:
            return format_html(
                '<span style="background-color: green; color: white; padding: 3px 10px; border-radius: 3px;">Active</span>'
            )
        return format_html(
            '<span style="background-color: gray; color: white; padding: 3px 10px; border-radius: 3px;">Inactive</span>'
        )
    active_badge.short_description = 'Status'


@admin.register(AICertsSyncLog)
class AICertsSyncLogAdmin(admin.ModelAdmin):
    """Admin for sync operation logs"""

    list_display = [
        'id',
        'operation_badge',
        'status_badge',
        'user_link',
        'course_link',
        'records_processed',
        'duration_display',
        'created_at'
    ]
    list_filter = [
        'operation_type',
        'status',
        ('created_at', admin.DateFieldListFilter)
    ]
    search_fields = [
        'user__email',
        'course__title',
        'error_message'
    ]
    readonly_fields = [
        'operation_type',
        'status',
        'user',
        'course',
        'request_data',
        'response_data',
        'error_message',
        'duration_ms',
        'records_processed',
        'created_at'
    ]
    date_hierarchy = 'created_at'

    def has_add_permission(self, request):
        """Don't allow manual log creation"""
        return False

    def has_change_permission(self, request, obj=None):
        """Don't allow log editing"""
        return False

    def user_link(self, obj):
        """Link to user if present"""
        if obj.user:
            url = reverse('admin:users_user_change', args=[obj.user.id])
            return format_html('<a href="{}">{}</a>', url, obj.user.email)
        return '-'
    user_link.short_description = 'User'

    def course_link(self, obj):
        """Link to course if present"""
        if obj.course:
            url = reverse('admin:aicerts_courses_aicertscourse_change', args=[obj.course.id])
            return format_html('<a href="{}">{}</a>', url, obj.course.title[:50])
        return '-'
    course_link.short_description = 'Course'

    def operation_badge(self, obj):
        """Color-coded operation type"""
        colors = {
            'course_sync': '#3498db',
            'user_create': '#2ecc71',
            'user_enroll': '#9b59b6',
            'user_auth': '#f39c12',
            'progress_update': '#1abc9c',
            'instructor_sync': '#e74c3c'
        }
        color = colors.get(obj.operation_type, '#95a5a6')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 3px;">{}</span>',
            color,
            obj.get_operation_type_display()
        )
    operation_badge.short_description = 'Operation'

    def status_badge(self, obj):
        """Color-coded status"""
        colors = {
            'success': 'green',
            'failed': 'red',
            'partial': 'orange'
        }
        color = colors.get(obj.status, 'gray')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; border-radius: 3px;">{}</span>',
            color,
            obj.get_status_display()
        )
    status_badge.short_description = 'Status'

    def duration_display(self, obj):
        """Format duration nicely"""
        if obj.duration_ms:
            if obj.duration_ms < 1000:
                return f"{obj.duration_ms}ms"
            return f"{obj.duration_ms / 1000:.2f}s"
        return '-'
    duration_display.short_description = 'Duration'


@admin.register(AICertsSSOSession)
class AICertsSSOSessionAdmin(admin.ModelAdmin):
    """Admin for SSO session tracking"""

    list_display = [
        'id',
        'user_link',
        'course_link',
        'successful_badge',
        'created_at',
        'expires_at',
        'expired_badge'
    ]
    list_filter = [
        'successful',
        ('created_at', admin.DateFieldListFilter),
        ('expires_at', admin.DateFieldListFilter)
    ]
    search_fields = [
        'user__email',
        'course__title',
        'session_token',
        'ip_address'
    ]
    readonly_fields = [
        'user',
        'course',
        'sso_url',
        'session_token',
        'ip_address',
        'user_agent',
        'successful',
        'accessed_at',
        'expires_at',
        'created_at',
        'updated_at'
    ]

    def has_add_permission(self, request):
        """Don't allow manual session creation"""
        return False

    def user_link(self, obj):
        """Link to user"""
        url = reverse('admin:users_user_change', args=[obj.user.id])
        return format_html('<a href="{}">{}</a>', url, obj.user.email)
    user_link.short_description = 'User'

    def course_link(self, obj):
        """Link to course if present"""
        if obj.course:
            url = reverse('admin:aicerts_courses_aicertscourse_change', args=[obj.course.id])
            return format_html('<a href="{}">{}</a>', url, obj.course.title[:50])
        return 'Dashboard'
    course_link.short_description = 'Target'

    def successful_badge(self, obj):
        """Success status badge"""
        if obj.successful:
            return format_html(
                '<span style="background-color: green; color: white; padding: 3px 10px; border-radius: 3px;">Success</span>'
            )
        return format_html(
            '<span style="background-color: orange; color: white; padding: 3px 10px; border-radius: 3px;">Pending</span>'
        )
    successful_badge.short_description = 'Status'

    def expired_badge(self, obj):
        """Expiry status badge"""
        if obj.is_expired:
            return format_html(
                '<span style="background-color: red; color: white; padding: 3px 10px; border-radius: 3px;">Expired</span>'
            )
        return format_html(
            '<span style="background-color: green; color: white; padding: 3px 10px; border-radius: 3px;">Valid</span>'
        )
    expired_badge.short_description = 'Expiry'
