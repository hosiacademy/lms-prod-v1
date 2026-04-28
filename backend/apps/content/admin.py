# apps/content/admin.py

from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe

from .models import (
    Page, AboutPage, PrivacyPolicy,
    Testimonial, Sponsor, FrontPage
)


@admin.register(Page)
class PageAdmin(admin.ModelAdmin):
    """
    Custom static pages (e.g., Terms, FAQ, Contact).
    """
    list_display = ('title', 'slug', 'status_display', 'updated_at')
    list_filter = ('status',)
    search_fields = ('title', 'slug', 'heading', 'description')
    prepopulated_fields = {"slug": ("title",)}
    readonly_fields = ('created_at', 'updated_at', 'breadcumb_preview')

    fieldsets = (
        ("Page Content", {
            'fields': ('title', 'slug', 'heading', 'description')
        }),
        ("Media", {
            'fields': ('breadcumb_preview',),
        }),
        ("Status", {
            'fields': ('status',)
        }),
        ("Timestamps", {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    def breadcumb_preview(self, obj):
        if obj.breadcumb_image:
            return format_html('<img src="{}" style="max-height: 200px; border-radius: 8px;" />', obj.breadcumb_image)
        return "(no image)"
    breadcumb_preview.short_description = "Breadcrumb Banner"

    def status_display(self, obj):
        color = "#27ae60" if obj.status == 1 else "#95a5a6"
        text = "Published" if obj.status == 1 else "Draft"
        return format_html('<strong style="color: {};">{}</strong>', color, text)
    status_display.short_description = "Status"


@admin.register(AboutPage)
class AboutPageAdmin(admin.ModelAdmin):
    """
    Singleton About Us page – central to your Afro-centric story.
    """
    list_display = ('banner_title', 'who_we_are_preview', 'updated_at')
    readonly_fields = (
        'image1_preview', 'image2_preview', 'image3_preview',
        'image4_preview', 'created_at', 'updated_at'
    )

    # FIXED: Avoid querying non-existent table
    def has_add_permission(self, request):
        # Temporarily allow adding until the table is created
        # When you run migrations for content app, this can be restored
        return True

    def has_delete_permission(self, request, obj=None):
        return False

    fieldsets = (
        ("Vision & Mission", {
            'fields': ('banner_title', 'who_we_are'),
            'description': mark_safe(
                "<strong>Afro-centric Story:</strong><br>"
                "Tell the world why this LMS exists: to empower African minds, "
                "preserve indigenous knowledge, build local AI capacity, "
                "and create opportunities across the continent."
            )
        }),
        ("Our Journey", {
            'fields': ('story_title', 'story_description'),
        }),
        ("Community Impact", {
            'fields': ('teacher_title', 'teacher_details',
                       'course_title', 'course_details',
                       'student_title', 'student_details'),
        }),
        ("Visual Story", {
            'fields': ('image1_preview', 'image2_preview',
                       'image3_preview', 'image4_preview'),
            'description': "Use authentic African imagery: classrooms in Nairobi, "
                         "students in Lagos, innovators in Addis Ababa, etc."
        }),
        ("Timestamps", {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    def who_we_are_preview(self, obj):
        return (obj.who_we_are or "")[:60] + "..." if obj.who_we_are and len(obj.who_we_are) > 60 else obj.who_we_are or "(empty)"
    who_we_are_preview.short_description = "Who We Are"

    def image1_preview(self, obj):
        if hasattr(obj, 'image1') and obj.image1:
            return format_html('<img src="{}" style="max-width: 400px; border-radius: 8px;" />', obj.image1)
        return "No image"
    image1_preview.short_description = "Image 1"

    def image2_preview(self, obj):
        if hasattr(obj, 'image2') and obj.image2:
            return format_html('<img src="{}" style="max-width: 400px; border-radius: 8px;" />', obj.image2)
        return "No image"
    image2_preview.short_description = "Image 2"

    def image3_preview(self, obj):
        if hasattr(obj, 'image3') and obj.image3:
            return format_html('<img src="{}" style="max-width: 400px; border-radius: 8px;" />', obj.image3)
        return "No image"
    image3_preview.short_description = "Image 3"

    def image4_preview(self, obj):
        if hasattr(obj, 'image4') and obj.image4:
            return format_html('<img src="{}" style="max-width: 600px;" />', obj.image4)
        return "No image"
    image4_preview.short_description = "Background / Counter"


@admin.register(PrivacyPolicy)
class PrivacyPolicyAdmin(admin.ModelAdmin):
    """
    Privacy Policy – critical for trust, especially in African data contexts.
    """
    list_display = ('status_display', 'updated_by', 'updated_at')
    readonly_fields = ('created_by', 'updated_by', 'created_at', 'updated_at')

    def has_add_permission(self, request):
        # Temporarily allow until table exists
        return True

    fieldsets = (
        ("General Policy", {
            'fields': ('description', 'general'),
        }),
        ("Data Protection", {
            'fields': ('personal_data', 'voluntary_disclosure', 'children_privacy'),
        }),
        ("Cookies & Tracking", {
            'fields': ('information_about_cookies', 'thirt_party_adv', 'other_sites'),
        }),
        ("Community Specific", {
            'fields': ('teacher', 'student', 'business_transfer'),
            'description': mark_safe(
                "<strong>African Context:</strong> Emphasize respect for local data laws, "
                "cultural privacy norms, and commitment to keeping African data on the continent where possible."
            )
        }),
        ("Status & Audit", {
            'fields': ('status', 'created_by', 'updated_by', 'created_at', 'updated_at'),
        }),
    )

    def status_display(self, obj):
        color = "#27ae60" if obj.status == 1 else "#e74c3c"
        text = "Active" if obj.status == 1 else "Inactive"
        return format_html('<strong style="color: {};">{}</strong>', color, text)
    status_display.short_description = "Status"


@admin.register(Testimonial)
class TestimonialAdmin(admin.ModelAdmin):
    """
    Student & instructor success stories – powerful social proof.
    Prioritize authentic African voices.
    """
    list_display = ('author', 'profession', 'star_display', 'image_preview', 'status_display')
    list_filter = ('status', 'star')
    search_fields = ('author', 'profession', 'body')

    readonly_fields = ('created_by', 'updated_by', 'created_at', 'updated_at', 'image_full')

    fieldsets = (
        ("Testimonial", {
            'fields': ('body', 'author', 'profession', 'star')
        }),
        ("Media", {
            'fields': ('image_preview', 'image_full'),
        }),
        ("Status", {
            'fields': ('status', 'created_by', 'updated_by'),
        }),
        ("Timestamps", {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    def image_preview(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="max-height: 80px; border-radius: 50%;" />', obj.image)
        return "(no photo)"
    image_preview.short_description = "Photo"

    def image_full(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="max-width: 300px; border-radius: 12px;" />', obj.image)
        return "No image"
    image_full.short_description = "Full Photo"

    def star_display(self, obj):
        return "★" * (obj.star or 0)
    star_display.short_description = "Rating"

    def status_display(self, obj):
        color = "#27ae60" if obj.status == 1 else "#95a5a6"
        text = "Visible" if obj.status == 1 else "Hidden"
        return format_html('<strong style="color: {};">{}</strong>', color, text)
    status_display.short_description = "Status"


@admin.register(Sponsor)
class SponsorAdmin(admin.ModelAdmin):
    """
    Partners and sponsors – showcase African organizations, universities, tech hubs.
    """
    list_display = ('title', 'image_preview', 'status_display')
    list_filter = ('status',)
    search_fields = ('title',)

    readonly_fields = ('created_at', 'updated_at', 'image_full')

    fieldsets = (
        ("Sponsor Info", {
            'fields': ('title', 'status')
        }),
        ("Logo", {
            'fields': ('image_preview', 'image_full'),
        }),
        ("Timestamps", {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    def image_preview(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="max-height: 80px;" />', obj.image)
        return "(no logo)"
    image_preview.short_description = "Logo"

    def image_full(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="max-height: 200px;" />', obj.image)
        return "No logo"
    image_full.short_description = "Full Logo"

    def status_display(self, obj):
        return "Active" if obj.status else "Inactive"
    status_display.boolean = True
    status_display.short_description = "Visible"


@admin.register(FrontPage)
class FrontPageAdmin(admin.ModelAdmin):
    """
    Additional front-facing static pages (beyond homepage).
    """
    list_display = ('name', 'title', 'slug', 'status_display', 'is_static_display')
    list_filter = ('status', 'is_static')
    search_fields = ('name', 'title', 'slug', 'details')
    prepopulated_fields = {"slug": ("title",)}

    readonly_fields = ('created_at', 'updated_at', 'banner_preview')

    fieldsets = (
        ("Page Info", {
            'fields': ('name', 'title', 'sub_title', 'slug')
        }),
        ("Content", {
            'fields': ('details',)
        }),
        ("Media", {
            'fields': ('banner_preview',),
        }),
        ("Settings", {
            'fields': ('status', 'is_static'),
        }),
        ("Timestamps", {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    def banner_preview(self, obj):
        if obj.banner:
            return format_html('<img src="{}" style="max-width: 600px; border-radius: 8px;" />', obj.banner)
        return "(no banner)"
    banner_preview.short_description = "Banner"

    def status_display(self, obj):
        color = "#27ae60" if obj.status == 1 else "#95a5a6"
        return format_html('<strong style="color: {};">{}</strong>', color, "Active" if obj.status == 1 else "Inactive")
    status_display.short_description = "Status"

    def is_static_display(self, obj):
        return "Static" if obj.is_static == 1 else "Dynamic"
    is_static_display.short_description = "Type"