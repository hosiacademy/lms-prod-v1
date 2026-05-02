import os
import django
import sys

# Setup Django environment
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "lms_project.settings")
django.setup()

from django.contrib.auth import get_user_model
from django.db import transaction
from django.db.models import Count, Q
from apps.payments.models import Enrollment, EnrollmentStatus

User = get_user_model()

def run():
    print("Starting deletion of students with incomplete enrollments...")
    
    with transaction.atomic():
        # Find enrollments that are incomplete
        incomplete_statuses = ['pending_info', 'pending_payment', 'payment_processing', 'cancelled']
        
        incomplete_enrollments = Enrollment.objects.filter(status__in=incomplete_statuses)
        incomplete_count = incomplete_enrollments.count()
        print(f"Found {incomplete_count} incomplete enrollments in payments.Enrollment.")
        
        # We need to find users who ONLY have incomplete enrollments
        # Or maybe ANY user that has an incomplete enrollment and NO completed enrollments?
        # Let's get all user IDs associated with incomplete enrollments
        users_with_incomplete = incomplete_enrollments.values_list('user_id', flat=True).distinct()
        
        # Now find users from this list who do NOT have any 'enrolled' or 'completed' enrollments
        users_to_delete = []
        for user_id in users_with_incomplete:
            user = User.objects.filter(id=user_id).first()
            if not user:
                continue
                
            # Check if they are staff or superuser
            if user.is_staff or user.is_superuser:
                print(f"Skipping staff/superuser: {user.email}")
                continue
                
            # Check if they have any completed/enrolled enrollments
            has_complete = Enrollment.objects.filter(
                user_id=user_id, 
                status__in=['enrolled', 'completed']
            ).exists()
            
            if not has_complete:
                users_to_delete.append(user)
        
        print(f"Identified {len(users_to_delete)} students to delete.")
        
        # Also check provisional enrollments
        from apps.enrollments.models import ProvisionalEnrollment
        prov_enrollments = ProvisionalEnrollment.objects.filter(status__in=['cash_pending', 'provisional', 'rejected', 'refunded', 'expired'])
        prov_users = prov_enrollments.values_list('user_id', flat=True).distinct()
        
        for user_id in prov_users:
            if user_id is None:
                continue
            user = User.objects.filter(id=user_id).first()
            if not user or user.is_staff or user.is_superuser or user in users_to_delete:
                continue
                
            # Check if they have ANY complete enrollment
            has_complete_reg = Enrollment.objects.filter(
                user_id=user_id, 
                status__in=['enrolled', 'completed']
            ).exists()
            has_complete_prov = ProvisionalEnrollment.objects.filter(
                user_id=user_id,
                status='confirmed'
            ).exists()
            
            if not has_complete_reg and not has_complete_prov:
                users_to_delete.append(user)
                
        print(f"Total students identified after checking provisional enrollments: {len(users_to_delete)}")
        
        # Delete them
        for user in users_to_delete:
            print(f"Deleting user: {user.email} (ID: {user.id})")
            user.delete()
            
        # Also delete any orphaned incomplete enrollments just in case they belong to deleted users or something
        deleted_enrollments_count, _ = incomplete_enrollments.delete()
        print(f"Deleted {deleted_enrollments_count} incomplete enrollment records.")
        
        deleted_prov_count, _ = ProvisionalEnrollment.objects.filter(status__in=['cash_pending', 'provisional', 'rejected', 'refunded', 'expired']).delete()
        print(f"Deleted {deleted_prov_count} incomplete provisional enrollment records.")
        
        print("Deletion complete.")

if __name__ == "__main__":
    run()
