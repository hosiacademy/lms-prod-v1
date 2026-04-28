# Empty migration - tables already exist

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('localization', '0010_localizedpromotion_discount_percentage'),
    ]

    operations = [
    ]
