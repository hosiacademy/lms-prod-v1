"""
Test actual enrollment workflow against database schema.
Creates realistic test enrollments following the actual enrollment process.

This tests:
1. Student registration with full demographic data
2. Programme selection
3. Payment pathway (country-specific providers)
4. Prerequisites verification
5. Enrollment confirmation
6. SETA/reporting compliance data

Usage:
    python manage.py test_enrollment_workflow
"""
import random
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
from django.utils import timezone
from django.db import transaction
from apps.localization.models import Country
from apps.payments.models import PaymentTransaction, PaymentProvider, TransactionType, PaymentStatus
from apps.learnerships.models import (
    LearnershipProgramme, 
    LearnershipEnrollment, 
    EnrollmentStatus,
    PrerequisiteEvidence
)
from apps.masterclasses.models import Masterclass
from apps.enrollments.models import ProvisionalEnrollment
from apps.industry_based_training.models import Industry, Offering

User = get_user_model()


class Command(BaseCommand):
    help = 'Test actual enrollment workflow with database schema'

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

    # Realistic student data for testing
    STUDENT_DATA_TEMPLATES = {
        'demographics': {
            'race': ['Black African', 'Coloured', 'Indian/Asian', 'White'],
            'employment_status': ['employed', 'unemployed', 'student', 'self_employed'],
            'education_level': ['Grade 12', 'Diploma', 'Bachelor\'s Degree', 'Honours', 'Master\'s'],
            'funding_source': ['self_funded', 'company_funded', 'seta', 'nsfas'],
        }
    }

    def add_arguments(self, parser):
        parser.add_argument('--force', action='store_true', help='Recreate if exists')
        parser.add_argument('--country', type=str, help='Test specific country only')

    @transaction.atomic
    def handle(self, *args, **options):
        force = options.get('force', False)
        specific_country = options.get('country')
        
        self.stdout.write(self.style.SUCCESS('=' * 80))
        self.stdout.write(self.style.SUCCESS('ENROLLMENT WORKFLOW TEST'))
        self.stdout.write(self.style.SUCCESS('Testing Database Schema Against Actual Enrollment Process'))
        self.stdout.write(self.style.SUCCESS('=' * 80))
        self.stdout.write('')
        
        # Test enrollment workflow for each country
        countries_to_test = {k: v for k, v in self.COUNTRIES_CONFIG.items()}
        if specific_country:
            countries_to_test = {specific_country: self.COUNTRIES_CONFIG[specific_country]}
        
        for country_code, config in countries_to_test.items():
            self.test_country_enrollments(country_code, config, force)
        
        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('=' * 80))
        self.stdout.write(self.style.SUCCESS('WORKFLOW TEST COMPLETE'))
        self.stdout.write(self.style.SUCCESS('=' * 80))

    def test_country_enrollments(self, country_code, config, force=False):
        """Test complete enrollment workflow for a country"""
        
        self.stdout.write(self.style.SUCCESS(f'\n{"="*80}'))
        self.stdout.write(self.style.SUCCESS(f'Testing: {config["name"]} ({country_code})'))
        self.stdout.write(self.style.SUCCESS(f'{"="*80}'))
        
        country, _ = Country.objects.get_or_create(
            code=country_code,
            defaults={'name': config['name'], 'is_active': True}
        )
        
        # Create test student
        student = self.create_test_student(country_code, config, country, force)
        if not student:
            return
        
        # Test different enrollment pathways
        self.test_learnership_enrollment(student, country_code, config, force)
        self.test_masterclass_enrollment(student, country_code, config, force)
        self.test_industry_enrollment(student, country_code, config, force)
        
        # Display enrollment summary
        self.display_enrollment_summary(student, country_code)

    def create_test_student(self, country_code, config, country, force=False):
        """Create test student with realistic demographic data"""
        
        student_num = random.randint(1000, 9999)
        username = f'test_student_{country_code.lower()}_{student_num}'
        email = f'test.{student_num}.{country_code.lower()}@test.hosi.academy'
        password = f'Test@{country_code}{student_num}'
        phone = f'{config["phone_prefix"]}7{random.randint(10000000, 99999999)}'
        
        # Check if exists
        if not force and User.objects.filter(username=username).exists():
            self.stdout.write(self.style.WARNING(f'  • Student exists: {username}'))
            return User.objects.get(username=username)
        
        # Create student with realistic data
        first_name = f'Student{student_num}'
        last_name = config['name']
        
        student = User.objects.create_user(
            username=username,
            email=email,
            password=password,
            role_id=3,
            name=f'{first_name} {last_name}',
            first_name=first_name,
            last_name=last_name,
            country=country,
            phone=phone,
            email_verified_at=timezone.now(),
            address=f'{random.randint(1, 999)} Test Street, {config["name"]} City',
            # Note: state and city require State/City model instances
            # For testing, we leave them null and use address field instead
        )
        
        self.stdout.write(self.style.SUCCESS(f'  ✓ Created student: {username}'))
        return student

    def test_learnership_enrollment(self, student, country_code, config, force=False):
        """Test complete learnership enrollment workflow"""
        
        self.stdout.write('\n  Testing Learnership Enrollment...')
        
        # Step 1: Create/get learnership programme
        programme, _ = LearnershipProgramme.objects.get_or_create(
            title=f'Test Learnership - {config["name"]}',
            defaults={
                'description': f'Test learnership programme for {config["name"]}',
                'specialization': 'Business Administration',
                'start_date': timezone.now() + timedelta(days=30),
                'end_date': timezone.now() + timedelta(days=365),
                'price': 25000 if config['currency'] == 'KES' else 250,
                'currency': config['currency'],
            }
        )
        
        # Step 2: Simulate payment (following actual payment workflow)
        provider = random.choice([config['primary_provider'], config['secondary_provider']])
        transaction_ref = f'LP-{country_code}-{timezone.now().strftime("%Y%m%d%H%M%S")}'
        
        payment = PaymentTransaction.objects.create(
            user=student,
            amount=25000 if config['currency'] == 'KES' else 250,
            currency=config['currency'],
            provider=provider,
            status=PaymentStatus.SUCCESSFUL,
            transaction_type=TransactionType.PURCHASE,
            provider_reference=transaction_ref,
            country=country_code,
            phone_number=student.phone,
            metadata={
                'test_enrollment': True,
                'pathway': 'learnership',
                'payment_method': provider.label,
            },
            completed_at=timezone.now(),
        )
        
        self.stdout.write(f'    ✓ Payment: {payment.amount} {config["currency"]} via {provider.label}')

        # Step 3: Create enrollment with ALL required demographic/compliance fields
        # This tests if the schema supports actual enrollment data capture
        enrollment = LearnershipEnrollment.objects.create(
            programme=programme,
            user=student,
            status=EnrollmentStatus.PROVISIONAL,
            enrollment_type='individual',
            
            # Payment details
            payment_transaction=payment,
            payment_status='paid',
            amount_paid=payment.amount,
            currency=config['currency'],
            total_amount=payment.amount,
            payment_plan_type='full',
            
            # Demographics (SETA compliance)
            race=random.choice(self.STUDENT_DATA_TEMPLATES['demographics']['race']),
            employment_status=random.choice(self.STUDENT_DATA_TEMPLATES['demographics']['employment_status']),
            nationality=country_code,
            
            # Academic information
            highest_qualification=random.choice(self.STUDENT_DATA_TEMPLATES['demographics']['education_level']),
            qualification_institution=f'Test Institution {config["name"]}',
            qualification_year=str(random.randint(2018, 2024)),
            education_level=random.choice(self.STUDENT_DATA_TEMPLATES['demographics']['education_level']),
            
            # Contact & Emergency
            next_of_kin_name=f'Next of Kin {student.first_name}',
            next_of_kin_phone=f'{config["phone_prefix"]}7{random.randint(10000000, 99999999)}',
            next_of_kin_relationship='Parent/Guardian',
            next_of_kin_email=f'nextofkin.{student.username}@test.com',
            next_of_kin_address=student.address or f'{random.randint(1, 999)} Kin Street, {config["name"]}',
            
            # Medical & Accessibility
            medical_conditions='None declared',
            allergies='None declared',
            medications='None',
            accessibility_needs='None',
            
            # Learning support
            requires_learning_support='no',
            has_previous_learnership_experience=random.choice(['yes', 'no']),
            
            # Documentation checklist
            has_id_copy=True,
            has_qualification_certificates=True,
            has_proof_of_residence=True,
            has_cv=True,
            has_motivational_letter=True,
            
            # Funding
            funding_source=random.choice(self.STUDENT_DATA_TEMPLATES['demographics']['funding_source']),
            
            # Debit order (if applicable)
            requires_debit_order='no',
            
            # Declarations
            terms_accepted=True,
            data_protection_accepted=True,
            certification_declaration_accepted=True,
            seta_declaration_accepted=True,
            
            # Prerequisites verification
            prerequisites_verified=True,
            verification_notes='Test enrollment - prerequisites verified',
            verified_by=student,
            verified_at=timezone.now(),
            
            # Metadata
            metadata={
                'test_enrollment': True,
                'pathway': 'learnership',
                'enrollment_source': 'management_command',
                'country': country_code,
            }
        )
        
        self.stdout.write(f'    ✓ Enrollment created: {enrollment.status}')
        self.stdout.write(f'    ✓ Demographics captured: Race, Employment, Nationality')
        self.stdout.write(f'    ✓ Academic info: {enrollment.highest_qualification}')
        self.stdout.write(f'    ✓ Next of kin: {enrollment.next_of_kin_name}')
        self.stdout.write(f'    ✓ Documentation: ID, Certificates, CV, Motivation Letter')
        self.stdout.write(f'    ✓ Declarations: Terms, Data Protection, SETA')
        
        return enrollment

    def test_masterclass_enrollment(self, student, country_code, config, force=False):
        """Test masterclass enrollment via ProvisionalEnrollment"""
        
        self.stdout.write('\n  Testing Masterclass Enrollment...')
        
        # Create masterclass
        masterclass, _ = Masterclass.objects.get_or_create(
            title=f'Test Masterclass - {config["name"]}',
            defaults={
                'description': f'Test masterclass for {config["name"]}',
                'slug': f'test-mc-{country_code.lower()}-{timezone.now().strftime("%Y%m%d")}',
                'start_date': timezone.now() + timedelta(days=30),
                'end_date': timezone.now() + timedelta(days=32),
                'status': 'scheduled',
                'price': 5000 if config['currency'] == 'KES' else 50,
                'currency': config['currency'],
                'country_code': country_code,
                'country_name': config['name'],
            }
        )
        
        # Create payment
        provider = random.choice([config['primary_provider'], config['secondary_provider']])
        payment = PaymentTransaction.objects.create(
            user=student,
            amount=5000 if config['currency'] == 'KES' else 50,
            currency=config['currency'],
            provider=provider,
            status=PaymentStatus.SUCCESSFUL,
            transaction_type=TransactionType.PURCHASE,
            provider_reference=f'MC-{country_code}-{timezone.now().strftime("%Y%m%d%H%M%S")}',
            metadata={'test_enrollment': True, 'pathway': 'masterclass'},
            completed_at=timezone.now(),
        )
        
        # Create provisional enrollment
        enrollment = ProvisionalEnrollment.objects.create(
            user=student,
            enrollment_type='masterclass',
            status='confirmed',
            payment_transaction=payment,
            metadata={
                'training_id': masterclass.id,
                'training_title': masterclass.title,
                'payment_provider': provider.label,
                'test_enrollment': True,
            }
        )
        
        self.stdout.write(f'    ✓ Masterclass: {masterclass.title[:40]}...')
        self.stdout.write(f'    ✓ Payment: {payment.amount} {config["currency"]} via {provider.label}')
        self.stdout.write(f'    ✓ Enrollment status: {enrollment.status}')
        
        return enrollment

    def test_industry_enrollment(self, student, country_code, config, force=False):
        """Test industry specialised training enrollment"""
        
        self.stdout.write('\n  Testing Industry Training Enrollment...')
        
        # Create industry and offering
        industry, _ = Industry.objects.get_or_create(
            name=f'Test Industry - {config["name"]}',
            defaults={'description': f'Test industry for {config["name"]}'}
        )
        
        offering, _ = Offering.objects.get_or_create(
            name=f'Test Industry Training - {config["name"]}',
            defaults={
                'description': f'Test industry training for {config["name"]}',
                'industry': industry,
                'price_usd': 150,
            }
        )
        
        # Create payment
        provider = random.choice([config['primary_provider'], config['secondary_provider']])
        payment = PaymentTransaction.objects.create(
            user=student,
            amount=150,
            currency='USD',
            provider=provider,
            status=PaymentStatus.SUCCESSFUL,
            transaction_type=TransactionType.PURCHASE,
            provider_reference=f'IT-{country_code}-{timezone.now().strftime("%Y%m%d%H%M%S")}',
            metadata={'test_enrollment': True, 'pathway': 'industry'},
            completed_at=timezone.now(),
        )
        
        # Create provisional enrollment
        enrollment = ProvisionalEnrollment.objects.create(
            user=student,
            enrollment_type='industry',
            status='confirmed',
            payment_transaction=payment,
            metadata={
                'training_id': offering.id,
                'training_title': offering.name,
                'payment_provider': provider.label,
                'test_enrollment': True,
            }
        )
        
        self.stdout.write(f'    ✓ Industry Training: {offering.name[:40]}...')
        self.stdout.write(f'    ✓ Payment: {payment.amount} USD via {provider.label}')
        self.stdout.write(f'    ✓ Enrollment status: {enrollment.status}')
        
        return enrollment

    def display_enrollment_summary(self, student, country_code):
        """Display enrollment summary for student"""
        
        self.stdout.write(f'\n  {"="*60}')
        self.stdout.write(self.style.SUCCESS(f'  ENROLLMENT SUMMARY: {student.username}'))
        self.stdout.write(f'  {"="*60}')
        
        # Learnership enrollments
        lp_enrollments = LearnershipEnrollment.objects.filter(user=student)
        self.stdout.write(f'  Learnerships: {lp_enrollments.count()}')
        for lp in lp_enrollments:
            self.stdout.write(f'    - {lp.programme.title[:50]} ({lp.status})')
            self.stdout.write(f'      Payment: {lp.amount_paid} {lp.currency} ({lp.payment_status})')
            self.stdout.write(f'      Demographics: {lp.race}, {lp.employment_status}, {lp.nationality}')
            self.stdout.write(f'      Qualification: {lp.highest_qualification} ({lp.qualification_year})')
            self.stdout.write(f'      Next of Kin: {lp.next_of_kin_name} ({lp.next_of_kin_relationship})')
            self.stdout.write(f'      Documentation: ID={lp.has_id_copy}, Certs={lp.has_qualification_certificates}')
            self.stdout.write(f'      Declarations: Terms={lp.terms_accepted}, SETA={lp.seta_declaration_accepted}')
        
        # Provisional enrollments
        prov_enrollments = ProvisionalEnrollment.objects.filter(user=student)
        self.stdout.write(f'  Other Enrollments: {prov_enrollments.count()}')
        for prov in prov_enrollments:
            self.stdout.write(f'    - {prov.enrollment_type}: {prov.status}')
