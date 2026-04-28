from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('learner_portal', '0004_wishlist_notes'),
    ]

    operations = [
        migrations.AddField(
            model_name='coursecatalogitem',
            name='display_order',
            field=models.IntegerField(default=0, help_text='Lower numbers appear first in catalog', verbose_name='Display Order'),
        ),
    ]
