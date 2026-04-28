# Generated migration for AdminCountryAccess model
# Supports multi-country assignments for admin roles

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0013_alter_order_user_paymentreference_enrollment_and_more'),
        ('localization', '0001_initial'),  # Assuming localization app has initial migration
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='AdminCountryAccess',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('is_active', models.BooleanField(default=True, help_text='Whether this country access is currently active', verbose_name='Active')),
                ('granted_at', models.DateTimeField(auto_now_add=True, verbose_name='Granted At')),
                ('revoked_at', models.DateTimeField(blank=True, null=True, verbose_name='Revoked At')),
                ('notes', models.TextField(blank=True, verbose_name='Notes')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created At')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Updated At')),
                ('admin_role', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='country_accesses', to='payments.adminrole', verbose_name='Admin Role')),
                ('country', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='admin_role_accesses', to='localization.country', verbose_name='Country')),
                ('granted_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='granted_country_accesses', to=settings.AUTH_USER_MODEL, verbose_name='Granted By')),
                ('revoked_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='revoked_country_accesses', to=settings.AUTH_USER_MODEL, verbose_name='Revoked By')),
            ],
            options={
                'verbose_name': 'Admin Country Access',
                'verbose_name_plural': 'Admin Country Accesses',
                'db_table': 'admin_country_access',
                'ordering': ['country__name', 'admin_role'],
                'unique_together': {('admin_role', 'country')},
                'indexes': [
                    models.Index(fields=['admin_role', 'is_active'], name='admin_count_admin_r_rol_5f8d9a_idx'),
                    models.Index(fields=['country', 'is_active'], name='admin_count_country_rol_2c4e5b_idx'),
                ],
            },
        ),
    ]
