# apps/aicerts_courses/admin.py

from django.contrib import admin
from django.utils.html import format_html, mark_safe
from django import forms
import json
from django.utils import timezone
from .models import AiCertsCourse  # ONLY THIS


# =========================
# AiCertsCourse Admin Form
# =========================

class AiCertsCourseAdminForm(forms.ModelForm):
    class Meta:
        model = AiCertsCourse
        fields = '__all__'
        widgets = {
            'summary': forms.Textarea(attrs={'rows': 4, 'cols': 80}),
            'description': forms.Textarea(attrs={'rows': 8, 'cols': 80}),
            'category_name': forms.Textarea(attrs={'rows': 2, 'cols': 80}),
            'raw_data': forms.Textarea(attrs={'rows': 10, 'cols': 80}),
        }


# =========================
# AiCertsCourse Admin
# =========================

@admin.register(AiCertsCourse)
class AiCertsCourseAdmin(admin.ModelAdmin):
    form = AiCertsCourseAdminForm

    list_display = (
        'external_id',
        'title_truncated',
        'provider',
        'categories_display',
        'offering_status',
        'price_display',
        'package_display',
        'certificate_badge_preview',
        'last_synced',
    )

    list_filter = (
        'provider',
        'is_offered',
        'is_in_package',
        'is_self_paced',
        'category_name',
        'last_synced',
    )

    search_fields = (
        'title',
        'shortname',
        'summary',
        'description',
        'category_name',
        'external_id',
        'package_name',
    )

    fieldsets = (
        ('Course Information (From API)', {
            'fields': (
                'provider',
                'external_id',
                'title',
                'shortname',
                'description',
                'summary',
                'category_name',
                'certificate_badge_url',
                'feature_image_url',
                'lms_course_id',
                'raw_data_preview',
            ),
            'description': 'These fields are synced from AICERTs public API (v1.1)'
        }),
        ('Hosi Academy Offering & Pricing', {
            'fields': (
                'is_offered',
                'is_self_paced',
                'price_individual',
                'is_in_package',
                'package_name',
                'price_package',
            ),
            'description': 'Control offering status and override/set pricing locally'
        }),
        ('System Information', {
            'fields': (
                'last_synced',
                'created_at',
                'updated_at',
            ),
            'classes': ('collapse',)
        }),
    )

    readonly_fields = (
        'provider', 'external_id', 'title', 'shortname', 'summary', 'description',
        'category_name', 'certificate_badge_url', 'feature_image_url',
        'lms_course_id', 'raw_data_preview', 'last_synced', 'created_at', 'updated_at'
    )

    ordering = ('-last_synced',)
    date_hierarchy = 'last_synced'
    list_per_page = 50

    # -----------------------------
    # Custom display methods
    # -----------------------------
    def title_truncated(self, obj):
        return obj.title[:70] + '...' if len(obj.title) > 70 else obj.title
    title_truncated.short_description = "Course Title"
    title_truncated.admin_order_field = 'title'

    def categories_display(self, obj):
        if obj.category_name:
            cats = [cat.strip() for cat in obj.category_name.split(',')]
            return ', '.join(cats[:3]) + ('...' if len(cats) > 3 else '')
        return "-"
    categories_display.short_description = "Categories"

    def offering_status(self, obj):
        if obj.is_offered:
            return format_html(
                '<span style="color:green;font-weight:bold;">✓ OFFERED</span>'
            )
        return format_html(
            '<span style="color:#666;">Not Offered</span>'
        )
    offering_status.short_description = "Status"
    offering_status.admin_order_field = 'is_offered'

    def price_display(self, obj):
        if obj.price_individual:
            return format_html(
                '<span style="color:blue;font-weight:bold;">${:,.2f}</span>',
                obj.price_individual
            )
        return "-"
    price_display.short_description = "Individual Price"

    def package_display(self, obj):
        if obj.is_in_package:
            return format_html(
                '<span style="color:purple;">{} (${:,.2f})</span>',
                obj.package_name or "Package",
                obj.price_package or 0
            )
        return "-"
    package_display.short_description = "Package"

    def certificate_badge_preview(self, obj):
        if obj.certificate_badge_url:
            return format_html(
                '<img src="{}" style="max-height:40px;" alt="Badge" />',
                obj.certificate_badge_url
            )
        return "-"
    certificate_badge_preview.short_description = "Badge"

    def raw_data_preview(self, obj):
        if not obj.raw_data:
            return "-"
        try:
            pretty = json.dumps(obj.raw_data, indent=2, ensure_ascii=False)
            return mark_safe(
                f'<pre style="font-size:0.9em; background:#f8f9fa; padding:12px; border-radius:6px; '
                f'max-height:350px; overflow:auto; white-space:pre-wrap; font-family:monospace;">{pretty}</pre>'
            )
        except Exception:
            return "Invalid data preview"
    raw_data_preview.short_description = "API Raw Data (JSON)"

    # -----------------------------
    # Bulk actions
    # -----------------------------
    actions = ['mark_as_offered', 'mark_as_not_offered']

    def mark_as_offered(self, request, queryset):
        updated = queryset.update(is_offered=True)
        self.message_user(request, f"{updated} courses marked as OFFERED")
    mark_as_offered.short_description = "Mark selected as OFFERED"

    def mark_as_not_offered(self, request, queryset):
        updated = queryset.update(is_offered=False)
        self.message_user(request, f"{updated} courses marked as NOT offered")
    mark_as_not_offered.short_description = "Mark selected as NOT offered"