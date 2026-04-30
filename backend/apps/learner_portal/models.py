# apps/learner_portal/models.py
from django.db import models
from django.conf import settings
from django.utils import timezone
from django.utils.translation import gettext_lazy as _
from django.contrib.contenttypes.fields import GenericForeignKey
from django.contrib.contenttypes.models import ContentType


class StudentProfile(models.Model):
    """
    Extended student profile to store enrollment history and payment preferences.

    Tracks:
    - Previous company details (for quick reuse)
    - Previous individual details
    - Payment method preferences
    - Enrollment history
    """

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='student_profile',
        verbose_name=_("User")
    )

    # Core Student Identification
    student_id = models.CharField(
        max_length=50,
        unique=True,
        null=True,
        blank=True,
        verbose_name=_("Student ID"),
        help_text=_("Unique student identifier")
    )

    # Instructor relationship
    instructor = models.ForeignKey(
        'instructors.Instructor',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='students',
        verbose_name=_("Instructor"),
        help_text=_("Primary instructor assigned to this student")
    )

    enrollment_date = models.DateField(
        blank=True,
        null=True,
        default=timezone.now,
        verbose_name=_("Enrollment Date"),
        help_text=_("Date when student first enrolled")
    )

    student_status = models.CharField(
        max_length=30,
        choices=[
            ('provisional', _('Provisional')),
            ('confirmed', _('Confirmed')),
            ('active', _('Active')),
            ('completed', _('Completed')),
            ('dropped_out', _('Dropped Out')),
            ('rejected', _('Rejected')),
        ],
        default='provisional',
        verbose_name=_("Student Status")
    )

    # Contact Information
    phone = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("Phone Number")
    )

    # Personal Identification
    id_number = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("ID Number / Passport Number")
    )
    date_of_birth = models.DateField(
        blank=True,
        null=True,
        verbose_name=_("Date of Birth")
    )
    gender = models.CharField(
        max_length=20,
        blank=True,
        null=True,
        choices=[
            ('male', _('Male')),
            ('female', _('Female')),
            ('non_binary', _('Non-Binary')),
            ('prefer_not_to_say', _('Prefer Not to Say')),
        ],
        verbose_name=_("Gender")
    )

    # Physical Address
    address = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Street Address")
    )
    postal_code = models.CharField(
        max_length=20,
        blank=True,
        null=True,
        verbose_name=_("Postal Code")
    )

    # Emergency Contact
    emergency_contact_name = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        verbose_name=_("Emergency Contact Name")
    )
    emergency_contact_phone = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("Emergency Contact Phone")
    )
    emergency_contact_relationship = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        verbose_name=_("Emergency Contact Relationship")
    )

    # Banking Details
    bank_name = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        verbose_name=_("Bank Name")
    )
    bank_account_number = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("Bank Account Number")
    )
    bank_branch_code = models.CharField(
        max_length=20,
        blank=True,
        null=True,
        verbose_name=_("Bank Branch Code")
    )
    bank_account_type = models.CharField(
        max_length=20,
        blank=True,
        null=True,
        choices=[
            ('savings', _('Savings')),
            ('cheque', _('Cheque/Current')),
        ],
        verbose_name=_("Bank Account Type")
    )
    bank_account_holder_name = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        verbose_name=_("Bank Account Holder Name")
    )

    # Mobile Money
    mobile_money_number = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("Mobile Money Number")
    )
    mobile_money_provider = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("Mobile Money Provider")
    )

    # Current Location/Address
    country = models.ForeignKey(
        'localization.Country',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='students',
        verbose_name=_("Country"),
        help_text=_("Current country of residence")
    )

    state = models.ForeignKey(
        'localization.State',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='students',
        verbose_name=_("State/Region"),
        help_text=_("Current state/region of residence")
    )

    city = models.ForeignKey(
        'localization.City',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='students',
        verbose_name=_("City"),
        help_text=_("Current city of residence")
    )

    # Education and Employment
    highest_qualification = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        verbose_name=_("Highest Qualification")
    )

    qualification_institution = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        verbose_name=_("Qualification Institution")
    )

    qualification_year = models.CharField(
        max_length=10,
        blank=True,
        null=True,
        verbose_name=_("Qualification Year")
    )

    employer = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        verbose_name=_("Employer")
    )

    job_title = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        verbose_name=_("Job Title")
    )

    employment_status = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        choices=[
            ('employed', _('Employed')),
            ('self_employed', _('Self-Employed')),
            ('unemployed', _('Unemployed')),
            ('student', _('Student')),
            ('retired', _('Retired')),
        ],
        verbose_name=_("Employment Status")
    )

    # Demographic Information
    race = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("Race/Ethnicity")
    )

    disability = models.CharField(
        max_length=10,
        blank=True,
        null=True,
        choices=[
            ('none', _('No Disability')),
            ('physical', _('Physical Disability')),
            ('visual', _('Visual Impairment')),
            ('hearing', _('Hearing Impairment')),
            ('cognitive', _('Cognitive Disability')),
            ('other', _('Other')),
        ],
        verbose_name=_("Disability Status")
    )

    nationality = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        verbose_name=_("Nationality")
    )

    # Provider relationship (for self-paced/company-paid courses)
    provider = models.ForeignKey(
        'organizations.Company',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='students',
        verbose_name=_("Provider"),
        help_text=_("Company/provider associated with this student")
    )

    # Previous Company Details (for reuse)
    last_used_company_name = models.CharField(
        max_length=255,
        blank=True,
        verbose_name=_("Last Used Company Name")
    )
    last_used_company_email = models.EmailField(
        blank=True,
        verbose_name=_("Last Used Company Email")
    )
    last_used_company_phone = models.CharField(
        max_length=50,
        blank=True,
        verbose_name=_("Last Used Company Phone")
    )
    last_used_company_address = models.TextField(
        blank=True,
        verbose_name=_("Last Used Company Address")
    )
    last_used_vat_number = models.CharField(
        max_length=50,
        blank=True,
        verbose_name=_("Last Used VAT Number")
    )
    has_company_payment_history = models.BooleanField(
        default=False,
        verbose_name=_("Has Used Company Payment Before"),
        help_text=_("True if student has paid via company before")
    )

    # Location Preferences
    preferred_country = models.ForeignKey(
        'localization.Country',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='preferred_students',
        verbose_name=_("Preferred Country")
    )
    preferred_state = models.ForeignKey(
        'localization.State',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='preferred_students',
        verbose_name=_("Preferred State/Region")
    )
    preferred_city = models.ForeignKey(
        'localization.City',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='preferred_students',
        verbose_name=_("Preferred City")
    )

    # Payment Preferences
    preferred_payment_provider = models.CharField(
        max_length=50,
        blank=True,
        verbose_name=_("Preferred Payment Provider"),
        help_text=_("Last used payment provider (paystack, flutterwave, etc.)")
    )
    preferred_payment_method = models.CharField(
        max_length=20,
        blank=True,
        verbose_name=_("Preferred Payment Method"),
        help_text=_("Last used payment method (card, mobile_money, bank_transfer)")
    )

    # Enrollment Stats
    total_enrollments = models.IntegerField(
        default=0,
        verbose_name=_("Total Enrollments")
    )
    active_enrollments = models.IntegerField(
        default=0,
        verbose_name=_("Active Enrollments")
    )
    completed_enrollments = models.IntegerField(
        default=0,
        verbose_name=_("Completed Enrollments")
    )

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'students'  # Student profile table
        verbose_name = _("Student Profile")
        verbose_name_plural = _("Student Profiles")

    def __str__(self):
        return f"Profile: {self.user.email}"

    def get_company_details(self):
        """Get last used company details for reuse"""
        if not self.has_company_payment_history:
            return None

        return {
            'company_name': self.last_used_company_name,
            'contact_email': self.last_used_company_email,
            'contact_phone': self.last_used_company_phone,
            'company_address': self.last_used_company_address,
            'vat_number': self.last_used_vat_number,
        }

    def update_company_details(self, company_details):
        """Update stored company details after successful payment"""
        self.last_used_company_name = company_details.get('company_name', '')
        self.last_used_company_email = company_details.get('contact_email', '')
        self.last_used_company_phone = company_details.get('contact_phone', '')
        self.last_used_company_address = company_details.get('company_address', '')
        self.last_used_vat_number = company_details.get('vat_number', '')
        self.has_company_payment_history = True
        self.save()


