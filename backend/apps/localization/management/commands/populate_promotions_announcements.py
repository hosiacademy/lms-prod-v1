"""
Management command to populate sample localized promotions and announcements.

Creates country-specific promotions and announcements for testing.

Usage:
    python manage.py populate_promotions_announcements
    python manage.py populate_promotions_announcements --clear
"""

from django.core.management.base import BaseCommand
from django.db import transaction
from datetime import date, timedelta
from apps.localization.models import (
    Country, LocalizedPromotion, LocalizedAnnouncement
)


class Command(BaseCommand):
    help = 'Populate sample localized promotions and announcements'

    def add_arguments(self, parser):
        parser.add_argument(
            '--clear',
            action='store_true',
            help='Clear existing promotions and announcements before populating',
        )

    def handle(self, *args, **options):
        if options['clear']:
            self.stdout.write(self.style.WARNING('Clearing existing promotions and announcements...'))
            LocalizedPromotion.objects.all().delete()
            LocalizedAnnouncement.objects.all().delete()

        self.stdout.write(self.style.SUCCESS('Populating sample promotions and announcements...'))

        self.populate_promotions()
        self.populate_announcements()

        total_promotions = LocalizedPromotion.objects.count()
        total_announcements = LocalizedAnnouncement.objects.count()

        self.stdout.write(self.style.SUCCESS(
            f'\n[SUCCESS] Created {total_promotions} promotions and {total_announcements} announcements!'
        ))

    @transaction.atomic
    def populate_promotions(self):
        """Create sample promotions"""
        self.stdout.write('\nCreating promotions...')

        today = date.today()

        promotions = [
            # Kenya-specific promotion
            {
                'countries': ['KE'],
                'title': '50% Off AI Courses',
                'native_title': 'Punguzo la 50% kwa Kozi za AI',
                'description': 'Special offer for Kenyan students! Get 50% off all AI and Machine Learning courses this month. Limited time only!',
                'native_description': 'Ofa maalum kwa wanafunzi wa Kenya! Pata punguzo la 50% kwa kozi zote za AI na Ujifunzaji wa Mashine mwezi huu.',
                'promotion_type': 'discount',
                'icon': '💰',
                'background_color': '#FF5722',
                'text_color': '#FFFFFF',
                'cta_text': 'Enroll Now',
                'cta_url': '/courses/ai',
                'start_date': today,
                'end_date': today + timedelta(days=30),
                'priority': 100,
                'show_on_onboarding': True,
            },

            # Nigeria-specific promotion
            {
                'countries': ['NG'],
                'title': 'Free Certification for First 100 Students',
                'native_title': 'Satifiket Kyauta ga Dalibai 100 na Farko',
                'description': 'Be among the first 100 Nigerian students to complete any course and get FREE certification!',
                'native_description': 'Ku kasance daga cikin dalibai 100 na Najeriya na farko da suka kammala kowane kwas kuma ku samu satifiket KYAUTA!',
                'promotion_type': 'free_course',
                'icon': '🎓',
                'background_color': '#4CAF50',
                'text_color': '#FFFFFF',
                'cta_text': 'Start Learning',
                'cta_url': '/courses',
                'start_date': today,
                'end_date': today + timedelta(days=60),
                'priority': 90,
                'show_on_home': True,
            },

            # South Africa-specific promotion
            {
                'countries': ['ZA'],
                'title': 'Youth Month Special - 40% Discount',
                'native_title': 'Inyanga Yentsha Okukhethekile - 40% Isaphulelo',
                'description': 'Celebrating Youth Month! South African students get 40% off on all courses.',
                'native_description': 'Sigubha iNyanga Yentsha! Abafundi baseNingizimu Afrika bathola isaphulelo se-40% kuzo zonke izifundo.',
                'promotion_type': 'seasonal',
                'icon': '🎉',
                'background_color': '#2E7D32',
                'text_color': '#FFFFFF',
                'cta_text': 'View Courses',
                'cta_url': '/courses',
                'start_date': today,
                'end_date': today + timedelta(days=30),
                'priority': 85,
                'show_on_splash': True,
            },

            # Ghana-specific promotion
            {
                'countries': ['GH'],
                'title': 'Independence Day Bundle Offer',
                'native_title': 'Faahodie Da Bundle Offer',
                'description': 'Special Independence Day offer! Buy 2 courses, get 1 free. Valid for Ghanaian students only.',
                'native_description': 'Faahodie Da ofa titiriw! Tɔ kozi 2, nya 1 kwa. Ɛyɛ den ama Ghana asuafo nko ara.',
                'promotion_type': 'bundle',
                'icon': '🇬🇭',
                'background_color': '#FFC107',
                'text_color': '#000000',
                'cta_text': 'Get Offer',
                'cta_url': '/promotions/independence',
                'start_date': today,
                'end_date': today + timedelta(days=14),
                'priority': 80,
                'show_on_onboarding': True,
            },

            # Multi-country promotion (East Africa)
            {
                'countries': ['KE', 'TZ', 'UG', 'RW'],
                'title': 'East Africa Tech Week - Special Rates',
                'native_title': 'Wiki ya Teknolojia Afrika Mashariki - Bei Maalum',
                'description': 'Join us for East Africa Tech Week! Special discounted rates for students in Kenya, Tanzania, Uganda, and Rwanda.',
                'native_description': 'Jiunge nasi katika Wiki ya Teknolojia ya Afrika Mashariki! Bei za punguzo maalum kwa wanafunzi nchini Kenya, Tanzania, Uganda na Rwanda.',
                'promotion_type': 'limited_time',
                'icon': '🚀',
                'background_color': '#3F51B5',
                'text_color': '#FFFFFF',
                'cta_text': 'Register',
                'cta_url': '/events/tech-week',
                'start_date': today,
                'end_date': today + timedelta(days=7),
                'priority': 95,
                'show_on_home': True,
            },
        ]

        for promo_data in promotions:
            country_codes = promo_data.pop('countries')
            countries = Country.objects.filter(code__in=country_codes)

            promotion = LocalizedPromotion.objects.create(**promo_data)
            promotion.countries.set(countries)

            countries_str = ', '.join(country_codes)
            self.stdout.write(f'  [OK] Created promotion: {promo_data["title"]} ({countries_str})')

    @transaction.atomic
    def populate_announcements(self):
        """Create sample announcements"""
        self.stdout.write('\nCreating announcements...')

        today = date.today()

        announcements = [
            # Kenya-specific announcement
            {
                'countries': ['KE'],
                'title': 'New Swahili Courses Now Available!',
                'native_title': 'Kozi Mpya za Kiswahili Zinapatikana Sasa!',
                'message': 'We are excited to announce the launch of new courses taught entirely in Swahili! Start learning in your native language today.',
                'native_message': 'Tunafurahi kutangaza uzinduzi wa kozi mpya zinazofundishwa kabisa kwa Kiswahili! Anza kujifunza kwa lugha yako ya asili leo.',
                'announcement_type': 'new_feature',
                'icon': '📢',
                'background_color': '#2196F3',
                'text_color': '#FFFFFF',
                'action_text': 'View Courses',
                'action_url': '/courses/swahili',
                'start_date': today,
                'end_date': today + timedelta(days=30),
                'priority': 100,
                'show_on_onboarding': True,
            },

            # Nigeria-specific announcement
            {
                'countries': ['NG'],
                'title': 'Partnership with Nigerian Universities Announced',
                'native_title': 'An Sanar da Haɗin Gwiwa tare da Jami\'o\'in Najeriya',
                'message': 'Hosi Academy has partnered with leading Nigerian universities to offer accredited certifications. Your learning now counts towards university credit!',
                'native_message': 'Hosi Academy ta yi haɗin gwiwa da manyan jami\'o\'in Najeriya don ba da takaddun shaida masu inganci. Ilimin ku yanzu yana ƙidaya ga lissafin jami\'a!',
                'announcement_type': 'partnership',
                'icon': '🤝',
                'background_color': '#4CAF50',
                'text_color': '#FFFFFF',
                'action_text': 'Learn More',
                'action_url': '/partnerships',
                'start_date': today,
                'end_date': None,  # Indefinite
                'priority': 95,
                'show_on_onboarding': True,
            },

            # Global announcement (all countries)
            {
                'countries': [],  # Empty = all countries
                'title': 'Platform Maintenance Scheduled',
                'native_title': 'Platform Maintenance Scheduled',
                'message': 'We will be performing system maintenance on Sunday, 2:00 AM - 4:00 AM UTC. The platform may be temporarily unavailable during this time.',
                'native_message': 'Tutafanya matengenezo ya mfumo Jumapili, saa 2:00 asubuhi - 4:00 asubuhi UTC. Jukwaa linaweza kupatikana kwa muda mfupi wakati huu.',
                'announcement_type': 'maintenance',
                'icon': '⚠️',
                'background_color': '#FF9800',
                'text_color': '#FFFFFF',
                'action_text': '',
                'action_url': '',
                'start_date': today - timedelta(days=2),
                'end_date': today + timedelta(days=2),
                'priority': 90,
                'show_on_splash': True,
                'show_on_onboarding': True,
                'show_on_home': True,
                'require_acknowledgment': True,
            },

            # South Africa-specific announcement
            {
                'countries': ['ZA'],
                'title': 'Ubuntu Learning Initiative Launched',
                'native_title': 'I-Ubuntu Learning Initiative Iqaliwe',
                'message': 'Join our Ubuntu Learning Initiative - a community-driven learning program for South African students. Learn together, grow together!',
                'native_message': 'Joyina i-Ubuntu Learning Initiative yethu - uhlelo lokufunda oluqhutshwa ngumphakathi lwabafundi baseNingizimu Afrika. Fundani ndawonye, khulani ndawonye!',
                'announcement_type': 'event',
                'icon': '🌍',
                'background_color': '#009688',
                'text_color': '#FFFFFF',
                'action_text': 'Join Now',
                'action_url': '/ubuntu-learning',
                'start_date': today,
                'end_date': today + timedelta(days=90),
                'priority': 85,
                'show_on_onboarding': True,
            },

            # Ghana-specific announcement
            {
                'countries': ['GH'],
                'title': 'New Payment Options Available',
                'native_title': 'Payment Options Fofor Wɔ Hɔ',
                'message': 'You can now pay for courses using Mobile Money (MTN, Vodafone, AirtelTigo). Making education more accessible for Ghanaian students!',
                'native_message': 'Seesei wobetumi atua kozi ho ka denam Mobile Money (MTN, Vodafone, AirtelTigo) so. Yɛreyɛ nwomasua nkɔso ama Ghana asuafo!',
                'announcement_type': 'update',
                'icon': '💳',
                'background_color': '#673AB7',
                'text_color': '#FFFFFF',
                'action_text': 'See Payment Methods',
                'action_url': '/payment-methods',
                'start_date': today,
                'end_date': today + timedelta(days=60),
                'priority': 80,
                'show_on_home': True,
            },

            # Multi-country announcement (East Africa)
            {
                'countries': ['KE', 'TZ', 'UG'],
                'title': 'East Africa Career Fair - Virtual Event',
                'native_title': 'Maonyesho ya Kazi Afrika Mashariki - Tukio la Mtandaoni',
                'message': 'Join our virtual career fair connecting students with top employers in Kenya, Tanzania, and Uganda. Free for all students!',
                'native_message': 'Jiunge na maonyesho yetu ya kazi ya mtandaoni inayounganisha wanafunzi na waajiri wakuu nchini Kenya, Tanzania na Uganda. Bure kwa wanafunzi wote!',
                'announcement_type': 'event',
                'icon': '💼',
                'background_color': '#E91E63',
                'text_color': '#FFFFFF',
                'action_text': 'Register',
                'action_url': '/events/career-fair',
                'start_date': today,
                'end_date': today + timedelta(days=21),
                'priority': 88,
                'show_on_onboarding': True,
                'show_on_home': True,
            },
        ]

        for announcement_data in announcements:
            country_codes = announcement_data.pop('countries')

            if country_codes:  # Country-specific
                countries = Country.objects.filter(code__in=country_codes)
                announcement = LocalizedAnnouncement.objects.create(**announcement_data)
                announcement.countries.set(countries)
                countries_str = ', '.join(country_codes)
            else:  # Global
                announcement = LocalizedAnnouncement.objects.create(**announcement_data)
                countries_str = 'All countries'

            self.stdout.write(f'  [OK] Created announcement: {announcement_data["title"]} ({countries_str})')
