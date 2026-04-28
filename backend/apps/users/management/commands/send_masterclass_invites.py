# apps/users/management/commands/send_masterclass_invites.py
"""
Send masterclass invitations with schedules to enrolled students
Usage:
    python manage.py send_masterclass_invites --masterclass-type=ai_finance --start-date="2026-04-01"
    
Masterclass Types:
    - ai_finance: AI+ Finance™
    - ai_healthcare: AI+ Healthcare™
    - ai_education: AI+ Education™
    - ai_marketing: AI+ Marketing™
    - ai_hr: AI+ Human Resources™
"""
from django.core.management.base import BaseCommand
from django.conf import settings
from apps.users.models import User
from apps.learnerships.models import LearnershipEnrollment
from apps.users.services.email_service import EmailService
from apps.users.services.masterclass_curricula import get_masterclass_curriculum
from datetime import datetime, timedelta


class Command(BaseCommand):
    help = 'Send masterclass invitations with schedules to enrolled students'

    def add_arguments(self, parser):
        parser.add_argument(
            '--masterclass-type',
            type=str,
            choices=['ai_finance', 'ai_healthcare', 'ai_education', 'ai_marketing', 'ai_hr'],
            required=True,
            help='Type of masterclass'
        )
        parser.add_argument(
            '--start-date',
            type=str,
            required=True,
            help='Start date (YYYY-MM-DD)'
        )
        parser.add_argument(
            '--duration',
            type=int,
            default=3,
            help='Duration in days'
        )
        parser.add_argument(
            '--delivery-mode',
            type=str,
            choices=['Online', 'In-Person', 'Hybrid'],
            default='Online',
            help='Delivery mode'
        )
        parser.add_argument(
            '--venue',
            type=str,
            default='Hosi Academy Online Platform',
            help='Venue or platform URL'
        )
        parser.add_argument(
            '--client-company',
            type=str,
            default='Your Employer',
            help='Sponsoring company name'
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be sent without actually sending'
        )

    def handle(self, *args, **options):
        masterclass_type = options['masterclass_type']
        start_date_str = options['start_date']
        duration = options['duration']
        delivery_mode = options['delivery_mode']
        venue = options['venue']
        client_company = options['client_company']
        dry_run = options['dry_run']

        # Parse start date
        try:
            start_date = datetime.strptime(start_date_str, '%Y-%m-%d')
            end_date = start_date + timedelta(days=duration-1)
        except ValueError:
            self.stdout.write(self.style.ERROR('Invalid date format. Use YYYY-MM-DD'))
            return

        # Get curriculum
        curriculum = get_masterclass_curriculum(masterclass_type)

        # Get all enrolled students for this masterclass
        # For demo, get all active students
        students = User.objects.filter(role_id=3, is_active=True)[:10]

        self.stdout.write(f'\n🎓 MASTERCLASS INVITATIONS')
        self.stdout.write(f'=' * 60)
        self.stdout.write(f'Type: {curriculum["title"]}')
        self.stdout.write(f'Dates: {start_date.strftime("%d %B %Y")} - {end_date.strftime("%d %B %Y")}')
        self.stdout.write(f'Duration: {duration} days')
        self.stdout.write(f'Delivery: {delivery_mode}')
        self.stdout.write(f'Venue: {venue}')
        self.stdout.write(f'Client: {client_company}')
        self.stdout.write(f'Recipients: {len(students)} students')
        
        if dry_run:
            self.stdout.write(f'\n⚠️  DRY RUN - Not actually sending\n')
            for student in students[:5]:
                self.stdout.write(f'  - {student.email} ({student.name or student.username})')
            return

        self.stdout.write(f'\n🚀 Sending invitations...\n')

        sent = 0
        failed = 0

        for student in students:
            try:
                # Create a mock enrollment for demo
                # In production, you'd use actual enrollment objects
                masterclass_details = {
                    'title': curriculum['title'],
                    'start_date': start_date.strftime('%d %B %Y'),
                    'end_date': end_date.strftime('%d %B %Y'),
                    'duration_days': str(duration),
                    'delivery_mode': delivery_mode,
                    'venue_platform': venue,
                    'instructor_name': 'Hosi Academy Team',
                    'client_company_name': client_company,
                    'portal_url': 'https://www.hosiacademy.africa/student/dashboard/',
                    'certification': curriculum['certification'],
                    'target_audience': curriculum['target_audience'],
                    'daily_schedule_text': curriculum['daily_schedule_text'],
                    'curriculum_text': curriculum['curriculum_text'],
                }

                # For demo, create mock enrollment object
                class MockEnrollment:
                    user = student
                    id = 999

                EmailService.send_masterclass_invitation(MockEnrollment(), masterclass_details)
                sent += 1
                self.stdout.write(self.style.SUCCESS(f'✓ Sent to {student.email}'))

            except Exception as e:
                failed += 1
                self.stdout.write(self.style.ERROR(f'✗ Failed to {student.email}: {str(e)}'))

        self.stdout.write(f'\n✅ RESULTS')
        self.stdout.write(f'=' * 60)
        self.stdout.write(self.style.SUCCESS(f'Sent: {sent}'))
        if failed > 0:
            self.stdout.write(self.style.ERROR(f'Failed: {failed}'))
        
        self.stdout.write(f'\nTotal recipients: {len(students)}\n')
