from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import Country
from apps.users.utils import setup_admin_tiers_for_country

@receiver(post_save, sender=Country)
def on_country_save(sender, instance, created, **kwargs):
    if created and instance.is_active:
        setup_admin_tiers_for_country(instance)
