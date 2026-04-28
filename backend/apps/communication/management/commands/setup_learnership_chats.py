"""
Setup Chat Rooms for Existing Learnership Enrollments
======================================================
Creates chat rooms for all existing learnership enrollments.
Useful for backfilling chat rooms after adding the auto-enrollment signal.

Usage:
    python manage.py setup_learnership_chats [--instructor-email EMAIL]
"""
from django.core.management.base import BaseCommand
from django.db import transaction
from apps.learnerships.models import LearnershipEnrollment
from apps.communication.services import ChatEnforcerService
from apps.users.models import User


class Command(BaseCommand):
    help = 'Setup chat rooms for existing learnership enrollments'

    def add_arguments(self, parser):
        parser.add_argument(
            '--instructor-email',
            type=str,
            help='Filter enrollments by instructor email (optional)',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be created without actually creating',
        )

    @transaction.atomic
    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('\n' + '='*70))
        self.stdout.write(self.style.SUCCESS('LEARNERSHIP CHAT ROOMS SETUP'))
        self.stdout.write(self.style.SUCCESS('='*70 + '\n'))

        instructor_email = options.get('instructor_email')
        dry_run = options.get('dry_run')

        # Get all active learnership enrollments
        enrollments = LearnershipEnrollment.objects.filter(active=True).select_related(
            'user', 'programme'
        )

        # Filter by instructor if specified
        if instructor_email:
            try:
                instructor = User.objects.get(email=instructor_email, role_id=2)
                self.stdout.write(f'Filtering by instructor: {instructor.name}\n')
                
                # Filter enrollments that have this instructor
                from apps.payments.models import Order
                instructor_enrollments = []
                for e in enrollments:
                    order = Order.objects.filter(
                        user=e.user,
                        metadata__programme_id=e.programme.id,
                        metadata__instructor_id=instructor.id
                    ).first()
                    if order:
                        instructor_enrollments.append(e)
                
                enrollments = instructor_enrollments
                self.stdout.write(self.style.SUCCESS(f'Found {len(enrollments)} enrollments for {instructor.name}\n'))
            except User.DoesNotExist:
                self.stdout.write(self.style.ERROR(f'Instructor not found: {instructor_email}'))
                return

        if not enrollments:
            self.stdout.write(self.style.WARNING('No enrollments found to process'))
            return

        enrollments_count = len(enrollments)
        self.stdout.write(f'Processing {enrollments_count} enrollments...\n')

        stats = {
            'community': 0,
            'course': 0,
            'instructor_chat': 0,
            'errors': 0,
        }

        for idx, enrollment in enumerate(enrollments, 1):
            user = enrollment.user
            programme = enrollment.programme

            self.stdout.write(f'[{idx}/{enrollments_count}] {user.name} - {programme.title}')

            if dry_run:
                self.stdout.write(f'   [DRY RUN] Would create chat rooms')
                continue

            try:
                # Call the ChatEnforcerService
                ChatEnforcerService.enforce_enrollment_chats(enrollment)
                
                stats['course'] += 1
                self.stdout.write(self.style.SUCCESS('   ✓ Chat rooms created'))
            except Exception as e:
                stats['errors'] += 1
                self.stdout.write(self.style.ERROR(f'   ✗ Error: {e}'))

        # Summary
        self.stdout.write(self.style.SUCCESS('\n' + '='*70))
        self.stdout.write(self.style.SUCCESS('SETUP COMPLETE!'))
        self.stdout.write(self.style.SUCCESS('='*70))
        self.stdout.write(f'\n📊 Summary:')
        self.stdout.write(f'   - Enrollments processed: {enrollments_count}')
        self.stdout.write(f'   - Course chats created: {stats["course"]}')
        self.stdout.write(f'   - Errors: {stats["errors"]}')
        
        if dry_run:
            self.stdout.write(self.style.WARNING('\n⚠️  DRY RUN - No changes made'))
        
        self.stdout.write(self.style.SUCCESS('\n✅ Chat rooms are now available in the Instructor and Student portals!\n'))
