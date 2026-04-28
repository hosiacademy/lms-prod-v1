from django.db import migrations, models

class Migration(migrations.Migration):
    dependencies = [
        ('aicerts_courses', '0014_alter_aicertscourse_options_aicertscourse_ai_tools_and_more'),
    ]

    operations = [
        migrations.AlterField(
            model_name='aicertscourse',
            name='category_name',
            field=models.CharField(blank=True, max_length=10000),
        ),
        migrations.AlterField(
            model_name='aicertscourse',
            name='shortname',
            field=models.CharField(max_length=10000),
        ),
        migrations.AlterField(
            model_name='aicertscourse',
            name='title',
            field=models.CharField(max_length=10000),
        ),
        migrations.AlterField(
            model_name='aicertscourse',
            name='certificate_badge_url',
            field=models.CharField(blank=True, max_length=10000, null=True),
        ),
        migrations.AlterField(
            model_name='aicertscourse',
            name='feature_image_url',
            field=models.CharField(blank=True, max_length=10000, null=True),
        ),
        migrations.AlterField(
            model_name='aicertscourse',
            name='certificate_image_jpg_url',
            field=models.CharField(blank=True, max_length=10000, null=True),
        ),
    ]