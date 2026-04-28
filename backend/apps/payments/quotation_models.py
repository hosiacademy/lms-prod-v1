"""
Quotation System Models
- Client quotations with SmatPay payment integration
- Auto-populated pricing from courses/masterclasses/learnerships
- Email & SMS delivery
"""
from django.db import models
from django.utils.translation import gettext_lazy as _
from django.utils import timezone
from decimal import Decimal
import uuid


def generate_quotation_number():
    """Generate unique quotation number: QT-YYYY-XXXXX"""
    year = timezone.now().year
    count = ClientQuotation.objects.filter(
        created_at__year=year
    ).count() + 1
    return f"QT-{year}-{count:05d}"


class QuotationStatus(models.TextChoices):
    """Quotation lifecycle statuses"""
    DRAFT = 'draft', _('Draft')
    SENT = 'sent', _('Sent to Client')
    VIEWED = 'viewed', _('Viewed by Client')
    ACCEPTED = 'accepted', _('Accepted')
    PAID = 'paid', _('Paid via SmatPay')
    EXPIRED = 'expired', _('Expired')
    CANCELLED = 'cancelled', _('Cancelled')


class TrainingType(models.TextChoices):
    """Types of training offered"""
    COURSE = 'course', _('AI Certs Course')
    MASTERCLASS = 'masterclass', _('Professional Masterclass')
    LEARNERSHIP = 'learnership', _('Learnership Program')


class ClientQuotation(models.Model):
    """
    Client quotation for training programs
    Links to courses/masterclasses/learnerships with auto-populated pricing
    """
    # Quotation Identity
    quotation_number = models.CharField(
        max_length=20,
        unique=True,
        default=generate_quotation_number,
        verbose_name=_('Quotation Number')
    )
    
    # Client Information
    client_name = models.CharField(
        max_length=255,
        verbose_name=_('Client Name')
    )
    client_email = models.EmailField(
        verbose_name=_('Client Email')
    )
    client_phone = models.CharField(
        max_length=20,
        blank=True,
        verbose_name=_('Client Phone')
    )
    client_company = models.CharField(
        max_length=255,
        blank=True,
        verbose_name=_('Company/Organization')
    )
    client_country = models.CharField(
        max_length=2,
        default='ZW',
        verbose_name=_('Country Code')
    )
    
    # Training Type Selection (Cascading dropdowns)
    training_type = models.CharField(
        max_length=20,
        choices=TrainingType.choices,
        verbose_name=_('Training Type')
    )
    
    # Reference to specific training item (polymorphic)
    # These are populated based on training_type selection
    course_id = models.IntegerField(
        null=True,
        blank=True,
        verbose_name=_('Course ID (if type=course)')
    )
    course_name = models.CharField(
        max_length=255,
        blank=True,
        verbose_name=_('Course Name')
    )
    masterclass_id = models.IntegerField(
        null=True,
        blank=True,
        verbose_name=_('Masterclass ID (if type=masterclass)')
    )
    masterclass_name = models.CharField(
        max_length=255,
        blank=True,
        verbose_name=_('Masterclass Name')
    )
    learnership_id = models.IntegerField(
        null=True,
        blank=True,
        verbose_name=_('Learnership ID (if type=learnership)')
    )
    learnership_name = models.CharField(
        max_length=255,
        blank=True,
        verbose_name=_('Learnership Name')
    )
    
    # Pricing (Auto-populated from training item)
    base_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        verbose_name=_('Base Price (USD)')
    )
    local_currency = models.CharField(
        max_length=3,
        default='USD',
        verbose_name=_('Local Currency')
    )
    local_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        verbose_name=_('Amount in Local Currency')
    )
    exchange_rate = models.DecimalField(
        max_digits=10,
        decimal_places=6,
        default=Decimal('1.0'),
        verbose_name=_('Exchange Rate')
    )
    
    # Discounts
    discount_percentage = models.DecimalField(
        max_digits=5,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name=_('Discount %')
    )
    discount_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name=_('Discount Amount')
    )
    
    # Final Amounts
    subtotal = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        verbose_name=_('Subtotal')
    )
    vat_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        verbose_name=_('VAT/Tax Amount')
    )
    total_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        verbose_name=_('Total Amount')
    )
    
    # Quantity (for group bookings)
    quantity = models.PositiveIntegerField(
        default=1,
        verbose_name=_('Number of Participants')
    )
    
    # Quotation Details
    description = models.TextField(
        blank=True,
        verbose_name=_('Description/Notes')
    )
    validity_days = models.PositiveIntegerField(
        default=30,
        verbose_name=_('Validity (Days)')
    )
    
    # Status & Tracking
    status = models.CharField(
        max_length=20,
        choices=QuotationStatus.choices,
        default=QuotationStatus.DRAFT,
        verbose_name=_('Status')
    )
    
    # SmatPay Payment Integration
    smatpay_payment_link = models.URLField(
        blank=True,
        verbose_name=_('SmatPay Payment URL')
    )
    smatpay_reference = models.CharField(
        max_length=100,
        blank=True,
        verbose_name=_('SmatPay Reference')
    )
    
    # Delivery Tracking
    email_sent = models.BooleanField(
        default=False,
        verbose_name=_('Email Sent')
    )
    email_sent_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_('Email Sent At')
    )
    sms_sent = models.BooleanField(
        default=False,
        verbose_name=_('SMS Sent')
    )
    sms_sent_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_('SMS Sent At')
    )
    viewed_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_('First Viewed At')
    )
    viewed_count = models.PositiveIntegerField(
        default=0,
        verbose_name=_('View Count')
    )
    
    # Admin/Creator
    created_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='quotations_created',
        verbose_name=_('Created By')
    )
    
    # Timestamps
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    expires_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name=_('Expiration Date')
    )
    
    class Meta:
        db_table = 'client_quotations'
        ordering = ['-created_at']
        verbose_name = _('Client Quotation')
        verbose_name_plural = _('Client Quotations')
        indexes = [
            models.Index(fields=['quotation_number']),
            models.Index(fields=['client_email']),
            models.Index(fields=['status', 'created_at']),
            models.Index(fields=['training_type', 'status']),
        ]
    
    def __str__(self):
        return f"{self.quotation_number} - {self.client_name}"
    
    def save(self, *args, **kwargs):
        # Calculate expiration date
        if not self.expires_at and self.validity_days:
            from datetime import timedelta
            self.expires_at = self.created_at + timedelta(days=self.validity_days)
        
        # Calculate totals
        self._calculate_totals()
        
        super().save(*args, **kwargs)
    
    def _calculate_totals(self):
        """Calculate subtotal, discount, and total"""
        # Base calculation with quantity
        base = self.base_price * self.quantity
        
        # Apply discount
        if self.discount_percentage > 0:
            self.discount_amount = base * (self.discount_percentage / 100)
        
        self.subtotal = base - self.discount_amount
        self.total_amount = self.subtotal + self.vat_amount
        
        # Update local amount based on exchange rate
        if self.local_currency != 'USD':
            self.local_amount = self.total_amount * self.exchange_rate
        else:
            self.local_amount = self.total_amount
    
    @property
    def training_item_name(self):
        """Get the name of the selected training item"""
        if self.training_type == TrainingType.COURSE:
            return self.course_name
        elif self.training_type == TrainingType.MASTERCLASS:
            return self.masterclass_name
        elif self.training_type == TrainingType.LEARNERSHIP:
            return self.learnership_name
        return "Unknown"
    
    @property
    def is_expired(self):
        """Check if quotation has expired"""
        if self.expires_at:
            return timezone.now() > self.expires_at
        return False
    
    @property
    def days_until_expiry(self):
        """Get days remaining until expiry"""
        if self.expires_at:
            delta = self.expires_at - timezone.now()
            return max(0, delta.days)
        return 0


