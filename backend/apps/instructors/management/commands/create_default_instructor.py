"""
Management command to create default instructor (Takawira)
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.instructors.models import Instructor

User = get_user_model()

class Command(BaseCommand):
    help = 'Create Takawira as default instructor/facilitator'

    def handle(self, *args, **kwargs):
        self.stdout.write('Creating default instructor: Takawira...')

        # Create or get user
        user, created = User.objects.get_or_create(
            email='takawira@hosiacademy.africa',
            defaults={
                'username': 'takawira',
                'first_name': 'Takawira',
                'last_name': 'Instructor',
                'role_id': 2,  # Instructor role
                'is_active': True,
            }
        )

        if created:
            user.set_unusable_password()  # Admin should set password
            user.save()
            self.stdout.write(self.style.SUCCESS(f'✓ User created: {user.email}'))
        else:
            self.stdout.write(f'✓ User exists: {user.email}')

        # Create or get instructor record
        instructor, created = Instructor.objects.get_or_create(
            user=user,
            defaults={
                'bio': 'Default instructor/facilitator for Hosi Academy',
                'is_verified': True,
                'is_available': True,
            }
        )

        if created:
            self.stdout.write(self.style.SUCCESS(f'✓ Instructor record created'))
        else:
            self.stdout.write(f'✓ Instructor record exists')

        # Display instructor details
        self.stdout.write(self.style.SUCCESS('\n=== Default Instructor Created ==='))
        self.stdout.write(f'Name: Takawira')
        self.stdout.write(f'Email: takawira@hosiacademy.africa')
        self.stdout.write(f'Role: Instructor/Facilitator')
        self.stdout.write(f'Status: Active & Verified')
        self.stdout.write('\nNote: Password is unset. Admin should set password via admin panel.')
