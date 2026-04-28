"""
Django management command to create admin credentials for Kenya, Zimbabwe, Zambia, and Botswana.
Each admin role is restricted to their assigned country only.
System Admin has unrestricted access to all countries.

Usage:
    python manage.py create_country_admins

Credentials will be displayed in the output and saved to a file.
"""
import random
import string
from django.core.management.base import BaseCommand, CommandError
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.localization.models import Country
from apps.payments.models import AdminRole, AdminCountryAccess

User = get_user_model()


class Command(BaseCommand):
    help = 'Create admin credentials for Kenya, Zimbabwe, Zambia, and Botswana with country-based restrictions'

    # Country configurations
    COUNTRIES_CONFIG = {
        'KE': {
            'name': 'Kenya',
            'phone_code': '+254',
            'currency': 'KES',
        },
        'ZW': {
            'name': 'Zimbabwe',
            'phone_code': '+263',
            'currency': 'USD',
        },
        'ZM': {
            'name': 'Zambia',
            'phone_code': '+260',
            'currency': 'ZMW',
        },
        'BW': {
            'name': 'Botswana',
            'phone_code': '+267',
            'currency': 'BWP',
        },
    }

    # Password pattern: CountryCode+Role+Year+Special
    # Example: KE-HRAdmin-2026@
    PASSWORD_PATTERN = '{country_code}-{role_short}-{year}@'

    def add_arguments(self, parser):
        parser.add_argument(
            '--force',
            action='store_true',
            help='Force recreate admins if they already exist',
        )
        parser.add_argument(
            '--output-file',
            type=str,
            default='admin_credentials.txt',
            help='Output file for credentials (default: admin_credentials.txt)',
        )

    def generate_password(self, country_code, role_short):
        """Generate secure password based on pattern"""
        return self.PASSWORD_PATTERN.format(
            country_code=country_code,
            role_short=role_short,
            year=timezone.now().year
        )

    def generate_username(self, country_code, role_type):
        """Generate username based on country and role"""
        role_prefix = {
            'hr_admin': 'hr',
            'payment_admin': 'payment',
            'executive_admin': 'executive',
        }.get(role_type, 'admin')
        
        return f'{role_prefix}_{country_code.lower()}'

    def generate_email(self, country_code, role_type, country_name):
        """Generate email based on country and role"""
        role_prefix = {
            'hr_admin': 'hr',
            'payment_admin': 'payments',
            'executive_admin': 'executive',
        }.get(role_type, 'admin')
        
        country_short = country_name.lower().replace(' ', '_')
        return f'{role_prefix}.{country_short}@hosi.academy'

    def get_or_create_country(self, code, config):
        """Get or create a country"""
        country, created = Country.objects.get_or_create(
            code=code,
            defaults={
                'name': config['name'],
                'is_active': True,
            }
        )
        if created:
            self.stdout.write(
                self.style.SUCCESS(f'✓ Created country: {config["name"]} ({code})')
            )
        else:
            self.stdout.write(
                self.style.WARNING(f'• Country exists: {config["name"]} ({code})')
            )
        return country

    def create_or_update_admin(self, username, email, password, country, role_type, force=False):
        """Create or update an admin user with role and country access"""
        
        # Check if user exists
        existing_user = User.objects.filter(username=username).first()
        
        if existing_user:
            if not force:
                self.stdout.write(
                    self.style.WARNING(f'• User exists: {username} (skipping, use --force to recreate)')
                )
                return existing_user, False
            
            # Delete existing user if force
            self.stdout.write(
                self.style.WARNING(f'→ Deleting existing user: {username}')
            )
            existing_user.delete()
        
        # Create new user
        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            role_id=1,  # Admin role
            name=f'{role_type.replace("_", " ").title()} - {country.name}',
            country=country,
        )
        
        # Create admin role
        admin_role = AdminRole.objects.create(
            user=user,
            role_type=role_type,
            is_active=True,
            notes=f'Auto-created for {country.name} - {timezone.now().strftime("%Y-%m-%d")}'
        )
        
        # Assign country access
        AdminCountryAccess.objects.create(
            admin_role=admin_role,
            country=country,
            is_active=True,
            notes=f'Auto-assigned country access for {country.name}'
        )
        
        return user, True

    def create_system_admin(self, force=False):
        """Create System Admin (superuser) with unrestricted access"""
        username = 'system_admin'
        email = 'system.admin@hosi.academy'
        password = 'System@Hosi2026!'
        
        existing_user = User.objects.filter(username=username).first()
        
        if existing_user:
            if not force:
                self.stdout.write(
                    self.style.WARNING(f'• System Admin exists: {username} (skipping)')
                )
                return existing_user, False
            
            self.stdout.write(
                self.style.WARNING(f'→ Deleting existing System Admin: {username}')
            )
            existing_user.delete()
        
        # Create superuser (no country restrictions)
        user = User.objects.create_superuser(
            username=username,
            email=email,
            password=password,
            role_id=1,
            name='System Administrator',
        )
        
        return user, True

    def handle(self, *args, **options):
        force = options['force']
        output_file = options['output_file']
        
        self.stdout.write(self.style.SUCCESS('=' * 70))
        self.stdout.write(self.style.SUCCESS('HOSI ACADEMY - ADMIN CREDENTIALS SETUP'))
        self.stdout.write(self.style.SUCCESS('Country-Based Access Control for Kenya, Zimbabwe, Zambia, Botswana'))
        self.stdout.write(self.style.SUCCESS('=' * 70))
        self.stdout.write('')
        
        credentials = []
        
        # Step 1: Create/verify countries
        self.stdout.write(self.style.SUCCESS('STEP 1: Setting up countries...'))
        self.stdout.write('-' * 70)
        countries = {}
        for code, config in self.COUNTRIES_CONFIG.items():
            countries[code] = self.get_or_create_country(code, config)
        self.stdout.write('')
        
        # Step 2: Create System Admin
        self.stdout.write(self.style.SUCCESS('STEP 2: Creating System Admin (Unrestricted Access)...'))
        self.stdout.write('-' * 70)
        system_admin, created = self.create_system_admin(force)
        if created or force:
            self.stdout.write(
                self.style.SUCCESS(f'✓ Created System Admin: {system_admin.username}')
            )
        credentials.append({
            'role': 'System Admin',
            'username': system_admin.username,
            'email': system_admin.email,
            'password': 'System@Hosi2026!',
            'countries': 'ALL (Unrestricted)',
            'access_level': 'Full system access - All countries, all roles',
        })
        self.stdout.write('')
        
        # Step 3: Create country-specific admins
        self.stdout.write(self.style.SUCCESS('STEP 3: Creating Country-Specific Admins...'))
        self.stdout.write('-' * 70)
        
        role_types = [
            ('hr_admin', 'HR Admin', 'hr'),
            ('payment_admin', 'Payment Admin', 'payment'),
            ('executive_admin', 'Executive Admin', 'exec'),
        ]
        
        for country_code, country in countries.items():
            self.stdout.write(self.style.SUCCESS(f'\n{country.name} ({country_code}):'))
            
            for role_type, role_name, role_short in role_types:
                username = self.generate_username(country_code, role_type)
                email = self.generate_email(country_code, role_type, country.name)
                password = self.generate_password(country_code, role_short)
                
                user, created = self.create_or_update_admin(
                    username=username,
                    email=email,
                    password=password,
                    country=country,
                    role_type=role_type,
                    force=force
                )
                
                if created or force:
                    self.stdout.write(
                        self.style.SUCCESS(f'  ✓ Created: {role_name} ({username})')
                    )
                else:
                    self.stdout.write(
                        self.style.WARNING(f'  • Skipped: {role_name} ({username})')
                    )
                
                credentials.append({
                    'role': role_name,
                    'country': country.name,
                    'username': username,
                    'email': email,
                    'password': password,
                    'countries': country.name,
                    'access_level': f'{role_name} access - {country.name} only',
                })
        
        self.stdout.write('')
        
        # Step 4: Display credentials
        self.stdout.write(self.style.SUCCESS('=' * 70))
        self.stdout.write(self.style.SUCCESS('ADMIN CREDENTIALS'))
        self.stdout.write(self.style.SUCCESS('=' * 70))
        
        for cred in credentials:
            self.stdout.write('')
            self.stdout.write(self.style.SUCCESS(f"Role: {cred['role']}"))
            if 'country' in cred:
                self.stdout.write(f"  Country:    {cred['country']}")
            self.stdout.write(f"  Username:   {cred['username']}")
            self.stdout.write(f"  Email:      {cred['email']}")
            self.stdout.write(f"  Password:   {cred['password']}")
            self.stdout.write(f"  Access:     {cred['access_level']}")
        
        self.stdout.write('')
        
        # Step 5: Save to file
        self.stdout.write(self.style.SUCCESS('=' * 70))
        self.stdout.write(self.style.SUCCESS(f'Saving credentials to: {output_file}'))
        self.stdout.write('=' * 70)
        
        with open(output_file, 'w') as f:
            f.write('=' * 70 + '\n')
            f.write('HOSI ACADEMY - ADMIN CREDENTIALS\n')
            f.write('Country-Based Access Control\n')
            f.write(f'Generated: {timezone.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
            f.write('=' * 70 + '\n\n')
            
            f.write('IMPORTANT SECURITY NOTES:\n')
            f.write('-' * 70 + '\n')
            f.write('1. Change all passwords immediately after first login\n')
            f.write('2. Store credentials securely - do not share via email\n')
            f.write('3. System Admin has unrestricted access to all countries\n')
            f.write('4. Country admins can ONLY access their assigned country\n')
            f.write('5. Contact system administrator for access issues\n')
            f.write('\n')
            
            for cred in credentials:
                f.write('-' * 70 + '\n')
                f.write(f"Role: {cred['role']}\n")
                if 'country' in cred:
                    f.write(f"  Country:    {cred['country']}\n")
                f.write(f"  Username:   {cred['username']}\n")
                f.write(f"  Email:      {cred['email']}\n")
                f.write(f"  Password:   {cred['password']}\n")
                f.write(f"  Access:     {cred['access_level']}\n")
                f.write('\n')
            
            f.write('=' * 70 + '\n')
            f.write('END OF CREDENTIALS\n')
            f.write('=' * 70 + '\n')
        
        self.stdout.write(self.style.SUCCESS(f'✓ Credentials saved to: {output_file}'))
        
        # Step 6: Summary
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=' * 70))
        self.stdout.write(self.style.SUCCESS('SUMMARY'))
        self.stdout.write(self.style.SUCCESS('=' * 70))
        self.stdout.write(f'  Countries configured: {len(countries)}')
        self.stdout.write(f'  Total admin accounts: {len(credentials)}')
        self.stdout.write(f'  System Admin: 1 (unrestricted)')
        self.stdout.write(f'  Country Admins: {len(credentials) - 1} (country-restricted)')
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('Access Control Rules:'))
        self.stdout.write('  • System Admin: Full access to all countries')
        self.stdout.write('  • HR Admin: Can only view/manage users in assigned country')
        self.stdout.write('  • Payment Admin: Can only view payments in assigned country')
        self.stdout.write('  • Executive Admin: Can only view analytics for assigned country')
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('✓ Admin credentials setup complete!'))
        self.stdout.write('')
