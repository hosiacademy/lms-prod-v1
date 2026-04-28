# Generated migration for Instructor Application models

from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import uuid
import apps.instructors.models_instructor_application


class Migration(migrations.Migration):

    dependencies = [
        ('instructors', '0008_remove_earningsaccrual_assignment_and_more'),
        ('localization', '0001_initial'),  # Country model
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
    ]

    operations = [
        migrations.CreateModel(
            name='InstructorApplication',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('application_id', models.CharField(editable=False, max_length=50, unique=True, verbose_name='Application ID')),
                ('applicant_name', models.CharField(max_length=255, verbose_name='Full Name')),
                ('applicant_email', models.EmailField(max_length=254, verbose_name='Email Address')),
                ('applicant_phone', models.CharField(max_length=50, verbose_name='Phone Number')),
                ('professional_headline', models.CharField(max_length=255, verbose_name='Professional Headline')),
                ('areas_of_expertise', models.TextField(help_text='Comma-separated list of expertise areas', verbose_name='Areas of Expertise')),
                ('top_qualifications', models.TextField(verbose_name='Top Qualifications')),
                ('years_of_experience', models.PositiveIntegerField(default=0, verbose_name='Years of Experience')),
                ('motivation_letter', models.TextField(help_text='Why do you want to teach at Hosi Academy?', verbose_name='Motivation Letter')),
                ('cv_file', models.FileField(upload_to=apps.instructors.models_instructor_application.instructor_application_directory, verbose_name='CV/Resume')),
                ('certificates_file', models.FileField(blank=True, null=True, upload_to=apps.instructors.models_instructor_application.instructor_application_directory, verbose_name='Certificates')),
                ('additional_attachment_1', models.FileField(blank=True, null=True, upload_to=apps.instructors.models_instructor_application.instructor_application_directory, verbose_name='Additional Document 1')),
                ('additional_attachment_2', models.FileField(blank=True, null=True, upload_to=apps.instructors.models_instructor_application.instructor_application_directory, verbose_name='Additional Document 2')),
                ('additional_attachment_3', models.FileField(blank=True, null=True, upload_to=apps.instructors.models_instructor_application.instructor_application_directory, verbose_name='Additional Document 3')),
                ('additional_attachment_4', models.FileField(blank=True, null=True, upload_to=apps.instructors.models_instructor_application.instructor_application_directory, verbose_name='Additional Document 4')),
                ('additional_attachment_5', models.FileField(blank=True, null=True, upload_to=apps.instructors.models_instructor_application.instructor_application_directory, verbose_name='Additional Document 5')),
                ('status', models.CharField(choices=[('pending', 'Pending Review'), ('under_review', 'Under Review'), ('interview_scheduled', 'Interview Scheduled'), ('interview_completed', 'Interview Completed'), ('approved', 'Approved'), ('rejected', 'Rejected'), ('withdrawn', 'Withdrawn')], default='pending', max_length=30, verbose_name='Application Status')),
                ('interview_status', models.CharField(choices=[('not_scheduled', 'Not Scheduled'), ('scheduled', 'Scheduled'), ('completed', 'Completed'), ('cancelled', 'Cancelled'), ('rescheduled', 'Rescheduled')], default='not_scheduled', max_length=30, verbose_name='Interview Status')),
                ('interview_datetime', models.DateTimeField(blank=True, null=True, verbose_name='Scheduled Interview Date/Time')),
                ('interview_notes', models.TextField(blank=True, null=True, verbose_name='Interview Notes')),
                ('bbb_meeting_id', models.CharField(blank=True, max_length=255, null=True, verbose_name='BBB Meeting ID')),
                ('bbb_moderator_password', models.CharField(blank=True, max_length=255, null=True, verbose_name='BBB Moderator Password')),
                ('bbb_attendee_password', models.CharField(blank=True, max_length=255, null=True, verbose_name='BBB Attendee Password')),
                ('rejection_reason', models.TextField(blank=True, null=True, verbose_name='Rejection Reason')),
                ('approval_notes', models.TextField(blank=True, null=True, verbose_name='Approval Notes')),
                ('submitted_at', models.DateTimeField(auto_now_add=True, verbose_name='Submitted At')),
                ('reviewed_at', models.DateTimeField(blank=True, null=True, verbose_name='Reviewed At')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created At')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Updated At')),
                ('country', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='instructor_applications', to='localization.country', verbose_name='Country')),
                ('reviewed_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='reviewed_instructor_applications', to=settings.AUTH_USER_MODEL, verbose_name='Reviewed By (HR Admin)')),
            ],
            options={
                'verbose_name': 'Instructor Application',
                'verbose_name_plural': 'Instructor Applications',
                'db_table': 'instructor_applications',
                'ordering': ['-submitted_at'],
            },
        ),
        migrations.CreateModel(
            name='InstructorStatusLog',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('previous_status', models.CharField(blank=True, max_length=30, null=True, verbose_name='Previous Status')),
                ('new_status', models.CharField(choices=[('active', 'Active'), ('inactive', 'Inactive'), ('suspended', 'Suspended')], max_length=30, verbose_name='New Status')),
                ('reason', models.TextField(help_text='Required for inactive/suspended status', verbose_name='Reason for Status Change')),
                ('changed_at', models.DateTimeField(auto_now_add=True, verbose_name='Changed At')),
                ('changed_by', models.ForeignKey(null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='instructor_status_changes_made', to=settings.AUTH_USER_MODEL, verbose_name='Changed By (HR Admin)')),
                ('instructor', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='status_change_logs', to=settings.AUTH_USER_MODEL, verbose_name='Instructor')),
            ],
            options={
                'verbose_name': 'Instructor Status Log',
                'verbose_name_plural': 'Instructor Status Logs',
                'db_table': 'instructor_status_logs',
                'ordering': ['-changed_at'],
            },
        ),
        migrations.CreateModel(
            name='InstructorAnalytics',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('period_start', models.DateField(verbose_name='Period Start')),
                ('period_end', models.DateField(verbose_name='Period End')),
                ('total_courses_taught', models.PositiveIntegerField(default=0, verbose_name='Total Courses Taught')),
                ('total_students_taught', models.PositiveIntegerField(default=0, verbose_name='Total Students Taught')),
                ('average_rating', models.FloatField(default=0.0, validators=[django.core.validators.MaxValueValidator(5.0)], verbose_name='Average Rating (0-5)')),
                ('course_completion_rate', models.FloatField(default=0.0, validators=[django.core.validators.MaxValueValidator(100.0)], verbose_name='Course Completion Rate (%)')),
                ('student_retention_rate', models.FloatField(default=0.0, validators=[django.core.validators.MaxValueValidator(100.0)], verbose_name='Student Retention Rate (%)')),
                ('total_earnings', models.DecimalField(decimal_places=2, default=0.0, max_digits=12, verbose_name='Total Earnings')),
                ('total_live_sessions', models.PositiveIntegerField(default=0, verbose_name='Total Live Sessions')),
                ('total_session_attendance', models.PositiveIntegerField(default=0, verbose_name='Total Session Attendance')),
                ('status', models.CharField(choices=[('active', 'Active'), ('inactive', 'Inactive'), ('suspended', 'Suspended')], default='active', max_length=30, verbose_name='Status')),
                ('calculated_at', models.DateTimeField(auto_now_add=True, verbose_name='Calculated At')),
                ('created_at', models.DateTimeField(auto_now_add=True, verbose_name='Created At')),
                ('updated_at', models.DateTimeField(auto_now=True, verbose_name='Updated At')),
                ('country', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='instructor_analytics', to='localization.country', verbose_name='Country')),
                ('instructor', models.ForeignKey(on_delete=django.db.models.deletion.CASCADE, related_name='instructor_analytics', to=settings.AUTH_USER_MODEL, verbose_name='Instructor')),
            ],
            options={
                'verbose_name': 'Instructor Analytics',
                'verbose_name_plural': 'Instructor Analytics',
                'db_table': 'instructor_analytics',
                'ordering': ['-period_end'],
            },
        ),
        migrations.AddIndex(
            model_name='instructorapplication',
            index=models.Index(fields=['status', 'submitted_at'], name='instructor__status_855a4e_idx'),
        ),
        migrations.AddIndex(
            model_name='instructorapplication',
            index=models.Index(fields=['country', 'status'], name='instructor__country_952628_idx'),
        ),
        migrations.AddIndex(
            model_name='instructorapplication',
            index=models.Index(fields=['interview_status'], name='instructor__intervi_603e19_idx'),
        ),
        migrations.AlterUniqueTogether(
            name='instructoranalytics',
            unique_together={('instructor', 'period_start', 'period_end')},
        ),
        migrations.AddIndex(
            model_name='instructoranalytics',
            index=models.Index(fields=['country', 'period_end'], name='instructor__country_0aef9b_idx'),
        ),
        migrations.AddIndex(
            model_name='instructoranalytics',
            index=models.Index(fields=['instructor', 'period_end'], name='instructor__instruc_ca7f72_idx'),
        ),
    ]
