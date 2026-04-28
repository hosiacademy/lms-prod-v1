# apps/facilitators/admin.py

from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse, path
from django.http import HttpResponseRedirect
from django.contrib import messages
from django.shortcuts import render
from django.db.models import Count, Q, F, Avg
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from datetime import datetime, timedelta
import json

from .models import (
    Instructor, CourseAssignment, InstructorRating,
    InstructorActivityLog, PerformanceAppraisal, InstructorAnalytics
)
from apps.courses.models import Course
from apps.users.models import User


@admin.register(Instructor)
class InstructorAdmin(admin.ModelAdmin):
    list_display = [
        'instructor_id',
        'colored_name',
        'instructor_type',
        'department',
        'colored_performance',
        'current_course_count',
        'utilization_rate_display',
        'is_available',
        'is_active'
    ]
    
    list_filter = [
        'instructor_type',
        'department',
        'is_available',
        'is_active',
        'created_at'
    ]
    
    search_fields = [
        'instructor_id',
        'user__name',
        'user__username',
        'user__email',
        'employee_number',
        'department',
        'specialization'
    ]
    
    readonly_fields = [
        'instructor_id',
        'overall_rating',
        'performance_band',
        'total_courses_taught',
        'total_students_taught',
        'average_student_rating',
        'completion_rate',
        'current_course_count',
        'utilization_rate',
        'is_contract_valid',
        'performance_color_display',
        'created_at',
        'updated_at',
        'last_performance_review'
    ]
    
    fieldsets = [
        (_('Basic Information'), {
            'fields': [
                'user',
                'instructor_id',
                'instructor_type',
                ('employee_number', 'department'),
                'specialization'
            ]
        }),
        (_('Professional Information'), {
            'fields': [
                ('qualifications', 'years_experience'),
                ('date_hired', 'contract_expiry', 'is_contract_valid'),
                ('work_phone', 'work_email'),
                'office_location'
            ]
        }),
        (_('Availability'), {
            'fields': [
                ('is_available', 'is_active'),
                ('max_courses', 'current_course_count', 'utilization_rate'),
                'availability_notes',
            ]
        }),
        (_('Performance Metrics'), {
            'fields': [
                ('overall_rating', 'performance_band', 'performance_color_display'),
                ('average_student_rating', 'completion_rate'),
                ('total_courses_taught', 'total_students_taught'),
                'last_performance_review'
            ]
        }),
        (_('Administrative'), {
            'fields': [
                'notes',
                ('created_at', 'updated_at')
            ]
        }),
    ]
    
    actions = ['update_performance_metrics', 'mark_as_available', 'mark_as_unavailable']
    
    def colored_name(self, obj):
        return format_html(
            '<strong>{}</strong><br><small style="color:#666;">{}</small>',
            obj.user.name or obj.user.username,
            obj.user.email
        )
    colored_name.short_description = _('Facilitator')
    colored_name.admin_order_field = 'user__name'
    
    def colored_performance(self, obj):
        from django.conf import settings
        
        # Define performance colors
        performance_colors = {
            'excellent': '#10B981',  # Green
            'good': '#3B82F6',       # Blue
            'satisfactory': '#F59E0B',  # Amber
            'needs_improvement': '#EF4444',  # Red
            'poor': '#DC2626',       # Dark Red
        }
        
        # Get performance band or calculate from rating
        if hasattr(obj, 'performance_band') and obj.performance_band:
            band = obj.performance_band
        else:
            # Calculate band from rating
            if obj.overall_rating >= 90:
                band = 'excellent'
            elif obj.overall_rating >= 75:
                band = 'good'
            elif obj.overall_rating >= 60:
                band = 'satisfactory'
            elif obj.overall_rating >= 40:
                band = 'needs_improvement'
            else:
                band = 'poor'
        
        color = performance_colors.get(band, '#6B7280')
        
        # Get display text
        band_display = dict(Instructor.PERFORMANCE_RATINGS).get(band, band.title())
        
        return format_html(
            '<span style="color:{};font-weight:bold;">{} ({:.1f}%)</span>',
            color,
            band_display,
            obj.overall_rating
        )
    colored_performance.short_description = _('Performance')
    colored_performance.admin_order_field = 'overall_rating'
    
    def utilization_rate_display(self, obj):
        color = 'green' if obj.utilization_rate <= 80 else 'orange' if obj.utilization_rate <= 100 else 'red'
        return format_html(
            '<span style="color:{};font-weight:bold;">{:.1f}%</span>',
            color,
            obj.utilization_rate
        )
    utilization_rate_display.short_description = _('Utilization')
    utilization_rate_display.admin_order_field = 'utilization_rate'
    
    def performance_color_display(self, obj):
        from django.conf import settings
        
        # Define performance colors
        performance_colors = {
            'excellent': '#10B981',  # Green
            'good': '#3B82F6',       # Blue
            'satisfactory': '#F59E0B',  # Amber
            'needs_improvement': '#EF4444',  # Red
            'poor': '#DC2626',       # Dark Red
        }
        
        if hasattr(obj, 'performance_band') and obj.performance_band:
            color = performance_colors.get(obj.performance_band, '#6B7280')
        else:
            color = '#6B7280'
        
        return format_html(
            '<div style="width:20px;height:20px;background-color:{};border-radius:3px;"></div>',
            color
        )
    performance_color_display.short_description = _('Performance Color')
    
    def is_contract_valid(self, obj):
        """Check if contract is still valid."""
        if not obj.contract_expiry:
            return True
        return obj.contract_expiry >= timezone.now().date()
    is_contract_valid.boolean = True
    is_contract_valid.short_description = _('Contract Valid')
    
    def update_performance_metrics(self, request, queryset):
        for facilitator in queryset:
            try:
                # Simple performance calculation
                ratings = InstructorRating.objects.filter(facilitator=facilitator)
                if ratings.exists():
                    facilitator.average_student_rating = ratings.aggregate(avg=Avg('rating'))['avg']
                else:
                    facilitator.average_student_rating = 0.0
                
                # Update overall rating (simplified)
                facilitator.overall_rating = facilitator.average_student_rating * 20  # Convert 5-star to 100 scale
                
                # Determine performance band
                if facilitator.overall_rating >= 90:
                    facilitator.performance_band = 'excellent'
                elif facilitator.overall_rating >= 75:
                    facilitator.performance_band = 'good'
                elif facilitator.overall_rating >= 60:
                    facilitator.performance_band = 'satisfactory'
                elif facilitator.overall_rating >= 40:
                    facilitator.performance_band = 'needs_improvement'
                else:
                    facilitator.performance_band = 'poor'
                
                facilitator.save()
            except Exception as e:
                self.message_user(request, f"Error updating {facilitator}: {str(e)}", messages.ERROR)
        
        self.message_user(request, f"Updated performance metrics for {queryset.count()} facilitators.", messages.SUCCESS)
    update_performance_metrics.short_description = _("Update performance metrics for selected facilitators")
    
    def mark_as_available(self, request, queryset):
        updated = queryset.update(is_available=True)
        self.message_user(request, f"Marked {updated} facilitators as available.", messages.SUCCESS)
    mark_as_available.short_description = _("Mark selected as available")
    
    def mark_as_unavailable(self, request, queryset):
        updated = queryset.update(is_available=False)
        self.message_user(request, f"Marked {updated} facilitators as unavailable.", messages.SUCCESS)
    mark_as_unavailable.short_description = _("Mark selected as unavailable")
    
    def get_queryset(self, request):
        qs = super().get_queryset(request)
        # Prefetch related to optimize queries
        return qs.select_related('user')


