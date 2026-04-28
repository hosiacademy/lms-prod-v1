# apps/learnerships/management/commands/sync_learnerships.py
from django.core.management.base import BaseCommand
from apps.learnerships.services import sync_aicerts_courses_into_system

class Command(BaseCommand):
    help = "Sync AiCerts certifications into the generic Course table"

    def handle(self, *args, **options):
        count = sync_aicerts_courses_into_system()
        self.stdout.write(self.style.SUCCESS(f"Successfully synced {count} AiCerts courses"))
