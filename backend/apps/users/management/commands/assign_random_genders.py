#!/usr/bin/env python
"""
Assign random genders to users who don't have gender set.
Uses realistic distribution: 50% female, 50% male
"""
import random
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()


class Command(BaseCommand):
    help = 'Assign random genders to users without gender set'

    def handle(self, *args, **options):
        # Get users without gender
        users = User.objects.filter(gender__isnull=True) | User.objects.filter(gender='')
        total = users.count()

        self.stdout.write(f"Processing {total} users without gender...")

        if total == 0:
            self.stdout.write(self.style.WARNING("All users already have gender set!"))
            return

        updated_count = 0
        female_count = 0
        male_count = 0

        # Randomly assign 50% female, 50% male
        genders = ['female', 'male']

        for user in users:
            selected_gender = random.choice(genders)
            user.gender = selected_gender
            user.save(update_fields=['gender'])
            updated_count += 1

            if selected_gender == 'female':
                female_count += 1
            else:
                male_count += 1

            if updated_count % 20 == 0:
                self.stdout.write(f"  Processed {updated_count}/{total} users...")

        self.stdout.write(self.style.SUCCESS(
            f"\n[SUCCESS] Assigned genders to {updated_count} users!"
        ))

        self.stdout.write(f"\nGender Distribution:")
        self.stdout.write(f"  Female: {female_count} ({female_count/total*100:.1f}%)")
        self.stdout.write(f"  Male: {male_count} ({male_count/total*100:.1f}%)")
