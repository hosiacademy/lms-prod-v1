# apps/frontend_manage/serializers.py
"""
Serializers for dynamic frontend content management with WordPress color palette.

These expose database-driven homepage, branding, theme settings,
and appearance (WordPress colors, dark mode) to the Flutter frontend,
enabling real-time updates without app redeployment.
"""

from rest_framework import serializers

from .models import (
    FrontendSetting, HomeContent, GeneralSetting, 
    Theme, LoginPage, AppAppearance, ThemePreset
)


class FrontendSettingSerializer(serializers.ModelSerializer):
    """
    Individual frontend section/block (e.g., hero, features, CTA).
    Used for modular homepage layout.
    """
    icon = serializers.CharField(allow_blank=True, required=False)

    class Meta:
        model = FrontendSetting
        fields = (
            'id', 'section', 'title', 'description',
            'btn_name', 'btn_link', 'url', 'icon', 'status'
        )
        read_only_fields = ('created_at', 'updated_at')


class ThemeSerializer(serializers.ModelSerializer):
    """
    Available themes – allows switching between Afro-centric designs.
    """
    is_active = serializers.BooleanField(read_only=True)

    class Meta:
        model = Theme
        fields = (
            'id', 'name', 'title', 'image', 'version',
            'folder_path', 'live_link', 'description',
            'is_active', 'status', 'tags'
        )


class ThemePresetSerializer(serializers.ModelSerializer):
    """
    WordPress theme preset collections for quick theme switching.
    """
    colors = serializers.SerializerMethodField()
    design_tokens = serializers.SerializerMethodField()
    
    class Meta:
        model = ThemePreset
        fields = (
            'id', 'name', 'preset_type', 'description',
            'primary_color', 'primary_variant', 'secondary_color',
            'accent_color', 'background_color', 'text_primary',
            'shadow_type', 'spacing_scale', 'font_size',
            'thumbnail_url', 'is_active', 'is_recommended',
            'colors', 'design_tokens'
        )
    
    def get_colors(self, obj):
        """Return structured color data for Flutter theme system"""
        return {
            'primary': obj.primary_color,
            'primaryVariant': obj.primary_variant,
            'secondary': obj.secondary_color,
            'accent': obj.accent_color,
            'background': obj.background_color,
            'surface': '#F5F5F7',  # Default surface
            'textPrimary': obj.text_primary,
            'textSecondary': '#666666',
            'error': '#CF2E2E',  # WordPress Vivid Red
            'warning': '#FCB900',  # WordPress Luminous Vivid Amber
            'success': '#00D084',  # WordPress Vivid Green Cyan
        }
    
    def get_design_tokens(self, obj):
        """Return WordPress design tokens for consistent styling"""
        spacing_map = {
            's20': 7.0,
            's30': 11.0,
            's40': 16.0,
            's50': 24.0,
            's60': 36.0,
            's70': 54.0,
            's80': 81.0,
        }
        
        font_map = {
            'small': 13.0,
            'medium': 20.0,
            'large': 36.0,
            'xlarge': 42.0,
        }
        
        shadow_map = {
            'natural': {
                'color': '0x33000000',
                'offsetX': 6,
                'offsetY': 6,
                'blurRadius': 9,
            },
            'deep': {
                'color': '0x66000000',
                'offsetX': 12,
                'offsetY': 12,
                'blurRadius': 50,
            },
            'sharp': {
                'color': '0x33000000',
                'offsetX': 6,
                'offsetY': 6,
                'blurRadius': 0,
            },
            'outlined': {
                'color': '0xFF000000',
                'offsetX': 6,
                'offsetY': 6,
                'blurRadius': 0,
            },
            'crisp': {
                'color': '0xFF000000',
                'offsetX': 6,
                'offsetY': 6,
                'blurRadius': 0,
            },
        }
        
        return {
            'spacing': spacing_map.get(obj.spacing_scale, 16.0),
            'fontSize': font_map.get(obj.font_size, 20.0),
            'shadow': shadow_map.get(obj.shadow_type, shadow_map['natural']),
            'borderRadius': 'medium',
            'buttonStyle': 'rounded',
        }


class LoginPageSerializer(serializers.ModelSerializer):
    """
    Custom login page content and branding.
    """
    class Meta:
        model = LoginPage
        fields = ('id', 'title', 'banner', 'slogans1', 'slogans2', 'slogans3')


