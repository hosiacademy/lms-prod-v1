# Generated manually for industry/role training pathway
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0021_admin_chat_system'),
    ]

    operations = [
        migrations.AddField(
            model_name='enrollment',
            name='aicerts_enrollment_id',
            field=models.IntegerField(blank=True, default=0, null=True, help_text='FK to aicerts_enrollments.id', verbose_name='AICerts Enrollment ID'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='industry_enrollment_id',
            field=models.IntegerField(blank=True, default=0, null=True, help_text='FK to industry_based_training_industrytrainingenrollment.id', verbose_name='Industry Enrollment ID'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='learnership_enrollment_id',
            field=models.IntegerField(blank=True, default=0, null=True, help_text='FK to learnerships_learnershipenrollment.id', verbose_name='Learnership Enrollment ID'),
        ),
        migrations.AddField(
            model_name='enrollment',
            name='masterclass_enrollment_id',
            field=models.IntegerField(blank=True, default=0, null=True, help_text='FK to masterclasses_masterclassenrollment.id', verbose_name='Masterclass Enrollment ID'),
        ),
        migrations.AddIndex(
            model_name='enrollment',
            index=models.Index(fields=['aicerts_enrollment_id'], name='payments_en_aicerts_e4f5c2_idx'),
        ),
        migrations.AddIndex(
            model_name='enrollment',
            index=models.Index(fields=['industry_enrollment_id'], name='payments_en_industr_2a3f1a_idx'),
        ),
        migrations.AddIndex(
            model_name='enrollment',
            index=models.Index(fields=['learnership_enrollment_id'], name='payments_en_learners_e9d2b8_idx'),
        ),
        migrations.AddIndex(
            model_name='enrollment',
            index=models.Index(fields=['masterclass_enrollment_id'], name='payments_en_masterc_7c4d91_idx'),
        ),
    ]
