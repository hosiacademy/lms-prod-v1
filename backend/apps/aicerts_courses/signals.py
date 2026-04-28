from django.db.models.signals import post_save
from django.dispatch import receiver
from apps.aicerts_courses.models import AiCertsCourse
from apps.courses.models import Course

@receiver(post_save, sender=AiCertsCourse)
def sync_to_course_table(sender, instance, created, **kwargs):
    Course.objects.update_or_create(
        title=instance.title,
        defaults={
            'shortname': instance.shortname or instance.title[:50],
            'summary': instance.summary or instance.description or '',
            'category_name': instance.category_name,
            'is_active': True,
        }
    )
