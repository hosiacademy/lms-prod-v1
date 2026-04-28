"""
State-only migration: adds student_id, payment_gateway, payment_gateway_metadata
to LearnershipEnrollment model. All columns already exist in the DB.
"""
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('learnerships', '0016_alter_learnershipenrollment_status'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[],
            state_operations=[
                migrations.AddField(
                    model_name='learnershipenrollment',
                    name='student_id',
                    field=models.BigIntegerField(blank=True, null=True, help_text='FK to learner_portal_studentprofile.id'),
                ),
                migrations.AddField(
                    model_name='learnershipenrollment',
                    name='payment_gateway',
                    field=models.CharField(blank=True, max_length=100, null=True),
                ),
                migrations.AddField(
                    model_name='learnershipenrollment',
                    name='payment_gateway_metadata',
                    field=models.JSONField(blank=True, default=dict, null=True),
                ),
            ],
        ),
    ]
