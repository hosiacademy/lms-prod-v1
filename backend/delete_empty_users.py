import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "lms_project.settings")
django.setup()

from django.contrib.auth import get_user_model
from apps.payments.models import Enrollment, Order
from apps.enrollments.models import ProvisionalEnrollment

User = get_user_model()

def run():
    print("Checking for students with incomplete or missing enrollments...")
    
    users = User.objects.filter(is_staff=False, is_superuser=False)
    
    users_to_delete = []
    
    for user in users:
        # Check if they have a completed enrollment
        has_completed_enrollment = Enrollment.objects.filter(
            user=user, 
            status__in=['enrolled', 'completed']
        ).exists()
        
        has_prov_enrollment = ProvisionalEnrollment.objects.filter(
            user=user, 
            status='confirmed'
        ).exists()
        
        has_cash_pending = ProvisionalEnrollment.objects.filter(
            user=user,
            status='cash_pending'
        ).exists()
        
        if not has_completed_enrollment and not has_prov_enrollment and not has_cash_pending:
            # They are incomplete
            users_to_delete.append(user)
            
    from django.db import connection
    
    user_ids = [u.id for u in users_to_delete]
    print(f"Identified {len(user_ids)} users with no active/completed enrollments.")
    
    if user_ids:
        with connection.cursor() as cursor:
            try:
                format_strings = ','.join(['%s'] * len(user_ids))
                user_table = User._meta.db_table
                
                # Try deleting related records first (ignoring errors if tables don't exist)
                try: cursor.execute(f"DELETE FROM communication_chatparticipant WHERE user_id IN ({format_strings})", tuple(user_ids))
                except Exception: pass
                
                try: cursor.execute(f"DELETE FROM enrollments WHERE user_id IN ({format_strings})", tuple(user_ids))
                except Exception: pass
                
                try: cursor.execute(f"DELETE FROM user_theme_preferences WHERE user_id IN ({format_strings})", tuple(user_ids))
                except Exception: pass
                
                try: cursor.execute(f"DELETE FROM provisional_enrollments WHERE user_id IN ({format_strings})", tuple(user_ids))
                except Exception: pass
                
                try: cursor.execute(f"DELETE FROM payments_order WHERE user_id IN ({format_strings})", tuple(user_ids))
                except Exception: pass
                
                try: cursor.execute(f"DELETE FROM payment_transactions WHERE user_id IN ({format_strings})", tuple(user_ids))
                except Exception: pass
                
                cursor.execute(f"DELETE FROM {user_table} WHERE id IN ({format_strings})", tuple(user_ids))
                print(f"Successfully deleted {len(user_ids)} users via raw SQL.")
            except Exception as e:
                print(f"Error during raw SQL deletion: {e}")
                
    print("Cleanup complete.")

if __name__ == "__main__":
    run()
