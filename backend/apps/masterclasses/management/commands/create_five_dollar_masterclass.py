"""
Management command to create a special $5 USD masterclass across Kenya, South Africa, and Zimbabwe.

Usage:
    python manage.py create_five_dollar_masterclass
"""
from django.core.management.base import BaseCommand
from django.utils.text import slugify
import datetime

from apps.masterclasses.models import Masterclass
from apps.users.models import User


class Command(BaseCommand):
    help = "Create a special $5 USD masterclass held in Kenya, South Africa, and Harare"

    def handle(self, *args, **kwargs):
        self.stdout.write("Creating $5 USD Masterclass...")

        # Find Takawira as instructor
        instructor = User.objects.filter(first_name__icontains='takawira').first()
        if not instructor:
            instructor = User.objects.filter(email__icontains='takawira').first()
        
        if not instructor:
            self.stdout.write(self.style.WARNING("Takawira not found, creating masterclass without instructor"))
        else:
            self.stdout.write(f"Using instructor: {instructor.email}")

        # Create 3 masterclass sessions for the $5 offering
        masterclass_data = [
            # Kenya - Nairobi
            {
                'title': "AI+ Digital Literacy™ - Special $5 Masterclass",
                'country_name': "Kenya",
                'country_code': "KE",
                'city': "Nairobi",
                'venue': "Nairobi Innovation Hub, Nairobi, Kenya",
                'start_date': "2026-04-15",
                'end_date': "2026-04-15",
            },
            # South Africa - Johannesburg
            {
                'title': "AI+ Digital Literacy™ - Special $5 Masterclass",
                'country_name': "South Africa",
                'country_code': "ZA",
                'city': "Johannesburg",
                'venue': "Montecasino Boulevard, Fourways, Johannesburg, South Africa",
                'start_date': "2026-04-22",
                'end_date': "2026-04-22",
            },
            # Zimbabwe - Harare
            {
                'title': "AI+ Digital Literacy™ - Special $5 Masterclass",
                'country_name': "Zimbabwe",
                'country_code': "ZW",
                'city': "Harare",
                'venue': "Hosi Academy Campus, Harare, Zimbabwe",
                'start_date': "2026-04-29",
                'end_date': "2026-04-29",
            },
        ]

        created_count = 0
        for mc_data in masterclass_data:
            slug = slugify(f"{mc_data['title']} - {mc_data['city']} - {mc_data['start_date']}")
            
            # Check if already exists
            if Masterclass.objects.filter(slug=slug).exists():
                self.stdout.write(self.style.WARNING(
                    f"Masterclass already exists for {mc_data['city']}, skipping..."
                ))
                continue

            masterclass = Masterclass(
                title=mc_data['title'],
                slug=slug,
                description="Special promotional masterclass introducing AI fundamentals and digital literacy. "
                           "Perfect for beginners looking to understand AI basics and how to leverage AI tools "
                           "in their personal and professional lives. This special $5 masterclass is part of "
                           "HOSI Academy's mission to make AI education accessible across Africa.",
                category="AI & Digital Literacy",
                stream_type="professional",
                tier="basic",
                focus_area="AI Fundamentals & Digital Literacy",
                country_code=mc_data['country_code'],
                country_name=mc_data['country_name'],
                city=mc_data['city'],
                venue=mc_data['venue'],
                start_date=datetime.datetime.strptime(mc_data['start_date'], "%Y-%m-%d").date(),
                end_date=datetime.datetime.strptime(mc_data['end_date'], "%Y-%m-%d").date(),
                price_physical=5.00,  # $5 USD
                price_online=5.00,    # $5 USD for online as well
                currency="USD",
                status="scheduled",
                is_featured=True,
                has_online_option=True,
                max_participants=100,
                current_participants=0,
                instructor=instructor,
                notes="Special $5 promotional masterclass - Kenya, South Africa, Zimbabwe tour",
            )
            masterclass.save()

            created_count += 1
            self.stdout.write(self.style.SUCCESS(
                f"✓ Created $5 Masterclass: {mc_data['city']}, {mc_data['country_name']} "
                f"({mc_data['start_date']})"
            ))

        self.stdout.write(self.style.SUCCESS(
            f"\n✅ Successfully created {created_count} masterclass session(s) at $5 USD each!"
        ))
        self.stdout.write(self.style.SUCCESS(
            "Locations: Nairobi (Kenya), Johannesburg (South Africa), Harare (Zimbabwe)"
        ))