class GeneralSettingSerializer(serializers.ModelSerializer):
    """
    Global site settings – branding, contact, social, currency.
    Single source of truth for core identity.
    """
    currency_symbol = serializers.CharField(source='currency.symbol', read_only=True)
    currency_code = serializers.CharField(source='currency.code', read_only=True)

    class Meta:
        model = GeneralSetting
        fields = (
            'site_title', 'logo', 'logo2', 'favicon',
            'phone', 'email', 'address', 'city', 'state',
            'fb', 'twitter', 'youtube', 'linkedin',
            'copyright_text', 'commission',
            'currency_id', 'currency_symbol', 'currency_code',
            'template_id', 'ttl_rtl', 'recapthca'
        )
        read_only_fields = fields  # Usually only one instance, edited in admin


class HomeContentSerializer(serializers.ModelSerializer):
    """
    Comprehensive homepage content serializer.
    Powers the entire dynamic landing page with Afro-centric messaging.
    """
    key_features = serializers.SerializerMethodField()

    class Meta:
        model = HomeContent
        fields = (
            'slider_title', 'slider_text', 'slider_banner',
            'category_title', 'category_sub_title',
            'instructor_title', 'instructor_sub_title', 'instructor_banner',
            'course_title', 'course_sub_title', 'course_page_banner',
            'best_category_title', 'best_category_sub_title', 'best_category_banner',
            'quiz_title', 'quiz_page_banner',
            'testimonial_title', 'testimonial_sub_title',
            'become_instructor_title', 'become_instructor_sub_title', 'become_instructor_logo',
            'subscribe_title', 'subscribe_sub_title', 'subscribe_logo',
            'show_key_feature', 'key_features',
            'active_status'
        )

    def get_key_features(self, obj):
        """Return structured key feature blocks for easy rendering in Flutter."""
        return [
            {
                "title": obj.key_feature_title1,
                "subtitle": obj.key_feature_subtitle1,
                "logo": obj.key_feature_logo1,
                "link": obj.key_feature_link1
            },
            {
                "title": obj.key_feature_title2,
                "subtitle": obj.key_feature_subtitle2,
                "logo": obj.key_feature_logo2,
                "link": obj.key_feature_link2
            },
            {
                "title": obj.key_feature_title3,
                "subtitle": obj.key_feature_subtitle3,
                "logo": obj.key_feature_logo3,
                "link": obj.key_feature_link3
            },
        ]


