# apps/frontend_manage/models.py

from django.db import models
from django.utils.translation import gettext_lazy as _
from django.contrib.auth import get_user_model

User = get_user_model()


class GeneralSetting(models.Model):
    site_title = models.CharField(max_length=191, default='Infix LMS')
    company_info = models.TextField(blank=True, null=True)
    zip_code = models.CharField(max_length=191, blank=True, null=True)
    vat_number = models.CharField(max_length=191, blank=True, null=True)
    address = models.CharField(max_length=191, blank=True, null=True)
    phone = models.CharField(max_length=191, blank=True, null=True)
    email = models.CharField(max_length=191, blank=True, null=True)
    currency_id = models.IntegerField(default=2)
    logo = models.CharField(max_length=191, blank=True, null=True)
    logo2 = models.CharField(max_length=191, blank=True, null=True)
    favicon = models.CharField(max_length=191, blank=True, null=True)
    system_version = models.CharField(max_length=191, default='1.0')
    active_status = models.IntegerField(default=1)
    website_url = models.CharField(max_length=191, blank=True, null=True)
    ttl_rtl = models.IntegerField(default=2)
    phone_number_privacy = models.IntegerField(default=1)
    language_id = models.IntegerField(default=19)
    date_format_id = models.IntegerField(default=1)
    software_version = models.CharField(max_length=100, blank=True, null=True)
    mail_signature = models.CharField(max_length=191, blank=True, null=True)
    mail_header = models.CharField(max_length=191, blank=True, null=True)
    mail_footer = models.CharField(max_length=191, blank=True, null=True)
    mail_protocol = models.CharField(max_length=100, blank=True, null=True)
    time_zone_id = models.IntegerField(default=83)
    country_id = models.IntegerField(default=19)
    city = models.CharField(max_length=191, default='Dhaka', blank=True, null=True)
    state = models.CharField(max_length=191, default='Dhaka', blank=True, null=True)
    fb = models.URLField(default='https://facebook.com/')
    twitter = models.URLField(default='https://twitter.com/')
    youtube = models.URLField(default='https://youtube.com/')
    linkedin = models.URLField(default='https://www.linkedin.com/')
    copyright_text = models.CharField(
        max_length=191,
        default='Copyright © 2024 InfixLMS. All rights reserved'
    )
    commission = models.FloatField(default=40.0)
    recapthca = models.BooleanField(default=False)
    recaptcha_key = models.CharField(max_length=191, blank=True, null=True)
    recaptcha_secret = models.CharField(max_length=191, blank=True, null=True)
    template_id = models.SmallIntegerField(default=3)
    instructor_reg = models.BooleanField(default=True)
    email_template = models.TextField(blank=True, null=True)
    meta_keywords = models.TextField(blank=True, null=True)
    meta_description = models.TextField(blank=True, null=True)
    currency_conversion = models.CharField(max_length=191, default='Fixer')
    device_limit = models.IntegerField(default=0)
    email_notification = models.BooleanField(default=False)
    show_drip = models.BooleanField(default=False)
    AmazonS3 = models.BooleanField(default=True)
    BBB = models.BooleanField(default=False)
    Sslcommerz = models.BooleanField(default=False)
    Zoom = models.BooleanField(default=True)
    lat = models.CharField(max_length=191, default='23.597506547242276')
    lng = models.CharField(max_length=191, default='58.42824308465575')
    zoom_level = models.CharField(max_length=191, default='11')
    gmap_key = models.CharField(max_length=191, default='AIzaSyA7nx22ZmINYk9TGiXDEXGVxghC43Ox6qA')
    fixer_key = models.CharField(max_length=191, default='0bd244e811264242d56e1759c93a3f1a')
    footer_about_title = models.CharField(max_length=191, default='About')
    footer_about_description = models.TextField(blank=True, null=True)
    footer_copy_right = models.TextField(blank=True, null=True)
    footer_section_one_title = models.CharField(max_length=191, default='Support Zone')
    footer_section_two_title = models.CharField(max_length=191, default='Company Info')
    footer_section_three_title = models.CharField(max_length=191, default='Explore Services')
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)
    system_domain = models.CharField(max_length=191, blank=True, null=True)
    system_activated_date = models.CharField(max_length=191, blank=True, null=True)
    last_updated_date = models.CharField(max_length=191, blank=True, null=True)

    class Meta:
        db_table = 'frontend_general_settings'
        verbose_name = _("General Setting")
        verbose_name_plural = _("General Settings")


