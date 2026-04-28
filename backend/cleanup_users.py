from django.contrib.auth import get_user_model
from django.db import connection, transaction
from django.db.models import Q

User = get_user_model()

def cleanup_users():
    with transaction.atomic():
        print("Starting cleanup...")
        
        # 1. Update System Administrators
        updated = User.objects.filter(email='mazandotakawira@gmail.com').update(
            first_name='Takawira', last_name='Mazando', is_staff=True, is_superuser=True
        )
        print(f"Updated Takawira: {updated}")
        
        updated = User.objects.filter(email='sam@hosiafrica.com').update(
            first_name='Samuel', last_name='Mokoena', is_staff=True, is_superuser=True
        )
        print(f"Updated Samuel: {updated}")
        
        updated = User.objects.filter(email__in=['richard@hosiacademy.com', 'richards@hosiacademy.com']).update(
            first_name='Richard', last_name='Masukume', is_staff=True, is_superuser=True
        )
        print(f"Updated Richard: {updated}")
        
        # 2. Delete users without names (except admins)
        admin_emails = ['mazandotakawira@gmail.com', 'sam@hosiafrica.com', 'richard@hosiacademy.com', 'richards@hosiacademy.com']
        
        # First, get users to delete
        users_to_delete = User.objects.filter(
            (Q(first_name__isnull=True) | Q(first_name='')) &
            (Q(last_name__isnull=True) | Q(last_name=''))
        ).exclude(email__in=admin_emails)
        
        print(f"Found {users_to_delete.count()} users to delete")
        
        # Delete related records first (using raw SQL to bypass ORM)
        for user in users_to_delete:
            with connection.cursor() as cursor:
                cursor.execute("DELETE FROM communication_chatparticipant WHERE user_id = %s", [user.id])
                cursor.execute("DELETE FROM enrollments WHERE user_id = %s", [user.id])
                cursor.execute("DELETE FROM user_theme_preferences WHERE user_id = %s", [user.id])
        
        # Now delete the users
        deleted_count = users_to_delete.delete()[0]
        print(f"Deleted {deleted_count} users")
        
        # 3. Keep only Prof Nkosi and Dr Thabo as instructors
        keep_instructors = ['instructor_nkosi_5@hosiacademy.co.za', 'instructor_mbeki_1@hosiacademy.co.za']
        
        # Delete other instructors from related tables first
        other_instructors = User.objects.filter(
            email__icontains='instructor'
        ).exclude(email__in=keep_instructors)
        
        for instructor in other_instructors:
            with connection.cursor() as cursor:
                cursor.execute("DELETE FROM instructor_ratings WHERE instructor_id = %s", [instructor.id])
                cursor.execute("DELETE FROM instructor_analytics WHERE instructor_id = %s", [instructor.id])
                cursor.execute("DELETE FROM instructor_activity_logs WHERE instructor_id = %s", [instructor.id])
        
        # Delete the users
        deleted_instructors = other_instructors.delete()[0]
        print(f"Deleted {deleted_instructors} other instructors")
        
        # 4. Create/update students for each country
        students = [
            ('student.za@hosiacademy.com', 'Thabo', 'Ndlovu'),
            ('student.zw@hosiacademy.com', 'Tendai', 'Moyo'),
            ('student.zm@hosiacademy.com', 'Mutale', 'Banda'),
            ('student.ke@hosiacademy.com', 'Njeri', 'Omondi'),
        ]
        
        for email, first, last in students:
            obj, created = User.objects.update_or_create(
                email=email,
                defaults={
                    'first_name': first,
                    'last_name': last,
                    'is_active': True,
                    'is_staff': False,
                    'is_superuser': False
                }
            )
            print(f"{'Created' if created else 'Updated'}: {email}")
        
        # 5. Ensure Richard is a student
        User.objects.filter(email='richard@hosiacademy.com').update(
            is_staff=False, 
            is_superuser=False, 
            first_name='Richard', 
            last_name='Masukume'
        )
        print("Updated Richard as student")
        
        print("\n=== CLEANUP COMPLETE ===")
        
        # Show final user count
        print(f"\nTotal users remaining: {User.objects.count()}")
        print("\nRemaining users:")
        for user in User.objects.all().order_by('email'):
            print(f"  - {user.email} ({user.first_name} {user.last_name}) | Staff: {user.is_staff} | Superuser: {user.is_superuser}")

if __name__ == '__main__':
    cleanup_users()
