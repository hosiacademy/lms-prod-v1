# apps/localization/models.py
from django.db import models
from django.utils.translation import gettext_lazy as _
from django.contrib.auth import get_user_model

User = get_user_model()


class Language(models.Model):
    """
    Language model mapped to the existing 'languages' table in hosiacademylms database.
    Enhanced with Afrocentric context in mind — supporting Africa's rich linguistic diversity.
    """

    code = models.CharField(
        max_length=191,
        unique=True,
        help_text=_("ISO 639-1 or 639-2 language code (e.g., 'sw' for Swahili, 'yo' for Yorùbá)")
    )
    name = models.CharField(
        max_length=191,
        help_text=_("English name of the language")
    )
    native = models.CharField(
        max_length=191,
        help_text=_("Name in the native language (e.g., 'Kiswahili', 'Èdè Yorùbá')")
    )
    rtl = models.SmallIntegerField(
        default=0,
        choices=((0, 'Left-to-Right'), (1, 'Right-to-Left')),
        help_text=_("1 = Right-to-Left (e.g., Arabic, Geʽez for Amharic/Tigrinya)")
    )
    status = models.SmallIntegerField(
        default=1,
        choices=((0, 'Disabled'), (1, 'Active')),
        help_text=_("Is this language available in the LMS?")
    )
    json_exist = models.SmallIntegerField(
        default=0,
        choices=((0, 'Missing'), (1, 'Translation files present')),
        help_text=_("Do translation JSON files exist for this language?")
    )

    created_at = models.DateTimeField(auto_now_add=True, null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True, null=True, blank=True)

    class Meta:
        db_table = 'languages'  # Maps directly to existing Infix LMS table
        verbose_name = _("Language")
        verbose_name_plural = _("Languages")
        ordering = ['name']

    def __str__(self):
        return f"{self.native or self.name} ({self.code.upper()})"

    # Afrocentric helper properties (used in admin & API)
    def is_african_origin(self):
        """Quick flag for African indigenous/original languages"""
        african_codes = ['sw', 'yo', 'ig', 'ha', 'zu', 'xh', 'am', 'om', 'ti', 'rw', 'ln', 'ak', 'sn', 'so']
        return self.code.lower()[:2] in african_codes

    def get_script_name(self):
        scripts = {
            'am': 'Geʽez (ግዕዝ)',
            'ti': 'Geʽez',
            'ar': 'Arabic script (عربي)',
            'ha': 'Latin + Ajami (عجمي)',
            'yo': 'Latin with diacritics',
            'sw': 'Latin',
            'zu': 'Latin',
            'rw': 'Latin',
        }
        return scripts.get(self.code.lower()[:2], 'Latin')

    def get_primary_countries(self):
        """Returns list of country codes where this is official/widely used"""
        countries = {
            'sw': ['TZ', 'KE', 'UG', 'CD', 'RW'],
            'ha': ['NG', 'NE', 'GH'],
            'yo': ['NG', 'BJ'],
            'ig': ['NG'],
            'am': ['ET'],
            'om': ['ET'],
            'ti': ['ER', 'ET'],
            'zu': ['ZA'],
            'xh': ['ZA'],
            'af': ['ZA', 'NA'],
            'ar': ['EG', 'MA', 'DZ', 'TN', 'SD', 'LY'],
            'fr': ['SN', 'CI', 'CM', 'BF', 'ML', 'NE', 'TG'],
            'pt': ['AO', 'MZ', 'GW', 'CV', 'ST'],
            'rw': ['RW'],
            'ln': ['CD', 'CG'],
            'ak': ['GH'],
            'sn': ['ZW', 'ZA'],
            'so': ['SO', 'ET'],
            'en': ['NG', 'KE', 'ZA', 'GH', 'UG', 'ZW', 'RW'],
        }
        return countries.get(self.code.lower()[:2], [])


