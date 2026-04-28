# apps/users/models.py

from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils.translation import gettext_lazy as _


class User(AbstractUser):
    """
    Custom User model mapped directly to the existing 'users' table in hosiacademylms.
    Replaces Django's default auth_user table.
    Full compatibility with existing Infix LMS data + optional AiCerts/Moodle sync fields.
    """

    # === Core Infix LMS Fields (exact match to existing table) ===
    role_id = models.IntegerField(
        default=3,
        help_text=_("1=Admin, 2=Instructor, 3=Student")
    )
    name = models.CharField(
        max_length=191,
        blank=True,
        null=True,
        verbose_name=_("Full Name")
    )
    photo = models.CharField(max_length=191, blank=True, null=True)
    image = models.CharField(max_length=191, blank=True, null=True, verbose_name=_("Profile Image"))
    avatar = models.CharField(max_length=191, blank=True, null=True)

    mobile_verified_at = models.DateTimeField(blank=True, null=True)
    email_verified_at = models.DateTimeField(blank=True, null=True)

    notification_preference = models.CharField(max_length=191, default='mail')
    email_verify = models.CharField(max_length=191, default='0')  # '0'=unverified, '1'=verified

    headline = models.CharField(max_length=191, blank=True, null=True)
    phone = models.CharField(max_length=100, blank=True, null=True)
    address = models.CharField(max_length=191, blank=True, null=True)
    
    # Location fields (hierarchical)
    country = models.ForeignKey(
        'localization.Country',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='users',
        verbose_name=_("Country")
    )
    state = models.ForeignKey(
        'localization.State',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='users',
        verbose_name=_("State/Province")
    )
    city = models.ForeignKey(
        'localization.City',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='users',
        verbose_name=_("City")
    )
    
    zip = models.CharField(max_length=191, blank=True, null=True)
    dob = models.CharField(max_length=191, blank=True, null=True, help_text=_("Date of birth as string"))

    about = models.TextField(blank=True, null=True, verbose_name=_("About Me"))
    short_details = models.TextField(blank=True, null=True)

    # Social Links
    facebook = models.CharField(max_length=191, blank=True, null=True)
    twitter = models.CharField(max_length=191, blank=True, null=True)
    linkedin = models.CharField(max_length=191, blank=True, null=True)
    instagram = models.CharField(max_length=191, blank=True, null=True)
    youtube = models.CharField(max_length=191, blank=True, null=True)

    subscribe = models.IntegerField(default=0)
    provider = models.CharField(max_length=191, blank=True, null=True, help_text=_("OAuth provider: google, facebook, etc."))
    provider_id = models.CharField(max_length=191, blank=True, null=True)

    # Language (from Infix)
    language_id = models.CharField(max_length=191, default='19')
    language_code = models.CharField(max_length=191, default='en')
    language_name = models.CharField(max_length=191, default='English')

    # Financial / Instructor
    balance = models.FloatField(default=0.0)
    hourly_rate = models.DecimalField(
        decimal_places=2,
        default=0.00,
        max_digits=10,
        verbose_name=_("Hourly Rate")
    )
    currency_id = models.IntegerField(default=112)
    special_commission = models.IntegerField(default=1)

    payout = models.CharField(max_length=191, default='PayPal')
    payout_icon = models.CharField(max_length=191, default='public/uploads/payout/pay_1.png')
    payout_email = models.CharField(max_length=191, default='demo@paypal.com')

    # Zoom
    zoom_api_key_of_user = models.CharField(max_length=191, blank=True, null=True)
    zoom_api_serect_of_user = models.CharField(max_length=191, blank=True, null=True)  # typo preserved

    remember_token = models.CharField(max_length=100, blank=True, null=True)

    # Bank Details (Instructor Payouts)
    bank_name = models.CharField(max_length=191, blank=True, null=True)
    branch_name = models.CharField(max_length=191, blank=True, null=True)
    bank_account_number = models.CharField(max_length=191, blank=True, null=True)
    account_holder_name = models.CharField(max_length=191, blank=True, null=True)
    bank_type = models.CharField(max_length=191, blank=True, null=True)

    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True, null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True, null=True, blank=True)

    # === Optional: AiCerts / Moodle Sync Fields ===
    # These are preserved for future or ongoing sync with AiCerts (Moodle-based)
    fullname = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Full Name (AiCerts)"))
    phone1 = models.CharField(max_length=20, blank=True, null=True, verbose_name=_("Phone 1"))
    phone2 = models.CharField(max_length=20, blank=True, null=True, verbose_name=_("Phone 2"))
    department = models.CharField(max_length=255, blank=True, null=True)
    institution = models.CharField(max_length=255, blank=True, null=True)
    idnumber = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("ID Number"))
    interests = models.TextField(blank=True, null=True)
    firstaccess = models.PositiveIntegerField(blank=True, null=True, help_text=_("Unix timestamp"))
    lastaccess = models.PositiveIntegerField(blank=True, null=True, help_text=_("Unix timestamp"))
    auth = models.CharField(max_length=255, default='manual')
    suspended = models.BooleanField(default=False)
    confirmed = models.BooleanField(default=True)
    lang = models.CharField(max_length=30, default='en')
    theme = models.CharField(max_length=50, blank=True, null=True)
    timezone = models.CharField(max_length=100, default='UTC')
    mailformat = models.PositiveSmallIntegerField(default=1)
    description = models.TextField(blank=True, null=True)
    descriptionformat = models.PositiveSmallIntegerField(default=1)
    profileimageurlsmall = models.URLField(max_length=255, blank=True, null=True)
    profileimageurl = models.URLField(max_length=255, blank=True, null=True)
    partner_id = models.PositiveIntegerField(blank=True, null=True)
    source = models.CharField(max_length=100, blank=True, null=True, verbose_name=_("Source: sso, aicerts, etc."))

    is_aicerts_instructor = models.BooleanField(default=False, verbose_name=_("Is AiCerts Instructor"))
    aicerts_user_id = models.PositiveIntegerField(blank=True, null=True, verbose_name=_("AiCerts User ID"))
    aicerts_synced_at = models.DecimalField(max_digits=20, decimal_places=4, blank=True, null=True, verbose_name=_("AiCerts Sync Timestamp"))
    
    # Relationship to AICerts courses they can instruct
    aicerts_instructor_courses = models.ManyToManyField(
        'aicerts_courses.AiCertsCourse',
        through='aicerts_integration.AICertsInstructorDesignation',
        through_fields=('instructor', 'course'),
        blank=True,
        related_name='instructors'
    )

    class Meta:
        db_table = 'users'
        verbose_name = _("User")
        verbose_name_plural = _("Users")
        ordering = ['-date_joined']

    def __str__(self):
        return self.name or self.get_full_name() or self.username or self.email

    def get_full_name(self):
        return self.name.strip() if self.name else super().get_full_name()

    # Helper properties for common use
    @property
    def display_name(self):
        return self.name or self.username or self.email

    @property
    def is_instructor(self):
        return self.role_id == 2

    @property
    def is_student(self):
        return self.role_id == 3

    @property
    def is_admin(self):
        return self.role_id == 1

    @property
    def admin_role(self):
        """
        Returns the first active AdminRole for this user.
        Used for regional routing and dashboard access.
        """
        return self.admin_roles.filter(is_active=True).first()