@admin.register(CourseAssignment)
class CourseAssignmentAdmin(admin.ModelAdmin):
    list_display = [
        'assignment_id',
        'colored_facilitator',
        'colored_course',
        'status_display',
        'start_date',
        'expected_end_date',
        'duration_days_display',
        'assigned_by_display'
    ]
    
    list_filter = [
        'status',
        'assigned_date',
        'start_date',
        'instructor__instructor_type',
    ]
    
    search_fields = [
        'assignment_id',
        'facilitator__user__name',
        'facilitator__user__username',
        'course__title',
        'course__code'
    ]
    
    readonly_fields = [
        'assignment_id',
        'assigned_by',
        'assigned_date',
        'duration_days',
        'is_active',
        'created_at',
        'updated_at'
    ]
    
    fieldsets = [
        (_('Assignment Details'), {
            'fields': [
                'assignment_id',
                ('facilitator', 'course'),
                'status',
            ]
        }),
        (_('Timeline'), {
            'fields': [
                ('assigned_by', 'assigned_date'),
                ('start_date', 'expected_end_date', 'actual_end_date'),
                'duration_days'
            ]
        }),
        (_('Review & Notes'), {
            'fields': [
                'assignment_notes',
            ]
        }),
        (_('Metadata'), {
            'fields': [
                ('created_at', 'updated_at')
            ]
        }),
    ]
    
    actions = ['mark_as_completed', 'mark_as_ongoing']
    
    def colored_facilitator(self, obj):
        return format_html(
            '<strong>{}</strong><br><small>{}</small>',
            obj.facilitator.user.name or obj.facilitator.user.username,
            obj.facilitator.instructor_id
        )
    colored_facilitator.short_description = _('Facilitator')
    colored_facilitator.admin_order_field = 'facilitator__user__name'
    
    def colored_course(self, obj):
        return format_html(
            '<strong>{}</strong><br><small>{}</small>',
            obj.course.title,
            obj.course.code if hasattr(obj.course, 'code') else ''
        )
    colored_course.short_description = _('Course')
    colored_course.admin_order_field = 'course__title'
    
    def status_display(self, obj):
        colors = {
            'pending': '#F59E0B',  # Amber
            'assigned': '#3B82F6',  # Blue
            'ongoing': '#10B981',   # Green
            'completed': '#6B7280',  # Gray
            'cancelled': '#EF4444',  # Red
        }
        return format_html(
            '<span style="color:{};font-weight:bold;">{}</span>',
            colors.get(obj.status, '#6B7280'),
            obj.get_status_display()
        )
    status_display.short_description = _('Status')
    status_display.admin_order_field = 'status'
    
    def duration_days_display(self, obj):
        if obj.actual_end_date:
            days = (obj.actual_end_date - obj.start_date).days
        elif obj.expected_end_date:
            days = (obj.expected_end_date - obj.start_date).days
        else:
            days = 0
        
        if days > 0:
            return f"{days} days"
        return "-"
    duration_days_display.short_description = _('Duration')
    
    def assigned_by_display(self, obj):
        if obj.assigned_by:
            return obj.assigned_by.name or obj.assigned_by.username
        return "-"
    assigned_by_display.short_description = _('Assigned By')
    
    def mark_as_completed(self, request, queryset):
        updated = queryset.update(status='completed', actual_end_date=timezone.now().date())
        self.message_user(request, f"Marked {updated} assignments as completed.", messages.SUCCESS)
    mark_as_completed.short_description = _("Mark selected as completed")
    
    def mark_as_ongoing(self, request, queryset):
        updated = queryset.update(status='ongoing')
        self.message_user(request, f"Marked {updated} assignments as ongoing.", messages.SUCCESS)
    mark_as_ongoing.short_description = _("Mark selected as ongoing")
    
    def save_model(self, request, obj, form, change):
        if not obj.assigned_by:
            obj.assigned_by = request.user
        super().save_model(request, obj, form, change)
    
    def duration_days(self, obj):
        if obj.actual_end_date:
            return (obj.actual_end_date - obj.start_date).days
        elif obj.expected_end_date:
            return (obj.expected_end_date - obj.start_date).days
        return 0
    duration_days.short_description = _('Duration (days)')
    
    def is_active(self, obj):
        return obj.status in ['assigned', 'ongoing']
    is_active.boolean = True
    is_active.short_description = _('Active')


