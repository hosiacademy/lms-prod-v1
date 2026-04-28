# apps/aicerts_integration/serializers.py
"""
Serializers for AICERTs Partnership Integration
"""

from rest_framework import serializers
from .models import (
    AICertsEnrollment,
    AICertsInstructorDesignation,
    AICertsSyncLog,
    AICertsSSOSession
)
from apps.aicerts_courses.models import AiCertsCourse
from apps.users.models import User


class AICertsEnrollmentSerializer(serializers.ModelSerializer):
    """Serializer for AICERTs enrollment tracking"""

    user_email = serializers.EmailField(source='user.email', read_only=True)
    user_name = serializers.CharField(source='user.get_full_name', read_only=True)
    course_title = serializers.CharField(source='course.title', read_only=True)
    course_shortname = serializers.CharField(source='course.shortname', read_only=True)
    course_lms_id = serializers.IntegerField(source='course.lms_course_id', read_only=True)
    course_thumbnail = serializers.SerializerMethodField()
    sso_url = serializers.SerializerMethodField()

    class Meta:
        model = AICertsEnrollment
        fields = [
            'id',
            'user',
            'user_email',
            'user_name',
            'course',
            'course_title',
            'course_shortname',
            'course_lms_id',
            'course_thumbnail',
            'sso_url',
            'aicerts_enrollment_status',
            'aicerts_already_enrolled',
            'enrolled_at',
            'synced_at',
            'last_sync_attempt',
            'sync_attempts',
            'sync_error',
            'progress_percentage',
            'last_accessed_at',
            'completed_at',
            'certificate_issued_at',
            'created_at',
            'updated_at'
        ]
        read_only_fields = [
            'id',
            'user_email',
            'user_name',
            'course_title',
            'course_shortname',
            'course_lms_id',
            'course_thumbnail',
            'sso_url',
            'aicerts_enrollment_status',
            'aicerts_already_enrolled',
            'enrolled_at',
            'synced_at',
            'last_sync_attempt',
            'sync_attempts',
            'sync_error',
            'created_at',
            'updated_at'
        ]

    def get_course_thumbnail(self, obj):
        """Get course thumbnail URL"""
        if obj.course:
            return getattr(obj.course, 'feature_image_url', None)
        return None

    def get_sso_url(self, obj):
        """Generate SSO URL for course access if enrolled"""
        if obj.aicerts_enrollment_status != 'enrolled' or not obj.user.aicerts_user_id:
            return None
        try:
            from apps.aicerts_integration.services import SSOService
            return SSOService.generate_sso_url(
                email=obj.user.email,
                course_id=obj.course.lms_course_id if obj.course else None
            )
        except Exception:
            return None  # SSO generation failed


class EnrollUserSerializer(serializers.Serializer):
    """Serializer for enrolling a user in a course"""

    course_id = serializers.IntegerField(required=True)

    def validate_course_id(self, value):
        """Validate that course exists"""
        if not AiCertsCourse.objects.filter(id=value).exists():
            raise serializers.ValidationError("Course not found")
        return value


class GenerateSSOSerializer(serializers.Serializer):
    """Serializer for SSO URL generation"""

    course_id = serializers.IntegerField(required=False, allow_null=True)
    user_id = serializers.IntegerField(required=False, allow_null=True)

    def validate_course_id(self, value):
        """Validate that course exists if provided"""
        if value and not AiCertsCourse.objects.filter(id=value).exists():
            raise serializers.ValidationError("Course not found")
        return value


class AICertsInstructorDesignationSerializer(serializers.ModelSerializer):
    """Serializer for instructor designations"""

    instructor_name = serializers.CharField(source='instructor.get_full_name', read_only=True)
    instructor_email = serializers.EmailField(source='instructor.email', read_only=True)
    course_title = serializers.CharField(source='course.title', read_only=True)
    designated_by_name = serializers.CharField(source='designated_by.get_full_name', read_only=True, allow_null=True)

    class Meta:
        model = AICertsInstructorDesignation
        fields = [
            'id',
            'instructor',
            'instructor_name',
            'instructor_email',
            'course',
            'course_title',
            'aicerts_instructor_id',
            'designated_at',
            'designated_by',
            'designated_by_name',
            'is_active',
            'notes',
            'created_at',
            'updated_at'
        ]
        read_only_fields = [
            'id',
            'instructor_name',
            'instructor_email',
            'course_title',
            'designated_at',
            'designated_by',
            'designated_by_name',
            'created_at',
            'updated_at'
        ]

    def validate_instructor(self, value):
        """Validate that instructor is registered with AICERTs"""
        if not value.is_aicerts_instructor:
            raise serializers.ValidationError(
                "User must be a registered AICERTs instructor. "
                "Please set is_aicerts_instructor=True first."
            )
        return value


class AICertsSyncLogSerializer(serializers.ModelSerializer):
    """Serializer for sync operation logs"""

    user_email = serializers.EmailField(source='user.email', read_only=True, allow_null=True)
    course_title = serializers.CharField(source='course.title', read_only=True, allow_null=True)
    operation_type_display = serializers.CharField(source='get_operation_type_display', read_only=True)
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = AICertsSyncLog
        fields = [
            'id',
            'operation_type',
            'operation_type_display',
            'status',
            'status_display',
            'user',
            'user_email',
            'course',
            'course_title',
            'request_data',
            'response_data',
            'error_message',
            'duration_ms',
            'records_processed',
            'created_at'
        ]
        read_only_fields = '__all__'


class AICertsSSOSessionSerializer(serializers.ModelSerializer):
    """Serializer for SSO sessions"""

    user_email = serializers.EmailField(source='user.email', read_only=True)
    course_title = serializers.CharField(source='course.title', read_only=True, allow_null=True)

    class Meta:
        model = AICertsSSOSession
        fields = [
            'id',
            'user',
            'user_email',
            'course',
            'course_title',
            'session_token',
            'ip_address',
            'user_agent',
            'successful',
            'accessed_at',
            'expires_at',
            'created_at',
            'updated_at'
        ]
        read_only_fields = '__all__'
