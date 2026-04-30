# apps/masterclasses/admin.py
from django.contrib import admin
from django import forms
from django.utils.html import format_html
from django.utils import timezone
from django.db.models import Count, Sum, Q, Avg
from django.urls import path
from django.shortcuts import render
from datetime import datetime, timedelta
from .models import Masterclass, MasterclassEnrollment, AFRICAN_COUNTRIES
from apps.aicerts_courses.models import AiCertsCourse

# ==================== CUSTOM FORM ====================

class MasterclassAdminForm(forms.ModelForm):
    class Meta:
        model = Masterclass
        fields = '__all__'
        widgets = {
            'provider_courses': forms.SelectMultiple(attrs={'size': 10}),
            'description': forms.Textarea(attrs={'rows': 5}),
            'notes': forms.Textarea(attrs={'rows': 4}),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['provider_courses'].queryset = AiCertsCourse.objects.filter(
            is_offered=True
        ).order_by('title')

        if not self.instance.pk:
            self.initial.update({
                'status': 'scheduled',
                'currency': 'USD',
                'stream_type': 'professional',
                'tier': 'standard',
            })

# ==================== CUSTOM FILTERS ====================

class ScheduleStatusFilter(admin.SimpleListFilter):
    title = 'Schedule Status'
    parameter_name = 'schedule_status'

    def lookups(self, request, model_admin):
        return (
            ('future', 'Future / Scheduled'),
            ('current', 'Currently Ongoing'),
            ('past', 'Past / Completed'),
        )

    def queryset(self, request, queryset):
        today = timezone.now().date()
        if self.value() == 'future':
            return queryset.filter(start_date__gt=today, status='scheduled')
        if self.value() == 'current':
            return queryset.filter(
                Q(start_date__lte=today) & Q(end_date__gte=today),
                status__in=['scheduled', 'ongoing']
            )
        if self.value() == 'past':
            return queryset.filter(
                Q(end_date__lt=today) | Q(status__in=['completed', 'cancelled'])
            )
        return queryset

class StreamTypeFilter(admin.SimpleListFilter):
    title = 'Stream Type'
    parameter_name = 'stream_type'

    def lookups(self, request, model_admin):
        return Masterclass.STREAM_TYPE_CHOICES

    def queryset(self, request, queryset):
        if self.value():
            return queryset.filter(stream_type=self.value())
        return queryset

class TierFilter(admin.SimpleListFilter):
    title = 'Tier'
    parameter_name = 'tier'

    def lookups(self, request, model_admin):
        return Masterclass.TIER_CHOICES

    def queryset(self, request, queryset):
        if self.value():
            return queryset.filter(tier=self.value())
        return queryset

class CountryFilter(admin.SimpleListFilter):
    title = 'Country'
    parameter_name = 'country_code'

    def lookups(self, request, model_admin):
        # Get countries that have masterclasses
        countries = Masterclass.objects.exclude(
            country_code__isnull=True
        ).values_list(
            'country_code', 'country_name'
        ).distinct().order_by('country_name')
        
        return [(code, name) for code, name in countries if code and name]

    def queryset(self, request, queryset):
        if self.value():
            return queryset.filter(country_code=self.value())
        return queryset

# ==================== MAIN ADMIN ====================

@admin.register(Masterclass)
class MasterclassAdmin(admin.ModelAdmin):
    form = MasterclassAdminForm
    
    list_display = [
        'title_link',
        'status_badge',
        'stream_type_badge',
        'tier_badge',
        'date_range',
        'location_display',
        'courses_count_badge',
        'category_badge',
        'focus_area_short',
        'price_display',
        'participants_progress',
        'duration_display',
        'is_featured_icon',
    ]
    
    list_filter = [
        'status',
        ScheduleStatusFilter,
        StreamTypeFilter,
        TierFilter,
        CountryFilter,
        'is_featured',
        'start_date',
    ]
    
    search_fields = [
        'title',
        'slug',
        'description',
        'category',
        'focus_area',
        'city',
        'venue',
        'country_name',
        'provider_courses__title',
    ]
    
    date_hierarchy = 'start_date'
    list_per_page = 25
    list_select_related = True
    
    fieldsets = (
        ('Basic Information', {
            'fields': ('title', 'slug', 'description', 'category'),
        }),
        ('Frontend Filtering', {
            'fields': ('stream_type', 'tier', 'focus_area'),
            'description': 'Fields used for frontend filtering and categorization'
        }),
        ('Location Information', {
            'fields': ('country_code', 'country_name', 'city', 'venue'),
            'description': 'Specific location details for the masterclass'
        }),
        ('Linked AiCerts Courses', {
            'fields': ('provider_courses',),
            'description': 'Select one or more offered AiCerts courses. Category will auto-update on save.'
        }),
        ('Schedule & Status', {
            'fields': ('start_date', 'end_date', 'status', 'is_featured'),
        }),
        ('Pricing & Capacity', {
            'fields': ('price', 'currency', 'max_participants', 'current_participants'),
        }),
        ('Additional Information', {
            'fields': ('notes', 'locations'),
            'description': 'Notes and legacy locations field (auto-populated)',
            'classes': ('collapse',),
        }),
        ('Timestamps (Read-only)', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )
    
    readonly_fields = ('created_at', 'updated_at', 'category')
    
    # Display methods
    def title_link(self, obj):
        url = f"/admin/masterclasses/masterclass/{obj.pk}/change/"
        return format_html('<a href="{}">{}</a>', url, obj.title[:50] + '...' if len(obj.title) > 50 else obj.title)
    title_link.short_description = "Title"

    def status_badge(self, obj):
        colors = {
            'scheduled': '#007bff',
            'ongoing': '#28a745',
            'completed': '#6c757d',
            'cancelled': '#dc3545',
        }
        color = colors.get(obj.status, '#6c757d')
        return format_html(
            '<span style="background-color:{}; color:white; padding:4px 10px; border-radius:12px; font-weight:bold; font-size:11px;">{}</span>',
            color, obj.get_status_display()[:3].upper()
        )
    status_badge.short_description = "Status"

    def stream_type_badge(self, obj):
        colors = {
            'professional': '#4e73df',
            'technical': '#1cc88a',
        }
        color = colors.get(obj.stream_type, '#6c757d')
        return format_html(
            '<span style="background-color:{}; color:white; padding:4px 8px; border-radius:12px; font-size:11px;">{}</span>',
            color, obj.get_stream_type_display()[:3].upper()
        )
    stream_type_badge.short_description = "Stream"

    def tier_badge(self, obj):
        colors = {
            'basic': '#858796',
            'standard': '#36b9cc',
            'premium': '#f6c23e',
        }
        color = colors.get(obj.tier or 'standard', '#6c757d')
        return format_html(
            '<span style="background-color:{}; color:{}; padding:4px 8px; border-radius:12px; font-size:11px;">{}</span>',
            color, '#000' if obj.tier == 'premium' else 'white', 
            obj.get_tier_display() if obj.tier else '—'
        )
    tier_badge.short_description = "Tier"

    def date_range(self, obj):
        if obj.start_date and obj.end_date:
            return f"{obj.start_date.strftime('%d %b')} → {obj.end_date.strftime('%d %b %Y')}"
        return "—"
    date_range.short_description = "Dates"

    def location_display(self, obj):
        if obj.city and obj.country_name:
            return f"{obj.city}, {obj.country_name}"
        elif obj.country_name:
            return obj.country_name
        return "—"
    location_display.short_description = "Location"

    def courses_count_badge(self, obj):
        count = obj.provider_courses.count()
        if count == 0:
            return format_html('<span style="color:#dc3545; font-size:11px;">None</span>')
        return format_html(
            '<span style="background:#6f42c1; color:white; padding:3px 6px; border-radius:12px; font-size:11px;">{}</span>',
            count
        )
    courses_count_badge.short_description = "Courses"

    def category_badge(self, obj):
        if not obj.category:
            return "—"
        return format_html(
            '<span style="background:#17a2b8; color:white; padding:3px 6px; border-radius:12px; font-size:11px;">{}</span>',
            obj.category[:20] + '...' if len(obj.category) > 20 else obj.category
        )
    category_badge.short_description = "Category"

    def focus_area_short(self, obj):
        if not obj.focus_area:
            return "—"
        return obj.focus_area[:25] + '...' if len(obj.focus_area) > 25 else obj.focus_area
    focus_area_short.short_description = "Focus Area"

    def price_display(self, obj):
        return f"{obj.currency} {obj.price:,.0f}" if obj.price else "—"
    price_display.short_description = "Price"

    def participants_progress(self, obj):
        if obj.max_participants == 0:
            return "—"
        percent = int((obj.current_participants / obj.max_participants) * 100)
        color = '#dc3545' if percent >= 100 else '#28a745'
        return format_html(
            '<span style="color:{}; font-size:11px;">{}/{} ({}%)</span>',
            color, obj.current_participants, obj.max_participants, percent
        )
    participants_progress.short_description = "Participants"

    def duration_display(self, obj):
        days = obj.duration_days
        if days is None:
            return "—"
        return f"{days}d"
    duration_display.short_description = "Dur"

    def is_featured_icon(self, obj):
        return format_html('⭐') if obj.is_featured else ''
    is_featured_icon.short_description = "⭐"

    # Bulk actions
    actions = [
        'mark_featured',
        'mark_not_featured',
        'mark_completed',
        'mark_cancelled',
        'mark_as_professional',
        'mark_as_technical',
        'duplicate_selected',
    ]

    def mark_featured(self, request, queryset):
        queryset.update(is_featured=True)
        self.message_user(request, f"{queryset.count()} marked as featured.")
    mark_featured.short_description = "Mark as Featured"

    def mark_not_featured(self, request, queryset):
        queryset.update(is_featured=False)
        self.message_user(request, f"{queryset.count()} removed from featured.")
    mark_not_featured.short_description = "Remove Featured"

    def mark_completed(self, request, queryset):
        queryset.update(status='completed')
        self.message_user(request, f"{queryset.count()} marked as completed.")
    mark_completed.short_description = "Mark as Completed"

    def mark_cancelled(self, request, queryset):
        queryset.update(status='cancelled')
        self.message_user(request, f"{queryset.count()} marked as cancelled.")
    mark_cancelled.short_description = "Mark as Cancelled"

    def mark_as_professional(self, request, queryset):
        queryset.update(stream_type='professional')
        self.message_user(request, f"{queryset.count()} marked as professional stream.")
    mark_as_professional.short_description = "Mark as Professional"

    def mark_as_technical(self, request, queryset):
        queryset.update(stream_type='technical')
        self.message_user(request, f"{queryset.count()} marked as technical stream.")
    mark_as_technical.short_description = "Mark as Technical"

    def duplicate_selected(self, request, queryset):
        count = 0
        for obj in queryset:
            obj.pk = None
            obj.slug = f"{obj.slug}-copy-{timezone.now().strftime('%Y%m%d%H%M')}"
            obj.title = f"{obj.title} (Copy)"
            obj.status = 'scheduled'
            obj.current_participants = 0
            obj.save()
            obj.provider_courses.set(obj.provider_courses.all())
            count += 1
        self.message_user(request, f"{count} duplicated successfully.")
    duplicate_selected.short_description = "Duplicate Selected"

    # Custom save to handle country_name auto-population
    def save_model(self, request, obj, form, change):
        # Auto-populate country_name from country_code if not set
        if obj.country_code and not obj.country_name:
            country_dict = dict(AFRICAN_COUNTRIES)
            obj.country_name = country_dict.get(obj.country_code, obj.country_code)
        super().save_model(request, obj, form, change)

@admin.register(MasterclassEnrollment)
class MasterclassEnrollmentAdmin(admin.ModelAdmin):
    list_display = [
        'user_email',
        'masterclass_title',
        'status_badge',
        'payment_status_badge',
        'attendance_type',
        'amount_paid',
        'created_at',
    ]
    
    list_filter = [
        'status',
        'payment_status',
        'attendance_type',
        'created_at',
    ]
    
    search_fields = [
        'user__email',
        'user__first_name',
        'user__last_name',
        'masterclass__title',
    ]
    
    raw_id_fields = ('user', 'masterclass', 'payment_transaction')
    
    def user_email(self, obj):
        return obj.user.email
    user_email.short_description = "User"
    
    def masterclass_title(self, obj):
        return obj.masterclass.title
    masterclass_title.short_description = "Masterclass"
    
    def status_badge(self, obj):
        colors = {
            'pending': '#ffc107',
            'enrolled': '#28a745',
            'completed': '#6c757d',
            'cancelled': '#dc3545',
        }
        color = colors.get(obj.status, '#6c757d')
        return format_html(
            '<span style="background-color:{}; color:white; padding:4px 8px; border-radius:12px; font-weight:bold; font-size:10px;">{}</span>',
            color, obj.status.upper()
        )
    status_badge.short_description = "Status"
    
    def payment_status_badge(self, obj):
        colors = {
            'pending': '#ffc107',
            'paid': '#28a745',
            'refunded': '#17a2b8',
            'failed': '#dc3545',
        }
        color = colors.get(obj.payment_status, '#6c757d')
        return format_html(
            '<span style="background-color:{}; color:white; padding:4px 8px; border-radius:12px; font-weight:bold; font-size:10px;">{}</span>',
            color, obj.payment_status.upper()
        )
    payment_status_badge.short_description = "Payment"

# ==================== COMPLETED MASTERCLASSES ADMIN ====================

class CompletedMasterclassAdmin(MasterclassAdmin):
    def get_queryset(self, request):
        return super().get_queryset(request).filter(status='completed')

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

# ==================== ANALYTICS ADMIN SITE ====================

class MasterclassAnalyticsAdmin(admin.AdminSite):
    site_header = "Masterclasses Analytics Dashboard"
    site_title = "Masterclasses Analytics"
    index_title = "Analytics Overview"

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path('', self.admin_view(self.analytics_view), name='analytics'),
        ]
        return custom_urls + urls

    def analytics_view(self, request):
        today = timezone.now().date()

        # Basic counts
        total_masterclasses = Masterclass.objects.count()
        scheduled_masterclasses = Masterclass.objects.filter(status='scheduled', start_date__gt=today).count()
        ongoing_masterclasses = Masterclass.objects.filter(
            Q(start_date__lte=today) & Q(end_date__gte=today),
            status__in=['scheduled', 'ongoing']
        ).count()
        completed_masterclasses = Masterclass.objects.filter(status='completed').count()
        
        # New field analytics
        stream_type_counts = Masterclass.objects.values('stream_type').annotate(
            count=Count('id')
        ).order_by('-count')
        
        tier_counts = Masterclass.objects.values('tier').annotate(
            count=Count('id')
        ).order_by('-count')
        
        country_counts = Masterclass.objects.exclude(country_code__isnull=True).values(
            'country_name'
        ).annotate(
            count=Count('id')
        ).order_by('-count')[:10]
        
        focus_area_counts = Masterclass.objects.exclude(focus_area__isnull=True).values(
            'focus_area'
        ).annotate(
            count=Count('id')
        ).order_by('-count')[:10]

        # Revenue calculations
        total_revenue = Masterclass.objects.aggregate(
            total=Sum('price' * 'current_participants')
        )['total'] or 0

        avg_price = Masterclass.objects.aggregate(avg=Avg('price'))['avg'] or 0
        avg_participation = Masterclass.objects.aggregate(avg=Avg('current_participants'))['avg'] or 0

        # Monthly trends
        twelve_months_ago = today - timedelta(days=365)
        monthly_data = Masterclass.objects.filter(
            created_at__gte=twelve_months_ago
        ).extra({
            'month': "date_trunc('month', created_at)"
        }).values('month').annotate(
            count=Count('id'),
            participants=Sum('current_participants'),
            revenue=Sum('price' * 'current_participants')
        ).order_by('month')

        # Top performing
        top_masterclasses = Masterclass.objects.order_by('-current_participants')[:10]

        # Course usage analytics
        course_usage = AiCertsCourse.objects.annotate(
            masterclass_count=Count('masterclasses'),
            total_participants=Sum('masterclasses__current_participants')
        ).filter(masterclass_count__gt=0).order_by('-masterclass_count')[:10]

        # Categories analytics
        categories_data = Masterclass.objects.values('category').annotate(
            count=Count('id'),
            participants=Sum('current_participants')
        ).order_by('-count')[:10]

        context = {
            'total_masterclasses': total_masterclasses,
            'scheduled_masterclasses': scheduled_masterclasses,
            'ongoing_masterclasses': ongoing_masterclasses,
            'completed_masterclasses': completed_masterclasses,
            'stream_type_counts': list(stream_type_counts),
            'tier_counts': list(tier_counts),
            'country_counts': list(country_counts),
            'focus_area_counts': list(focus_area_counts),
            'total_revenue': total_revenue,
            'avg_price': avg_price,
            'avg_participation': avg_participation,
            'monthly_data': list(monthly_data),
            'top_masterclasses': top_masterclasses,
            'course_usage': course_usage,
            'categories_data': list(categories_data),
            'today': today,
        }

        return render(request, 'admin/masterclasses/analytics.html', context)

# Create analytics site instance
analytics_site = MasterclassAnalyticsAdmin(name='masterclasses_analytics')

# ==================== COMPLETED SITE ====================

completed_site = admin.AdminSite(name='completed_masterclasses')
completed_site.site_header = "Completed Masterclasses"
completed_site.site_title = "Completed Masterclasses"
completed_site.index_title = "Historical Masterclasses"
completed_site.register(Masterclass, CompletedMasterclassAdmin)

# ==================== EXPORT FOR urls.py ====================
__all__ = ['analytics_site', 'completed_site']