@admin.register(InstructorRating)
class InstructorRatingAdmin(admin.ModelAdmin):
    list_display = [
        'colored_facilitator',
        'colored_course',
        'colored_student',
        'colored_rating',
        'created_at'
    ]
    
    list_filter = [
        'instructor__instructor_type',
        'created_at'
    ]
    
    search_fields = [
        'facilitator__user__name',
        'facilitator__user__username',
        'course__title',
        'student__name',
        'student__username',
        'review'
    ]
    
    readonly_fields = ['created_at', 'updated_at']
    
    fieldsets = [
        (_('Rating Details'), {
            'fields': [
                ('facilitator', 'course', 'student'),
                'rating',
                'review',
            ]
        }),
        (_('Metadata'), {
            'fields': [
                ('created_at', 'updated_at')
            ]
        }),
    ]
    
    def colored_facilitator(self, obj):
        return format_html(
            '<strong>{}</strong>',
            obj.facilitator.user.name or obj.facilitator.user.username
        )
    colored_facilitator.short_description = _('Facilitator')
    colored_facilitator.admin_order_field = 'facilitator__user__name'
    
    def colored_course(self, obj):
        return format_html(
            '<strong>{}</strong>',
            obj.course.title
        )
    colored_course.short_description = _('Course')
    colored_course.admin_order_field = 'course__title'
    
    def colored_student(self, obj):
        return format_html(
            '<strong>{}</strong>',
            obj.student.name or obj.student.username
        )
    colored_student.short_description = _('Student')
    colored_student.admin_order_field = 'student__name'
    
    def colored_rating(self, obj):
        if obj.rating >= 4.0:
            color = '#10B981'  # Green
        elif obj.rating >= 3.0:
            color = '#F59E0B'  # Amber
        else:
            color = '#EF4444'  # Red
        
        stars = '★' * int(obj.rating) + '☆' * (5 - int(obj.rating))
        return format_html(
            '<span style="color:{};font-weight:bold;">{:.1f}</span> <span style="color:#F59E0B;">{}</span>',
            color,
            obj.rating,
            stars
        )
    colored_rating.short_description = _('Rating')
    colored_rating.admin_order_field = 'rating'


