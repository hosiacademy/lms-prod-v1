"""
Management command to create $5 USD Industry Courses (Custom Selection).
These are individual courses available for custom selection in Industry Based Training.
Standalone promotional offering at $5 USD.

Usage:
    python manage.py create_five_dollar_industry_courses
"""
from django.core.management.base import BaseCommand
from django.utils.text import slugify
import datetime

from apps.industry_based_training.models import Industry, AiCertsCourse
from apps.users.models import User


class Command(BaseCommand):
    help = "Create $5 USD Industry Courses (Custom Selection)"

    def handle(self, *args, **kwargs):
        self.stdout.write("Creating $5 USD Industry Courses (Custom Selection)...")

        # Get or create industry for the courses
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

        # Create PRODUCTION $5 Industry Course
        prod_title = 'AI+ Digital Literacy - $5 Custom Selection'
        prod_course_id = 'AI-DIGITAL-LITERACY-5USD'

        if not AiCertsCourse.objects.filter(course_id=prod_course_id).exists():
            prod_course = AiCertsCourse(
                title=prod_title,
                course_id=prod_course_id,
                description='Join HOSI Academy transformative AI+ Digital Literacy course! '
                           'This comprehensive program introduces AI fundamentals and digital literacy, '
                           'perfect for beginners looking to understand AI basics and leverage AI tools '
                           'in their personal and professional lives. Learn from industry experts, gain '
                           'hands-on experience, and join a growing community of AI-literate professionals '
                           'across Africa. This special $5 course is part of HOSI Academy mission to make '
                           'AI education accessible to all Africans.',
                categories='AI, Digital Literacy, Custom Selection',
                certificate_badge_url='',
                feature_image_url='',
                lms_id=None,  # Can be synced later
                price_usd=5.00,  # $5 USD
                industry=industry,
            )
            prod_course.save()
            self.stdout.write(self.style.SUCCESS(
                f"✓ Created PRODUCTION Industry Course: {prod_course.title}"
            ))
            self.stdout.write(self.style.SUCCESS(
                f"  - Price: ${prod_course.price_usd} USD"
            ))
            self.stdout.write(self.style.SUCCESS(
                f"  - Industry: {prod_course.industry.name}"
            ))
        else:
            self.stdout.write(self.style.WARNING(
                f"PRODUCTION Industry Course already exists, skipping..."
            ))

        self.stdout.write(self.style.SUCCESS(
            f"\n✅ Successfully created $5 Industry Courses (Custom Selection)!"
        ))
        self.stdout.write(self.style.SUCCESS(
            "💡 These courses are available for individual enrollment (Custom Selection)."
        ))
        self.stdout.write(self.style.SUCCESS(
            "💡 Cost: $5 USD per course."
        ))
