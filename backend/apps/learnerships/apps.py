# apps/learnerships/apps.py
from django.apps import AppConfig

class LearnershipsConfig(AppConfig):
    default_auto_field = "django.db.models.BigAutoField"
    name = "apps.learnerships"
    verbose_name = "Learnerships"

    def ready(self):
        # Import signals to auto-send enrollment emails
        import apps.learnerships.signals
