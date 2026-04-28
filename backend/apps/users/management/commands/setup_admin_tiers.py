import os
import django
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.payments.models import AdminRole, AdminCountryAccess
from apps.localization.models import Country

User = get_user_model()

class Command(BaseCommand):
    help = 'Setup the two-tier administrator system for Hosi Academy'

    def handle(self, *args, **options):
        # 1. Tier 1 - Universal Administrator
        universal_email = 'hosimonorepo@gmail.com'
        universal_user, created = User.objects.get_or_create(
            email=universal_email,
            defaults={'username': universal_email, 'first_name': 'Universal', 'last_name': 'Admin', 'is_staff': True}
        )
        if created:
            universal_user.set_password('HosiAdmin2026!')
            universal_user.save()

        roles = [
            ('system_admin', 'System Administrator'),
            ('payment_admin', 'Payment Operations Admin'),
            ('marketing_admin', 'Sales & Marketing Admin'),
            ('hr_admin', 'HR Admin'),
            ('executive_admin', 'Executive Admin'),
            ('payment_sales_marketing_admin', 'Unified Payment & Marketing Admin'),
        ]

        for role_type, role_name in roles:
            AdminRole.objects.get_or_create(
                user=universal_user,
                role_type=role_type,
                defaults={'is_active': True}
            )
        self.stdout.write(self.style.SUCCESS(f'Universal Admin setup completed for {universal_email}'))

        # 2. Tier 2 - Country-Specific Administrators
        target_countries = ['ZW', 'ZM', 'KE', 'ZA']
        
        for country_code in target_countries:
            try:
                country = Country.objects.get(code=country_code)
            except Country.DoesNotExist:
                self.stdout.write(self.style.WARNING(f'Country {country_code} not found, skipping...'))
                continue

            for role_type, role_name in roles:
                admin_email = f"{role_type}_{country_code.lower()}@hosiacademy.africa"
                admin_user, created = User.objects.get_or_create(
                    email=admin_email,
                    defaults={
                        'username': admin_email,
                        'first_name': role_name.split(' ')[0],
                        'last_name': f'Admin ({country_code})',
                        'is_staff': True
                    }
                )
                if created:
                    admin_user.set_password('HosiAdmin2026!')
                    admin_user.save()

                admin_role, _ = AdminRole.objects.get_or_create(
                    user=admin_user,
                    role_type=role_type,
                    defaults={'is_active': True}
                )

                # Assign country access
                AdminCountryAccess.objects.get_or_create(
                    admin_role=admin_role,
                    country=country,
                    defaults={'is_active': True}
                )
            
            self.stdout.write(self.style.SUCCESS(f'Tier 2 Admins setup completed for {country.name} ({country_code})'))

        self.stdout.write(self.style.SUCCESS('All admin tiers have been synchronized.'))
