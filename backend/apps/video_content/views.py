from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from .models import VideoLesson, VideoProgress
from .serializers import VideoLessonSerializer, VideoProgressSerializer

class VideoLessonViewSet(viewsets.ReadOnlyModelViewSet):
    """API for viewing video lessons and tracking progress"""
    queryset = VideoLesson.objects.all()
    serializer_class = VideoLessonSerializer
    permission_classes = [IsAuthenticated]
    
    @action(detail=True, methods=['post'])
    def update_progress(self, request, pk=None):
        """Update video playback progress"""
        lesson = self.get_object()
        position = request.data.get('position', 0)
        
        try:
            position = int(position)
        except (ValueError, TypeError):
            return Response({'error': 'Invalid position'}, status=status.HTTP_400_BAD_REQUEST)
        
        progress, created = VideoProgress.objects.get_or_create(
            user=request.user,
            lesson=lesson,
        )
        
        progress.last_position_seconds = position
        
        if lesson.duration_seconds > 0:
            progress.completion_percentage = (position / lesson.duration_seconds) * 100
        else:
            progress.completion_percentage = 0.0
            
        # Mark as completed if watched 95% or more
        if progress.completion_percentage >= 95 and not progress.completed:
            progress.completed = True
            progress.completed_at = timezone.now()
        
        progress.save()
        
        return Response({
            'position': progress.last_position_seconds,
            'completed': progress.completed,
            'percentage': round(progress.completion_percentage, 2)
        })
    
    @action(detail=True, methods=['get'])
    def progress(self, request, pk=None):
        """Get current video progress for the user"""
        lesson = self.get_object()
        
        try:
            progress = VideoProgress.objects.get(user=request.user, lesson=lesson)
            serializer = VideoProgressSerializer(progress)
            return Response(serializer.data)
        except VideoProgress.DoesNotExist:
            return Response({
                'position': 0,
                'completed': False,
                'percentage': 0.0
            })
