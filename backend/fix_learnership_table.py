
import os
import django
from django.db import connection
from django.apps import apps

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

def fix_table():
    model = apps.get_model('learnerships', 'LearnershipEnrollment')
    table_name = model._meta.db_table
    
    with connection.cursor() as cursor:
        cursor.execute(f"SELECT column_name FROM information_schema.columns WHERE table_name = '{table_name}'")
        existing_columns = [row[0] for row in cursor.fetchall()]
        
        for field in model._meta.fields:
            column_name = field.column
            if column_name not in existing_columns:
                print(f"Adding missing column: {column_name}")
                # Determine SQL type (simplified)
                db_type = field.db_type(connection)
                if db_type:
                    cursor.execute(f"ALTER TABLE {table_name} ADD COLUMN {column_name} {db_type};")
                else:
                    print(f"Could not determine type for {column_name}")

if __name__ == '__main__':
    fix_table()
