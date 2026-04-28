from rest_framework import serializers
from .models import CertificationTrack, CertificationItem
from apps.payments.serializer_fields import LocalizedPriceField, CurrencyField, FormattedPriceField

class CertificationItemSerializer(serializers.ModelSerializer):
    # Localized pricing for cert cost
    cert_cost_localized = LocalizedPriceField(source='cert_cost', read_only=True)
    formatted_cert_cost = FormattedPriceField(source='*', price_field='cert_cost', read_only=True)
    
    class Meta:
        model = CertificationItem
        fields = ['id', 'name', 'description', 'phase', 'cert_cost', 'cert_cost_localized', 
                  'formatted_cert_cost', 'order']

class CertificationTrackSerializer(serializers.ModelSerializer):
    certifications = CertificationItemSerializer(many=True, read_only=True)
    
    # Localized pricing fields
    total_cert_cost_localized = LocalizedPriceField(source='total_cert_cost', read_only=True)
    platform_cost_localized = LocalizedPriceField(source='platform_cost', read_only=True)
    instructor_cost_localized = LocalizedPriceField(source='instructor_cost', read_only=True)
    total_cost_localized = LocalizedPriceField(source='total_cost', read_only=True)
    sales_price_localized = LocalizedPriceField(source='sales_price', read_only=True)
    monthly_price_localized = LocalizedPriceField(source='monthly_price', read_only=True)
    gross_margin_localized = LocalizedPriceField(source='gross_margin', read_only=True)
    
    formatted_total_cert_cost = FormattedPriceField(source='*', price_field='total_cert_cost', read_only=True)
    formatted_platform_cost = FormattedPriceField(source='*', price_field='platform_cost', read_only=True)
    formatted_instructor_cost = FormattedPriceField(source='*', price_field='instructor_cost', read_only=True)
    formatted_total_cost = FormattedPriceField(source='*', price_field='total_cost', read_only=True)
    formatted_sales_price = FormattedPriceField(source='*', price_field='sales_price', read_only=True)
    formatted_monthly_price = FormattedPriceField(source='*', price_field='monthly_price', read_only=True)
    formatted_gross_margin = FormattedPriceField(source='*', price_field='gross_margin', read_only=True)

    class Meta:
        model = CertificationTrack
        fields = ['id', 'name', 'track_type', 'description', 'total_cert_cost',
                  'platform_cost', 'instructor_cost', 'total_cost', 'sales_price',
                  'monthly_price', 'gross_margin', 'certifications',
                  'total_cert_cost_localized', 'platform_cost_localized', 
                  'instructor_cost_localized', 'total_cost_localized',
                  'sales_price_localized', 'monthly_price_localized', 'gross_margin_localized',
                  'formatted_total_cert_cost', 'formatted_platform_cost',
                  'formatted_instructor_cost', 'formatted_total_cost',
                  'formatted_sales_price', 'formatted_monthly_price', 'formatted_gross_margin']
