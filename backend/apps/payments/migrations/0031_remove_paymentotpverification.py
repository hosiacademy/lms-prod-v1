# Generated migration to remove PaymentOTPVerification model

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0030_contactverificationotp'),
    ]

    operations = [
        migrations.DeleteModel(
            name='PaymentOTPVerification',
        ),
    ]