# Executive Dashboard Views
@admin.register(InstructorAnalytics)
class InstructorAnalyticsAdmin(admin.ModelAdmin):
    list_display = [
        'colored_facilitator',
        'period_display',
        'courses_completed',
        'total_students',
        'average_rating_display',
        'completion_rate_display',
        'is_current_display'
    ]
    
    list_filter = [
        'is_current',
        'period_end',
        'instructor__instructor_type'
    ]
    
    search_fields = [
        'facilitator__user__name',
        'facilitator__user__username',
        'facilitator__instructor_id'
    ]
    
    readonly_fields = [
        'calculated_at',
        'created_at',
        'updated_at'
    ]
    
    def colored_facilitator(self, obj):
        return format_html(
            '<strong>{}</strong><br><small>{}</small>',
            obj.facilitator.user.name or obj.facilitator.user.username,
            obj.facilitator.instructor_id
        )
    colored_facilitator.short_description = _('Facilitator')
    colored_facilitator.admin_order_field = 'facilitator__user__name'
    
    def period_display(self, obj):
        return format_html(
            '{} to {}',
            obj.period_start.strftime('%d %b %Y'),
            obj.period_end.strftime('%d %b %Y')
        )
    period_display.short_description = _('Period')
    
    def average_rating_display(self, obj):
        stars = '★' * int(obj.average_rating) + '☆' * (5 - int(obj.average_rating))
        color = '#10B981' if obj.average_rating >= 4.0 else '#F59E0B' if obj.average_rating >= 3.0 else '#EF4444'
        return format_html(
            '<span style="color:{};font-weight:bold;">{:.1f}</span> <span style="color:#F59E0B;">{}</span>',
            color,
            obj.average_rating,
            stars
        )
    average_rating_display.short_description = _('Rating')
    average_rating_display.admin_order_field = 'average_rating'
    
    def completion_rate_display(self, obj):
        color = '#10B981' if obj.completion_rate >= 70 else '#F59E0B' if obj.completion_rate >= 50 else '#EF4444'
        return format_html(
            '<span style="color:{};font-weight:bold;">{:.1f}%</span>',
            color,
            obj.completion_rate
        )
    completion_rate_display.short_description = _('Completion')
    completion_rate_display.admin_order_field = 'completion_rate'
    
    def is_current_display(self, obj):
        if obj.is_current:
            return format_html(
                '<span style="color:#10B981;font-weight:bold;">✓ Current</span>'
            )
        return format_html('<span style="color:#6B7280;">Historical</span>')
    is_current_display.short_description = _('Status')
    is_current_display.admin_order_field = 'is_current'


