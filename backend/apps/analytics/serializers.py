# apps/analytics/serializers.py
from rest_framework import serializers
from .models import PlatformAnalytics, CourseAnalytics, LearnershipAnalytics, UserProgress, ActivityLog


class PlatformAnalyticsSerializer(serializers.ModelSerializer):
    """
    Serializer for daily platform-wide metrics
    """
    class Meta:
        model = PlatformAnalytics
        fields = [
            'id',
            'date',
            'total_users',
            'active_users',
            'new_users',
            'page_views',
            'created_at',  # if you have timestamps
        ]
        read_only_fields = ['id', 'created_at']


class CourseAnalyticsSerializer(serializers.ModelSerializer):
    """
    Per-course daily analytics with course display name
    """
    course_title = serializers.CharField(source='course.title', read_only=True)
    course_shortname = serializers.CharField(source='course.shortname', read_only=True)
    completion_rate = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = CourseAnalytics
        fields = [
            'id',
            'course',
            'course_title',
            'course_shortname',
            'date',
            'views',
            'enrollments',
            'completions',
            'completion_rate',
        ]
        read_only_fields = ['id', 'course_title', 'course_shortname', 'completion_rate']

    def get_completion_rate(self, obj):
        """Calculate completion rate % (safe division)"""
        if obj.enrollments == 0:
            return 0.0
        return round((obj.completions / obj.enrollments) * 100, 2)


class LearnershipAnalyticsSerializer(serializers.ModelSerializer):
    """
    Per-learnership daily analytics with title
    """
    learnership_title = serializers.CharField(source='learnership.title', read_only=True)

    class Meta:
        model = LearnershipAnalytics
        fields = [
            'id',
            'learnership',
            'learnership_title',
            'date',
            'views',
            'enrollments',
            'completions',
        ]
        read_only_fields = ['id', 'learnership_title']


class UserProgressSerializer(serializers.ModelSerializer):
    """
    User progress per course/learnership
    """
    user_email = serializers.CharField(source='user.email', read_only=True)
    course_title = serializers.CharField(source='course.title', read_only=True, allow_null=True)
    learnership_title = serializers.CharField(source='learnership.title', read_only=True, allow_null=True)

    class Meta:
        model = UserProgress
        fields = [
            'id',
            'user',
            'user_email',
            'course',
            'course_title',
            'learnership',
            'learnership_title',
            'progress_percentage',
            'last_accessed',
        ]
        read_only_fields = ['id', 'user_email', 'course_title', 'learnership_title', 'last_accessed']


class ActivityLogSerializer(serializers.ModelSerializer):
    """
    Detailed user activity logs (for admin/audit use)
    """
    user_email = serializers.CharField(source='user.email', read_only=True, allow_null=True)
    activity_display = serializers.CharField(source='get_activity_type_display', read_only=True)
    course_title = serializers.CharField(source='course.title', read_only=True, allow_null=True)
    learnership_title = serializers.CharField(source='learnership.title', read_only=True, allow_null=True)

    class Meta:
        model = ActivityLog
        fields = [
            'id',
            'user',
            'user_email',
            'activity_type',
            'activity_display',
            'course',
            'course_title',
            'learnership',
            'learnership_title',
            'ip_address',
            'user_agent',
            'timestamp',
        ]
        read_only_fields = [
            'id', 'activity_display', 'user_email',
            'course_title', 'learnership_title', 'timestamp'
        ]