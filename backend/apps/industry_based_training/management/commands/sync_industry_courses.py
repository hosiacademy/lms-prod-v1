from django.core.management.base import BaseCommand
from apps.industry_based_training.services import sync_courses

class Command(BaseCommand):
    help = 'Sync industry-based courses from AICerts API and bucket them into industries'

    def handle(self, *args, **options):
        self.stdout.write(self.style.WARNING('Starting Industry Courses Sync...'))
        try:
            count = sync_courses()
            self.stdout.write(self.style.SUCCESS(f'Successfully synced {count} industry courses'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Failed to sync courses: {e}'))
