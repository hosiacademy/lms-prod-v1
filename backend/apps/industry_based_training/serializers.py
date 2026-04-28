from rest_framework import serializers
from .models import AiCertsCourse, Offering
from apps.payments.serializer_fields import LocalizedPriceField, CurrencyField, FormattedPriceField


class AiCertsCourseSerializer(serializers.ModelSerializer):
    """
    Public serializer for Hosi Academy offered AICERTS courses.
    """

    # RAW-backed fields (read-only proxies)
    title = serializers.CharField(read_only=True)
    description = serializers.CharField(read_only=True)
    categories = serializers.CharField(read_only=True)
    certificate_badge_url = serializers.URLField(read_only=True)
    feature_image_url = serializers.URLField(read_only=True)
    lms_id = serializers.CharField(read_only=True)

    # Display helpers
    duration_display = serializers.CharField(read_only=True)
    offering_period_display = serializers.CharField(read_only=True)
    location_display = serializers.CharField(read_only=True)

    # Pricing localization
    price = LocalizedPriceField(source='our_price_usd', read_only=True)
    currency = CurrencyField(read_only=True)
    formatted_price = FormattedPriceField(source='*', price_field='our_price_usd', read_only=True)

    class Meta:
        model = AiCertsCourse
        fields = [
            "id",
            "course_id",
            "title",
            "description",
            "categories",
            "certificate_badge_url",
            "feature_image_url",
            "lms_id",
            "is_offered",
            "active",
            "duration_days",
            "duration_display",
            "offering_start",
            "offering_end",
            "offering_period_display",
            "our_price_usd",
            "price",
            "currency",
            "formatted_price",
            "country",
            "city",
            "venue",
            "location_display",
            "last_synced",
        ]
        read_only_fields = fields


class OfferingSerializer(serializers.ModelSerializer):
    """
    Serializer for commercial Offering packages.
    """

    courses = serializers.SerializerMethodField()
    
    # Localized Pricing
    price = LocalizedPriceField(source='price_usd', read_only=True)
    currency = CurrencyField(read_only=True)
    formatted_price = FormattedPriceField(source='*', price_field='price_usd', read_only=True)

    class Meta:
        model = Offering
        fields = [
            "id",
            "name",
            "description",
            "price_usd",
            "price",
            "currency",
            "formatted_price",
            "updated_at",
            "courses",
        ]
        read_only_fields = fields

    def get_courses(self, obj):
        qs = obj.courses.filter(is_offered=True).select_related("raw_course", "industry")
        return AiCertsCourseSerializer(qs, many=True, context=self.context).data
