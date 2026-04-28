"""
State-only migration: adds enrollment_fee field to Enrollment model.
The DB column already exists — no ALTER TABLE needed.
"""
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0025_enrollment_pk_enrollment_id'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[],
            state_operations=[
                migrations.AddField(
                    model_name='enrollment',
                    name='enrollment_fee',
                    field=models.DecimalField(decimal_places=2, default=0, max_digits=12, verbose_name='Enrollment Fee'),
                ),
            ],
        ),
    ]
