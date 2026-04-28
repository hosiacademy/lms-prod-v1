"""
Management command to create 6 student accounts for BBB live session access.
Students: Richard Masukume + 5 others.
"""
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model

User = get_user_model()

STUDENTS = [
    {
        'first_name': 'Richard',
        'last_name': 'Masukume',
        'email': 'richard.masukume@hosiacademy.africa',
        'username': 'richard.masukume',
        'password': 'HosiLearn@2026!',
    },
    {
        'first_name': 'Amara',
        'last_name': 'Diallo',
        'email': 'amara.diallo@hosiacademy.africa',
        'username': 'amara.diallo',
        'password': 'HosiLearn@2026!',
    },
    {
        'first_name': 'Chidi',
        'last_name': 'Okonkwo',
        'email': 'chidi.okonkwo@hosiacademy.africa',
        'username': 'chidi.okonkwo',
        'password': 'HosiLearn@2026!',
    },
    {
        'first_name': 'Fatima',
        'last_name': 'Nkosi',
        'email': 'fatima.nkosi@hosiacademy.africa',
        'username': 'fatima.nkosi',
        'password': 'HosiLearn@2026!',
    },
    {
        'first_name': 'Kofi',
        'last_name': 'Asante',
        'email': 'kofi.asante@hosiacademy.africa',
        'username': 'kofi.asante',
        'password': 'HosiLearn@2026!',
    },
    {
        'first_name': 'Zanele',
        'last_name': 'Dlamini',
        'email': 'zanele.dlamini@hosiacademy.africa',
        'username': 'zanele.dlamini',
        'password': 'HosiLearn@2026!',
    },
]


class Command(BaseCommand):
    help = 'Create 6 student accounts for BBB live session access'

    def handle(self, *args, **options):
        created_count = 0
        skipped_count = 0

        for student_data in STUDENTS:
            email = student_data['email']
            username = student_data['username']

            if User.objects.filter(email=email).exists():
                self.stdout.write(
                    self.style.WARNING(f'  SKIP  {email} (already exists)')
                )
                skipped_count += 1
                continue

            user = User.objects.create_user(
                username=username,
                email=email,
                password=student_data['password'],
                first_name=student_data['first_name'],
                last_name=student_data['last_name'],
                role_id=3,  # Student
                is_active=True,
            )
            created_count += 1
            self.stdout.write(
                self.style.SUCCESS(
                    f'  OK    {user.get_full_name()} — {email}'
                )
            )

        self.stdout.write('')
        self.stdout.write(
            self.style.SUCCESS(
                f'Done: {created_count} created, {skipped_count} skipped.'
            )
        )
        self.stdout.write('')
        self.stdout.write('Student credentials (all share the same password):')
        self.stdout.write('  Password: HosiLearn@2026!')
        self.stdout.write('')
        for s in STUDENTS:
            self.stdout.write(f"  {s['first_name']} {s['last_name']:12}  {s['email']}")
