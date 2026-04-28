"""
Management command to populate ALL 54 African countries

Usage:
    python manage.py populate_african_countries
    python manage.py populate_african_countries --clear
"""

from django.core.management.base import BaseCommand
from apps.localization.models import Country


class Command(BaseCommand):
    help = 'Populate all 54 African countries'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing countries before populating',
        )

    def handle(self, *args, **options):
        if options['clear']:
            self.stdout.write(self.style.WARNING('Clearing existing countries...'))
            Country.objects.all().delete()

        self.stdout.write(self.style.SUCCESS('Populating all 54 African countries...'))

        countries = [
            # NORTH AFRICA (7)
            {'code': 'DZ', 'name': 'Algeria'},
            {'code': 'EG', 'name': 'Egypt'},
            {'code': 'LY', 'name': 'Libya'},
            {'code': 'MR', 'name': 'Mauritania'},
            {'code': 'MA', 'name': 'Morocco'},
            {'code': 'SD', 'name': 'Sudan'},
            {'code': 'TN', 'name': 'Tunisia'},

            # WEST AFRICA (16)
            {'code': 'BJ', 'name': 'Benin'},
            {'code': 'BF', 'name': 'Burkina Faso'},
            {'code': 'CV', 'name': 'Cape Verde'},
            {'code': 'CI', 'name': 'Ivory Coast'},
            {'code': 'GM', 'name': 'Gambia'},
            {'code': 'GH', 'name': 'Ghana'},
            {'code': 'GN', 'name': 'Guinea'},
            {'code': 'GW', 'name': 'Guinea-Bissau'},
            {'code': 'LR', 'name': 'Liberia'},
            {'code': 'ML', 'name': 'Mali'},
            {'code': 'NE', 'name': 'Niger'},
            {'code': 'NG', 'name': 'Nigeria'},
            {'code': 'SN', 'name': 'Senegal'},
            {'code': 'SL', 'name': 'Sierra Leone'},
            {'code': 'TG', 'name': 'Togo'},

            # EAST AFRICA (18)
            {'code': 'BI', 'name': 'Burundi'},
            {'code': 'KM', 'name': 'Comoros'},
            {'code': 'DJ', 'name': 'Djibouti'},
            {'code': 'ER', 'name': 'Eritrea'},
            {'code': 'ET', 'name': 'Ethiopia'},
            {'code': 'KE', 'name': 'Kenya'},
            {'code': 'MG', 'name': 'Madagascar'},
            {'code': 'MW', 'name': 'Malawi'},
            {'code': 'MU', 'name': 'Mauritius'},
            {'code': 'MZ', 'name': 'Mozambique'},
            {'code': 'RW', 'name': 'Rwanda'},
            {'code': 'SC', 'name': 'Seychelles'},
            {'code': 'SO', 'name': 'Somalia'},
            {'code': 'SS', 'name': 'South Sudan'},
            {'code': 'TZ', 'name': 'Tanzania'},
            {'code': 'UG', 'name': 'Uganda'},
            {'code': 'ZM', 'name': 'Zambia'},
            {'code': 'ZW', 'name': 'Zimbabwe'},

            # CENTRAL AFRICA (8)
            {'code': 'CM', 'name': 'Cameroon'},
            {'code': 'CF', 'name': 'Central African Republic'},
            {'code': 'TD', 'name': 'Chad'},
            {'code': 'CG', 'name': 'Congo (Brazzaville)'},
            {'code': 'CD', 'name': 'Congo (Kinshasa)'},
            {'code': 'GQ', 'name': 'Equatorial Guinea'},
            {'code': 'GA', 'name': 'Gabon'},
            {'code': 'ST', 'name': 'Sao Tome and Principe'},

            # SOUTHERN AFRICA (5)
            {'code': 'AO', 'name': 'Angola'},
            {'code': 'BW', 'name': 'Botswana'},
            {'code': 'SZ', 'name': 'Eswatini'},
            {'code': 'LS', 'name': 'Lesotho'},
            {'code': 'NA', 'name': 'Namibia'},
            {'code': 'ZA', 'name': 'South Africa'},
        ]

        created_count = 0
        updated_count = 0

        for country_data in countries:
            country, created = Country.objects.get_or_create(
                code=country_data['code'],
                defaults={'name': country_data['name'], 'is_active': True}
            )
            if created:
                created_count += 1
                self.stdout.write(f"  + Created: {country.name} ({country.code})")
            else:
                updated_count += 1
                self.stdout.write(f"  = Exists: {country.name} ({country.code})")

        self.stdout.write(self.style.SUCCESS(f'\nDone! Created: {created_count}, Existed: {updated_count}'))
        self.stdout.write(self.style.SUCCESS(f'Total African countries: {Country.objects.count()}'))
