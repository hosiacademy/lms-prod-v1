"""
Migration: Add promotion display fields to CouponCode.

Consolidates LocalizedPromotion (display-only) and CouponCode (functional) into
one unified record. Every promotion is now a coupon — global or localised.
"""
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0028_coupon_code'),
        ('localization', '0010_localizedpromotion_discount_percentage'),
    ]

    operations = [
        # Promotion type classifier
        migrations.AddField(
            model_name='couponcode',
            name='promotion_type',
            field=models.CharField(
                choices=[
                    ('discount', 'Discount/Sale'),
                    ('free_course', 'Free Course'),
                    ('bundle', 'Bundle Offer'),
                    ('limited_time', 'Limited Time Offer'),
                    ('seasonal', 'Seasonal Campaign'),
                    ('partnership', 'Partnership Offer'),
                    ('referral', 'Referral Program'),
                    ('other', 'Other'),
                ],
                default='discount',
                max_length=50,
            ),
        ),

        # Visual / display fields
        migrations.AddField(
            model_name='couponcode',
            name='background_color',
            field=models.CharField(default='#172E3D', max_length=7),
        ),
        migrations.AddField(
            model_name='couponcode',
            name='text_color',
            field=models.CharField(default='#FFFFFF', max_length=7),
        ),
        migrations.AddField(
            model_name='couponcode',
            name='icon',
            field=models.CharField(blank=True, max_length=50),
        ),
        migrations.AddField(
            model_name='couponcode',
            name='image_url',
            field=models.URLField(blank=True),
        ),
        migrations.AddField(
            model_name='couponcode',
            name='cta_text',
            field=models.CharField(default='Enroll Now', max_length=100),
        ),
        migrations.AddField(
            model_name='couponcode',
            name='cta_url',
            field=models.URLField(blank=True),
        ),
        migrations.AddField(
            model_name='couponcode',
            name='priority',
            field=models.IntegerField(default=0),
        ),

        # Placement flags
        migrations.AddField(
            model_name='couponcode',
            name='show_on_onboarding',
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name='couponcode',
            name='show_on_home',
            field=models.BooleanField(default=True),
        ),
        migrations.AddField(
            model_name='couponcode',
            name='show_on_splash',
            field=models.BooleanField(default=False),
        ),

        # M2M country targeting (display; separate from country_restriction validation field)
        migrations.AddField(
            model_name='couponcode',
            name='countries',
            field=models.ManyToManyField(
                blank=True,
                related_name='coupon_promotions',
                to='localization.country',
            ),
        ),
    ]
