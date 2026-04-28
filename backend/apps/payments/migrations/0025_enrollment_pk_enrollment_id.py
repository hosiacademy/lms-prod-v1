"""
State-only migration: tells Django that Enrollment PK is 'enrollment_id'.
The DB column already exists as 'enrollment_id' — no ALTER TABLE needed.
"""
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0024_paymentotpverification'),
    ]

    operations = [
        migrations.SeparateDatabaseAndState(
            database_operations=[],
            state_operations=[
                # Remove the implicit auto 'id' field from the migration state
                migrations.RemoveField(
                    model_name='enrollment',
                    name='id',
                ),
                # Add the correct PK
                migrations.AddField(
                    model_name='enrollment',
                    name='enrollment_id',
                    field=models.BigAutoField(primary_key=True, serialize=False, verbose_name='Enrollment ID'),
                ),
            ],
        ),
    ]
