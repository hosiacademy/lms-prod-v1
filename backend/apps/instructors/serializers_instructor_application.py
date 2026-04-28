# apps/instructors/serializers_instructor_application.py

from rest_framework import serializers
from django.conf import settings
from django.contrib.auth import get_user_model
from .models_instructor_application import (
    InstructorApplication,
    InstructorStatusLog
)
from .models import InstructorAnalytics

User = get_user_model()


class InstructorApplicationSerializer(serializers.ModelSerializer):
    """Serializer for InstructorApplication model."""
    
    country_name = serializers.CharField(
        source='country.name',
        read_only=True
    )
    
    reviewed_by_name = serializers.CharField(
        source='reviewed_by.name',
        read_only=True
    )
    
    total_attachments = serializers.IntegerField(
        source='total_attachments_count',
        read_only=True
    )
    
    additional_attachments = serializers.SerializerMethodField()
    
    class Meta:
        model = InstructorApplication
        fields = [
            'id', 'application_id', 'applicant_name', 'applicant_email',
            'applicant_phone', 'professional_headline', 'areas_of_expertise',
            'top_qualifications', 'years_of_experience', 'motivation_letter',
            'cv_file', 'certificates_file', 'additional_attachments',
            'total_attachments', 'status', 'country', 'country_name',
            'main_streams', 'interested_masterclasses',
            'interested_learnerships', 'interested_custom_courses',
            'interested_industry_courses',
            'reviewed_by', 'reviewed_by_name', 'interview_status',
            'interview_datetime', 'interview_notes',
            'bbb_meeting_id', 'bbb_moderator_password', 'bbb_attendee_password',
            'rejection_reason', 'approval_notes',
            'submitted_at', 'reviewed_at', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'application_id', 'status', 'reviewed_by', 'reviewed_at',
            'created_at', 'updated_at', 'bbb_meeting_id',
            'bbb_moderator_password', 'bbb_attendee_password'
        ]
    
    def get_additional_attachments(self, obj):
        return obj.get_additional_attachments
    
    def validate_cv_file(self, value):
        """Validate CV file size and type."""
        max_size = 10 * 1024 * 1024  # 10MB
        allowed_extensions = ['.pdf', '.doc', '.docx']
        
        if value.size > max_size:
            raise serializers.ValidationError("CV file must not exceed 10MB")
        
        ext = value.name.split('.')[-1].lower()
        if f'.{ext}' not in allowed_extensions:
            raise serializers.ValidationError(
                "CV must be PDF, DOC, or DOCX format"
            )
        
        return value
    
    def validate_additional_attachment_1(self, value):
        """Validate additional attachment file size."""
        if value and value.size > 10 * 1024 * 1024:
            raise serializers.ValidationError("Each file must not exceed 10MB")
        return value
    
    # Repeat validation for other additional attachments
    validate_additional_attachment_2 = validate_additional_attachment_1
    validate_additional_attachment_3 = validate_additional_attachment_1
    validate_additional_attachment_4 = validate_additional_attachment_1
    validate_additional_attachment_5 = validate_additional_attachment_1


class InstructorApplicationCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating instructor applications (frontend submission)."""
    
    class Meta:
        model = InstructorApplication
        fields = [
            'applicant_name', 'applicant_email', 'applicant_phone',
            'professional_headline', 'areas_of_expertise',
            'top_qualifications', 'years_of_experience', 'motivation_letter',
            'cv_file', 'certificates_file',
            'additional_attachment_1', 'additional_attachment_2',
            'additional_attachment_3', 'additional_attachment_4',
            'additional_attachment_5',
            'country',
            'main_streams', 'interested_masterclasses',
            'interested_learnerships', 'interested_custom_courses',
            'interested_industry_courses',
        ]
    
    def create(self, validated_data):
        """Create a new instructor application."""
        return InstructorApplication.objects.create(**validated_data)


class InstructorApplicationReviewSerializer(serializers.Serializer):
    """Serializer for HR Admin reviewing applications."""
    
    status = serializers.ChoiceField(
        choices=InstructorApplication.STATUS_CHOICES
    )
    
    country = serializers.IntegerField(
        required=False,
        help_text="Country ID to assign application to"
    )
    
    interview_datetime = serializers.DateTimeField(
        required=False,
        allow_null=True
    )
    
    interview_notes = serializers.CharField(
        required=False,
        allow_blank=True
    )
    
    rejection_reason = serializers.CharField(
        required=False,
        allow_blank=True
    )
    
    approval_notes = serializers.CharField(
        required=False,
        allow_blank=True
    )
    
    def validate(self, data):
        """Validate status-specific requirements."""
        status = data.get('status')
        
        if status == 'rejected' and not data.get('rejection_reason'):
            raise serializers.ValidationError({
                'rejection_reason': 'Rejection reason is required for rejected applications'
            })
        
        if status == 'approved' and not data.get('approval_notes'):
            raise serializers.ValidationError({
                'approval_notes': 'Approval notes are required for approved applications'
            })
        
        if status == 'interview_scheduled' and not data.get('interview_datetime'):
            raise serializers.ValidationError({
                'interview_datetime': 'Interview datetime is required when scheduling interview'
            })
        
        return data


class InstructorStatusLogSerializer(serializers.ModelSerializer):
    """Serializer for InstructorStatusLog model."""
    
    instructor_name = serializers.CharField(
        source='instructor.name',
        read_only=True
    )
    
    instructor_email = serializers.EmailField(
        source='instructor.email',
        read_only=True
    )
    
    changed_by_name = serializers.CharField(
        source='changed_by.name',
        read_only=True
    )
    
    class Meta:
        model = InstructorStatusLog
        fields = [
            'id', 'instructor', 'instructor_name', 'instructor_email',
            'previous_status', 'new_status', 'reason',
            'changed_by', 'changed_by_name', 'changed_at'
        ]
        read_only_fields = ['changed_at']


class InstructorAnalyticsSerializer(serializers.ModelSerializer):
    """Serializer for InstructorAnalytics model."""
    
    instructor_name = serializers.CharField(
        source='instructor.name',
        read_only=True
    )
    
    instructor_email = serializers.EmailField(
        source='instructor.email',
        read_only=True
    )
    
    country_name = serializers.CharField(
        source='country.name',
        read_only=True
    )
    
    class Meta:
        model = InstructorAnalytics
        fields = [
            'id', 'instructor', 'instructor_name', 'instructor_email',
            'country', 'country_name', 'period_start', 'period_end',
            'total_courses_taught', 'total_students_taught',
            'average_rating', 'course_completion_rate',
            'student_retention_rate', 'total_earnings',
            'total_live_sessions', 'total_session_attendance',
            'status', 'calculated_at'
        ]
        read_only_fields = ['calculated_at']


class InstructorAnalyticsSummarySerializer(serializers.Serializer):
    """Serializer for instructor analytics summary."""
    
    country = serializers.CharField()
    country_name = serializers.CharField()
    total_instructors = serializers.IntegerField()
    active_instructors = serializers.IntegerField()
    inactive_instructors = serializers.IntegerField()
    suspended_instructors = serializers.IntegerField()
    average_rating = serializers.FloatField()
    total_courses = serializers.IntegerField()
    total_students = serializers.IntegerField()
    total_earnings = serializers.DecimalField(
        max_digits=12,
        decimal_places=2
    )
