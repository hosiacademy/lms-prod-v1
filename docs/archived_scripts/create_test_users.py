#!/usr/bin/env python
"""
Create Test Users: Instructor Takawira Mazando and 5 African Students
Usage: python manage.py shell < create_test_users.py
"""
import os
import sys
import django

# Setup Django
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from django.contrib.auth import get_user_model
from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment
from apps.payments.models import Order, PaymentTransaction
from apps.localization.models import Country

User = get_user_model()

print('='*70)
print('📝 CREATING TEST USERS - TAKAWIRA & AFRICAN STUDENTS')
print('='*70)

# =====================================================
# STEP 1: Get Countries
# =====================================================
print('\n📍 Loading countries...')
countries = {c.code: c for c in Country.objects.filter(code__in=['ZW', 'KE', 'ZA', 'ZM'])}

if not countries:
    print('⚠️  No countries found. Creating...')
    # Create countries if they don't exist
    country_data = [
        {'code': 'ZW', 'name': 'Zimbabwe'},
        {'code': 'KE', 'name': 'Kenya'},
        {'code': 'ZA', 'name': 'South Africa'},
        {'code': 'ZM', 'name': 'Zambia'},
    ]
    for data in country_data:
        country, _ = Country.objects.get_or_create(code=data['code'], defaults={'name': data['name']})
        countries[data['code']] = country
    print(f'✓ Created {len(countries)} countries')
else:
    print(f'✓ Found {len(countries)} countries')

# =====================================================
# STEP 2: Create Instructor - Takawira Mazando
# =====================================================
print('\n👨‍🏫 Creating Instructor: Takawira Mazando')
instructor, created = User.objects.get_or_create(
    username='takawira.mazando',
    defaults={
        'email': 'takawira.mazando@hosiacademy.co.za',
        'first_name': 'Takawira',
        'last_name': 'Mazando',
        'name': 'Takawira Mazando',
        'role_id': 2,  # Instructor
        'is_staff': False,
        'is_active': True,
        'country': countries.get('ZW'),
    }
)
if created:
    instructor.set_password('Instructor@2026!')
    instructor.save()
    print(f'✓ Created Instructor: {instructor.name} (ID: {instructor.id})')
else:
    print(f'✓ Instructor exists: {instructor.name} (ID: {instructor.id})')

# =====================================================
# STEP 3: Create 5 African Students
# =====================================================
print('\n👥 Creating 5 African Students')

students_data = [
    {
        'username': 'tariro.moyo.zimbabwe',
        'email': 'tariro.moyo.zimbabwe@learner.hosiacademy.co.za',
        'first_name': 'Tariro',
        'last_name': 'Moyo',
        'name': 'Tariro Moyo',
        'country_code': 'ZW',
        'timezone': 'Africa/Harare',
    },
    {
        'username': 'wanjiru.omondi.kenya',
        'email': 'wanjiru.omondi.kenya@learner.hosiacademy.co.za',
        'first_name': 'Wanjiru',
        'last_name': 'Omondi',
        'name': 'Wanjiru Omondi',
        'country_code': 'KE',
        'timezone': 'Africa/Nairobi',
    },
    {
        'username': 'thabo.dlamini.southafrica',
        'email': 'thabo.dlamini.southafrica@learner.hosiacademy.co.za',
        'first_name': 'Thabo',
        'last_name': 'Dlamini',
        'name': 'Thabo Dlamini',
        'country_code': 'ZA',
        'timezone': 'Africa/Johannesburg',
    },
    {
        'username': 'chanda.mwanza.zambia',
        'email': 'chanda.mwanza.zambia@learner.hosiacademy.co.za',
        'first_name': 'Chanda',
        'last_name': 'Mwanza',
        'name': 'Chanda Mwanza',
        'country_code': 'ZM',
        'timezone': 'Africa/Lusaka',
    },
    {
        'username': 'mulenga.phiri.zambia',
        'email': 'mulenga.phiri.zambia@learner.hosiacademy.co.za',
        'first_name': 'Mulenga',
        'last_name': 'Phiri',
        'name': 'Mulenga Phiri',
        'country_code': 'ZM',
        'timezone': 'Africa/Lusaka',
    },
]

students = []
for data in students_data:
    country_code = data.pop('country_code')
    student, created = User.objects.get_or_create(
        username=data['username'],
        defaults={
            **data,
            'role_id': 3,  # Student/Learner
            'is_staff': False,
            'is_active': True,
            'country': countries.get(country_code),
        }
    )
    if created:
        student.set_password('Student@2026!')
        student.save()
        print(f'✓ Created: {student.name} ({student.country.name}) - ID: {student.id}')
    else:
        print(f'✓ Exists: {student.name} ({student.country.name}) - ID: {student.id}')
    students.append(student)

# =====================================================
# STEP 4: Get Learnership Programmes
# =====================================================
print('\n📚 Loading Learnership Programmes')
programmes = list(LearnershipProgramme.objects.all()[:4])
if not programmes:
    print('⚠️  No learnership programmes found. Creating sample programmes...')
    # Create sample programmes if none exist
    programme_titles = [
        'AI Developer / Machine Learning Engineer Learnership',
        'AI Engineer / Deep Learning Specialist Learnership',
        'Cloud AI Engineer / MLOps Specialist Learnership',
        'Data Scientist / AI Data Engineer Learnership',
    ]
    for title in programme_titles:
        p, _ = LearnershipProgramme.objects.get_or_create(
            title=title,
            defaults={
                'description': f'Comprehensive {title} programme',
                'duration_months': 12,
            }
        )
        programmes.append(p)
    print(f'✓ Created {len(programmes)} programmes')
else:
    print(f'✓ Found {len(programmes)} programmes')

for p in programmes:
    print(f'   - {p.title} (ID: {p.id})')

# =====================================================
# STEP 5: Create Enrollments (Students -> Programmes)
# =====================================================
print('\n📝 Creating Enrollments')
enrollment_count = 0
for student in students:
    for programme in programmes:
        enrollment, created = LearnershipEnrollment.objects.get_or_create(
            user=student,
            programme=programme,
            defaults={
                'active': True,
            }
        )
        if created:
            enrollment_count += 1
    print(f'✓ {student.name}: Enrolled in {len(programmes)} programmes')

print(f'\n✓ Total enrollments created: {enrollment_count}')

# =====================================================
# STEP 6: Summary
# =====================================================
print('\n' + '='*70)
print('✅ TEST DATA CREATION COMPLETE')
print('='*70)

# Verify Instructor
print(f'\n👨‍🏫 Instructor:')
print(f'   Name: {instructor.name}')
print(f'   Email: {instructor.email}')
print(f'   Role ID: {instructor.role_id}')
print(f'   Country: {instructor.country.name if instructor.country else "N/A"}')
print(f'   Password: Instructor@2026!')

# Verify Students
print(f'\n👥 Students:')
for student in students:
    enrollments = LearnershipEnrollment.objects.filter(user=student, active=True)
    print(f'   • {student.name}')
    print(f'     - Email: {student.email}')
    print(f'     - Country: {student.country.name}')
    print(f'     - Role ID: {student.role_id}')
    print(f'     - Enrollments: {enrollments.count()}')
    print(f'     - Password: Student@2026!')

print('\n' + '='*70)
print('🎉 All test users created successfully!')
print('='*70)