class Wishlist(models.Model):
    """
    Student wishlist for courses they're interested in but not yet enrolled.

    Features:
    - Tracks all 4 training types (Masterclass, Learnership, Industry, Custom)
    - Available to Marketing team for lead follow-up
    - Shows courses student wants to study (now or future)
    - Excludes courses already enrolled in
    """

    TRAINING_TYPE_CHOICES = [
        ('masterclass', 'Masterclass'),
        ('learnership', 'Learnership'),
        ('industry_training', 'Industry Training'),
        ('custom_selection', 'Custom Selection'),
        ('aicertscourse', 'AICerts Course'),
        ('course', 'Course'),
        ('offering', 'Industry Training'),
    ]

    INTEREST_LEVEL_CHOICES = [
        ('high', 'High - Want to enroll soon'),
        ('medium', 'Medium - Considering'),
        ('low', 'Low - Just browsing'),
    ]

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='wishlist_items',
        verbose_name=_("Student")
    )

    # Generic relation to any course type
    content_type = models.ForeignKey(
        ContentType,
        on_delete=models.CASCADE,
        limit_choices_to={
            'model__in': (
                'masterclass',
                'learnershipprogramme',
                'aicertscourse',
                'offering',  # Industry training
                'course'  # Generic course
            )
        },
        verbose_name=_("Course Type")
    )
    object_id = models.PositiveIntegerField(verbose_name=_("Course ID"))
    course = GenericForeignKey('content_type', 'object_id')
    title = models.CharField(max_length=255, blank=True, null=True, verbose_name=_("Course Title"))

    # Regional tracking for admin filtering
    country = models.ForeignKey(
        'localization.Country',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='wishlists',
        verbose_name=_("Country")
    )

    # Training type for filtering
    training_type = models.CharField(
        max_length=20,
        choices=TRAINING_TYPE_CHOICES,
        verbose_name=_("Training Type")
    )

    # Interest tracking
    interest_level = models.CharField(
        max_length=10,
        choices=INTEREST_LEVEL_CHOICES,
        default='medium',
        verbose_name=_("Interest Level")
    )

    # Timeline
    intended_start = models.CharField(
        max_length=20,
        choices=[
            ('immediate', 'Immediate (within 1 month)'),
            ('short_term', 'Short term (1-3 months)'),
            ('medium_term', 'Medium term (3-6 months)'),
            ('long_term', 'Long term (6+ months)'),
            ('undecided', 'Undecided'),
        ],
        default='undecided',
        verbose_name=_("Intended Start Time")
    )

    # User notes (Reason)
    notes = models.TextField(
        blank=True,
        verbose_name=_("Reason for Interest"),
        help_text=_("Why does the student want this course?")
    )

    # Marketing follow-up
    marketing_contacted = models.BooleanField(
        default=False,
        verbose_name=_("Marketing Contacted"),
        help_text=_("Has marketing team followed up on this lead?")
    )
    marketing_contacted_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_("Marketing Contact Date")
    )
    marketing_notes = models.TextField(
        blank=True,
        verbose_name=_("Marketing Notes"),
        help_text=_("Notes from marketing follow-up")
    )
    contacted_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='contacted_wishlist_leads',
        verbose_name=_("Contacted By")
    )

    # Conversion tracking
    converted_to_cart = models.BooleanField(
        default=False,
        verbose_name=_("Moved to Cart"),
        help_text=_("Did student add this to their cart?")
    )
    converted_to_cart_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_("Added to Cart At")
    )

    converted_to_enrollment = models.BooleanField(
        default=False,
        verbose_name=_("Enrolled"),
        help_text=_("Did student complete enrollment?")
    )
    converted_to_enrollment_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_("Enrolled At")
    )

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Added to Wishlist"))
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'wishlist'
        verbose_name = _("Wishlist Item")
        verbose_name_plural = _("Wishlist")
        ordering = ['-created_at']
        unique_together = ['user', 'content_type', 'object_id']
        indexes = [
            models.Index(fields=['user', 'training_type']),
            models.Index(fields=['marketing_contacted', 'interest_level']),
            models.Index(fields=['converted_to_cart', 'converted_to_enrollment']),
            models.Index(fields=['intended_start']),
        ]

    def __str__(self):
        return f"{self.user.email} - {self.training_type} wishlist"

    def mark_marketing_contacted(self, by_user, notes=''):
        """Mark as contacted by marketing team"""
        self.marketing_contacted = True
        self.marketing_contacted_at = timezone.now()
        self.marketing_notes = notes
        self.contacted_by = by_user
        self.save()

    def move_to_cart(self):
        """Mark as moved to cart"""
        self.converted_to_cart = True
        self.converted_to_cart_at = timezone.now()
        self.save()

    def mark_enrolled(self):
        """Mark as successfully enrolled"""
        self.converted_to_enrollment = True
        self.converted_to_enrollment_at = timezone.now()
        self.save()


