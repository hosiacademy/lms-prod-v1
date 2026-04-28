# Generated migration for Instructor Hours Claims models

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import uuid


class Migration(migrations.Migration):

    dependencies = [
        ('instructors', '0010_instructor_instructoractivitylog_instructorrating_and_more'),
        ('localization', '0002_publicholiday_localizedgreeting_holidaymessage_and_more'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='InstructorHoursClaim',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('claim_id', models.CharField(editable=False, max_length=50, unique=True, verbose_name='Claim ID')),
                ('month', models.PositiveIntegerField(choices=[(1, 'January'), (2, 'February'), (3, 'March'), (4, 'April'), (5, 'May'), (6, 'June'), (7, 'July'), (8, 'August'), (9, 'September'), (10, 'October'), (11, 'November'), (12, 'December')], verbose_name='Month')),
                ('year', models.PositiveIntegerField(verbose_name='Year')),
                ('regular_hours', models.DecimalField(decimal_places=2, default=0.0, max_digits=8, verbose_name='Regular Hours')),
                ('overtime_hours', models.DecimalField(decimal_places=2, default=0.0, max_digits=8, verbose_name='Overtime Hours')),
                ('total_hours', models.DecimalField(editable=False, max_digits=8, decimal_places=2, verbose_name='Total Hours')),
                ('hourly_rate', models.DecimalField(decimal_places=2, max_digits=10, verbose_name='Hourly Rate')),
                ('overtime_rate_multiplier', models.DecimalField(decimal_places=2, default=1.5, max_digits=3, verbose_name='Overtime Rate Multiplier')),
                ('regular_pay', models.DecimalField(editable=False, max_digits=10, decimal_places=2, verbose_name='Regular Pay')),
                ('overtime_pay', models.DecimalField(editable=False, max_digits=10, decimal_places=2, verbose_name='Overtime Pay')),
                ('total_claim_amount', models.DecimalField(editable=False, max_digits=10, decimal_places=2, verbose_name='Total Claim Amount')),
                ('session_ids', models.JSONField(default=list, verbose_name='Session IDs')),
                ('session_breakdown', models.JSONField(default=list, verbose_name='Session Breakdown')),
                ('overtime_justification', models.TextField(blank=True, null=True, verbose_name='Overtime Justification')),
                ('overtime_supporting_documents', models.FileField(blank=True, null=True, upload_to='instructor_overtime_supporting/', verbose_name='Supporting Documents')),
                ('status', models.CharField(choices=[('draft', 'Draft'), ('pending', 'Pending Review'), ('under_review', 'Under Review'), ('approved', 'Approved'), ('rejected', 'Rejected'), ('paid', 'Paid')], default='draft', max_length=20, verbose_name='Status')),
                ('submitted_at', models.DateTimeField(blank=True, null=True, verbose_name='Submitted At')),
                ('reviewed_at', models.DateTimeField(blank=True, null=True, verbose_name='Reviewed At')),
                ('approval_notes', models.TextField(blank=True, null=True, verbose_name='Approval Notes')),
                ('rejection_reason', models.TextField(blank=True, null=True, verbose_name='Rejection Reason')),
                ('paid_at', models.DateTimeField(blank=True, null=True, verbose_name='Paid At')),
                ('payment_reference', models.CharField(blank=True, max_length=255, null=True, verbose_name='Payment Reference')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created At')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Updated At')),
                ('instructor', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='hours_claims', to='instructors.instructor', verbose_name='Instructor')),
                ('reviewed_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='reviewed_hours_claims', to=settings.AUTH_USER_MODEL, verbose_name='Reviewed By (HR Admin)')),
            ],
            options={
                'verbose_name': 'Instructor Hours Claim',
                'verbose_name_plural': 'Instructor Hours Claims',
                'db_table': 'instructor_hours_claims',
                'ordering': ['-year', '-month', '-created_at'],
                'indexes': [
                    models.Index(fields=['instructor', 'year', 'month'], name='instructor__instructo_b6c0d7_idx'),
                    models.Index(fields=['status', 'submitted_at'], name='instructor__status_9a0c3b_idx'),
                    models.Index(fields=['year', 'month'], name='instructor__year_mo_8f3d2e_idx'),
                ],
            },
        ),
        migrations.CreateModel(
            name='InstructorOvertime',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('overtime_id', models.CharField(editable=False, max_length=50, unique=True, verbose_name='Overtime ID')),
                ('overtime_date', models.DateField(verbose_name='Overtime Date')),
                ('hours_requested', models.DecimalField(decimal_places=2, max_digits=5, verbose_name='Hours Requested')),
                ('reason', models.TextField(verbose_name='Reason for Overtime')),
                ('supporting_document', models.FileField(blank=True, null=True, upload_to='instructor_overtime/', verbose_name='Supporting Document')),
                ('status', models.CharField(choices=[('pending', 'Pending'), ('approved', 'Approved'), ('rejected', 'Rejected')], default='pending', max_length=20, verbose_name='Status')),
                ('reviewed_at', models.DateTimeField(blank=True, null=True, verbose_name='Reviewed At')),
                ('approval_notes', models.TextField(blank=True, null=True, verbose_name='Approval Notes')),
                ('rejection_reason', models.TextField(blank=True, null=True, verbose_name='Rejection Reason')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created At')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Updated At')),
                ('instructor', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='overtime_requests', to='instructors.instructor', verbose_name='Instructor')),
                ('hours_claim', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='overtime_requests', to='instructors.instructorhoursclaim', verbose_name='Linked Hours Claim')),
                ('reviewed_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='reviewed_overtime_requests', to=settings.AUTH_USER_MODEL, verbose_name='Reviewed By')),
            ],
            options={
                'verbose_name': 'Instructor Overtime Request',
                'verbose_name_plural': 'Instructor Overtime Requests',
                'db_table': 'instructor_overtime',
                'ordering': ['-overtime_date', '-created_at'],
                'indexes': [
                    models.Index(fields=['instructor', 'status'], name='instructor__instructo_c4e5f2_idx'),
                    models.Index(fields=['overtime_date'], name='instructor__overtime_a8b3c1_idx'),
                ],
            },
        ),
        migrations.CreateModel(
            name='InstructorPayrollSummary',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('month', models.PositiveIntegerField(verbose_name='Month')),
                ('year', models.PositiveIntegerField(verbose_name='Year')),
                ('total_instructors', models.PositiveIntegerField(default=0, verbose_name='Total Instructors')),
                ('total_regular_hours', models.DecimalField(decimal_places=2, default=0.0, max_digits=10, verbose_name='Total Regular Hours')),
                ('total_overtime_hours', models.DecimalField(decimal_places=2, default=0.0, max_digits=10, verbose_name='Total Overtime Hours')),
                ('total_payroll_amount', models.DecimalField(decimal_places=2, default=0.0, max_digits=12, verbose_name='Total Payroll Amount')),
                ('total_paid_amount', models.DecimalField(decimal_places=2, default=0.0, max_digits=12, verbose_name='Total Paid Amount')),
                ('total_pending_amount', models.DecimalField(decimal_places=2, default=0.0, max_digits=12, verbose_name='Total Pending Amount')),
                ('total_claims', models.PositiveIntegerField(default=0, verbose_name='Total Claims')),
                ('approved_claims', models.PositiveIntegerField(default=0, verbose_name='Approved Claims')),
                ('pending_claims', models.PositiveIntegerField(default=0, verbose_name='Pending Claims')),
                ('processed_at', models.DateTimeField(blank=True, null=True, verbose_name='Processed At')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created At')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Updated At')),
                ('processed_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='processed_payroll_summaries', to=settings.AUTH_USER_MODEL, verbose_name='Processed By (HR Admin)')),
            ],
            options={
                'verbose_name': 'Instructor Payroll Summary',
                'verbose_name_plural': 'Instructor Payroll Summaries',
                'db_table': 'instructor_payroll_summaries',
                'ordering': ['-year', '-month'],
                'unique_together': {('month', 'year')},
            },
        ),
    ]
