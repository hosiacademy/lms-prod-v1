from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _

class MarketingAsset(models.Model):
    ASSET_TYPES = [
        ('IMAGE', 'Image'),
        ('VIDEO', 'Video'),
        ('SVG', 'SVG'),
    ]
    
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    asset_type = models.CharField(max_length=10, choices=ASSET_TYPES)
    file = models.FileField(upload_to='marketing/assets/')
    thumbnail = models.ImageField(upload_to='marketing/thumbnails/', null=True, blank=True)
    
    # Social media content
    suggested_caption = models.TextField(blank=True, help_text=_("Suggested text for social media posts"))
    
    # Tracking (Aggregated)
    total_clicks = models.IntegerField(default=0)
    total_shares = models.IntegerField(default=0)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        verbose_name = _('Marketing Asset')
        verbose_name_plural = _('Marketing Assets')
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.title} ({self.asset_type})"

class SocialShareEvent(models.Model):
    PLATFORMS = [
        ('facebook', 'Facebook'),
        ('twitter', 'Twitter/X'),
        ('linkedin', 'LinkedIn'),
        ('whatsapp', 'WhatsApp'),
        ('instagram', 'Instagram'),
    ]
    
    asset = models.ForeignKey(MarketingAsset, on_delete=models.CASCADE, related_name='share_events')
    platform = models.CharField(max_length=20, choices=PLATFORMS)
    shared_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    referral_link = models.URLField(max_length=500)
    
    # Tracking per share
    clicks = models.IntegerField(default=0)
    
    shared_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = _('Social Share Event')
        verbose_name_plural = _('Social Share Events')
        ordering = ['-shared_at']

class MarketingLead(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='marketing_leads')
    training_type = models.CharField(max_length=50) # course, masterclass, learnership
    object_id = models.CharField(max_length=100)
    title = models.CharField(max_length=255)
    
    # Lead details (The "expression" part for prospective students)
    goals = models.TextField(verbose_name=_("Primary Goals"))
    professional_status = models.CharField(max_length=255)
    planned_start = models.CharField(max_length=100)
    expectations = models.TextField()
    
    created_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, default='new', choices=[
        ('new', 'New'),
        ('contacted', 'Contacted'),
        ('converted', 'Converted'),
        ('closed', 'Closed'),
    ])
    
    class Meta:
        verbose_name = _('Marketing Lead')
        verbose_name_plural = _('Marketing Leads')
        ordering = ['-created_at']

    def __str__(self):
        return f"Lead: {self.user.email} - {self.title}"
