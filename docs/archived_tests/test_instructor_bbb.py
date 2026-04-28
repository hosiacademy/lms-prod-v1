import os
import django
import sys

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
sys.path.append('/home/tk/lms-prod/backend')

django.setup()

from django.contrib.auth import get_user_model
from apps.bbb_integration.models import LiveSession

User = get_user_model()
user = User.objects.filter(email='takawira.mazando@hosiacademy.co.za').first()
if not user:
    print("Instructor not found")
    sys.exit(1)

print(f"User: {user.email}, Role ID: {user.role_id}")

sessions = LiveSession.objects.filter(instructor=user)
print(f"Total sessions: {sessions.count()}")

for session in sessions:
    print(f"Session: {session.title}, Status: {session.status}")