class CourseCart(models.Model):
    """
    Shopping cart for course enrollment.

    Features:
    - Drag and drop from catalog/wishlist
    - Multi-course selection
    - Supports all 4 training types
    - Skips data collection for authenticated users
    - Prompts to reuse previous company details
    """

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='course_carts',
        verbose_name=_("Student")
    )

    # Cart status
    is_active = models.BooleanField(
        default=True,
        verbose_name=_("Active"),
        help_text=_("Is this the user's current active cart?")
    )

    # Checkout status
    status = models.CharField(
        max_length=20,
        choices=[
            ('active', 'Active'),
            ('checkout', 'In Checkout'),
            ('completed', 'Completed'),
            ('abandoned', 'Abandoned'),
        ],
        default='active',
        verbose_name=_("Cart Status")
    )

    # Enrollment preferences
    use_previous_company_details = models.BooleanField(
        default=False,
        verbose_name=_("Reuse Previous Company Details"),
        help_text=_("Reuse company details from previous enrollment?")
    )

    is_corporate_enrollment = models.BooleanField(
        default=False,
        verbose_name=_("Corporate Enrollment"),
        help_text=_("Is this a company-paid enrollment?")
    )

    # Totals
    total_courses = models.IntegerField(
        default=0,
        verbose_name=_("Total Courses")
    )
    total_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0.00,
        verbose_name=_("Total Amount")
    )
    currency = models.CharField(
        max_length=3,
        default='USD',
        verbose_name=_("Currency")
    )

    # Conversion tracking
    checkout_started_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_("Checkout Started")
    )
    completed_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_("Completed At")
    )
    abandoned_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_("Abandoned At")
    )

    # Linked order/payment
    order = models.ForeignKey(
        'payments.Order',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='course_carts',
        verbose_name=_("Order")
    )

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'course_carts'
        verbose_name = _("Course Cart")
        verbose_name_plural = _("Course Carts")
        ordering = ['-updated_at']
        indexes = [
            models.Index(fields=['user', 'is_active']),
            models.Index(fields=['status', 'updated_at']),
        ]

    def __str__(self):
        return f"Cart {self.id} - {self.user.email} ({self.total_courses} courses)"

    def recalculate_totals(self):
        """Recalculate cart totals from items"""
        from decimal import Decimal
        items = self.items.all()
        self.total_courses = items.count()
        # Safely sum prices, handling empty querysets and None values
        self.total_amount = sum(
            (item.price or Decimal('0.00')) for item in items
        ) or Decimal('0.00')
        self.save()

    def start_checkout(self):
        """Mark cart as in checkout"""
        self.status = 'checkout'
        self.checkout_started_at = timezone.now()
        self.save()

    def mark_completed(self, order=None):
        """Mark cart as completed"""
        self.status = 'completed'
        self.completed_at = timezone.now()
        if order:
            self.order = order
        self.save()

    def mark_abandoned(self):
        """Mark cart as abandoned"""
        self.status = 'abandoned'
        self.abandoned_at = timezone.now()
        self.save()


