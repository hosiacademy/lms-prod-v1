import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

cursor = connection.cursor()
cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'enrollments'")
columns = [c[0] for c in cursor.fetchall()]
print(f"COLUMNS: {columns}")