class Country(models.Model):
    """
    Countries with Afro-centric focus (e.g., South Africa, Nigeria, Kenya).
    Used for country-sensitive LMS customizations.
    """
    code = models.CharField(
        max_length=2,
        unique=True,
        help_text=_("ISO 3166-1 alpha-2 code, e.g., 'ZA', 'NG', 'KE'")
    )
    name = models.CharField(max_length=100, help_text=_("Full country name"))
    is_active = models.BooleanField(default=True)
    phone_code = models.CharField(
        max_length=10,
        blank=True,
        null=True,
        help_text=_("Country phone calling code (e.g., '+27')")
    )

    class Meta:
        db_table = 'localization_countries'
        verbose_name = _("Country")
        verbose_name_plural = _("Countries")
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.code})"


class State(models.Model):
    """
    States/Provinces/Regions within countries.
    Enables cascading location selection: Country → State → City
    """
    country = models.ForeignKey(
        Country,
        on_delete=models.CASCADE,
        related_name='states',
        help_text=_("Country this state belongs to")
    )
    name = models.CharField(
        max_length=100,
        help_text=_("State/Province/Region name")
    )
    code = models.CharField(
        max_length=10,
        blank=True,
        help_text=_("Optional state code (e.g., 'GP' for Gauteng)")
    )
    is_active = models.BooleanField(default=True)

    class Meta:
        db_table = 'localization_states'
        verbose_name = _("State")
        verbose_name_plural = _("States")
        ordering = ['country', 'name']
        unique_together = ('country', 'name')

    def __str__(self):
        return f"{self.name}, {self.country.code}"


class City(models.Model):
    """
    Cities/Towns within states.
    Enables full cascading: Country → State → City
    """
    state = models.ForeignKey(
        State,
        on_delete=models.CASCADE,
        related_name='cities',
        null=True,
        blank=True,
        help_text=_("State this city belongs to")
    )
    name = models.CharField(
        max_length=100,
        help_text=_("City/Town name")
    )
    is_active = models.BooleanField(default=True)
    population = models.IntegerField(
        null=True,
        blank=True,
        help_text=_("Approximate population (for sorting/prioritization)")
    )

    class Meta:
        db_table = 'localization_cities'
        verbose_name = _("City")
        verbose_name_plural = _("Cities")
        ordering = ['state', '-population', 'name']
        unique_together = ('state', 'name')

    def __str__(self):
        return f"{self.name}, {self.state.name}"

    @property
    def country(self):
        """Helper to get country directly from city"""
        return self.state.country



