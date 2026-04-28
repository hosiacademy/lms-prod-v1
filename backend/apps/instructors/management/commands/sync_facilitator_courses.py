# apps/facilitators/management/commands/sync_facilitator_courses.py

from django.core.management.base import BaseCommand
from django.utils import timezone
import logging

# IMPORTANT: Import the function from your services module
from apps.facilitators.services import sync_courses_for_facilitators

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Sync courses from AICerts API for facilitator assignments'

    def add_arguments(self, parser):
        parser.add_argument(
            '--force',
            action='store_true',
            help='Force sync even if recent sync exists',
        )

    def handle(self, *args, **options):
        force = options.get('force', False)
        
        self.stdout.write('Starting course sync from AICerts API...')
        
        try:
            result = sync_courses_for_facilitators(force=force)  # Now resolved
            
            self.stdout.write(
                self.style.SUCCESS(
                    f"✓ Successfully synced {result['synced']} courses "
                    f"(skipped {result['skipped']} self-paced courses)"
                )
            )
            
        except Exception as e:
            self.stdout.write(
                self.style.ERROR(f"✗ Failed to sync courses: {str(e)}")
            )
            logger.error(f"Course sync failed: {e}")