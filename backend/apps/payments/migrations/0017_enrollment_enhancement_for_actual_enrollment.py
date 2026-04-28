# Generated migration to align Enrollment model with actual enrollment process
# Adds SETA compliance, next of kin, medical, banking, and declaration fields
# to match the comprehensive LearnershipEnrollment model

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0016_exchange_rate'),
    ]

    operations = [
        # ===== ACADEMIC & EMPLOYMENT INFORMATION (For SETA Compliance) =====
        migrations.AddField(
            model_name='enrollment',
            name='highest_qualification',
            field=models.CharField(blank=True, max_length=255, null=True, help_text='Highest qualification obtained'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='qualification_institution',
            field=models.CharField(blank=True, max_length=255, null=True, help_text='Institution where qualification was obtained'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='qualification_year',
            field=models.CharField(blank=True, max_length=10, null=True, help_text='Year of qualification'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='employer',
            field=models.CharField(blank=True, max_length=255, null=True, help_text='Current employer'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='job_title',
            field=models.CharField(blank=True, max_length=255, null=True, help_text='Current job title'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='employment_status',
            field=models.CharField(
                blank=True,
                max_length=50,
                null=True,
                choices=[
                    ('employed', 'Employed'),
                    ('unemployed', 'Unemployed'),
                    ('student', 'Student'),
                    ('self_employed', 'Self Employed'),
                ],
                help_text='Employment status for reporting'
            ),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='monthly_income',
            field=models.CharField(blank=True, max_length=50, null=True, help_text='Monthly income range for SETA reporting'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='existing_skills',
            field=models.TextField(blank=True, null=True, help_text='Existing skills and competencies'),
        ),

        # ===== DEMOGRAPHICS (For SETA/Employment Equity Reporting) =====
        migrations.AddField(
            model_name='enrollment',
            name='race',
            field=models.CharField(blank=True, max_length=50, null=True, help_text='Race/ethnicity for employment equity reporting'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='disability',
            field=models.CharField(
                blank=True,
                max_length=10,
                null=True,
                choices=[('yes', 'Yes'), ('no', 'No')],
                help_text='Disability status for reporting'
            ),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='nationality',
            field=models.CharField(blank=True, max_length=100, null=True, help_text='Student nationality'),
        ),

        # ===== NEXT OF KIN / EMERGENCY CONTACT (Enhanced) =====
        # Note: Basic emergency contact fields already exist, adding comprehensive next of kin
        migrations.AddField(
            model_name='enrollment',
            name='next_of_kin_name',
            field=models.CharField(blank=True, max_length=255, null=True, help_text='Next of kin full name'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='next_of_kin_phone',
            field=models.CharField(blank=True, max_length=50, null=True, help_text='Next of kin phone number'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='next_of_kin_relationship',
            field=models.CharField(blank=True, max_length=100, null=True, help_text='Relationship to next of kin'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='next_of_kin_email',
            field=models.EmailField(blank=True, max_length=254, null=True, help_text='Next of kin email address'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='next_of_kin_address',
            field=models.TextField(blank=True, null=True, help_text='Next of kin physical address'),
        ),

        # ===== MEDICAL & ACCESSIBILITY =====
        migrations.AddField(
            model_name='enrollment',
            name='medical_conditions',
            field=models.TextField(blank=True, null=True, help_text='Medical conditions that may affect learning'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='allergies',
            field=models.TextField(blank=True, null=True, help_text='Known allergies'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='medications',
            field=models.TextField(blank=True, null=True, help_text='Current medications'),
        ),
        # accessibility_needs already exists, but we'll enhance it
        migrations.AlterField(
            model_name='enrollment',
            name='accessibility_needs',
            field=models.TextField(blank=True, null=True, help_text='Special accessibility requirements or accommodations needed'),
        ),

        # ===== LEARNING SUPPORT =====
        migrations.AddField(
            model_name='enrollment',
            name='requires_learning_support',
            field=models.CharField(
                blank=True,
                max_length=10,
                null=True,
                choices=[('yes', 'Yes'), ('no', 'No')],
                help_text='Whether learner requires additional learning support'
            ),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='learning_support_details',
            field=models.TextField(blank=True, null=True, help_text='Details of required learning support'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='has_previous_learnership_experience',
            field=models.CharField(
                blank=True,
                max_length=10,
                null=True,
                choices=[('yes', 'Yes'), ('no', 'No')],
                help_text='Whether learner has previous learnership experience'
            ),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='previous_learnership_details',
            field=models.TextField(blank=True, null=True, help_text='Details of previous learnership experience'),
        ),

        # ===== DOCUMENTATION CHECKLIST =====
        migrations.AddField(
            model_name='enrollment',
            name='has_id_copy',
            field=models.BooleanField(default=False, help_text='ID copy received'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='has_qualification_certificates',
            field=models.BooleanField(default=False, help_text='Qualification certificates received'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='has_proof_of_residence',
            field=models.BooleanField(default=False, help_text='Proof of residence received'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='has_cv',
            field=models.BooleanField(default=False, help_text='CV received'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='has_motivational_letter',
            field=models.BooleanField(default=False, help_text='Motivational letter received'),
        ),

        # ===== PAYMENT & FUNDING =====
        migrations.AddField(
            model_name='enrollment',
            name='funding_source',
            field=models.CharField(
                blank=True,
                max_length=50,
                null=True,
                choices=[
                    ('self_funded', 'Self Funded'),
                    ('company_funded', 'Company Funded'),
                    ('seta', 'SETA'),
                    ('nsfas', 'NSFAS'),
                    ('other', 'Other'),
                ],
                help_text='Source of funding for this enrollment'
            ),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='company_vat_number',
            field=models.CharField(blank=True, max_length=100, null=True, help_text='Company VAT/Tax number'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='purchase_order_number',
            field=models.CharField(blank=True, max_length=100, null=True, help_text='Purchase order number for corporate enrollments'),
        ),

        # ===== DEBIT ORDER DETAILS =====
        migrations.AddField(
            model_name='enrollment',
            name='requires_debit_order',
            field=models.CharField(
                blank=True,
                max_length=10,
                null=True,
                choices=[('yes', 'Yes'), ('no', 'No')],
                help_text='Whether learner requires debit order payment plan'
            ),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='bank_name',
            field=models.CharField(blank=True, max_length=100, null=True, help_text='Bank name for debit orders'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='bank_account_number',
            field=models.CharField(blank=True, max_length=50, null=True, help_text='Bank account number for debit orders'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='bank_branch_code',
            field=models.CharField(blank=True, max_length=20, null=True, help_text='Bank branch code'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='bank_account_type',
            field=models.CharField(
                blank=True,
                max_length=20,
                null=True,
                choices=[
                    ('savings', 'Savings'),
                    ('cheque', 'Cheque/Current'),
                ],
                help_text='Type of bank account'
            ),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='bank_account_holder_name',
            field=models.CharField(blank=True, max_length=255, null=True, help_text='Name on the bank account'),
        ),

        # ===== LEGAL DECLARATIONS =====
        migrations.AddField(
            model_name='enrollment',
            name='data_protection_accepted',
            field=models.BooleanField(default=False, help_text='POPIA/GDPR data protection declaration accepted'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='certification_declaration_accepted',
            field=models.BooleanField(default=False, help_text='Certification terms and conditions accepted'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='seta_declaration_accepted',
            field=models.BooleanField(default=False, help_text='SETA compliance declaration accepted'),
        ),

        # ===== ADDITIONAL FIELDS =====
        migrations.AddField(
            model_name='enrollment',
            name='referral_source',
            field=models.CharField(blank=True, max_length=255, null=True, help_text='How did the learner hear about us'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='prerequisites_verified',
            field=models.BooleanField(default=False, help_text='Whether prerequisites have been verified'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='verification_notes',
            field=models.TextField(blank=True, null=True, help_text='Admin notes on prerequisite verification'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='verified_by',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=models.deletion.SET_NULL,
                related_name='verified_enrollments',
                to='users.user',
                help_text='User who verified the prerequisites',
            ),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='verified_at',
            field=models.DateTimeField(blank=True, null=True, help_text='When prerequisites were verified'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='confirmed_at',
            field=models.DateTimeField(blank=True, null=True, help_text='When enrollment was confirmed'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='dropped_out_at',
            field=models.DateTimeField(blank=True, null=True, help_text='When learner dropped out'),
        ),

        # ===== ADD INDEXES FOR PERFORMANCE =====
        migrations.AddIndex(
            model_name='enrollment',
            index=models.Index(fields=['status', 'created_at'], name='enrollments_status_created_idx'),
        ),
        migrations.AddIndex(
            model_name='enrollment',
            index=models.Index(fields=['user', 'status'], name='enrollments_user_status_idx'),
        ),
        migrations.AddIndex(
            model_name='enrollment',
            index=models.Index(fields=['enrollment_type', 'status'], name='enrollments_type_status_idx'),
        ),
    ]
