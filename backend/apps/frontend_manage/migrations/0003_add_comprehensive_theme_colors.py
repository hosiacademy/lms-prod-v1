# Generated migration for comprehensive theme colors

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('frontend_manage', '0002_initial'),
    ]

    operations = [
        # Add missing color fields
        migrations.AddField(
            model_name='appappearance',
            name='on_primary',
            field=models.CharField(
                default='#FFFFFF',
                help_text='Color for content on primary color surfaces',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='surface_variant',
            field=models.CharField(
                default='#21262D',
                help_text='Variant surface color for cards and dialogs',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='on_surface',
            field=models.CharField(
                default='#E6F0FF',
                help_text='Color for content on surface',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='on_background',
            field=models.CharField(
                default='#E6F0FF',
                help_text='Color for content on background',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='info_color',
            field=models.CharField(
                default='#0693E3',
                help_text='Info/information color',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='outline_color',
            field=models.CharField(
                default='#30363D',
                help_text='Border and outline color',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='outline_variant',
            field=models.CharField(
                default='#21262D',
                help_text='Lighter variant of outline color',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='divider_color',
            field=models.CharField(
                default='#30363D',
                help_text='Divider line color',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='shadow_color',
            field=models.CharField(
                default='#000000',
                help_text='Shadow color (usually black)',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='shadow_opacity',
            field=models.FloatField(
                default=0.15,
                help_text='Shadow opacity (0.0 to 1.0)'
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='card_color',
            field=models.CharField(
                default='#161B22',
                help_text='Card background color',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='app_bar_color',
            field=models.CharField(
                default='#161B22',
                help_text='AppBar background color',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='bottom_nav_color',
            field=models.CharField(
                default='#161B22',
                help_text='Bottom navigation bar color',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='fab_color',
            field=models.CharField(
                default='#0693E3',
                help_text='Floating action button color',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='on_error',
            field=models.CharField(
                default='#FFFFFF',
                help_text='Color for content on error color',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='on_warning',
            field=models.CharField(
                default='#000000',
                help_text='Color for content on warning color',
                max_length=7
            ),
        ),
        migrations.AddField(
            model_name='appappearance',
            name='on_success',
            field=models.CharField(
                default='#FFFFFF',
                help_text='Color for content on success color',
                max_length=7
            ),
        ),
    ]
