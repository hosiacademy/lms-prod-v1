import os
import django
from django.db import connection

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

def run_sql():
    with connection.cursor() as cursor:
        cursor.execute("SELECT id, title, category, price_physical, price_online FROM masterclasses_masterclass LIMIT 3;")
        rows = cursor.fetchall()
        print("ID | Title | Category | Physical | Online")
        print("-" * 60)
        for row in rows:
            print(f"{row[0]} | {row[1]} | {row[2]} | {row[3]} | {row[4]}")

if __name__ == "__main__":
    run_sql()
