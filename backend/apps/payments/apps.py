# apps/payments/apps.py

from django.apps import AppConfig


class PaymentsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.payments'
    verbose_name = 'Payments & Enrollments'

    def ready(self):
        """
        Import signals when app is ready.
        This ensures payment-triggered AICERTS enrollment automation works.
        """
        import apps.payments.signals  # noqa: F401