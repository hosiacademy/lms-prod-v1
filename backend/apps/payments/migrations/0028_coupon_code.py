from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0027_enrollment_full_db_alignment'),
        ('users', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='CouponCode',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('code', models.CharField(db_index=True, max_length=50, unique=True)),
                ('name', models.CharField(max_length=200)),
                ('description', models.TextField(blank=True)),
                ('discount_type', models.CharField(
                    choices=[('percentage', 'Percentage Discount'), ('fixed', 'Fixed Amount Discount'), ('capped_percentage', 'Percentage with Cap')],
                    default='percentage', max_length=20)),
                ('discount_value', models.DecimalField(decimal_places=2, max_digits=10)),
                ('max_discount_amount', models.DecimalField(blank=True, decimal_places=2, max_digits=10, null=True)),
                ('product_pathway', models.CharField(
                    choices=[('all', 'All Products'), ('masterclass', 'Masterclasses'), ('learnership', 'Learnerships'), ('industry_training', 'Industry-Based Training'), ('aicerts', 'AICERTS Courses'), ('custom', 'Custom Selection')],
                    default='all', max_length=30)),
                ('country_restriction', models.CharField(blank=True, max_length=2)),
                ('client_type', models.CharField(
                    choices=[('all', 'All Clients'), ('public', 'Public / Individual'), ('corporate', 'Corporate'), ('private', 'Private')],
                    default='all', max_length=20)),
                ('min_purchase_amount', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('usage_limit', models.PositiveIntegerField(blank=True, null=True)),
                ('per_user_limit', models.PositiveIntegerField(default=1)),
                ('times_used', models.PositiveIntegerField(default=0)),
                ('valid_from', models.DateTimeField()),
                ('valid_until', models.DateTimeField()),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('created_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='coupons_created', to='users.user')),
            ],
            options={'verbose_name': 'Coupon Code', 'verbose_name_plural': 'Coupon Codes', 'ordering': ['-created_at']},
        ),
        migrations.CreateModel(
            name='CouponRedemption',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('email', models.EmailField(db_index=True)),
                ('original_amount', models.DecimalField(decimal_places=2, max_digits=10)),
                ('discount_amount', models.DecimalField(decimal_places=2, max_digits=10)),
                ('final_amount', models.DecimalField(decimal_places=2, max_digits=10)),
                ('ip_address', models.GenericIPAddressField(blank=True, null=True)),
                ('redeemed_at', models.DateTimeField(auto_now_add=True)),
                ('coupon', models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='redemptions', to='payments.couponcode')),
                ('order', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='coupon_redemptions', to='payments.order')),
                ('user', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='coupon_redemptions', to='users.user')),
            ],
            options={'verbose_name': 'Coupon Redemption', 'verbose_name_plural': 'Coupon Redemptions', 'ordering': ['-redeemed_at']},
        ),
    ]
