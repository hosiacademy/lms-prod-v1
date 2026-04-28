"""
Management command to create $5 USD Industry Training Offerings.
These are bundled course offerings (Role Training) in Industry Based Training.
Standalone promotional offering at $5 USD.

Usage:
    python manage.py create_five_dollar_industry_offerings
"""
from django.core.management.base import BaseCommand
import datetime

from apps.industry_based_training.models import Industry, AiCertsCourse, Offering
from apps.users.models import User


class Command(BaseCommand):
    help = "Create $5 USD Industry Training Offerings"

    def handle(self, *args, **kwargs):
        self.stdout.write("Creating $5 USD Industry Training Offerings...")

        # Get or create industry for the offerings
        industry, _ = Industry.objects.get_or_create(
            name='AI & Digital Literacy',
            defaults={'description': 'AI and Digital Literacy courses for all Africans'}
        )

        # Find Takawira as instructor (for reference)
        instructor = User.objects.filter(first_name__icontains='takawira').first()
        if not instructor:
            instructor = User.objects.filter(email__icontains='takawira').first()

        if instructor:
            self.stdout.write(f"Using instructor: {instructor.email}")

        # Get the $5 industry course
        prod_course = AiCertsCourse.objects.filter(course_id='AI-DIGITAL-LITERACY-5USD').first()

        # Create PRODUCTION $5 Industry Training Offering
        prod_offering_name = 'AI+ Digital Literacy Industry Training - $5'

        if not Offering.objects.filter(name=prod_offering_name).exists():
            prod_offering = Offering(
                name=prod_offering_name,
                description='Join HOSI Academy transformative AI+ Digital Literacy Industry Training! '
                           'This comprehensive bundle introduces AI fundamentals and digital literacy, '
                           'perfect for organizations or individuals looking to upskill. Learn from industry '
                           'experts, gain hands-on experience, and join a growing community of AI-literate '
                           'professionals across Africa. This special $5 offering is part of HOSI Academy '
                           'mission to make AI education accessible to all Africans.',
                industry=industry,
                price_usd=5.00,  # $5 USD
            )
            prod_offering.save()

            # Add the production course to the offering
            if prod_course:
                prod_offering.courses.add(prod_course)

            self.stdout.write(self.style.SUCCESS(
                f"✓ Created PRODUCTION Industry Training Offering: {prod_offering.name}"
            ))
            self.stdout.write(self.style.SUCCESS(
                f"  - Price: ${prod_offering.price_usd} USD"
            ))
            self.stdout.write(self.style.SUCCESS(
                f"  - Industry: {prod_offering.industry.name}"
            ))
            self.stdout.write(self.style.SUCCESS(
                f"  - Courses in Bundle: {prod_offering.courses.count()}"
            ))
        else:
            self.stdout.write(self.style.WARNING(
                f"PRODUCTION Industry Training Offering already exists, skipping..."
            ))

        self.stdout.write(self.style.SUCCESS(
            f"\n✅ Successfully created $5 Industry Training Offerings!"
        ))
        self.stdout.write(self.style.SUCCESS(
            "💡 These are bundled course offerings (Role Training)."
        ))
        self.stdout.write(self.style.SUCCESS(
            "💡 Cost: $5 USD per offering bundle."
        ))