class AppAppearanceSerializer(serializers.ModelSerializer):
    """
    Backend-controlled appearance settings using WordPress color palette.
    Includes WordPress design tokens for consistent styling.
    """
    # WordPress Design System Tokens
    spacing_values = serializers.SerializerMethodField()
    font_size_values = serializers.SerializerMethodField()
    shadow_values = serializers.SerializerMethodField()
    color_scheme = serializers.SerializerMethodField()
    
    class Meta:
        model = AppAppearance
        fields = (
            # WordPress Color Palette
            'primary_color', 'primary_variant', 'secondary_color',
            'accent_color', 'error_color', 'warning_color', 'success_color',
            'background_color', 'surface_color',
            'text_primary', 'text_secondary', 'text_tertiary',
            
            # Dark Mode & Fonts
            'is_dark_mode', 'font_family', 'font_family_secondary',
            'font_size_multiplier',
            
            # WordPress Design Tokens
            'shadow_preset', 'spacing_preset', 'font_size_preset',
            'border_radius', 'button_style',
            
            # Logo & Branding
            'logo_url', 'logo_dark_url', 'favicon_url',
            
            # Computed Values
            'spacing_values', 'font_size_values', 'shadow_values',
            'color_scheme'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')
    
    def get_spacing_values(self, obj):
        """Convert spacing preset to actual pixel values"""
        spacing_map = {
            's20': 7.0,   # 0.44rem ≈ 7px
            's30': 11.0,  # 0.67rem ≈ 11px
            's40': 16.0,  # 1rem ≈ 16px
            's50': 24.0,  # 1.5rem ≈ 24px
            's60': 36.0,  # 2.25rem ≈ 36px
            's70': 54.0,  # 3.38rem ≈ 54px
            's80': 81.0,  # 5.06rem ≈ 81px
        }
        
        base_spacing = spacing_map.get(obj.spacing_preset, 16.0)
        return {
            'xs': base_spacing * 0.5,
            'sm': base_spacing * 0.75,
            'md': base_spacing,
            'lg': base_spacing * 1.5,
            'xl': base_spacing * 2,
            'xxl': base_spacing * 3,
        }
    
    def get_font_size_values(self, obj):
        """Convert font size preset to actual pixel values"""
        base_size_map = {
            'small': 13.0,
            'medium': 20.0,
            'large': 36.0,
            'xlarge': 42.0,
        }
        
        base_size = base_size_map.get(obj.font_size_preset, 20.0)
        multiplier = obj.font_size_multiplier or 1.0
        
        return {
            'caption': base_size * 0.75 * multiplier,
            'body': base_size * 0.875 * multiplier,
            'subtitle': base_size * multiplier,
            'title': base_size * 1.25 * multiplier,
            'headline': base_size * 1.5 * multiplier,
            'display': base_size * 2 * multiplier,
        }
    
    def get_shadow_values(self, obj):
        """Convert shadow preset to Flutter BoxShadow values"""
        shadows = {
            'natural': {
                'color': '0x33000000',  # rgba(0,0,0,0.2)
                'offsetX': 6,
                'offsetY': 6,
                'blurRadius': 9,
                'spreadRadius': 0,
            },
            'deep': {
                'color': '0x66000000',  # rgba(0,0,0,0.4)
                'offsetX': 12,
                'offsetY': 12,
                'blurRadius': 50,
                'spreadRadius': 0,
            },
            'sharp': {
                'color': '0x33000000',  # rgba(0,0,0,0.2)
                'offsetX': 6,
                'offsetY': 6,
                'blurRadius': 0,
                'spreadRadius': 0,
            },
            'outlined': {
                'color': '0xFF000000',  # black
                'offsetX': 6,
                'offsetY': 6,
                'blurRadius': 0,
                'spreadRadius': 0,
                'secondColor': '0xFFFFFFFF',  # white
                'secondOffsetX': 6,
                'secondOffsetY': 6,
            },
            'crisp': {
                'color': '0xFF000000',  # black
                'offsetX': 6,
                'offsetY': 6,
                'blurRadius': 0,
                'spreadRadius': 0,
            },
        }
        return shadows.get(obj.shadow_preset, shadows['natural'])
    
    def get_color_scheme(self, obj):
        """Return complete color scheme for Material Design 3"""
        return {
            'primary': obj.primary_color,
            'onPrimary': self._get_contrast_color(obj.primary_color),
            'primaryContainer': obj.primary_variant,
            'onPrimaryContainer': self._get_contrast_color(obj.primary_variant),
            
            'secondary': obj.secondary_color,
            'onSecondary': self._get_contrast_color(obj.secondary_color),
            
            'tertiary': obj.accent_color,
            'onTertiary': self._get_contrast_color(obj.accent_color),
            
            'error': obj.error_color,
            'onError': self._get_contrast_color(obj.error_color),
            
            'background': obj.background_color,
            'onBackground': obj.text_primary,
            
            'surface': obj.surface_color,
            'onSurface': obj.text_primary,
            
            'surfaceVariant': self._adjust_color(obj.surface_color, -10),
            'onSurfaceVariant': obj.text_secondary,
            
            'outline': obj.text_tertiary,
            'outlineVariant': self._adjust_color(obj.text_tertiary, 20),
            
            'shadow': obj.text_primary,
            'scrim': f"{obj.text_primary}80",  # 50% opacity
        }
    
    def _get_contrast_color(self, hex_color):
        """Calculate contrasting text color (white or black)"""
        # Simple luminance calculation
        if hex_color.startswith('#'):
            hex_color = hex_color[1:]
        
        if len(hex_color) == 6:
            r = int(hex_color[0:2], 16)
            g = int(hex_color[2:4], 16)
            b = int(hex_color[4:6], 16)
        else:
            return '#000000'  # Default to black
        
        # Calculate relative luminance
        luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255
        return '#FFFFFF' if luminance < 0.5 else '#000000'
    
    def _adjust_color(self, hex_color, amount):
        """Lighten or darken a color"""
        if not hex_color.startswith('#'):
            return hex_color
        
        # Simplified adjustment - for production use a proper color library
        return hex_color


# ──────────────────────────────────────────────────────────────────────────────
# Master Serializer – One endpoint to rule them all
# ──────────────────────────────────────────────────────────────────────────────

class FrontendConfigSerializer(serializers.Serializer):
    """
    Master serializer that returns ALL dynamic frontend content in one call.
    Includes WordPress theme presets and design tokens.
    """
    general = serializers.SerializerMethodField()
    home = serializers.SerializerMethodField()
    login_page = serializers.SerializerMethodField()
    sections = serializers.SerializerMethodField()
    themes = serializers.SerializerMethodField()
    theme_presets = serializers.SerializerMethodField()
    active_theme = serializers.SerializerMethodField()
    appearance = serializers.SerializerMethodField()

    def get_general(self, obj):
        general = GeneralSetting.objects.first()
        return GeneralSettingSerializer(general).data if general else {}

    def get_home(self, obj):
        home = HomeContent.objects.first()
        return HomeContentSerializer(home).data if home else {}

    def get_login_page(self, obj):
        login = LoginPage.objects.first()
        return LoginPageSerializer(login).data if login else {}

    def get_sections(self, obj):
        sections = FrontendSetting.objects.filter(status=1).order_by('id')
        return FrontendSettingSerializer(sections, many=True).data

    def get_themes(self, obj):
        themes = Theme.objects.filter(status=True)
        return ThemeSerializer(themes, many=True).data
    
    def get_theme_presets(self, obj):
        """Return WordPress theme presets for quick switching"""
        presets = ThemePreset.objects.filter(is_active=True).order_by('sort_order', 'name')
        return ThemePresetSerializer(presets, many=True).data

    def get_active_theme(self, obj):
        theme = Theme.objects.filter(is_active=True, status=True).first()
        return ThemeSerializer(theme).data if theme else {}

    def get_appearance(self, obj):
        try:
            appearance = AppAppearance.objects.filter(user__isnull=True).first()
            if not appearance:
                # Create default WordPress-themed appearance
                appearance = AppAppearance.objects.create(
                    # WordPress Default Colors
                    primary_color='#0693E3',  # Vivid Cyan Blue
                    primary_variant='#8ED1FC',  # Pale Cyan Blue
                    secondary_color='#9B51E0',  # Vivid Purple
                    accent_color='#00D084',  # Vivid Green Cyan
                    error_color='#CF2E2E',  # Vivid Red
                    warning_color='#FCB900',  # Luminous Vivid Amber
                    success_color='#00D084',  # Vivid Green Cyan
                    
                    # Background & Text
                    background_color='#FFFFFF',  # White
                    surface_color='#F5F5F7',
                    text_primary='#000000',  # Black
                    text_secondary='#666666',
                    text_tertiary='#ABB8C3',  # Cyan Bluish Gray
                    
                    # Design Tokens
                    shadow_preset='natural',
                    spacing_preset='s40',
                    font_size_preset='medium',
                    border_radius='medium',
                    button_style='rounded',
                    
                    # Fonts
                    font_family='Roboto',
                    font_family_secondary='Open Sans',
                    font_size_multiplier=1.0,
                    
                    # Dark Mode
                    is_dark_mode=False,
                )
            return AppAppearanceSerializer(appearance).data
        except Exception as e:
            print(f"Error getting appearance: {e}")
            # Fallback to WordPress default theme
            return {
                'primary_color': '#0693E3',
                'primary_variant': '#8ED1FC',
                'secondary_color': '#9B51E0',
                'accent_color': '#00D084',
                'error_color': '#CF2E2E',
                'warning_color': '#FCB900',
                'success_color': '#00D084',
                'background_color': '#FFFFFF',
                'surface_color': '#F5F5F7',
                'text_primary': '#000000',
                'text_secondary': '#666666',
                'text_tertiary': '#ABB8C3',
                'is_dark_mode': False,
                'font_family': 'Roboto',
                'font_family_secondary': 'Open Sans',
                'font_size_multiplier': 1.0,
                'shadow_preset': 'natural',
                'spacing_preset': 's40',
                'font_size_preset': 'medium',
                'border_radius': 'medium',
                'button_style': 'rounded',
                'logo_url': None,
                'logo_dark_url': None,
                'favicon_url': None,
            }