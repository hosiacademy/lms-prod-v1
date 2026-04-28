from django.db import connection
import sys
import os
sys.path.append(os.getcwd())
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

with connection.cursor() as cursor:
    cursor.execute("SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public'")
    count = cursor.fetchone()[0]
    print(f"Total tables: {count}")
