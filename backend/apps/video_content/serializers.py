from rest_framework import serializers
from .models import VideoLesson, VideoProgress

class VideoLessonSerializer(serializers.ModelSerializer):
    """Serializer for video lessons"""
    class Meta:
        model = VideoLesson
        fields = [
            'id', 'lesson_id', 'course', 'title', 'description', 
            'order', 'video_url', 'thumbnail_url', 'duration_seconds',
            'subtitle_en_url', 'subtitle_es_url', 'subtitle_fr_url',
            'is_preview', 'allow_download', 'created_at', 'updated_at'
        ]

class VideoProgressSerializer(serializers.ModelSerializer):
    """Serializer for video progress"""
    class Meta:
        model = VideoProgress
        fields = [
            'id', 'user', 'lesson', 'last_position_seconds', 
            'completed', 'completion_percentage', 'last_watched_at', 
            'completed_at'
        ]
        read_only_fields = ['user']
