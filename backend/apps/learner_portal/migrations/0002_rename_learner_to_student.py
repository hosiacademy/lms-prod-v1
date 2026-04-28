# Generated migration for renaming LearnerProfile to StudentProfile
from django.db import migrations, models
import django.db.models.deletion
from django.conf import settings


class Migration(migrations.Migration):

    dependencies = [
        ('learner_portal', '0001_initial'),
        ('localization', '0001_initial'),
    ]

    operations = [
        # Rename the model class (no DB changes, just Django metadata)
        migrations.RenameModel(
            old_name='LearnerProfile',
            new_name='StudentProfile',
        ),

        # Update related_name on Country model
        migrations.AlterField(
            model_name='studentprofile',
            name='preferred_country',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='preferred_students',
                to='localization.country',
                verbose_name='Preferred Country'
            ),
        ),

        # Update related_name on State model
        migrations.AlterField(
            model_name='studentprofile',
            name='preferred_state',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='preferred_students',
                to='localization.state',
                verbose_name='Preferred State/Region'
            ),
        ),

        # Update related_name on City model
        migrations.AlterField(
            model_name='studentprofile',
            name='preferred_city',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='preferred_students',
                to='localization.city',
                verbose_name='Preferred City'
            ),
        ),

        # Update related_name on user field
        migrations.AlterField(
            model_name='studentprofile',
            name='user',
            field=models.OneToOneField(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='student_profile',
                to=settings.AUTH_USER_MODEL,
                verbose_name='User'
            ),
        ),

        # Update verbose names
        migrations.AlterModelOptions(
            name='studentprofile',
            options={
                'verbose_name': 'Student Profile',
                'verbose_name_plural': 'Student Profiles',
            },
        ),

        # Update verbose_name on Wishlist user field
        migrations.AlterField(
            model_name='wishlist',
            name='user',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='wishlist_items',
                to=settings.AUTH_USER_MODEL,
                verbose_name='Student'
            ),
        ),

        # Update verbose_name on CourseCart user field
        migrations.AlterField(
            model_name='coursecart',
            name='user',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.CASCADE,
                related_name='course_carts',
                to=settings.AUTH_USER_MODEL,
                verbose_name='Student'
            ),
        ),

        # Update help_text on CourseCartItem
        migrations.AlterField(
            model_name='coursecartitem',
            name='prerequisites_met',
            field=models.BooleanField(
                default=True,
                help_text='Does student meet prerequisites for this course?',
                verbose_name='Prerequisites Met'
            ),
        ),

        # Update help_text on Wishlist fields
        migrations.AlterField(
            model_name='wishlist',
            name='converted_to_cart',
            field=models.BooleanField(
                default=False,
                help_text='Did student add this to their cart?',
                verbose_name='Moved to Cart'
            ),
        ),

        migrations.AlterField(
            model_name='wishlist',
            name='converted_to_enrollment',
            field=models.BooleanField(
                default=False,
                help_text='Did student complete enrollment?',
                verbose_name='Enrolled'
            ),
        ),
    ]
