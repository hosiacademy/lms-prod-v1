import os
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from apps.payments.models import AdminRole
from decouple import Config, RepositoryEnv
from django.conf import settings

User = get_user_model()

class Command(BaseCommand):
    help = 'Send full list of admin accounts to hosimonorepo@gmail.com using RAW SMTP'

    def handle(self, *args, **options):
        recipient = 'hosimonorepo@gmail.com'
        self.stdout.write(f'Generating official admin directory for {recipient}...')
        
        # Load .env explicitly for raw SMTP
        # BASE_DIR is c:\lms-prod\backend
        BASE_DIR = settings.BASE_DIR
        env_path = os.path.join(BASE_DIR, '.env')
        config = Config(RepositoryEnv(env_path))
        
        # Admin accounts gathering
        admin_users = User.objects.filter(is_staff=True).order_by('email')
        
        html_content = """
        <html>
        <head>
            <style>
                body { font-family: sans-serif; color: #333; }
                table { width: 100%; border-collapse: collapse; margin-top: 20px; }
                th { background-color: #1a237e; color: white; text-align: left; padding: 10px; }
                td { padding: 10px; border-bottom: 1px solid #eee; }
                .tier-header { background-color: #f5f5f5; font-weight: bold; color: #1a237e; }
            </style>
        </head>
        <body>
            <div style="max-width: 800px; margin: 0 auto; padding: 20px;">
                <h1 style="color: #1a237e; text-align: center;">Hosi Academy LMS - Administrator Directory</h1>
                <p>Official list of active administrator accounts for ZW, ZM, KE, ZA and Universal tiers.</p>
                <table>
                    <thead>
                        <tr>
                            <th>Email</th>
                            <th>Role</th>
                            <th>Jurisdiction</th>
                        </tr>
                    </thead>
                    <tbody>
        """

        # Grouping logic
        universal_admins = []
        regional_admins = {}

        for user in admin_users:
            roles = user.admin_roles.all()
            if not roles.exists():
                row = {'email': user.email, 'role': 'System Admin', 'access': 'Universal'}
                universal_admins.append(row)
                continue

            for role in roles:
                access_list = [a.country.name for a in role.country_accesses.all()]
                is_universal = len(access_list) == 0
                row = {
                    'email': user.email,
                    'role': role.get_role_display_name(),
                    'access': "Universal" if is_universal else ", ".join(access_list)
                }
                if is_universal:
                    universal_admins.append(row)
                else:
                    country = access_list[0]
                    if country not in regional_admins: regional_admins[country] = []
                    regional_admins[country].append(row)

        # Build table
        html_content += '<tr class="tier-header"><td colspan="3">TIER 1 - UNIVERSAL</td></tr>'
        for row in universal_admins:
            html_content += f"<tr><td>{row['email']}</td><td>{row['role']}</td><td>{row['access']}</td></tr>"

        for country in sorted(regional_admins.keys()):
            admins_list = regional_admins[country]
            html_content += f'<tr class="tier-header"><td colspan="3">TIER 2 - {country.upper()}</td></tr>'
            for row in admins_list:
                html_content += f"<tr><td>{row['email']}</td><td>{row['role']}</td><td>{row['access']}</td></tr>"

        html_content += """
                    </tbody>
                </table>
                <p><strong>Default Password:</strong> <code>HosiAdmin2026!</code></p>
                <hr>
                <p><small>This is an automated official communication from Hosi Academy LMS.</small></p>
            </div>
        </body>
        </html>
        """

        # RAW SMTP SEND
        host = config('EMAIL_HOST')
        port = config('EMAIL_PORT', cast=int)
        user = config('EMAIL_HOST_USER')
        password = config('EMAIL_HOST_PASSWORD')
        use_tls = config('EMAIL_USE_TLS', cast=bool)

        recipients = ['hosimonorepo@gmail.com', 'mazandotakawira@gmail.com']
        
        for recipient in recipients:
            self.stdout.write(f'Sending to {recipient}...')
            msg = MIMEMultipart()
            msg['From'] = f"Hosi Academy <{user}>"
            msg['To'] = recipient
            msg['Subject'] = "LMS Admin Directory Update"
            msg.attach(MIMEText(html_content, 'html'))

            try:
                server = smtplib.SMTP(host, port, timeout=20)
                if use_tls:
                    server.starttls()
                server.login(user, password)
                server.send_message(msg)
                server.quit()
                self.stdout.write(self.style.SUCCESS(f'Successfully sent to {recipient}'))
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'Failed to send to {recipient}: {str(e)}'))
