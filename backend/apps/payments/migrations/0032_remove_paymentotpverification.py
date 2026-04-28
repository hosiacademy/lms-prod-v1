# Clean migration - only remove PaymentOTPVerification table
# All other fields already exist in the database

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0031_remove_paymentotpverification'),
    ]

    operations = [
    ]
