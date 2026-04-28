# apps/enrollments/serializers.py
from rest_framework import serializers
from .models import ProvisionalEnrollment


class ProvisionalEnrollmentSerializer(serializers.ModelSerializer):
    """Serializer for provisional enrollment responses"""
    is_expired = serializers.ReadOnlyField()

    class Meta:
        model = ProvisionalEnrollment
        fields = [
            'id', 'user', 'programme', 'enrollment_type', 'status',
            'created_at', 'expires_at', 'reference_code',
            'prerequisites_verified', 'verification_notes',
            'is_expired', 'metadata'
        ]
        read_only_fields = ['id', 'created_at', 'reference_code', 'is_expired']


class ProvisionalEnrollmentCreateSerializer(serializers.Serializer):
    """Serializer for creating provisional enrollments"""
    programme_id = serializers.IntegerField(required=False, allow_null=True)
    enrollment_type = serializers.ChoiceField(
        choices=['masterclass', 'learnership', 'industry', 'custom_selection']
    )
    payment_method = serializers.CharField(default='cash')
    corporate_details = serializers.JSONField(required=False, allow_null=True)
    individual_details = serializers.JSONField(required=False, allow_null=True)
