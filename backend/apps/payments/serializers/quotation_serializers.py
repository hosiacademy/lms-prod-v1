from rest_framework import serializers
from ..quotation_models import ClientQuotation, QuotationItem, TrainingType
from apps.localization.models import Country

class QuotationItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuotationItem
        fields = [
            'id', 'training_type', 'item_id', 'item_code', 
            'description', 'quantity', 'stream', 'unit_price_usd', 'total_price_usd'
        ]
        read_only_fields = ['total_price_usd']

class ClientQuotationSerializer(serializers.ModelSerializer):
    additional_items = QuotationItemSerializer(many=True, read_only=True)
    created_by_name = serializers.ReadOnlyField(source='created_by.name')
    country_name = serializers.ReadOnlyField(source='client_country.name')
    country_code = serializers.ReadOnlyField(source='client_country.code')

    class Meta:
        model = ClientQuotation
        fields = [
            'id', 'quotation_number', 'quotation_type', 'client_name', 'client_email', 'client_phone',
            'recipients', 'client_company', 'client_country', 'country_name', 'country_code',
            'client_address', 'client_reference_code', 'local_currency', 'exchange_rate',
            'is_universal', 'subtotal_usd', 'discount_percentage', 'discount_amount_usd',
            'tax_amount_usd', 'total_amount_usd', 'total_amount_local',
            'introduction', 'prerequisites', 'description', 'validity_days',
            'status', 'smatpay_payment_link', 'email_sent', 'email_sent_at',
            'created_by_name', 'created_at', 'expires_at', 'additional_items'
        ]
        read_only_fields = [
            'quotation_number', 'subtotal_usd', 'discount_amount_usd', 
            'total_amount_usd', 'total_amount_local', 'created_at', 'expires_at'
        ]
