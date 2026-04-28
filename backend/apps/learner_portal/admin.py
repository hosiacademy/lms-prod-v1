# apps/learner_portal/admin.py
from django.contrib import admin
from django.utils.html import format_html
from django.template.response import TemplateResponse
from django.http import HttpResponseRedirect
from django.utils import timezone
from django.db.models import Count, Q, Avg
from django.urls import path
from .models import (
    StudentProfile,
    Wishlist,
    CourseCart,
    CourseCartItem,
    CourseProvider,
    CourseCatalogItem
)


@admin.register(StudentProfile)
class StudentProfileAdmin(admin.ModelAdmin):
    list_display = [
        'user_email',
        'total_enrollments',
        'active_enrollments',
        'completed_enrollments',
        'has_company_history',
        'preferred_country',
        'preferred_payment_provider',
    ]

    list_filter = [
        'has_company_payment_history',
        'preferred_country',
        'preferred_payment_provider',
        'created_at',
    ]

    search_fields = [
        'user__email',
        'user__first_name',
        'user__last_name',
        'last_used_company_name',
    ]

    readonly_fields = [
        'created_at',
        'updated_at',
        'total_enrollments',
        'active_enrollments',
        'completed_enrollments',
    ]

    fieldsets = (
        ('User Information', {
            'fields': ('user',)
        }),
        ('Company Payment History', {
            'fields': (
                'has_company_payment_history',
                'last_used_company_name',
                'last_used_company_email',
                'last_used_company_phone',
                'last_used_company_address',
                'last_used_vat_number',
            ),
            'description': 'Previous company details for quick reuse'
        }),
        ('Location Preferences', {
            'fields': (
                'preferred_country',
                'preferred_state',
                'preferred_city',
            )
        }),
        ('Payment Preferences', {
            'fields': (
                'preferred_payment_provider',
                'preferred_payment_method',
            )
        }),
        ('Enrollment Statistics', {
            'fields': (
                'total_enrollments',
                'active_enrollments',
                'completed_enrollments',
            )
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at')
        }),
    )

    def user_email(self, obj):
        return obj.user.email
    user_email.short_description = 'Email'

    def has_company_history(self, obj):
        if obj.has_company_payment_history:
            return format_html('<span style="color: green;">✓ Yes</span>')
        return format_html('<span style="color: gray;">✗ No</span>')
    has_company_history.short_description = 'Company History'