# Performance Appraisal Admin
@admin.register(PerformanceAppraisal)
class PerformanceAppraisalAdmin(admin.ModelAdmin):
    list_display = [
        'appraisal_id',
        'colored_facilitator',
        'appraisal_type_display',
        'colored_status',
        'appraisal_period',
        'overall_score_display',
        'scheduled_date',
        'is_overdue_display'
    ]
    
    list_filter = [
        'appraisal_type',
        'status',
        'appraisal_period_start',
        'appraisal_period_end'
    ]
    
    search_fields = [
        'appraisal_id',
        'facilitator__user__name',
        'facilitator__user__username',
        'strengths',
        'areas_for_improvement'
    ]
    
    def appraisal_type_display(self, obj):
        icons = {
            'quarterly': '📅',
            'mid_year': '📊',
            'annual': '🏆',
            'probation': '👁️',
            'promotion': '📈',
            'special': '⚠️',
        }
        return format_html(
            '{} {}',
            icons.get(obj.appraisal_type, '📋'),
            obj.get_appraisal_type_display()
        )
    appraisal_type_display.short_description = _('Type')
    appraisal_type_display.admin_order_field = 'appraisal_type'
    
    def colored_facilitator(self, obj):
        return format_html(
            '<strong>{}</strong><br><small>{}</small>',
            obj.facilitator.user.name or obj.facilitator.user.username,
            obj.facilitator.instructor_id
        )
    colored_facilitator.short_description = _('Facilitator')
    colored_facilitator.admin_order_field = 'facilitator__user__name'
    
    def colored_status(self, obj):
        colors = {
            'draft': '#6B7280',      # Gray
            'scheduled': '#3B82F6',   # Blue
            'in_progress': '#F59E0B', # Amber
            'completed': '#10B981',   # Green
            'archived': '#9CA3AF',    # Light Gray
        }
        return format_html(
            '<span style="color:{};font-weight:bold;">{}</span>',
            colors.get(obj.status, '#6B7280'),
            obj.get_status_display()
        )
    colored_status.short_description = _('Status')
    colored_status.admin_order_field = 'status'
    
    def appraisal_period(self, obj):
        return format_html(
            '{} to {}',
            obj.appraisal_period_start.strftime('%b %Y'),
            obj.appraisal_period_end.strftime('%b %Y')
        )
    appraisal_period.short_description = _('Period')
    
    def overall_score_display(self, obj):
        if obj.overall_score >= 90:
            color = '#10B981'  # Green
        elif obj.overall_score >= 75:
            color = '#3B82F6'  # Blue
        elif obj.overall_score >= 60:
            color = '#F59E0B'  # Amber
        elif obj.overall_score >= 40:
            color = '#EF4444'  # Red
        else:
            color = '#DC2626'  # Dark Red
        
        return format_html(
            '<span style="color:{};font-weight:bold;">{:.1f}</span>',
            color,
            obj.overall_score
        )
    overall_score_display.short_description = _('Score')
    overall_score_display.admin_order_field = 'overall_score'
    
    def is_overdue_display(self, obj):
        if obj.status in ['completed', 'archived']:
            return format_html('<span style="color:#10B981;">✓ Completed</span>')
        elif obj.scheduled_date < timezone.now().date():
            return format_html(
                '<span style="color:#EF4444;font-weight:bold;">⚠️ Overdue</span>'
            )
        return format_html('<span style="color:#10B981;">✓ On track</span>')
    is_overdue_display.short_description = _('Timeline')


