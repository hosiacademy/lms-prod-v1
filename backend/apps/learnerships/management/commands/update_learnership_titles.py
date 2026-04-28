"""
Update learnership titles to be specific rather than generic "Hosi Academy Learnership"
"""
from django.core.management.base import BaseCommand
from apps.learnerships.models import LearnershipProgramme


class Command(BaseCommand):
    help = 'Update learnership titles to be specific based on their role'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Updating learnership titles...'))

        updated_count = 0
        for learnership in LearnershipProgramme.objects.all():
            old_title = learnership.title
            # Generate specific title from role
            learnership.title = f"{learnership.get_role_display()} Learnership Programme"
            learnership.save()

            self.stdout.write(
                self.style.SUCCESS(f'✓ Updated: "{old_title}" → "{learnership.title}"')
            )
            updated_count += 1

        self.stdout.write(
            self.style.SUCCESS(f'\n✅ Updated {updated_count} learnership titles')
        )
