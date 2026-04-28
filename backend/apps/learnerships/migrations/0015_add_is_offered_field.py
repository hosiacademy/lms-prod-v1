# Generated migration for is_offered field
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('learnerships', '0014_merge_academic_and_provider'),
    ]

    operations = [
        migrations.AddField(
            model_name='learnershipprogramme',
            name='is_offered',
            field=models.BooleanField(
                default=True,
                help_text="Whether this learnership is currently offered to the public. If False, hidden from frontend but still selectable in backend."
            ),
        ),
    ]
