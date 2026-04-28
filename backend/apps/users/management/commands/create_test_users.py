"""
Django management command to create test users for development/testing
Usage: python manage.py create_test_users
"""

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone

User = get_user_model()


class Command(BaseCommand):
    help = 'Creates test users for development and testing'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Creating test users...'))

        # Test Instructor: Sam
        instructor_email = 'sam@hosiafrica.com'
        instructor_password = '2222'

        # Check if user already exists
        if User.objects.filter(email=instructor_email).exists():
            instructor = User.objects.get(email=instructor_email)
            self.stdout.write(
                self.style.WARNING(
                    f'Instructor user already exists: {instructor_email}'
                )
            )
            # Update password and ensure correct role
            instructor.set_password(instructor_password)
            instructor.role_id = 2  # Instructor role
            instructor.is_staff = True
            instructor.is_active = True
            instructor.is_aicerts_instructor = True  # Mark as AICerts instructor
            instructor.source = 'test_account'
            instructor.fullname = 'Sam Instructor'
            instructor.confirmed = True
            instructor.suspended = False
            instructor.save()
            self.stdout.write(
                self.style.SUCCESS(
                    f'[OK] Updated instructor: {instructor_email} (password reset to {instructor_password})'
                )
            )
        else:
            # Create new instructor
            instructor = User.objects.create_user(
                username='sam_instructor',
                email=instructor_email,
                password=instructor_password,
                first_name='Sam',
                last_name='Instructor',
                name='Sam Instructor',
                role_id=2,  # Instructor role (1=Admin, 2=Instructor, 3=Student)
                is_staff=True,
                is_active=True,
                email_verify='1',  # Email verified
                email_verified_at=timezone.now(),
                phone='+27 82 555 0001',
                city='Johannesburg',
                country='South Africa',
                headline='Expert Instructor in AI & Blockchain',
                about='Experienced instructor specializing in AI, Machine Learning, and Blockchain technologies. '
                      'Passionate about education and helping students achieve their goals.',
                balance=0.0,
                payout='PayPal',
                payout_email='sam@hosiafrica.com',
                # AICerts Integration Fields
                is_aicerts_instructor=True,
                fullname='Sam Instructor',
                confirmed=True,
                suspended=False,
                source='test_account',
                timezone='Africa/Johannesburg',
            )
            self.stdout.write(
                self.style.SUCCESS(
                    f'[OK] Created instructor: {instructor_email} with password: {instructor_password}'
                )
            )

        # Test Student: John Doe
        student_email = 'student@hosiafrica.com'
        student_password = '1111'

        if User.objects.filter(email=student_email).exists():
            student = User.objects.get(email=student_email)
            self.stdout.write(
                self.style.WARNING(f'Student user already exists: {student_email}')
            )
            student.set_password(student_password)
            student.role_id = 3  # Student role
            student.is_active = True
            student.source = 'test_account'
            student.fullname = 'John Doe'
            student.confirmed = True
            student.suspended = False
            student.save()
            self.stdout.write(
                self.style.SUCCESS(
                    f'[OK] Updated student: {student_email} (password reset to {student_password})'
                )
            )
        else:
            student = User.objects.create_user(
                username='john_student',
                email=student_email,
                password=student_password,
                first_name='John',
                last_name='Doe',
                name='John Doe',
                role_id=3,  # Student role
                is_staff=False,
                is_active=True,
                email_verify='1',
                email_verified_at=timezone.now(),
                phone='+27 83 555 0002',
                city='Cape Town',
                country='South Africa',
                headline='Aspiring AI Professional',
                about='Passionate learner focused on AI and Data Science. Enrolled in multiple courses to advance career.',
                # AICerts Integration Fields
                fullname='John Doe',
                confirmed=True,
                suspended=False,
                source='test_account',
                timezone='Africa/Johannesburg',
            )
            self.stdout.write(
                self.style.SUCCESS(
                    f'[OK] Created student: {student_email} with password: {student_password}'
                )
            )

        # Test Admin: Admin User
        admin_email = 'admin@hosiafrica.com'
        admin_password = 'admin1234'

        if User.objects.filter(email=admin_email).exists():
            admin = User.objects.get(email=admin_email)
            self.stdout.write(
                self.style.WARNING(f'Admin user already exists: {admin_email}')
            )
            admin.set_password(admin_password)
            admin.role_id = 1  # Admin role
            admin.is_superuser = True
            admin.is_staff = True
            admin.is_active = True
            admin.save()
            self.stdout.write(
                self.style.SUCCESS(
                    f'[OK] Updated admin: {admin_email} (password reset to {admin_password})'
                )
            )
        else:
            admin = User.objects.create_superuser(
                username='admin',
                email=admin_email,
                password=admin_password,
                first_name='Admin',
                last_name='User',
                name='Admin User',
                role_id=1,  # Admin role
                email_verify='1',
                email_verified_at=timezone.now(),
                phone='+27 11 555 0000',
                city='Pretoria',
                country='South Africa',
                headline='System Administrator',
                about='Platform administrator with full system access.',
            )
            self.stdout.write(
                self.style.SUCCESS(
                    f'[OK] Created admin: {admin_email} with password: {admin_password}'
                )
            )

        # Summary
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=' * 60))
        self.stdout.write(self.style.SUCCESS('Test Users Created Successfully!'))
        self.stdout.write(self.style.SUCCESS('=' * 60))
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('INSTRUCTOR LOGIN:'))
        self.stdout.write(f'  Email:    {instructor_email}')
        self.stdout.write(f'  Password: {instructor_password}')
        self.stdout.write(f'  Role:     Instructor (role_id=2)')
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('STUDENT LOGIN:'))
        self.stdout.write(f'  Email:    {student_email}')
        self.stdout.write(f'  Password: {student_password}')
        self.stdout.write(f'  Role:     Student (role_id=3)')
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('ADMIN LOGIN:'))
        self.stdout.write(f'  Email:    {admin_email}')
        self.stdout.write(f'  Password: {admin_password}')
        self.stdout.write(f'  Role:     Admin (role_id=1, superuser)')
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=' * 60))
        self.stdout.write('')
        self.stdout.write(
            self.style.WARNING(
                'NOTE: These are test credentials for development only. '
                'Do not use in production!'
            )
        )
