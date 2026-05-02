import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "lms_project.settings")
django.setup()

from apps.payments.models import Order
from django.contrib.auth import get_user_model

User = get_user_model()

def run():
    pending_orders = Order.objects.filter(status__in=['pending', 'failed', 'cancelled'])
    print(f"Found {pending_orders.count()} incomplete orders.")
    
    users_with_pending = pending_orders.values_list('user_id', flat=True).distinct()
    users_to_delete = []
    
    for user_id in users_with_pending:
        if not user_id: continue
        user = User.objects.filter(id=user_id).first()
        if not user or user.is_staff or user.is_superuser: continue
        
        # Check if they have ANY completed orders or enrollments
        has_completed_order = Order.objects.filter(user_id=user_id, status='completed').exists()
        
        from apps.payments.models import Enrollment
        has_completed_enrollment = Enrollment.objects.filter(user_id=user_id, status__in=['enrolled', 'completed']).exists()
        
        from apps.enrollments.models import ProvisionalEnrollment
        has_prov_enrollment = ProvisionalEnrollment.objects.filter(user_id=user_id, status='confirmed').exists()
        
        if not has_completed_order and not has_completed_enrollment and not has_prov_enrollment:
            users_to_delete.append(user)
            
    print(f"Identified {len(users_to_delete)} users to delete based on pending orders.")
    for u in users_to_delete:
        print(f"Deleting user: {u.email}")
        u.delete()
        
    deleted_orders, _ = pending_orders.delete()
    print(f"Deleted {deleted_orders} incomplete orders.")

if __name__ == "__main__":
    run()
