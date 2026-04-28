from django.db import migrations, models
from decimal import Decimal

class Migration(migrations.Migration):

    dependencies = [
        # Use the LAST migration that is ACTUALLY applied in the DB.
        # From your earlier --fake, it's likely 0010 or 0011.
        # If unsure, run: python manage.py showmigrations users
        ('users', '0011_set_default_hourly_rate'),  # ← change if needed to match last [X]
    ]

    operations = [
        # 1. Set default for new inserts (this is the main fix)
        migrations.AlterField(
            model_name='user',
            name='hourly_rate',
            field=models.DecimalField(
                decimal_places=2,
                default=Decimal('0.00'),
                max_digits=10,
            ),
        ),

        # 2. Optional: Backfill any NULLs that might exist (safe even if none)
        migrations.RunSQL(
            sql="UPDATE users SET hourly_rate = 0.00 WHERE hourly_rate IS NULL;",
            reverse_sql="UPDATE users SET hourly_rate = NULL WHERE hourly_rate = 0.00;",
        ),
    ]