class UserThemePreference(models.Model):
    """
    Stores user theme preferences (light/dark mode).
    Synced with frontend for persistent theme across devices.
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='theme_preference',
        verbose_name=_("User")
    )
    theme_mode = models.CharField(
        max_length=20,
        default='dark',
        choices=[
            ('light', 'Light Mode'),
            ('dark', 'Dark Mode'),
            ('system', 'System Default'),
        ],
        verbose_name=_("Theme Mode")
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'user_theme_preferences'
        verbose_name = _("User Theme Preference")
        verbose_name_plural = _("User Theme Preferences")

    def __str__(self):
        return f"{self.user.email} - {self.theme_mode}"

    def is_synced_with_aicerts(self):
        """Check if user has been successfully created on AICERTs LMS"""
        return self.aicerts_user_id is not None

    def get_aicerts_sso_url(self, course_id=None):
        """Generate SSO URL for this user"""
        from apps.aicerts_integration.services import SSOService
        return SSOService.generate_sso_url(self.email, course_id)


class AuthOTP(models.Model):
    """
    Temporary storage for authentication OTP codes.
    """
    identifier = models.CharField(max_length=255, help_text=_("Email or Phone Number"))
    otp = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    is_used = models.BooleanField(default=False)
    expires_at = models.DateTimeField()

    class Meta:
        db_table = 'auth_otps'
        verbose_name = _("Auth OTP")
        verbose_name_plural = _("Auth OTPs")
        ordering = ['-created_at']

    def __str__(self):
        return f"OTP for {self.identifier} - {'Used' if self.is_used else 'Active'}"

    def is_expired(self):
        from django.utils import timezone
        return timezone.now() > self.expires_at