class CourseCartItem(models.Model):
    """
    Individual item in the course cart.

    Supports:
    - All course types (Masterclass, Learnership, Industry, Custom)
    - Pricing information
    - Prerequisites checking
    """

    TRAINING_TYPE_CHOICES = [
        ('masterclass', 'Masterclass'),
        ('learnership', 'Learnership'),
        ('industry_training', 'Industry Training'),
        ('custom_selection', 'Custom Selection'),
        ('aicertscourse', 'AICerts Course'),
        ('course', 'Course'),
        ('offering', 'Industry Training'),
    ]

    cart = models.ForeignKey(
        CourseCart,
        on_delete=models.CASCADE,
        related_name='items',
        verbose_name=_("Cart")
    )

    # Generic relation to any course type
    content_type = models.ForeignKey(
        ContentType,
        on_delete=models.CASCADE,
        limit_choices_to={
            'model__in': (
                'masterclass',
                'learnershipprogramme',
                'aicertscourse',
                'offering',  # Industry training
                'course'  # Generic course
            )
        },
        verbose_name=_("Course Type")
    )
    object_id = models.PositiveIntegerField(verbose_name=_("Course ID"))
    course = GenericForeignKey('content_type', 'object_id')

    # Training type
    training_type = models.CharField(
        max_length=20,
        choices=TRAINING_TYPE_CHOICES,
        verbose_name=_("Training Type")
    )

    # Pricing
    price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name=_("Price")
    )
    currency = models.CharField(
        max_length=3,
        default='USD',
        verbose_name=_("Currency")
    )

    # Prerequisites
    prerequisites_met = models.BooleanField(
        default=True,
        verbose_name=_("Prerequisites Met"),
        help_text=_("Does student meet prerequisites for this course?")
    )
    prerequisite_notes = models.TextField(
        blank=True,
        verbose_name=_("Prerequisite Notes"),
        help_text=_("Details about prerequisites")
    )

    # Source tracking
    added_from_wishlist = models.BooleanField(
        default=False,
        verbose_name=_("Added from Wishlist")
    )
    wishlist_item = models.ForeignKey(
        Wishlist,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='cart_items',
        verbose_name=_("Source Wishlist Item")
    )

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Added to Cart"))
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'course_cart_items'
        verbose_name = _("Cart Item")
        verbose_name_plural = _("Cart Items")
        ordering = ['created_at']
        unique_together = ['cart', 'content_type', 'object_id']

    def __str__(self):
        return f"Cart {self.cart.id} - {self.training_type} item"

    def save(self, *args, **kwargs):
        super().save(*args, **kwargs)
        # Update cart totals after saving
        self.cart.recalculate_totals()


