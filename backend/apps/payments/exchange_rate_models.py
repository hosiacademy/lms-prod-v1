"""
Exchange Rate Models
Stores cached currency exchange rates fetched daily via Celery
"""
from django.db import models
from django.utils import timezone
from datetime import timedelta


class ExchangeRate(models.Model):
    """
    Stores exchange rate from USD to local currency.
    Rates are fetched daily via Celery task and cached for 24 hours.
    """
    currency_code = models.CharField(max_length=3, unique=True, db_index=True)
    rate = models.DecimalField(
        max_digits=12,
        decimal_places=6,
        help_text="1 USD = X local currency"
    )
    currency_name = models.CharField(max_length=100)
    currency_symbol = models.CharField(max_length=10, blank=True)
    country_code = models.CharField(max_length=2, db_index=True)
    country_name = models.CharField(max_length=100)
    
    # Timestamps
    fetched_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    expires_at = models.DateTimeField(help_text="Rate expires after 24 hours")
    
    # Metadata
    source = models.CharField(
        max_length=50,
        default='exchangerate-api',
        help_text="API source for the rate"
    )
    is_active = models.BooleanField(default=True)
    
    class Meta:
        ordering = ['currency_code']
        verbose_name_plural = 'Exchange Rates'
    
    def __str__(self):
        return f"1 USD = {self.rate} {self.currency_code}"
    
    @property
    def is_expired(self):
        """Check if rate has expired (older than 24 hours)"""
        return timezone.now() > self.expires_at
    
    @property
    def is_fresh(self):
        """Check if rate is fresh (less than 1 hour old)"""
        return timezone.now() < (self.fetched_at + timedelta(hours=1))
    
    @classmethod
    def get_rate(cls, currency_code):
        """
        Get exchange rate for currency.
        Returns None if not found or expired.
        """
        try:
            rate = cls.objects.get(
                currency_code=currency_code.upper(),
                is_active=True,
                expires_at__gt=timezone.now()
            )
            return rate
        except cls.DoesNotExist:
            return None
    
    @classmethod
    def get_rate_or_default(cls, currency_code, default_rate=1.0):
        """
        Get exchange rate or return default (for USD).
        """
        if currency_code.upper() == 'USD':
            return 1.0
        
        rate = cls.get_rate(currency_code)
        if rate:
            return float(rate.rate)
        return default_rate


class ExchangeRateLog(models.Model):
    """
    Logs all exchange rate fetch attempts for auditing.
    """
    STATUS_CHOICES = [
        ('success', 'Success'),
        ('failed', 'Failed'),
        ('partial', 'Partial'),
    ]
    
    fetched_at = models.DateTimeField(auto_now_add=True)
    source = models.CharField(max_length=50)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES)
    rates_fetched = models.IntegerField(default=0)
    error_message = models.TextField(blank=True)
    raw_response = models.JSONField(null=True, blank=True)
    
    class Meta:
        ordering = ['-fetched_at']
    
    def __str__(self):
        return f"{self.status} - {self.fetched_at}"
