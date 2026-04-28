# apps/analytics/admin.py
from django.contrib import admin
from django.utils.html import format_html
from django.db.models import Sum, Avg
from .models import PlatformAnalytics, CourseAnalytics, LearnershipAnalytics, UserProgress, ActivityLog


@admin.register(PlatformAnalytics)
class PlatformAnalyticsAdmin(admin.ModelAdmin):
    list_display = (
        'date',
        'colored_total_users',
        'colored_active_users',
        'colored_new_users',
        'page_views',
        'growth_badge',
    )
    list_filter = ('date',)
    date_hierarchy = 'date'
    ordering = ('-date',)
    readonly_fields = ('date',)

    def colored_total_users(self, obj):
        return format_html(
            '<span style="color: #2ecc71; font-weight: bold;">{:,}</span>',
            int(obj.total_users)  # force int to ensure numeric formatting works
        )
    colored_total_users.short_description = "Total Users"

    def colored_active_users(self, obj):
        return format_html(
            '<span style="color: #3498db; font-weight: bold;">{:,}</span>',
            int(obj.active_users)
        )
    colored_active_users.short_description = "Active Users"

    def colored_new_users(self, obj):
        return format_html(
            '<span style="color: #e67e22; font-weight: bold;">+{:,}</span>',
            int(obj.new_users)
        )
    colored_new_users.short_description = "New Users"

    def growth_badge(self, obj):
        if obj.new_users > 20:
            badge = '<span style="background:#27ae60;color:white;padding:4px 8px;border-radius:12px;">High Growth</span>'
        elif obj.new_users > 5:
            badge = '<span style="background:#f39c12;color:white;padding:4px 8px;border-radius:12px;">Growing</span>'
        else:
            badge = '<span style="background:#95a5a6;color:white;padding:4px 8px;border-radius:12px;">Stable</span>'
        return format_html(badge)
    growth_badge.short_description = "Growth"

    def has_add_permission(self, request):
        return False  # Data should come from jobs/cron, not manual


@admin.register(CourseAnalytics)
class CourseAnalyticsAdmin(admin.ModelAdmin):
    list_display = (
        'course_link',
        'date',
        'views',
        'enrollments',
        'completions',
        'colored_completion_rate',
    )
    list_filter = ('date', 'course')
    search_fields = ('course__title', 'course__shortname')
    date_hierarchy = 'date'
    ordering = ('-date',)

    def course_link(self, obj):
        return format_html(
            '<a href="/admin/aicerts_courses/aicertscourse/{}/change/">{}</a>',
            obj.course.id, obj.course.title
        )
    course_link.short_description = "Course"

    def colored_completion_rate(self, obj):
        if obj.enrollments == 0:
            rate = 0.0
        else:
            rate = round((obj.completions / obj.enrollments) * 100, 1)
        color = "#27ae60" if rate >= 70 else "#f39c12" if rate >= 40 else "#e74c3c"
        return format_html('<span style="color:{};font-weight:bold;">{:.1f}%</span>', color, rate)
    colored_completion_rate.short_description = "Completion %"


@admin.register(LearnershipAnalytics)
class LearnershipAnalyticsAdmin(admin.ModelAdmin):
    list_display = (
        'learnership_link',
        'date',
        'views',
        'enrollments',
        'completions',
        'colored_completion_rate',
    )
    list_filter = ('date', 'learnership')
    search_fields = ('learnership__title',)
    date_hierarchy = 'date'
    ordering = ('-date',)

    def learnership_link(self, obj):
        return format_html(
            '<a href="/admin/learnerships/learnership/{}/change/">{}</a>',
            obj.learnership.id, obj.learnership.title
        )
    learnership_link.short_description = "Learnership"

    def colored_completion_rate(self, obj):
        if obj.enrollments == 0:
            rate = 0.0
        else:
            rate = round((obj.completions / obj.enrollments) * 100, 1)
        color = "#27ae60" if rate >= 70 else "#f39c12" if rate >= 40 else "#e74c3c"
        return format_html('<span style="color:{};font-weight:bold;">{:.1f}%</span>', color, rate)
    colored_completion_rate.short_description = "Completion %"


@admin.register(UserProgress)
class UserProgressAdmin(admin.ModelAdmin):
    list_display = (
        'user_link',
        'course_or_learnership',
        'progress_bar',
        'last_accessed',
    )
    list_filter = ('course', 'learnership')
    search_fields = ('user__email', 'course__title', 'learnership__title')
    readonly_fields = ('last_accessed',)
    ordering = ('-last_accessed',)

    def user_link(self, obj):
        return format_html(
            '<a href="/admin/users/user/{}/change/">{}</a>',
            obj.user.id, obj.user.email
        )
    user_link.short_description = "User"

    def course_or_learnership(self, obj):
        if obj.course:
            return format_html('<span style="color:#3498db;">Course: {}</span>', obj.course.title)
        if obj.learnership:
            return format_html('<span style="color:#9b59b6;">Learnership: {}</span>', obj.learnership.title)
        return "-"
    course_or_learnership.short_description = "Item"

    def progress_bar(self, obj):
        percent = int(obj.progress_percentage)
        color = "#27ae60" if percent >= 80 else "#f39c12" if percent >= 40 else "#e74c3c"
        return format_html(
            '<div style="background:#eee;width:120px;height:12px;border-radius:6px;overflow:hidden;">'
            '<div style="background:{};width:{}%;height:100%;"></div>'
            '</div> {}%',
            color, percent, percent
        )
    progress_bar.short_description = "Progress"


@admin.register(ActivityLog)
class ActivityLogAdmin(admin.ModelAdmin):
    list_display = (
        'timestamp',
        'user_link',
        'colored_activity_type',
        'item_link',
        'ip_address',
    )
    list_filter = ('activity_type', 'timestamp')
    search_fields = ('user__email', 'course__title', 'learnership__title')
    date_hierarchy = 'timestamp'
    ordering = ('-timestamp',)
    readonly_fields = ('timestamp', 'ip_address', 'user_agent')

    def user_link(self, obj):
        if not obj.user:
            return "-"
        return format_html(
            '<a href="/admin/users/user/{}/change/">{}</a>',
            obj.user.id, obj.user.email
        )
    user_link.short_description = "User"

    def colored_activity_type(self, obj):
        colors = {
            'course_view': '#3498db',
            'course_enroll': '#27ae60',
            'course_complete': '#2ecc71',
            'learnership_view': '#9b59b6',
            'learnership_enroll': '#8e44ad',
            'learnership_complete': '#1abc9c',
            'login': '#f39c12',
            'search': '#95a5a6',
        }
        color = colors.get(obj.activity_type, '#7f8c8d')
        return format_html('<span style="color:{};">{}</span>', color, obj.get_activity_type_display())
    colored_activity_type.short_description = "Activity"

    def item_link(self, obj):
        if obj.course:
            return format_html(
                '<a href="/admin/aicerts_courses/aicertscourse/{}/change/">{}</a>',
                obj.course.id, obj.course.title
            )
        if obj.learnership:
            return format_html(
                '<a href="/admin/learnerships/learnership/{}/change/">{}</a>',
                obj.learnership.id, obj.learnership.title
            )
        return "-"
    item_link.short_description = "Item"