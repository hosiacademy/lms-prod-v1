from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('learnerships', '0006_learnershipprogramme_cost_usd_and_more'),
    ]

    operations = [
        migrations.AddField(
            model_name='learnershipphase',
            name='programme',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='phases',
                to='learnerships.learnershipprogramme',
            ),
            preserve_default=False,
        ),
    ]