class HomeContent(models.Model):
    slider_title = models.CharField(max_length=191, blank=True, null=True)
    slider_text = models.CharField(max_length=191, blank=True, null=True)
    testimonial_title = models.CharField(max_length=191, blank=True, null=True)
    active_status = models.SmallIntegerField(default=1)
    created_by = models.IntegerField(blank=True, null=True)
    updated_by = models.IntegerField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'frontend_home_contents'
        verbose_name = _("Home Content")
        verbose_name_plural = _("Home Contents")


class FrontendSetting(models.Model):
    section = models.CharField(max_length=191)
    title = models.CharField(max_length=191)
    description = models.CharField(max_length=191, blank=True, null=True)
    btn_name = models.CharField(max_length=191, blank=True, null=True)
    btn_link = models.CharField(max_length=191, blank=True, null=True)
    url = models.CharField(max_length=191, blank=True, null=True)
    icon = models.CharField(max_length=191, blank=True, null=True)
    status = models.SmallIntegerField(default=1)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'frontend_settings'
        verbose_name = _("Frontend Setting")
        verbose_name_plural = _("Frontend Settings")


class Theme(models.Model):
    """
    User-installed or custom frontend themes (e.g., from marketplace)
    Different from appearance.Theme which handles platform-wide styling.
    """
    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='frontend_themes',  # avoids clash with users.User.theme
        blank=True,
        null=True,
        verbose_name=_("Uploaded By")
    )
    name = models.CharField(max_length=191)
    title = models.CharField(max_length=191)
    image = models.CharField(max_length=191)
    version = models.CharField(max_length=191, blank=True, null=True)
    folder_path = models.CharField(max_length=191, default='infixlmstheme')
    live_link = models.CharField(max_length=191, default='#')
    description = models.TextField()
    is_active = models.BooleanField(default=False)
    status = models.BooleanField(default=False)
    tags = models.TextField(blank=True, null=True)
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'frontend_manage_themes'
        verbose_name = _("Frontend Theme")
        verbose_name_plural = _("Frontend Themes")

    def __str__(self):
        return f"{self.title} (v{self.version or '1.0'}) - {'Active' if self.is_active else 'Inactive'}"


class LoginPage(models.Model):
    title = models.TextField()
    banner = models.TextField()
    slogans1 = models.TextField()
    slogans2 = models.TextField()
    slogans3 = models.TextField()
    created_at = models.DateTimeField(blank=True, null=True)
    updated_at = models.DateTimeField(blank=True, null=True)

    class Meta:
        db_table = 'frontend_login_pages'
        verbose_name = _("Login Page Content")
        verbose_name_plural = _("Login Page Contents")


# WordPress Color Palette Constants
WP_COLOR_CHOICES = [
    ('#000000', 'Black'),
    ('#ABB8C3', 'Cyan Bluish Gray'),
    ('#FFFFFF', 'White'),
    ('#F78DA7', 'Pale Pink'),
    ('#CF2E2E', 'Vivid Red'),
    ('#FF6900', 'Luminous Vivid Orange'),
    ('#FCB900', 'Luminous Vivid Amber'),
    ('#7BDCB5', 'Light Green Cyan'),
    ('#00D084', 'Vivid Green Cyan'),
    ('#8ED1FC', 'Pale Cyan Blue'),
    ('#0693E3', 'Vivid Cyan Blue'),
    ('#9B51E0', 'Vivid Purple'),
]

# WordPress Shadow Presets
WP_SHADOW_CHOICES = [
    ('natural', 'Natural Shadow'),
    ('deep', 'Deep Shadow'),
    ('sharp', 'Sharp Shadow'),
    ('outlined', 'Outlined Shadow'),
    ('crisp', 'Crisp Shadow'),
]

