"""
Create complete test environment with students, instructors, and enrollments.
Links students to instructors and populates dashboards accordingly.

Creates for each country (Kenya, Zimbabwe, Zambia, Botswana):
- 3 Students with full demographic data
- 1 Instructor/Facilitator 
- Links students to instructor
- Creates enrollments showing in respective dashboards

Usage:
    python manage.py create_complete_test_data
"""
import random
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.db import transaction
from apps.localization.models import Country
from apps.payments.models import PaymentTransaction, PaymentProvider, TransactionType, PaymentStatus
from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment, EnrollmentStatus
from apps.masterclasses.models import Masterclass
from apps.enrollments.models import ProvisionalEnrollment
from apps.facilitators.models import FacilitatorProfile
from apps.industry_based_training.models import Industry, Offering

User = get_user_model()


class Command(BaseCommand):
    help = 'Create complete test environment with students, instructors, and dashboard data'

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

    def add_arguments(self, parser):
        parser.add_argument('--force', action='store_true', help='Recreate if exists')
        parser.add_argument('--output-file', type=str, default='complete_test_credentials.txt',
                          help='Output file for credentials')

    @transaction.atomic
    def handle(self, *args, **options):
        force = options['force']
        output_file = options['output_file']
        
        self.stdout.write(self.style.SUCCESS('=' * 80))
        self.stdout.write(self.style.SUCCESS('HOSI ACADEMY - COMPLETE TEST ENVIRONMENT SETUP'))
        self.stdout.write(self.style.SUCCESS('Students, Instructors, Enrollments & Dashboard Data'))
        self.stdout.write(self.style.SUCCESS('=' * 80))
        self.stdout.write('')
        
        all_credentials = []
        
        for country_code, config in self.COUNTRIES_CONFIG.items():
            country_data = self.setup_country(country_code, config, force)
            all_credentials.extend(country_data['credentials'])
        
        # Save credentials
        self.save_credentials(all_credentials, output_file)
        
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=' * 80))
        self.stdout.write(self.style.SUCCESS('SETUP COMPLETE'))
        self.stdout.write(self.style.SUCCESS('=' * 80))
        self.stdout.write(f'  Total Countries: {len(self.COUNTRIES_CONFIG)}')
        self.stdout.write(f'  Total Students: {len(self.COUNTRIES_CONFIG) * 3}')
        self.stdout.write(f'  Total Instructors: {len(self.COUNTRIES_CONFIG)}')
        self.stdout.write(f'  Credentials saved to: {output_file}')
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('Dashboard URLs:'))
        self.stdout.write('  Student Dashboard: http://localhost:7000/dashboard')
        self.stdout.write('  Instructor Dashboard: http://localhost:7000/instructor/dashboard')
        self.stdout.write('  Admin Dashboard: http://localhost:7000/admin/dashboard')
        self.stdout.write('')

    def setup_country(self, country_code, config, force=False):
        """Setup complete test environment for a country"""
        
        self.stdout.write(self.style.SUCCESS(f'\n{"="*80}'))
        self.stdout.write(self.style.SUCCESS(f'{config["name"]} ({country_code})'))
        self.stdout.write(self.style.SUCCESS(f'{"="*80}'))
        
        country, _ = Country.objects.get_or_create(
            code=country_code,
            defaults={'name': config['name'], 'is_active': True}
        )
        
        # Create instructor
        instructor = self.create_instructor(country_code, config, country, force)
        
        # Create students and link to instructor
        students = []
        for i in range(1, 4):
            student = self.create_student(country_code, config, country, i, force)
            students.append(student)
        
        # Create programmes/courses linked to instructor
        learnership = self.create_learnership_programme(country_code, config, instructor, force)
        masterclass = self.create_masterclass(country_code, config, instructor, force)
        industry_offering = self.create_industry_offering(country_code, config, instructor, force)
        
        # Enroll students with payments
        credentials = []
        for student in students:
            student_creds = self.enroll_student(
                student, instructor, learnership, masterclass, industry_offering,
                country_code, config, country
            )
            credentials.append(student_creds)
        
        # Add instructor credentials
        credentials.append({
            'type': 'instructor',
            'country': config['name'],
            'username': instructor.username,
            'email': instructor.email,
            'password': f'Instructor@{country_code}2026',
            'role': 'Instructor/Facilitator',
        })
        
        self.stdout.write(f'  ✓ Setup complete for {config["name"]}')
        
        return {'instructor': instructor, 'students': students, 'credentials': credentials}

    def create_instructor(self, country_code, config, country, force=False):
        """Create instructor/facilitator for country"""
        
        username = f'instructor_{country_code.lower()}'
        email = f'instructor.{country_code.lower()}@hosi.academy'
        password = f'Instructor@{country_code}2026'
        phone = f'{config["phone_prefix"]}7{random.randint(10000000, 99999999)}'
        
        # Check if exists
        existing = User.objects.filter(username=username).first()
        if existing:
            if not force:
                self.stdout.write(f'  • Instructor exists: {username}')
                return existing
            existing.delete()
        
        # Create instructor user
        instructor = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            role_id=2,  # Instructor role
            name=f'Instructor {config["name"]}',
            first_name='Instructor',
            last_name=config['name'],
            country=country,
            phone=phone,
            email_verified_at=timezone.now(),
            is_aicerts_instructor=True,
        )
        
        # Create facilitator profile
        profile, _ = FacilitatorProfile.objects.get_or_create(
            user=instructor,
            defaults={
                'facilitator_type': 'instructor',
                'department': 'Academic',
                'specialization': f'{config["name"]} Studies',
                'work_email': email,
                'is_available': True,
                'overall_rating': 4.8,
                'total_courses_taught': 0,
                'total_students_taught': 0,
            }
        )
        
        self.stdout.write(self.style.SUCCESS(f'  ✓ Created instructor: {username}'))
        return instructor

    def create_student(self, country_code, config, country, student_num, force=False):
        """Create student with full demographic data"""
        
        username = f'student_{country_code.lower()}_{student_num:03d}'
        email = f'student{student_num}.{country_code.lower()}@test.hosi.academy'
        password = f'{country_code}Student{student_num}@2026'
        phone = f'{config["phone_prefix"]}7{random.randint(10000000, 99999999)}'
        
        # Check if exists
        existing = User.objects.filter(username=username).first()
        if existing:
            if not force:
                self.stdout.write(f'    • Student exists: {username}')
                return existing
            existing.delete()
        
        # Create student
        student = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            role_id=3,  # Student role
            name=f'Student{student_num} {config["name"]}',
            first_name=f'Student{student_num}',
            last_name=config['name'],
            country=country,
            phone=phone,
            email_verified_at=timezone.now(),
            address=f'{random.randint(1, 999)} Test Street, {config["name"]} City',
        )
        
        self.stdout.write(self.style.SUCCESS(f'    ✓ Created: {username}'))
        return student

    def create_learnership_programme(self, country_code, config, instructor, force=False):
        """Create learnership programme linked to instructor"""
        
        title = f'{config["name"]} Business Learnership'
        
        # Check if exists
        existing = LearnershipProgramme.objects.filter(title=title).first()
        if existing:
            if not force:
                return existing
            existing.delete()
        
        programme = LearnershipProgramme.objects.create(
            title=title,
            description=f'Comprehensive business learnership for {config["name"]}',
            specialization='Business Administration',
            instructor=instructor,
            start_date=timezone.now() + timedelta(days=30),
            end_date=timezone.now() + timedelta(days=365),
            price=25000 if config['currency'] == 'KES' else 250,
            currency=config['currency'],
            is_active=True,
        )
        
        self.stdout.write(f'  ✓ Created learnership: {title[:40]}...')
        return programme

    def create_masterclass(self, country_code, config, instructor, force=False):
        """Create masterclass linked to instructor"""
        
        title = f'{config["name"]} Digital Marketing Masterclass'
        slug = f'{country_code.lower()}-digital-marketing-{timezone.now().strftime("%Y%m%d")}'
        
        # Check if exists
        existing = Masterclass.objects.filter(slug=slug).first()
        if existing:
            if not force:
                return existing
            existing.delete()
        
        masterclass = Masterclass.objects.create(
            title=title,
            slug=slug,
            description=f'Digital marketing masterclass for {config["name"]}',
            start_date=timezone.now() + timedelta(days=30),
            end_date=timezone.now() + timedelta(days=32),
            status='scheduled',
            price=5000 if config['currency'] == 'KES' else 50,
            currency=config['currency'],
            country_code=country_code,
            country_name=config['name'],
            city=f'{config["name"]} City',
            max_participants=35,
        )
        
        self.stdout.write(f'  ✓ Created masterclass: {title[:40]}...')
        return masterclass

    def create_industry_offering(self, country_code, config, instructor, force=False):
        """Create industry training offering"""
        
        industry, _ = Industry.objects.get_or_create(
            name=f'{config["name"]} Tech Industry',
            defaults={'description': f'Tech industry for {config["name"]}'}
        )
        
        title = f'{config["name"]} Tech Skills Programme'
        
        offering, _ = Offering.objects.get_or_create(
            name=title,
            defaults={
                'description': f'Tech skills training for {config["name"]}',
                'industry': industry,
                'price_usd': 150,
            }
        )
        
        self.stdout.write(f'  ✓ Created industry training: {title[:40]}...')
        return offering

    def enroll_student(self, student, instructor, learnership, masterclass, industry_offering,
                      country_code, config, country):
        """Enroll student in all pathways with payments"""
        
        enrollments = []
        
        # 1. Learnership Enrollment
        provider = random.choice([config['primary_provider'], config['secondary_provider']])
        payment = PaymentTransaction.objects.create(
            user=student,
            amount=25000 if config['currency'] == 'KES' else 250,
            currency=config['currency'],
            provider=provider,
            status=PaymentStatus.SUCCESSFUL,
            transaction_type=TransactionType.PURCHASE,
            provider_reference=f'LP-{country_code}-{student.id}-{timezone.now().strftime("%Y%m%d%H%M%S")}',
            country=country_code,
            phone_number=student.phone,
            metadata={'pathway': 'learnership', 'instructor': instructor.id},
            completed_at=timezone.now(),
        )
        
        enrollment = LearnershipEnrollment.objects.create(
            programme=learnership,
            user=student,
            status=EnrollmentStatus.CONFIRMED,
            enrollment_type='individual',
            payment_transaction=payment,
            payment_status='paid',
            amount_paid=payment.amount,
            currency=config['currency'],
            total_amount=payment.amount,
            payment_plan_type='full',
            race=random.choice(['Black African', 'Coloured', 'Indian/Asian', 'White']),
            employment_status=random.choice(['employed', 'unemployed', 'student']),
            nationality=country_code,
            highest_qualification=random.choice(['Grade 12', 'Diploma', 'Bachelor\'s Degree']),
            qualification_institution=f'Test Institution {config["name"]}',
            qualification_year=str(random.randint(2018, 2024)),
            next_of_kin_name=f'Next of Kin {student.first_name}',
            next_of_kin_phone=f'{config["phone_prefix"]}7{random.randint(10000000, 99999999)}',
            next_of_kin_relationship='Parent/Guardian',
            next_of_kin_email=f'nextofkin.{student.username}@test.com',
            medical_conditions='None declared',
            allergies='None declared',
            accessibility_needs='None',
            requires_learning_support='no',
            has_id_copy=True,
            has_qualification_certificates=True,
            has_proof_of_residence=True,
            has_cv=True,
            has_motivational_letter=True,
            funding_source='self_funded',
            requires_debit_order='no',
            terms_accepted=True,
            data_protection_accepted=True,
            certification_declaration_accepted=True,
            seta_declaration_accepted=True,
            prerequisites_verified=True,
            verified_by=instructor,
            verified_at=timezone.now(),
            metadata={'instructor': instructor.id, 'test_enrollment': True},
        )
        enrollments.append(('Learnership', enrollment.programme.title, float(payment.amount), config['currency'], provider.label))
        
        # 2. Masterclass Enrollment
        provider = random.choice([config['primary_provider'], config['secondary_provider']])
        payment = PaymentTransaction.objects.create(
            user=student,
            amount=5000 if config['currency'] == 'KES' else 50,
            currency=config['currency'],
            provider=provider,
            status=PaymentStatus.SUCCESSFUL,
            transaction_type=TransactionType.PURCHASE,
            provider_reference=f'MC-{country_code}-{student.id}-{timezone.now().strftime("%Y%m%d%H%M%S")}',
            metadata={'pathway': 'masterclass', 'instructor': instructor.id},
            completed_at=timezone.now(),
        )
        
        enrollment = ProvisionalEnrollment.objects.create(
            user=student,
            enrollment_type='masterclass',
            status='confirmed',
            payment_transaction=payment,
            metadata={
                'training_id': masterclass.id,
                'training_title': masterclass.title,
                'payment_provider': provider.label,
                'instructor': instructor.id,
                'test_enrollment': True,
            }
        )
        enrollments.append(('Masterclass', masterclass.title, float(payment.amount), config['currency'], provider.label))
        
        # 3. Industry Training Enrollment
        provider = random.choice([config['primary_provider'], config['secondary_provider']])
        payment = PaymentTransaction.objects.create(
            user=student,
            amount=150,
            currency='USD',
            provider=provider,
            status=PaymentStatus.SUCCESSFUL,
            transaction_type=TransactionType.PURCHASE,
            provider_reference=f'IT-{country_code}-{student.id}-{timezone.now().strftime("%Y%m%d%H%M%S")}',
            metadata={'pathway': 'industry', 'instructor': instructor.id},
            completed_at=timezone.now(),
        )
        
        enrollment = ProvisionalEnrollment.objects.create(
            user=student,
            enrollment_type='industry',
            status='confirmed',
            payment_transaction=payment,
            metadata={
                'training_id': industry_offering.id,
                'training_title': industry_offering.name,
                'payment_provider': provider.label,
                'instructor': instructor.id,
                'test_enrollment': True,
            }
        )
        enrollments.append(('Industry Training', industry_offering.name, float(payment.amount), 'USD', provider.label))
        
        self.stdout.write(f'    ✓ Enrolled in 3 pathways (Instructor: {instructor.username})')
        
        return {
            'type': 'student',
            'country': config['name'],
            'username': student.username,
            'email': student.email,
            'password': f'{country_code}Student{enrollments[0][1].split()[-1] if "Student" in enrollments[0][1] else "1"}@2026'.replace(config['name'], str([e for e in range(1,4) if f'student_{country_code.lower()}_{e:03d}' == student.username][0])),
            'role': 'Student',
            'instructor': instructor.username,
            'enrollments': enrollments,
        }

    def save_credentials(self, all_credentials, output_file):
        """Save all credentials to file"""
        
        with open(output_file, 'w') as f:
            f.write('=' * 80 + '\n')
            f.write('HOSI ACADEMY - COMPLETE TEST ENVIRONMENT CREDENTIALS\n')
            f.write(f'Generated: {timezone.now().strftime("%Y-%m-%d %H:%M:%S")}\n')
            f.write('=' * 80 + '\n\n')
            
            f.write('SYSTEM ADMIN (All Countries)\n')
            f.write('-' * 80 + '\n')
            f.write('Username: system_admin\n')
            f.write('Password: System@Hosi2026!\n')
            f.write('Access: Full system access - All countries\n\n')
            
            # Group by country
            countries = {}
            for cred in all_credentials:
                if cred['country'] not in countries:
                    countries[cred['country']] = []
                countries[cred['country']].append(cred)
            
            for country, creds in countries.items():
                f.write(f'\n{country}\n')
                f.write('=' * 80 + '\n')
                
                # Instructors
                instructors = [c for c in creds if c['type'] == 'instructor']
                for inst in instructors:
                    f.write(f'\nINSTRUCTOR\n')
                    f.write(f'  Username: {inst["username"]}\n')
                    f.write(f'  Email: {inst["email"]}\n')
                    f.write(f'  Password: {inst["password"]}\n')
                    f.write(f'  Role: {inst["role"]}\n')
                    f.write(f'  Dashboard: /instructor/dashboard\n')
                
                # Students
                students = [c for c in creds if c['type'] == 'student']
                for stud in students:
                    f.write(f'\nSTUDENT\n')
                    f.write(f'  Username: {stud["username"]}\n')
                    f.write(f'  Email: {stud["email"]}\n')
                    f.write(f'  Password: {stud["password"]}\n')
                    f.write(f'  Role: {stud["role"]}\n')
                    f.write(f'  Assigned Instructor: {stud["instructor"]}\n')
                    f.write(f'  Dashboard: /dashboard\n')
                    f.write(f'  Enrollments:\n')
                    for pathway, title, amount, currency, provider in stud['enrollments']:
                        f.write(f'    - {pathway}: {amount} {currency} ({provider})\n')
            
            f.write('\n' + '=' * 80 + '\n')
            f.write('DASHBOARD URLS\n')
            f.write('=' * 80 + '\n')
            f.write('Student Dashboard: http://localhost:7000/dashboard\n')
            f.write('Instructor Dashboard: http://localhost:7000/instructor/dashboard\n')
            f.write('Admin Dashboard: http://localhost:7000/admin/dashboard\n')
            f.write('\n' + '=' * 80 + '\n')
        
        self.stdout.write(self.style.SUCCESS(f'  ✓ Credentials saved to: {output_file}'))
