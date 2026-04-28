from django.core.management.base import BaseCommand
from django.core.mail import send_mail
from django.conf import settings

class Command(BaseCommand):
    help = 'Send a test email to verify SMTP settings'

    def handle(self, *args, **options):
        recipient = 'hosimonorepo@gmail.com'
        self.stdout.write(f'Attempting to send test email to {recipient}...')
        
        try:
            send_mail(
                subject='Django Test',
                message='Django send_mail test.',
                from_email='academy@hosiafrica.com',
                recipient_list=[recipient],
                fail_silently=False
            )
            self.stdout.write(self.style.SUCCESS(f'Successfully sent test email to {recipient}'))
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'Failed to send test email: {str(e)}'))
