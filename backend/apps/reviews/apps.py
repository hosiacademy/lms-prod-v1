# apps/reviews/apps.py
from django.apps import AppConfig


class ReviewsConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.reviews'
    verbose_name = 'Reviews & Ratings'

    def ready(self):
        # Import signals
        try:
            import apps.reviews.signals  # noqa
        except ImportError:
            pass
