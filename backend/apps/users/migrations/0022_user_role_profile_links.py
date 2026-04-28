from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('users', '0021_add_user_theme_preference'),
        ('learner_portal', '0001_initial'),
        ('instructors', '0001_initial'),
        ('payments', '0001_initial'),
    ]

    operations = [
        migrations.AddField(
            model_name='user',
            name='student_profile_link',
            field=models.ForeignKey(
                blank=True,
                null=True,
                db_column='student_profile_id',
                help_text='Links to the students table record for this user',
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='user_links',
                to='learner_portal.studentprofile',
                verbose_name='Student Profile',
            ),
        ),
        migrations.AddField(
            model_name='user',
            name='instructor_profile_link',
            field=models.ForeignKey(
                blank=True,
                null=True,
                db_column='instructor_profile_id',
                help_text='Links to the instructors table record for this user',
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='user_links',
                to='instructors.instructor',
                verbose_name='Instructor Profile',
            ),
        ),
        migrations.AddField(
            model_name='user',
            name='admin_profile_link',
            field=models.ForeignKey(
                blank=True,
                null=True,
                db_column='admin_profile_id',
                help_text='Links to the administrators table record for this user',
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='user_links',
                to='payments.administrator',
                verbose_name='Admin Profile',
            ),
        ),
        # Backfill: populate from existing user_id relationships in each profile table
        migrations.RunSQL(
            sql="""
                -- Populate student_profile_id from students.user_id
                UPDATE users u
                SET student_profile_id = s.id
                FROM students s
                WHERE s.user_id = u.id
                  AND u.student_profile_id IS NULL;

                -- Populate instructor_profile_id from instructors.user_id
                UPDATE users u
                SET instructor_profile_id = i.id
                FROM instructors i
                WHERE i.user_id = u.id
                  AND u.instructor_profile_id IS NULL;

                -- Populate admin_profile_id from administrators.user_id
                UPDATE users u
                SET admin_profile_id = a.id
                FROM administrators a
                WHERE a.user_id = u.id
                  AND u.admin_profile_id IS NULL;
            """,
            reverse_sql="""
                UPDATE users SET student_profile_id = NULL, instructor_profile_id = NULL, admin_profile_id = NULL;
            """,
        ),
    ]
