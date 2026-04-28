# Generated migration for simplified pricing - no VAT, no fees

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0017_enrollment_enhancement_for_actual_enrollment'),
    ]

    operations = [
        # Remove old pricing fields
        migrations.RemoveField(
            model_name='enrollment',
            name='enrollment_fee',
        ),
        migrations.RemoveField(
            model_name='enrollment',
            name='discount_applied',
        ),
        migrations.RemoveField(
            model_name='enrollment',
            name='final_amount',
        ),
        
        # Add simplified total_amount field
        migrations.AddField(
            model_name='enrollment',
            name='total_amount',
            field=models.DecimalField(
                max_digits=12,
                decimal_places=2,
                verbose_name='Total Amount',
                help_text='Exact course price - no VAT, no additional fees'
            ),
            preserve_default=False,
        ),
    ]
