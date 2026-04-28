"""
Management command to create a TEST $5 USD Learnership Programme.
This is a TEST learnership for testing purposes but functions exactly like production learnerships.
Marked as featured (RED card emphasis) for easy identification.

Usage:
    python manage.py create_test_five_dollar_learnership
"""
from django.core.management.base import BaseCommand
from django.utils.text import slugify
import datetime

from apps.learnerships.models import LearnershipProgramme, LearnershipPhase, PhaseCourse, Course, CourseProvider
from apps.users.models import User


class Command(BaseCommand):
    help = "Create a TEST $5 USD Learnership Programme"

    def handle(self, *args, **kwargs):
        self.stdout.write("Creating TEST $5 USD Learnership Programme...")

        # Find Takawira as instructor
        instructor = User.objects.filter(first_name__icontains='takawira').first()
        if not instructor:
            instructor = User.objects.filter(email__icontains='takawira').first()

        if not instructor:
            self.stdout.write(self.style.WARNING("Takawira not found, creating learnership without instructor"))
        else:
            self.stdout.write(f"Using instructor: {instructor.email}")

        # Get or create a generic course provider for the learnership
        provider, _ = CourseProvider.objects.get_or_create(
            name='HOSI Academy',
            defaults={'active': True}
        )

        # Create the $5 TEST Learnership Programme
        title = 'TEST - AI+ Digital Literacy Learnership - $5'
        slug = slugify(title)

        # Check if already exists
        if LearnershipProgramme.objects.filter(slug=slug).exists():
            self.stdout.write(self.style.WARNING(
                f"TEST Learnership already exists with slug {slug}, skipping..."
            ))
            return

        # Create learnership programme
        learnership = LearnershipProgramme(
            title=title,
            slug=slug,
            role='AI Digital Literacy Specialist',
            specialization='AI & Digital Literacy',
            nqf_level='Level 5',
            duration_months=3,
            duration_weeks=12,
            description='TEST LEARNERSHIP - This is a test learnership for testing enrollment flows. '
                       'Comprehensive program introducing AI fundamentals and digital literacy. '
                       'Perfect for beginners looking to understand AI basics and leverage AI tools '
                       'in their personal and professional lives. This special $5 learnership is part '
                       'of HOSI Academy mission to make AI education accessible across Africa.',
            focus='AI Fundamentals, Digital Tools, Prompt Engineering, AI Ethics, Practical AI Applications',
            prerequisites='Basic computer literacy. No prior AI experience required.',
            entry_requirements='Grade 12 certificate or equivalent. Basic English proficiency.',
            career_outcomes='Digital Literacy Specialist, AI Assistant, Prompt Engineer, AI Content Creator',
            target_audience='Students, professionals, entrepreneurs, anyone interested in AI',
            category='Technical AI',  # Changed to match frontend category filter
            status='open',
            max_participants=100,
            current_participants=0,
            enrollment_deadline=datetime.date(2026, 12, 31),
            start_date=datetime.date(2026, 5, 1),
            end_date=datetime.date(2026, 7, 31),
            provider='HOSI Academy',
            accreditation_body='HOSI Academy',
            certificate='HOSI Academy AI+ Digital Literacy Certificate',
            delivery_mode='hybrid',
            location='Multiple Locations',
            country='South Africa',
            city='Johannesburg',
            stipend_amount=None,
            currency='USD',
            is_funded=False,
            is_featured=True,  # RED CARD EMPHASIS
            active=True,
            is_offered=True,  # Available for enrollment
            cost_usd=5.00,    # $5 USD - SAME for all modes
            intake_frequency='Quarterly',
            instructor=instructor,
            skills=[
                'AI Fundamentals',
                'Digital Literacy',
                'Prompt Engineering',
                'AI Tools Usage',
                'AI Ethics',
                'Content Creation with AI'
            ],
            modules=[
                {
                    'name': 'Module 1: Introduction to AI',
                    'topics': ['What is AI', 'AI History', 'AI Applications'],
                    'duration_weeks': 2
                },
                {
                    'name': 'Module 2: Digital Literacy Basics',
                    'topics': ['Computer Basics', 'Internet Safety', 'Digital Communication'],
                    'duration_weeks': 3
                },
                {
                    'name': 'Module 3: Prompt Engineering',
                    'topics': ['Writing Prompts', 'AI Tools', 'Best Practices'],
                    'duration_weeks': 3
                },
                {
                    'name': 'Module 4: Practical AI Applications',
                    'topics': ['AI in Work', 'AI in Daily Life', 'AI Projects'],
                    'duration_weeks': 4
                }
            ],
        )
        learnership.save()

        self.stdout.write(self.style.SUCCESS(
            f"✓ Created TEST Learnership: {learnership.title}"
        ))
        self.stdout.write(self.style.SUCCESS(
            f"  - Cost: ${learnership.cost_usd} USD"
        ))
        self.stdout.write(self.style.SUCCESS(
            f"  - Duration: {learnership.duration_weeks} weeks"
        ))
        self.stdout.write(self.style.SUCCESS(
            f"  - Featured: {learnership.is_featured} (RED CARD)"
        ))
        self.stdout.write(self.style.SUCCESS(
            f"  - Active & Offered: {learnership.active} / {learnership.is_offered}"
        ))

        # Create phases for the learnership
        self.stdout.write("\nCreating Learnership Phases...")
        
        phases_data = [
            {
                'name': 'Phase 1: Foundation',
                'order': 1,
                'start_date': '2026-05-01',
                'end_date': '2026-05-31',
                'duration_weeks': 4,
                'description': 'Introduction to AI and Digital Literacy fundamentals'
            },
            {
                'name': 'Phase 2: Intermediate',
                'order': 2,
                'start_date': '2026-06-01',
                'end_date': '2026-06-30',
                'duration_weeks': 4,
                'description': 'Prompt Engineering and AI Tools'
            },
            {
                'name': 'Phase 3: Advanced',
                'order': 3,
                'start_date': '2026-07-01',
                'end_date': '2026-07-31',
                'duration_weeks': 4,
                'description': 'Practical AI Applications and Projects'
            }
        ]

        for phase_data in phases_data:
            phase = LearnershipPhase(
                programme=learnership,
                name=phase_data['name'],
                order=phase_data['order'],
                start_date=datetime.datetime.strptime(phase_data['start_date'], '%Y-%m-%d').date(),
                end_date=datetime.datetime.strptime(phase_data['end_date'], '%Y-%m-%d').date(),
                duration_weeks=phase_data['duration_weeks'],
                description=phase_data['description']
            )
            phase.save()
            self.stdout.write(self.style.SUCCESS(f"  ✓ Created {phase.name}"))

        self.stdout.write(self.style.SUCCESS(
            f"\n✅ Successfully created TEST $5 Learnership Programme!"
        ))
        self.stdout.write(self.style.SUCCESS(
            "💡 This learnership is marked as featured (RED CARD) for emphasis."
        ))
        self.stdout.write(self.style.SUCCESS(
            "💡 Cost: $5 USD for all delivery modes (online, hybrid, in-person)."
        ))
