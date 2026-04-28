# apps/aicerts_courses/serializers.py
from rest_framework import serializers
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response
from .models import AiCertsCourse
from apps.payments.serializer_fields import LocalizedPriceField, CurrencyField, FormattedPriceField


class CustomPagination(PageNumberPagination):
    """Custom pagination class to match real AICERTs API style"""
    page_size = 10
    page_size_query_param = 'per_page'
    max_page_size = 100

    def get_paginated_response(self, data):
        return Response({
            'success': True,
            'page': self.page.number,
            'per_page': self.page.paginator.per_page,
            'total': self.page.paginator.count,
            'total_pages': self.page.paginator.num_pages,
            'data': data
        })


class AiCertsCourseListSerializer(serializers.ModelSerializer):
    """Serializer that matches the exact structure of real AICERTs API list endpoint"""
    title = serializers.CharField(read_only=True)
    categories = serializers.SerializerMethodField()  # Split string to array
    description = serializers.CharField(source='summary', allow_null=True)  # Use summary as description
    stream_type = serializers.CharField(read_only=True)

    price_individual = LocalizedPriceField(read_only=True)
    currency = CurrencyField(read_only=True)
    formatted_price = FormattedPriceField(source='*', price_field='price_individual', read_only=True)

    class Meta:
        model = AiCertsCourse
        fields = [
            'id',
            'lms_course_id',
            'title',
            'feature_image_url',
            'feature_image_jpg_url',
            'certificate_badge_url',
            'certificate_image_jpg_url',
            'categories',
            'description',
            'stream_type',
            'price_individual',
            'currency',
            'formatted_price',
        ]

    def get_categories(self, obj):
        """Split category_name string into list (as in real API)"""
        if obj.category_name:
            return [cat.strip() for cat in obj.category_name.split(',')]
        return []


class AiCertsCourseSerializer(serializers.ModelSerializer):
    """Full detail serializer (for single course)"""
    title = serializers.CharField(read_only=True)
    categories = serializers.SerializerMethodField()
    description = serializers.CharField(source='summary', allow_null=True, read_only=True)
    stream_type = serializers.CharField(read_only=True)

    price_individual = LocalizedPriceField(read_only=True)
    price_package = LocalizedPriceField(read_only=True)
    currency = CurrencyField(read_only=True)
    formatted_price = FormattedPriceField(source='*', price_field='price_individual', read_only=True)

    class Meta:
        model = AiCertsCourse
        fields = [
            'id',
            'lms_course_id',
            'title',
            'shortname',
            'certificate_badge_url',
            'certificate_image_jpg_url',
            'feature_image_url',
            'feature_image_jpg_url',
            'ai_tools',
            'categories',
            'description',
            'provider',
            'stream_type',
            'price_individual',
            'price_package',
            'currency',
            'formatted_price',
            'is_in_package',
            'package_name',
            'is_self_paced',
            'is_offered',
            'raw_data',
            'last_synced',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['last_synced', 'created_at', 'updated_at']

    def get_categories(self, obj):
        if obj.category_name:
            return [cat.strip() for cat in obj.category_name.split(',')]
        return []


# Optional: Pricing summary method (keep if useful)
def get_pricing_summary(self, obj):
    summary = {}
    if obj.price_individual:
        summary['individual'] = {'price': float(obj.price_individual), 'currency': 'USD'}
    if obj.is_in_package and obj.package_name:
        summary['package'] = {
            'name': obj.package_name,
            'price': float(obj.price_package) if obj.price_package else None,
            'currency': 'USD'
        }
    return summary if summary else None