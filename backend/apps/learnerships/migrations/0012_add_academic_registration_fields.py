# Migration for Comprehensive Academic Registration Form
# Adds all student detail fields required for learnerships

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('learnerships', '0011_alter_learnershipenrollment_options_and_more'),
    ]

    operations = [
        # ===== ACADEMIC & EMPLOYMENT INFORMATION =====
        migrations.AddField(
            model_name='learnershipenrollment',
            name='highest_qualification',
            field=models.CharField(blank=True, max_length=255),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='qualification_institution',
            field=models.CharField(blank=True, max_length=255),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='qualification_year',
            field=models.CharField(blank=True, max_length=10),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='education_level',
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='employer',
            field=models.CharField(blank=True, max_length=255),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='job_title',
            field=models.CharField(blank=True, max_length=255),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='employment_status',
            field=models.CharField(
                blank=True,
                max_length=50,
                choices=[
                    ('employed', 'Employed'),
                    ('unemployed', 'Unemployed'),
                    ('student', 'Student'),
                    ('self_employed', 'Self Employed'),
                ]
            ),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='monthly_income',
            field=models.CharField(blank=True, max_length=50, help_text='For SETA reporting'),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='existing_skills',
            field=models.TextField(blank=True),
        ),
        
        # ===== DEMOGRAPHICS (For SETA/Employment Equity Reporting) =====
        migrations.AddField(
            model_name='learnershipenrollment',
            name='race',
            field=models.CharField(blank=True, max_length=50),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='disability',
            field=models.CharField(
                blank=True,
                max_length=10,
                choices=[('yes', 'Yes'), ('no', 'No')]
            ),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='nationality',
            field=models.CharField(blank=True, max_length=100),
        ),
        
        # ===== NEXT OF KIN =====
        migrations.AddField(
            model_name='learnershipenrollment',
            name='next_of_kin_name',
            field=models.CharField(blank=True, max_length=255),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='next_of_kin_phone',
            field=models.CharField(blank=True, max_length=50),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='next_of_kin_relationship',
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='next_of_kin_email',
            field=models.EmailField(blank=True, max_length=254),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='next_of_kin_address',
            field=models.TextField(blank=True),
        ),
        
        # ===== MEDICAL & ACCESSIBILITY =====
        migrations.AddField(
            model_name='learnershipenrollment',
            name='medical_conditions',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='allergies',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='medications',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='accessibility_needs',
            field=models.TextField(blank=True),
        ),
        
        # ===== LEARNING SUPPORT =====
        migrations.AddField(
            model_name='learnershipenrollment',
            name='requires_learning_support',
            field=models.CharField(
                blank=True,
                max_length=10,
                choices=[('yes', 'Yes'), ('no', 'No')]
            ),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='learning_support_details',
            field=models.TextField(blank=True),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='has_previous_learnership_experience',
            field=models.CharField(
                blank=True,
                max_length=10,
                choices=[('yes', 'Yes'), ('no', 'No')]
            ),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='previous_learnership_details',
            field=models.TextField(blank=True),
        ),
        
        # ===== DOCUMENTATION CHECKLIST =====
        migrations.AddField(
            model_name='learnershipenrollment',
            name='has_id_copy',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='has_qualification_certificates',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='has_proof_of_residence',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='has_cv',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='has_motivational_letter',
            field=models.BooleanField(default=False),
        ),
        
        # ===== PAYMENT & FUNDING =====
        migrations.AddField(
            model_name='learnershipenrollment',
            name='funding_source',
            field=models.CharField(
                blank=True,
                max_length=50,
                choices=[
                    ('self_funded', 'Self Funded'),
                    ('company_funded', 'Company Funded'),
                    ('seta', 'SETA'),
                    ('nsfas', 'NSFAS'),
                    ('other', 'Other'),
                ]
            ),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='company_vat_number',
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='purchase_order_number',
            field=models.CharField(blank=True, max_length=100),
        ),
        
        # ===== DEBIT ORDER DETAILS =====
        migrations.AddField(
            model_name='learnershipenrollment',
            name='requires_debit_order',
            field=models.CharField(
                blank=True,
                max_length=10,
                choices=[('yes', 'Yes'), ('no', 'No')]
            ),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='bank_name',
            field=models.CharField(blank=True, max_length=100),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='bank_account_number',
            field=models.CharField(blank=True, max_length=50),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='bank_branch_code',
            field=models.CharField(blank=True, max_length=20),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='bank_account_type',
            field=models.CharField(
                blank=True,
                max_length=20,
                choices=[
                    ('savings', 'Savings'),
                    ('cheque', 'Cheque/Current'),
                ]
            ),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='bank_account_holder_name',
            field=models.CharField(blank=True, max_length=255),
        ),
        
        # ===== DECLARATIONS =====
        migrations.AddField(
            model_name='learnershipenrollment',
            name='terms_accepted',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='data_protection_accepted',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='certification_declaration_accepted',
            field=models.BooleanField(default=False),
        ),
        migrations.AddField(
            model_name='learnershipenrollment',
            name='seta_declaration_accepted',
            field=models.BooleanField(default=False),
        ),
        
        # ===== ADDITIONAL =====
        migrations.AddField(
            model_name='learnershipenrollment',
            name='referral_source',
            field=models.CharField(blank=True, max_length=255, help_text='How did you hear about us'),
        ),
    ]
