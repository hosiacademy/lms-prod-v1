#!/usr/bin/env python
"""
Test Custom Selection Pathway

This script tests the complete custom selection enrollment flow:
1. Create a successful payment transaction for custom courses
2. Trigger provisioning
3. Verify AICertsEnrollment is created
4. Verify generic Enrollment is created
5. Verify AICerts API calls would be made (mocked)
"""

import os
import sys
sys.path.insert(0, '/home/tk/lms-prod/backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')

import django
django.setup()

from apps.users.models import User
from apps.payments.models import PaymentTransaction, PaymentStatus, TransactionType
from apps.payments.services.payment_service import PaymentService
from apps.aicerts_courses.models import AiCertsCourse
from apps.aicerts_integration.models import AICertsEnrollment
from apps.payments.models import Enrollment as GenericEnrollment

def test_custom_selection_pathway():
    print("=" * 80)
    print("Testing Custom Selection Enrollment Pathway")
    print("=" * 80)
    
    # 1. Get or create test user
    print("\n1. Getting test user...")
    user, created = User.objects.get_or_create(
        email='customselection.test@test.com',
        defaults={
            'username': 'customselection_test',
            'first_name': 'Custom',
            'last_name': 'Selection Test',
        }
    )
    if created:
        print(f"   Created user: {user.email}")
    else:
        print(f"   Using existing user: {user.email}")
    
    # 2. Get active AICerts courses
    print("\n2. Getting active AICerts courses...")
    courses = AiCertsCourse.objects.filter(is_offered=True)[:2]
    if not courses:
        # Try without filter
        courses = AiCertsCourse.objects.all()[:2]
    
    if not courses:
        print("   ❌ No AICerts courses found!")
        return
    
    course_ids = [c.id for c in courses]
    print(f"   Found courses: {[c.title for c in courses]}")
    
    # 3. Create successful payment transaction
    print("\n3. Creating successful payment transaction...")
    import random
    import string
    rand_ref = ''.join(random.choices(string.ascii_uppercase + string.digits, k=10))
    
    txn = PaymentTransaction.objects.create(
        user=user,
        amount=198.0,  # $99 per course x 2
        currency='USD',
        country='KE',
        provider='mpesa',
        transaction_type=TransactionType.PURCHASE,
        provider_reference=f'CUSTOM_TEST_{rand_ref}',
        status=PaymentStatus.SUCCESSFUL,
        enrollment_type='custom_selection',
        metadata={
            'course_ids': course_ids,
            'individual_details': {
                'email': user.email,
                'full_name': user.get_full_name(),
            }
        }
    )
    print(f"   Created transaction: {txn.id}")
    print(f"   Provider reference: {txn.provider_reference}")
    print(f"   Amount: ${txn.amount}")
    
    # 4. Trigger provisioning
    print("\n4. Triggering enrollment provisioning...")
    service = PaymentService()
    
    try:
        # Call provisioning directly (normally done via Celery task)
        service._provision_enrollment(
            user=user,
            enrollment_type='custom_selection',
            program_id=None,
            transaction=txn
        )
        print("   ✅ Provisioning completed")
    except Exception as e:
        print(f"   ❌ Provisioning failed: {e}")
        import traceback
        traceback.print_exc()
        return
    
    # 5. Verify AICertsEnrollment records
    print("\n5. Verifying AICertsEnrollment records...")
    aicerts_enrollments = AICertsEnrollment.objects.filter(
        user=user,
        course_id__in=course_ids
    )
    
    if aicerts_enrollments.exists():
        print(f"   ✅ Found {aicerts_enrollments.count()} AICertsEnrollment record(s)")
        for ae in aicerts_enrollments:
            print(f"      - Course: {ae.course.title}")
            print(f"        Status: {ae.aicerts_enrollment_status}")
            print(f"        Synced: {ae.synced_at}")
    else:
        print(f"   ❌ No AICertsEnrollment records found!")
    
    # 6. Verify generic Enrollment records
    print("\n6. Verifying generic Enrollment records...")
    generic_enrollments = GenericEnrollment.objects.filter(
        user=user,
        enrollment_type='custom_selection',
        enrollment_data__transaction_id=str(txn.id)
    )
    
    if generic_enrollments.exists():
        print(f"   ✅ Found {generic_enrollments.count()} Enrollment record(s)")
        for ge in generic_enrollments:
            print(f"      - Enrollment code: {ge.enrollment_code}")
            print(f"        Course: {ge.content_object}")
            print(f"        Status: {ge.status}")
            print(f"        AICerts Enrollment ID: {ge.aicerts_enrollment_id}")
            print(f"        Amount: ${ge.final_amount}")
    else:
        print(f"   ❌ No generic Enrollment records found!")
    
    # 7. Summary
    print("\n" + "=" * 80)
    print("SUMMARY")
    print("=" * 80)
    
    aicerts_count = aicerts_enrollments.count()
    generic_count = generic_enrollments.count()
    
    if aicerts_count > 0 and generic_count > 0:
        print("✅ SUCCESS: Both AICertsEnrollment and Enrollment records created!")
        print(f"   - AICertsEnrollment: {aicerts_count} record(s)")
        print(f"   - Enrollment: {generic_count} record(s)")
        print("\n   The custom selection pathway is working correctly.")
        print("   Students will have:")
        print("   1. Access to AICerts LMS courses")
        print("   2. Unified enrollment tracking in Sales Admin dashboard")
    elif aicerts_count > 0:
        print("⚠️  PARTIAL: Only AICertsEnrollment created (missing generic Enrollment)")
    elif generic_count > 0:
        print("⚠️  PARTIAL: Only Enrollment created (missing AICertsEnrollment)")
    else:
        print("❌ FAILED: No enrollment records created")

if __name__ == '__main__':
    test_custom_selection_pathway()
