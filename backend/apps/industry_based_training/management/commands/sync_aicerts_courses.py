# apps/industry_based_training/management/commands/sync_aicerts_courses.py
from django.core.management.base import BaseCommand
from apps.industry_based_training.services import sync_courses

class Command(BaseCommand):
    help = 'Sync courses with industry assignment'
    
    def handle(self, *args, **options):
        sync_courses()  # This syncs BOTH raw AND industry courses
        self.stdout.write(self.style.SUCCESS('Successfully synced courses with industries'))