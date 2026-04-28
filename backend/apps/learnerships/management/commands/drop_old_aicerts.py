from django.core.management.base import BaseCommand
from django.db import connection

class Command(BaseCommand):
    help = 'Drops the old industry_based_training_aicertscourse table'

    def handle(self, *args, **kwargs):
        table_name = "industry_based_training_aicertscourse"
        with connection.cursor() as cursor:
            cursor.execute(f'DROP TABLE IF EXISTS {table_name} CASCADE;')
        self.stdout.write(self.style.SUCCESS(f'Table "{table_name}" has been dropped successfully.'))
