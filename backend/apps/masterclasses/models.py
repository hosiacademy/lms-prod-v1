# apps/masterclasses/models.py
from decimal import Decimal
from django.db import models
from django.utils import timezone
from django.core.validators import MinValueValidator
from apps.aicerts_courses.models import AiCertsCourse

# African countries (ISO 3166-1 alpha-2 codes + names)
AFRICAN_COUNTRIES = [
    ('DZ', 'Algeria'), ('AO', 'Angola'), ('BJ', 'Benin'), ('BW', 'Botswana'),
    ('BF', 'Burkina Faso'), ('BI', 'Burundi'), ('CV', 'Cape Verde'), ('CM', 'Cameroon'),
    ('CF', 'Central African Republic'), ('TD', 'Chad'), ('KM', 'Comoros'), ('CG', 'Congo'),
    ('CD', 'Democratic Republic of the Congo'), ('CI', "Côte d'Ivoire"), ('DJ', 'Djibouti'),
    ('EG', 'Egypt'), ('GQ', 'Equatorial Guinea'), ('ER', 'Eritrea'), ('SZ', 'Eswatini'),
    ('ET', 'Ethiopia'), ('GA', 'Gabon'), ('GM', 'Gambia'), ('GH', 'Ghana'),
    ('GN', 'Guinea'), ('GW', 'Guinea-Bissau'), ('KE', 'Kenya'), ('LS', 'Lesotho'),
    ('LR', 'Liberia'), ('LY', 'Libya'), ('MG', 'Madagascar'), ('MW', 'Malawi'),
    ('ML', 'Mali'), ('MR', 'Mauritania'), ('MU', 'Mauritius'), ('MA', 'Morocco'),
    ('MZ', 'Mozambique'), ('NA', 'Namibia'), ('NE', 'Niger'), ('NG', 'Nigeria'),
    ('RW', 'Rwanda'), ('ST', 'São Tomé and Príncipe'), ('SN', 'Senegal'), ('SC', 'Seychelles'),
    ('SL', 'Sierra Leone'), ('SO', 'Somalia'), ('ZA', 'South Africa'), ('SS', 'South Sudan'),
    ('SD', 'Sudan'), ('TZ', 'Tanzania'), ('TG', 'Togo'), ('TN', 'Tunisia'),
    ('UG', 'Uganda'), ('ZM', 'Zambia'), ('ZW', 'Zimbabwe')
]

