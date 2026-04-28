from django.core.management.base import BaseCommand
from apps.courses.services import sync_aicerts_into_courses

class Command(BaseCommand):
    help = 'Sync provider courses into unified catalogue'

    def handle(self, *args, **options):
        count = sync_aicerts_into_courses()
        self.stdout.write(self.style.SUCCESS(
            f'Successfully synced {count} AICERTS courses'
        ))
