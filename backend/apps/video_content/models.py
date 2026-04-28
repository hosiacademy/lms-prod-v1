from django.db import models
from django.conf import settings
from django.utils.translation import gettext_lazy as _

class VideoLesson(models.Model):
    """Video lesson model"""
    lesson_id = models.CharField(max_length=255, unique=True)
    course = models.ForeignKey('courses.Course', on_delete=models.CASCADE, related_name='video_lessons')
    
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    order = models.IntegerField(default=0)
    
    # Video files
    video_url = models.URLField(help_text=_("HLS manifest URL or MP4 URL"))
    thumbnail_url = models.URLField(blank=True, null=True)
    duration_seconds = models.IntegerField(default=0)
    
    # Subtitles
    subtitle_en_url = models.URLField(blank=True, null=True)
    subtitle_es_url = models.URLField(blank=True, null=True)
    subtitle_fr_url = models.URLField(blank=True, null=True)
    
    # Settings
    is_preview = models.BooleanField(default=False, help_text=_("Can be viewed without enrollment"))
    allow_download = models.BooleanField(default=False)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        db_table = 'video_lessons'
        ordering = ['order']
        verbose_name = _('Video Lesson')
        verbose_name_plural = _('Video Lessons')

    def __str__(self):
        return f"{self.course.title} - {self.title}"

class VideoProgress(models.Model):
    """Track user progress in video lessons"""
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='video_progress')
    lesson = models.ForeignKey(VideoLesson, on_delete=models.CASCADE, related_name='user_progress')
    
    last_position_seconds = models.IntegerField(default=0)
    completed = models.BooleanField(default=False)
    completion_percentage = models.FloatField(default=0.0)
    
    last_watched_at = models.DateTimeField(auto_now=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        db_table = 'video_progress'
        unique_together = ['user', 'lesson']
        verbose_name = _('Video Progress')
        verbose_name_plural = _('Video Progress')

    def __str__(self):
        return f"{self.user.username} - {self.lesson.title} ({self.completion_percentage}%)"
