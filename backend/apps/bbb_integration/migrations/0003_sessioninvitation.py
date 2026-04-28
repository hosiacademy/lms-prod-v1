# Generated migration for SessionInvitation model

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('bbb_integration', '0002_livesession_phase_cohort'),
    ]

    operations = [
        migrations.CreateModel(
            name='SessionInvitation',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('email', models.EmailField(help_text='Student email address', max_length=254)),
                ('student_name', models.CharField(help_text='Student name', max_length=255)),
                ('status', models.CharField(choices=[('pending', 'Pending'), ('sent', 'Sent'), ('opened', 'Opened'), ('joined', 'Joined'), ('expired', 'Expired')], default='pending', max_length=20)),
                ('invitation_token', models.CharField(max_length=255, unique=True)),
                ('sent_at', models.DateTimeField(blank=True, null=True)),
                ('opened_at', models.DateTimeField(blank=True, null=True)),
                ('joined_at', models.DateTimeField(blank=True, null=True)),
                ('chat_invitation_sent', models.BooleanField(default=False, help_text='Whether 1-on-1 chat invite was sent')),
                ('chat_invitation_accepted', models.BooleanField(default=False, help_text='Whether student accepted chat invite')),
                ('metadata', models.JSONField(blank=True, default=dict, help_text='Additional invitation metadata')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('session', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='invitations', to='bbb_integration.livesession')),
            ],
            options={
                'verbose_name': 'Session Invitation',
                'verbose_name_plural': 'Session Invitations',
                'db_table': 'session_invitations',
                'ordering': ['-created_at'],
            },
        ),
        migrations.AddIndex(
            model_name='sessioninvitation',
            index=models.Index(fields=['session', 'status'], name='bbb_session_session_3c9f0f_idx'),
        ),
        migrations.AddIndex(
            model_name='sessioninvitation',
            index=models.Index(fields=['email', 'status'], name='bbb_session_email_s_e5c1e7_idx'),
        ),
        migrations.AddIndex(
            model_name='sessioninvitation',
            index=models.Index(fields=['invitation_token'], name='bbb_session_invitat_6c7d79_idx'),
        ),
    ]
