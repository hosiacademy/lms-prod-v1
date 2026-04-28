"""
Update Masterclass Pricing - Remove Discounts

Sets final prices directly in database (no discount calculations):

Technical Masterclasses:
    Physical: $1,100.00
    Online:   $750.00

Professional Masterclasses:
    Physical: $700.00
    Online:   $500.00

Prices are stored as-is in the database. Currency conversion happens
automatically based on user's IP location via CurrencyDetectionMiddleware.
"""
from django.db import migrations
from decimal import Decimal


def update_masterclass_pricing(apps, schema_editor):
    """
    Update masterclass prices to final values (no discounts).
    """
    Masterclass = apps.get_model('masterclasses', 'Masterclass')

    # Update Technical masterclasses
    technical_count = Masterclass.objects.filter(
        stream_type='technical'
    ).update(
        price_physical=Decimal('1100.00'),
        price_online=Decimal('750.00'),
        currency='USD'
    )

    # Update Professional masterclasses
    professional_count = Masterclass.objects.filter(
        stream_type='professional'
    ).update(
        price_physical=Decimal('700.00'),
        price_online=Decimal('500.00'),
        currency='USD'
    )

    print(f"Updated {technical_count} Technical masterclasses")
    print(f"Updated {professional_count} Professional masterclasses")
    print("\nPricing Structure (No Discounts):")
    print("-" * 60)
    print("Technical Masterclasses:")
    print("  • Physical: $1,100.00")
    print("  • Online:   $750.00")
    print("\nProfessional Masterclasses:")
    print("  • Physical: $700.00")
    print("  • Online:   $500.00")
    print("-" * 60)
    print("\nNote: Prices stored directly in database - no discount calculations.")
    print("Currency conversion happens automatically based on user's IP location.")


def revert_pricing(apps, schema_editor):
    """Revert to previous pricing structure"""
    Masterclass = apps.get_model('masterclasses', 'Masterclass')
    
    # Revert to migration 0008 prices
    Masterclass.objects.filter(
        stream_type='technical'
    ).update(
        price_physical=Decimal('1100.00'),
        price_online=Decimal('420.00'),
        currency='USD'
    )
    
    Masterclass.objects.filter(
        stream_type='professional'
    ).update(
        price_physical=Decimal('700.00'),
        price_online=Decimal('300.00'),
        currency='USD'
    )


class Migration(migrations.Migration):

    dependencies = [
        ('masterclasses', '0008_add_physical_online_pricing'),
    ]

    operations = [
        migrations.RunPython(
            update_masterclass_pricing,
            reverse_code=revert_pricing
        ),
    ]
