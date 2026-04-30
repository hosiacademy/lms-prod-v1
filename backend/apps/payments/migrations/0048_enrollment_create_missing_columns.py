"""
Migration 0048: Actually create the 48 columns in the 'enrollments' table
that were added to Django's state in migration 0027 (state-only) but never
written to the actual database with ALTER TABLE.
"""
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0047_delete_exchangerate_delete_exchangeratelog'),
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        # Employment & Qualifications
        migrations.AddField(model_name='enrollment', name='highest_qualification',
            field=models.CharField(blank=True, max_length=255, null=True, verbose_name='Highest Qualification')),
        migrations.AddField(model_name='enrollment', name='qualification_institution',
            field=models.CharField(blank=True, max_length=255, null=True, verbose_name='Institution')),
        migrations.AddField(model_name='enrollment', name='qualification_year',
            field=models.CharField(blank=True, max_length=10, null=True, verbose_name='Qualification Year')),
        migrations.AddField(model_name='enrollment', name='employer',
            field=models.CharField(blank=True, max_length=255, null=True, verbose_name='Employer')),
        migrations.AddField(model_name='enrollment', name='job_title',
            field=models.CharField(blank=True, max_length=255, null=True, verbose_name='Job Title')),
        migrations.AddField(model_name='enrollment', name='employment_status',
            field=models.CharField(blank=True, max_length=50, null=True, verbose_name='Employment Status')),
        migrations.AddField(model_name='enrollment', name='monthly_income',
            field=models.CharField(blank=True, max_length=50, null=True, verbose_name='Monthly Income')),
        migrations.AddField(model_name='enrollment', name='existing_skills',
            field=models.TextField(blank=True, null=True, verbose_name='Existing Skills')),

        # Demographics
        migrations.AddField(model_name='enrollment', name='race',
            field=models.CharField(blank=True, max_length=50, null=True, verbose_name='Race')),
        migrations.AddField(model_name='enrollment', name='disability',
            field=models.CharField(blank=True, max_length=10, null=True, verbose_name='Disability')),
        migrations.AddField(model_name='enrollment', name='nationality',
            field=models.CharField(blank=True, max_length=100, null=True, verbose_name='Nationality')),

        # Next of Kin
        migrations.AddField(model_name='enrollment', name='next_of_kin_name',
            field=models.CharField(blank=True, max_length=255, null=True, verbose_name='Next of Kin Name')),
        migrations.AddField(model_name='enrollment', name='next_of_kin_phone',
            field=models.CharField(blank=True, max_length=50, null=True, verbose_name='Next of Kin Phone')),
        migrations.AddField(model_name='enrollment', name='next_of_kin_relationship',
            field=models.CharField(blank=True, max_length=100, null=True, verbose_name='Next of Kin Relationship')),
        migrations.AddField(model_name='enrollment', name='next_of_kin_email',
            field=models.EmailField(blank=True, max_length=254, null=True, verbose_name='Next of Kin Email')),
        migrations.AddField(model_name='enrollment', name='next_of_kin_address',
            field=models.TextField(blank=True, null=True, verbose_name='Next of Kin Address')),

        # Medical & Accessibility
        migrations.AddField(model_name='enrollment', name='medical_conditions',
            field=models.TextField(blank=True, null=True, verbose_name='Medical Conditions')),
        migrations.AddField(model_name='enrollment', name='allergies',
            field=models.TextField(blank=True, null=True, verbose_name='Allergies')),
        migrations.AddField(model_name='enrollment', name='medications',
            field=models.TextField(blank=True, null=True, verbose_name='Medications')),
        migrations.AddField(model_name='enrollment', name='requires_learning_support',
            field=models.CharField(blank=True, max_length=10, null=True, verbose_name='Requires Learning Support')),
        migrations.AddField(model_name='enrollment', name='learning_support_details',
            field=models.TextField(blank=True, null=True, verbose_name='Learning Support Details')),

        # Learnership History
        migrations.AddField(model_name='enrollment', name='has_previous_learnership_experience',
            field=models.CharField(blank=True, max_length=10, null=True, verbose_name='Previous Learnership Experience')),
        migrations.AddField(model_name='enrollment', name='previous_learnership_details',
            field=models.TextField(blank=True, null=True, verbose_name='Previous Learnership Details')),

        # Documentation Checklist
        migrations.AddField(model_name='enrollment', name='has_id_copy',
            field=models.BooleanField(default=False, verbose_name='Has ID Copy')),
        migrations.AddField(model_name='enrollment', name='has_qualification_certificates',
            field=models.BooleanField(default=False, verbose_name='Has Qualification Certificates')),
        migrations.AddField(model_name='enrollment', name='has_proof_of_residence',
            field=models.BooleanField(default=False, verbose_name='Has Proof of Residence')),
        migrations.AddField(model_name='enrollment', name='has_cv',
            field=models.BooleanField(default=False, verbose_name='Has CV')),
        migrations.AddField(model_name='enrollment', name='has_motivational_letter',
            field=models.BooleanField(default=False, verbose_name='Has Motivational Letter')),

        # Funding & Banking
        migrations.AddField(model_name='enrollment', name='funding_source',
            field=models.CharField(blank=True, max_length=50, null=True, verbose_name='Funding Source')),
        migrations.AddField(model_name='enrollment', name='company_vat_number',
            field=models.CharField(blank=True, max_length=100, null=True, verbose_name='Company VAT Number')),
        migrations.AddField(model_name='enrollment', name='purchase_order_number',
            field=models.CharField(blank=True, max_length=100, null=True, verbose_name='Purchase Order Number')),
        migrations.AddField(model_name='enrollment', name='requires_debit_order',
            field=models.CharField(blank=True, max_length=10, null=True, verbose_name='Requires Debit Order')),
        migrations.AddField(model_name='enrollment', name='bank_name',
            field=models.CharField(blank=True, max_length=100, null=True, verbose_name='Bank Name')),
        migrations.AddField(model_name='enrollment', name='bank_account_number',
            field=models.CharField(blank=True, max_length=50, null=True, verbose_name='Bank Account Number')),
        migrations.AddField(model_name='enrollment', name='bank_branch_code',
            field=models.CharField(blank=True, max_length=20, null=True, verbose_name='Bank Branch Code')),
        migrations.AddField(model_name='enrollment', name='bank_account_type',
            field=models.CharField(blank=True, max_length=20, null=True, verbose_name='Bank Account Type')),
        migrations.AddField(model_name='enrollment', name='bank_account_holder_name',
            field=models.CharField(blank=True, max_length=255, null=True, verbose_name='Bank Account Holder Name')),

        # Declarations
        migrations.AddField(model_name='enrollment', name='data_protection_accepted',
            field=models.BooleanField(default=False, verbose_name='Data Protection Accepted')),
        migrations.AddField(model_name='enrollment', name='certification_declaration_accepted',
            field=models.BooleanField(default=False, verbose_name='Certification Declaration Accepted')),
        migrations.AddField(model_name='enrollment', name='seta_declaration_accepted',
            field=models.BooleanField(default=False, verbose_name='SETA Declaration Accepted')),
        migrations.AddField(model_name='enrollment', name='referral_source',
            field=models.CharField(blank=True, max_length=255, null=True, verbose_name='Referral Source')),

        # Verification Workflow
        migrations.AddField(model_name='enrollment', name='prerequisites_verified',
            field=models.BooleanField(default=False, verbose_name='Prerequisites Verified')),
        migrations.AddField(model_name='enrollment', name='verification_notes',
            field=models.TextField(blank=True, null=True, verbose_name='Verification Notes')),
        migrations.AddField(model_name='enrollment', name='verified_by',
            field=models.ForeignKey(blank=True, db_column='verified_by_id', null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='verified_enrollments', to=settings.AUTH_USER_MODEL,
                verbose_name='Verified By')),
        migrations.AddField(model_name='enrollment', name='verified_at',
            field=models.DateTimeField(blank=True, null=True, verbose_name='Verified At')),
        migrations.AddField(model_name='enrollment', name='confirmed_at',
            field=models.DateTimeField(blank=True, null=True, verbose_name='Confirmed At')),
        migrations.AddField(model_name='enrollment', name='dropped_out_at',
            field=models.DateTimeField(blank=True, null=True, verbose_name='Dropped Out At')),
        migrations.AddField(model_name='enrollment', name='provider_id',
            field=models.BigIntegerField(blank=True, null=True, verbose_name='Provider ID')),
    ]
