"""
Create 5 African Students for Takawira Mazando's Learnerships
==============================================================
Creates 5 students from Zimbabwe, Kenya, South Africa, and Zambia (×2)
enrolled in Takawira's 4 Learnerships with proper payment flow.

Usage:
    python manage.py create_takawira_students
"""
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone
from django.contrib.auth.hashers import make_password
from apps.users.models import User
from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment
from apps.payments.models import Order, Currency, PaymentTransaction
from apps.localization.models import Country
from decimal import Decimal
from datetime import timedelta
import random


class Command(BaseCommand):
    help = 'Create 5 African students for Takawira Mazando\'s learnerships with proper enrollment & payment flow'

    @transaction.atomic
    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('\n' + '='*70))
        self.stdout.write(self.style.SUCCESS("TAKAWIRA'S STUDENTS - AFRICAN ENROLLMENT"))
        self.stdout.write(self.style.SUCCESS('='*70 + '\n'))

        # Get Takawira Mazando (instructor)
        instructor = User.objects.filter(
            email='takawira.mazando@hosiacademy.co.za'
        ).first()
        
        if not instructor:
            self.stdout.write(self.style.ERROR('❌ Instructor Takawira Mazando not found!'))
            return
        
        self.stdout.write(f'📚 Instructor: {instructor.name} (ID: {instructor.id})')
        
        # Get the 4 learnerships Takawira teaches
        learnership_ids = [1, 2, 3, 4]
        programmes = list(LearnershipProgramme.objects.filter(
            id__in=learnership_ids, 
            active=True
        ))
        
        if len(programmes) < 4:
            self.stdout.write(self.style.ERROR(f'❌ Only {len(programmes)} learnerships found!'))
            return
        
        self.stdout.write(self.style.SUCCESS(f'✓ Found {len(programmes)} learnerships\n'))
        
        # Get countries
        countries_data = {
            'Zimbabwe': {
                'country': Country.objects.filter(name='Zimbabwe').first(),
                'names': ['Tariro', 'Shingai', 'Ruvimbo', 'Tafara'],
                'surnames': ['Moyo', 'Ncube', 'Moyo', 'Gumbo'],
                'phone_code': '+263',
                'cities': ['Harare', 'Bulawayo'],
            },
            'Kenya': {
                'country': Country.objects.filter(name='Kenya').first(),
                'names': ['Wanjiru', 'Kamau', 'Achieng', 'Mutua'],
                'surnames': ['Omondi', 'Kimani', 'Waweru', 'Otieno'],
                'phone_code': '+254',
                'cities': ['Nairobi', 'Mombasa', 'Kisumu'],
            },
            'South Africa': {
                'country': Country.objects.filter(name='South Africa').first(),
                'names': ['Thabo', 'Nomsa', 'Sipho', 'Zanele'],
                'surnames': ['Dlamini', 'Khumalo', 'Nkosi', 'Zulu'],
                'phone_code': '+27',
                'cities': ['Johannesburg', 'Cape Town', 'Durban'],
            },
            'Zambia': {
                'country': Country.objects.filter(name='Zambia').first(),
                'names': ['Chanda', 'Mulenga', 'Bwalya', 'Nkonde'],
                'surnames': ['Mwanza', 'Phiri', 'Mwamba', 'Chanda'],
                'phone_code': '+260',
                'cities': ['Lusaka', 'Ndola', 'Kitwe'],
            },
        }
        
        # Get cities from database (get some from each country's typical states)
        from apps.localization.models import City, State
        city_cache = {}
        
        # Get cities by looking up states in each country
        country_states = {
            'Zimbabwe': ['Harare', 'Bulawayo', 'Matabeleland'],
            'Kenya': ['Nairobi', 'Mombasa', 'Kisumu'],
            'South Africa': ['Gauteng', 'Western Cape', 'KwaZulu-Natal'],
            'Zambia': ['Lusaka', 'Copperbelt'],
        }
        
        for country_name, state_names in country_states.items():
            country = countries_data[country_name]['country']
            if country:
                cities = []
                for state_name in state_names:
                    state = State.objects.filter(name__icontains=state_name, country=country).first()
                    if state:
                        state_cities = City.objects.filter(state=state)[:2]
                        cities.extend(list(state_cities))
                city_cache[country_name] = cities if cities else list(City.objects.all()[:5])
            else:
                city_cache[country_name] = []
        
        # Create 5 students (one from each country, Zambia gets 2)
        students_data = [
            {'country': 'Zimbabwe', 'index': 0},
            {'country': 'Kenya', 'index': 0},
            {'country': 'South Africa', 'index': 0},
            {'country': 'Zambia', 'index': 0},
            {'country': 'Zambia', 'index': 1},  # Second Zambian student
        ]
        
        total_created = 0
        total_enrollments = 0
        total_payments = 0
        
        for student_info in students_data:
            country_name = student_info['country']
            idx = student_info['index']
            country_data = countries_data[country_name]
            
            if not country_data['country']:
                self.stdout.write(self.style.WARNING(f'⚠️  Country {country_name} not found, skipping'))
                continue
            
            # Create student
            first_name = country_data['names'][idx % len(country_data['names'])]
            last_name = country_data['surnames'][idx % len(country_data['surnames'])]
            email = f'{first_name.lower()}.{last_name.lower()}.{country_name.lower().replace(" ", "")}@learner.hosiacademy.co.za'
            username = f'{first_name.lower()}_{last_name.lower()}_{country_name.lower().replace(" ", "")}'
            
            city = city_cache[country_name][idx % len(city_cache[country_name])] if city_cache[country_name] else None
            
            student, created = User.objects.get_or_create(
                email=email,
                defaults={
                    'username': username,
                    'first_name': first_name,
                    'last_name': last_name,
                    'name': f'{first_name} {last_name}',
                    'role_id': 3,  # Student role
                    'password': make_password('Student@2026!'),
                    'is_active': True,
                    'email_verify': '1',
                    'email_verified_at': timezone.now(),
                    'phone': f'{country_data["phone_code"]} {random_phone(country_data["country"])}',
                    'country': country_data['country'],
                    'city': city,
                    'dob': f'{2000 + (idx % 5)}-{(idx % 12) + 1:02d}-{(idx % 28) + 1:02d}',
                    'idnumber': f'{country_data["country"].code}{random.randint(100000, 999999)}',
                    'about': f'Student from {country_name} enrolled in AI learnership programme.',
                }
            )
            
            if created:
                total_created += 1
                self.stdout.write(self.style.SUCCESS(f'\n✓ Created: {student.name} from {country_name}'))
            else:
                self.stdout.write(f'~ Exists: {student.name} from {country_name}')
            
            # Enroll in all 4 learnerships
            for programme in programmes:
                # Create enrollment
                enrollment, enrollment_created = LearnershipEnrollment.objects.get_or_create(
                    user=student,
                    programme=programme,
                    defaults={'active': True}
                )
                
                if enrollment_created:
                    total_enrollments += 1
                    
                    # Create payment order (simulating completed payment flow)
                    amount = Decimal(str(programme.cost_usd)) if programme.cost_usd else Decimal('5000.00')
                    tracking_ref = f'ORD-{programme.id}-{student.id}-{timezone.now().strftime("%Y%m%d%H%M%S")}'
                    
                    order = Order.objects.create(
                        tracking=tracking_ref,
                        user=student,
                        amount=amount,
                        currency=Currency.ZAR,
                        status='completed',
                        payment_method='mock_payment',
                        metadata={
                            'enrollment_id': enrollment.id,
                            'programme_id': programme.id,
                            'programme_title': programme.title,
                            'payment_note': f'Student enrollment - {country_name}',
                            'instructor_id': instructor.id,
                            'instructor_name': instructor.name,
                            'country': country_name,
                            'enrollment_type': 'individual',
                        },
                        created_at=timezone.now() - timedelta(days=random.randint(1, 15)),
                    )
                    
                    # Create payment transaction (simulating completed payment flow)
                    transaction = PaymentTransaction.objects.create(
                        user=student,
                        order=order,
                        amount=amount,
                        currency=Currency.ZAR,
                        transaction_type='payment',
                        provider='mock_provider',
                        provider_reference=f'PAY-{tracking_ref}',
                        provider_method='card',
                        description=f'Payment for {programme.title}',
                        status='successful',
                        metadata={
                            'enrollment_id': enrollment.id,
                            'programme_id': programme.id,
                            'programme_title': programme.title,
                            'payment_method': 'card',
                            'country': country_name,
                            'student_name': student.name,
                            'instructor_id': instructor.id,
                            'instructor_name': instructor.name,
                        },
                        webhook_received=True,
                        webhook_processed_at=timezone.now(),
                        reconciled=True,
                        reconciliation_date=timezone.now().date(),
                        completed_at=timezone.now(),
                        country=country_data['country'].code if country_data['country'] else 'ZA',
                        phone_number=student.phone,
                        is_corporate=False,
                        individual_name=student.name,
                        individual_email=student.email,
                        individual_phone=student.phone,
                        enrollment_type='individual',
                    )
                    
                    total_payments += 1
                    self.stdout.write(
                        self.style.SUCCESS(f'   📚 Enrolled: {programme.title[:50]}...')
                    )
                    self.stdout.write(
                        self.style.SUCCESS(f'   💰 Payment: {amount} ZAR (Order: {tracking_ref})')
                    )
        
        # Summary
        self.stdout.write(self.style.SUCCESS('\n' + '='*70))
        self.stdout.write(self.style.SUCCESS('ENROLLMENT COMPLETE!'))
        self.stdout.write(self.style.SUCCESS('='*70))
        self.stdout.write(f'\n📊 Summary:')
        self.stdout.write(f'   - Students created: {total_created}')
        self.stdout.write(f'   - Enrollments created: {total_enrollments}')
        self.stdout.write(f'   - Payments processed: {total_payments}')
        self.stdout.write(f'   - Learnerships: {len(programmes)}')
        self.stdout.write(f'   - Instructor: {instructor.name}')
        
        # List all students
        self.stdout.write(self.style.SUCCESS('\n👥 Created Students:'))
        students = User.objects.filter(
            email__contains='learner.hosiacademy.co.za',
            role_id=3
        ).order_by('country__name', 'name')[:10]
        
        for s in students:
            country_name = s.country.name if s.country else 'Unknown'
            self.stdout.write(f'   - {s.name} ({s.email}) - {country_name}')
        
        self.stdout.write(self.style.SUCCESS('\n✅ All students can now access their learnerships!\n'))


def random_phone(country):
    """Generate random phone number based on country"""
    import random
    if country.name == 'South Africa':
        return f'11 {random.randint(100, 999)} {random.randint(1000, 9999)}'
    elif country.name == 'Kenya':
        return f'7{random.randint(10, 99)} {random.randint(100, 999)} {random.randint(1000, 9999)}'
    elif country.name == 'Zimbabwe':
        return f'7{random.randint(10, 99)} {random.randint(100, 999)} {random.randint(1000, 9999)}'
    elif country.name == 'Zambia':
        return f'9{random.randint(10, 99)} {random.randint(100, 999)} {random.randint(1000, 9999)}'
    return f'{random.randint(1000000, 9999999)}'
