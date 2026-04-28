"""
Django management command to create test students for each country across all enrollment pathways.
Creates 3 students per country (Kenya, Zimbabwe, Zambia, Botswana) = 12 students total.
Each student is enrolled in:
1. Masterclasses
2. Custom Selection
3. Industry Specialised & Role-based Training
4. Learnerships

All enrollments follow the proper enrollment and payment pathways with simulated payments.

Usage:
    python manage.py create_test_students_enrollments

Credentials will be displayed in the output and saved to a file.
"""
import random
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from apps.localization.models import Country
from apps.payments.models import AdminRole, AdminCountryAccess, PaymentTransaction, PaymentProvider
from apps.enrollments.models import ProvisionalEnrollment
from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment
from apps.masterclasses.models import Masterclass

User = get_user_model()


class Command(BaseCommand):
    help = 'Create test students with enrollments across all pathways for Kenya, Zimbabwe, Zambia, Botswana'

    # Country configurations with payment providers
    COUNTRIES_CONFIG = {
        'KE': {
            'name': 'Kenya',
            'currency': 'KES',
            'primary_provider': PaymentProvider.MPESA,
            'secondary_provider': PaymentProvider.PESAPAL,
            'phone_prefix': '+254',
        },
        'ZW': {
            'name': 'Zimbabwe',
            'currency': 'USD',
            'primary_provider': PaymentProvider.ECASH,
            'secondary_provider': PaymentProvider.ONEMONEY,
            'phone_prefix': '+263',
        },
        'ZM': {
            'name': 'Zambia',
            'currency': 'ZMW',
            'primary_provider': PaymentProvider.AIRTEL_MONEY,
            'secondary_provider': PaymentProvider.MTN_MOMO,
            'phone_prefix': '+260',
        },
        'BW': {
            'name': 'Botswana',
            'currency': 'BWP',
            'primary_provider': PaymentProvider.MTN_MOMO,
            'secondary_provider': PaymentProvider.FLUTTERWAVE,
            'phone_prefix': '+267',
        },
    }

    # Course/programme prices by type
    PRICES = {
        'masterclass': {'KES': 5000, 'USD': 50, 'ZMW': 500, 'BWP': 400},
        'industry': {'KES': 15000, 'USD': 150, 'ZMW': 1500, 'BWP': 1200},
        'learnership': {'KES': 25000, 'USD': 250, 'ZMW': 2500, 'BWP': 2000},
        'custom': {'KES': 10000, 'USD': 100, 'ZMW': 1000, 'BWP': 800},
    }

    def add_arguments(self, parser):
        parser.add_argument(
            '--force',
            action='store_true',
            help='Force recreate students if they already exist',
        )
        parser.add_argument(
            '--output-file',
            type=str,
            default='test_student_credentials.txt',
            help='Output file for credentials (default: test_student_credentials.txt)',
        )

    def generate_password(self, country_code, student_num):
        """Generate password for student"""
        return f'{country_code}Student{student_num}@2026'

    def generate_username(self, country_code, student_num):
        """Generate username for student"""
        return f'student_{country_code.lower()}_{student_num:03d}'

    def generate_email(self, country_code, student_num, country_name):
        """Generate email for student"""
        country_short = country_name.lower().replace(' ', '_')
        return f'student{student_num}.{country_short}@test.hosi.academy'

    def generate_phone(self, country_code, student_num):
        """Generate phone number for student"""
        prefix = self.COUNTRIES_CONFIG[country_code]['phone_prefix']
        # Generate realistic phone numbers
        numbers = {
            'KE': f'{prefix}7{random.randint(10000000, 99999999)}',
            'ZW': f'{prefix}7{random.randint(10000000, 99999999)}',
            'ZM': f'{prefix}9{random.randint(10000000, 99999999)}',
            'BW': f'{prefix}7{random.randint(10000000, 99999999)}',
        }
        return numbers.get(country_code, f'{prefix}12345678')

    def get_or_create_country(self, code, config):
        """Get or create a country"""
        country, created = Country.objects.get_or_create(
            code=code,
            defaults={
                'name': config['name'],
                'is_active': True,
            }
        )
        return country

    def create_student(self, country_code, student_num, force=False):
        """Create a test student for a specific country"""
        config = self.COUNTRIES_CONFIG[country_code]
        country = self.get_or_create_country(country_code, config)
        
        username = self.generate_username(country_code, student_num)
        email = self.generate_email(country_code, student_num, config['name'])
        password = self.generate_password(country_code, student_num)
        phone = self.generate_phone(country_code, student_num)
        
        # Check if student exists
        existing_user = User.objects.filter(username=username).first()
        
        if existing_user:
            if not force:
                return existing_user, False
            existing_user.delete()
        
        # Create student user with proper name format for AICERTS
        first_name = f'Student{student_num}'
        last_name = config['name']  # Use country name as lastname
        
        student = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            role_id=3,  # Student role
            name=f'{first_name} {last_name}',
            first_name=first_name,
            last_name=last_name,
            country=country,
            phone=phone,
            email_verified_at=timezone.now(),
        )
        
        return student, True

    def simulate_payment(self, student, amount, currency, provider, transaction_type, reference=None):
        """Simulate a payment transaction"""
        from apps.payments.models import TransactionType
        
        # Map transaction_type string to enum
        type_map = {
            'masterclass': TransactionType.PURCHASE,
            'custom_selection': TransactionType.PURCHASE,
            'industry': TransactionType.PURCHASE,
            'learnership': TransactionType.PURCHASE,
        }
        
        transaction = PaymentTransaction.objects.create(
            user=student,
            amount=amount,
            currency=currency,
            provider=provider,
            status='successful',
            transaction_type=type_map.get(transaction_type, TransactionType.PURCHASE),
            provider_reference=reference or f'TEST-{timezone.now().strftime("%Y%m%d%H%M%S")}-{random.randint(1000, 9999)}',
            metadata={
                'test_payment': True,
                'country': student.country.code,
                'payment_method': provider,
            },
            completed_at=timezone.now(),
        )
        return transaction

    def enroll_in_masterclass(self, student, country_code):
        """Enroll student in a masterclass with payment"""
        config = self.COUNTRIES_CONFIG[country_code]
        currency = config['currency']
        price = self.PRICES['masterclass'].get(currency, 100)
        
        # Get or create a test masterclass
        masterclass, created = Masterclass.objects.get_or_create(
            title=f'Test Masterclass - {config["name"]}',
            defaults={
                'description': f'Test masterclass for {config["name"]} students',
                'price': price,
                'currency': currency,
                'country_code': country_code,
                'country_name': config['name'],
                'slug': f'test-masterclass-{country_code.lower()}-{timezone.now().strftime("%Y%m%d")}',
                'start_date': timezone.now() + timedelta(days=30),
                'end_date': timezone.now() + timedelta(days=32),
                'status': 'scheduled',
            }
        )
        
        # Simulate payment
        provider = random.choice([config['primary_provider'], config['secondary_provider']])
        transaction = self.simulate_payment(
            student, price, currency, provider,
            'masterclass', f'MC-{country_code}-{student.id}-{random.randint(1000,9999)}'
        )
        
        # Create provisional enrollment
        enrollment, created = ProvisionalEnrollment.objects.get_or_create(
            user=student,
            enrollment_type='masterclass',
            defaults={
                'status': 'confirmed',
                'payment_transaction': transaction,
                'metadata': {
                    'training_id': masterclass.id,
                    'training_title': masterclass.title,
                    'payment_provider': provider,
                    'test_enrollment': True,
                }
            }
        )
        
        return enrollment, created, masterclass, transaction

    def enroll_in_custom_selection(self, student, country_code):
        """Enroll student in custom selection pathway with payment"""
        config = self.COUNTRIES_CONFIG[country_code]
        currency = config['currency']
        price = self.PRICES['custom'].get(currency, 100)
        
        # Get or create a test programme for custom selection
        from apps.learnerships.models import LearnershipProgramme
        programme, _ = LearnershipProgramme.objects.get_or_create(
            title=f'Test Custom Selection - {config["name"]}',
            defaults={
                'description': f'Test custom selection programme for {config["name"]}',
                'specialization': 'Custom',
            }
        )
        
        # Simulate payment
        provider = random.choice([config['primary_provider'], config['secondary_provider']])
        transaction = self.simulate_payment(
            student, price, currency, provider,
            'custom_selection', f'CS-{country_code}-{student.id}-{random.randint(1000,9999)}'
        )
        
        # Create provisional enrollment
        enrollment, created = ProvisionalEnrollment.objects.get_or_create(
            user=student,
            enrollment_type='custom_selection',
            defaults={
                'status': 'confirmed',
                'payment_transaction': transaction,
                'programme': programme,
                'metadata': {
                    'training_id': programme.id,
                    'training_title': programme.title,
                    'payment_provider': provider,
                    'test_enrollment': True,
                }
            }
        )
        
        return enrollment, created, programme, transaction

    def enroll_in_industry_training(self, student, country_code):
        """Enroll student in industry specialised & role-based training with payment"""
        config = self.COUNTRIES_CONFIG[country_code]
        currency = config['currency']
        price = self.PRICES['industry'].get(currency, 150)
        
        # Get or create test industry offering
        from apps.industry_based_training.models import Industry, Offering
        industry, _ = Industry.objects.get_or_create(
            name=f'Test Industry - {config["name"]}',
            defaults={'description': f'Test industry for {config["name"]}'}
        )
        
        offering, _ = Offering.objects.get_or_create(
            name=f'Test Industry Training - {config["name"]}',
            defaults={
                'description': f'Test industry specialised training for {config["name"]}',
                'industry': industry,
                'price_usd': price,
            }
        )
        
        # Simulate payment
        provider = random.choice([config['primary_provider'], config['secondary_provider']])
        transaction = self.simulate_payment(
            student, price, currency, provider,
            'industry', f'IT-{country_code}-{student.id}-{random.randint(1000,9999)}'
        )
        
        # Create provisional enrollment
        enrollment, created = ProvisionalEnrollment.objects.get_or_create(
            user=student,
            enrollment_type='industry',
            defaults={
                'status': 'confirmed',
                'payment_transaction': transaction,
                'metadata': {
                    'training_id': offering.id,
                    'training_title': offering.name,
                    'payment_provider': provider,
                    'test_enrollment': True,
                }
            }
        )
        
        return enrollment, created, offering, transaction

    def enroll_in_learnership(self, student, country_code):
        """Enroll student in learnership pathway with payment"""
        config = self.COUNTRIES_CONFIG[country_code]
        currency = config['currency']
        price = self.PRICES['learnership'].get(currency, 250)
        
        # Get or create test learnership programme
        programme, _ = LearnershipProgramme.objects.get_or_create(
            title=f'Test Learnership - {config["name"]}',
            defaults={
                'description': f'Test learnership programme for {config["name"]}',
                'specialization': 'Learnership',
                'start_date': timezone.now() + timedelta(days=30),
                'end_date': timezone.now() + timedelta(days=180),
            }
        )
        
        # Simulate payment
        provider = random.choice([config['primary_provider'], config['secondary_provider']])
        transaction = self.simulate_payment(
            student, price, currency, provider,
            'learnership', f'LP-{country_code}-{student.id}-{random.randint(1000,9999)}'
        )
        
        # Create learnership enrollment with required fields
        enrollment, created = LearnershipEnrollment.objects.get_or_create(
            user=student,
            programme=programme,
            defaults={
                'status': 'enrolled',
                'active': True,
                'enrollment_type': 'individual',
                'payment_status': 'paid',
                'payment_transaction': transaction,
                'currency': currency,
                'amount_paid': price,
                'total_amount': price,
                'prerequisites_verified': True,
                'verified_at': timezone.now(),
                'verified_by': student,
                'metadata': {
                    'payment_provider': provider,
                    'payment_amount': price,
                    'payment_currency': currency,
                    'test_enrollment': True,
                }
            }
        )
        
        return enrollment, created, programme, transaction

    def handle(self, *args, **options):
        force = options['force']
        output_file = options['output_file']
        
        self.stdout.write(self.style.SUCCESS('=' * 80))
        self.stdout.write(self.style.SUCCESS('HOSI ACADEMY - TEST STUDENTS & ENROLLMENTS SETUP'))
        self.stdout.write(self.style.SUCCESS('Testing All Enrollment Pathways with Country-Specific Payments'))
        self.stdout.write(self.style.SUCCESS('=' * 80))
        self.stdout.write('')
        
        credentials = []
        enrollments_summary = []
        
        # Create students for each country
        for country_code, config in self.COUNTRIES_CONFIG.items():
            self.stdout.write(self.style.SUCCESS(f'\n{"="*80}'))
            self.stdout.write(self.style.SUCCESS(f'{config["name"]} ({country_code})'))
            self.stdout.write(self.style.SUCCESS(f'{"="*80}'))
            self.stdout.write(f'Currency: {config["currency"]}')
            self.stdout.write(f'Primary Provider: {config["primary_provider"].label}')
            self.stdout.write(f'Secondary Provider: {config["secondary_provider"].label}')
            self.stdout.write('')
            
            country_students = []
            
            # Create 3 students per country
            for student_num in range(1, 4):
                self.stdout.write(self.style.SUCCESS(f'\n--- Student {student_num} ---'))
                
                student, created = self.create_student(country_code, student_num, force)
                
                if created or force:
                    self.stdout.write(
                        self.style.SUCCESS(f'✓ Created: {student.username} ({student.email})')
                    )
                else:
                    self.stdout.write(
                        self.style.WARNING(f'• Exists: {student.username} ({student.email})')
                    )
                
                student_info = {
                    'country': config['name'],
                    'country_code': country_code,
                    'student_num': student_num,
                    'username': student.username,
                    'email': student.email,
                    'password': self.generate_password(country_code, student_num),
                    'phone': student.phone,
                    'enrollments': []
                }
                
                # Enroll in all pathways
                pathways = [
                    ('Masterclass', self.enroll_in_masterclass),
                    ('Custom Selection', self.enroll_in_custom_selection),
                    ('Industry Training', self.enroll_in_industry_training),
                    ('Learnership', self.enroll_in_learnership),
                ]
                
                for pathway_name, pathway_func in pathways:
                    try:
                        enrollment, created, programme, transaction = pathway_func(student, country_code)
                        
                        status = '✓ Created' if created else '• Exists'
                        self.stdout.write(
                            f'  {status} {pathway_name}: {programme.title[:50]}...'
                        )
                        self.stdout.write(
                            f'    Payment: {transaction.amount} {transaction.currency} via {transaction.provider.label}'
                        )
                        
                        student_info['enrollments'].append({
                            'pathway': pathway_name,
                            'programme': programme.title,
                            'amount': float(transaction.amount),
                            'currency': transaction.currency,
                            'provider': transaction.provider.label,
                            'reference': transaction.provider_reference,
                        })
                        
                        enrollments_summary.append({
                            'student': student.username,
                            'country': config['name'],
                            'pathway': pathway_name,
                            'programme': programme.title,
                            'amount': float(transaction.amount),
                            'currency': transaction.currency,
                            'provider': transaction.provider.label,
                        })
                        
                    except Exception as e:
                        self.stdout.write(
                            self.style.ERROR(f'  ✗ Failed {pathway_name}: {str(e)}')
                        )
                
                credentials.append(student_info)
                country_students.append(student)
        
        # Display credentials
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=' * 80))
        self.stdout.write(self.style.SUCCESS('STUDENT CREDENTIALS'))
        self.stdout.write(self.style.SUCCESS('=' * 80))
        
        for cred in credentials:
            self.stdout.write('')
            self.stdout.write(self.style.SUCCESS(f"Country: {cred['country']} (Student {cred['student_num']})"))
            self.stdout.write(f"  Username:   {cred['username']}")
            self.stdout.write(f"  Email:      {cred['email']}")
            self.stdout.write(f"  Password:   {cred['password']}")
            self.stdout.write(f"  Phone:      {cred['phone']}")
            self.stdout.write(f"  Enrollments:")
            for enrollment in cred['enrollments']:
                self.stdout.write(f"    - {enrollment['pathway']}: {enrollment['amount']} {enrollment['currency']} ({enrollment['provider']})")
        
        # Save to file
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=' * 80))
        self.stdout.write(self.style.SUCCESS(f'Saving credentials to: {output_file}'))
        self.stdout.write('=' * 80)
        
        with open(output_file, 'w') as f:
            f.write('=' * 80 + '\n')
            f.write('HOSI ACADEMY - TEST STUDENT CREDENTIALS\n')
            f.write('Enrollment Pathway Testing\n')
            f.write(f'Generated: {timezone.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
            f.write('=' * 80 + '\n\n')
            
            f.write('PAYMENT PROVIDERS BY COUNTRY:\n')
            f.write('-' * 80 + '\n')
            for country_code, config in self.COUNTRIES_CONFIG.items():
                f.write(f'{config["name"]} ({country_code}):\n')
                f.write(f'  Currency: {config["currency"]}\n')
                f.write(f'  Primary Provider: {config["primary_provider"].label}\n')
                f.write(f'  Secondary Provider: {config["secondary_provider"].label}\n\n')
            
            f.write('\nSTUDENT CREDENTIALS:\n')
            f.write('=' * 80 + '\n\n')
            
            for cred in credentials:
                f.write('-' * 80 + '\n')
                f.write(f"Country: {cred['country']} (Student {cred['student_num']})\n")
                f.write(f"  Username:   {cred['username']}\n")
                f.write(f"  Email:      {cred['email']}\n")
                f.write(f"  Password:   {cred['password']}\n")
                f.write(f"  Phone:      {cred['phone']}\n")
                f.write(f"  Enrollments:\n")
                for enrollment in cred['enrollments']:
                    f.write(f"    - {enrollment['pathway']}\n")
                    f.write(f"      Programme: {enrollment['programme']}\n")
                    f.write(f"      Amount: {enrollment['amount']} {enrollment['currency']}\n")
                    f.write(f"      Provider: {enrollment['provider']}\n")
                f.write('\n')
            
            f.write('=' * 80 + '\n')
            f.write('END OF CREDENTIALS\n')
            f.write('=' * 80 + '\n')
        
        self.stdout.write(self.style.SUCCESS(f'✓ Credentials saved to: {output_file}'))
        
        # Summary
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=' * 80))
        self.stdout.write(self.style.SUCCESS('SUMMARY'))
        self.stdout.write(self.style.SUCCESS('=' * 80))
        self.stdout.write(f'  Countries: {len(self.COUNTRIES_CONFIG)}')
        self.stdout.write(f'  Students per country: 3')
        self.stdout.write(f'  Total students: {len(credentials)}')
        self.stdout.write(f'  Pathways per student: 4')
        self.stdout.write(f'  Total enrollments: {len(enrollments_summary)}')
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('Enrollment Pathways Tested:'))
        self.stdout.write('  1. Masterclass - Direct enrollment with payment')
        self.stdout.write('  2. Custom Selection - Custom course selection with payment')
        self.stdout.write('  3. Industry Specialised & Role-based Training - Industry training with payment')
        self.stdout.write('  4. Learnerships - Full learnership programme enrollment with payment')
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('Payment Providers Used:'))
        for country_code, config in self.COUNTRIES_CONFIG.items():
            self.stdout.write(f'  {config["name"]}: {config["primary_provider"].label}, {config["secondary_provider"].label}')
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('✓ Test students and enrollments setup complete!'))
        self.stdout.write('')
