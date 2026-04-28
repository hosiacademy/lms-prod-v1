# apps/users/management/commands/send_bulk_email.py
"""
Send bulk emails to all users/enrollments in the database
Usage: 
    python manage.py send_bulk_email --subject="Update" --message="Hello {name}"
    python manage.py send_bulk_email --type=students --subject="..." --message="..."
"""
from django.core.management.base import BaseCommand
from django.conf import settings
from apps.users.services.email_service import EmailService


class Command(BaseCommand):
    help = 'Send bulk emails to mailing list from database'

    def add_arguments(self, parser):
        parser.add_argument(
            '--subject',
            type=str,
            help='Email subject',
            required=True
        )
        parser.add_argument(
            '--message',
            type=str,
            help='Email message body (use {name} for personalization)',
            required=True
        )
        parser.add_argument(
            '--type',
            type=str,
            choices=['all', 'students', 'instructors', 'admins', 'enrollments'],
            default='all',
            help='Type of recipients'
        )
        parser.add_argument(
            '--from-email',
            type=str,
            default=settings.DEFAULT_FROM_EMAIL,
            help='From email address'
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Show what would be sent without actually sending'
        )

    def handle(self, *args, **options):
        subject = options['subject']
        message = options['message']
        from_email = options['from_email']
        recipient_type = options['type']
        dry_run = options['dry_run']

        # Get recipients from database
        recipients = EmailService.get_mailing_list(recipient_type)
        
        self.stdout.write(f'\n📧 BULK EMAIL CAMPAIGN')
        self.stdout.write(f'=' * 50)
        self.stdout.write(f'Subject: {subject}')
        self.stdout.write(f'Type: {recipient_type}')
        self.stdout.write(f'Recipients: {len(recipients)}')
        self.stdout.write(f'From: {from_email}')
        
        if dry_run:
            self.stdout.write(f'\n⚠️  DRY RUN - Not actually sending\n')
            for r in recipients[:10]:  # Show first 10
                self.stdout.write(f'  - {r["email"]} ({r["name"]}) - {r["type"]}')
            if len(recipients) > 10:
                self.stdout.write(f'  ... and {len(recipients) - 10} more')
            return
        
        self.stdout.write(f'\n🚀 Sending...\n')
        
        # Send emails
        result = EmailService.send_bulk_email(
            recipients=recipients,
            subject=subject,
            message=message,
            from_email=from_email
        )
        
        self.stdout.write(f'\n✅ RESULTS')
        self.stdout.write(f'=' * 50)
        self.stdout.write(self.style.SUCCESS(f'Sent: {result["sent"]}'))
        if result['failed'] > 0:
            self.stdout.write(self.style.ERROR(f'Failed: {result["failed"]}'))
        
        self.stdout.write(f'\nTotal recipients: {len(recipients)}\n')
