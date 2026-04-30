import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

cursor = connection.cursor()
cursor.execute("SELECT * FROM enrollments LIMIT 1")
row = cursor.fetchone()
desc = cursor.description
if row:
    data = dict(zip([col[0] for col in desc], row))
    print(f"ROW DATA: {data}")
else:
    print("NO ROWS FOUND")
