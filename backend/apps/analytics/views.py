# apps/analytics/views.py
from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from django.db.models import Sum, Count, Avg, F
from django.db.models.functions import Coalesce
from datetime import datetime, timedelta
from .models import (
    PlatformAnalytics,
    CourseAnalytics,
    LearnershipAnalytics,
    UserProgress,
    ActivityLog
)
from .serializers import (
    PlatformAnalyticsSerializer,
    CourseAnalyticsSerializer,
    LearnershipAnalyticsSerializer,
    UserProgressSerializer,
    ActivityLogSerializer  # ← add this serializer if you don't have it yet
)


class PlatformAnalyticsViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Platform-wide analytics (daily aggregates)
    """
    queryset = PlatformAnalytics.objects.all()
    serializer_class = PlatformAnalyticsSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]  # restrict to admins

    def get_queryset(self):
        qs = super().get_queryset()
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        
        if start_date:
            qs = qs.filter(date__gte=start_date)
        if end_date:
            qs = qs.filter(date__lte=end_date)
            
        return qs.order_by('-date')

    @action(detail=False, methods=['get'])
    def summary(self, request):
        """Quick platform overview (totals & recent growth)"""
        last_30_days = datetime.now().date() - timedelta(days=30)
        
        recent = self.get_queryset().filter(date__gte=last_30_days)
        
        data = {
            "total_users": PlatformAnalytics.objects.latest('date').total_users if PlatformAnalytics.objects.exists() else 0,
            "new_users_last_30": recent.aggregate(total=Sum('new_users'))['total'] or 0,
            "active_users_avg": recent.aggregate(avg=Avg('active_users'))['avg'] or 0,
            "page_views_last_30": recent.aggregate(total=Sum('page_views'))['total'] or 0,
            "daily_avg_growth": recent.aggregate(growth=Avg(F('new_users')))['growth'] or 0,
        }
        return Response(data)


class CourseAnalyticsViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Per-course analytics (daily + aggregates)
    """
    queryset = CourseAnalytics.objects.all()
    serializer_class = CourseAnalyticsSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get_queryset(self):
        qs = super().get_queryset().select_related('course')
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        course_id = self.request.query_params.get('course_id')
        
        if course_id:
            qs = qs.filter(course_id=course_id)
        if start_date:
            qs = qs.filter(date__gte=start_date)
        if end_date:
            qs = qs.filter(date__lte=end_date)
            
        return qs.order_by('-date')

    @action(detail=False, methods=['get'])
    def top_courses(self, request):
        """Top 10 courses by total views/enrollments/completions"""
        top = CourseAnalytics.objects.values(
            'course__title',
            'course__shortname',
            'course_id'
        ).annotate(
            total_views=Coalesce(Sum('views'), 0),
            total_enrollments=Coalesce(Sum('enrollments'), 0),
            total_completions=Coalesce(Sum('completions'), 0),
            completion_rate=Coalesce(
                Avg('completions') * 100.0 / Avg('enrollments'), 0
            )
        ).order_by('-total_views')[:10]
        
        return Response(top)


class LearnershipAnalyticsViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Per-learnership analytics
    """
    queryset = LearnershipAnalytics.objects.all()
    serializer_class = LearnershipAnalyticsSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get_queryset(self):
        qs = super().get_queryset().select_related('learnership')
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        learnership_id = self.request.query_params.get('learnership_id')
        
        if learnership_id:
            qs = qs.filter(learnership_id=learnership_id)
        if start_date:
            qs = qs.filter(date__gte=start_date)
        if end_date:
            qs = qs.filter(date__lte=end_date)
            
        return qs.order_by('-date')

    @action(detail=False, methods=['get'])
    def top_learnerships(self, request):
        """Top learnerships by enrollments/views"""
        top = LearnershipAnalytics.objects.values(
            'learnership__title',
            'learnership_id'
        ).annotate(
            total_views=Coalesce(Sum('views'), 0),
            total_enrollments=Coalesce(Sum('enrollments'), 0),
            total_completions=Coalesce(Sum('completions'), 0)
        ).order_by('-total_enrollments')[:10]
        
        return Response(top)


class UserProgressViewSet(viewsets.ReadOnlyModelViewSet):
    """
    User progress tracking (personal + admin overview)
    """
    queryset = UserProgress.objects.all()
    serializer_class = UserProgressSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = super().get_queryset().select_related('user', 'course', 'learnership')
        user = self.request.user
        
        # Students see only their own progress
        if not user.is_staff:
            qs = qs.filter(user=user)
            
        course_id = self.request.query_params.get('course_id')
        learnership_id = self.request.query_params.get('learnership_id')
        
        if course_id:
            qs = qs.filter(course_id=course_id)
        if learnership_id:
            qs = qs.filter(learnership_id=learnership_id)
            
        return qs.order_by('-last_accessed')

    @action(detail=False, methods=['get'])
    def my_progress(self, request):
        """Current user's progress across all items"""
        progress = self.get_queryset().filter(user=request.user)
        serializer = self.get_serializer(progress, many=True)
        
        # Add summary stats
        summary = {
            "total_items": progress.count(),
            "avg_progress": progress.aggregate(avg=Avg('progress_percentage'))['avg'] or 0,
            "completed": progress.filter(progress_percentage=100).count(),
        }
        
        return Response({
            "summary": summary,
            "progress": serializer.data
        })


class ActivityLogViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Detailed user activity logs (audit trail)
    """
    queryset = ActivityLog.objects.all()
    serializer_class = ActivityLogSerializer
    permission_classes = [IsAuthenticated, IsAdminUser]

    def get_queryset(self):
        qs = super().get_queryset().select_related('user', 'course', 'learnership')
        
        user_id = self.request.query_params.get('user_id')
        activity_type = self.request.query_params.get('type')
        start_date = self.request.query_params.get('start_date')
        end_date = self.request.query_params.get('end_date')
        
        if user_id:
            qs = qs.filter(user_id=user_id)
        if activity_type:
            qs = qs.filter(activity_type=activity_type)
        if start_date:
            qs = qs.filter(timestamp__date__gte=start_date)
        if end_date:
            qs = qs.filter(timestamp__date__lte=end_date)
            
        return qs.order_by('-timestamp')