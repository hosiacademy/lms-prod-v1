from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _

class PartnerProgram(models.Model):
    PLATFORM_CHOICES = [
        ('twitter', 'Twitter / X'),
        ('linkedin', 'LinkedIn'),
        ('instagram', 'Instagram'),
        ('youtube', 'YouTube'),
        ('tiktok', 'TikTok'),
        ('other', 'Other'),
    ]

    user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='partner_profile')
    handle = models.CharField(_("Social Media Handle"), max_length=100)
    platform = models.CharField(_("Primary Platform"), max_length=20, choices=PLATFORM_CHOICES)
    unique_link_slug = models.SlugField(_("Unique Link Slug"), max_length=50, unique=True)
    commission_rate = models.DecimalField(_("Commission Rate (%)"), max_digits=5, decimal_places=2, default=10.00)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.email} (@{self.handle} on {self.platform})"

class Referral(models.Model):
    STATUS_CHOICES = [
        ('pending', 'Pending'),
        ('completed', 'Completed'),
        ('paid', 'Commission Paid'),
        ('cancelled', 'Cancelled'),
    ]

    partner = models.ForeignKey(PartnerProgram, on_delete=models.CASCADE, related_name='referrals')
    referred_user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.SET_NULL, null=True, blank=True, related_name='referred_by')
    course = models.ForeignKey('courses.Course', on_delete=models.CASCADE)
    commission_earned = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Referral by {self.partner.handle} for {self.course.title}"
