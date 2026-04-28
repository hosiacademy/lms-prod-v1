#!/usr/bin/env python
"""
Assign default profile pictures to all users without profile images.
Uses gender-based assignment:
- Female users → Random from sl1.jpeg to sl6.jpeg
- Male users → Random from sm1.jpeg to sm4.jpeg
- Other/Unset → Random from any default
"""
import random
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()


class Command(BaseCommand):
    help = 'Assign default profile pictures to all users without images'

    def add_arguments(self, parser):
        parser.add_argument(
            '--overwrite',
            action='store_true',
            help='Overwrite existing images with new defaults',
        )

    def handle(self, *args, **options):
        overwrite = options['overwrite']

        # Get all users
        if overwrite:
            users = User.objects.all()
            self.stdout.write(f"Processing ALL {users.count()} users (overwrite mode)...")
        else:
            users = User.objects.filter(
                image__isnull=True
            ) | User.objects.filter(
                image=''
            )
            self.stdout.write(f"Processing {users.count()} users without profile pictures...")

        updated_count = 0
        female_images = ['profiles/defaults/sl1.jpeg', 'profiles/defaults/sl2.jpeg',
                         'profiles/defaults/sl3.jpeg', 'profiles/defaults/sl4.jpeg',
                         'profiles/defaults/sl5.jpeg', 'profiles/defaults/sl6.jpeg']
        male_images = ['profiles/defaults/sm1.jpeg', 'profiles/defaults/sm2.jpeg',
                      'profiles/defaults/sm3.jpeg', 'profiles/defaults/sm4.jpeg']
        all_images = female_images + male_images

        for user in users:
            # Skip if user already has image and not in overwrite mode
            if not overwrite and user.image and user.image.strip():
                continue

            # Assign based on gender
            if user.gender == 'female':
                selected_image = random.choice(female_images)
            elif user.gender == 'male':
                selected_image = random.choice(male_images)
            else:
                selected_image = random.choice(all_images)

            user.image = selected_image
            user.save(update_fields=['image'])
            updated_count += 1

            self.stdout.write(
                f"  [OK] {user.username} ({user.gender or 'unset'}) -> {selected_image}"
            )

        self.stdout.write(self.style.SUCCESS(
            f"\n[SUCCESS] Assigned profile pictures to {updated_count} users!"
        ))

        # Summary by gender
        female_count = User.objects.filter(gender='female').count()
        male_count = User.objects.filter(gender='male').count()
        other_count = User.objects.exclude(gender__in=['female', 'male']).count()

        self.stdout.write(f"\nDatabase Summary:")
        self.stdout.write(f"  Female users: {female_count}")
        self.stdout.write(f"  Male users: {male_count}")
        self.stdout.write(f"  Other/Unset: {other_count}")
        self.stdout.write(f"  Total users: {User.objects.count()}")
