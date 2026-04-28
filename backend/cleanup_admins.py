import os
import sys
import django

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from apps.payments.models import AdminRole, AdminCountryAccess
from django.contrib.auth import get_user_model

User = get_user_model()

def cleanup():
    target_codes = ['zw', 'zm', 'ke', 'za']
    
    # 1. Identify users to keep admin access for
    all_staff = User.objects.filter(is_staff=True)
    keep_users_ids = []
    
    for user in all_staff:
        email = user.email.lower()
        # Keep specific known admins
        if email in ['hosimonorepo@gmail.com', 'mazandotakawira@gmail.com']:
            keep_users_ids.append(user.id)
            continue
            
        # Keep users with target country codes in their email
        is_target = False
        for code in target_codes:
            if f"_{code}@" in email:
                is_target = True
                break
        
        if is_target:
            keep_users_ids.append(user.id)
            
        # Keep personal emails (non-domain)
        if '@hosiacademy.africa' not in email:
            keep_users_ids.append(user.id)

    # 2. Identify roles to delete
    # Delete all roles for users NOT in the keep list
    roles_to_delete = AdminRole.objects.exclude(user__id__in=keep_users_ids)
    count_roles = roles_to_delete.count()
    roles_to_delete.delete()
    
    # 3. Revoke staff status for those users
    users_to_revoke = User.objects.filter(is_staff=True).exclude(id__in=keep_users_ids)
    count_users = users_to_revoke.count()
    users_to_revoke.update(is_staff=False)
    
    print(f"Cleanup complete.")
    print(f" - Revoked {count_roles} administrative roles.")
    print(f" - Revoked staff status for {count_users} accounts.")
    print(f"Remaining active admin accounts: {User.objects.filter(is_staff=True).count()}")

if __name__ == "__main__":
    cleanup()
