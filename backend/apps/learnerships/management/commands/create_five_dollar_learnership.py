"""
Management command to create $5 USD Learnership Promotional Offering.
This is a STANDALONE promotional learnership with $5 enrollment fee.
Distinct from other learnerships (which cost $2,000-$15,000+).

The $5 is the enrollment fee, with the balance on a monthly payment plan.

Usage:
    python manage.py create_five_dollar_learnership
"""
from django.core.management.base import BaseCommand
from django.utils.text import slugify
import datetime
from decimal import Decimal

from apps.learnerships.models import LearnershipProgramme, LearnershipPhase
from apps.users.models import User


class Command(BaseCommand):
    help = "Create $5 USD Learnership Promotional Offering"

    def handle(self, *args, **kwargs):
        self.stdout.write("Creating $5 USD Learnership Promotional Offering...")

        # Find an instructor
        instructor = User.objects.filter(first_name__icontains='takawira').first()
        if not instructor:
            instructor = User.objects.filter(email__icontains='takawira').first()

        if instructor:
            self.stdout.write(f"Using instructor: {instructor.email}")

        # Create PRODUCTION $5 Learnership Programme
        programme_title = 'AI+ Digital Literacy - $5 Promotional Learnership'
        programme_slug = slugify(programme_title)

        if not LearnershipProgramme.objects.filter(slug=programme_slug).exists():
            programme = LearnershipProgramme(
                title=programme_title,
                slug=programme_slug,
                specialization='AI & Digital Literacy',
                description='Join HOSI Academy transformative AI+ Digital Literacy Learnership! '
                           'This comprehensive 12-month work-based learning programme introduces AI '
                           'fundamentals and digital literacy, perfect for beginners looking to start '
                           'their AI career. Learn from industry experts, gain hands-on experience, '
                           'and join a growing community of AI-literate professionals across Africa. '
                           'This special $5 promotional learnership is part of HOSI Academy mission '
                           'to make AI education accessible to all Africans. STANDALONE promotional offering.',
                duration_months=12,
                cost_usd=5.00,  # $5 USD enrollment fee - PROMOTIONAL
                category='Technical AI',  # Changed to match frontend category filter
                status='open',
                is_featured=True,
                is_offered=True,
                max_participants=100,
                current_participants=0,
                instructor=instructor,
                country='South Africa',
                city='Johannesburg',
                delivery_mode='hybrid',
                start_date=datetime.date(2026, 6, 1),
                end_date=datetime.date(2027, 5, 31),
                enrollment_deadline=datetime.date(2026, 5, 25),
            )
            programme.save()
            self.stdout.write(self.style.SUCCESS(
                f"✓ Created $5 Learnership Programme: {programme.title}"
            ))
            self.stdout.write(self.style.SUCCESS(
                f"  - Enrollment Fee: ${programme.cost_usd} USD"
            ))
            self.stdout.write(self.style.SUCCESS(
                f"  - Duration: {programme.duration_months} months"
            ))
            self.stdout.write(self.style.SUCCESS(
                f"  - Specialization: {programme.specialization}"
            ))

            # Create a phase for the learnership
            phase = LearnershipPhase.objects.create(
                programme=programme,
                name='Foundation Phase',
                order=1,
                start_date=datetime.date(2026, 6, 1),
                end_date=datetime.date(2026, 9, 30),
                duration_weeks=17,
                description='Introduction to AI fundamentals and digital literacy basics',
            )
            self.stdout.write(self.style.SUCCESS(
                f"  - Created Phase 1: {phase.name}"
            ))

        else:
            self.stdout.write(self.style.WARNING(
                f"$5 Learnership Programme already exists, skipping..."
            ))

        self.stdout.write(self.style.SUCCESS(
            f"\n✅ Successfully created $5 Learnership Promotional Offering!"
        ))
        self.stdout.write(self.style.SUCCESS(
            "💡 This is a STANDALONE promotional learnership."
        ))
        self.stdout.write(self.style.SUCCESS(
            "💡 Enrollment Fee: $5 USD, then monthly payments."
        ))
        self.stdout.write(self.style.SUCCESS(
            "💡 Distinct from regular learnerships ($2,000-$15,000+)."
        ))
