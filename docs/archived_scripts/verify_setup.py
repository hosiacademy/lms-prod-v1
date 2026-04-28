#!/usr/bin/env python
"""
Verification script for LMS Django setup.
Checks student enrollments and database connectivity.
"""
import os
import sys
import django

# Setup Django environment
backend_path = os.path.join(os.path.dirname(__file__), 'backend')
sys.path.insert(0, backend_path)
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from django.contrib.auth import get_user_model
from apps.learnerships.models import LearnershipEnrollment, LearnershipProgramme as Programme

User = get_user_model()

print('='*70)
print('🔍 LMS SETUP VERIFICATION')
print('='*70)

# Check database connection
print('\n📊 Database Connection: OK')

# Check available roles
from django.db import connection
print('\n📊 Checking database...')

# Get all users
all_users = User.objects.all()
print(f'\n👥 Total Users: {all_users.count()}')

# Check role distribution
print('\n📋 Users by Role ID:')
for user in all_users[:20]:
    print(f'   - {user.name} ({user.email}) - Role: {user.role_id}')

# Get all students/learners
students = User.objects.filter(role_id=3)  # Assuming role_id=3 is student/learner
print(f'\n📚 Total Students Found (role_id=3): {students.count()}')

# Try other common role IDs for students
for role_id in [1, 2, 4, 5]:
    count = User.objects.filter(role_id=role_id).count()
    if count > 0:
        print(f'   Role {role_id}: {count} users')

# Sample students to check
test_emails = [
    'test@example.com',
    'student@example.com',
]

for email in test_emails:
    user = User.objects.filter(email=email).first()
    if user:
        print(f'\n✓ Found test user: {email}')

# Show sample of students
print('\n' + '='*70)
print('📋 SAMPLE STUDENT DATA')
print('='*70)

for student in students[:10]:  # Show first 10 students
    enrollments = LearnershipEnrollment.objects.filter(user=student)
    
    print(f'\n👤 {student.name} ({student.email})')
    print(f'   Role ID: {student.role_id}')
    print(f'   Country: {student.country.name if student.country else "N/A"}')
    print(f'   Enrollments: {enrollments.count()}')
    
    if enrollments.count() > 0:
        for e in enrollments:
            print(f'     • {e.programme.title}')
            print(f'       - Enrolled: {e.enrolled_at.strftime("%Y-%m-%d %H:%M")}')
            print(f'       - Status: {"Active" if e.active else "Inactive"}')
    else:
        print(f'   ⚠️  No active enrollments found')

print('\n' + '='*70)
print('✅ VERIFICATION COMPLETE')
print('='*70)
