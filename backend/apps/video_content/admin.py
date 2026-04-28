from django.contrib import admin
from .models import VideoLesson, VideoProgress

@admin.register(VideoLesson)
class VideoLessonAdmin(admin.ModelAdmin):
    list_display = ('title', 'course', 'order', 'duration_seconds', 'is_preview')
    list_filter = ('course', 'is_preview')
    search_fields = ('title', 'description', 'lesson_id')
    ordering = ('course', 'order')

@admin.register(VideoProgress)
class VideoProgressAdmin(admin.ModelAdmin):
    list_display = ('user', 'lesson', 'completion_percentage', 'completed', 'last_watched_at')
    list_filter = ('completed', 'lesson__course')
    search_fields = ('user__username', 'lesson__title')
    raw_id_fields = ('user', 'lesson')
