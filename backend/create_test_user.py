import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from django.contrib.auth import get_user_model
User = get_user_model()

try:
    user, created = User.objects.get_or_create(
        email='test_auth_user@example.com', 
        defaults={
            'username': 'testauthuser123',
            'first_name': 'Test',
            'last_name': 'User',
            'is_executive': False
        }
    )
    user.set_password('SecurePassword123!')
    user.is_active = True
    user.save()
    if created:
        print("OK: Test user created successfully via ORM")
    else:
        print("OK: Test user updated with test password")
except Exception as e:
    print(f"FAIL: {e}")