@admin.register(Wishlist)
class WishlistAdmin(admin.ModelAdmin):
    """
    Admin interface for Marketing team to view and follow up on wishlist leads.
    """
    list_display = [
        'user_email',
        'training_type_badge',
        'interest_level_badge',
        'intended_start_badge',
        'marketing_status',
        'conversion_status',
        'days_in_wishlist',
        'created_at',
    ]

    list_filter = [
        'training_type',
        'interest_level',
        'intended_start',
        'marketing_contacted',
        'converted_to_cart',
        'converted_to_enrollment',
        'created_at',
    ]

    search_fields = [
        'user__email',
        'user__first_name',
        'user__last_name',
        'marketing_notes',
    ]

    readonly_fields = [
        'created_at',
        'updated_at',
        'converted_to_cart_at',
        'converted_to_enrollment_at',
        'marketing_contacted_at',
    ]

    actions = [
        'mark_as_contacted',
        'mark_as_high_priority',
        'export_leads_for_follow_up',
    ]

    fieldsets = (
        ('Learner & Course', {
            'fields': (
                'user',
                'training_type',
                'content_type',
                'object_id',
            )
        }),
        ('Interest Details', {
            'fields': (
                'interest_level',
                'intended_start',
                'notes',
            )
        }),
        ('Marketing Follow-up', {
            'fields': (
                'marketing_contacted',
                'marketing_contacted_at',
                'contacted_by',
                'marketing_notes',
            ),
            'classes': ('wide',),
            'description': 'Track marketing team follow-up on this lead'
        }),
        ('Conversion Tracking', {
            'fields': (
                'converted_to_cart',
                'converted_to_cart_at',
                'converted_to_enrollment',
                'converted_to_enrollment_at',
            )
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at')
        }),
    )

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path(
                'marketing-dashboard/',
                self.admin_site.admin_view(self.marketing_dashboard_view),
                name='wishlist_marketing_dashboard',
            ),
        ]
        return custom_urls + urls

    def marketing_dashboard_view(self, request):
        """Custom dashboard for marketing team"""
        # Get statistics
        total_leads = Wishlist.objects.count()
        uncontacted = Wishlist.objects.filter(marketing_contacted=False).count()
        high_priority = Wishlist.objects.filter(
            interest_level='high',
            marketing_contacted=False
        ).count()

        conversion_rate = 0
        if total_leads > 0:
            converted = Wishlist.objects.filter(converted_to_enrollment=True).count()
            conversion_rate = (converted / total_leads) * 100

        # Get leads by training type
        leads_by_type = Wishlist.objects.values('training_type').annotate(
            count=Count('id'),
            uncontacted=Count('id', filter=Q(marketing_contacted=False))
        )

        # Get leads by intended start
        leads_by_timeline = Wishlist.objects.values('intended_start').annotate(
            count=Count('id')
        )

        # Recent high-priority leads
        high_priority_leads = Wishlist.objects.filter(
            interest_level='high',
            marketing_contacted=False
        ).select_related('user')[:20]

        context = {
            **self.admin_site.each_context(request),
            'total_leads': total_leads,
            'uncontacted': uncontacted,
            'high_priority': high_priority,
            'conversion_rate': round(conversion_rate, 2),
            'leads_by_type': leads_by_type,
            'leads_by_timeline': leads_by_timeline,
            'high_priority_leads': high_priority_leads,
            'opts': self.model._meta,
        }

        return TemplateResponse(
            request,
            'admin/learner_portal/wishlist_marketing_dashboard.html',
            context
        )

    def user_email(self, obj):
        return obj.user.email
    user_email.short_description = 'Learner Email'

    def training_type_badge(self, obj):
        colors = {
            'masterclass': '#2196F3',
            'learnership': '#FF9800',
            'industry_training': '#4CAF50',
            'custom_selection': '#9C27B0',
        }
        color = colors.get(obj.training_type, '#757575')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-size: 11px; font-weight: bold;">{}</span>',
            color,
            obj.get_training_type_display()
        )
    training_type_badge.short_description = 'Type'

    def interest_level_badge(self, obj):
        colors = {
            'high': '#F44336',
            'medium': '#FF9800',
            'low': '#9E9E9E',
        }
        icons = {
            'high': '🔥',
            'medium': '⭐',
            'low': '👀',
        }
        color = colors.get(obj.interest_level, '#757575')
        icon = icons.get(obj.interest_level, '')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-size: 11px;">{} {}</span>',
            color,
            icon,
            obj.get_interest_level_display()
        )
    interest_level_badge.short_description = 'Interest'

    def intended_start_badge(self, obj):
        colors = {
            'immediate': '#F44336',
            'short_term': '#FF9800',
            'medium_term': '#4CAF50',
            'long_term': '#2196F3',
            'undecided': '#9E9E9E',
        }
        color = colors.get(obj.intended_start, '#757575')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-size: 11px;">{}</span>',
            color,
            obj.get_intended_start_display()
        )
    intended_start_badge.short_description = 'Timeline'

    def marketing_status(self, obj):
        if obj.marketing_contacted:
            return format_html(
                '<span style="color: green; font-weight: bold;">✓ Contacted</span><br>'
                '<small>{}</small>',
                obj.marketing_contacted_at.strftime('%Y-%m-%d') if obj.marketing_contacted_at else ''
            )
        return format_html('<span style="color: orange; font-weight: bold;">⚠ Pending</span>')
    marketing_status.short_description = 'Marketing Status'

    def conversion_status(self, obj):
        if obj.converted_to_enrollment:
            return format_html('<span style="color: green;">✓ Enrolled</span>')
        elif obj.converted_to_cart:
            return format_html('<span style="color: blue;">🛒 In Cart</span>')
        return format_html('<span style="color: gray;">- Wishlist</span>')
    conversion_status.short_description = 'Conversion'

    def days_in_wishlist(self, obj):
        delta = timezone.now() - obj.created_at
        days = delta.days

        if days == 0:
            return 'Today'
        elif days == 1:
            return '1 day'
        elif days >= 30:
            return format_html('<span style="color: red; font-weight: bold;">{} days</span>', days)
        elif days >= 14:
            return format_html('<span style="color: orange;">{} days</span>', days)
        return f'{days} days'
    days_in_wishlist.short_description = 'Days in Wishlist'

    @admin.action(description='Mark as contacted by marketing')
    def mark_as_contacted(self, request, queryset):
        """Mark selected leads as contacted"""
        if 'apply' in request.POST:
            notes = request.POST.get('marketing_notes', '')

            for item in queryset.filter(marketing_contacted=False):
                item.mark_marketing_contacted(request.user, notes)

            self.message_user(request, f"Marked {queryset.count()} leads as contacted")
            return HttpResponseRedirect(request.get_full_path())

        # Show form
        context = {
            **self.admin_site.each_context(request),
            'leads': queryset.filter(marketing_contacted=False),
            'action': 'mark_as_contacted',
            'opts': self.model._meta,
        }
        return TemplateResponse(
            request,
            'admin/learner_portal/mark_contacted_form.html',
            context
        )

    @admin.action(description='Mark as high priority')
    def mark_as_high_priority(self, request, queryset):
        """Set selected items to high interest level"""
        updated = queryset.update(interest_level='high')
        self.message_user(request, f"Marked {updated} items as high priority")

    @admin.action(description='Export leads for follow-up (CSV)')
    def export_leads_for_follow_up(self, request, queryset):
        """Export wishlist leads as CSV for marketing team"""
        import csv
        from django.http import HttpResponse

        response = HttpResponse(content_type='text/csv')
        response['Content-Disposition'] = 'attachment; filename="wishlist_leads.csv"'

        writer = csv.writer(response)
        writer.writerow([
            'Email', 'Name', 'Training Type', 'Interest Level',
            'Intended Start', 'Days in Wishlist', 'Marketing Contacted',
            'Contact Date', 'Notes'
        ])

        for item in queryset.select_related('user'):
            writer.writerow([
                item.user.email,
                item.user.get_full_name() or '',
                item.get_training_type_display(),
                item.get_interest_level_display(),
                item.get_intended_start_display(),
                (timezone.now() - item.created_at).days,
                'Yes' if item.marketing_contacted else 'No',
                item.marketing_contacted_at.strftime('%Y-%m-%d') if item.marketing_contacted_at else '',
                item.marketing_notes or '',
            ])

        return response