# Activity Log Admin
@admin.register(InstructorActivityLog)
class InstructorActivityLogAdmin(admin.ModelAdmin):
    list_display = [
        'colored_facilitator',
        'activity_type_display',
        'description_preview',
        'duration_display',
        'activity_date',
        'is_verified'
    ]
    
    list_filter = [
        'activity_type',
        'is_verified',
        'activity_date',
        'instructor__instructor_type'
    ]
    
    search_fields = [
        'facilitator__user__name',
        'facilitator__user__username',
        'description',
        'course__title',
    ]
    
    def activity_type_display(self, obj):
        icons = {
            'course_creation': '📚',
            'content_upload': '📄',
            'assessment_created': '📝',
            'live_session': '🎥',
            'student_feedback': '💬',
            'grading': '✏️',
            'forum_participation': '💭',
            'announcement': '📢',
            'resource_shared': '📎',
            'meeting_attended': '👥',
            'training_completed': '🎓',
            'other': '📊',
        }
        return format_html(
            '{} {}',
            icons.get(obj.activity_type, '📋'),
            obj.get_activity_type_display()
        )
    activity_type_display.short_description = _('Activity Type')
    activity_type_display.admin_order_field = 'activity_type'
    
    def description_preview(self, obj):
        if len(obj.description) > 50:
            return f"{obj.description[:50]}..."
        return obj.description
    description_preview.short_description = _('Description')
    
    def colored_facilitator(self, obj):
        return format_html(
            '<strong>{}</strong><br><small>{}</small>',
            obj.facilitator.user.name or obj.facilitator.user.username,
            obj.facilitator.instructor_id
        )
    colored_facilitator.short_description = _('Facilitator')
    colored_facilitator.admin_order_field = 'facilitator__user__name'
    
    def duration_display(self, obj):
        if obj.duration_minutes < 60:
            return f"{obj.duration_minutes}m"
        hours = obj.duration_minutes / 60
        return f"{hours:.1f}h"
    duration_display.short_description = _('Duration')


