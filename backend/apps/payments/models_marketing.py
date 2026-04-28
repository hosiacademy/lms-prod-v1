from django.db import models
from django.conf import settings

class MailingList(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField(null=True, blank=True)
    owner = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='marketing_mailing_lists')
    country = models.CharField(max_length=100, null=True, blank=True, help_text="Specific country for this list")
    is_universal = models.BooleanField(default=False, help_text="True if this list is for all countries")
    theme = models.CharField(max_length=100, null=True, blank=True, help_text="Category or theme for this list")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'marketing_mailing_lists'
        verbose_name = 'Mailing List'
        verbose_name_plural = 'Mailing Lists'
        ordering = ['-created_at']

    def __str__(self):
        return self.name

class MailingListContact(models.Model):
    mailing_list = models.ForeignKey(MailingList, on_delete=models.CASCADE, related_name='contacts')
    name = models.CharField(max_length=255)
    email = models.EmailField(null=True, blank=True)
    phone = models.CharField(max_length=20, null=True, blank=True)
    country_code = models.CharField(max_length=5, default='+27')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'marketing_mailing_list_contacts'
        verbose_name = 'Mailing List Contact'
        verbose_name_plural = 'Mailing List Contacts'
        ordering = ['name']

    def __str__(self):
        return f"{self.name} ({self.email or self.phone})"

class MarketingCampaign(models.Model):
    name = models.CharField(max_length=255)
    theme = models.CharField(max_length=100, null=True, blank=True)
    message = models.TextField()
    method = models.CharField(max_length=20, choices=[('sms', 'SMS'), ('email', 'Email')])
    media_url = models.URLField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='marketing_campaigns')

    class Meta:
        db_table = 'marketing_campaigns'
        verbose_name = 'Marketing Campaign'
        verbose_name_plural = 'Marketing Campaigns'
        ordering = ['-created_at']

    def __str__(self):
        return self.name
