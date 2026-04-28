import os
import sys
import django

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from django.db import connection

def check():
    with connection.cursor() as cursor:
        cursor.execute("SELECT column_name FROM information_schema.columns WHERE table_name = 'enrollments'")
        columns = [c[0] for c in cursor.fetchall()]
        print(f"Columns in 'enrollments' table: {columns}")

if __name__ == "__main__":
    check()
