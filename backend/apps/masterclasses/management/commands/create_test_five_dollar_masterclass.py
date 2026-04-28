"""
Management command to create a TEST $5 USD masterclass across South Africa, Zimbabwe, Zambia, and Kenya.
This is a TEST masterclass for testing purposes but functions exactly like production masterclasses.

Usage:
    python manage.py create_test_five_dollar_masterclass
"""
from django.core.management.base import BaseCommand
from django.utils.text import slugify
import datetime

from apps.masterclasses.models import Masterclass
from apps.users.models import User


class Command(BaseCommand):
    help = "Create a TEST $5 USD masterclass held in South Africa, Zimbabwe, Zambia, and Kenya"

    def handle(self, *args, **kwargs):
        self.stdout.write("Creating TEST $5 USD Masterclass...")

        # Find Takawira as instructor
        instructor = User.objects.filter(first_name__icontains='takawira').first()
        if not instructor:
            instructor = User.objects.filter(email__icontains='takawira').first()

        if not instructor:
            self.stdout.write(self.style.WARNING("Takawira not found, creating masterclass without instructor"))
        else:
            self.stdout.write(f"Using instructor: {instructor.email}")

        # Create 4 masterclass sessions for the $5 TEST offering - one per country
        # Same price for both online and physical attendance ($5)
        masterclass_data = [
            # South Africa - Johannesburg
            {
                'title': 'TEST - AI+ Digital Literacy - $5 Masterclass',
                'country_name': 'South Africa',
                'country_code': 'ZA',
                'city': 'Johannesburg',
                'venue': 'Montecasino Boulevard, Fourways, Johannesburg, South Africa',
                'start_date': '2026-05-15',
                'end_date': '2026-05-15',
            },
            # Zimbabwe - Harare
            {
                'title': 'TEST - AI+ Digital Literacy - $5 Masterclass',
                'country_name': 'Zimbabwe',
                'country_code': 'ZW',
                'city': 'Harare',
                'venue': 'HOSI Academy Campus, Harare, Zimbabwe',
                'start_date': '2026-05-22',
                'end_date': '2026-05-22',
            },
            # Zambia - Lusaka
            {
                'title': 'TEST - AI+ Digital Literacy - $5 Masterclass',
                'country_name': 'Zambia',
                'country_code': 'ZM',
                'city': 'Lusaka',
                'venue': 'Lusaka Conference Center, Lusaka, Zambia',
                'start_date': '2026-05-29',
                'end_date': '2026-05-29',
            },
            # Kenya - Nairobi
            {
                'title': 'TEST - AI+ Digital Literacy - $5 Masterclass',
                'country_name': 'Kenya',
                'country_code': 'KE',
                'city': 'Nairobi',
                'venue': 'Nairobi Innovation Hub, Nairobi, Kenya',
                'start_date': '2026-06-05',
                'end_date': '2026-06-05',
            },
        ]

        created_count = 0
        for mc_data in masterclass_data:
            slug = slugify(f"{mc_data['title']} - {mc_data['city']} - {mc_data['start_date']}")

            # Check if already exists
            if Masterclass.objects.filter(slug=slug).exists():
                self.stdout.write(self.style.WARNING(
                    f"TEST Masterclass already exists for {mc_data['city']}, skipping..."
                ))
                continue

            masterclass = Masterclass(
                title=mc_data['title'],
                slug=slug,
                description='TEST MASTERCLASS - This is a test masterclass for testing purposes. '
                           'It introduces AI fundamentals and digital literacy. Perfect for beginners looking to '
                           'understand AI basics and how to leverage AI tools in their personal and professional lives. '
                           'This $5 masterclass has the SAME PRICE for both online and physical attendance. '
                           'Part of HOSI Academy mission to make AI education accessible across Africa.',
                category='AI & Digital Literacy',
                stream_type='professional',
                tier='basic',
                focus_area='AI Fundamentals & Digital Literacy',
                country_code=mc_data['country_code'],
                country_name=mc_data['country_name'],
                city=mc_data['city'],
                venue=mc_data['venue'],
                start_date=datetime.datetime.strptime(mc_data['start_date'], '%Y-%m-%d').date(),
                end_date=datetime.datetime.strptime(mc_data['end_date'], '%Y-%m-%d').date(),
                price_physical=5.00,  # $5 USD - SAME as online
                price_online=5.00,    # $5 USD - SAME as physical
                currency='USD',
                status='scheduled',
                is_featured=True,
                has_online_option=True,
                max_participants=100,
                current_participants=0,
                instructor=instructor,
                notes='TEST $5 promotional masterclass - South Africa, Zimbabwe, Zambia, Kenya tour. '
                      'Same price for online and physical attendance.',
            )
            masterclass.save()

            created_count += 1
            self.stdout.write(self.style.SUCCESS(
                f"Created TEST $5 Masterclass: {mc_data['city']}, {mc_data['country_name']} "
                f"({mc_data['start_date']})"
            ))

        self.stdout.write(self.style.SUCCESS(
            f"\nSuccessfully created {created_count} TEST masterclass session(s) at $5 USD each!"
        ))
        self.stdout.write(self.style.SUCCESS(
            'Locations: Johannesburg (South Africa), Harare (Zimbabwe), Lusaka (Zambia), Nairobi (Kenya)'
        ))
        self.stdout.write(self.style.SUCCESS(
            'Both online and physical attendance cost $5 USD each.'
        ))
