"""
Update Masterclass Pricing Structure

Adds separate physical and online price fields:

Technical Masterclasses:
    Physical: $1,100.00
    Online:   $420.00

Professional Masterclasses:
    Physical: $700.00
    Online:   $300.00

No discounts - prices are stored as-is in the database.
"""
from django.db import migrations, models
from decimal import Decimal


def update_masterclass_pricing(apps, schema_editor):
    """
    Add physical and online price fields and populate with correct values.
    """
    Masterclass = apps.get_model('masterclasses', 'Masterclass')
    
    # Update Technical masterclasses
    technical_count = Masterclass.objects.filter(
        stream_type='technical'
    ).update(
        price_physical=Decimal('1100.00'),
        price_online=Decimal('420.00'),
        currency='USD'
    )
    
    # Update Professional masterclasses
    professional_count = Masterclass.objects.filter(
        stream_type='professional'
    ).update(
        price_physical=Decimal('700.00'),
        price_online=Decimal('300.00'),
        currency='USD'
    )
    
    print(f"Updated {technical_count} Technical masterclasses")
    print(f"Updated {professional_count} Professional masterclasses")
    print("\nPricing Structure:")
    print("-" * 60)
    print("Technical Masterclasses:")
    print("  • Physical: $1,100.00")
    print("  • Online:   $420.00")
    print("\nProfessional Masterclasses:")
    print("  • Physical: $700.00")
    print("  • Online:   $300.00")
    print("-" * 60)
    print("\nNote: Prices are stored directly in database - no discounts applied.")
    print("Currency conversion happens automatically based on user's IP location.")


def revert_pricing(apps, schema_editor):
    """Revert to previous pricing structure"""
    Masterclass = apps.get_model('masterclasses', 'Masterclass')
    Masterclass.objects.all().update(
        price_physical=Decimal('500.00'),
        price_online=Decimal('500.00'),
        currency='USD'
    )


class Migration(migrations.Migration):

    dependencies = [
        ('masterclasses', '0007_update_masterclass_pricing'),
    ]

    operations = [
        # Add new fields
        migrations.AddField(
            model_name='masterclass',
            name='price_physical',
            field=models.DecimalField(
                max_digits=10,
                decimal_places=2,
                default=Decimal('500.00'),
                help_text='Physical attendance price in USD'
            ),
            preserve_default=False,
        ),
        migrations.AddField(
            model_name='masterclass',
            name='price_online',
            field=models.DecimalField(
                max_digits=10,
                decimal_places=2,
                default=Decimal('500.00'),
                help_text='Online attendance price in USD'
            ),
            preserve_default=False,
        ),
        # Run data update
        migrations.RunPython(
            update_masterclass_pricing,
            reverse_code=revert_pricing
        ),
    ]
