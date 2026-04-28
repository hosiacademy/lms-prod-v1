#!/usr/bin/env python
"""
Management command to create proper payment records for students.
Business flow: Payment MUST come BEFORE enrollment.

Usage:
    python manage.py create_student_payments
"""

from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import datetime, timedelta
import uuid
import json

from apps.users.models import User
from apps.learnerships.models import LearnershipProgramme, LearnershipEnrollment
from apps.payments.models import Order
from django.db import connection


class Command(BaseCommand):
    help = 'Create payment records for students enrolled in learnerships'

    def handle(self, *args, **kwargs):
        self.stdout.write('='*70)
        self.stdout.write('💳 CREATING PAYMENT RECORDS FOR STUDENTS (Payment → Enrollment)')
        self.stdout.write('='*70)

        # The 5 African students
        student_emails = [
            'tariro.moyo.zimbabwe@learner.hosiacademy.co.za',
            'wanjiru.omondi.kenya@learner.hosiacademy.co.za',
            'thabo.dlamini.southafrica@learner.hosiacademy.co.za',
            'chanda.mwanza.zambia@learner.hosiacademy.co.za',
            'mulenga.phiri.zambia@learner.hosiacademy.co.za',
        ]

        # Takawira's learnerships (IDs 7-10)
        programme_ids = [7, 8, 9, 10]
        
        # Get programmes
        programmes = LearnershipProgramme.objects.filter(id__in=programme_ids)
        programme_map = {p.id: p for p in programmes}
        
        self.stdout.write(f'\n📚 Learnerships: {programmes.count()}')
        for p in programmes:
            instructor_name = p.instructor.name if p.instructor else 'Unassigned'
            self.stdout.write(f'   - {p.title} (Instructor: {instructor_name})')

        # Get students
        students = User.objects.filter(email__in=student_emails)
        self.stdout.write(f'\n👥 Students: {students.count()}')
        
        total_orders = 0
        total_payments = 0
        total_enrollments = 0
        
        for student in students:
            self.stdout.write(f'\n{"="*70}')
            self.stdout.write(f'🎓 {student.name} ({student.email})')
            self.stdout.write(f'   Country: {student.country.name if student.country else "N/A"}')
            
            # Create payment and enrollment for each programme
            base_date = datetime(2026, 3, 1, 10, 0, 0)
            minutes_offset = 0
            
            for programme in programmes:
                # Calculate price based on programme
                price = programme.cost_usd if programme.cost_usd else 299.00
                
                # STEP 1: Create Order (payment intent)
                order_date = base_date + timedelta(minutes=minutes_offset)
                order = Order.objects.create(
                    user=student,
                    tracking=f'TRK-{student.id}-{programme.id}-{uuid.uuid4().hex[:6].upper()}',
                    amount=price,
                    currency='USD',
                    status='completed',
                    payment_method='card',
                    metadata={
                        'programme_id': programme.id,
                        'programme_title': programme.title,
                        'instructor_id': programme.instructor.id if programme.instructor else None,
                        'instructor_name': programme.instructor.name if programme.instructor else None,
                        'student_country': student.country.code if student.country else 'N/A',
                        'enrollment_type': 'learnership',
                        'payment_flow': 'payment_first',
                    }
                )
                total_orders += 1
                
                # STEP 2: Create PaymentTransaction (successful payment) - Using raw SQL
                payment_date = order_date + timedelta(minutes=5)
                provider_ref = f'pi_{uuid.uuid4().hex[:20]}'
                
                metadata_json = json.dumps({
                    'programme_id': programme.id,
                    'programme_title': programme.title,
                    'instructor_id': programme.instructor.id if programme.instructor else None,
                    'instructor_name': programme.instructor.name if programme.instructor else None,
                    'student_country': student.country.code if student.country else 'N/A',
                    'payment_flow': 'payment_first',
                    'flow_description': 'Payment processed BEFORE enrollment confirmation',
                })
                
                with connection.cursor() as cursor:
                    cursor.execute("""
                        INSERT INTO payment_transactions (
                            user_id, order_id, amount, currency, transaction_type,
                            provider, provider_reference, provider_method, description,
                            status, metadata, webhook_received, reconciled,
                            created_at, updated_at, user_agent, country, phone_number
                        ) VALUES (
                            %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
                        ) RETURNING id
                    """, [
                        student.id, order.id, price, 'USD', 'purchase',
                        'stripe', provider_ref, 'card', f'Payment for {programme.title}',
                        'successful', metadata_json, True, True, payment_date, payment_date,
                        'Mozilla/5.0 (Management Command)', student.country.code if student.country else 'ZW',
                        '+263771234567'
                    ])
                    payment_id = cursor.fetchone()[0]
                total_payments += 1
                
                # STEP 3: Create enrollment AFTER successful payment (correct business flow)
                enrollment, created = LearnershipEnrollment.objects.get_or_create(
                    user=student,
                    programme=programme,
                    defaults={'active': True}
                )
                
                if created:
                    total_enrollments += 1
                else:
                    # Re-activate if it existed
                    enrollment.active = True
                    enrollment.save()
                
                minutes_offset += 10
                
                self.stdout.write(f'   ✓ Order #{order.id} + Payment #{payment_id} → Enrollment #{enrollment.id} for {programme.title} (${price})')
        
        self.stdout.write(f'\n{"="*70}')
        self.stdout.write('✅ PAYMENT RECORDS CREATED SUCCESSFULLY')
        self.stdout.write(f'{"="*70}')
        self.stdout.write(f'📊 Summary:')
        self.stdout.write(f'   Total Orders: {total_orders}')
        self.stdout.write(f'   Total Payments: {total_payments}')
        self.stdout.write(f'   Total Enrollments: {total_enrollments}')
        self.stdout.write(f'   Payment Success Rate: 100%')
        self.stdout.write(f'\n💡 Business Flow: Payment → Enrollment (CORRECT)')
        self.stdout.write(f'   1. Student initiates purchase (Order created)')
        self.stdout.write(f'   2. Student pays (PaymentTransaction created with status=successful)')
        self.stdout.write(f'   3. ONLY after successful payment, enrollment is created')
