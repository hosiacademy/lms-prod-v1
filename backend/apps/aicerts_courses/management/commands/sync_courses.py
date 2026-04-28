# apps/aicerts_courses/management/commands/sync_courses.py
from django.core.management.base import BaseCommand
from apps.aicerts_courses.services import sync_courses

class Command(BaseCommand):
    help = 'Sync RAW courses from AICerts API (no industry assignment)'
    
    def handle(self, *args, **options):
        count = sync_courses()  # This should only sync raw courses
        self.stdout.write(self.style.SUCCESS(f'Successfully synced {count} RAW courses'))