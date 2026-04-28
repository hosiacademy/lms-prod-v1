#!/usr/bin/env python
"""
Test that all users have profile pictures and URLs are working
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.conf import settings
import os

User = get_user_model()


class Command(BaseCommand):
    help = 'Test that all users have profile pictures'

    def handle(self, *args, **options):
        total_users = User.objects.count()
        self.stdout.write(f"\n=== Testing Profile Pictures for {total_users} Users ===\n")

        users_with_image_field = User.objects.exclude(image__isnull=True).exclude(image='').count()
        users_without_image_field = total_users - users_with_image_field

        self.stdout.write(f"Users with 'image' field set: {users_with_image_field}")
        self.stdout.write(f"Users without 'image' field: {users_without_image_field}")

        # Test a sample of users
        sample_users = User.objects.all()[:10]

        self.stdout.write(f"\n=== Testing Sample of {len(sample_users)} Users ===\n")

        for user in sample_users:
            # Get profile picture URL
            profile_pic_url = user.get_profile_picture_url()

            # Extract file path from URL
            if profile_pic_url:
                # Remove protocol and domain
                if 'http' in profile_pic_url:
                    path_part = profile_pic_url.split(settings.MEDIA_URL)[-1]
                else:
                    path_part = profile_pic_url.replace(settings.MEDIA_URL, '')

                file_path = os.path.join(settings.MEDIA_ROOT, path_part)
                file_exists = os.path.exists(file_path)

                status = "✓" if file_exists else "✗"
                self.stdout.write(
                    f"{status} {user.username:30} | Gender: {user.gender or 'None':8} | "
                    f"Image Field: {user.image or 'None':30} | "
                    f"URL: {profile_pic_url}"
                )

                if not file_exists:
                    self.stdout.write(
                        self.style.ERROR(f"  FILE NOT FOUND: {file_path}")
                    )
            else:
                self.stdout.write(
                    self.style.ERROR(
                        f"✗ {user.username:30} | NO PROFILE PICTURE URL RETURNED"
                    )
                )

        # Check default images directory
        self.stdout.write(f"\n=== Checking Default Images Directory ===\n")

        defaults_dir = os.path.join(settings.MEDIA_ROOT, 'profiles', 'defaults')

        if os.path.exists(defaults_dir):
            default_images = os.listdir(defaults_dir)
            self.stdout.write(
                self.style.SUCCESS(
                    f"✓ Defaults directory exists: {defaults_dir}"
                )
            )
            self.stdout.write(f"  Found {len(default_images)} default images:")
            for img in sorted(default_images):
                file_path = os.path.join(defaults_dir, img)
                size_kb = os.path.getsize(file_path) / 1024
                self.stdout.write(f"    - {img:15} ({size_kb:.1f} KB)")
        else:
            self.stdout.write(
                self.style.ERROR(
                    f"✗ Defaults directory NOT FOUND: {defaults_dir}"
                )
            )
            self.stdout.write(
                self.style.WARNING(
                    "\n  SOLUTION: Copy default profile images to the media folder:\n"
                    f"    mkdir -p {defaults_dir}\n"
                    f"    cp /path/to/your/images/sl*.jpeg {defaults_dir}/\n"
                    f"    cp /path/to/your/images/sm*.jpeg {defaults_dir}/\n"
                    "\n  Where sl*.jpeg are female default images and sm*.jpeg are male default images\n"
                )
            )

        # Summary
        self.stdout.write(f"\n=== Summary ===\n")
        self.stdout.write(f"Total Users: {total_users}")
        self.stdout.write(f"Users with image field: {users_with_image_field}")
        self.stdout.write(f"Users relying on defaults: {users_without_image_field}")

        if users_without_image_field > 0 and not os.path.exists(defaults_dir):
            self.stdout.write(
                self.style.ERROR(
                    f"\n[ERROR] {users_without_image_field} users have no image field "
                    "AND default images directory is missing!"
                )
            )
        elif users_without_image_field > 0:
            self.stdout.write(
                self.style.SUCCESS(
                    f"\n[OK] {users_without_image_field} users will use gender-based "
                    "default images"
                )
            )
        else:
            self.stdout.write(
                self.style.SUCCESS(
                    "\n[OK] All users have profile pictures assigned!"
                )
            )
