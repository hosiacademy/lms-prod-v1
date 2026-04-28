"""
Management command to populate ALL African holidays for ALL 54 African countries.

Includes:
- National holidays (Independence Days, National Days)
- Christian holidays (Christmas, Easter, Good Friday)
- Muslim holidays (Eid al-Fitr, Eid al-Adha, Mawlid)
- Country-specific holidays
- Cultural celebrations

Usage:
    python manage.py populate_african_holidays
    python manage.py populate_african_holidays --clear  # Clear existing and repopulate
"""

from django.core.management.base import BaseCommand
from django.db import transaction
from apps.localization.models import Country, PublicHoliday


class Command(BaseCommand):
    help = 'Populate ALL African holidays for all 54 African countries'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing holidays before populating',
        )

    def handle(self, *args, **options):
        if options['clear']:
            self.stdout.write(self.style.WARNING('Clearing existing holidays...'))
            PublicHoliday.objects.all().delete()

        self.stdout.write(self.style.SUCCESS('Starting African holidays population...'))

        # Common holidays across multiple countries
        self.common_holidays = self.get_common_holidays()

        # Populate all countries
        self.populate_all_countries()

        total = PublicHoliday.objects.count()
        self.stdout.write(self.style.SUCCESS(f'\n[SUCCESS] Populated {total} holidays across all African countries!'))

    def get_common_holidays(self):
        """Common holidays shared across many African countries"""
        return {
            'christian': [
                {
                    'name': 'New Year\'s Day',
                    'month': 1, 'day': 1,
                    'type': 'national',
                    'description': 'First day of the Gregorian calendar year'
                },
                {
                    'name': 'Good Friday',
                    'type': 'religious_christian',
                    'is_fixed_date': False,
                    'year_dates': {
                        '2024': '2024-03-29',
                        '2025': '2025-04-18',
                        '2026': '2026-04-03',
                        '2027': '2027-03-26',
                        '2028': '2028-04-14',
                    },
                    'description': 'Friday before Easter Sunday'
                },
                {
                    'name': 'Easter Sunday',
                    'type': 'religious_christian',
                    'is_fixed_date': False,
                    'year_dates': {
                        '2024': '2024-03-31',
                        '2025': '2025-04-20',
                        '2026': '2026-04-05',
                        '2027': '2027-03-28',
                        '2028': '2028-04-16',
                    },
                    'description': 'Resurrection of Jesus Christ'
                },
                {
                    'name': 'Easter Monday',
                    'type': 'religious_christian',
                    'is_fixed_date': False,
                    'year_dates': {
                        '2024': '2024-04-01',
                        '2025': '2025-04-21',
                        '2026': '2026-04-06',
                        '2027': '2027-03-29',
                        '2028': '2028-04-17',
                    },
                    'description': 'Monday after Easter Sunday'
                },
                {
                    'name': 'Christmas Day',
                    'month': 12, 'day': 25,
                    'type': 'religious_christian',
                    'description': 'Birth of Jesus Christ'
                },
                {
                    'name': 'Boxing Day',
                    'month': 12, 'day': 26,
                    'type': 'national',
                    'description': 'Day after Christmas'
                },
            ],
            'muslim': [
                {
                    'name': 'Eid al-Fitr',
                    'type': 'religious_muslim',
                    'is_fixed_date': False,
                    'duration_days': 2,
                    'year_dates': {
                        '2024': '2024-04-10',
                        '2025': '2025-03-30',
                        '2026': '2026-03-20',
                        '2027': '2027-03-09',
                        '2028': '2028-02-26',
                    },
                    'description': 'End of Ramadan fasting'
                },
                {
                    'name': 'Eid al-Adha',
                    'type': 'religious_muslim',
                    'is_fixed_date': False,
                    'duration_days': 2,
                    'year_dates': {
                        '2024': '2024-06-16',
                        '2025': '2025-06-06',
                        '2026': '2026-05-27',
                        '2027': '2027-05-16',
                        '2028': '2028-05-04',
                    },
                    'description': 'Festival of Sacrifice'
                },
                {
                    'name': 'Mawlid al-Nabi',
                    'native_name': 'Prophet\'s Birthday',
                    'type': 'religious_muslim',
                    'is_fixed_date': False,
                    'year_dates': {
                        '2024': '2024-09-15',
                        '2025': '2025-09-04',
                        '2026': '2026-08-25',
                        '2027': '2027-08-14',
                        '2028': '2028-08-02',
                    },
                    'description': 'Birth of Prophet Muhammad'
                },
            ]
        }

    @transaction.atomic
    def populate_all_countries(self):
        """Populate holidays for all 54 African countries"""

        # NORTH AFRICA
        self.populate_algeria()
        self.populate_egypt()
        self.populate_libya()
        self.populate_mauritania()
        self.populate_morocco()
        self.populate_sudan()
        self.populate_tunisia()

        # WEST AFRICA
        self.populate_benin()
        self.populate_burkina_faso()
        self.populate_cape_verde()
        self.populate_ivory_coast()
        self.populate_gambia()
        self.populate_ghana()
        self.populate_guinea()
        self.populate_guinea_bissau()
        self.populate_liberia()
        self.populate_mali()
        self.populate_niger()
        self.populate_nigeria()
        self.populate_senegal()
        self.populate_sierra_leone()
        self.populate_togo()

        # EAST AFRICA
        self.populate_burundi()
        self.populate_comoros()
        self.populate_djibouti()
        self.populate_eritrea()
        self.populate_ethiopia()
        self.populate_kenya()
        self.populate_madagascar()
        self.populate_malawi()
        self.populate_mauritius()
        self.populate_mozambique()
        self.populate_rwanda()
        self.populate_seychelles()
        self.populate_somalia()
        self.populate_south_sudan()
        self.populate_tanzania()
        self.populate_uganda()
        self.populate_zambia()
        self.populate_zimbabwe()

        # CENTRAL AFRICA
        self.populate_cameroon()
        self.populate_central_african_republic()
        self.populate_chad()
        self.populate_congo_brazzaville()
        self.populate_congo_kinshasa()
        self.populate_equatorial_guinea()
        self.populate_gabon()
        self.populate_sao_tome_principe()

        # SOUTHERN AFRICA
        self.populate_angola()
        self.populate_botswana()
        self.populate_eswatini()
        self.populate_lesotho()
        self.populate_namibia()
        self.populate_south_africa()

    def add_holidays(self, country_code, holidays):
        """Helper to add holidays for a country"""
        try:
            country = Country.objects.get(code=country_code)
            created_count = 0

            for holiday_data in holidays:
                # Map 'type' to 'holiday_type' for model compatibility
                processed_data = holiday_data.copy()
                if 'type' in processed_data:
                    processed_data['holiday_type'] = processed_data.pop('type')

                # Set defaults
                if 'is_fixed_date' not in processed_data:
                    processed_data['is_fixed_date'] = True
                if 'is_public_holiday' not in processed_data:
                    processed_data['is_public_holiday'] = True
                if 'is_active' not in processed_data:
                    processed_data['is_active'] = True

                holiday, created = PublicHoliday.objects.get_or_create(
                    country=country,
                    name=holiday_data['name'],
                    defaults=processed_data
                )
                if created:
                    created_count += 1

            self.stdout.write(f'  [OK] {country.name}: {created_count} holidays added')
        except Country.DoesNotExist:
            self.stdout.write(self.style.WARNING(f'  [!] Country {country_code} not found in database'))

    def add_common_christian_holidays(self, country_code):
        """Add common Christian holidays to a country"""
        self.add_holidays(country_code, self.common_holidays['christian'])

    def add_common_muslim_holidays(self, country_code):
        """Add common Muslim holidays to a country"""
        self.add_holidays(country_code, self.common_holidays['muslim'])

    # ==========================================
    # NORTH AFRICA
    # ==========================================

    def populate_algeria(self):
        """Algeria (DZ) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Independence Day', 'month': 7, 'day': 5, 'type': 'national', 'description': 'Independence from France (1962)'},
            {'name': 'Revolution Day', 'month': 11, 'day': 1, 'type': 'national', 'description': 'Start of Algerian Revolution (1954)'},
        ]
        self.add_holidays('DZ', holidays)
        self.add_common_muslim_holidays('DZ')

    def populate_egypt(self):
        """Egypt (EG) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Coptic Christmas', 'month': 1, 'day': 7, 'type': 'religious_christian', 'description': 'Coptic Orthodox Christmas'},
            {'name': 'Revolution Day', 'month': 1, 'day': 25, 'type': 'national', 'description': '2011 Revolution'},
            {'name': 'Sinai Liberation Day', 'month': 4, 'day': 25, 'type': 'national', 'description': 'Sinai returned to Egypt'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Revolution Day (June 30)', 'month': 6, 'day': 30, 'type': 'national', 'description': '2013 Revolution'},
            {'name': 'Revolution Day (July 23)', 'month': 7, 'day': 23, 'type': 'national', 'description': '1952 Revolution'},
        ]
        self.add_holidays('EG', holidays)
        self.add_common_muslim_holidays('EG')

    def populate_libya(self):
        """Libya (LY) - Muslim majority"""
        holidays = [
            {'name': 'Independence Day', 'month': 12, 'day': 24, 'type': 'national', 'description': 'Independence from Italy (1951)'},
            {'name': 'Revolution Day', 'month': 2, 'day': 17, 'type': 'national', 'description': '2011 Revolution'},
        ]
        self.add_holidays('LY', holidays)
        self.add_common_muslim_holidays('LY')

    def populate_mauritania(self):
        """Mauritania (MR) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Africa Day', 'month': 5, 'day': 25, 'type': 'national', 'description': 'African Unity'},
            {'name': 'Independence Day', 'month': 11, 'day': 28, 'type': 'national', 'description': 'Independence from France (1960)'},
        ]
        self.add_holidays('MR', holidays)
        self.add_common_muslim_holidays('MR')

    def populate_morocco(self):
        """Morocco (MA) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Independence Manifesto Day', 'month': 1, 'day': 11, 'type': 'national', 'description': 'Independence Manifesto (1944)'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Throne Day', 'month': 7, 'day': 30, 'type': 'national', 'description': 'King\'s Accession'},
            {'name': 'Oued Ed-Dahab Day', 'month': 8, 'day': 14, 'type': 'national', 'description': 'Recovery of Oued Ed-Dahab'},
            {'name': 'Revolution Day', 'month': 8, 'day': 20, 'type': 'national', 'description': 'King and People\'s Revolution'},
            {'name': 'Youth Day', 'month': 8, 'day': 21, 'type': 'national', 'description': 'King\'s Birthday'},
            {'name': 'Green March Day', 'month': 11, 'day': 6, 'type': 'national', 'description': 'Green March (1975)'},
            {'name': 'Independence Day', 'month': 11, 'day': 18, 'type': 'national', 'description': 'Independence from France/Spain (1956)'},
        ]
        self.add_holidays('MA', holidays)
        self.add_common_muslim_holidays('MA')

    def populate_sudan(self):
        """Sudan (SD) - Muslim majority"""
        holidays = [
            {'name': 'Independence Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'Independence from UK/Egypt (1956)'},
            {'name': 'Coptic Christmas', 'month': 1, 'day': 7, 'type': 'religious_christian', 'description': 'Coptic Orthodox Christmas'},
        ]
        self.add_holidays('SD', holidays)
        self.add_common_muslim_holidays('SD')

    def populate_tunisia(self):
        """Tunisia (TN) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Revolution Day', 'month': 1, 'day': 14, 'type': 'national', 'description': '2011 Revolution'},
            {'name': 'Independence Day', 'month': 3, 'day': 20, 'type': 'national', 'description': 'Independence from France (1956)'},
            {'name': 'Martyrs\' Day', 'month': 4, 'day': 9, 'type': 'national', 'description': 'Commemoration of Martyrs'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Republic Day', 'month': 7, 'day': 25, 'type': 'national', 'description': 'Declaration of Republic (1957)'},
            {'name': 'Women\'s Day', 'month': 8, 'day': 13, 'type': 'national', 'description': 'Women\'s Rights'},
            {'name': 'Evacuation Day', 'month': 10, 'day': 15, 'type': 'national', 'description': 'French forces evacuated (1963)'},
        ]
        self.add_holidays('TN', holidays)
        self.add_common_muslim_holidays('TN')

    # ==========================================
    # WEST AFRICA (Part 1)
    # ==========================================

    def populate_benin(self):
        """Benin (BJ) - Christian/Muslim/Traditional"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Traditional Day', 'month': 1, 'day': 10, 'type': 'religious_traditional', 'description': 'Vodun Day'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Ascension Day', 'month': 5, 'day': 9, 'type': 'religious_christian', 'description': 'Ascension of Jesus'},
            {'name': 'Independence Day', 'month': 8, 'day': 1, 'type': 'national', 'description': 'Independence from France (1960)'},
            {'name': 'Assumption Day', 'month': 8, 'day': 15, 'type': 'religious_christian', 'description': 'Assumption of Mary'},
            {'name': 'Armed Forces Day', 'month': 10, 'day': 26, 'type': 'national', 'description': 'Armed Forces'},
            {'name': 'All Saints\' Day', 'month': 11, 'day': 1, 'type': 'religious_christian', 'description': 'All Saints'},
            {'name': 'National Day', 'month': 11, 'day': 30, 'type': 'national', 'description': 'National Day'},
        ]
        self.add_holidays('BJ', holidays)
        self.add_common_christian_holidays('BJ')
        self.add_common_muslim_holidays('BJ')

    def populate_burkina_faso(self):
        """Burkina Faso (BF) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Women\'s Day', 'month': 3, 'day': 8, 'type': 'national', 'description': 'International Women\'s Day'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Independence Day', 'month': 8, 'day': 5, 'type': 'national', 'description': 'Independence from France (1960)'},
            {'name': 'Assumption Day', 'month': 8, 'day': 15, 'type': 'religious_christian', 'description': 'Assumption of Mary'},
            {'name': 'All Saints\' Day', 'month': 11, 'day': 1, 'type': 'religious_christian', 'description': 'All Saints'},
            {'name': 'Republic Day', 'month': 12, 'day': 11, 'type': 'national', 'description': 'Proclamation of Republic (1958)'},
        ]
        self.add_holidays('BF', holidays)
        self.add_common_christian_holidays('BF')
        self.add_common_muslim_holidays('BF')

    def populate_cape_verde(self):
        """Cape Verde (CV) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'National Heroes Day', 'month': 1, 'day': 20, 'type': 'national', 'description': 'Amílcar Cabral Day'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Children\'s Day', 'month': 6, 'day': 1, 'type': 'national', 'description': 'Children\'s Day'},
            {'name': 'Independence Day', 'month': 7, 'day': 5, 'type': 'national', 'description': 'Independence from Portugal (1975)'},
            {'name': 'Assumption Day', 'month': 8, 'day': 15, 'type': 'religious_christian', 'description': 'Assumption of Mary'},
            {'name': 'All Saints\' Day', 'month': 11, 'day': 1, 'type': 'religious_christian', 'description': 'All Saints'},
        ]
        self.add_holidays('CV', holidays)
        self.add_common_christian_holidays('CV')

    def populate_ivory_coast(self):
        """Ivory Coast (CI) - Muslim/Christian"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Ascension Day', 'month': 5, 'day': 9, 'type': 'religious_christian', 'description': 'Ascension of Jesus'},
            {'name': 'Whit Monday', 'month': 5, 'day': 20, 'type': 'religious_christian', 'description': 'Pentecost Monday'},
            {'name': 'Independence Day', 'month': 8, 'day': 7, 'type': 'national', 'description': 'Independence from France (1960)'},
            {'name': 'Assumption Day', 'month': 8, 'day': 15, 'type': 'religious_christian', 'description': 'Assumption of Mary'},
            {'name': 'All Saints\' Day', 'month': 11, 'day': 1, 'type': 'religious_christian', 'description': 'All Saints'},
            {'name': 'National Day', 'month': 12, 'day': 7, 'type': 'national', 'description': 'National Peace Day'},
        ]
        self.add_holidays('CI', holidays)
        self.add_common_christian_holidays('CI')
        self.add_common_muslim_holidays('CI')

    def populate_gambia(self):
        """Gambia (GM) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Independence Day', 'month': 2, 'day': 18, 'type': 'national', 'description': 'Independence from UK (1965)'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
        ]
        self.add_holidays('GM', holidays)
        self.add_common_christian_holidays('GM')
        self.add_common_muslim_holidays('GM')

    def populate_ghana(self):
        """Ghana (GH) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Constitution Day', 'month': 1, 'day': 7, 'type': 'national', 'description': 'Fourth Republic Constitution'},
            {'name': 'Independence Day', 'month': 3, 'day': 6, 'type': 'national', 'description': 'Independence from UK (1957)'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Africa Day', 'month': 5, 'day': 25, 'type': 'national', 'description': 'African Unity'},
            {'name': 'Founders\' Day', 'month': 8, 'day': 4, 'type': 'national', 'description': 'Founding Fathers'},
            {'name': 'Kwame Nkrumah Memorial Day', 'month': 9, 'day': 21, 'type': 'national', 'description': 'First President'},
            {'name': 'Farmers\' Day', 'month': 12, 'day': 6, 'type': 'national', 'description': 'First Friday of December'},
        ]
        self.add_holidays('GH', holidays)
        self.add_common_christian_holidays('GH')
        self.add_common_muslim_holidays('GH')

    def populate_guinea(self):
        """Guinea (GN) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Africa Day', 'month': 5, 'day': 25, 'type': 'national', 'description': 'African Unity'},
            {'name': 'Independence Day', 'month': 10, 'day': 2, 'type': 'national', 'description': 'Independence from France (1958)'},
        ]
        self.add_holidays('GN', holidays)
        self.add_common_christian_holidays('GN')
        self.add_common_muslim_holidays('GN')

    def populate_guinea_bissau(self):
        """Guinea-Bissau (GW) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'National Heroes Day', 'month': 1, 'day': 20, 'type': 'national', 'description': 'Amílcar Cabral Day'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Independence Day', 'month': 9, 'day': 24, 'type': 'national', 'description': 'Independence from Portugal (1973)'},
        ]
        self.add_holidays('GW', holidays)
        self.add_common_christian_holidays('GW')
        self.add_common_muslim_holidays('GW')

    def populate_liberia(self):
        """Liberia (LR) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Armed Forces Day', 'month': 2, 'day': 11, 'type': 'national', 'description': 'Armed Forces'},
            {'name': 'Decoration Day', 'month': 3, 'day': 13, 'type': 'national', 'description': 'Memorial Day'},
            {'name': 'J.J. Roberts Birthday', 'month': 3, 'day': 15, 'type': 'national', 'description': 'First President'},
            {'name': 'Fast and Prayer Day', 'month': 4, 'day': 11, 'type': 'national', 'description': 'National Prayer'},
            {'name': 'National Unification Day', 'month': 5, 'day': 14, 'type': 'national', 'description': 'National Unity'},
            {'name': 'Independence Day', 'month': 7, 'day': 26, 'type': 'national', 'description': 'Independence (1847)'},
            {'name': 'Flag Day', 'month': 8, 'day': 24, 'type': 'national', 'description': 'National Flag'},
            {'name': 'Thanksgiving Day', 'month': 11, 'day': 7, 'type': 'national', 'description': 'First Thursday of November'},
            {'name': 'President Tubman\'s Birthday', 'month': 11, 'day': 29, 'type': 'national', 'description': 'President Tubman'},
        ]
        self.add_holidays('LR', holidays)
        self.add_common_christian_holidays('LR')
        self.add_common_muslim_holidays('LR')

    def populate_mali(self):
        """Mali (ML) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Armed Forces Day', 'month': 1, 'day': 20, 'type': 'national', 'description': 'Armed Forces'},
            {'name': 'Martyrs\' Day', 'month': 3, 'day': 26, 'type': 'national', 'description': 'Democracy Martyrs'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Africa Day', 'month': 5, 'day': 25, 'type': 'national', 'description': 'African Unity'},
            {'name': 'Independence Day', 'month': 9, 'day': 22, 'type': 'national', 'description': 'Independence from France (1960)'},
        ]
        self.add_holidays('ML', holidays)
        self.add_common_christian_holidays('ML')
        self.add_common_muslim_holidays('ML')

    def populate_niger(self):
        """Niger (NE) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Independence Day', 'month': 8, 'day': 3, 'type': 'national', 'description': 'Independence from France (1960)'},
            {'name': 'Republic Day', 'month': 12, 'day': 18, 'type': 'national', 'description': 'Proclamation of Republic (1958)'},
        ]
        self.add_holidays('NE', holidays)
        self.add_common_christian_holidays('NE')
        self.add_common_muslim_holidays('NE')

    def populate_nigeria(self):
        """Nigeria (NG) - Mixed Christian/Muslim"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Workers\' Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Democracy Day', 'month': 6, 'day': 12, 'type': 'national', 'description': 'Return to Democracy (1999)'},
            {'name': 'Independence Day', 'month': 10, 'day': 1, 'type': 'national', 'description': 'Independence from UK (1960)'},
        ]
        self.add_holidays('NG', holidays)
        self.add_common_christian_holidays('NG')
        self.add_common_muslim_holidays('NG')

    def populate_senegal(self):
        """Senegal (SN) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Independence Day', 'month': 4, 'day': 4, 'type': 'national', 'description': 'Independence from France (1960)'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Assumption Day', 'month': 8, 'day': 15, 'type': 'religious_christian', 'description': 'Assumption of Mary'},
            {'name': 'All Saints\' Day', 'month': 11, 'day': 1, 'type': 'religious_christian', 'description': 'All Saints'},
        ]
        self.add_holidays('SN', holidays)
        self.add_common_christian_holidays('SN')
        self.add_common_muslim_holidays('SN')

    def populate_sierra_leone(self):
        """Sierra Leone (SL) - Muslim/Christian"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Independence Day', 'month': 4, 'day': 27, 'type': 'national', 'description': 'Independence from UK (1961)'},
        ]
        self.add_holidays('SL', holidays)
        self.add_common_christian_holidays('SL')
        self.add_common_muslim_holidays('SL')

    def populate_togo(self):
        """Togo (TG) - Christian/Traditional"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Liberation Day', 'month': 1, 'day': 13, 'type': 'national', 'description': '1963/1967 Liberation'},
            {'name': 'Victory Day', 'month': 1, 'day': 24, 'type': 'national', 'description': 'Victory'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Independence Day', 'month': 4, 'day': 27, 'type': 'national', 'description': 'Independence from France (1960)'},
            {'name': 'Ascension Day', 'month': 5, 'day': 9, 'type': 'religious_christian', 'description': 'Ascension of Jesus'},
            {'name': 'Whit Monday', 'month': 5, 'day': 20, 'type': 'religious_christian', 'description': 'Pentecost Monday'},
            {'name': 'Assumption Day', 'month': 8, 'day': 15, 'type': 'religious_christian', 'description': 'Assumption of Mary'},
            {'name': 'All Saints\' Day', 'month': 11, 'day': 1, 'type': 'religious_christian', 'description': 'All Saints'},
        ]
        self.add_holidays('TG', holidays)
        self.add_common_christian_holidays('TG')
        self.add_common_muslim_holidays('TG')

    # ==========================================
    # EAST AFRICA
    # ==========================================

    def populate_burundi(self):
        """Burundi (BI) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Unity Day', 'month': 2, 'day': 5, 'type': 'national', 'description': 'National Unity'},
            {'name': 'President Ntaryamira Day', 'month': 4, 'day': 6, 'type': 'national', 'description': 'Assassination of President'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Ascension Day', 'month': 5, 'day': 9, 'type': 'religious_christian', 'description': 'Ascension of Jesus'},
            {'name': 'Independence Day', 'month': 7, 'day': 1, 'type': 'national', 'description': 'Independence from Belgium (1962)'},
            {'name': 'Assumption Day', 'month': 8, 'day': 15, 'type': 'religious_christian', 'description': 'Assumption of Mary'},
            {'name': 'Prince Louis Rwagasore Day', 'month': 10, 'day': 13, 'type': 'national', 'description': 'Assassination of Prince'},
            {'name': 'President Ndadaye Day', 'month': 10, 'day': 21, 'type': 'national', 'description': 'Assassination of President'},
            {'name': 'All Saints\' Day', 'month': 11, 'day': 1, 'type': 'religious_christian', 'description': 'All Saints'},
        ]
        self.add_holidays('BI', holidays)
        self.add_common_christian_holidays('BI')

    def populate_comoros(self):
        """Comoros (KM) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Independence Day', 'month': 7, 'day': 6, 'type': 'national', 'description': 'Independence from France (1975)'},
        ]
        self.add_holidays('KM', holidays)
        self.add_common_muslim_holidays('KM')

    def populate_djibouti(self):
        """Djibouti (DJ) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Independence Day', 'month': 6, 'day': 27, 'type': 'national', 'description': 'Independence from France (1977)'},
        ]
        self.add_holidays('DJ', holidays)
        self.add_common_muslim_holidays('DJ')

    def populate_eritrea(self):
        """Eritrea (ER) - Christian/Muslim"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Coptic Christmas', 'month': 1, 'day': 7, 'type': 'religious_christian', 'description': 'Coptic Orthodox Christmas'},
            {'name': 'Epiphany', 'month': 1, 'day': 19, 'type': 'religious_christian', 'description': 'Timkat'},
            {'name': 'Fenkil Day', 'month': 2, 'day': 10, 'type': 'national', 'description': 'Liberation of Massawa'},
            {'name': 'Women\'s Day', 'month': 3, 'day': 8, 'type': 'national', 'description': 'International Women\'s Day'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Liberation Day', 'month': 5, 'day': 24, 'type': 'national', 'description': 'Liberation (1991)'},
            {'name': 'Martyrs\' Day', 'month': 6, 'day': 20, 'type': 'national', 'description': 'Martyrs'},
            {'name': 'Start of Armed Struggle', 'month': 9, 'day': 1, 'type': 'national', 'description': 'Armed Struggle (1961)'},
        ]
        self.add_holidays('ER', holidays)
        self.add_common_christian_holidays('ER')
        self.add_common_muslim_holidays('ER')

    def populate_ethiopia(self):
        """Ethiopia (ET) - Christian majority (Orthodox)"""
        holidays = [
            {'name': 'Ethiopian Christmas', 'month': 1, 'day': 7, 'type': 'religious_christian', 'description': 'Genna (Ethiopian Christmas)'},
            {'name': 'Epiphany', 'month': 1, 'day': 19, 'type': 'religious_christian', 'description': 'Timkat'},
            {'name': 'Adwa Victory Day', 'month': 3, 'day': 2, 'type': 'national', 'description': 'Battle of Adwa (1896)'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Patriots\' Victory Day', 'month': 5, 'day': 5, 'type': 'national', 'description': 'Liberation from Italy (1941)'},
            {'name': 'Downfall of Derg', 'month': 5, 'day': 28, 'type': 'national', 'description': 'End of Military Rule (1991)'},
            {'name': 'Ethiopian New Year', 'month': 9, 'day': 11, 'type': 'national', 'description': 'Enkutatash'},
            {'name': 'Meskel', 'month': 9, 'day': 27, 'type': 'religious_christian', 'description': 'Finding of True Cross'},
        ]
        self.add_holidays('ET', holidays)
        self.add_common_muslim_holidays('ET')

    def populate_kenya(self):
        """Kenya (KE) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Madaraka Day', 'month': 6, 'day': 1, 'type': 'national', 'description': 'Self-Governance Day (1963)'},
            {'name': 'Mashujaa Day', 'month': 10, 'day': 20, 'type': 'national', 'description': 'Heroes Day'},
            {'name': 'Jamhuri Day', 'month': 12, 'day': 12, 'type': 'national', 'description': 'Independence Day (1963)'},
        ]
        self.add_holidays('KE', holidays)
        self.add_common_christian_holidays('KE')
        self.add_common_muslim_holidays('KE')

    def populate_madagascar(self):
        """Madagascar (MG) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Commemoration of 1947 Rebellion', 'month': 3, 'day': 29, 'type': 'national', 'description': '1947 Rebellion'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Ascension Day', 'month': 5, 'day': 9, 'type': 'religious_christian', 'description': 'Ascension of Jesus'},
            {'name': 'Whit Monday', 'month': 5, 'day': 20, 'type': 'religious_christian', 'description': 'Pentecost Monday'},
            {'name': 'Independence Day', 'month': 6, 'day': 26, 'type': 'national', 'description': 'Independence from France (1960)'},
            {'name': 'Assumption Day', 'month': 8, 'day': 15, 'type': 'religious_christian', 'description': 'Assumption of Mary'},
            {'name': 'All Saints\' Day', 'month': 11, 'day': 1, 'type': 'religious_christian', 'description': 'All Saints'},
            {'name': 'Republic Day', 'month': 12, 'day': 11, 'type': 'national', 'description': 'Proclamation of Republic (1958)'},
        ]
        self.add_holidays('MG', holidays)
        self.add_common_christian_holidays('MG')

    def populate_malawi(self):
        """Malawi (MW) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'John Chilembwe Day', 'month': 1, 'day': 15, 'type': 'national', 'description': 'Independence Activist'},
            {'name': 'Martyrs\' Day', 'month': 3, 'day': 3, 'type': 'national', 'description': 'Political Martyrs'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Kamuzu Day', 'month': 5, 'day': 14, 'type': 'national', 'description': 'First President Birthday'},
            {'name': 'Independence Day', 'month': 7, 'day': 6, 'type': 'national', 'description': 'Independence from UK (1964)'},
            {'name': 'Mother\'s Day', 'month': 10, 'day': 15, 'type': 'national', 'description': 'Mother\'s Day'},
        ]
        self.add_holidays('MW', holidays)
        self.add_common_christian_holidays('MW')
        self.add_common_muslim_holidays('MW')

    def populate_mauritius(self):
        """Mauritius (MU) - Multi-religious"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Thaipoosam Cavadee', 'month': 1, 'day': 24, 'type': 'religious_other', 'description': 'Hindu Festival'},
            {'name': 'Abolition of Slavery', 'month': 2, 'day': 1, 'type': 'national', 'description': 'End of Slavery (1835)'},
            {'name': 'Spring Festival', 'month': 2, 'day': 10, 'type': 'cultural', 'description': 'Chinese New Year'},
            {'name': 'Maha Shivaratri', 'month': 3, 'day': 8, 'type': 'religious_other', 'description': 'Hindu Festival'},
            {'name': 'Independence Day', 'month': 3, 'day': 12, 'type': 'national', 'description': 'Independence from UK (1968)'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Arrival of Indentured Labourers', 'month': 11, 'day': 2, 'type': 'national', 'description': 'Indentured Labourers Day'},
        ]
        self.add_holidays('MU', holidays)
        self.add_common_christian_holidays('MU')
        self.add_common_muslim_holidays('MU')

    def populate_mozambique(self):
        """Mozambique (MZ) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Mozambican Heroes Day', 'month': 2, 'day': 3, 'type': 'national', 'description': 'Heroes Day'},
            {'name': 'Mozambican Women\'s Day', 'month': 4, 'day': 7, 'type': 'national', 'description': 'Women\'s Day'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Independence Day', 'month': 6, 'day': 25, 'type': 'national', 'description': 'Independence from Portugal (1975)'},
            {'name': 'Victory Day', 'month': 9, 'day': 7, 'type': 'national', 'description': 'Lusaka Accord (1974)'},
            {'name': 'Armed Forces Day', 'month': 9, 'day': 25, 'type': 'national', 'description': 'Armed Forces'},
            {'name': 'Peace and Reconciliation Day', 'month': 10, 'day': 4, 'type': 'national', 'description': 'Peace Accord (1992)'},
            {'name': 'Family Day', 'month': 12, 'day': 25, 'type': 'national', 'description': 'Family Day'},
        ]
        self.add_holidays('MZ', holidays)
        self.add_common_christian_holidays('MZ')

    def populate_rwanda(self):
        """Rwanda (RW) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'National Heroes Day', 'month': 2, 'day': 1, 'type': 'national', 'description': 'Heroes Day'},
            {'name': 'Genocide Memorial Day', 'month': 4, 'day': 7, 'type': 'national', 'description': '1994 Genocide Remembrance'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Independence Day', 'month': 7, 'day': 1, 'type': 'national', 'description': 'Independence from Belgium (1962)'},
            {'name': 'Liberation Day', 'month': 7, 'day': 4, 'type': 'national', 'description': 'Liberation (1994)'},
            {'name': 'Assumption Day', 'month': 8, 'day': 15, 'type': 'religious_christian', 'description': 'Assumption of Mary'},
            {'name': 'Umuganura Day', 'month': 8, 'day': 2, 'type': 'cultural', 'description': 'Harvest Festival'},
        ]
        self.add_holidays('RW', holidays)
        self.add_common_christian_holidays('RW')

    def populate_seychelles(self):
        """Seychelles (SC) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'New Year Holiday', 'month': 1, 'day': 2, 'type': 'national', 'description': 'New Year Holiday'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Liberation Day', 'month': 6, 'day': 5, 'type': 'national', 'description': 'Liberation (1977)'},
            {'name': 'National Day', 'month': 6, 'day': 18, 'type': 'national', 'description': 'National Day'},
            {'name': 'Independence Day', 'month': 6, 'day': 29, 'type': 'national', 'description': 'Independence from UK (1976)'},
            {'name': 'Assumption Day', 'month': 8, 'day': 15, 'type': 'religious_christian', 'description': 'Assumption of Mary'},
            {'name': 'All Saints\' Day', 'month': 11, 'day': 1, 'type': 'religious_christian', 'description': 'All Saints'},
            {'name': 'Immaculate Conception', 'month': 12, 'day': 8, 'type': 'religious_christian', 'description': 'Immaculate Conception'},
        ]
        self.add_holidays('SC', holidays)
        self.add_common_christian_holidays('SC')

    def populate_somalia(self):
        """Somalia (SO) - Muslim majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Independence Day', 'month': 6, 'day': 26, 'type': 'national', 'description': 'Independence from UK (1960)'},
            {'name': 'Foundation of the Republic', 'month': 7, 'day': 1, 'type': 'national', 'description': 'Union with Italian Somaliland'},
        ]
        self.add_holidays('SO', holidays)
        self.add_common_muslim_holidays('SO')

    def populate_south_sudan(self):
        """South Sudan (SS) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Peace Agreement Day', 'month': 1, 'day': 9, 'type': 'national', 'description': 'CPA Signing (2005)'},
            {'name': 'SPLA Day', 'month': 5, 'day': 16, 'type': 'national', 'description': 'SPLA Foundation'},
            {'name': 'Martyrs\' Day', 'month': 7, 'day': 30, 'type': 'national', 'description': 'Death of Dr. John Garang'},
            {'name': 'Independence Day', 'month': 7, 'day': 9, 'type': 'national', 'description': 'Independence from Sudan (2011)'},
        ]
        self.add_holidays('SS', holidays)
        self.add_common_christian_holidays('SS')
        self.add_common_muslim_holidays('SS')

    def populate_tanzania(self):
        """Tanzania (TZ) - Christian/Muslim"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Zanzibar Revolution Day', 'month': 1, 'day': 12, 'type': 'national', 'description': 'Zanzibar Revolution (1964)'},
            {'name': 'Union Day', 'month': 4, 'day': 26, 'type': 'national', 'description': 'Union of Tanganyika and Zanzibar (1964)'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Karume Day', 'month': 7, 'day': 7, 'type': 'national', 'description': 'Abeid Amani Karume Day'},
            {'name': 'Peasants\' Day', 'month': 8, 'day': 8, 'type': 'national', 'description': 'Nane Nane'},
            {'name': 'Independence Day', 'month': 12, 'day': 9, 'type': 'national', 'description': 'Independence from UK (1961)'},
        ]
        self.add_holidays('TZ', holidays)
        self.add_common_christian_holidays('TZ')
        self.add_common_muslim_holidays('TZ')

    def populate_uganda(self):
        """Uganda (UG) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'NRM Liberation Day', 'month': 1, 'day': 26, 'type': 'national', 'description': 'NRM Takeover (1986)'},
            {'name': 'Women\'s Day', 'month': 3, 'day': 8, 'type': 'national', 'description': 'International Women\'s Day'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Martyrs\' Day', 'month': 6, 'day': 3, 'type': 'religious_christian', 'description': 'Uganda Martyrs'},
            {'name': 'National Heroes Day', 'month': 6, 'day': 9, 'type': 'national', 'description': 'Heroes Day'},
            {'name': 'Independence Day', 'month': 10, 'day': 9, 'type': 'national', 'description': 'Independence from UK (1962)'},
        ]
        self.add_holidays('UG', holidays)
        self.add_common_christian_holidays('UG')
        self.add_common_muslim_holidays('UG')

    def populate_zambia(self):
        """Zambia (ZM) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Youth Day', 'month': 3, 'day': 12, 'type': 'national', 'description': 'Youth Day'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Africa Freedom Day', 'month': 5, 'day': 25, 'type': 'national', 'description': 'Africa Day'},
            {'name': 'Heroes Day', 'month': 7, 'day': 1, 'type': 'national', 'description': 'Heroes Day (First Monday of July)'},
            {'name': 'Unity Day', 'month': 7, 'day': 2, 'type': 'national', 'description': 'Unity Day (First Tuesday of July)'},
            {'name': 'Farmers\' Day', 'month': 8, 'day': 5, 'type': 'national', 'description': 'Farmers\' Day (First Monday of August)'},
            {'name': 'Independence Day', 'month': 10, 'day': 24, 'type': 'national', 'description': 'Independence from UK (1964)'},
        ]
        self.add_holidays('ZM', holidays)
        self.add_common_christian_holidays('ZM')

    def populate_zimbabwe(self):
        """Zimbabwe (ZW) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Robert Mugabe National Youth Day', 'month': 2, 'day': 21, 'type': 'national', 'description': 'Youth Day'},
            {'name': 'Independence Day', 'month': 4, 'day': 18, 'type': 'national', 'description': 'Independence from UK (1980)'},
            {'name': 'Workers\' Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Africa Day', 'month': 5, 'day': 25, 'type': 'national', 'description': 'Africa Day'},
            {'name': 'Heroes\' Day', 'month': 8, 'day': 11, 'type': 'national', 'description': 'Heroes Day (Second Monday of August)'},
            {'name': 'Defence Forces Day', 'month': 8, 'day': 12, 'type': 'national', 'description': 'Defence Forces (Second Tuesday of August)'},
        ]
        self.add_holidays('ZW', holidays)
        self.add_common_christian_holidays('ZW')

    # ==========================================
    # CENTRAL AFRICA
    # ==========================================

    def populate_cameroon(self):
        """Cameroon (CM) - Christian/Muslim"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Youth Day', 'month': 2, 'day': 11, 'type': 'national', 'description': 'National Youth Day'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'National Day', 'month': 5, 'day': 20, 'type': 'national', 'description': 'Unification Day (1972)'},
            {'name': 'Ascension Day', 'month': 5, 'day': 9, 'type': 'religious_christian', 'description': 'Ascension of Jesus'},
            {'name': 'Assumption Day', 'month': 8, 'day': 15, 'type': 'religious_christian', 'description': 'Assumption of Mary'},
        ]
        self.add_holidays('CM', holidays)
        self.add_common_christian_holidays('CM')
        self.add_common_muslim_holidays('CM')

    def populate_central_african_republic(self):
        """Central African Republic (CF) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Boganda Day', 'month': 3, 'day': 29, 'type': 'national', 'description': 'Barthélemy Boganda Day'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Ascension Day', 'month': 5, 'day': 9, 'type': 'religious_christian', 'description': 'Ascension of Jesus'},
            {'name': 'Whit Monday', 'month': 5, 'day': 20, 'type': 'religious_christian', 'description': 'Pentecost Monday'},
            {'name': 'National Day of Prayer', 'month': 6, 'day': 30, 'type': 'national', 'description': 'National Prayer'},
            {'name': 'Independence Day', 'month': 8, 'day': 13, 'type': 'national', 'description': 'Independence from France (1960)'},
            {'name': 'Assumption Day', 'month': 8, 'day': 15, 'type': 'religious_christian', 'description': 'Assumption of Mary'},
            {'name': 'All Saints\' Day', 'month': 11, 'day': 1, 'type': 'religious_christian', 'description': 'All Saints'},
            {'name': 'Republic Day', 'month': 12, 'day': 1, 'type': 'national', 'description': 'Proclamation of Republic (1958)'},
        ]
        self.add_holidays('CF', holidays)
        self.add_common_christian_holidays('CF')

    def populate_chad(self):
        """Chad (TD) - Muslim/Christian"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Africa Day', 'month': 5, 'day': 25, 'type': 'national', 'description': 'Africa Day'},
            {'name': 'Independence Day', 'month': 8, 'day': 11, 'type': 'national', 'description': 'Independence from France (1960)'},
            {'name': 'All Saints\' Day', 'month': 11, 'day': 1, 'type': 'religious_christian', 'description': 'All Saints'},
            {'name': 'Republic Day', 'month': 11, 'day': 28, 'type': 'national', 'description': 'Proclamation of Republic (1958)'},
        ]
        self.add_holidays('TD', holidays)
        self.add_common_christian_holidays('TD')
        self.add_common_muslim_holidays('TD')

    def populate_congo_brazzaville(self):
        """Republic of Congo (CG) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Whit Monday', 'month': 5, 'day': 20, 'type': 'religious_christian', 'description': 'Pentecost Monday'},
            {'name': 'Independence Day', 'month': 8, 'day': 15, 'type': 'national', 'description': 'Independence from France (1960)'},
            {'name': 'All Saints\' Day', 'month': 11, 'day': 1, 'type': 'religious_christian', 'description': 'All Saints'},
            {'name': 'Republic Day', 'month': 11, 'day': 28, 'type': 'national', 'description': 'Proclamation of Republic (1958)'},
        ]
        self.add_holidays('CG', holidays)
        self.add_common_christian_holidays('CG')

    def populate_congo_kinshasa(self):
        """Democratic Republic of Congo (CD) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Martyrs of Independence Day', 'month': 1, 'day': 4, 'type': 'national', 'description': 'Independence Martyrs'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Liberation Day', 'month': 5, 'day': 17, 'type': 'national', 'description': 'Liberation (1997)'},
            {'name': 'Independence Day', 'month': 6, 'day': 30, 'type': 'national', 'description': 'Independence from Belgium (1960)'},
            {'name': 'Parents\' Day', 'month': 8, 'day': 1, 'type': 'national', 'description': 'Parents\' Day'},
        ]
        self.add_holidays('CD', holidays)
        self.add_common_christian_holidays('CD')

    def populate_equatorial_guinea(self):
        """Equatorial Guinea (GQ) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Corpus Christi', 'month': 6, 'day': 8, 'type': 'religious_christian', 'description': 'Corpus Christi'},
            {'name': 'President\'s Birthday', 'month': 6, 'day': 5, 'type': 'national', 'description': 'President\'s Birthday'},
            {'name': 'Armed Forces Day', 'month': 8, 'day': 3, 'type': 'national', 'description': 'Armed Forces'},
            {'name': 'Constitution Day', 'month': 8, 'day': 15, 'type': 'national', 'description': 'Constitution Day'},
            {'name': 'Independence Day', 'month': 10, 'day': 12, 'type': 'national', 'description': 'Independence from Spain (1968)'},
            {'name': 'Immaculate Conception', 'month': 12, 'day': 8, 'type': 'religious_christian', 'description': 'Immaculate Conception'},
        ]
        self.add_holidays('GQ', holidays)
        self.add_common_christian_holidays('GQ')

    def populate_gabon(self):
        """Gabon (GA) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Whit Monday', 'month': 5, 'day': 20, 'type': 'religious_christian', 'description': 'Pentecost Monday'},
            {'name': 'Independence Day', 'month': 8, 'day': 17, 'type': 'national', 'description': 'Independence from France (1960)'},
            {'name': 'All Saints\' Day', 'month': 11, 'day': 1, 'type': 'religious_christian', 'description': 'All Saints'},
        ]
        self.add_holidays('GA', holidays)
        self.add_common_christian_holidays('GA')

    def populate_sao_tome_principe(self):
        """São Tomé and Príncipe (ST) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Independence Day', 'month': 7, 'day': 12, 'type': 'national', 'description': 'Independence from Portugal (1975)'},
            {'name': 'Armed Forces Day', 'month': 9, 'day': 6, 'type': 'national', 'description': 'Armed Forces'},
            {'name': 'All Saints\' Day', 'month': 11, 'day': 1, 'type': 'religious_christian', 'description': 'All Saints'},
            {'name': 'Immaculate Conception', 'month': 12, 'day': 8, 'type': 'religious_christian', 'description': 'Immaculate Conception'},
        ]
        self.add_holidays('ST', holidays)
        self.add_common_christian_holidays('ST')

    # ==========================================
    # SOUTHERN AFRICA
    # ==========================================

    def populate_angola(self):
        """Angola (AO) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Beginning of the Armed Struggle Day', 'month': 2, 'day': 4, 'type': 'national', 'description': 'Start of Independence Struggle (1961)'},
            {'name': 'Carnival Day', 'month': 2, 'day': 13, 'type': 'cultural', 'description': 'Carnival Tuesday'},
            {'name': 'International Women\'s Day', 'month': 3, 'day': 8, 'type': 'national', 'description': 'Women\'s Day'},
            {'name': 'Southern Africa Liberation Day', 'month': 3, 'day': 23, 'type': 'national', 'description': 'Southern Africa Liberation'},
            {'name': 'Peace Day', 'month': 4, 'day': 4, 'type': 'national', 'description': 'Peace and National Reconciliation'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Africa Day', 'month': 5, 'day': 25, 'type': 'national', 'description': 'Africa Day'},
            {'name': 'Children\'s Day', 'month': 6, 'day': 1, 'type': 'national', 'description': 'International Children\'s Day'},
            {'name': 'National Heroes Day', 'month': 9, 'day': 17, 'type': 'national', 'description': 'Dr. António Agostinho Neto'},
            {'name': 'All Souls\' Day', 'month': 11, 'day': 2, 'type': 'religious_christian', 'description': 'All Souls'},
            {'name': 'Independence Day', 'month': 11, 'day': 11, 'type': 'national', 'description': 'Independence from Portugal (1975)'},
        ]
        self.add_holidays('AO', holidays)
        self.add_common_christian_holidays('AO')

    def populate_botswana(self):
        """Botswana (BW) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'New Year Holiday', 'month': 1, 'day': 2, 'type': 'national', 'description': 'New Year Holiday'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Ascension Day', 'month': 5, 'day': 9, 'type': 'religious_christian', 'description': 'Ascension of Jesus'},
            {'name': 'Sir Seretse Khama Day', 'month': 7, 'day': 1, 'type': 'national', 'description': 'First President'},
            {'name': 'President\'s Day', 'month': 7, 'day': 15, 'type': 'national', 'description': 'Third Monday of July'},
            {'name': 'Botswana Day', 'month': 9, 'day': 30, 'type': 'national', 'description': 'Independence from UK (1966)'},
            {'name': 'Botswana Day Holiday', 'month': 10, 'day': 1, 'type': 'national', 'description': 'Independence Holiday'},
        ]
        self.add_holidays('BW', holidays)
        self.add_common_christian_holidays('BW')

    def populate_eswatini(self):
        """Eswatini (SZ) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'King\'s Birthday', 'month': 4, 'day': 19, 'type': 'national', 'description': 'King Mswati III Birthday'},
            {'name': 'National Flag Day', 'month': 4, 'day': 25, 'type': 'national', 'description': 'National Flag'},
            {'name': 'Independence Day', 'month': 9, 'day': 6, 'type': 'national', 'description': 'Independence from UK (1968)'},
        ]
        self.add_holidays('SZ', holidays)
        self.add_common_christian_holidays('SZ')

    def populate_lesotho(self):
        """Lesotho (LS) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Moshoeshoe Day', 'month': 3, 'day': 11, 'type': 'national', 'description': 'Founder King Moshoeshoe I'},
            {'name': 'Labour Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Ascension Day', 'month': 5, 'day': 9, 'type': 'religious_christian', 'description': 'Ascension of Jesus'},
            {'name': 'Africa Day', 'month': 5, 'day': 25, 'type': 'national', 'description': 'Africa Day'},
            {'name': 'King\'s Birthday', 'month': 7, 'day': 17, 'type': 'national', 'description': 'King Letsie III Birthday'},
            {'name': 'Independence Day', 'month': 10, 'day': 4, 'type': 'national', 'description': 'Independence from UK (1966)'},
        ]
        self.add_holidays('LS', holidays)
        self.add_common_christian_holidays('LS')

    def populate_namibia(self):
        """Namibia (NA) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Independence Day', 'month': 3, 'day': 21, 'type': 'national', 'description': 'Independence from South Africa (1990)'},
            {'name': 'Workers\' Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Africa Day', 'month': 5, 'day': 25, 'type': 'national', 'description': 'Africa Day'},
            {'name': 'Cassinga Day', 'month': 5, 'day': 4, 'type': 'national', 'description': 'Cassinga Massacre Remembrance'},
            {'name': 'Heroes\' Day', 'month': 8, 'day': 26, 'type': 'national', 'description': 'Heroes Day'},
            {'name': 'Human Rights Day', 'month': 12, 'day': 10, 'type': 'national', 'description': 'International Human Rights Day'},
        ]
        self.add_holidays('NA', holidays)
        self.add_common_christian_holidays('NA')

    def populate_south_africa(self):
        """South Africa (ZA) - Christian majority"""
        holidays = [
            {'name': 'New Year\'s Day', 'month': 1, 'day': 1, 'type': 'national', 'description': 'New Year'},
            {'name': 'Human Rights Day', 'month': 3, 'day': 21, 'type': 'national', 'description': 'Sharpeville Massacre (1960)'},
            {'name': 'Family Day', 'month': 3, 'day': 29, 'type': 'national', 'description': 'Easter Monday as Family Day'},
            {'name': 'Freedom Day', 'month': 4, 'day': 27, 'type': 'national', 'description': 'First Democratic Elections (1994)'},
            {'name': 'Workers\' Day', 'month': 5, 'day': 1, 'type': 'national', 'description': 'International Workers Day'},
            {'name': 'Youth Day', 'month': 6, 'day': 16, 'type': 'national', 'description': 'Soweto Uprising (1976)'},
            {'name': 'Women\'s Day', 'month': 8, 'day': 9, 'type': 'national', 'description': 'Women\'s March (1956)'},
            {'name': 'Heritage Day', 'month': 9, 'day': 24, 'type': 'national', 'description': 'National Braai Day'},
            {'name': 'Day of Reconciliation', 'month': 12, 'day': 16, 'type': 'national', 'description': 'Reconciliation Day'},
            {'name': 'Day of Goodwill', 'month': 12, 'day': 26, 'type': 'national', 'description': 'Boxing Day'},
        ]
        self.add_holidays('ZA', holidays)
        self.add_common_christian_holidays('ZA')
