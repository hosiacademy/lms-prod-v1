import os
import django
import sys
from django.conf import settings

# Set up Django environment
sys.path.append('backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from apps.notifications.services import EmailService
from datetime import datetime, timedelta

def send_test_email():
    target_email = "mazandotakawira@gmail.com"
    user_name = "Mazan Dotakawira"
    enrollment_code = "HOSI-ENR-2026-X84"
    program_name = "AI in Real Estate Practitioner"
    program_type = "masterclass"
    
    enrollment_details = {
        'start_date': datetime.now() + timedelta(days=30),
        'duration': '3 Days (Intensive)',
        'location': 'Sandton Office, Johannesburg / Zoom',
        'delivery_mode': 'Hybrid',
        'enrolled_at': datetime.now(),
    }
    
    access_credentials = {
        'username': target_email,
        'password': 'Set your password via the link sent previously'
    }
    
    print(f"Sending enrollment success email to {target_email}...")
    try:
        success = EmailService.send_enrollment_success(
            user_email=target_email,
            user_name=user_name,
            enrollment_code=enrollment_code,
            program_name=program_name,
            program_type=program_type,
            enrollment_details=enrollment_details,
            access_credentials=access_credentials
        )
        
        if success:
            print("SUCCESS: Email sent successfully!")
        else:
            print("FAILURE: Failed to send email.")
    except Exception as e:
        print(f"ERROR: {str(e)}")

if __name__ == "__main__":
    send_test_email()