class QuotationItem(models.Model):
    """
    Additional line items for a quotation
    (e.g., materials, certification fees, group discounts)
    """
    quotation = models.ForeignKey(
        ClientQuotation,
        on_delete=models.CASCADE,
        related_name='additional_items',
        verbose_name=_('Quotation')
    )
    description = models.CharField(
        max_length=255,
        verbose_name=_('Item Description')
    )
    quantity = models.PositiveIntegerField(
        default=1,
        verbose_name=_('Quantity')
    )
    unit_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        verbose_name=_('Unit Price (USD)')
    )
    total_price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        verbose_name=_('Total Price')
    )
    
    class Meta:
        db_table = 'quotation_items'
        verbose_name = _('Quotation Item')
        verbose_name_plural = _('Quotation Items')
    
    def save(self, *args, **kwargs):
        self.total_price = self.quantity * self.unit_price
        super().save(*args, **kwargs)


class QuotationActivityLog(models.Model):
    """
    Audit log for quotation activities
    """
    quotation = models.ForeignKey(
        ClientQuotation,
        on_delete=models.CASCADE,
        related_name='activity_logs',
        verbose_name=_('Quotation')
    )
    activity_type = models.CharField(
        max_length=50,
        verbose_name=_('Activity Type')
    )
    description = models.TextField(
        verbose_name=_('Description')
    )
    performed_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        verbose_name=_('Performed By')
    )
    ip_address = models.GenericIPAddressField(
        null=True,
        blank=True,
        verbose_name=_('IP Address')
    )
    user_agent = models.TextField(
        blank=True,
        verbose_name=_('User Agent')
    )
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'quotation_activity_logs'
        ordering = ['-created_at']
        verbose_name = _('Quotation Activity Log')


class QuotationTemplate(models.Model):
    """
    Pre-defined quotation templates for quick creation
    """
    name = models.CharField(
        max_length=255,
        verbose_name=_('Template Name')
    )
    training_type = models.CharField(
        max_length=20,
        choices=TrainingType.choices,
        verbose_name=_('Training Type')
    )
    # Store IDs instead of foreign keys to avoid dependency issues
    course_id = models.IntegerField(
        null=True,
        blank=True,
        verbose_name=_('Course ID')
    )
    masterclass_id = models.IntegerField(
        null=True,
        blank=True,
        verbose_name=_('Masterclass ID')
    )
    learnership_id = models.IntegerField(
        null=True,
        blank=True,
        verbose_name=_('Learnership ID')
    )
    default_description = models.TextField(
        blank=True,
        verbose_name=_('Default Description')
    )
    validity_days = models.PositiveIntegerField(
        default=30,
        verbose_name=_('Default Validity (Days)')
    )
    is_active = models.BooleanField(
        default=True,
        verbose_name=_('Is Active')
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'quotation_templates'
        verbose_name = _('Quotation Template')
        verbose_name_plural = _('Quotation Templates')
