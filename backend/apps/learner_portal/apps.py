# apps/learner_portal/apps.py
from django.apps import AppConfig


class StudentPortalConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.learner_portal'
    verbose_name = 'Student Portal'
