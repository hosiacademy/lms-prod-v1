#!/usr/bin/env python
"""
Populate African states/regions and major cities.
Focuses on major African countries with key states/provinces and cities.
"""
from django.core.management.base import BaseCommand
from apps.localization.models import Country, State, City


class Command(BaseCommand):
    help = 'Populate African states and major cities'

    def handle(self, *args, **options):
        self.stdout.write("Populating African locations...")

        # Kenya
        self.populate_kenya()

        # Nigeria
        self.populate_nigeria()

        # South Africa
        self.populate_south_africa()

        # Ghana
        self.populate_ghana()

        # Egypt
        self.populate_egypt()

        # Tanzania
        self.populate_tanzania()

        # Uganda
        self.populate_uganda()

        # Morocco
        self.populate_morocco()

        self.stdout.write(self.style.SUCCESS("African locations populated successfully!"))

    def populate_kenya(self):
        try:
            kenya = Country.objects.get(code='KE')
        except Country.DoesNotExist:
            self.stdout.write(self.style.WARNING("Kenya not found, skipping"))
            return

        states_cities = {
            'Nairobi County': ['Nairobi', 'Westlands', 'Karen', 'Kibera'],
            'Mombasa County': ['Mombasa', 'Nyali', 'Likoni'],
            'Kisumu County': ['Kisumu', 'Kisumu Central'],
            'Nakuru County': ['Nakuru', 'Naivasha'],
            'Kiambu County': ['Thika', 'Kikuyu', 'Ruiru'],
            'Machakos County': ['Machakos', 'Athi River'],
        }

        for state_name, cities in states_cities.items():
            state, _ = State.objects.get_or_create(
                country=kenya,
                name=state_name,
                defaults={'code': state_name[:3].upper()}
            )
            for city_name in cities:
                City.objects.get_or_create(
                    state=state,
                    name=city_name
                )

        self.stdout.write("Kenya locations added")

    def populate_nigeria(self):
        try:
            nigeria = Country.objects.get(code='NG')
        except Country.DoesNotExist:
            self.stdout.write(self.style.WARNING("Nigeria not found, skipping"))
            return

        states_cities = {
            'Lagos State': ['Lagos', 'Ikeja', 'Lekki', 'Victoria Island'],
            'Abuja': ['Abuja', 'Asokoro', 'Maitama', 'Gwagwalada'],
            'Kano State': ['Kano', 'Kano Municipal'],
            'Rivers State': ['Port Harcourt', 'Bonny'],
            'Kaduna State': ['Kaduna', 'Zaria'],
            'Oyo State': ['Ibadan', 'Oyo'],
            'Anambra State': ['Awka', 'Onitsha', 'Nnewi'],
        }

        for state_name, cities in states_cities.items():
            state, _ = State.objects.get_or_create(
                country=nigeria,
                name=state_name,
                defaults={'code': state_name[:3].upper()}
            )
            for city_name in cities:
                City.objects.get_or_create(
                    state=state,
                    name=city_name
                )

        self.stdout.write("Nigeria locations added")

    def populate_south_africa(self):
        try:
            sa = Country.objects.get(code='ZA')
        except Country.DoesNotExist:
            self.stdout.write(self.style.WARNING("South Africa not found, skipping"))
            return

        states_cities = {
            'Gauteng': ['Johannesburg', 'Pretoria', 'Sandton', 'Soweto', 'Centurion'],
            'Western Cape': ['Cape Town', 'Stellenbosch', 'Paarl', 'George'],
            'KwaZulu-Natal': ['Durban', 'Pietermaritzburg', 'Richards Bay'],
            'Eastern Cape': ['Port Elizabeth', 'East London', 'Mthatha'],
            'Free State': ['Bloemfontein', 'Welkom'],
            'Limpopo': ['Polokwane', 'Tzaneen'],
            'Mpumalanga': ['Nelspruit', 'Witbank'],
            'North West': ['Rustenburg', 'Mahikeng'],
            'Northern Cape': ['Kimberley', 'Upington'],
        }

        for state_name, cities in states_cities.items():
            state, _ = State.objects.get_or_create(
                country=sa,
                name=state_name,
                defaults={'code': state_name[:3].upper()}
            )
            for city_name in cities:
                City.objects.get_or_create(
                    state=state,
                    name=city_name
                )

        self.stdout.write("South Africa locations added")

    def populate_ghana(self):
        try:
            ghana = Country.objects.get(code='GH')
        except Country.DoesNotExist:
            self.stdout.write(self.style.WARNING("Ghana not found, skipping"))
            return

        states_cities = {
            'Greater Accra Region': ['Accra', 'Tema', 'Kasoa'],
            'Ashanti Region': ['Kumasi', 'Obuasi'],
            'Western Region': ['Sekondi-Takoradi'],
            'Central Region': ['Cape Coast', 'Winneba'],
            'Eastern Region': ['Koforidua', 'Akosombo'],
        }

        for state_name, cities in states_cities.items():
            state, _ = State.objects.get_or_create(
                country=ghana,
                name=state_name,
                defaults={'code': state_name[:3].upper()}
            )
            for city_name in cities:
                City.objects.get_or_create(
                    state=state,
                    name=city_name
                )

        self.stdout.write("Ghana locations added")

    def populate_egypt(self):
        try:
            egypt = Country.objects.get(code='EG')
        except Country.DoesNotExist:
            self.stdout.write(self.style.WARNING("Egypt not found, skipping"))
            return

        states_cities = {
            'Cairo Governorate': ['Cairo', 'Heliopolis', 'Nasr City'],
            'Alexandria Governorate': ['Alexandria', 'Borg El Arab'],
            'Giza Governorate': ['Giza', '6th of October City'],
            'Qalyubia Governorate': ['Banha', 'Shubra El Kheima'],
        }

        for state_name, cities in states_cities.items():
            state, _ = State.objects.get_or_create(
                country=egypt,
                name=state_name,
                defaults={'code': state_name[:3].upper()}
            )
            for city_name in cities:
                City.objects.get_or_create(
                    state=state,
                    name=city_name
                )

        self.stdout.write("Egypt locations added")

    def populate_tanzania(self):
        try:
            tz = Country.objects.get(code='TZ')
        except Country.DoesNotExist:
            self.stdout.write(self.style.WARNING("Tanzania not found, skipping"))
            return

        states_cities = {
            'Dar es Salaam Region': ['Dar es Salaam', 'Kinondoni', 'Temeke'],
            'Arusha Region': ['Arusha', 'Moshi'],
            'Mwanza Region': ['Mwanza', 'Misungwi'],
            'Dodoma Region': ['Dodoma'],
            'Zanzibar': ['Zanzibar City', 'Stone Town'],
        }

        for state_name, cities in states_cities.items():
            state, _ = State.objects.get_or_create(
                country=tz,
                name=state_name,
                defaults={'code': state_name[:3].upper()}
            )
            for city_name in cities:
                City.objects.get_or_create(
                    state=state,
                    name=city_name
                )

        self.stdout.write("Tanzania locations added")

    def populate_uganda(self):
        try:
            uganda = Country.objects.get(code='UG')
        except Country.DoesNotExist:
            self.stdout.write(self.style.WARNING("Uganda not found, skipping"))
            return

        states_cities = {
            'Central Region': ['Kampala', 'Entebbe', 'Mukono'],
            'Eastern Region': ['Jinja', 'Mbale', 'Tororo'],
            'Northern Region': ['Gulu', 'Lira'],
            'Western Region': ['Mbarara', 'Fort Portal', 'Kasese'],
        }

        for state_name, cities in states_cities.items():
            state, _ = State.objects.get_or_create(
                country=uganda,
                name=state_name,
                defaults={'code': state_name[:3].upper()}
            )
            for city_name in cities:
                City.objects.get_or_create(
                    state=state,
                    name=city_name
                )

        self.stdout.write("Uganda locations added")

    def populate_morocco(self):
        try:
            morocco = Country.objects.get(code='MA')
        except Country.DoesNotExist:
            self.stdout.write(self.style.WARNING("Morocco not found, skipping"))
            return

        states_cities = {
            'Casablanca-Settat': ['Casablanca', 'Mohammedia', 'El Jadida'],
            'Rabat-Salé-Kénitra': ['Rabat', 'Salé', 'Kénitra'],
            'Fès-Meknès': ['Fès', 'Meknès'],
            'Marrakesh-Safi': ['Marrakesh', 'Safi', 'Essaouira'],
            'Tangier-Tetouan-Al Hoceima': ['Tangier', 'Tetouan'],
        }

        for state_name, cities in states_cities.items():
            state, _ = State.objects.get_or_create(
                country=morocco,
                name=state_name,
                defaults={'code': state_name[:3].upper()}
            )
            for city_name in cities:
                City.objects.get_or_create(
                    state=state,
                    name=city_name
                )

        self.stdout.write("Morocco locations added")
