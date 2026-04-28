from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('bbb_integration', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='livesession',
            name='phase_id',
            field=models.IntegerField(
                blank=True,
                null=True,
                help_text='Learnership phase ID (optional)',
            ),
        ),
        migrations.AddField(
            model_name='livesession',
            name='cohort_info',
            field=models.JSONField(
                default=dict,
                blank=True,
                help_text='Extra context: phase name, NQF level, location, cohort details',
            ),
        ),
    ]
