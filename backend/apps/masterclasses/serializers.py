# apps/masterclasses/serializers.py
from rest_framework import serializers
from .models import Masterclass
from apps.payments.serializer_fields import LocalizedPriceField, CurrencyField, FormattedPriceField


class MasterclassSerializer(serializers.ModelSerializer):
    """Full serializer for masterclass detail view"""

    # Read-only computed fields
    duration_days = serializers.ReadOnlyField()
    seats_remaining = serializers.ReadOnlyField()
    is_full = serializers.ReadOnlyField()
    location_display = serializers.ReadOnlyField()
    is_upcoming = serializers.ReadOnlyField()
    is_past = serializers.ReadOnlyField()
    is_ongoing = serializers.ReadOnlyField()

    # Localized Pricing
    price_physical = LocalizedPriceField(source='price_physical')
    price_online = LocalizedPriceField(source='price_online')
    currency = CurrencyField(read_only=True)
    formatted_price_physical = FormattedPriceField(source='*', price_field='price_physical', read_only=True)
    formatted_price_online = FormattedPriceField(source='*', price_field='price_online', read_only=True)

    # Add country alias for backward compatibility
    country = serializers.CharField(source='country_name', read_only=True)
    price_usd = serializers.DecimalField(source='price_online', max_digits=10, decimal_places=2, read_only=True, help_text="Base USD price (alias to price_online for API compatibility)")
    price_physical_usd = serializers.DecimalField(source='price_physical', max_digits=10, decimal_places=2, read_only=True)
    price_online_usd = serializers.DecimalField(source='price_online', max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = Masterclass
        fields = [
            'id',
            'title',
            'slug',
            'description',
            'category',
            'stream_type',
            'tier',
            'focus_area',
            'country_code',
            'country_name',
            'country',  # Alias
            'city',
            'venue',
            'locations',  # Legacy field
            'start_date',
            'end_date',
            'price_physical',
            'price_online',
            'price_usd',  # Base USD price alias
            'price_physical_usd',  # Alias
            'price_online_usd',  # Alias
            'currency',
            'status',
            'is_featured',
            'max_participants',
            'current_participants',
            'provider_courses',
            'notes',
            'created_at',
            'updated_at',
            'has_online_option',
            # Computed properties
            'duration_days',
            'seats_remaining',
            'is_full',
            'formatted_price_physical',
            'formatted_price_online',
            'location_display',
            'is_upcoming',
            'is_past',
            'is_ongoing',
        ]
        read_only_fields = ['id', 'created_at', 'updated_at', 'slug', 'category']


class MasterclassListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for masterclass list view"""

    # Computed fields
    seats_remaining = serializers.ReadOnlyField()
    is_full = serializers.ReadOnlyField()

    # Localized Pricing
    price_physical = LocalizedPriceField(source='price_physical')
    price_online = LocalizedPriceField(source='price_online')
    currency = CurrencyField(read_only=True)
    formatted_price_physical = FormattedPriceField(source='*', price_field='price_physical', read_only=True)
    formatted_price_online = FormattedPriceField(source='*', price_field='price_online', read_only=True)

    # Aliases for backward compatibility
    country = serializers.CharField(source='country_name', read_only=True)
    price_usd = serializers.DecimalField(source='price_online', max_digits=10, decimal_places=2, read_only=True, help_text="Base USD price (alias to price_online for API compatibility)")
    price_physical_usd = serializers.DecimalField(source='price_physical', max_digits=10, decimal_places=2, read_only=True)
    price_online_usd = serializers.DecimalField(source='price_online', max_digits=10, decimal_places=2, read_only=True)

    class Meta:
        model = Masterclass
        fields = [
            'id',
            'title',
            'slug',
            'description',
            'status',
            'stream_type',
            'tier',
            'focus_area',
            'start_date',
            'end_date',
            'city',
            'country',
            'country_name',
            'venue',
            'price_physical',
            'price_online',
            'formatted_price_physical',
            'formatted_price_online',
            'price_usd',
            'price_physical_usd',
            'price_online_usd',
            'currency',
            'is_featured',
            'has_online_option',
            'seats_remaining',
            'is_full',
        ]