# WordPress Spacing Presets
WP_SPACING_CHOICES = [
    ('s20', 'Extra Small (7px)'),
    ('s30', 'Small (11px)'),
    ('s40', 'Medium (16px)'),
    ('s50', 'Large (24px)'),
    ('s60', 'Extra Large (36px)'),
    ('s70', 'XX Large (54px)'),
    ('s80', 'XXX Large (81px)'),
]

# WordPress Font Size Presets
WP_FONT_SIZE_CHOICES = [
    ('small', 'Small (13px)'),
    ('medium', 'Medium (20px)'),
    ('large', 'Large (36px)'),
    ('xlarge', 'X-Large (42px)'),
]


class AppAppearance(models.Model):
    """
    Backend-controlled appearance settings using WordPress color palette.
    Supports global (user=None) and per-user customization.
    """
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        null=True,
        blank=True,
        help_text=_("Null means global appearance for all users"),
        related_name='user_appearance'
    )

    # WordPress Color Palette
    primary_color = models.CharField(
        max_length=7,
        default="#0693E3",  # WordPress Vivid Cyan Blue
        choices=WP_COLOR_CHOICES,
        help_text=_("Main brand color from WordPress palette")
    )
    primary_variant = models.CharField(
        max_length=7,
        default="#8ED1FC",  # WordPress Pale Cyan Blue
        choices=WP_COLOR_CHOICES,
        help_text=_("Lighter variant of primary color")
    )
    secondary_color = models.CharField(
        max_length=7,
        default="#9B51E0",  # WordPress Vivid Purple
        choices=WP_COLOR_CHOICES,
        help_text=_("Secondary accent color")
    )
    accent_color = models.CharField(
        max_length=7,
        default="#00D084",  # WordPress Vivid Green Cyan
        choices=WP_COLOR_CHOICES,
        help_text=_("Tertiary accent/action color")
    )
    error_color = models.CharField(
        max_length=7,
        default="#CF2E2E",  # WordPress Vivid Red
        choices=WP_COLOR_CHOICES,
        help_text=_("Error/warning color")
    )
    warning_color = models.CharField(
        max_length=7,
        default="#FCB900",  # WordPress Luminous Vivid Amber
        choices=WP_COLOR_CHOICES,
        help_text=_("Warning color")
    )
    success_color = models.CharField(
        max_length=7,
        default="#00D084",  # WordPress Vivid Green Cyan
        choices=WP_COLOR_CHOICES,
        help_text=_("Success color")
    )

    # Background & surface
    background_color = models.CharField(
        max_length=7,
        default="#FFFFFF",  # WordPress White
        choices=WP_COLOR_CHOICES,
        help_text=_("Main background color")
    )
    surface_color = models.CharField(
        max_length=7,
        default="#F5F5F7",
        help_text=_("Cards, sheets, dialogs background")
    )

    # Text colors
    text_primary = models.CharField(
        max_length=7,
        default="#000000",  # WordPress Black
        choices=WP_COLOR_CHOICES,
        help_text=_("Primary text color")
    )
    text_secondary = models.CharField(
        max_length=7,
        default="#666666",
        help_text=_("Secondary text/muted color")
    )
    text_tertiary = models.CharField(
        max_length=7,
        default="#ABB8C3",  # WordPress Cyan Bluish Gray
        choices=WP_COLOR_CHOICES,
        help_text=_("Tertiary/hint text color")
    )

    # Dark mode preference
    is_dark_mode = models.BooleanField(
        default=False,
        help_text=_("Enable dark mode theme")
    )

    # WordPress Design System Tokens
    shadow_preset = models.CharField(
        max_length=20,
        choices=WP_SHADOW_CHOICES,
        default='natural',
        help_text=_("WordPress shadow style preset")
    )
    
    spacing_preset = models.CharField(
        max_length=20,
        choices=WP_SPACING_CHOICES,
        default='s40',
        help_text=_("Base spacing unit (based on WordPress rem scale)")
    )
    
    font_size_preset = models.CharField(
        max_length=20,
        choices=WP_FONT_SIZE_CHOICES,
        default='medium',
        help_text=_("Base font size preset")
    )

    # Custom font (for future extension)
    font_family = models.CharField(
        max_length=100,
        default="Roboto",
        blank=True,
        help_text=_("Primary font family (Google Font name)")
    )
    
    font_family_secondary = models.CharField(
        max_length=100,
        default="Open Sans",
        blank=True,
        help_text=_("Secondary font family for headings")
    )
    
    font_size_multiplier = models.FloatField(
        default=1.0,
        help_text=_("Font size multiplier (0.8 to 1.5)")
    )

    # Logo and branding
    logo_url = models.URLField(
        blank=True,
        null=True,
        help_text=_("URL to main logo image")
    )
    
    logo_dark_url = models.URLField(
        blank=True,
        null=True,
        help_text=_("URL to dark mode logo")
    )
    
    favicon_url = models.URLField(
        blank=True,
        null=True,
        help_text=_("URL to favicon")
    )

    # Additional theme options
    border_radius = models.CharField(
        max_length=20,
        default="medium",
        choices=[
            ('none', 'No Radius'),
            ('small', 'Small (4px)'),
            ('medium', 'Medium (8px)'),
            ('large', 'Large (16px)'),
            ('full', 'Full (50%)'),
        ],
        help_text=_("Border radius style")
    )
    
    button_style = models.CharField(
        max_length=20,
        default="rounded",
        choices=[
            ('flat', 'Flat'),
            ('rounded', 'Rounded'),
            ('pill', 'Pill'),
            ('outlined', 'Outlined'),
        ],
        help_text=_("Button style preset")
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'frontend_appearance_settings'
        verbose_name = _("App Appearance")
        verbose_name_plural = _("App Appearances")
        unique_together = ('user',)  # One per user + one global

    def __str__(self):
        if self.user:
            return f"Appearance for {self.user.username}"
        return "Global App Appearance"

    @classmethod
    def get_current(cls, user=None):
        """
        Helper: Get current appearance (user > global > default)
        """
        appearance = cls.objects.filter(user=user).first()
        if appearance:
            return appearance

        global_appearance = cls.objects.filter(user__isnull=True).first()
        if global_appearance:
            return global_appearance

        # Ultimate fallback (WordPress default values)
        return cls()

    def get_spacing_value(self, preset=None):
        """Convert spacing preset to pixel value"""
        if not preset:
            preset = self.spacing_preset
            
        spacing_map = {
            's20': 7.0,   # 0.44rem ≈ 7px
            's30': 11.0,  # 0.67rem ≈ 11px
            's40': 16.0,  # 1rem ≈ 16px
            's50': 24.0,  # 1.5rem ≈ 24px
            's60': 36.0,  # 2.25rem ≈ 36px
            's70': 54.0,  # 3.38rem ≈ 54px
            's80': 81.0,  # 5.06rem ≈ 81px
        }
        return spacing_map.get(preset, 16.0)

    def get_font_size_value(self, preset=None):
        """Convert font size preset to pixel value"""
        if not preset:
            preset = self.font_size_preset
            
        font_map = {
            'small': 13.0,
            'medium': 20.0,
            'large': 36.0,
            'xlarge': 42.0,
        }
        return font_map.get(preset, 20.0)


class ThemePreset(models.Model):
    """
    WordPress theme preset collections for quick switching
    """
    WP_PRESETS = [
        ('wp_default', 'WordPress Default (Vivid Cyan Blue)'),
        ('wp_vivid', 'WordPress Vivid (Orange/Red)'),
        ('wp_pastel', 'WordPress Pastel (Soft Colors)'),
        ('wp_dark', 'WordPress Dark (Dark Mode)'),
        ('wp_professional', 'WordPress Professional (Blue/Purple)'),
        ('wp_energetic', 'WordPress Energetic (Orange/Amber)'),
        ('wp_nature', 'WordPress Nature (Green/Cyan)'),
        ('custom', 'Custom Theme'),
    ]
    
    name = models.CharField(max_length=100)
    preset_type = models.CharField(max_length=20, choices=WP_PRESETS, default='wp_default')
    description = models.TextField(blank=True)
    
    # Color scheme from WordPress palette
    primary_color = models.CharField(max_length=7, default='#0693E3', choices=WP_COLOR_CHOICES)
    primary_variant = models.CharField(max_length=7, default='#8ED1FC', choices=WP_COLOR_CHOICES)
    secondary_color = models.CharField(max_length=7, default='#9B51E0', choices=WP_COLOR_CHOICES)
    accent_color = models.CharField(max_length=7, default='#00D084', choices=WP_COLOR_CHOICES)
    background_color = models.CharField(max_length=7, default='#FFFFFF', choices=WP_COLOR_CHOICES)
    text_primary = models.CharField(max_length=7, default='#000000', choices=WP_COLOR_CHOICES)
    
    # Design tokens
    shadow_type = models.CharField(max_length=20, choices=WP_SHADOW_CHOICES, default='natural')
    spacing_scale = models.CharField(max_length=20, choices=WP_SPACING_CHOICES, default='s40')
    font_size = models.CharField(max_length=20, choices=WP_FONT_SIZE_CHOICES, default='medium')
    
    # Theme metadata
    thumbnail_url = models.URLField(blank=True, null=True)
    is_active = models.BooleanField(default=False)
    is_recommended = models.BooleanField(default=False)
    sort_order = models.IntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'frontend_theme_presets'
        verbose_name = _("Theme Preset")
        verbose_name_plural = _("Theme Presets")
        ordering = ['sort_order', 'name']

    def __str__(self):
        return f"{self.name} ({self.get_preset_type_display()})"
    
    def apply_to_appearance(self, appearance):
        """Apply this preset to an AppAppearance instance"""
        appearance.primary_color = self.primary_color
        appearance.primary_variant = self.primary_variant
        appearance.secondary_color = self.secondary_color
        appearance.accent_color = self.accent_color
        appearance.background_color = self.background_color
        appearance.text_primary = self.text_primary
        appearance.shadow_preset = self.shadow_type
        appearance.spacing_preset = self.spacing_scale
        appearance.font_size_preset = self.font_size
        appearance.save()
        return appearance
    
    @classmethod
    def seed_default_presets(cls):
        """Create default WordPress theme presets"""
        default_presets = [
            {
                'name': 'WordPress Default',
                'preset_type': 'wp_default',
                'description': 'Standard WordPress color scheme with Vivid Cyan Blue',
                'primary_color': '#0693E3',
                'primary_variant': '#8ED1FC',
                'secondary_color': '#9B51E0',
                'accent_color': '#00D084',
                'background_color': '#FFFFFF',
                'text_primary': '#000000',
                'is_recommended': True,
                'sort_order': 1,
            },
            {
                'name': 'WordPress Vivid',
                'preset_type': 'wp_vivid',
                'description': 'Bright and energetic orange/red theme',
                'primary_color': '#FF6900',
                'primary_variant': '#FCB900',
                'secondary_color': '#CF2E2E',
                'accent_color': '#F78DA7',
                'background_color': '#FFFFFF',
                'text_primary': '#000000',
                'is_recommended': False,
                'sort_order': 2,
            },
            {
                'name': 'WordPress Pastel',
                'preset_type': 'wp_pastel',
                'description': 'Soft pastel colors for a gentle look',
                'primary_color': '#8ED1FC',
                'primary_variant': '#F78DA7',
                'secondary_color': '#7BDCB5',
                'accent_color': '#FCB900',
                'background_color': '#FFFFFF',
                'text_primary': '#000000',
                'is_recommended': False,
                'sort_order': 3,
            },
            {
                'name': 'WordPress Dark',
                'preset_type': 'wp_dark',
                'description': 'Dark mode with vibrant accents',
                'primary_color': '#0693E3',
                'primary_variant': '#8ED1FC',
                'secondary_color': '#9B51E0',
                'accent_color': '#00D084',
                'background_color': '#121212',
                'text_primary': '#FFFFFF',
                'is_recommended': False,
                'sort_order': 4,
            },
        ]
        
        for preset_data in default_presets:
            cls.objects.get_or_create(
                name=preset_data['name'],
                defaults=preset_data
            )