class CountryOverride(models.Model):
    """
    Country-specific nuances for "country sensitive" LMS.
    Examples:
    - ZA: 'Sawubona!' greeting, Youth Day (16 June) banner, green/gold/red colors
    - NG: Yoruba/Igbo/Hausa greetings, Independence Day theme
    - KE: Swahili greeting, Jamhuri Day banner
    Overrides appearance/themes from frontend_manage.
    """
    country = models.OneToOneField(
        Country,
        on_delete=models.CASCADE,
        related_name='override',
        help_text=_("One override per country")
    )

    # Link to appearance override (colors, mode, etc.)
    appearance = models.ForeignKey(
        'frontend_manage.AppAppearance',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        help_text=_("Optional color/mode override for this country")
    )

    # Cultural & Country-Specific Elements
    greeting_message = models.CharField(
        max_length=200,
        blank=True,
        help_text=_("Country-specific greeting (e.g., 'Sawubona!' for ZA)")
    )
    holiday_banner_url = models.URLField(
        blank=True,
        help_text=_("Banner for national holidays (e.g., Youth Day image for ZA)")
    )
    holiday_date = models.DateField(
        blank=True,
        null=True,
        help_text=_("Primary national holiday date (e.g., 16 June for ZA)")
    )
    cultural_note = models.TextField(
        blank=True,
        help_text=_("Brief note on cultural elements (e.g., 'Celebrate African Unity!')")
    )

    # Language tie-in
    default_language = models.ForeignKey(
        Language,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        help_text=_("Recommended default language for this country")
    )

    is_default = models.BooleanField(
        default=False,
        help_text=_("Use this as fallback when no country is detected")
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'localization_country_overrides'
        verbose_name = _("Country Override")
        verbose_name_plural = _("Country Overrides")

    def __str__(self):
        return f"Override for {self.country.name}"

    def save(self, *args, **kwargs):
        if self.is_default:
            CountryOverride.objects.filter(is_default=True).exclude(id=self.id).update(is_default=False)
        super().save(*args, **kwargs)

    @classmethod
    def get_current(cls, country_code):
        """Helper: Get override for given country code (fallback to default)"""
        country = Country.objects.filter(code=country_code.upper()).first()
        if country:
            override = cls.objects.filter(country=country).first()
            if override:
                return override

        # Fallback to default override (if any)
        return cls.objects.filter(is_default=True).first()


class Translation(models.Model):
    """
    Key-value translations for strings, per language.
    e.g., key: 'welcome_message' → value: 'Sawubona!' (Zulu)
    """
    key = models.CharField(max_length=191, help_text=_("Unique key, e.g., 'welcome_message'"))
    language = models.ForeignKey(Language, on_delete=models.CASCADE, related_name='translations')
    value = models.TextField(help_text=_("Translated text, supports placeholders"))
    description = models.TextField(blank=True, help_text=_("Context for translators"))

    class Meta:
        db_table = 'localization_translations'
        verbose_name = _("Translation")
        verbose_name_plural = _("Translations")
        unique_together = ('key', 'language')

    def __str__(self):
        return f"{self.key} ({self.language.code})"


class LocalizedPromotion(models.Model):
    """
    Country-specific promotions shown as animated flyers on the onboarding page.
    Supports discount percentages, limited-time offers, seasonal campaigns, etc.
    """
    PROMOTION_TYPES = [
        ('discount', 'Discount/Sale'),
        ('free_course', 'Free Course'),
        ('bundle', 'Bundle Offer'),
        ('limited_time', 'Limited Time Offer'),
        ('seasonal', 'Seasonal Campaign'),
        ('partnership', 'Partnership Offer'),
        ('referral', 'Referral Program'),
        ('other', 'Other'),
    ]

    title = models.CharField(max_length=200, help_text=_("Promotion title (e.g., '50% Off AI Courses')"))
    native_title = models.CharField(max_length=200, blank=True, help_text=_("Title in native language"))
    description = models.TextField(help_text=_("Promotion description and details"))
    native_description = models.TextField(blank=True, help_text=_("Description in native language"))
    promotion_type = models.CharField(max_length=50, choices=PROMOTION_TYPES, default='discount')

    image = models.ImageField(upload_to='promotions/', blank=True, null=True,
                              help_text=_("Upload promotion banner image"))
    image_url = models.URLField(blank=True, help_text=_("Or provide external image URL"))
    background_color = models.CharField(max_length=7, default='#FF5722',
                                        help_text=_("Banner background color (hex code)"))
    text_color = models.CharField(max_length=7, default='#FFFFFF',
                                  help_text=_("Text color (hex code)"))
    icon = models.CharField(max_length=50, blank=True,
                            help_text=_("Icon/emoji for promotion (e.g., '🎉', '💰', '🎓')"))

    discount_percentage = models.DecimalField(
        max_digits=5, decimal_places=2, null=True, blank=True,
        help_text=_("Discount percentage to apply at checkout (e.g., 20.00 for 20% off)")
    )

    cta_text = models.CharField(max_length=100, default='Learn More',
                                help_text=_("Call-to-action button text"))
    cta_url = models.URLField(blank=True, help_text=_("Link when user clicks the promotion"))

    start_date = models.DateField(help_text=_("Promotion starts on this date"))
    end_date = models.DateField(help_text=_("Promotion ends on this date"))
    priority = models.IntegerField(default=0, help_text=_("Higher priority promotions show first (0-100)"))

    show_on_splash = models.BooleanField(default=False, help_text=_("Show on splash screen"))
    show_on_home = models.BooleanField(default=True, help_text=_("Show on home page"))
    show_on_onboarding = models.BooleanField(default=True, help_text=_("Show during onboarding"))

    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    countries = models.ManyToManyField(
        Country, related_name='promotions',
        help_text=_("Countries where this promotion is visible")
    )
    created_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True,
        related_name='created_promotions'
    )

    class Meta:
        db_table = 'localized_promotions'
        verbose_name = _("Localized Promotion")
        verbose_name_plural = _("Localized Promotions")
        ordering = ['-priority', '-start_date']
        indexes = [
            models.Index(fields=['start_date', 'end_date']),
            models.Index(fields=['-priority']),
        ]

    def __str__(self):
        return f"{self.title} ({self.promotion_type})"

    @property
    def is_currently_active(self):
        from django.utils import timezone
        today = timezone.now().date()
        return self.is_active and self.start_date <= today <= self.end_date