class CourseProvider(models.Model):
    """
    Course providers (AICERTS, Udemy, Coursera, etc.)

    Only active course providers appear in custom enrollment catalog.
    """

    name = models.CharField(
        max_length=100,
        unique=True,
        verbose_name=_("Provider Name"),
        help_text=_("e.g., AICERTS, Udemy, Coursera")
    )

    code = models.CharField(
        max_length=50,
        unique=True,
        verbose_name=_("Provider Code"),
        help_text=_("Unique identifier (e.g., aicerts, udemy)")
    )

    description = models.TextField(
        blank=True,
        verbose_name=_("Description")
    )

    website = models.URLField(
        blank=True,
        verbose_name=_("Website URL")
    )

    logo = models.ImageField(
        upload_to='providers/',
        blank=True,
        null=True,
        verbose_name=_("Provider Logo")
    )

    # Integration details
    api_url = models.URLField(
        blank=True,
        verbose_name=_("API URL"),
        help_text=_("Base URL for provider API")
    )
    api_key = models.CharField(
        max_length=500,
        blank=True,
        verbose_name=_("API Key")
    )

    # Status
    is_active = models.BooleanField(
        default=True,
        verbose_name=_("Active"),
        help_text=_("Only active providers appear in custom enrollment catalog")
    )

    # Display settings
    display_order = models.IntegerField(
        default=0,
        verbose_name=_("Display Order"),
        help_text=_("Lower numbers appear first")
    )

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'course_providers'
        verbose_name = _("Course Provider")
        verbose_name_plural = _("Course Providers")
        ordering = ['display_order', 'name']

    def __str__(self):
        return self.name

    @property
    def active_courses_count(self):
        """Get count of active courses from this provider"""
        # This will be implemented based on your course models
        return 0


