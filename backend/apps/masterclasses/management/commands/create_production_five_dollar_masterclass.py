"""
Management command to create the PRODUCTION $5 USD masterclass across South Africa, Zimbabwe, Zambia, and Kenya.
This is the ACTUAL production masterclass with real go-live details.
Same price ($5) for both online and physical attendance.

Usage:
    python manage.py create_production_five_dollar_masterclass
"""
from django.core.management.base import BaseCommand
from django.utils.text import slugify
import datetime

from apps.masterclasses.models import Masterclass
from apps.users.models import User


class Command(BaseCommand):
    help = "Create the PRODUCTION $5 USD masterclass held in South Africa, Zimbabwe, Zambia, and Kenya"

    def handle(self, *args, **kwargs):
        self.stdout.write("Creating PRODUCTION $5 USD Masterclass...")

        # Find Takawira as instructor
        instructor = User.objects.filter(first_name__icontains='takawira').first()
        if not instructor:
            instructor = User.objects.filter(email__icontains='takawira').first()

        if not instructor:
            self.stdout.write(self.style.WARNING("Takawira not found, creating masterclass without instructor"))
        else:
            self.stdout.write(f"Using instructor: {instructor.email}")

        # Create 4 masterclass sessions for the $5 PRODUCTION offering - one per country
        # Same price for both online and physical attendance ($5)
        # Actual go-live dates starting June 2026
        masterclass_data = [
            # South Africa - Johannesburg
            {
                'title': 'AI+ Digital Literacy - $5 Masterclass',
                'country_name': 'South Africa',
                'country_code': 'ZA',
                'city': 'Johannesburg',
                'venue': 'Montecasino Boulevard, Fourways, Johannesburg, South Africa',
                'start_date': '2026-06-15',
                'end_date': '2026-06-15',
            },
            # Zimbabwe - Harare
            {
                'title': 'AI+ Digital Literacy - $5 Masterclass',
                'country_name': 'Zimbabwe',
                'country_code': 'ZW',
                'city': 'Harare',
                'venue': 'HOSI Academy Campus, Harare, Zimbabwe',
                'start_date': '2026-06-22',
                'end_date': '2026-06-22',
            },
            # Zambia - Lusaka
            {
                'title': 'AI+ Digital Literacy - $5 Masterclass',
                'country_name': 'Zambia',
                'country_code': 'ZM',
                'city': 'Lusaka',
                'venue': 'Lusaka Conference Center, Lusaka, Zambia',
                'start_date': '2026-06-29',
                'end_date': '2026-06-29',
            },
            # Kenya - Nairobi
            {
                'title': 'AI+ Digital Literacy - $5 Masterclass',
                'country_name': 'Kenya',
                'country_code': 'KE',
                'city': 'Nairobi',
                'venue': 'Nairobi Innovation Hub, Nairobi, Kenya',
                'start_date': '2026-07-06',
                'end_date': '2026-07-06',
            },
        ]

        created_count = 0
        for mc_data in masterclass_data:
            slug = slugify(f"{mc_data['title']} - {mc_data['city']} - {mc_data['start_date']}")

            # Check if already exists
            if Masterclass.objects.filter(slug=slug).exists():
                self.stdout.write(self.style.WARNING(
                    f"Production Masterclass already exists for {mc_data['city']}, skipping..."
                ))
                continue

            masterclass = Masterclass(
                title=mc_data['title'],
                slug=slug,
                description='Join HOSI Academy transformative AI+ Digital Literacy Masterclass! '
                           'This comprehensive program introduces AI fundamentals and digital literacy, '
                           'perfect for beginners looking to understand AI basics and leverage AI tools '
                           'in their personal and professional lives. Learn from industry experts, gain '
                           'hands-on experience, and join a growing community of AI-literate professionals '
                           'across Africa. This special $5 masterclass is part of HOSI Academy mission '
                           'to make AI education accessible to all Africans. SAME PRICE for both online '
                           'and physical attendance!',
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
                notes='PRODUCTION $5 promotional masterclass - South Africa, Zimbabwe, Zambia, Kenya tour. '
                      'Same price for online and physical attendance. Go-live 2026.',
            )
            masterclass.save()

            created_count += 1
            self.stdout.write(self.style.SUCCESS(
                f"Created PRODUCTION $5 Masterclass: {mc_data['city']}, {mc_data['country_name']} "
                f"({mc_data['start_date']})"
            ))

        self.stdout.write(self.style.SUCCESS(
            f"\nSuccessfully created {created_count} PRODUCTION masterclass session(s) at $5 USD each!"
        ))
        self.stdout.write(self.style.SUCCESS(
            'Locations: Johannesburg (South Africa), Harare (Zimbabwe), Lusaka (Zambia), Nairobi (Kenya)'
        ))
        self.stdout.write(self.style.SUCCESS(
            'Both online and physical attendance cost $5 USD each.'
        ))
