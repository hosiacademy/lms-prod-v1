# apps/frontend_manage/admin.py

from django.contrib import admin
from django.utils.html import format_html
from django.utils.safestring import mark_safe
from django.utils.translation import gettext_lazy as _
from django.contrib import messages
from django.http import HttpResponseRedirect
from django.urls import path, reverse

from .models import (
    FrontendSetting, HomeContent, GeneralSetting,
    Theme, LoginPage, AppAppearance, ThemePreset
)


@admin.register(FrontendSetting)
class FrontendSettingAdmin(admin.ModelAdmin):
    """
    Admin for individual frontend sections (e.g., hero, features, CTA).
    Used to customize homepage blocks.
    """
    list_display = ('section', 'title', 'status_display', 'icon_preview', 'url')
    list_filter = ('status',)
    search_fields = ('section', 'title', 'description')
    ordering = ('section',)

    readonly_fields = ('created_at', 'updated_at')

    fieldsets = (
        ("Section Details", {
            'fields': ('section', 'title', 'description', 'btn_name', 'btn_link')
        }),
        ("Media & Links", {
            'fields': ('url', 'icon_preview'),
        }),
        ("Status", {
            'fields': ('status',)
        }),
        ("Timestamps", {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    def icon_preview(self, obj):
        if obj.icon:
            return format_html('<i class="{}" style="font-size: 2em;"></i>', obj.icon)
        return "(no icon)"
    icon_preview.short_description = "Icon"

    def status_display(self, obj):
        color = "#27ae60" if obj.status == 1 else "#95a5a6"
        text = "Active" if obj.status == 1 else "Disabled"
        return format_html('<strong style="color: {};">{}</strong>', color, text)
    status_display.short_description = "Status"


@admin.register(HomeContent)
class HomeContentAdmin(admin.ModelAdmin):
    """
    Admin for global homepage content (sliders, testimonials, key messages).
    Central place for Afro-centric branding and messaging.
    """
    list_display = ('slider_title', 'testimonial_title', 'active_status_display', 'updated_by')
    list_filter = ('active_status',)
    search_fields = ('slider_title', 'testimonial_title', 'category_title')

    readonly_fields = ('created_at', 'updated_at', 'created_by', 'updated_by')

    fieldsets = (
        ("Hero & Slider", {
            'fields': ('slider_title', 'slider_text', 'slider_banner'),
            'description': mark_safe(
                "<strong>Afro-centric Tip:</strong> Use imagery and messages celebrating African innovation, "
                "education, and unity. Highlight local success stories."
            )
        }),
        ("Key Sections", {
            'fields': (
                'category_title', 'category_sub_title',
                'instructor_title', 'instructor_sub_title',
                'course_title', 'course_sub_title',
                'best_category_title', 'best_category_sub_title',
                'quiz_title', 'testimonial_title', 'testimonial_sub_title'
            )
        }),
        ("Banners & Logos", {
            'fields': (
                'instructor_banner', 'best_category_banner',
                'course_page_banner', 'class_page_banner', 'quiz_page_banner',
                'instructor_page_banner', 'contact_page_banner', 'about_page_banner',
                'become_instructor_logo', 'subscribe_logo'
            ),
        }),
        ("Call to Action & Pages", {
            'fields': (
                'become_instructor_title', 'become_instructor_sub_title',
                'subscribe_title', 'subscribe_sub_title'
            ),
        }),
        ("Key Features", {
            'fields': (
                'show_key_feature', 'key_feature_title1', 'key_feature_subtitle1', 'key_feature_logo1',
                'key_feature_title2', 'key_feature_subtitle2', 'key_feature_logo2',
                'key_feature_title3', 'key_feature_subtitle3', 'key_feature_logo3'
            ),
            'classes': ('collapse',),
        }),
        ("Status & Metadata", {
            'fields': ('active_status', 'created_by', 'updated_by', 'created_at', 'updated_at'),
        }),
    )

    def active_status_display(self, obj):
        color = "#27ae60" if obj.active_status == 1 else "#e74c3c"
        text = "Live" if obj.active_status == 1 else "Draft"
        return format_html('<strong style="color: {};">{}</strong>', color, text)
    active_status_display.short_description = "Homepage Status"


@admin.register(GeneralSetting)
class GeneralSettingAdmin(admin.ModelAdmin):
    """
    Global site settings – site title, logo, colors, social links, etc.
    Central hub for Afro-centric branding.
    """
    list_display = ('site_title', 'phone', 'email', 'currency_symbol', 'template_id')
    search_fields = ('site_title', 'email', 'phone')

    def has_add_permission(self, request):
        # Usually only one instance – prevent multiple adds
        return GeneralSetting.objects.count() == 0

    def has_delete_permission(self, request, obj=None):
        return False

    fieldsets = (
        ("Branding", {
            'fields': ('site_title', 'logo', 'logo2', 'favicon', 'copyright_text'),
            'description': mark_safe(
                "<strong>Afro-centric Branding:</strong> Use Pan-African colors (green, gold, red, black), "
                "African patterns, or symbols of unity and knowledge."
            )
        }),
        ("Contact & Location", {
            'fields': ('phone', 'email', 'address', 'city', 'state', 'zip_code'),
        }),
        ("Social & Links", {
            'fields': ('fb', 'twitter', 'youtube', 'linkedin'),
        }),
        ("Currency & Commission", {
            'fields': ('currency_id', 'commission'),
        }),
        ("Appearance", {
            'fields': ('template_id', 'ttl_rtl'),
            'classes': ('collapse',),
        }),
        ("Advanced", {
            'fields': ('recapthca', 'recaptcha_key', 'recaptcha_secret', 'gmap_key'),
            'classes': ('collapse',),
        }),
    )

    def currency_symbol(self, obj):
        # Placeholder — replace with real lookup when ready
        return "$"
    currency_symbol.short_description = "Currency"


@admin.register(Theme)
class ThemeAdmin(admin.ModelAdmin):
    """
    Theme management – custom LMS themes/templates.
    Encourage Afro-centric design themes.
    """
    list_display = ('name', 'title', 'version', 'is_active', 'is_active_display', 'status_display', 'activate_button')
    list_filter = ('is_active', 'status')
    search_fields = ('name', 'title', 'description', 'tags')
    # REMOVE: list_editable = ('is_active',)  # This causes the error
    actions = ['activate_selected_themes', 'deactivate_selected_themes']

    readonly_fields = ('created_at', 'updated_at', 'preview_theme')

    fieldsets = (
        ("Theme Info", {
            'fields': ('name', 'title', 'image', 'version', 'folder_path', 'live_link'),
        }),
        ("Description & Tags", {
            'fields': ('description', 'tags'),
        }),
        ("Appearance Preview", {
            'fields': ('preview_theme',),
            'classes': ('collapse',),
        }),
        ("Status", {
            'fields': ('is_active', 'status'),
        }),
        ("Timestamps", {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    def is_active_display(self, obj):
        return "Active" if obj.is_active else "Inactive"
    is_active_display.boolean = True
    is_active_display.short_description = "Active Theme"

    def status_display(self, obj):
        color = "#27ae60" if obj.status else "#95a5a6"
        text = "Published" if obj.status else "Draft"
        return format_html('<strong style="color: {};">{}</strong>', color, text)
    status_display.short_description = "Status"

    def activate_button(self, obj):
        if not obj.is_active:
            url = reverse('admin:activate-theme', args=[obj.id])
            return format_html(
                '<a class="button" href="{}" style="background-color: #27ae60; color: white; padding: 5px 10px; text-decoration: none; border-radius: 3px;">Activate</a>',
                url
            )
        return format_html('<span style="color: #27ae60;">✓ Active</span>')
    activate_button.short_description = "Actions"

    def preview_theme(self, obj):
        return format_html(
            '<div style="border: 1px solid #ddd; padding: 15px; margin: 10px 0; border-radius: 8px;">'
            '<h4 style="margin-top: 0;">Theme Preview</h4>'
            '<p><strong>Name:</strong> {}</p>'
            '<p><strong>Version:</strong> {}</p>'
            '<p><strong>Description:</strong> {}</p>'
            '<p><strong>Live Demo:</strong> <a href="{}" target="_blank">{}</a></p>'
            '</div>',
            obj.title or obj.name,
            obj.version,
            obj.description or "No description provided",
            obj.live_link or "#",
            obj.live_link or "No link"
        )
    preview_theme.short_description = "Theme Preview"

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path(
                '<int:theme_id>/activate/',
                self.admin_site.admin_view(self.activate_theme_view),
                name='activate-theme',
            ),
        ]
        return custom_urls + urls

    def activate_theme_view(self, request, theme_id):
        try:
            theme = Theme.objects.get(id=theme_id)
            # Deactivate all other themes
            Theme.objects.filter(is_active=True).update(is_active=False)
            # Activate selected theme
            theme.is_active = True
            theme.save()
            
            messages.success(
                request, 
                f'Theme "{theme.name}" has been activated. All other themes have been deactivated.'
            )
        except Theme.DoesNotExist:
            messages.error(request, 'Theme not found.')
        
        return HttpResponseRedirect(reverse('admin:frontend_manage_theme_changelist'))

    def activate_selected_themes(self, request, queryset):
        # Deactivate all themes first
        Theme.objects.filter(is_active=True).update(is_active=False)
        # Activate selected themes
        count = queryset.update(is_active=True)
        self.message_user(
            request, 
            f'Successfully activated {count} theme(s). Only one theme should be active at a time.',
            messages.WARNING if count > 1 else messages.SUCCESS
        )
    activate_selected_themes.short_description = "Activate selected themes"

    def deactivate_selected_themes(self, request, queryset):
        count = queryset.update(is_active=False)
        self.message_user(request, f'Successfully deactivated {count} theme(s).')
    deactivate_selected_themes.short_description = "Deactivate selected themes"

    def save_model(self, request, obj, form, change):
        # Ensure only one active theme at a time
        if obj.is_active:
            Theme.objects.filter(is_active=True).exclude(id=obj.id).update(is_active=False)
        super().save_model(request, obj, form, change)


@admin.register(ThemePreset)
class ThemePresetAdmin(admin.ModelAdmin):
    """
    WordPress theme preset management for quick theme switching.
    """
    list_display = ('name', 'preset_type_display', 'color_preview', 'is_active', 
                    'is_recommended', 'apply_preset_button', 'sort_order')
    list_filter = ('preset_type', 'is_active', 'is_recommended')
    search_fields = ('name', 'description')
    list_editable = ('sort_order', 'is_recommended')
    ordering = ('sort_order', 'name')
    actions = ['activate_presets', 'deactivate_presets', 'mark_as_recommended', 'apply_to_global_appearance']
    
    readonly_fields = ('created_at', 'updated_at', 'theme_preview', 'design_tokens_preview')
    
    fieldsets = (
        ("Preset Information", {
            'fields': ('name', 'preset_type', 'description', 
                      'thumbnail_url', 'sort_order'),
        }),
        ("WordPress Color Scheme", {
            'fields': ('primary_color', 'primary_variant', 'secondary_color',
                      'accent_color', 'background_color', 'text_primary'),
            'description': mark_safe(
                "<strong>WordPress Color Palette:</strong> Use the official WordPress color presets "
                "for consistent design across platforms."
            )
        }),
        ("Design Tokens", {
            'fields': ('shadow_type', 'spacing_scale', 'font_size'),
            'classes': ('collapse',),
        }),
        ("Status", {
            'fields': ('is_active', 'is_recommended'),
        }),
        ("Theme Preview", {
            'fields': ('theme_preview', 'design_tokens_preview'),
            'classes': ('collapse',),
        }),
        ("Timestamps", {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )
    
    def preset_type_display(self, obj):
        type_map = {
            'wp_default': 'WordPress Default',
            'wp_vivid': 'WordPress Vivid',
            'wp_pastel': 'WordPress Pastel',
            'wp_dark': 'WordPress Dark',
            'wp_professional': 'WordPress Professional',
            'wp_energetic': 'WordPress Energetic',
            'wp_nature': 'WordPress Nature',
            'custom': 'Custom',
        }
        return type_map.get(obj.preset_type, obj.preset_type)
    preset_type_display.short_description = "Preset Type"
    
    def color_preview(self, obj):
        return format_html(
            '<div style="display: flex; gap: 3px; align-items: center;">'
            '<div style="width: 20px; height: 20px; background-color: {}; border: 1px solid #ccc; border-radius: 3px;" title="Primary: {}"></div>'
            '<div style="width: 20px; height: 20px; background-color: {}; border: 1px solid #ccc; border-radius: 3px;" title="Secondary: {}"></div>'
            '<div style="width: 20px; height: 20px; background-color: {}; border: 1px solid #ccc; border-radius: 3px;" title="Accent: {}"></div>'
            '</div>',
            obj.primary_color, obj.primary_color,
            obj.secondary_color, obj.secondary_color,
            obj.accent_color, obj.accent_color
        )
    color_preview.short_description = "Colors"
    
    def apply_preset_button(self, obj):
        url = reverse('admin:apply-theme-preset', args=[obj.id])
        return format_html(
            '<a class="button" href="{}" style="background-color: #3498db; color: white; padding: 3px 8px; text-decoration: none; border-radius: 3px; font-size: 12px;">Apply</a>',
            url
        )
    apply_preset_button.short_description = "Actions"
    
    def theme_preview(self, obj):
        """Preview the theme with colors and design tokens"""
        return format_html(
            '<div style="border: 1px solid #ddd; padding: 20px; margin: 10px 0; border-radius: 8px; background-color: {};">'
            '<h4 style="color: {}; margin-top: 0;">Theme Preview: {}</h4>'
            '<div style="display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin: 15px 0;">'
            '<div style="background-color: {}; padding: 15px; border-radius: 6px; color: white; font-weight: bold; text-align: center;">Primary</div>'
            '<div style="background-color: {}; padding: 15px; border-radius: 6px; color: white; font-weight: bold; text-align: center;">Secondary</div>'
            '<div style="background-color: {}; padding: 15px; border-radius: 6px; color: white; font-weight: bold; text-align: center;">Accent</div>'
            '<div style="background-color: {}; padding: 15px; border-radius: 6px; color: {}; font-weight: bold; text-align: center;">Background</div>'
            '</div>'
            '<div style="margin-top: 20px; padding: 15px; background-color: #F5F5F7; border-radius: 6px;">'
            '<p style="color: {}; margin: 0;"><strong>Design Tokens:</strong></p>'
            '<p style="color: {}; margin: 5px 0;">Shadow: {}</p>'
            '<p style="color: {}; margin: 5px 0;">Spacing: {}</p>'
            '<p style="color: {}; margin: 5px 0;">Font Size: {}</p>'
            '</div>'
            '</div>',
            obj.background_color or '#FFFFFF',
            obj.text_primary or '#000000',
            obj.name,
            obj.primary_color or '#0693E3',
            obj.secondary_color or '#9B51E0',
            obj.accent_color or '#00D084',
            obj.background_color or '#FFFFFF',
            '#000000' if obj.background_color and obj.background_color.upper() != '#FFFFFF' else '#000000',
            obj.text_primary or '#000000',
            obj.text_primary or '#000000', obj.get_shadow_type_display(),
            obj.text_primary or '#000000', obj.get_spacing_scale_display(),
            obj.text_primary or '#000000', obj.get_font_size_display()
        )
    theme_preview.short_description = "Theme Preview"
    
    def design_tokens_preview(self, obj):
        """Show design token values"""
        spacing_map = {
            's20': '7px', 's30': '11px', 's40': '16px',
            's50': '24px', 's60': '36px', 's70': '54px', 's80': '81px'
        }
        
        font_map = {
            'small': '13px', 'medium': '20px',
            'large': '36px', 'xlarge': '42px'
        }
        
        return format_html(
            '<div style="border: 1px solid #ddd; padding: 15px; margin: 10px 0; border-radius: 6px; background-color: #f8f9fa;">'
            '<h5 style="margin-top: 0;">Design Token Values</h5>'
            '<table style="width: 100%; border-collapse: collapse;">'
            '<tr><td style="padding: 8px; border-bottom: 1px solid #dee2e6;"><strong>Spacing</strong></td><td style="padding: 8px; border-bottom: 1px solid #dee2e6;">{} ({})</td></tr>'
            '<tr><td style="padding: 8px; border-bottom: 1px solid #dee2e6;"><strong>Font Size</strong></td><td style="padding: 8px; border-bottom: 1px solid #dee2e6;">{} ({})</td></tr>'
            '<tr><td style="padding: 8px;"><strong>Shadow Type</strong></td><td style="padding: 8px;">{}</td></tr>'
            '</table>'
            '</div>',
            obj.spacing_scale, spacing_map.get(obj.spacing_scale, '16px'),
            obj.font_size, font_map.get(obj.font_size, '20px'),
            obj.get_shadow_type_display()
        )
    design_tokens_preview.short_description = "Design Tokens"
    
    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path(
                '<int:preset_id>/apply/',
                self.admin_site.admin_view(self.apply_preset_view),
                name='apply-theme-preset',
            ),
        ]
        return custom_urls + urls
    
    def apply_preset_view(self, request, preset_id):
        """Apply this preset to global appearance"""
        try:
            preset = ThemePreset.objects.get(id=preset_id)
            appearance, created = AppAppearance.objects.get_or_create(user=None)
            preset.apply_to_appearance(appearance)
            
            messages.success(
                request,
                f'Theme preset "{preset.name}" has been applied to global appearance.'
            )
        except ThemePreset.DoesNotExist:
            messages.error(request, 'Theme preset not found.')
        
        return HttpResponseRedirect(reverse('admin:frontend_manage_themepreset_changelist'))
    
    @admin.action(description="Activate selected presets")
    def activate_presets(self, request, queryset):
        count = queryset.update(is_active=True)
        self.message_user(request, f'Activated {count} theme preset(s).', messages.SUCCESS)
    
    @admin.action(description="Deactivate selected presets")
    def deactivate_presets(self, request, queryset):
        count = queryset.update(is_active=False)
        self.message_user(request, f'Deactivated {count} theme preset(s).', messages.SUCCESS)
    
    @admin.action(description="Mark as recommended")
    def mark_as_recommended(self, request, queryset):
        count = queryset.update(is_recommended=True)
        self.message_user(request, f'Marked {count} theme preset(s) as recommended.', messages.SUCCESS)
    
    @admin.action(description="Apply to Global Appearance")
    def apply_to_global_appearance(self, request, queryset):
        if queryset.count() != 1:
            self.message_user(request, 'Please select exactly one preset to apply.', messages.ERROR)
            return
        
        preset = queryset.first()
        appearance, created = AppAppearance.objects.get_or_create(user=None)
        preset.apply_to_appearance(appearance)
        
        self.message_user(
            request,
            f'Theme preset "{preset.name}" has been applied to global appearance.',
            messages.SUCCESS
        )
    
    def save_model(self, request, obj, form, change):
        # Set thumbnail URL based on preset type if not provided
        if not obj.thumbnail_url and obj.preset_type != 'custom':
            thumbnail_map = {
                'wp_default': 'https://via.placeholder.com/300x200/0693E3/FFFFFF?text=WordPress+Default',
                'wp_vivid': 'https://via.placeholder.com/300x200/FF6900/FFFFFF?text=WordPress+Vivid',
                'wp_pastel': 'https://via.placeholder.com/300x200/8ED1FC/000000?text=WordPress+Pastel',
                'wp_dark': 'https://via.placeholder.com/300x200/121212/FFFFFF?text=WordPress+Dark',
            }
            obj.thumbnail_url = thumbnail_map.get(obj.preset_type, '')
        
        super().save_model(request, obj, form, change)


@admin.register(LoginPage)
class LoginPageAdmin(admin.ModelAdmin):
    """
    Custom login page content and branding.
    """
    list_display = ('title', 'slogans_preview')
    search_fields = ('title', 'slogans1', 'slogans2', 'slogans3')

    def has_add_permission(self, request):
        # Usually only one instance
        return LoginPage.objects.count() == 0

    def slogans_preview(self, obj):
        slogans = [s for s in [obj.slogans1, obj.slogans2, obj.slogans3] if s]
        return " | ".join(slogans[:2]) + ("..." if len(slogans) > 2 else "")
    slogans_preview.short_description = "Slogans"

    fieldsets = (
        ("Login Page Content", {
            'fields': ('title', 'banner'),
        }),
        ("Slogans & Messaging", {
            'fields': ('slogans1', 'slogans2', 'slogans3'),
            'description': mark_safe(
                "<em>Example Afro-centric slogans:</em><br>"
                "• 'Empowering Africa's Next Generation of Leaders'<br>"
                "• 'Learn in Your Language, Excel in Your Future'<br>"
                "• 'African Minds, Global Impact'"
            )
        }),
        ("Timestamps", {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )


@admin.register(AppAppearance)
class AppAppearanceAdmin(admin.ModelAdmin):
    """
    Manage global and per-user appearance settings using WordPress color palette.
    Includes WordPress design tokens for consistent styling.
    """
    list_display = (
        'display_name', 'is_dark_mode_display',
        'color_palette_preview', 'design_tokens_preview', 
        'make_default_button', 'updated_at'
    )
    list_filter = ('is_dark_mode', 'user')
    search_fields = ('user__username', 'user__email')
    ordering = ('-updated_at',)
    actions = ['make_selected_default', 'apply_wordpress_default']
    
    readonly_fields = ('created_at', 'updated_at', 'theme_preview', 
                      'color_scheme_preview', 'design_tokens_values')

    fieldsets = (
        ("Scope", {
            'fields': ('user',),
            'description': mark_safe(
                "<strong>Global vs User:</strong><br>"
                "Leave 'User' empty for global appearance (applies to everyone).<br>"
                "Select a user for personal customization (e.g., dark mode preference)."
            )
        }),
        ("WordPress Color Palette", {
            'fields': (
                'primary_color', 'primary_variant', 'secondary_color',
                'accent_color', 'error_color', 'warning_color', 'success_color'
            ),
            'description': mark_safe(
                "<strong>WordPress Color Palette:</strong> Use the official WordPress color presets "
                "for professional, consistent design across platforms."
            )
        }),
        ("Background & Text Colors", {
            'fields': (
                'background_color', 'surface_color',
                'text_primary', 'text_secondary', 'text_tertiary'
            ),
        }),
        ("WordPress Design Tokens", {
            'fields': (
                'shadow_preset', 'spacing_preset', 'font_size_preset',
                'border_radius', 'button_style'
            ),
            'classes': ('collapse',),
        }),
        ("Typography", {
            'fields': ('font_family', 'font_family_secondary', 'font_size_multiplier'),
            'classes': ('collapse',),
        }),
        ("Branding Assets", {
            'fields': ('logo_url', 'logo_dark_url', 'favicon_url'),
            'classes': ('collapse',),
        }),
        ("Mode", {
            'fields': ('is_dark_mode',),
        }),
        ("Previews", {
            'fields': ('theme_preview', 'color_scheme_preview', 'design_tokens_values'),
            'classes': ('collapse',),
        }),
        ("Timestamps", {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )

    def display_name(self, obj):
        return _("Global Appearance") if not obj.user else f"{obj.user.username}'s Appearance"
    display_name.short_description = _("Scope")

    def is_dark_mode_display(self, obj):
        return "🌙 Dark" if obj.is_dark_mode else "☀️ Light"
    is_dark_mode_display.short_description = _("Mode")

    def color_palette_preview(self, obj):
        """Show WordPress color palette preview"""
        return format_html(
            '<div style="display: flex; gap: 4px; align-items: center;">'
            '<div style="width: 16px; height: 16px; background-color: {}; border: 1px solid #ccc; border-radius: 2px;" title="Primary: {}"></div>'
            '<div style="width: 16px; height: 16px; background-color: {}; border: 1px solid #ccc; border-radius: 2px;" title="Secondary: {}"></div>'
            '<div style="width: 16px; height: 16px; background-color: {}; border: 1px solid #ccc; border-radius: 2px;" title="Accent: {}"></div>'
            '<div style="width: 16px; height: 16px; background-color: {}; border: 1px solid #ccc; border-radius: 2px;" title="Background: {}"></div>'
            '</div>',
            obj.primary_color or '#0693E3', obj.primary_color or '#0693E3',
            obj.secondary_color or '#9B51E0', obj.secondary_color or '#9B51E0',
            obj.accent_color or '#00D084', obj.accent_color or '#00D084',
            obj.background_color or '#FFFFFF', obj.background_color or '#FFFFFF'
        )
    color_palette_preview.short_description = _("WordPress Colors")

    def design_tokens_preview(self, obj):
        """Show WordPress design tokens preview"""
        spacing_text = obj.get_spacing_preset_display()
        font_text = obj.get_font_size_preset_display()
        shadow_text = obj.get_shadow_preset_display()
        
        return format_html(
            '<div style="display: flex; gap: 6px; align-items: center; color: #666; font-size: 12px;">'
            '<span title="Spacing">📏 {}</span>'
            '<span title="Font">🔤 {}</span>'
            '<span title="Shadow">🌑 {}</span>'
            '</div>',
            spacing_text, font_text, shadow_text
        )
    design_tokens_preview.short_description = _("Design Tokens")

    def make_default_button(self, obj):
        if obj.user:
            return format_html('<span style="color: #95a5a6;">User-specific</span>')
        
        # Check if this is already the global default
        default_global = AppAppearance.objects.filter(user__isnull=True).first()
        if default_global and default_global.id == obj.id:
            return format_html('<span style="color: #27ae60;">✓ Global Default</span>')
        
        url = reverse('admin:make-default-appearance', args=[obj.id])
        return format_html(
            '<a class="button" href="{}" style="background-color: #3498db; color: white; padding: 3px 8px; text-decoration: none; border-radius: 3px; font-size: 12px;">Make Default</a>',
            url
        )
    make_default_button.short_description = _("Actions")

    def theme_preview(self, obj):
        """Full theme preview with colors and design tokens"""
        return format_html(
            '<div style="border: 1px solid #ddd; padding: 20px; margin: 10px 0; border-radius: 8px; background-color: {};">'
            '<h4 style="color: {}; margin-top: 0;">Theme Preview</h4>'
            
            '<div style="display: grid; grid-template-columns: repeat(6, 1fr); gap: 8px; margin: 15px 0;">'
            '<div style="background-color: {}; padding: 12px; border-radius: 4px; color: white; font-size: 11px; text-align: center; font-weight: bold;">Primary</div>'
            '<div style="background-color: {}; padding: 12px; border-radius: 4px; color: white; font-size: 11px; text-align: center; font-weight: bold;">Secondary</div>'
            '<div style="background-color: {}; padding: 12px; border-radius: 4px; color: white; font-size: 11px; text-align: center; font-weight: bold;">Accent</div>'
            '<div style="background-color: {}; padding: 12px; border-radius: 4px; color: #000; font-size: 11px; text-align: center; font-weight: bold;">Error</div>'
            '<div style="background-color: {}; padding: 12px; border-radius: 4px; color: #000; font-size: 11px; text-align: center; font-weight: bold;">Warning</div>'
            '<div style="background-color: {}; padding: 12px; border-radius: 4px; color: white; font-size: 11px; text-align: center; font-weight: bold;">Success</div>'
            '</div>'
            
            '<div style="margin-top: 20px; padding: 15px; background-color: {}; border-radius: 6px; border: 1px solid {};">'
            '<h5 style="color: {}; margin-top: 0;">UI Component Preview</h5>'
            '<div style="display: flex; gap: 10px; margin-top: 10px;">'
            '<button style="background-color: {}; color: white; border: none; padding: 8px 16px; border-radius: {}; cursor: default;">Button</button>'
            '<div style="background-color: {}; color: {}; padding: 8px 16px; border-radius: {}; border: 1px solid {};">Card</div>'
            '</div>'
            '</div>'
            
            '<div style="margin-top: 20px;">'
            '<h5 style="color: {}; margin-top: 0;">Text Preview</h5>'
            '<p style="color: {}; font-size: 16px; margin: 8px 0;"><strong>Primary Text</strong> - This is how primary text appears</p>'
            '<p style="color: {}; font-size: 14px; margin: 8px 0;">Secondary Text - Supporting information</p>'
            '<p style="color: {}; font-size: 12px; margin: 8px 0;">Tertiary Text - Additional details or hints</p>'
            '</div>'
            '</div>',
            obj.background_color or '#FFFFFF',
            obj.text_primary or '#000000',
            obj.primary_color or '#0693E3',
            obj.secondary_color or '#9B51E0',
            obj.accent_color or '#00D084',
            obj.error_color or '#CF2E2E',
            obj.warning_color or '#FCB900',
            obj.success_color or '#00D084',
            obj.surface_color or '#F5F5F7',
            obj.text_tertiary or '#ABB8C3',
            obj.text_primary or '#000000',
            obj.primary_color or '#0693E3',
            '4px' if obj.border_radius == 'small' else '8px' if obj.border_radius == 'medium' else '16px' if obj.border_radius == 'large' else '24px',
            obj.surface_color or '#F5F5F7',
            obj.text_primary or '#000000',
            '4px' if obj.border_radius == 'small' else '8px' if obj.border_radius == 'medium' else '16px' if obj.border_radius == 'large' else '24px',
            obj.text_tertiary or '#ABB8C3',
            obj.text_primary or '#000000',
            obj.text_primary or '#000000',
            obj.text_secondary or '#666666',
            obj.text_tertiary or '#ABB8C3'
        )
    theme_preview.short_description = "Full Theme Preview"

    def color_scheme_preview(self, obj):
        """Show Material Design 3 color scheme"""
        from .serializers import AppAppearanceSerializer
        serializer = AppAppearanceSerializer(obj)
        color_scheme = serializer.get_color_scheme(obj)
        
        return format_html(
            '<div style="border: 1px solid #ddd; padding: 15px; margin: 10px 0; border-radius: 8px; background-color: #f8f9fa;">'
            '<h5 style="margin-top: 0;">Material Design 3 Color Scheme</h5>'
            '<div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 8px; margin-top: 10px;">'
            '<div style="background-color: {}; padding: 10px; border-radius: 4px; color: {}; font-size: 11px;"><strong>primary</strong><br>{}</div>'
            '<div style="background-color: {}; padding: 10px; border-radius: 4px; color: {}; font-size: 11px;"><strong>onPrimary</strong><br>{}</div>'
            '<div style="background-color: {}; padding: 10px; border-radius: 4px; color: {}; font-size: 11px;"><strong>secondary</strong><br>{}</div>'
            '<div style="background-color: {}; padding: 10px; border-radius: 4px; color: {}; font-size: 11px;"><strong>onSecondary</strong><br>{}</div>'
            '<div style="background-color: {}; padding: 10px; border-radius: 4px; color: {}; font-size: 11px;"><strong>surface</strong><br>{}</div>'
            '<div style="background-color: {}; padding: 10px; border-radius: 4px; color: {}; font-size: 11px;"><strong>onSurface</strong><br>{}</div>'
            '<div style="background-color: {}; padding: 10px; border-radius: 4px; color: {}; font-size: 11px;"><strong>error</strong><br>{}</div>'
            '<div style="background-color: {}; padding: 10px; border-radius: 4px; color: {}; font-size: 11px;"><strong>onError</strong><br>{}</div>'
            '</div>'
            '</div>',
            color_scheme.get('primary', '#0693E3'), 
            color_scheme.get('onPrimary', '#FFFFFF'), color_scheme.get('primary', '#0693E3'),
            
            color_scheme.get('onPrimary', '#FFFFFF'),
            color_scheme.get('primary', '#0693E3'), color_scheme.get('onPrimary', '#FFFFFF'),
            
            color_scheme.get('secondary', '#9B51E0'),
            color_scheme.get('onSecondary', '#FFFFFF'), color_scheme.get('secondary', '#9B51E0'),
            
            color_scheme.get('onSecondary', '#FFFFFF'),
            color_scheme.get('secondary', '#9B51E0'), color_scheme.get('onSecondary', '#FFFFFF'),
            
            color_scheme.get('surface', '#F5F5F7'),
            color_scheme.get('onSurface', '#000000'), color_scheme.get('surface', '#F5F5F7'),
            
            color_scheme.get('onSurface', '#000000'),
            color_scheme.get('surface', '#F5F5F7'), color_scheme.get('onSurface', '#000000'),
            
            color_scheme.get('error', '#CF2E2E'),
            color_scheme.get('onError', '#FFFFFF'), color_scheme.get('error', '#CF2E2E'),
            
            color_scheme.get('onError', '#FFFFFF'),
            color_scheme.get('error', '#CF2E2E'), color_scheme.get('onError', '#FFFFFF'),
        )
    color_scheme_preview.short_description = "MD3 Color Scheme"

    def design_tokens_values(self, obj):
        """Show computed design token values"""
        from .serializers import AppAppearanceSerializer
        serializer = AppAppearanceSerializer(obj)
        
        spacing = serializer.get_spacing_values(obj)
        fonts = serializer.get_font_size_values(obj)
        shadow = serializer.get_shadow_values(obj)
        
        return format_html(
            '<div style="border: 1px solid #ddd; padding: 15px; margin: 10px 0; border-radius: 8px; background-color: #f8f9fa;">'
            '<h5 style="margin-top: 0;">Computed Design Token Values</h5>'
            
            '<div style="margin-top: 15px;">'
            '<h6 style="margin: 0 0 8px 0; color: #666;">Spacing Scale</h6>'
            '<div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px;">'
            '<div style="background-color: #e9ecef; padding: 8px; border-radius: 4px; font-size: 12px;"><strong>XS:</strong> {:.1f}px</div>'
            '<div style="background-color: #e9ecef; padding: 8px; border-radius: 4px; font-size: 12px;"><strong>SM:</strong> {:.1f}px</div>'
            '<div style="background-color: #e9ecef; padding: 8px; border-radius: 4px; font-size: 12px;"><strong>MD:</strong> {:.1f}px</div>'
            '<div style="background-color: #e9ecef; padding: 8px; border-radius: 4px; font-size: 12px;"><strong>LG:</strong> {:.1f}px</div>'
            '<div style="background-color: #e9ecef; padding: 8px; border-radius: 4px; font-size: 12px;"><strong>XL:</strong> {:.1f}px</div>'
            '<div style="background-color: #e9ecef; padding: 8px; border-radius: 4px; font-size: 12px;"><strong>XXL:</strong> {:.1f}px</div>'
            '</div>'
            '</div>'
            
            '<div style="margin-top: 20px;">'
            '<h6 style="margin: 0 0 8px 0; color: #666;">Typography Scale</h6>'
            '<div style="display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px;">'
            '<div style="background-color: #e9ecef; padding: 8px; border-radius: 4px; font-size: 12px;"><strong>Caption:</strong> {:.1f}px</div>'
            '<div style="background-color: #e9ecef; padding: 8px; border-radius: 4px; font-size: 12px;"><strong>Body:</strong> {:.1f}px</div>'
            '<div style="background-color: #e9ecef; padding: 8px; border-radius: 4px; font-size: 12px;"><strong>Subtitle:</strong> {:.1f}px</div>'
            '<div style="background-color: #e9ecef; padding: 8px; border-radius: 4px; font-size: 12px;"><strong>Title:</strong> {:.1f}px</div>'
            '<div style="background-color: #e9ecef; padding: 8px; border-radius: 4px; font-size: 12px;"><strong>Headline:</strong> {:.1f}px</div>'
            '<div style="background-color: #e9ecef; padding: 8px; border-radius: 4px; font-size: 12px;"><strong>Display:</strong> {:.1f}px</div>'
            '</div>'
            '</div>'
            
            '<div style="margin-top: 20px;">'
            '<h6 style="margin: 0 0 8px 0; color: #666;">Shadow</h6>'
            '<div style="background-color: #e9ecef; padding: 10px; border-radius: 4px; font-size: 12px;">'
            '<strong>Type:</strong> {}<br>'
            '<strong>Offset:</strong> {}x, {}y<br>'
            '<strong>Blur:</strong> {}<br>'
            '<strong>Color:</strong> {}'
            '</div>'
            '</div>'
            '</div>',
            spacing.get('xs', 8.0), spacing.get('sm', 12.0), spacing.get('md', 16.0),
            spacing.get('lg', 24.0), spacing.get('xl', 32.0), spacing.get('xxl', 48.0),
            
            fonts.get('caption', 15.0), fonts.get('body', 17.5), fonts.get('subtitle', 20.0),
            fonts.get('title', 25.0), fonts.get('headline', 30.0), fonts.get('display', 40.0),
            
            obj.get_shadow_preset_display(),
            shadow.get('offsetX', 6), shadow.get('offsetY', 6),
            shadow.get('blurRadius', 9),
            shadow.get('color', '0x33000000')
        )
    design_tokens_values.short_description = "Computed Token Values"

    def get_readonly_fields(self, request, obj=None):
        # Make user readonly after creation (to avoid accidental changes)
        if obj and obj.pk:
            return self.readonly_fields + ('user',)
        return self.readonly_fields

    def get_urls(self):
        urls = super().get_urls()
        custom_urls = [
            path(
                '<int:appearance_id>/make-default/',
                self.admin_site.admin_view(self.make_default_view),
                name='make-default-appearance',
            ),
        ]
        return custom_urls + urls

    def make_default_view(self, request, appearance_id):
        try:
            appearance = AppAppearance.objects.get(id=appearance_id)
            if appearance.user:
                messages.error(request, 'Cannot make user-specific appearance the global default.')
            else:
                # Update this appearance as the primary global one
                # (in this model, we can have multiple global, but API uses first())
                # We'll move it to the top by updating timestamp
                appearance.save()  # This updates updated_at
                messages.success(
                    request, 
                    f'Appearance settings have been set as the global default.'
                )
        except AppAppearance.DoesNotExist:
            messages.error(request, 'Appearance not found.')
        
        return HttpResponseRedirect(reverse('admin:frontend_manage_appappearance_changelist'))

    def make_selected_default(self, request, queryset):
        # Filter for global appearances only
        global_appearances = queryset.filter(user__isnull=True)
        if global_appearances.exists():
            # Update the first one (will be used by API)
            appearance = global_appearances.first()
            appearance.save()  # Update timestamp
            count = global_appearances.count()
            self.message_user(
                request, 
                f'Set {count} global appearance(s) as default. Only the most recent will be used by the API.',
                messages.SUCCESS if count == 1 else messages.WARNING
            )
        else:
            self.message_user(
                request, 
                'No global appearances selected. Cannot set user-specific appearances as default.',
                messages.ERROR
            )
    make_selected_default.short_description = "Make selected global appearances the default"
    
    @admin.action(description="Apply WordPress Default Theme")
    def apply_wordpress_default(self, request, queryset):
        for appearance in queryset:
            # Apply WordPress default colors
            appearance.primary_color = '#0693E3'
            appearance.primary_variant = '#8ED1FC'
            appearance.secondary_color = '#9B51E0'
            appearance.accent_color = '#00D084'
            appearance.error_color = '#CF2E2E'
            appearance.warning_color = '#FCB900'
            appearance.success_color = '#00D084'
            appearance.background_color = '#FFFFFF'
            appearance.surface_color = '#F5F5F7'
            appearance.text_primary = '#000000'
            appearance.text_secondary = '#666666'
            appearance.text_tertiary = '#ABB8C3'
            appearance.save()
        
        count = queryset.count()
        self.message_user(
            request,
            f'Applied WordPress Default theme to {count} appearance(s).',
            messages.SUCCESS
        )

    class Media:
        css = {
            'all': ('admin/css/color-preview.css',)
        }
        js = ('admin/js/color-picker.js',)

# Add a custom admin action for quick theme creation from templates
def create_theme_from_template(modeladmin, request, queryset):
    for appearance in queryset.filter(user__isnull=True):
        # Create a theme based on appearance
        theme_name = f"Auto-Theme-{appearance.id}"
        if not Theme.objects.filter(name=theme_name).exists():
            Theme.objects.create(
                name=theme_name,
                title=f"Auto Generated from Appearance #{appearance.id}",
                version="1.0",
                description=f"Auto-generated theme based on appearance settings: Primary: {appearance.primary_color}, Secondary: {appearance.secondary_color}",
                status=True,
                is_active=False
            )
    modeladmin.message_user(request, "Themes created from selected appearances.")
create_theme_from_template.short_description = "Create themes from appearances"

# Register the action
AppAppearanceAdmin.actions.append(create_theme_from_template)