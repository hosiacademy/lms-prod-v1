# apps/instructors/serializers_hours_claims.py
"""
Serializers for Instructor Hours Claims Management
"""

from rest_framework import serializers
from django.conf import settings
from django.contrib.auth import get_user_model
from django.utils import timezone
from .models_hours_claims import (
    InstructorHoursClaim,
    InstructorOvertime,
    InstructorPayrollSummary
)
from .models import Instructor

User = get_user_model()


class InstructorHoursClaimSerializer(serializers.ModelSerializer):
    """Serializer for InstructorHoursClaim model."""

    instructor_name = serializers.CharField(
        source='instructor.user.name',
        read_only=True
    )

    instructor_email = serializers.EmailField(
        source='instructor.user.email',
        read_only=True
    )

    month_label = serializers.CharField(
        source='get_month_year_label',
        read_only=True
    )

    reviewed_by_name = serializers.CharField(
        source='reviewed_by.name',
        read_only=True
    )

    # Calculated fields
    session_count = serializers.IntegerField(read_only=True)
    average_session_duration = serializers.FloatField(read_only=True)

    # Helper fields
    can_submit = serializers.BooleanField(read_only=True)
    can_review = serializers.BooleanField(read_only=True)
    can_approve = serializers.BooleanField(read_only=True)
    can_reject = serializers.BooleanField(read_only=True)

    class Meta:
        model = InstructorHoursClaim
        fields = [
            'id', 'claim_id', 'instructor', 'instructor_name', 'instructor_email',
            'month', 'year', 'month_label',
            'regular_hours', 'overtime_hours', 'total_hours',
            'hourly_rate', 'overtime_rate_multiplier',
            'regular_pay', 'overtime_pay', 'total_claim_amount',
            'session_ids', 'session_breakdown',
            'session_count', 'average_session_duration',
            'overtime_justification', 'overtime_supporting_documents',
            'status', 'submitted_at', 'reviewed_by', 'reviewed_by_name',
            'reviewed_at', 'approval_notes', 'rejection_reason',
            'paid_at', 'payment_reference',
            'created_at', 'updated_at',
            'can_submit', 'can_review', 'can_approve', 'can_reject'
        ]
        read_only_fields = [
            'claim_id', 'total_hours', 'regular_pay', 'overtime_pay',
            'total_claim_amount', 'reviewed_by', 'reviewed_at',
            'paid_at', 'created_at', 'updated_at'
        ]

    def validate(self, data):
        """Validate hours claim data."""
        # Check for duplicate claims
        if self.instance is None:  # Creating new claim
            existing = InstructorHoursClaim.objects.filter(
                instructor=data.get('instructor'),
                month=data.get('month'),
                year=data.get('year'),
                status__in=['draft', 'pending', 'under_review', 'approved']
            ).exists()

            if existing:
                raise serializers.ValidationError({
                    'month': 'A claim for this month already exists'
                })

        # Validate overtime justification if overtime hours claimed
        if data.get('overtime_hours', 0) > 0:
            if not data.get('overtime_justification'):
                raise serializers.ValidationError({
                    'overtime_justification': 'Overtime justification is required when claiming overtime hours'
                })

        return data

    def create(self, validated_data):
        """Create a new hours claim."""
        return InstructorHoursClaim.objects.create(**validated_data)


class InstructorHoursClaimCreateSerializer(serializers.ModelSerializer):
    """Serializer for instructors to create hours claims."""

    class Meta:
        model = InstructorHoursClaim
        fields = [
            'month', 'year',
            'regular_hours', 'overtime_hours',
            'overtime_justification', 'overtime_supporting_documents',
        ]

    def create(self, validated_data):
        """Create a new hours claim for the current instructor."""
        instructor = self.context['request'].user.instructor
        validated_data['instructor'] = instructor
        validated_data['hourly_rate'] = instructor.hourly_rate
        validated_data['status'] = 'draft'
        return InstructorHoursClaim.objects.create(**validated_data)


