# apps/aicerts_integration/apps.py
from django.apps import AppConfig


class AicertsIntegrationConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.aicerts_integration'
    verbose_name = 'AICERTs Partnership Integration'

    def ready(self):
        """Import signals when app is ready"""
        try:
            import apps.aicerts_integration.signals
        except ImportError:
            pass
