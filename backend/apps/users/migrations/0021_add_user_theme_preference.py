# Generated migration for UserThemePreference model

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0013_alter_user_hourly_rate'),
    ]

    operations = [
        migrations.CreateModel(
            name='UserThemePreference',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('theme_mode', models.CharField(choices=[('light', 'Light Mode'), ('dark', 'Dark Mode'), ('system', 'System Default')], default='dark', max_length=20, verbose_name='Theme Mode')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('user', models.OneToOneField(on_delete=django.db.models.deletion.CASCADE, related_name='theme_preference', to=settings.AUTH_USER_MODEL, verbose_name='User')),
            ],
            options={
                'verbose_name': 'User Theme Preference',
                'verbose_name_plural': 'User Theme Preferences',
                'db_table': 'user_theme_preferences',
            },
        ),
    ]