class InstructorHoursClaimSubmitSerializer(serializers.Serializer):
    """Serializer for submitting hours claims for review."""

    session_ids = serializers.ListField(
        child=serializers.IntegerField(),
        required=True,
        help_text="List of BBB session IDs to include in claim"
    )

    def validate_session_ids(self, value):
        """Validate that sessions exist and belong to the instructor."""
        from apps.bbb_integration.models import LiveSession
        
        instructor = self.context['request'].user.instructor
        sessions = LiveSession.objects.filter(
            id__in=value,
            instructor=instructor,
            status='completed'
        )

        if len(sessions) != len(value):
            raise serializers.ValidationError(
                "Some sessions do not exist or are not completed"
            )

        return value


class InstructorHoursClaimReviewSerializer(serializers.Serializer):
    """Serializer for HR Admin reviewing hours claims."""

    status = serializers.ChoiceField(
        choices=InstructorHoursClaim.STATUS_CHOICES,
        required=True
    )

    approval_notes = serializers.CharField(
        required=False,
        allow_blank=True
    )

    rejection_reason = serializers.CharField(
        required=False,
        allow_blank=True
    )

    payment_reference = serializers.CharField(
        required=False,
        allow_blank=True
    )

    def validate(self, data):
        """Validate status-specific requirements."""
        status = data.get('status')

        if status == 'approved':
            if not data.get('payment_reference'):
                raise serializers.ValidationError({
                    'payment_reference': 'Payment reference is required for approved claims'
                })

        if status == 'rejected' and not data.get('rejection_reason'):
            raise serializers.ValidationError({
                'rejection_reason': 'Rejection reason is required for rejected claims'
            })

        return data


class InstructorOvertimeSerializer(serializers.ModelSerializer):
    """Serializer for InstructorOvertime model."""

    instructor_name = serializers.CharField(
        source='instructor.user.name',
        read_only=True
    )

    instructor_email = serializers.EmailField(
        source='instructor.user.email',
        read_only=True
    )

    reviewed_by_name = serializers.CharField(
        source='reviewed_by.name',
        read_only=True
    )

    hours_claim_id = serializers.CharField(
        source='hours_claim.claim_id',
        read_only=True,
        allow_null=True
    )

    class Meta:
        model = InstructorOvertime
        fields = [
            'id', 'overtime_id', 'instructor', 'instructor_name', 'instructor_email',
            'overtime_date', 'hours_requested', 'reason', 'supporting_document',
            'hours_claim', 'hours_claim_id',
            'status', 'reviewed_by', 'reviewed_by_name',
            'reviewed_at', 'approval_notes', 'rejection_reason',
            'created_at', 'updated_at'
        ]
        read_only_fields = [
            'overtime_id', 'reviewed_by', 'reviewed_at',
            'created_at', 'updated_at'
        ]


class InstructorOvertimeCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating overtime requests."""

    class Meta:
        model = InstructorOvertime
        fields = [
            'overtime_date', 'hours_requested', 'reason', 'supporting_document',
        ]

    def create(self, validated_data):
        """Create a new overtime request."""
        instructor = self.context['request'].user.instructor
        validated_data['instructor'] = instructor
        return InstructorOvertime.objects.create(**validated_data)


class InstructorPayrollSummarySerializer(serializers.ModelSerializer):
    """Serializer for InstructorPayrollSummary model."""

    processed_by_name = serializers.CharField(
        source='processed_by.name',
        read_only=True
    )

    class Meta:
        model = InstructorPayrollSummary
        fields = [
            'id', 'month', 'year', 'total_instructors',
            'total_regular_hours', 'total_overtime_hours',
            'total_payroll_amount', 'total_paid_amount', 'total_pending_amount',
            'total_claims', 'approved_claims', 'pending_claims',
            'processed_by', 'processed_by_name', 'processed_at',
            'created_at', 'updated_at'
        ]
        read_only_fields = fields
