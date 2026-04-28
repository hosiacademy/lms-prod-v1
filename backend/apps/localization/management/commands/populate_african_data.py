from django.core.management.base import BaseCommand
from apps.localization.models import Country, Language, CountryOverride
from datetime import date

class Command(BaseCommand):
    help = 'Populate African countries, languages, and country overrides with Afro-centric data'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Starting population of African data...'))

        # Helper to get/create Language
        def get_or_create_lang(code, name, native, status=1, json_exist=0, rtl=0):
            lang, created = Language.objects.get_or_create(
                code=code,
                defaults={'name': name, 'native': native, 'status': status,
                          'json_exist': json_exist, 'rtl': rtl}
            )
            if created:
                self.stdout.write(f'Created language: {name} ({code})')
            return lang

        # Languages (only create if missing)
        languages = [
            ('en', 'English', 'English', 1, 1, 0),
            ('zu', 'isiZulu', 'isiZulu', 1, 0, 0),
            ('xh', 'isiXhosa', 'isiXhosa', 1, 0, 0),
            ('ar', 'Arabic', 'العربية', 1, 1, 1),
            ('fr', 'French', 'Français', 1, 1, 0),
            ('pt', 'Portuguese', 'Português', 1, 1, 0),
            ('sw', 'Swahili', 'Kiswahili', 1, 0, 0),
            ('ha', 'Hausa', 'Hausa', 1, 0, 0),
            ('yo', 'Yoruba', 'Èdè Yorùbá', 1, 0, 0),
            ('ig', 'Igbo', 'Asụsụ Igbo', 1, 0, 0),
            ('am', 'Amharic', 'አማርኛ', 1, 0, 0),
            ('om', 'Oromo', 'Afaan Oromoo', 1, 0, 0),
            ('ti', 'Tigrinya', 'ትግርኛ', 1, 0, 0),
            ('rw', 'Kinyarwanda', 'Ikinyarwanda', 1, 0, 0),
            ('ln', 'Lingala', 'Lingála', 1, 0, 0),
            ('sn', 'Shona', 'chiShona', 1, 0, 0),
            ('so', 'Somali', 'Af-Soomaali', 1, 0, 0),
            ('ak', 'Akan', 'Akan', 1, 0, 0),
            ('mg', 'Malagasy', 'Malagasy', 1, 0, 0),
            ('ny', 'Chichewa', 'Chichewa', 1, 0, 0),
            ('bm', 'Bambara', 'Bamanankan', 1, 0, 0),
            ('ff', 'Fula', 'Fulfulde', 1, 0, 0),
            ('wo', 'Wolof', 'Wolof', 1, 0, 0),
        ]

        for data in languages:
            get_or_create_lang(*data)

        # Full 54 countries data
        countries_data = [
            {"code": "DZ", "name": "Algeria", "main_lang": "ar", "local1": "ber", "local2": "fr"},
            {"code": "AO", "name": "Angola", "main_lang": "pt", "local1": "umb", "local2": "kik"},
            {"code": "BJ", "name": "Benin", "main_lang": "fr", "local1": "fon", "local2": "yo"},
            {"code": "BW", "name": "Botswana", "main_lang": "en", "local1": "tn", "local2": "kln"},
            {"code": "BF", "name": "Burkina Faso", "main_lang": "fr", "local1": "mos", "local2": "dyu"},
            {"code": "BI", "name": "Burundi", "main_lang": "rn", "local2": "fr", "local1": "sw"},
            {"code": "CV", "name": "Cabo Verde", "main_lang": "pt", "local1": "kea", "local2": "kab"},
            {"code": "CM", "name": "Cameroon", "main_lang": "fr", "local1": "en", "local2": "bam"},
            {"code": "CF", "name": "Central African Republic", "main_lang": "fr", "local1": "sg", "local2": "gba"},
            {"code": "TD", "name": "Chad", "main_lang": "fr", "local1": "ar", "local2": "saa"},
            {"code": "KM", "name": "Comoros", "main_lang": "ar", "local1": "fr", "local2": "swb"},
            {"code": "CD", "name": "Democratic Republic of the Congo", "main_lang": "fr", "local1": "ln", "local2": "sw"},
            {"code": "CG", "name": "Republic of the Congo", "main_lang": "fr", "local1": "ln", "local2": "kng"},
            {"code": "CI", "name": "Cote d'Ivoire", "main_lang": "fr", "local1": "dyu", "local2": "bci"},
            {"code": "DJ", "name": "Djibouti", "main_lang": "fr", "local1": "ar", "local2": "aa"},
            {"code": "EG", "name": "Egypt", "main_lang": "ar", "local1": "arz", "local2": "cop"},
            {"code": "GQ", "name": "Equatorial Guinea", "main_lang": "es", "local1": "fr", "local2": "fan"},
            {"code": "ER", "name": "Eritrea", "main_lang": "ti", "local1": "ar", "local2": "tig"},
            {"code": "SZ", "name": "Eswatini", "main_lang": "en", "local1": "ss", "local2": "zu"},
            {"code": "ET", "name": "Ethiopia", "main_lang": "am", "local1": "om", "local2": "ti"},
            {"code": "GA", "name": "Gabon", "main_lang": "fr", "local1": "fan", "local2": "mye"},
            {"code": "GM", "name": "Gambia", "main_lang": "en", "local1": "mnk", "local2": "wo"},
            {"code": "GH", "name": "Ghana", "main_lang": "en", "local1": "ak", "local2": "ee"},
            {"code": "GN", "name": "Guinea", "main_lang": "fr", "local1": "ff", "local2": "man"},
            {"code": "GW", "name": "Guinea-Bissau", "main_lang": "pt", "local1": "pov", "local2": "ff"},
            {"code": "KE", "name": "Kenya", "main_lang": "en", "local1": "sw", "local2": "ki"},
            {"code": "LS", "name": "Lesotho", "main_lang": "en", "local1": "st", "local2": "zu"},
            {"code": "LR", "name": "Liberia", "main_lang": "en", "local1": "kpe", "local2": "bsq"},
            {"code": "LY", "name": "Libya", "main_lang": "ar", "local1": "ber", "local2": "tbu"},
            {"code": "MG", "name": "Madagascar", "main_lang": "mg", "local1": "fr", "local2": "bhr"},
            {"code": "MW", "name": "Malawi", "main_lang": "en", "local1": "ny", "local2": "yao"},
            {"code": "ML", "name": "Mali", "main_lang": "fr", "local1": "bm", "local2": "ff"},
            {"code": "MR", "name": "Mauritania", "main_lang": "ar", "local1": "fuc", "local2": "wo"},
            {"code": "MU", "name": "Mauritius", "main_lang": "en", "local1": "mfe", "local2": "fr"},
            {"code": "MA", "name": "Morocco", "main_lang": "ar", "local1": "ber", "local2": "fr"},
            {"code": "MZ", "name": "Mozambique", "main_lang": "pt", "local1": "vmw", "local2": "tng"},
            {"code": "NA", "name": "Namibia", "main_lang": "en", "local1": "ng", "local2": "af"},
            {"code": "NE", "name": "Niger", "main_lang": "fr", "local1": "ha", "local2": "dje"},
            {"code": "NG", "name": "Nigeria", "main_lang": "en", "local1": "ha", "local2": "yo"},
            {"code": "RW", "name": "Rwanda", "main_lang": "rw", "local1": "en", "local2": "fr"},
            {"code": "ST", "name": "Sao Tome and Principe", "main_lang": "pt", "local1": "cri", "local2": "ao"},
            {"code": "SN", "name": "Senegal", "main_lang": "fr", "local1": "wo", "local2": "fuc"},
            {"code": "SC", "name": "Seychelles", "main_lang": "en", "local1": "fr", "local2": "crs"},
            {"code": "SL", "name": "Sierra Leone", "main_lang": "en", "local1": "kri", "local2": "men"},
            {"code": "SO", "name": "Somalia", "main_lang": "so", "local1": "ar", "local2": "maa"},
            {"code": "ZA", "name": "South Africa", "main_lang": "en", "local1": "zu", "local2": "xh"},
            {"code": "SS", "name": "South Sudan", "main_lang": "en", "local1": "din", "local2": "nus"},
            {"code": "SD", "name": "Sudan", "main_lang": "ar", "local1": "nub", "local2": "bej"},
            {"code": "TZ", "name": "Tanzania", "main_lang": "sw", "local1": "en", "local2": "kiv"},
            {"code": "TG", "name": "Togo", "main_lang": "fr", "local1": "ee", "local2": "kab"},
            {"code": "TN", "name": "Tunisia", "main_lang": "ar", "local1": "fr", "local2": "ber"},
            {"code": "UG", "name": "Uganda", "main_lang": "en", "local1": "lg", "local2": "sw"},
            {"code": "ZM", "name": "Zambia", "main_lang": "en", "local1": "bem", "local2": "nya"},
            {"code": "ZW", "name": "Zimbabwe", "main_lang": "en", "local1": "sn", "local2": "nd"},
        ]

        self.stdout.write(f"Creating {len(countries_data)} countries and overrides...")

        for data in countries_data:
            country_code = data["code"]
            country_name = data["name"]

            country, _ = Country.objects.get_or_create(
                code=country_code,
                defaults={"name": country_name, "is_active": True}
            )

            main_lang = get_or_create_lang(data["main_lang"], data["main_lang"].upper(), data["main_lang"].upper())
            local1 = get_or_create_lang(data["local1"], data["local1"].upper(), data["local1"].upper())
            local2 = get_or_create_lang(data["local2"], data["local2"].upper(), data["local2"].upper())

            override, created = CountryOverride.objects.get_or_create(
                country=country,
                defaults={
                    "default_language": main_lang,
                    "is_default": country_code == "ZA",
                    "greeting_message": f"Welcome to {country_name}!",
                    "cultural_note": f"Celebrating the rich diversity of {country_name}.",
                    "holiday_banner_url": f"https://example.com/banners/{country_code.lower()}-holiday.jpg",
                }
            )

            if country_code == "ZA":
                override.greeting_message = "Sawubona! Welcome to AfroLearn"
                override.holiday_date = date(2026, 6, 16)
                override.holiday_banner_url = "https://example.com/youth-day.jpg"
                override.cultural_note = "Honouring the 1976 Soweto Youth Uprising – symbol of resistance and education"
            elif country_code == "NG":
                override.greeting_message = "Bawo ni? Welcome to AfroLearn"
                override.holiday_date = date(2026, 10, 1)
                override.cultural_note = "Celebrating Independence Day and Nigeria's vibrant cultural heritage"
            elif country_code == "KE":
                override.greeting_message = "Jambo! Welcome to AfroLearn"
                override.holiday_date = date(2026, 12, 12)
                override.cultural_note = "Jamhuri Day – commemorating Kenya's independence and unity"

            override.default_language = main_lang
            override.save()

            self.stdout.write(self.style.SUCCESS(
                f"Processed: {country_name} ({country_code}) → Default: {main_lang.name}"
            ))

        self.stdout.write(self.style.SUCCESS(
            "\nDONE! All 54 African countries, languages, and overrides are now in the database."
        ))
        self.stdout.write("Check admin: /admin/localization/country/ and /admin/localization/countryoverride/")