class CourseCatalogItem(models.Model):
    """
    Unified catalog item linking all course types.

    Makes it easy to show all available courses in one place
    for custom enrollment and wishlist features.
    """

    TRAINING_TYPE_CHOICES = [
        ('masterclass', 'Masterclass'),
        ('learnership', 'Learnership'),
        ('industry_training', 'Industry Training'),
        ('custom_selection', 'Custom Selection'),
        ('aicertscourse', 'AICerts Course'),
        ('course', 'Course'),
        ('offering', 'Industry Training'),
    ]

    # Generic relation to any course type
    content_type = models.ForeignKey(
        ContentType,
        on_delete=models.CASCADE,
        limit_choices_to={
            'model__in': (
                'masterclass',
                'learnershipprogramme',
                'aicertscourse',
                'offering',  # Industry training
                'course'  # Generic course
            )
        },
        verbose_name=_("Course Type")
    )
    object_id = models.PositiveIntegerField(verbose_name=_("Course ID"))
    course = GenericForeignKey('content_type', 'object_id')

    # Classification
    training_type = models.CharField(
        max_length=20,
        choices=TRAINING_TYPE_CHOICES,
        verbose_name=_("Training Type")
    )

    provider = models.ForeignKey(
        CourseProvider,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='catalog_items',
        verbose_name=_("Provider")
    )

    # Display info (denormalized for performance)
    title = models.CharField(
        max_length=500,
        verbose_name=_("Course Title")
    )
    description = models.TextField(
        blank=True,
        verbose_name=_("Course Description")
    )
    thumbnail = models.URLField(
        blank=True,
        verbose_name=_("Thumbnail URL")
    )

    # Pricing
    price = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        verbose_name=_("Price")
    )
    currency = models.CharField(
        max_length=3,
        default='USD',
        verbose_name=_("Currency")
    )

    # Status
    is_active = models.BooleanField(
        default=True,
        verbose_name=_("Active"),
        help_text=_("Show in catalog?")
    )
    is_featured = models.BooleanField(
        default=False,
        verbose_name=_("Featured"),
        help_text=_("Show as featured course?")
    )

    # Enrollment stats
    total_enrollments = models.IntegerField(
        default=0,
        verbose_name=_("Total Enrollments")
    )
    total_wishlist_adds = models.IntegerField(
        default=0,
        verbose_name=_("Total Wishlist Adds")
    )

    # Metadata
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'course_catalog'
        verbose_name = _("Catalog Item")
        verbose_name_plural = _("Course Catalog")
        ordering = ['-is_featured', '-created_at']
        unique_together = ['content_type', 'object_id']
        indexes = [
            models.Index(fields=['training_type', 'is_active']),
            models.Index(fields=['provider', 'is_active']),
            models.Index(fields=['-is_featured', '-total_enrollments']),
        ]

    def __str__(self):
        return f"{self.title} ({self.training_type})"
