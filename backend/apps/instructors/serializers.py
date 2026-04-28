# apps/instructors/serializers.py

from rest_framework import serializers
from django.contrib.auth import get_user_model

from .models import Instructor, CourseAssignment, InstructorRating
from .serializers_instructor_application import (
    InstructorApplicationSerializer,
    InstructorApplicationCreateSerializer,
    InstructorApplicationReviewSerializer,
    InstructorStatusLogSerializer,
    InstructorAnalyticsSerializer,
    InstructorAnalyticsSummarySerializer
)

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model."""
    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'name']


class InstructorSerializer(serializers.ModelSerializer):
    """Serializer for Instructor model."""
    user = UserSerializer(read_only=True)
    current_course_count = serializers.IntegerField(read_only=True)
    utilization_rate = serializers.FloatField(read_only=True)

    class Meta:
        model = Instructor
        fields = [
            'id', 'instructor_id', 'user', 'instructor_type',
            'employee_number', 'department', 'specialization',
            'qualifications', 'years_experience',
            'work_phone', 'work_email', 'office_location',
            'is_available', 'is_active', 'max_courses',
            'overall_rating', 'performance_band',
            'total_courses_taught', 'total_students_taught',
            'average_student_rating', 'completion_rate',
            'date_hired', 'contract_expiry',
            'current_course_count', 'utilization_rate',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'instructor_id', 'overall_rating', 'performance_band',
            'total_courses_taught', 'total_students_taught',
            'average_student_rating', 'completion_rate',
            'current_course_count', 'utilization_rate',
            'created_at', 'updated_at'
        ]


class CourseAssignmentSerializer(serializers.ModelSerializer):
    """Serializer for CourseAssignment model."""
    instructor = InstructorSerializer(read_only=True)
    assigned_by = UserSerializer(read_only=True)

    class Meta:
        model = CourseAssignment
        fields = [
            'id', 'assignment_id', 'instructor', 'course',
            'status', 'assigned_by', 'assigned_date',
            'start_date', 'expected_end_date', 'actual_end_date',
            'assignment_notes', 'created_at', 'updated_at'
        ]
        read_only_fields = [
            'assignment_id', 'assigned_by', 'assigned_date',
            'created_at', 'updated_at'
        ]


class InstructorRatingSerializer(serializers.ModelSerializer):
    """Serializer for InstructorRating model."""
    instructor = InstructorSerializer(read_only=True)
    student = UserSerializer(read_only=True)

    class Meta:
        model = InstructorRating
        fields = [
            'id', 'instructor', 'course', 'student',
            'rating', 'review', 'created_at', 'updated_at'
        ]
        read_only_fields = ['created_at', 'updated_at']


class PerformanceMetricsSerializer(serializers.Serializer):
    """Serializer for performance metrics."""
    instructor_id = serializers.CharField()
    overall_rating = serializers.FloatField()
    performance_band = serializers.CharField()
    average_student_rating = serializers.FloatField()
    completion_rate = serializers.FloatField()
    total_courses = serializers.IntegerField()
    total_students = serializers.IntegerField()


class AssignmentSuggestionSerializer(serializers.Serializer):
    """Serializer for assignment suggestions."""
    instructor = InstructorSerializer()
    course = serializers.CharField()
    match_score = serializers.FloatField()
    match_reasons = serializers.ListField(child=serializers.CharField())