# Custom Admin Views for Executive Dashboard
class InstructorAnalyticsAdminSite(admin.AdminSite):
    site_header = "Facilitators Analytics Executive Dashboard"
    site_title = "Facilitators Analytics"
    index_title = "Executive Dashboard"
    
    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('executive-dashboard/', self.admin_view(self.executive_dashboard), name='executive_dashboard'),
            path('performance-comparison/', self.admin_view(self.performance_comparison), name='performance_comparison'),
            path('assignment-tool/', self.admin_view(self.assignment_tool), name='assignment_tool'),
        ]
        return custom_urls + urls
    
    def executive_dashboard(self, request):
        """Executive dashboard view."""
        from django.db.models import Count, Avg
        
        # Get statistics
        total_facilitators = Instructor.objects.filter(is_active=True).count()
        active_facilitators = Instructor.objects.filter(is_active=True, is_available=True).count()
        
        # Get performance distribution
        performance_data = []
        for band, display in Instructor.PERFORMANCE_RATINGS:
            count = Instructor.objects.filter(
                is_active=True,
                performance_band=band
            ).count()
            performance_data.append({
                'band': display,
                'count': count,
                'percentage': (count / total_facilitators * 100) if total_facilitators > 0 else 0
            })
        
        # Get recent activities
        thirty_days_ago = datetime.now() - timedelta(days=30)
        recent_activities = InstructorActivityLog.objects.filter(
            activity_date__gte=thirty_days_ago
        ).select_related('facilitator', 'course').order_by('-activity_date')[:20]
        
        # Get top performers
        top_performers = Instructor.objects.filter(
            is_active=True,
            overall_rating__gt=0
        ).order_by('-overall_rating')[:10]
        
        # Get assignments statistics
        active_assignments = CourseAssignment.objects.filter(status__in=['assigned', 'ongoing']).count()
        completed_assignments = CourseAssignment.objects.filter(
            status='completed',
            actual_end_date__gte=datetime.now() - timedelta(days=30)
        ).count()
        
        context = {
            **self.each_context(request),
            'title': 'Executive Dashboard',
            'total_facilitators': total_facilitators,
            'active_facilitators': active_facilitators,
            'performance_data': performance_data,
            'recent_activities': recent_activities,
            'top_performers': top_performers,
            'active_assignments': active_assignments,
            'completed_assignments': completed_assignments,
            'opts': Instructor._meta,
        }
        
        return render(request, 'admin/facilitators/executive_dashboard.html', context)
    
    def performance_comparison(self, request):
        """Performance comparison view."""
        facilitators = Instructor.objects.filter(is_active=True).select_related('user')
        
        # Get comparison data
        comparison_data = []
        for facilitator in facilitators:
            assignments = CourseAssignment.objects.filter(facilitator=facilitator, status='completed')
            avg_rating = InstructorRating.objects.filter(facilitator=facilitator).aggregate(avg=Avg('rating'))['avg'] or 0
            
            comparison_data.append({
                'facilitator': facilitator,
                'total_courses': assignments.count(),
                'avg_rating': avg_rating,
                'utilization_rate': facilitator.utilization_rate,
                'performance_band': facilitator.performance_band,
            })
        
        # Sort by rating
        sort_by = request.GET.get('sort', 'avg_rating')
        reverse = request.GET.get('order', 'desc') == 'desc'
        
        if sort_by == 'avg_rating':
            comparison_data.sort(key=lambda x: x['avg_rating'], reverse=reverse)
        elif sort_by == 'total_courses':
            comparison_data.sort(key=lambda x: x['total_courses'], reverse=reverse)
        elif sort_by == 'utilization':
            comparison_data.sort(key=lambda x: x['utilization_rate'], reverse=reverse)
        
        context = {
            **self.each_context(request),
            'title': 'Performance Comparison',
            'comparison_data': comparison_data,
            'sort_by': sort_by,
            'order': 'asc' if not reverse else 'desc',
            'opts': Instructor._meta,
        }
        
        return render(request, 'admin/facilitators/performance_comparison.html', context)
    
    def assignment_tool(self, request):
        """Course assignment tool."""
        from apps.courses.models import Course
        
        # Get available courses (without active assignments)
        available_courses = Course.objects.filter(
            is_active=True
        ).exclude(
            facilitator_assignments__status__in=['assigned', 'ongoing']
        ).order_by('title')
        
        # Get available facilitators
        available_facilitators = Instructor.objects.filter(
            is_active=True,
            is_available=True
        ).annotate(
            current_count=Count('course_assignments', filter=Q(course_assignments__status__in=['assigned', 'ongoing']))
        ).filter(
            current_count__lt=F('max_courses')
        ).order_by('user__name')
        
        # Get recent assignments
        recent_assignments = CourseAssignment.objects.filter(
            assigned_date__gte=datetime.now() - timedelta(days=30)
        ).select_related('facilitator', 'course', 'assigned_by').order_by('-assigned_date')[:20]
        
        context = {
            **self.each_context(request),
            'title': 'Course Assignment Tool',
            'available_courses': available_courses,
            'available_facilitators': available_facilitators,
            'recent_assignments': recent_assignments,
            'opts': CourseAssignment._meta,
        }
        
        return render(request, 'admin/facilitators/assignment_tool.html', context)


# Register the custom admin site
facilitators_admin_site = InstructorAnalyticsAdminSite(name='facilitators_admin')

# Register models with the custom admin site
facilitators_admin_site.register(Instructor, InstructorAdmin)
facilitators_admin_site.register(CourseAssignment, CourseAssignmentAdmin)
facilitators_admin_site.register(InstructorRating, InstructorRatingAdmin)
facilitators_admin_site.register(InstructorActivityLog, InstructorActivityLogAdmin)
facilitators_admin_site.register(PerformanceAppraisal, PerformanceAppraisalAdmin)
facilitators_admin_site.register(InstructorAnalytics, InstructorAnalyticsAdmin)