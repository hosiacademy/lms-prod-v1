"""
Management command to populate localized greetings and holiday messages for all African countries.

Automatically creates:
- Native language greetings (pre-colonial languages)
- International language greetings (English, French, Portuguese, Spanish, Arabic)
- Holiday-specific greetings
- Time-of-day variations (morning, afternoon, evening)
- Holiday banner messages

Usage:
    python manage.py populate_greetings_and_messages
    python manage.py populate_greetings_and_messages --clear
"""

from django.core.management.base import BaseCommand
from django.db import transaction
from apps.localization.models import (
    Country, Language, LocalizedGreeting,
    PublicHoliday, HolidayMessage
)


class Command(BaseCommand):
    help = 'Populate localized greetings and holiday messages for all African countries'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing greetings and messages before populating',
        )

    def handle(self, *args, **options):
        if options['clear']:
            self.stdout.write(self.style.WARNING('Clearing existing greetings and messages...'))
            LocalizedGreeting.objects.all().delete()
            HolidayMessage.objects.all().delete()

        self.stdout.write(self.style.SUCCESS('Populating greetings and holiday messages...'))

        # Country-to-language mapping
        self.country_languages = self.get_country_language_mapping()

        # Populate greetings and messages
        self.populate_all_greetings()
        self.populate_holiday_messages()

        total_greetings = LocalizedGreeting.objects.count()
        total_messages = HolidayMessage.objects.count()

        self.stdout.write(self.style.SUCCESS(
            f'\n[SUCCESS] Created {total_greetings} greetings and {total_messages} holiday messages!'
        ))

    def get_country_language_mapping(self):
        """Map countries to their native and colonial languages with greetings"""
        return {
            # NORTH AFRICA
            'DZ': {  # Algeria
                'native': {'code': 'ar', 'greeting': 'مرحبا', 'name': 'Arabic'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'EG': {  # Egypt
                'native': {'code': 'ar', 'greeting': 'مرحبا', 'name': 'Arabic'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'LY': {  # Libya
                'native': {'code': 'ar', 'greeting': 'مرحبا', 'name': 'Arabic'},
                'colonial': {'code': 'ar', 'greeting': 'مرحبا', 'name': 'Arabic'}
            },
            'MR': {  # Mauritania
                'native': {'code': 'ar', 'greeting': 'مرحبا', 'name': 'Arabic'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'MA': {  # Morocco
                'native': {'code': 'ar', 'greeting': 'مرحبا', 'name': 'Arabic'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'SD': {  # Sudan
                'native': {'code': 'ar', 'greeting': 'مرحبا', 'name': 'Arabic'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'TN': {  # Tunisia
                'native': {'code': 'ar', 'greeting': 'مرحبا', 'name': 'Arabic'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },

            # WEST AFRICA
            'BJ': {  # Benin
                'native': {'code': 'yo', 'greeting': 'Ẹ káàbọ̀', 'name': 'Yoruba'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'BF': {  # Burkina Faso
                'native': {'code': 'mos', 'greeting': 'Né y kɩbariŋ', 'name': 'Mossi'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'CV': {  # Cape Verde
                'native': {'code': 'pt', 'greeting': 'Olá', 'name': 'Portuguese Creole'},
                'colonial': {'code': 'pt', 'greeting': 'Olá', 'name': 'Portuguese'}
            },
            'CI': {  # Ivory Coast
                'native': {'code': 'bci', 'greeting': 'Ani sogoma', 'name': 'Baoulé'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'GM': {  # Gambia
                'native': {'code': 'man', 'greeting': 'I ni ce', 'name': 'Mandinka'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'GH': {  # Ghana
                'native': {'code': 'ak', 'greeting': 'Akwaaba', 'name': 'Akan'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'GN': {  # Guinea
                'native': {'code': 'ff', 'greeting': 'Jam nga fanaan', 'name': 'Fula'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'GW': {  # Guinea-Bissau
                'native': {'code': 'pt', 'greeting': 'Olá', 'name': 'Guinea-Bissau Creole'},
                'colonial': {'code': 'pt', 'greeting': 'Olá', 'name': 'Portuguese'}
            },
            'LR': {  # Liberia
                'native': {'code': 'en', 'greeting': 'Hello', 'name': 'Liberian English'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'ML': {  # Mali
                'native': {'code': 'bm', 'greeting': 'I ni ce', 'name': 'Bambara'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'NE': {  # Niger
                'native': {'code': 'ha', 'greeting': 'Sannu', 'name': 'Hausa'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'NG': {  # Nigeria
                'native': {'code': 'ha', 'greeting': 'Sannu', 'name': 'Hausa'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'SN': {  # Senegal
                'native': {'code': 'wo', 'greeting': 'Asalaam alaikum', 'name': 'Wolof'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'SL': {  # Sierra Leone
                'native': {'code': 'men', 'greeting': 'Bi e', 'name': 'Mende'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'TG': {  # Togo
                'native': {'code': 'ee', 'greeting': 'Ɛzɔdzɔɛ', 'name': 'Ewe'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },

            # EAST AFRICA
            'BI': {  # Burundi
                'native': {'code': 'rn', 'greeting': 'Amakuru', 'name': 'Kirundi'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'KM': {  # Comoros
                'native': {'code': 'ar', 'greeting': 'Bariza', 'name': 'Comorian'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'DJ': {  # Djibouti
                'native': {'code': 'so', 'greeting': 'Iska warran', 'name': 'Somali'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'ER': {  # Eritrea
                'native': {'code': 'ti', 'greeting': 'Selam', 'name': 'Tigrinya'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'ET': {  # Ethiopia
                'native': {'code': 'am', 'greeting': 'ሰላም', 'name': 'Amharic'},
                'colonial': {'code': 'am', 'greeting': 'ሰላም', 'name': 'Amharic'}
            },
            'KE': {  # Kenya
                'native': {'code': 'sw', 'greeting': 'Jambo', 'name': 'Swahili'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'MG': {  # Madagascar
                'native': {'code': 'mg', 'greeting': 'Salama', 'name': 'Malagasy'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'MW': {  # Malawi
                'native': {'code': 'ny', 'greeting': 'Moni', 'name': 'Chichewa'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'MU': {  # Mauritius
                'native': {'code': 'mfe', 'greeting': 'Bonzour', 'name': 'Mauritian Creole'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'MZ': {  # Mozambique
                'native': {'code': 'ts', 'greeting': 'Avuxeni', 'name': 'Tsonga'},
                'colonial': {'code': 'pt', 'greeting': 'Olá', 'name': 'Portuguese'}
            },
            'RW': {  # Rwanda
                'native': {'code': 'rw', 'greeting': 'Muraho', 'name': 'Kinyarwanda'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'SC': {  # Seychelles
                'native': {'code': 'crs', 'greeting': 'Bonzour', 'name': 'Seychellois Creole'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'SO': {  # Somalia
                'native': {'code': 'so', 'greeting': 'Iska warran', 'name': 'Somali'},
                'colonial': {'code': 'ar', 'greeting': 'مرحبا', 'name': 'Arabic'}
            },
            'SS': {  # South Sudan
                'native': {'code': 'din', 'greeting': 'Kudual', 'name': 'Dinka'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'TZ': {  # Tanzania
                'native': {'code': 'sw', 'greeting': 'Jambo', 'name': 'Swahili'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'UG': {  # Uganda
                'native': {'code': 'lg', 'greeting': 'Ki kati', 'name': 'Luganda'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'ZM': {  # Zambia
                'native': {'code': 'bem', 'greeting': 'Mwapoleni', 'name': 'Bemba'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'ZW': {  # Zimbabwe
                'native': {'code': 'sn', 'greeting': 'Mhoro', 'name': 'Shona'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },

            # CENTRAL AFRICA
            'CM': {  # Cameroon
                'native': {'code': 'ff', 'greeting': 'Jam nga fanaan', 'name': 'Fula'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'CF': {  # Central African Republic
                'native': {'code': 'sg', 'greeting': 'Bara Ala', 'name': 'Sango'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'TD': {  # Chad
                'native': {'code': 'ar', 'greeting': 'مرحبا', 'name': 'Chadian Arabic'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'CG': {  # Congo (Brazzaville)
                'native': {'code': 'ln', 'greeting': 'Mbote', 'name': 'Lingala'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'CD': {  # Congo (Kinshasa)
                'native': {'code': 'ln', 'greeting': 'Mbote', 'name': 'Lingala'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'GQ': {  # Equatorial Guinea
                'native': {'code': 'fan', 'greeting': 'Mbolo', 'name': 'Fang'},
                'colonial': {'code': 'es', 'greeting': 'Hola', 'name': 'Spanish'}
            },
            'GA': {  # Gabon
                'native': {'code': 'fan', 'greeting': 'Mbolo', 'name': 'Fang'},
                'colonial': {'code': 'fr', 'greeting': 'Bonjour', 'name': 'French'}
            },
            'ST': {  # Sao Tome and Principe
                'native': {'code': 'pt', 'greeting': 'Olá', 'name': 'Portuguese Creole'},
                'colonial': {'code': 'pt', 'greeting': 'Olá', 'name': 'Portuguese'}
            },

            # SOUTHERN AFRICA
            'AO': {  # Angola
                'native': {'code': 'umb', 'greeting': 'Wakulonga', 'name': 'Umbundu'},
                'colonial': {'code': 'pt', 'greeting': 'Olá', 'name': 'Portuguese'}
            },
            'BW': {  # Botswana
                'native': {'code': 'tn', 'greeting': 'Dumela', 'name': 'Tswana'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'SZ': {  # Eswatini
                'native': {'code': 'ss', 'greeting': 'Sawubona', 'name': 'Swati'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'LS': {  # Lesotho
                'native': {'code': 'st', 'greeting': 'Lumela', 'name': 'Sesotho'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'NA': {  # Namibia
                'native': {'code': 'hz', 'greeting': 'Wa uhala po', 'name': 'Herero'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
            'ZA': {  # South Africa
                'native': {'code': 'zu', 'greeting': 'Sawubona', 'name': 'Zulu'},
                'colonial': {'code': 'en', 'greeting': 'Hello', 'name': 'English'}
            },
        }

    @transaction.atomic
    def populate_all_greetings(self):
        """Populate greetings for all countries"""
        self.stdout.write('\nPopulating greetings...')

        for country_code, langs in self.country_languages.items():
            try:
                country = Country.objects.get(code=country_code)
                self.create_greetings_for_country(country, langs)
                self.stdout.write(f'  [OK] {country.name}: Greetings created')
            except Country.DoesNotExist:
                self.stdout.write(self.style.WARNING(f'  [!] Country {country_code} not found'))

    def create_greetings_for_country(self, country, langs):
        """Create general and holiday-specific greetings for a country"""
        native_greeting = langs['native']['greeting']
        native_lang_name = langs['native']['name']
        colonial_greeting = langs['colonial']['greeting']
        colonial_lang_name = langs['colonial']['name']

        # Get or create Language objects (we'll use dummy ones if they don't exist)
        native_lang = None
        colonial_lang = None

        # TIME-BASED GREETINGS (General - not holiday specific)
        time_greetings = [
            {
                'time': 'morning',
                'welcome': f"{native_greeting}! {colonial_greeting} and welcome to Hosi Academy! Start your learning journey this beautiful morning."
            },
            {
                'time': 'afternoon',
                'welcome': f"{native_greeting}! {colonial_greeting} and welcome to Hosi Academy! Continue your learning journey this afternoon."
            },
            {
                'time': 'evening',
                'welcome': f"{native_greeting}! {colonial_greeting} and welcome to Hosi Academy! Keep learning this evening."
            },
            {
                'time': 'any',
                'welcome': f"{native_greeting}! {colonial_greeting} and welcome to Hosi Academy!"
            }
        ]

        for greeting_data in time_greetings:
            LocalizedGreeting.objects.get_or_create(
                country=country,
                time_of_day=greeting_data['time'],
                holiday=None,  # General greeting, not holiday-specific
                defaults={
                    'native_greeting': native_greeting,
                    'native_language': native_lang,
                    'international_greeting': colonial_greeting,
                    'international_language': colonial_lang,
                    'welcome_message': greeting_data['welcome'],
                    'priority': 0,  # Lower priority than holiday greetings
                    'is_active': True
                }
            )

        # HOLIDAY-SPECIFIC GREETINGS
        holidays = PublicHoliday.objects.filter(country=country, is_active=True)

        for holiday in holidays[:10]:  # Create greetings for first 10 major holidays
            self.create_holiday_greeting(country, holiday, native_greeting, colonial_greeting, native_lang, colonial_lang)

    def create_holiday_greeting(self, country, holiday, native_greeting, colonial_greeting, native_lang, colonial_lang):
        """Create a holiday-specific greeting"""

        # Different messages for different holiday types
        if holiday.holiday_type == 'national':
            message = f"{native_greeting}! {colonial_greeting}! Happy {holiday.name}! Celebrating {country.name}'s heritage and unity. Welcome to Hosi Academy!"
        elif holiday.holiday_type == 'religious_christian':
            message = f"{native_greeting}! {colonial_greeting}! Wishing you a blessed {holiday.name}! Welcome to Hosi Academy!"
        elif holiday.holiday_type == 'religious_muslim':
            message = f"{native_greeting}! {colonial_greeting}! {holiday.name} Mubarak! May this blessed day bring peace and joy. Welcome to Hosi Academy!"
        elif holiday.holiday_type == 'cultural':
            message = f"{native_greeting}! {colonial_greeting}! Celebrating {holiday.name} with you! Welcome to Hosi Academy!"
        else:
            message = f"{native_greeting}! {colonial_greeting}! Happy {holiday.name}! Welcome to Hosi Academy!"

        LocalizedGreeting.objects.get_or_create(
            country=country,
            holiday=holiday,
            time_of_day='any',
            defaults={
                'native_greeting': native_greeting,
                'native_language': native_lang,
                'international_greeting': colonial_greeting,
                'international_language': colonial_lang,
                'welcome_message': message,
                'priority': 100,  # Higher priority - holiday greetings show first
                'is_active': True
            }
        )

    @transaction.atomic
    def populate_holiday_messages(self):
        """Populate holiday banner messages"""
        self.stdout.write('\nPopulating holiday messages...')

        # Get major holidays across all countries
        major_holidays = PublicHoliday.objects.filter(
            is_active=True,
            is_public_holiday=True
        )

        # Banner colors by holiday type
        colors = {
            'national': '#2E7D32',  # Green
            'religious_christian': '#1565C0',  # Blue
            'religious_muslim': '#00695C',  # Teal
            'cultural': '#F57C00',  # Orange
            'historical': '#5D4037',  # Brown
        }

        # Icons by holiday type
        icons = {
            'national': '🎉',
            'religious_christian': '✝️',
            'religious_muslim': '☪️',
            'cultural': '🎊',
            'historical': '📜',
        }

        created_count = 0
        for holiday in major_holidays[:100]:  # Create messages for first 100 major holidays
            country_langs = self.country_languages.get(holiday.country.code)
            if not country_langs:
                continue

            native_greeting = country_langs['native']['greeting']

            # Create message
            if holiday.holiday_type == 'national':
                message = f"Today we celebrate {holiday.name}! {holiday.country.name} marks this special day with pride and unity."
                native_message = f"{native_greeting}! Happy {holiday.name}!"
            elif holiday.holiday_type == 'religious_christian':
                message = f"Blessed {holiday.name}! May this holy day bring you peace and joy."
                native_message = f"{native_greeting}! {holiday.name} blessings!"
            elif holiday.holiday_type == 'religious_muslim':
                message = f"{holiday.name} Mubarak! Wishing you and your loved ones a blessed celebration."
                native_message = f"{native_greeting}! {holiday.name} Mubarak!"
            else:
                message = f"Happy {holiday.name}! Join us in celebrating this special occasion."
                native_message = f"{native_greeting}! {holiday.name}!"

            HolidayMessage.objects.get_or_create(
                holiday=holiday,
                defaults={
                    'message': message,
                    'native_language_message': native_message,
                    'show_banner': True,
                    'banner_color': colors.get(holiday.holiday_type, '#4CAF50'),
                    'banner_icon': icons.get(holiday.holiday_type, '🎉'),
                    'show_days_before': 0,  # Show on the day
                    'show_days_after': 0,   # Show on the day only
                    'is_active': True
                }
            )
            created_count += 1

        self.stdout.write(f'  [OK] Created {created_count} holiday messages')
