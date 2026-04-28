from django.db import migrations, models
import django.db.models.deletion
from decimal import Decimal


class Migration(migrations.Migration):

    dependencies = [
        ('learnerships', '0012_add_academic_registration_fields'),
    ]

    operations = [
        migrations.CreateModel(
            name='CertificationTrack',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=255, unique=True)),
                ('track_type', models.CharField(choices=[('blue_teamer', 'Blue Teamer'), ('bug_hunter', 'Bug Hunter'), ('ai_security', 'AI Security Specialist'), ('cloud_security', 'Cloud Security Engineer')], max_length=50)),
                ('description', models.TextField(blank=True)),
                ('total_cert_cost', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('platform_cost', models.DecimalField(decimal_places=2, default=240, max_digits=10)),
                ('instructor_cost', models.DecimalField(decimal_places=2, default=600, max_digits=10)),
                ('total_cost', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('sales_price', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('monthly_price', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('gross_margin', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'verbose_name': 'Certification Track',
                'verbose_name_plural': 'Certification Tracks',
                'ordering': ['name'],
            },
        ),
        migrations.CreateModel(
            name='CertificationItem',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=255)),
                ('description', models.TextField(blank=True)),
                ('phase', models.CharField(choices=[('phase_1_foundation', 'Phase 1 – Foundation'), ('phase_2_vendor_spec', 'Phase 2 – Vendor Spec'), ('phase_3_practical', 'Phase 3 – Practical/Readiness')], max_length=50)),
                ('cert_cost', models.DecimalField(decimal_places=2, default=0, max_digits=10)),
                ('order', models.PositiveIntegerField(default=1)),
                ('active', models.BooleanField(default=True)),
                ('track', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='certifications', to='learnerships.certificationtrack')),
            ],
            options={
                'verbose_name': 'Certification Item',
                'verbose_name_plural': 'Certification Items',
                'ordering': ['track', 'phase', 'order'],
            },
        ),
    ]