class LocalizedAnnouncement(models.Model):
    """
    Country-specific announcements shown as pop-ups or banners.
    """
    ANNOUNCEMENT_TYPES = [
        ('info', 'Information'),
        ('warning', 'Warning'),
        ('success', 'Success/Good News'),
        ('update', 'Platform Update'),
        ('maintenance', 'Maintenance'),
        ('partnership', 'Partnership Announcement'),
        ('new_feature', 'New Feature'),
        ('event', 'Event Announcement'),
    ]

    title = models.CharField(max_length=200, help_text=_("Announcement title"))
    native_title = models.CharField(max_length=200, blank=True, help_text=_("Title in native language"))
    message = models.TextField(help_text=_("Announcement message"))
    native_message = models.TextField(blank=True, help_text=_("Message in native language"))
    announcement_type = models.CharField(max_length=50, choices=ANNOUNCEMENT_TYPES, default='info')

    image = models.ImageField(upload_to='announcements/', blank=True, null=True,
                              help_text=_("Upload announcement banner image"))
    icon = models.CharField(max_length=50, blank=True,
                            help_text=_("Icon/emoji (e.g., 'ℹ️', '⚠️', '✅', '📢')"))
    background_color = models.CharField(max_length=7, default='#2196F3',
                                        help_text=_("Background color (hex code)"))
    text_color = models.CharField(max_length=7, default='#FFFFFF',
                                  help_text=_("Text color (hex code)"))

    action_text = models.CharField(max_length=100, blank=True,
                                   help_text=_("Optional action button text"))
    action_url = models.URLField(blank=True, help_text=_("Optional link for action button"))

    start_date = models.DateField(help_text=_("Show announcement starting from this date"))
    end_date = models.DateField(null=True, blank=True,
                                help_text=_("Stop showing after this date (leave empty for indefinite)"))
    priority = models.IntegerField(default=0, help_text=_("Higher priority announcements show first (0-100)"))

    show_on_splash = models.BooleanField(default=False)
    show_on_onboarding = models.BooleanField(default=True)
    show_on_home = models.BooleanField(default=True)

    is_dismissible = models.BooleanField(default=True)
    require_acknowledgment = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    countries = models.ManyToManyField(
        Country, related_name='announcements', blank=True,
        help_text=_("Countries where visible (leave empty for all countries)")
    )
    created_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True,
        related_name='created_announcements'
    )

    class Meta:
        db_table = 'localized_announcements'
        verbose_name = _("Localized Announcement")
        verbose_name_plural = _("Localized Announcements")
        ordering = ['-priority', '-start_date']

    def __str__(self):
        return f"{self.title} ({self.announcement_type})"