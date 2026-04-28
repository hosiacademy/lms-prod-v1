# Generated migration for Learnership Enrollment enhancement
# Adds status tracking, corporate fields, evidence tracking, and audit trail

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('learnerships', '0009_learnershipprogramme_instructor'),
        ('payments', '0013_alter_order_user_paymentreference_enrollment_and_more'),
        ('localization', '0009_alter_city_options_state_alter_city_unique_together_and_more'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        # Create new EnrollmentStatus choices enum (stored as CharField)
        migrations.AddField(
            model_name='learnershipenrollment',
            name='status',
            field=models.CharField(
                choices=[
                    ('provisional', 'Provisional (Payment Pending)'),
                    ('pending_evidence', 'Pending Evidence Upload'),
                    ('evidence_submitted', 'Evidence Submitted'),
                    ('under_review', 'Under Review'),
                    ('confirmed', 'Confirmed (Prerequisites Met)'),
                    ('rejected', 'Rejected (Prerequisites Not Met)'),
                    ('refunded', 'Refunded'),
                    ('expired', 'Expired'),
                    ('active', 'Active (Learning in Progress)'),
                    ('completed', 'Completed'),
                    ('dropped_out', 'Dropped Out'),
                ],
                default='provisional',
                help_text='Current enrollment status in the learnership pathway',
                max_length=20
            ),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='enrollment_type',
            field=models.CharField(
                choices=[
                    ('individual', 'Individual Enrollment'),
                    ('corporate', 'Corporate Enrollment'),
                ],
                default='individual',
                max_length=20
            ),
        ),
        # Corporate enrollment fields
        migrations.AddField(
            model_name='learnershipenrollment',
            name='company_name',
            field=models.CharField(blank=True, max_length=255),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='company_registration_number',
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='company_tax_number',
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='company_contact_person',
            field=models.CharField(blank=True, max_length=255),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='company_email',
            field=models.EmailField(blank=True, max_length=254),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='company_phone',
            field=models.CharField(blank=True, max_length=50),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='company_address',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='company_country',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='corporate_learnership_enrollments',
                to='localization.country'
            ),
        ),
        # Payment tracking
        migrations.AddField(
            model_name='learnershipenrollment',
            name='payment_transaction',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='learnership_enrollments',
                to='payments.paymenttransaction'
            ),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='payment_status',
            field=models.CharField(
                choices=[
                    ('pending', 'Pending'),
                    ('cash_promise', 'Cash Promise (To Pay at Office)'),
                    ('partial_paid', 'Partially Paid (Deposit + Debit Order)'),
                    ('paid', 'Paid in Full'),
                    ('refunded', 'Refunded'),
                    ('failed', 'Failed'),
                    ('debit_order_active', 'Debit Order Active'),
                ],
                default='pending',
                max_length=30
            ),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='amount_paid',
            field=models.DecimalField(
                blank=True,
                decimal_places=2,
                max_digits=10,
                null=True
            ),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='currency',
            field=models.CharField(default='USD', max_length=3),
        ),
        # Debit Order fields
        migrations.AddField(
            model_name='learnershipenrollment',
            name='debit_order_reference',
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='debit_order_start_date',
            field=models.DateField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='debit_order_amount',
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=10, null=True, help_text='Monthly debit order amount'),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='debit_order_active',
            field=models.BooleanField(default=False),
        ),
        # Cash Payment fields
        migrations.AddField(
            model_name='learnershipenrollment',
            name='cash_payment_reference',
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='cash_payment_due_date',
            field=models.DateField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='cash_payment_office',
            field=models.CharField(blank=True, max_length=255, help_text='Office location where cash payment should be made'),
        ),
        # Payment Plan fields
        migrations.AddField(
            model_name='learnershipenrollment',
            name='payment_plan_type',
            field=models.CharField(default='full', max_length=30, choices=[('full', 'Full Payment'), ('deposit_debit', 'Deposit + Debit Order'), ('cash_office', 'Cash at Office')]),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='total_amount',
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=10, null=True),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='deposit_paid',
            field=models.DecimalField(blank=True, decimal_places=2, max_digits=10, null=True),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='installments_remaining',
            field=models.PositiveIntegerField(default=0),
        ),
        # Prerequisites verification
        migrations.AddField(
            model_name='learnershipenrollment',
            name='prerequisites_verified',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='verification_notes',
            field=models.TextField(
                blank=True,
                help_text='Admin notes on prerequisite verification'
            ),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='verified_by',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='verified_learnership_enrollments',
                to=settings.AUTH_USER_MODEL
            ),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='verified_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        # Timeline fields
        migrations.AddField(
            model_name='learnershipenrollment',
            name='confirmed_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='started_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='completed_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='dropped_out_at',
            field=models.DateTimeField(blank=True, null=True),
        ),
        # Metadata
        migrations.AddField(
            model_name='learnershipenrollment',
            name='metadata',
            field=models.JSONField(blank=True, default=dict),
        ),
        # Create PrerequisiteEvidence model
        migrations.CreateModel(
            name='PrerequisiteEvidence',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('prerequisite_key', models.CharField(help_text='Index or key of the prerequisite in programme.prerequisites list', max_length=100)),
                ('prerequisite_name', models.CharField(help_text='Human-readable name of the prerequisite', max_length=255)),
                ('evidence_file', models.FileField(help_text='Uploaded document proving prerequisite completion', upload_to='learnerships/evidence/%Y/%m/%d/')),
                ('file_type', models.CharField(blank=True, max_length=50)),
                ('file_size', models.PositiveIntegerField(blank=True, null=True)),
                ('evidence_description', models.TextField(blank=True, help_text="Learner's description of the uploaded evidence")),
                ('status', models.CharField(
                    choices=[
                        ('pending_submission', 'Pending Submission'),
                        ('submitted', 'Submitted'),
                        ('pending_review', 'Pending Review'),
                        ('approved', 'Approved'),
                        ('rejected', 'Rejected (Resubmission Required)'),
                    ],
                    default='pending_submission',
                    max_length=20
                )),
                ('reviewed_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='reviewed_evidences', to=settings.AUTH_USER_MODEL)),
                ('reviewed_at', models.DateTimeField(blank=True, null=True)),
                ('review_notes', models.TextField(blank=True, help_text='Admin notes on why evidence was approved/rejected')),
                ('uploaded_at', models.DateTimeField(auto_now_add=True)),
                ('resubmission_count', models.PositiveIntegerField(default=0)),
                ('enrollment', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='prerequisite_evidences', to='learnerships.learnershipenrollment')),
            ],
            options={
                'verbose_name': 'Prerequisite Evidence',
                'verbose_name_plural': 'Prerequisite Evidences',
                'ordering': ['enrollment', 'prerequisite_key'],
                'unique_together': {('enrollment', 'prerequisite_key')},
            },
        ),
        # Create EnrollmentStatusHistory model
        migrations.CreateModel(
            name='EnrollmentStatusHistory',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('from_status', models.CharField(max_length=20)),
                ('to_status', models.CharField(max_length=20)),
                ('changed_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, to=settings.AUTH_USER_MODEL)),
                ('reason', models.TextField(blank=True)),
                ('changed_at', models.DateTimeField(auto_now_add=True)),
                ('enrollment', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='status_history', to='learnerships.learnershipenrollment')),
            ],
            options={
                'verbose_name': 'Enrollment Status History',
                'verbose_name_plural': 'Enrollment Status Histories',
                'ordering': ['-changed_at'],
            },
        ),
        # Add indexes for performance
        migrations.AddIndex(
            model_name='learnershipenrollment',
            index=models.Index(fields=['status', 'enrolled_at'], name='learnership_status_enroll_idx'),
        ),
        migrations.AddIndex(
            model_name='learnershipenrollment',
            index=models.Index(fields=['user', 'status'], name='learnership_user_status_idx'),
        ),
        migrations.AddIndex(
            model_name='learnershipenrollment',
            index=models.Index(fields=['programme', 'status'], name='learnership_prog_status_idx'),
        ),
    ]
