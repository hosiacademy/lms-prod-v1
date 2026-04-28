# apps/learnerships/management/commands/sync_courses.py
from django.core.management.base import BaseCommand
from django.utils import timezone
import requests
from apps.learnerships.models import CourseProvider, Course

class Command(BaseCommand):
    help = 'Sync courses from AiCerts API'

    def handle(self, *args, **kwargs):
        base_url = "https://www.aicerts.ai/wp-json/aicerts-api/v1/courses"
        provider, _ = CourseProvider.objects.get_or_create(name="AiCerts", defaults={'active': True})

        page = 1
        while True:
            response = requests.get(f"{base_url}?page={page}")
            if response.status_code != 200 or not response.json().get('success'):
                break

            data = response.json().get('data', [])
            if not data:
                break

            for item in data:
                Course.objects.update_or_create(
                    external_id=item.get('id'),
                    defaults={
                        'provider': provider,
                        'title': item.get('title'),
                        'description': item.get('description'),
                        'category_name': ', '.join(item.get('categories', [])),
                        'certificate_badge_url': item.get('certificate_badge_url'),
                        'last_synced': timezone.now(),
                        'active': True
                    }
                )
            self.stdout.write(self.style.SUCCESS(f'Synced page {page}'))
            page += 1

        self.stdout.write(self.style.SUCCESS('Courses sync complete'))