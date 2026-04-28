from django.core.management.base import BaseCommand
from apps.aicerts_courses.models import AiCertsCourse
from django.db import transaction


class Command(BaseCommand):
    help = 'Fix duplicate external_id issues'

    def handle(self, *args, **options):
        with transaction.atomic():
            # Find courses with empty or duplicate external_id
            courses = AiCertsCourse.objects.all()
            
            # First, find and fix empty external_id
            empty_ids = AiCertsCourse.objects.filter(external_id='')
            if empty_ids.exists():
                self.stdout.write(f'Found {empty_ids.count()} courses with empty external_id')
                
                for i, course in enumerate(empty_ids):
                    # Create a unique ID for each empty one
                    if course.raw_data and isinstance(course.raw_data, dict):
                        # Try to get ID from raw_data
                        if 'api_data' in course.raw_data and 'id' in course.raw_data['api_data']:
                            course.external_id = str(course.raw_data['api_data']['id'])
                        else:
                            # Create a fallback ID
                            course.external_id = f'empty_{course.id}_{i}'
                    else:
                        course.external_id = f'empty_{course.id}_{i}'
                    
                    course.save()
                    self.stdout.write(f'  Fixed course {course.id}: {course.title[:50]}...')
            
            # Now find duplicate non-empty IDs
            from django.db.models import Count
            duplicates = AiCertsCourse.objects.values('external_id') \
                .annotate(count=Count('id')) \
                .filter(count__gt=1, external_id__gt='')
            
            for dup in duplicates:
                dup_id = dup['external_id']
                dup_courses = AiCertsCourse.objects.filter(external_id=dup_id)
                self.stdout.write(f'\nFound {dup_courses.count()} duplicates for ID: {dup_id}')
                
                # Keep the first one, fix the rest
                first_course = dup_courses.first()
                for i, course in enumerate(dup_courses[1:], 1):
                    # Create a unique ID by appending suffix
                    new_id = f"{dup_id}_dup{i}"
                    course.external_id = new_id
                    course.save()
                    self.stdout.write(f'  Fixed duplicate {course.id} -> {new_id}')
            
            self.stdout.write(self.style.SUCCESS('Successfully fixed all duplicate issues!'))