@admin.register(CourseCart)
class CourseCartAdmin(admin.ModelAdmin):
    """
    Admin interface for monitoring course carts and conversion.
    """
    list_display = [
        'cart_id',
        'user_email',
        'status_badge',
        'total_courses',
        'total_amount_display',
        'is_corporate_badge',
        'days_since_update',
        'created_at',
    ]

    list_filter = [
        'status',
        'is_active',
        'is_corporate_enrollment',
        'use_previous_company_details',
        'created_at',
        'updated_at',
    ]

    search_fields = [
        'user__email',
        'user__first_name',
        'user__last_name',
    ]

    readonly_fields = [
        'total_courses',
        'total_amount',
        'created_at',
        'updated_at',
        'checkout_started_at',
        'completed_at',
        'abandoned_at',
    ]

    actions = [
        'mark_as_abandoned',
        'send_cart_reminder',
    ]

    def cart_id(self, obj):
        return f"#{obj.id}"
    cart_id.short_description = 'Cart ID'

    def user_email(self, obj):
        return obj.user.email
    user_email.short_description = 'Learner'

    def status_badge(self, obj):
        colors = {
            'active': '#4CAF50',
            'checkout': '#2196F3',
            'completed': '#4CAF50',
            'abandoned': '#F44336',
        }
        color = colors.get(obj.status, '#757575')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-size: 11px; font-weight: bold;">{}</span>',
            color,
            obj.get_status_display()
        )
    status_badge.short_description = 'Status'

    def total_amount_display(self, obj):
        return f"{obj.total_amount} {obj.currency}"
    total_amount_display.short_description = 'Total'

    def is_corporate_badge(self, obj):
        if obj.is_corporate_enrollment:
            return format_html('<span style="color: blue;">🏢 Corporate</span>')
        return format_html('<span style="color: gray;">👤 Individual</span>')
    is_corporate_badge.short_description = 'Type'

    def days_since_update(self, obj):
        delta = timezone.now() - obj.updated_at
        days = delta.days

        if days == 0:
            return 'Today'
        elif obj.status == 'active' and days >= 7:
            return format_html('<span style="color: red; font-weight: bold;">{} days ago</span>', days)
        elif obj.status == 'active' and days >= 3:
            return format_html('<span style="color: orange;">{} days ago</span>', days)
        return f'{days} days ago'
    days_since_update.short_description = 'Last Updated'

    @admin.action(description='Mark as abandoned')
    def mark_as_abandoned(self, request, queryset):
        """Mark selected carts as abandoned"""
        updated = 0
        for cart in queryset.filter(status='active'):
            cart.mark_abandoned()
            updated += 1
        self.message_user(request, f"Marked {updated} carts as abandoned")

    @admin.action(description='Send cart reminder email')
    def send_cart_reminder(self, request, queryset):
        """Send reminder email to users with abandoned carts"""
        # TODO: Implement email sending
        count = queryset.filter(status='active').count()
        self.message_user(
            request,
            f"Would send reminder to {count} users (email integration pending)"
        )


