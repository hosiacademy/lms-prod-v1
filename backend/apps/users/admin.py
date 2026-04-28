# apps/users/admin.py

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _
from django.utils.html import format_html

from .models import User  # Only import the existing User model


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """
    Custom admin for the real Infix LMS User model (mapped to existing 'users' table).
    Fully supports existing data + AiCerts sync fields.
    """
    # Main detail view
    fieldsets = (
        (None, {
            'fields': ('username', 'password')
        }),
        (_('Personal Info'), {
            'fields': (
                'name', 'email', 'phone', 'headline',
                'address', 'city', 'country', 'zip', 'dob', 'about'
            )
        }),
        (_('Profile Images'), {
            'fields': ('image_preview', 'avatar_preview', 'photo_preview'),
            'classes': ('collapse',),
        }),
        (_('Social Links'), {
            'fields': ('facebook', 'twitter', 'linkedin', 'instagram', 'youtube'),
            'classes': ('collapse',),
        }),
        (_('Instructor & Financial'), {
            'fields': (
                'role_id', 'balance', 'currency_id', 'special_commission',
                'payout', 'payout_icon', 'payout_email',
                'bank_name', 'branch_name', 'bank_account_number',
                'account_holder_name', 'bank_type'
            ),
            'description': 'Visible if user is an instructor (role_id ≈ 2)'
        }),
        (_('AiCerts / SSO Sync'), {
            'fields': ('partner_id', 'source', 'provider', 'provider_id'),
            'classes': ('collapse',),
            'description': 'Fields populated during AiCerts/Moodle sync'
        }),
        (_('Zoom Integration'), {
            'fields': ('zoom_api_key_of_user', 'zoom_api_serect_of_user'),
            'classes': ('collapse',),
        }),
        (_('Permissions'), {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions'),
        }),
        (_('Important dates'), {
            'fields': ('last_login', 'date_joined'),
        }),
    )

    # Add form (for creating new users)
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('username', 'email', 'name', 'password1', 'password2'),
        }),
        (_('Personal Info'), {
            'fields': ('phone', 'headline', 'about'),
        }),
        (_('Instructor Settings (Optional)'), {
            'fields': ('role_id', 'payout_email'),
            'description': 'Set role_id=2 for instructors'
        }),
    )

    list_display = (
        'username', 'name', 'email', 'role_display', 'balance',
        'is_active', 'is_staff', 'date_joined', 'source_link'
    )
    list_filter = (
        'is_staff', 'is_superuser', 'is_active',
        'role_id', 'source', 'provider'
    )
    search_fields = (
        'username', 'name', 'email', 'phone',
        'headline', 'payout_email', 'provider_id'
    )
    ordering = ('-date_joined',)
    readonly_fields = (
        'image_preview', 'avatar_preview', 'photo_preview',
        'balance', 'date_joined', 'last_login'
    )
    filter_horizontal = ('groups', 'user_permissions',)
    autocomplete_fields = ('groups',)

    def role_display(self, obj):
        role_map = {1: 'Admin', 2: 'Instructor', 3: 'Student'}
        return role_map.get(obj.role_id, f"Role {obj.role_id}")
    role_display.short_description = "Role"

    def source_link(self, obj):
        if obj.source or obj.provider:
            return format_html('<code>{} ({})</code>', obj.source or 'local', obj.provider or '')
        return "Local"
    source_link.short_description = "Source"

    # Image previews
    def image_preview(self, obj):
        if obj.image:
            return format_html('<img src="{}" style="max-height: 200px; border-radius: 8px;" />', obj.image)
        return "(no main image)"
    image_preview.short_description = "Main Profile Image"

    def avatar_preview(self, obj):
        if obj.avatar:
            return format_html('<img src="{}" style="max-height: 150px; border-radius: 50%;" />', obj.avatar)
        return "(no avatar)"
    avatar_preview.short_description = "Avatar"

    def photo_preview(self, obj):
        if obj.photo:
            return format_html('<img src="{}" style="max-height: 150px;" />', obj.photo)
        return "(no photo)"
    photo_preview.short_description = "Photo"

    def get_queryset(self, request):
        return super().get_queryset(request).select_related()