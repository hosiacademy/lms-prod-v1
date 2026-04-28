from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0029_coupon_promotion_display_fields'),
    ]

    operations = [
        migrations.CreateModel(
            name='ContactVerificationOTP',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('contact', models.CharField(db_index=True, max_length=255)),
                ('contact_type', models.CharField(choices=[('email', 'Email'), ('phone', 'Phone')], max_length=10)),
                ('otp', models.CharField(max_length=6)),
                ('verified', models.BooleanField(default=False)),
                ('is_valid', models.BooleanField(default=True)),
                ('expires_at', models.DateTimeField()),
                ('verified_at', models.DateTimeField(blank=True, null=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'verbose_name': 'Contact Verification OTP',
                'verbose_name_plural': 'Contact Verification OTPs',
                'ordering': ['-created_at'],
                'indexes': [
                    models.Index(fields=['contact', 'contact_type', 'verified'], name='payments_co_contact_idx'),
                ],
            },
        ),
    ]
