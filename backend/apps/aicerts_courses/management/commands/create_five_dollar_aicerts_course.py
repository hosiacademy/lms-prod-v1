"""
Management command to create $5 USD AICERTS Promotional Course.
This is a STANDALONE promotional course at $5 USD.
Distinct from other AICERTS courses (which cost $250-$420).

Usage:
    python manage.py create_five_dollar_aicerts_course
"""
from django.core.management.base import BaseCommand
from apps.aicerts_courses.models import AiCertsCourse
from apps.industry_based_training.models import Industry


class Command(BaseCommand):
    help = "Create $5 USD AICERTS Promotional Course"

    def handle(self, *args, **kwargs):
        self.stdout.write("Creating $5 USD AICERTS Promotional Course...")

        # Get or create industry for the course
        industry, _ = Industry.objects.get_or_create(
            name='AI & Digital Literacy',
            defaults={'description': 'AI and Digital Literacy courses for all Africans'}
        )

        # Create PRODUCTION $5 AICERTS Course
        course_title = 'AI+ Digital Literacy - $5 Promotional Course'
        external_id = 99999  # Special ID for promotional course

        if not AiCertsCourse.objects.filter(external_id=external_id).exists():
            course = AiCertsCourse(
                title=course_title,
                external_id=external_id,
                shortname='AI+ Digital Literacy $5',
                description='<p>Join HOSI Academy transformative AI+ Digital Literacy course! '
                           'This comprehensive program introduces AI fundamentals and digital literacy, '
                           'perfect for beginners looking to understand AI basics and leverage AI tools '
                           'in their personal and professional lives. Learn from industry experts, gain '
                           'hands-on experience, and join a growing community of AI-literate professionals '
                           'across Africa. This special $5 promotional course is part of HOSI Academy mission '
                           'to make AI education accessible to all Africans. STANDALONE promotional offering.</p>',
                summary='Special $5 promotional AI+ Digital Literacy course - standalone offering.',
                category_name='AI, Digital Literacy, Promotional, AICERTS',
                certificate_badge_url='',
                feature_image_url='',
                price_package=5.00,  # $5 USD - PROMOTIONAL PRICE
                price_individual=5.00,  # $5 USD
                is_offered=True,
            )
            course.save()
            self.stdout.write(self.style.SUCCESS(
                f"✓ Created $5 AICERTS Promotional Course: {course.title}"
            ))
            self.stdout.write(self.style.SUCCESS(
                f"  - Price: ${course.price_package} USD"
            ))
            self.stdout.write(self.style.SUCCESS(
                f"  - External ID: {course.external_id}"
            ))
        else:
            self.stdout.write(self.style.WARNING(
                f"$5 AICERTS Promotional Course already exists, skipping..."
            ))

        self.stdout.write(self.style.SUCCESS(
            f"\n✅ Successfully created $5 AICERTS Promotional Course!"
        ))
        self.stdout.write(self.style.SUCCESS(
            "💡 This is a STANDALONE promotional course."
        ))
        self.stdout.write(self.style.SUCCESS(
            "💡 Cost: $5 USD (distinct from regular AICERTS courses at $250-$420)."
        ))
