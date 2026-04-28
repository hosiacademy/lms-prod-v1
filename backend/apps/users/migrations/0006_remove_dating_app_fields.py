# Generated manually on 2026-02-04
# Removes all dating app fields that were mistakenly added to LMS
# This migration aligns Django's migration history with the cleaned database

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0005_user_based_city_user_based_country_user_based_state_and_more'),
    ]

    operations = [
        # Remove ProfileImage model
        migrations.DeleteModel(
            name='ProfileImage',
        ),

        # Remove dating app fields from User model
        # Note: gender field is KEPT as it's used for default profile pictures (LMS feature)

        migrations.RemoveField(
            model_name='user',
            name='intro_video',
        ),
        migrations.RemoveField(
            model_name='user',
            name='latitude',
        ),
        migrations.RemoveField(
            model_name='user',
            name='longitude',
        ),
        migrations.RemoveField(
            model_name='user',
            name='based_city',
        ),
        migrations.RemoveField(
            model_name='user',
            name='based_state',
        ),
        migrations.RemoveField(
            model_name='user',
            name='based_country',
        ),
        migrations.RemoveField(
            model_name='user',
            name='origin_city',
        ),
        migrations.RemoveField(
            model_name='user',
            name='origin_state',
        ),
        migrations.RemoveField(
            model_name='user',
            name='origin_country',
        ),
    ]