class Masterclass(models.Model):
    """Hosi Academy Masterclass - can map to provider courses"""

    STATUS_CHOICES = [
        ('scheduled', 'Scheduled'),
        ('ongoing', 'Ongoing'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    ]

    STREAM_TYPE_CHOICES = [
        ('professional', 'Professional'),
        ('technical', 'Technical'),
    ]

    TIER_CHOICES = [
        ('basic', 'Basic'),
        ('standard', 'Standard'),
        ('premium', 'Premium'),
    ]

    # ===== BASIC INFO =====
    title = models.CharField(max_length=255)
    slug = models.SlugField(unique=True, max_length=500)
    description = models.TextField(blank=True)
    category = models.CharField(max_length=255, blank=True, help_text="Auto-filled from selected AICERTS courses")
    
    # ===== FRONTEND FILTERING FIELDS =====
    stream_type = models.CharField(
        max_length=20,
        choices=STREAM_TYPE_CHOICES,
        default='professional',
        help_text="Type of masterclass for filtering"
    )
    
    tier = models.CharField(
        max_length=20,
        choices=TIER_CHOICES,
        default='standard',
        blank=True,
        null=True,
        help_text="Tier/level of the masterclass"
    )
    
    focus_area = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        help_text="Area of focus (e.g., AI Strategy, Blockchain Development)"
    )

    # ===== LOCATION FIELDS =====
    country_code = models.CharField(
        max_length=2,
        choices=AFRICAN_COUNTRIES,
        blank=True,
        null=True,
        verbose_name="Country Code",
        help_text="ISO 3166-1 alpha-2 country code"
    )
    
    country_name = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        verbose_name="Country Name",
        help_text="Full country name"
    )
    
    city = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        help_text="City where masterclass is held"
    )
    
    venue = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        help_text="Specific venue or address"
    )
    
    # Legacy field kept for backward compatibility
    locations = models.JSONField(
        default=list,
        blank=True,
        help_text="Legacy field: List of countries with their cities"
    )

    # ===== DATES =====
    start_date = models.DateField()
    end_date = models.DateField()

    # ===== PRICING =====
    price_physical = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0)],
        help_text="Physical attendance price in USD"
    )
    price_online = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(0)],
        help_text="Online attendance price in USD"
    )
    currency = models.CharField(max_length=3, default='USD')

    # ===== STATUS =====
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='scheduled'
    )
    is_featured = models.BooleanField(default=False)
    has_online_option = models.BooleanField(
        default=True,
        help_text="Whether this masterclass can be attended online"
    )

    # ===== CAPACITY =====
    max_participants = models.PositiveIntegerField(default=35)
    current_participants = models.PositiveIntegerField(default=0)

    # ===== INSTRUCTOR =====
    instructor = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='taught_masterclasses',
        verbose_name="Assigned Instructor",
        help_text="The instructor assigned to teach this masterclass"
    )

    # ===== RELATIONSHIPS =====
    provider_courses = models.ManyToManyField(
        AiCertsCourse,
        related_name='masterclasses',
        blank=True,
        verbose_name="Linked Provider Courses (AICERTS)"
    )

    # ===== ADDITIONAL INFO =====
    notes = models.TextField(blank=True)

    # ===== TIMESTAMPS =====
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['start_date', 'title']
        verbose_name = "Masterclass"
        verbose_name_plural = "Masterclasses"

    def __str__(self):
        return f"{self.title} - {self.get_status_display()}"

    def save(self, *args, **kwargs):
        # Auto-populate category from selected AICERTS courses (only if already saved)
        if self.pk and self.provider_courses:
            try:
                categories = set(course.category_name for course in self.provider_courses.all() if course.category_name)
                self.category = ", ".join(sorted(categories)) if categories else ""
            except:
                pass

        # Auto-populate country_name from country_code if not set
        if self.country_code and not self.country_name:
            self.country_name = dict(AFRICAN_COUNTRIES).get(self.country_code, self.country_code)

        # Keep backward compatibility: populate locations if empty
        if not self.locations and self.country_code and self.city:
            self.locations = [{
                'country': self.country_code,
                'cities': [self.city]
            }]

        super().save(*args, **kwargs)

    # ===== PROPERTIES =====
    @property
    def price(self):
        """Legacy price property - returns price_online for API compatibility"""
        return self.price_online

    @property
    def duration_days(self):
        """Calculate duration in days"""
        if self.start_date and self.end_date:
            return (self.end_date - self.start_date).days + 1
        return None

    @property
    def seats_remaining(self):
        """Calculate available seats"""
        return max(0, self.max_participants - self.current_participants)

    @property
    def is_full(self):
        """Check if masterclass is full"""
        return self.current_participants >= self.max_participants

    @property
    def formatted_price(self):
        """Format physical price with currency"""
        return f"{self.currency} {self.price_physical:,.2f}"

    @property
    def online_price(self):
        """Return online price as stored in database"""
        return float(self.price_online)

    @property
    def physical_price(self):
        """Return physical price as stored in database"""
        return float(self.price_physical)

    @property
    def location_display(self):
        """Display location in readable format"""
        if self.city and self.country_name:
            return f"{self.city}, {self.country_name}"
        elif self.locations:
            # Legacy display
            display = []
            for loc in self.locations:
                country_name = dict(AFRICAN_COUNTRIES).get(loc.get('country'), loc.get('country'))
                cities = ", ".join(loc.get('cities', []))
                display.append(f"{cities} ({country_name})")
            return "; ".join(display)
        return "Location not set"

    @property
    def is_upcoming(self):
        """Check if masterclass is upcoming"""
        return self.start_date > timezone.now().date()

    @property
    def is_past(self):
        """Check if masterclass is past"""
        return self.end_date < timezone.now().date()

    @property
    def is_ongoing(self):
        """Check if masterclass is currently ongoing"""
        today = timezone.now().date()
        return self.start_date <= today <= self.end_date