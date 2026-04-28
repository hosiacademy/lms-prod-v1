# apps/users/management/commands/send_mailing_list.py
"""
Send emails to all users/enrollments in the mailing list
Usage: python manage.py send_mailing_list --subject="Test" --message="Hello"
"""
from django.core.management.base import BaseCommand
from django.core.mail import send_mail, EmailMultiAlternatives
from django.conf import settings
from apps.users.models import User
from apps.learnerships.models import LearnershipEnrollment
from apps.payments.models import Enrollment as PaymentEnrollment


class Command(BaseCommand):
    help = 'Send emails to all users in the mailing list'

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
            help='Email message body',
            required=True
        )
        parser.add_argument(
            '--from-email',
            type=str,
            default=settings.DEFAULT_FROM_EMAIL,
            help='From email address'
        )
        parser.add_argument(
            '--type',
            type=str,
            choices=['all', 'students', 'instructors', 'admins', 'enrollments'],
            default='all',
            help='Type of recipients'
        )

    def handle(self, *args, **options):
        subject = options['subject']
        message = options['message']
        from_email = options['from_email']
        recipient_type = options['type']

        recipients = self.get_recipients(recipient_type)
        
        self.stdout.write(f'Sending to {len(recipients)} recipients...')
        
        # Send in bulk using EmailMultiAlternatives
        emails_sent = 0
        for recipient in recipients:
            try:
                email = recipient['email']
                name = recipient.get('name', '')
                
                # Personalize message
                personalized_message = message.replace('{name}', name)
                
                msg = EmailMultiAlternatives(
                    subject=subject,
                    body=personalized_message,
                    from_email=from_email,
                    to=[email]
                )
                msg.send()
                emails_sent += 1
                self.stdout.write(self.style.SUCCESS(f'✓ Sent to {email} ({name})'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'✗ Failed to {email}: {str(e)}'))

        self.stdout.write(self.style.SUCCESS(f'\nSuccessfully sent {emails_sent}/{len(recipients)} emails'))

    def get_recipients(self, recipient_type):
        """Get list of recipients based on type"""
        recipients = []

        if recipient_type in ['all', 'students']:
            # Get all students
            students = User.objects.filter(role_id=3, is_active=True)
            for student in students:
                recipients.append({
                    'email': student.email,
                    'name': student.name or student.username,
                    'type': 'student'
                })

        if recipient_type in ['all', 'instructors']:
            # Get all instructors
            instructors = User.objects.filter(role_id=2, is_active=True)
            for instructor in instructors:
                recipients.append({
                    'email': instructor.email,
                    'name': instructor.name or instructor.username,
                    'type': 'instructor'
                })

        if recipient_type in ['all', 'admins']:
            # Get all admins
            admins = User.objects.filter(
                is_staff=True,
                is_active=True
            )
            for admin in admins:
                recipients.append({
                    'email': admin.email,
                    'name': admin.name or admin.username,
                    'type': 'admin'
                })

        if recipient_type in ['all', 'enrollments']:
            # Get all enrolled students with their enrollment details
            enrollments = LearnershipEnrollment.objects.select_related('user', 'programme').filter(
                active=True
            )
            for enrollment in enrollments:
                recipients.append({
                    'email': enrollment.user.email,
                    'name': enrollment.user.name or enrollment.user.username,
                    'type': 'enrollment',
                    'programme': enrollment.programme.title,
                    'enrollment_id': enrollment.id
                })

        # Remove duplicates (same email)
        seen = set()
        unique_recipients = []
        for r in recipients:
            if r['email'] not in seen:
                seen.add(r['email'])
                unique_recipients.append(r)

        return unique_recipients
