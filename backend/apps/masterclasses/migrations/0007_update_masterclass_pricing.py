"""
Update Masterclass Pricing

Sets base prices according to stream type:
- Technical Masterclasses: Physical $1,100.00 (Online: $750.00)
- Professional Masterclasses: Physical $700.00 (Online: $500.00)

The online price is calculated dynamically via the model's online_price property
with discounts:
- Technical: $350 discount for online
- Professional: $200 discount for online
"""
from django.db import migrations
from decimal import Decimal


def update_masterclass_pricing(apps, schema_editor):
    """
    Update all existing masterclasses with correct base pricing.
    Base price = Physical attendance price.
    Online price is calculated dynamically with stream-type-specific discount.
    """
    Masterclass = apps.get_model('masterclasses', 'Masterclass')
    
    # Technical masterclasses: $1,100 physical
    technical_count = Masterclass.objects.filter(
        stream_type='technical'
    ).update(
        price=Decimal('1100.00'),
        currency='USD'
    )
    
    # Professional masterclasses: $700 physical
    professional_count = Masterclass.objects.filter(
        stream_type='professional'
    ).update(
        price=Decimal('700.00'),
        currency='USD'
    )
    
    print(f"Updated {technical_count} Technical masterclasses to $1,100.00 (Physical)")
    print(f"Updated {professional_count} Professional masterclasses to $700.00 (Physical)")
    print("\nPricing Summary:")
    print("-" * 60)
    print("Technical Masterclasses:")
    print("  • Physical: $1,100.00")
    print("  • Online:   $750.00  ($350 discount)")
    print("\nProfessional Masterclasses:")
    print("  • Physical: $700.00")
    print("  • Online:   $500.00  ($200 discount)")
    print("-" * 60)
    print("\nNote: Online prices are calculated dynamically via the online_price property.")
    print("Currency conversion happens automatically based on user's IP location.")


def revert_pricing(apps, schema_editor):
    """Revert to previous pricing (if needed)"""
    Masterclass = apps.get_model('masterclasses', 'Masterclass')
    # Reset to a neutral value - though this is unlikely to be needed
    Masterclass.objects.all().update(
        price=Decimal('500.00'),
        currency='USD'
    )


class Migration(migrations.Migration):

    dependencies = [
        ('masterclasses', '0006_masterclass_has_online_option'),
    ]

    operations = [
        migrations.RunPython(
            update_masterclass_pricing,
            reverse_code=revert_pricing
        ),
    ]
