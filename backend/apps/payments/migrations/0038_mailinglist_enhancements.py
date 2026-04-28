from django.db import migrations, models

class Migration(migrations.Migration):

    dependencies = [
        ('payments', '0037_mailinglist_mailinglistcontact'),
    ]

    operations = [
        migrations.AddField(
            model_name='mailinglist',
            name='country',
            field=models.CharField(blank=True, help_text='Specific country for this list', max_length=100, null=True),
        ),
        migrations.AddField(
            model_name='mailinglist',
            name='is_universal',
            field=models.BooleanField(default=False, help_text='True if this list is for all countries'),
        ),
        migrations.AddField(
            model_name='mailinglist',
            name='theme',
            field=models.CharField(blank=True, help_text='Category or theme for this list', max_length=100, null=True),
        ),
    ]
