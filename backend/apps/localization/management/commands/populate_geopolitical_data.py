from django.core.management.base import BaseCommand
from apps.localization.models import Language, Country, State, City


class Command(BaseCommand):
    help = 'Populate Language, Country, Province and City tables with ALL African geopolitical data'

    def handle(self, *args, **options):
        self.stdout.write(self.style.WARNING('Starting comprehensive African geopolitical data population...'))
        
        # 1. Populate Languages (Focus on major African languages)
        languages_data = [
            {'code': 'sw', 'name': 'Swahili', 'native': 'Kiswahili', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'zu', 'name': 'Zulu', 'native': 'isiZulu', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'xh', 'name': 'Xhosa', 'native': 'isiXhosa', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'yo', 'name': 'Yoruba', 'native': 'Èdè Yorùbá', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'ig', 'name': 'Igbo', 'native': 'Asụsụ Igbo', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'ha', 'name': 'Hausa', 'native': 'Harshen Hausa', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'am', 'name': 'Amharic', 'native': 'አማርኛ', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'om', 'name': 'Oromo', 'native': 'Afaan Oromoo', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'ti', 'name': 'Tigrinya', 'native': 'ትግርኛ', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'rw', 'name': 'Kinyarwanda', 'native': 'Ikinyarwanda', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'sn', 'name': 'Shona', 'native': 'chiShona', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'so', 'name': 'Somali', 'native': 'Af-Soomaali', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'af', 'name': 'Afrikaans', 'native': 'Afrikaans', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'ln', 'name': 'Lingala', 'native': 'Lingála', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'ak', 'name': 'Akan', 'native': 'Akan', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'st', 'name': 'Sesotho', 'native': 'Sesotho', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'ts', 'name': 'Tsonga', 'native': 'Xitsonga', 'rtl': 0, 'status': 1, 'json_exist': 0},
            {'code': 'en', 'name': 'English', 'native': 'English', 'rtl': 0, 'status': 1, 'json_exist': 1},
            {'code': 'fr', 'name': 'French', 'native': 'Français', 'rtl': 0, 'status': 1, 'json_exist': 1},
            {'code': 'pt', 'name': 'Portuguese', 'native': 'Português', 'rtl': 0, 'status': 1, 'json_exist': 1},
            {'code': 'ar', 'name': 'Arabic', 'native': 'العربية', 'rtl': 1, 'status': 1, 'json_exist': 1},
        ]
        
        for lang_data in languages_data:
            Language.objects.update_or_create(code=lang_data['code'], defaults=lang_data)

        # 2. Comprehensive African Countries Data
        # Grouped by Region
        all_african_countries = [
            # Southern Africa
            {'code': 'ZA', 'name': 'South Africa', 'is_active': True},
            {'code': 'ZW', 'name': 'Zimbabwe', 'is_active': True},
            {'code': 'BW', 'name': 'Botswana', 'is_active': True},
            {'code': 'NA', 'name': 'Namibia', 'is_active': True},
            {'code': 'MZ', 'name': 'Mozambique', 'is_active': True},
            {'code': 'ZM', 'name': 'Zambia', 'is_active': True},
            {'code': 'MW', 'name': 'Malawi', 'is_active': True},
            {'code': 'LS', 'name': 'Lesotho', 'is_active': True},
            {'code': 'SZ', 'name': 'Eswatini', 'is_active': True},
            {'code': 'AO', 'name': 'Angola', 'is_active': True},

            # East Africa
            {'code': 'KE', 'name': 'Kenya', 'is_active': True},
            {'code': 'TZ', 'name': 'Tanzania', 'is_active': True},
            {'code': 'UG', 'name': 'Uganda', 'is_active': True},
            {'code': 'RW', 'name': 'Rwanda', 'is_active': True},
            {'code': 'ET', 'name': 'Ethiopia', 'is_active': True},
            {'code': 'SO', 'name': 'Somalia', 'is_active': True},
            {'code': 'ER', 'name': 'Eritrea', 'is_active': True},
            {'code': 'DJ', 'name': 'Djibouti', 'is_active': True},
            {'code': 'BI', 'name': 'Burundi', 'is_active': True},
            {'code': 'SS', 'name': 'South Sudan', 'is_active': True},
            {'code': 'KM', 'name': 'Comoros', 'is_active': True},
            {'code': 'MU', 'name': 'Mauritius', 'is_active': True},
            {'code': 'SC', 'name': 'Seychelles', 'is_active': True},
            {'code': 'MG', 'name': 'Madagascar', 'is_active': True},

            # West Africa
            {'code': 'NG', 'name': 'Nigeria', 'is_active': True},
            {'code': 'GH', 'name': 'Ghana', 'is_active': True},
            {'code': 'SN', 'name': 'Senegal', 'is_active': True},
            {'code': 'CI', 'name': 'Côte d\'Ivoire', 'is_active': True},
            {'code': 'GM', 'name': 'Gambia', 'is_active': True},
            {'code': 'GN', 'name': 'Guinea', 'is_active': True},
            {'code': 'GW', 'name': 'Guinea-Bissau', 'is_active': True},
            {'code': 'LR', 'name': 'Liberia', 'is_active': True},
            {'code': 'SL', 'name': 'Sierra Leone', 'is_active': True},
            {'code': 'ML', 'name': 'Mali', 'is_active': True},
            {'code': 'BF', 'name': 'Burkina Faso', 'is_active': True},
            {'code': 'NE', 'name': 'Niger', 'is_active': True},
            {'code': 'TG', 'name': 'Togo', 'is_active': True},
            {'code': 'BJ', 'name': 'Benin', 'is_active': True},
            {'code': 'CV', 'name': 'Cabo Verde', 'is_active': True},
            {'code': 'MR', 'name': 'Mauritania', 'is_active': True},

            # Central Africa
            {'code': 'CD', 'name': 'Democratic Republic of Congo', 'is_active': True},
            {'code': 'CG', 'name': 'Republic of Congo', 'is_active': True},
            {'code': 'CM', 'name': 'Cameroon', 'is_active': True},
            {'code': 'GA', 'name': 'Gabon', 'is_active': True},
            {'code': 'CF', 'name': 'Central African Republic', 'is_active': True},
            {'code': 'TD', 'name': 'Chad', 'is_active': True},
            {'code': 'GQ', 'name': 'Equatorial Guinea', 'is_active': True},
            {'code': 'ST', 'name': 'Sao Tome and Principe', 'is_active': True},

            # North Africa
            {'code': 'EG', 'name': 'Egypt', 'is_active': True},
            {'code': 'MA', 'name': 'Morocco', 'is_active': True},
            {'code': 'DZ', 'name': 'Algeria', 'is_active': True},
            {'code': 'TN', 'name': 'Tunisia', 'is_active': True},
            {'code': 'LY', 'name': 'Libya', 'is_active': True},
            {'code': 'SD', 'name': 'Sudan', 'is_active': True},
        ]

        for country_data in all_african_countries:
            Country.objects.update_or_create(code=country_data['code'], defaults=country_data)

        # 3. Hierarchy Data for ALL African Countries
        location_data = {
            # --- SOUTHERN AFRICA ---
            'ZA': {
                'Gauteng': ['Johannesburg', 'Pretoria', 'Soweto', 'Sandton', 'Centurion'],
                'Western Cape': ['Cape Town', 'Stellenbosch', 'Paarl', 'George'],
                'KwaZulu-Natal': ['Durban', 'Pietermaritzburg', 'Umhlanga'],
                'Eastern Cape': ['Gqeberha', 'East London', 'Mthatha'],
                'Free State': ['Bloemfontein', 'Welkom'],
                'Limpopo': ['Polokwane', 'Tzaneen'],
                'Mpumalanga': ['Mbombela', 'Witbank'],
                'North West': ['Mahikeng', 'Rustenburg'],
                'Northern Cape': ['Kimberley', 'Upington'],
            },
            'ZW': {
                'Harare': ['Harare', 'Chitungwiza', 'Epworth'],
                'Bulawayo': ['Bulawayo'],
                'Manicaland': ['Mutare', 'Rusape', 'Chipinge'],
                'Mashonaland Central': ['Bindura', 'Mazowe'],
                'Mashonaland East': ['Marondera', 'Goromonzi'],
                'Mashonaland West': ['Chinhoyi', 'Kadoma', 'Kariba'],
                'Masvingo': ['Masvingo', 'Chiredzi'],
                'Matabeleland North': ['Victoria Falls', 'Hwange'],
                'Matabeleland South': ['Gwanda', 'Beitbridge'],
                'Midlands': ['Gweru', 'Kwekwe', 'Zvishavane'],
            },
            'BW': {
                'South-East': ['Gaborone', 'Ramotswa'],
                'Francistown': ['Francistown'],
                'Kweneng': ['Molepolole', 'Mogoditshane'],
                'Central': ['Serowe', 'Palapye', 'Mahalapye', 'Selibe Phikwe'],
                'North-West': ['Maun', 'Kasane'],
                'Kgatleng': ['Mochudi'],
                'Southern': ['Kanye', 'Lobatse'],
            },
            'NA': {
                'Khomas': ['Windhoek'],
                'Erongo': ['Walvis Bay', 'Swakopmund'],
                'Oshana': ['Oshakati', 'Ongwediva'],
                'Otjozondjupa': ['Otjiwarongo', 'Okahandja'],
                'Hardap': ['Rehoboth', 'Mariental'],
            },
            'MZ': {
                'Maputo City': ['Maputo'],
                'Sofala': ['Beira'],
                'Nampula': ['Nampula', 'Nacala'],
                'Tete': ['Tete'],
                'Zambezia': ['Quelimane'],
            },
            'ZM': {
                'Lusaka': ['Lusaka', 'Chilanga', 'Kafue'],
                'Copperbelt': ['Ndola', 'Kitwe', 'Mufulira', 'Luanshya'],
                'Southern': ['Livingstone', 'Choma', 'Mazabuka'],
                'Central': ['Kabwe'],
            },
            'MW': {
                'Lilongwe': ['Lilongwe'],
                'Blantyre': ['Blantyre', 'Limbe'],
                'Mzuzu': ['Mzuzu'],
                'Zomba': ['Zomba'],
            },
            'LS': {
                'Maseru': ['Maseru'],
                'Leribe': ['Hlotse', 'Maputsoe'],
                'Mafeteng': ['Mafeteng'],
            },
            'SZ': {
                'Hhohho': ['Mbabane'],
                'Manzini': ['Manzini', 'Matsapha'],
                'Lubombo': ['Siteki'],
                'Shiselweni': ['Nhlangano'],
            },
            'AO': {
                'Luanda': ['Luanda', 'Viana', 'Cacuaco'],
                'Benguela': ['Benguela', 'Lobito'],
                'Huambo': ['Huambo'],
                'Huila': ['Lubango'],
            },

            # --- EAST AFRICA ---
            'KE': {
                'Nairobi': ['Nairobi'],
                'Mombasa': ['Mombasa'],
                'Kisumu': ['Kisumu'],
                'Nakuru': ['Nakuru', 'Naivasha'],
                'Uasin Gishu': ['Eldoret'],
                'Kiambu': ['Thika', 'Ruiru'],
            },
            'TZ': {
                'Dar es Salaam': ['Dar es Salaam'],
                'Arusha': ['Arusha'],
                'Mwanza': ['Mwanza'],
                'Dodoma': ['Dodoma'],
                'Zanzibar': ['Zanzibar City'],
            },
            'UG': {
                'Central': ['Kampala', 'Entebbe', 'Mukono'],
                'Eastern': ['Jinja', 'Mbale'],
                'Western': ['Mbarara', 'Fort Portal'],
                'Northern': ['Gulu', 'Lira'],
            },
            'RW': {
                'Kigali': ['Kigali'],
                'Northern': ['Musanze'],
                'Southern': ['Huye', 'Muhanga'],
                'Eastern': ['Rwamagana'],
                'Western': ['Rubavu'],
            },
            'ET': {
                'Addis Ababa': ['Addis Ababa'],
                'Oromia': ['Adama', 'Jimma'],
                'Amhara': ['Bahir Dar', 'Gondar'],
                'Tigray': ['Mekelle'],
            },
            'SO': {
                'Banaadir': ['Mogadishu'],
                'Somaliland': ['Hargeisa', 'Berbera'],
                'Puntland': ['Garowe', 'Bosaso'],
            },
            'ER': {
                'Maekel': ['Asmara'],
                'Anseba': ['Keren'],
                'Semienawi Keyih Bahri': ['Massawa'],
            },
            'DJ': {
                'Djibouti': ['Djibouti City'],
                'Ali Sabieh': ['Ali Sabieh'],
            },
            'BI': {
                'Bujumbura Mairie': ['Bujumbura'],
                'Gitega': ['Gitega'],
                'Ngozi': ['Ngozi'],
            },
            'SS': {
                'Central Equatoria': ['Juba'],
                'Upper Nile': ['Malakal'],
                'Western Bahr el Ghazal': ['Wau'],
            },
            'KM': {
                'Grande Comore': ['Moroni'],
                'Anjouan': ['Mutsamudu'],
            },
            'MU': {
                'Port Louis': ['Port Louis'],
                'Plaines Wilhems': ['Curepipe', 'Vacoas', 'Beau Bassin'],
            },
            'SC': {
                'Victoria': ['Victoria'],
            },
            'MG': {
                'Analamanga': ['Antananarivo'],
                'Atsinanana': ['Toamasina'],
                'Boeny': ['Mahajanga'],
            },

            # --- WEST AFRICA ---
            'NG': {
                'Lagos': ['Ikeja', 'Lagos Island', 'Lekki', 'Victoria Island'],
                'Abuja (FCT)': ['Abuja', 'Gwagwalada'],
                'Rivers': ['Port Harcourt'],
                'Oyo': ['Ibadan'],
                'Kano': ['Kano'],
                'Kaduna': ['Kaduna'],
                'Enugu': ['Enugu'],
            },
            'GH': {
                'Greater Accra': ['Accra', 'Tema'],
                'Ashanti': ['Kumasi'],
                'Western': ['Sekondi-Takoradi'],
                'Northern': ['Tamale'],
            },
            'SN': {
                'Dakar': ['Dakar'],
                'Thiès': ['Thiès'],
                'Saint-Louis': ['Saint-Louis'],
            },
            'CI': {
                'Abidjan': ['Abidjan'],
                'Yamoussoukro': ['Yamoussoukro'],
                'Bas-Sassandra': ['San-Pédro'],
            },
            'GM': {
                'Banjul': ['Banjul'],
                'Kanifing': ['Serrekunda'],
            },
            'GN': {
                'Conakry': ['Conakry'],
                'Kindia': ['Kindia'],
            },
            'GW': {
                'Bissau': ['Bissau'],
            },
            'LR': {
                'Montserrado': ['Monrovia'],
            },
            'SL': {
                'Western Area': ['Freetown'],
                'Northern': ['Makeni'],
            },
            'ML': {
                'Bamako': ['Bamako'],
                'Sikasso': ['Sikasso'],
            },
            'BF': {
                'Centre': ['Ouagadougou'],
                'Hauts-Bassins': ['Bobo-Dioulasso'],
            },
            'NE': {
                'Niamey': ['Niamey'],
                'Zinder': ['Zinder'],
            },
            'TG': {
                'Maritime': ['Lomé'],
                'Centrale': ['Sokodé'],
            },
            'BJ': {
                'Littoral': ['Cotonou'],
                'Ouémé': ['Porto-Novo'],
            },
            'CV': {
                'Santiago': ['Praia'],
                'São Vicente': ['Mindelo'],
            },
            'MR': {
                'Nouakchott': ['Nouakchott'],
                'Dakhlet Nouadhibou': ['Nouadhibou'],
            },

            # --- CENTRAL AFRICA ---
            'CD': {
                'Kinshasa': ['Kinshasa'],
                'Haut-Katanga': ['Lubumbashi'],
                'Kongo Central': ['Matadi'],
                'North Kivu': ['Goma'],
            },
            'CG': {
                'Brazzaville': ['Brazzaville'],
                'Pointe-Noire': ['Pointe-Noire'],
            },
            'CM': {
                'Centre': ['Yaoundé'],
                'Littoral': ['Douala'],
                'North West': ['Bamenda'],
            },
            'GA': {
                'Estuaire': ['Libreville'],
                'Ogooué-Maritime': ['Port-Gentil'],
            },
            'CF': {
                'Bangui': ['Bangui'],
            },
            'TD': {
                'N\'Djamena': ['N\'Djamena'],
                'Logone Occidental': ['Moundou'],
            },
            'GQ': {
                'Bioko Norte': ['Malabo'],
                'Litoral': ['Bata'],
            },
            'ST': {
                'Água Grande': ['São Tomé'],
            },

            # --- NORTH AFRICA ---
            'EG': {
                'Cairo': ['Cairo', 'Giza'],
                'Alexandria': ['Alexandria'],
                'Dakahlia': ['Mansoura'],
                'Red Sea': ['Hurghada'],
            },
            'MA': {
                'Casablanca-Settat': ['Casablanca'],
                'Rabat-Salé-Kénitra': ['Rabat', 'Salé'],
                'Marrakesh-Safi': ['Marrakesh'],
                'Fès-Meknès': ['Fès', 'Meknès'],
                'Tanger-Tetouan-Al Hoceima': ['Tangier'],
            },
            'DZ': {
                'Algiers': ['Algiers'],
                'Oran': ['Oran'],
                'Constantine': ['Constantine'],
            },
            'TN': {
                'Tunis': ['Tunis'],
                'Sfax': ['Sfax'],
                'Sousse': ['Sousse'],
            },
            'LY': {
                'Tripoli': ['Tripoli'],
                'Benghazi': ['Benghazi'],
                'Misrata': ['Misrata'],
            },
            'SD': {
                'Khartoum': ['Khartoum', 'Omdurman'],
                'Red Sea': ['Port Sudan'],
            },
        }

        for country_code, data in location_data.items():
            try:
                country = Country.objects.get(code=country_code)
                self.populate_location_hierarchy(country, data)
            except Country.DoesNotExist:
                self.stdout.write(self.style.ERROR(f'Country {country_code} not found in database!'))

        self.stdout.write(self.style.SUCCESS(f'\n✅ Comprehensive Population complete!'))

    def populate_location_hierarchy(self, country, data):
        """Helper to create states and cities for a country"""
        self.stdout.write(self.style.WARNING(f'Populating locations for {country.name}...'))
        for state_name, cities in data.items():
            state, _ = State.objects.update_or_create(
                country=country,
                name=state_name
            )
            for city_name in cities:
                City.objects.update_or_create(
                    state=state,
                    name=city_name
                )
            self.stdout.write(f'  ✓ {state_name}: {len(cities)} cities')
