import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

with connection.cursor() as cursor:
    cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'admin_roles'")
    columns = [row[0] for row in cursor.fetchall()]
    print(f"Columns for admin_roles: {columns}")
