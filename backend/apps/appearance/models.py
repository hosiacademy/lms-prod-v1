# apps/appearance/models.py

from django.db import models
from django.utils.translation import gettext_lazy as _


class Theme(models.Model):
    name = models.CharField(max_length=191, unique=True, verbose_name=_("Internal Name"))
    title = models.CharField(max_length=191, verbose_name=_("Display Title"))
    description = models.TextField(blank=True, null=True, verbose_name=_("Description"))
    image = models.CharField(max_length=500, blank=True, null=True, verbose_name=_("Preview Image URL"))
    folder_path = models.CharField(max_length=191, default='default', verbose_name=_("Theme Folder"))
    live_link = models.URLField(blank=True, null=True, verbose_name=_("Live Demo Link"))
    is_active = models.BooleanField(default=False, verbose_name=_("Active Theme"))
    status = models.BooleanField(default=True, verbose_name=_("Published"))
    tags = models.TextField(blank=True, null=True, verbose_name=_("Tags (e.g., kente, adinkra, pan-african)"))
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'themes'
        verbose_name = _("Theme")
        verbose_name_plural = _("Themes")
        ordering = ['-is_active', 'title']

    def __str__(self):
        return self.title or self.name

    def save(self, *args, **kwargs):
        if self.is_active:
            # Ensure only one theme is active
            Theme.objects.filter(is_active=True).exclude(pk=self.pk).update(is_active=False)
        super().save(*args, **kwargs)