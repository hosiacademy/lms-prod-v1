from rest_framework import serializers
from .models import (
    CommissionTier,
    PartnerBenefit,
    PartnerProgramInfo,
    PartnerApplication,
)


class CommissionTierSerializer(serializers.ModelSerializer):
    """Serializer for commission tiers."""
    sales_range = serializers.CharField(source='get_sales_range_display', read_only=True)

    class Meta:
        model = CommissionTier
        fields = [
            'id',
            'tier_code',
            'display_name',
            'description',
            'sales_range',
            'min_sales',
            'max_sales',
            'commission_rate',
            'color_code',
            'display_order',
            'is_active',
        ]


class PartnerBenefitSerializer(serializers.ModelSerializer):
    """Serializer for partner benefits."""

    class Meta:
        model = PartnerBenefit
        fields = [
            'id',
            'title',
            'description',
            'icon_name',
            'display_order',
            'is_active',
            'is_featured',
        ]


class PartnerProgramInfoSerializer(serializers.ModelSerializer):
    """Serializer for partner program information."""

    class Meta:
        model = PartnerProgramInfo
        fields = [
            'introduction',
            'mission_title',
            'mission_description',
            'who_should_apply_intro',
            'cta_title',
            'cta_description',
            'contact_email',
            'contact_phone',
            'is_active',
        ]


class PartnerApplicationSerializer(serializers.ModelSerializer):
    """Serializer for partner applications."""

    class Meta:
        model = PartnerApplication
        fields = [
            'id',
            'full_name',
            'email',
            'phone',
            'business_name',
            'partner_type',
            'country',
            'social_media_handles',
            'estimated_reach',
            'marketing_experience',
            'target_regions',
            'why_partner',
            'status',
            'applied_at',
        ]
        read_only_fields = ['id', 'status', 'applied_at']


class PartnerProgramPublicSerializer(serializers.Serializer):
    """
    Combined serializer for public partner program page.
    Returns all necessary data in one call.
    """
    info = PartnerProgramInfoSerializer()
    commission_tiers = CommissionTierSerializer(many=True)
    benefits = PartnerBenefitSerializer(many=True)
