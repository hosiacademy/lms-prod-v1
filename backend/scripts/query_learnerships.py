import os
import django

# Force SQLite for this script
os.environ['DB_ENGINE'] = 'django.db.backends.sqlite3'
os.environ['DB_NAME'] = 'db.sqlite3'
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')

django.setup()

from apps.learnerships.models import LearnershipProgramme
print(list(LearnershipProgramme.objects.values('title', 'category')))
