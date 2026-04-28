from django.db import migrations


class Migration(migrations.Migration):
    """
    Adds discount_percentage column to localized_promotions table.
    Uses RunSQL instead of AddField to avoid migration state issues
    (LocalizedPromotion model was faked in migrations 0003/0004).
    Column may already exist if created via raw SQL — IF NOT EXISTS guard used.
    """

    dependencies = [
        ('localization', '0009_alter_city_options_state_alter_city_unique_together_and_more'),
    ]

    operations = [
        migrations.RunSQL(
            sql="ALTER TABLE localized_promotions ADD COLUMN IF NOT EXISTS discount_percentage NUMERIC(5,2);",
            reverse_sql="ALTER TABLE localized_promotions DROP COLUMN IF EXISTS discount_percentage;",
        ),
    ]
