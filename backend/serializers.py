# apps/aicerts_courses/serializers.py
from rest_framework import serializers
from .models import AiCertsCourse  # ONLY AiCertsCourse, no Masterclass or TrainingStream


class AiCertsCourseSerializer(serializers.ModelSerializer):
    """Serializer for AiCertsCourse model"""

    # Optional: Add computed fields or custom serialization
    pricing_summary = serializers.SerializerMethodField()
    is_available = serializers.BooleanField(source='is_offered', read_only=True)

    class Meta:
        model = AiCertsCourse
        fields = [
            'id',
            'external_id',
            'fullname',
            'shortname',
            'summary',
            'provider',
            'category_name',
            'feature_image_url',
            'certificate_badge_url',
            'lms_course_id',
            'price_individual',
            'price_package',
            'is_in_package',
            'package_name',
            'is_self_paced',
            'is_offered',
            'is_available',  # Computed field
            'raw_data',
            'last_synced',
            'created_at',
            'updated_at',
            'pricing_summary',  # Computed field
        ]
        read_only_fields = ['last_synced', 'created_at', 'updated_at']

    def get_pricing_summary(self, obj):
        """Generate a pricing summary for the course"""
        summary = {}
        if obj.price_individual:
            summary['individual'] = {
                'price': float(obj.price_individual),
                'currency': 'USD'
            }
        if obj.is_in_package and obj.package_name:
            summary['package'] = {
                'name': obj.package_name,
                'price': float(obj.price_package) if obj.price_package else None,
                'currency': 'USD'
            }
        return summary if summary else None


# Optional: Simplified serializers for list views
class AiCertsCourseListSerializer(serializers.ModelSerializer):
    """Simplified serializer for listing AiCerts courses"""

    class Meta:
        model = AiCertsCourse
        fields = [
            'id',
            'fullname',
            'shortname',
            'category_name',
            'feature_image_url',
            'price_individual',
            'is_self_paced',
            'is_offered',
        ]
