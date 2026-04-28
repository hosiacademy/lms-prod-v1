"""
Script to check and fix get_content_types endpoint 500 errors.
Run via: docker exec -i lms-prod-backend-1 python manage.py shell < fix_content_types.py
"""
import os
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')

from django.contrib.contenttypes.models import ContentType

models = ['masterclass', 'learnershipprogramme', 'aicertscourse', 'offering', 'course']
for m in models:
    exists = ContentType.objects.filter(model=m).exists()
    print(f"{m}: {exists}")
