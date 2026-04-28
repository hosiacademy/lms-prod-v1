# apps/payments/management/commands/create_test_admins.py
"""
Management command to create test admin users with different roles.

Usage:
    python manage.py create_test_admins
    python manage.py create_test_admins --reset  # Delete existing test admins first
"""

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.payments.models import AdminRole
from django.db import transaction

User = get_user_model()


class Command(BaseCommand):
    help = 'Creates test admin users for Payment Admin, HR Admin, and Executive Admin roles'

    def add_arguments(self, parser):
        parser.add_argument(
            '--reset',
            action='store_true',
            help='Delete existing test admin users before creating new ones',
        )

    def handle(self, *args, **options):
        self.stdout.write(self.style.WARNING('Creating test admin users...'))

        # Test admin user configurations
        test_admins = [
            {
                'username': 'payment_admin_test',
                'email': 'payment.admin@hosi.academy',
                'first_name': 'Payment',
                'last_name': 'Admin',
                'password': 'Payment@2027',
                'role': 'payment_admin',
                'description': 'Payment Admin - Verifies and manages payments'
            },
            {
                'username': 'hr_admin_test',
                'email': 'hr.admin@hosi.academy',
                'first_name': 'HR',
                'last_name': 'Admin',
                'password': 'HRAdmin@2027',
                'role': 'hr_admin',
                'description': 'HR Admin - Manages learners and enrollments'
            },
            {
                'username': 'executive_admin_test',
                'email': 'executive.admin@hosi.academy',
                'first_name': 'Executive',
                'last_name': 'Admin',
                'password': 'Executive@2027',
                'role': 'executive_admin',
                'description': 'Executive Admin - C-Suite analytics and insights'
            },
        ]

        # Reset if requested
        if options['reset']:
            self.stdout.write(self.style.WARNING('Resetting existing test admin users...'))
            for admin_config in test_admins:
                try:
                    user = User.objects.get(username=admin_config['username'])
                    # Delete associated admin roles first
                    AdminRole.objects.filter(user=user).delete()
                    user.delete()
                    self.stdout.write(
                        self.style.SUCCESS(f"  [+] Deleted existing user: {admin_config['username']}")
                    )
                except User.DoesNotExist:
                    pass

        # Create test admin users
        created_users = []
        for admin_config in test_admins:
            try:
                with transaction.atomic():
                    # Check if user already exists
                    user, created = User.objects.get_or_create(
                        username=admin_config['username'],
                        defaults={
                            'email': admin_config['email'],
                            'first_name': admin_config['first_name'],
                            'last_name': admin_config['last_name'],
                            'is_staff': True,
                            'is_active': True,
                        }
                    )

                    if created:
                        # Set password for newly created user
                        user.set_password(admin_config['password'])
                        user.save()
                        self.stdout.write(
                            self.style.SUCCESS(f"[+] Created user: {admin_config['username']}")
                        )
                    else:
                        self.stdout.write(
                            self.style.WARNING(f"  User already exists: {admin_config['username']}")
                        )

                    # Create or get admin role
                    admin_role, role_created = AdminRole.objects.get_or_create(
                        user=user,
                        role_type=admin_config['role'],
                        defaults={
                            'is_active': True,
                            'notes': f"Test admin user for {admin_config['role']} role"
                        }
                    )

                    if role_created:
                        self.stdout.write(
                            self.style.SUCCESS(f"  [+] Assigned role: {admin_config['role']}")
                        )
                    else:
                        # Ensure role is active
                        if not admin_role.is_active:
                            admin_role.is_active = True
                            admin_role.save()
                            self.stdout.write(
                                self.style.SUCCESS(f"  [+] Reactivated role: {admin_config['role']}")
                            )
                        else:
                            self.stdout.write(
                                self.style.WARNING(f"  Role already assigned: {admin_config['role']}")
                            )

                    created_users.append({
                        'user': user,
                        'role': admin_config['role'],
                        'description': admin_config['description'],
                        'password': admin_config['password']
                    })

            except Exception as e:
                self.stdout.write(
                    self.style.ERROR(f"[!] Error creating {admin_config['username']}: {str(e)}")
                )

        # Print summary
        self.stdout.write('\n' + '=' * 80)
        self.stdout.write(self.style.SUCCESS('\n[SUCCESS] Test Admin Users Created Successfully!\n'))
        self.stdout.write('=' * 80 + '\n')

        self.stdout.write(self.style.WARNING('Login Credentials:\n'))

        for user_info in created_users:
            self.stdout.write(f"\n{user_info['description']}:")
            self.stdout.write(f"  Username: {user_info['user'].username}")
            self.stdout.write(f"  Email:    {user_info['user'].email}")
            self.stdout.write(f"  Password: {user_info['password']}")
            self.stdout.write(f"  Role:     {user_info['role']}")

        self.stdout.write('\n' + '=' * 80)
        self.stdout.write(self.style.WARNING('\nRole Descriptions:\n'))
        self.stdout.write('  * Payment Admin:    Verifies cash payments, manages payment approvals')
        self.stdout.write('  * HR Admin:         Manages learner data, enrollments, and certificates')
        self.stdout.write('  * Executive Admin:  C-Suite analytics, revenue insights, and reports')
        self.stdout.write('\n' + '=' * 80)

        self.stdout.write(self.style.WARNING('\n[!] IMPORTANT: Change these passwords in production!\n'))

        # Show role verification
        self.stdout.write('\n' + self.style.SUCCESS('Verifying roles...'))
        for user_info in created_users:
            user = user_info['user']
            roles = list(AdminRole.get_user_roles(user))
            self.stdout.write(
                f"  {user.username}: {', '.join(roles) if roles else 'No roles'}"
            )

        self.stdout.write('\n' + self.style.SUCCESS('[SUCCESS] All test admin users are ready to use!\n'))
