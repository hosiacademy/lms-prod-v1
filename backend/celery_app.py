# lms_monorepo/celery.py
import os
from celery import Celery

# Set the default Django settings module for the Celery app
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_monorepo.settings')  # <-- CHANGE IF YOUR SETTINGS FILE IS NAMED DIFFERENTLY

# Create Celery app instance
app = Celery('lms_monorepo')

# Load configuration from Django settings with CELERY_ namespace
app.config_from_object('django.conf:settings', namespace='CELERY')

# Automatically discover tasks in all installed apps
app.autodiscover_tasks()

# Optional: Add a debug task to confirm Celery is working
@app.task(bind=True, ignore_result=True)
def debug_task(self):
    print(f'Request: {self.request!r}')