@admin.register(CourseCartItem)
class CourseCartItemAdmin(admin.ModelAdmin):
    list_display = [
        'cart_id',
        'user_email',
        'training_type',
        'price_display',
        'prerequisites_badge',
        'added_from_wishlist',
        'created_at',
    ]

    list_filter = [
        'training_type',
        'prerequisites_met',
        'added_from_wishlist',
        'created_at',
    ]

    search_fields = [
        'cart__user__email',
        'title',  # If you add title field
    ]

    def cart_id(self, obj):
        return f"#{obj.cart.id}"
    cart_id.short_description = 'Cart'

    def user_email(self, obj):
        return obj.cart.user.email
    user_email.short_description = 'Learner'

    def price_display(self, obj):
        return f"{obj.price} {obj.currency}"
    price_display.short_description = 'Price'

    def prerequisites_badge(self, obj):
        if obj.prerequisites_met:
            return format_html('<span style="color: green;">✓ Met</span>')
        return format_html(
            '<span style="color: red; font-weight: bold;">✗ Not Met</span>'
        )
    prerequisites_badge.short_description = 'Prerequisites'


@admin.register(CourseProvider)
class CourseProviderAdmin(admin.ModelAdmin):
    """
    Admin interface for managing course providers.
    Only active providers appear in custom enrollment catalog.
    """
    list_display = [
        'name',
        'code',
        'is_active_badge',
        'display_order',
        'active_courses_count',
        'created_at',
    ]

    list_filter = [
        'is_active',
        'created_at',
    ]

    search_fields = [
        'name',
        'code',
        'description',
    ]

    readonly_fields = ['created_at', 'updated_at']

    fieldsets = (
        ('Basic Information', {
            'fields': (
                'name',
                'code',
                'description',
                'website',
                'logo',
            )
        }),
        ('Integration', {
            'fields': (
                'api_url',
                'api_key',
            ),
            'classes': ('collapse',),
        }),
        ('Display Settings', {
            'fields': (
                'is_active',
                'display_order',
            ),
            'description': 'Only active providers appear in custom enrollment catalog'
        }),
        ('Metadata', {
            'fields': ('created_at', 'updated_at')
        }),
    )

    def is_active_badge(self, obj):
        if obj.is_active:
            return format_html(
                '<span style="color: green; font-weight: bold;">✓ Active</span>'
            )
        return format_html(
            '<span style="color: red;">✗ Inactive</span>'
        )
    is_active_badge.short_description = 'Status'


@admin.register(CourseCatalogItem)
class CourseCatalogItemAdmin(admin.ModelAdmin):
    """
    Admin interface for the unified course catalog.
    """
    list_display = [
        'title',
        'training_type_badge',
        'provider',
        'price_display',
        'is_active_badge',
        'is_featured_badge',
        'total_enrollments',
        'total_wishlist_adds',
    ]

    list_filter = [
        'training_type',
        'provider',
        'is_active',
        'is_featured',
        'created_at',
    ]

    search_fields = [
        'title',
        'description',
    ]

    readonly_fields = [
        'total_enrollments',
        'total_wishlist_adds',
        'created_at',
        'updated_at',
    ]

    actions = [
        'mark_as_featured',
        'mark_as_active',
        'mark_as_inactive',
    ]

    def training_type_badge(self, obj):
        colors = {
            'masterclass': '#2196F3',
            'learnership': '#FF9800',
            'industry_training': '#4CAF50',
            'custom_selection': '#9C27B0',
        }
        color = colors.get(obj.training_type, '#757575')
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 3px; font-size: 11px;">{}</span>',
            color,
            obj.get_training_type_display()
        )
    training_type_badge.short_description = 'Type'

    def price_display(self, obj):
        return f"{obj.price} {obj.currency}"
    price_display.short_description = 'Price'

    def is_active_badge(self, obj):
        if obj.is_active:
            return format_html('<span style="color: green;">✓</span>')
        return format_html('<span style="color: red;">✗</span>')
    is_active_badge.short_description = 'Active'

    def is_featured_badge(self, obj):
        if obj.is_featured:
            return format_html('<span style="color: gold;">⭐</span>')
        return ''
    is_featured_badge.short_description = 'Featured'

    @admin.action(description='Mark as featured')
    def mark_as_featured(self, request, queryset):
        updated = queryset.update(is_featured=True)
        self.message_user(request, f"Marked {updated} courses as featured")

    @admin.action(description='Mark as active')
    def mark_as_active(self, request, queryset):
        updated = queryset.update(is_active=True)
        self.message_user(request, f"Activated {updated} courses")

    @admin.action(description='Mark as inactive')
    def mark_as_inactive(self, request, queryset):
        updated = queryset.update(is_active=False)
        self.message_user(request, f"Deactivated {updated} courses")
