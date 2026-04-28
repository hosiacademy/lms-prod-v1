"""
Custom Serializer Fields for Automatic Currency Conversion

These fields automatically convert USD prices to the user's local currency
based on their IP address (detected by CurrencyDetectionMiddleware).

Usage:
    from apps.payments.serializer_fields import LocalizedPriceField

    class ProgrammeSerializer(serializers.ModelSerializer):
        price = LocalizedPriceField(source='cost_usd')
        currency = CurrencyField()

        class Meta:
            model = Programme
            fields = ['id', 'title', 'price', 'currency']
"""

from rest_framework import serializers
from decimal import Decimal
import logging

from .services.currency_service import CurrencyConversionService

logger = logging.getLogger(__name__)


class LocalizedPriceField(serializers.Field):
    """
    Automatically converts USD price to user's local currency.

    Reads from request.user_currency (set by CurrencyDetectionMiddleware)
    and converts the price from USD to that currency.

    Input (database): Decimal in USD (e.g., Decimal('100.00'))
    Output (API): Decimal in local currency (e.g., Decimal('12950.00') for KES)
    """

    def __init__(self, base_currency='USD', **kwargs):
        self.base_currency = base_currency
        super().__init__(**kwargs)

    def to_representation(self, value):
        """
        Convert USD value to user's local currency.
        """
        if value is None:
            return None

        # 1. Determine target currency
        request = self.context.get('request')
        target_currency = getattr(request, 'user_currency', 'USD') if request else 'USD'

        # 2. Convert value to Decimal if it isn't already
        try:
            if not isinstance(value, Decimal):
                val_decimal = Decimal(str(value))
            else:
                val_decimal = value
        except (ValueError, TypeError):
            logger.error(f"Cannot convert {value} to Decimal")
            return value

        # 3. If already in target currency, return float
        if target_currency == self.base_currency:
            return float(val_decimal)

        try:
            converted = CurrencyConversionService.convert_amount(
                val_decimal,
                self.base_currency,
                target_currency
            )
            return float(converted)
        except Exception as e:
            logger.error(f"Price conversion failed: {str(e)}")
            return float(val_decimal)


class CurrencyField(serializers.Field):
    """
    Returns the user's current currency code.
    """
    def __init__(self, **kwargs):
        kwargs['read_only'] = True
        super().__init__(**kwargs)

    def to_representation(self, value):
        request = self.context.get('request')
        return getattr(request, 'user_currency', 'USD') if request else 'USD'


class FormattedPriceField(serializers.Field):
    """
    Returns a formatted price string with currency symbol.
    """
    def __init__(self, price_field='cost_usd', **kwargs):
        self.price_field = price_field
        kwargs['read_only'] = True
        super().__init__(**kwargs)

    def to_representation(self, value):
        """Format price with currency"""
        # If value is None, try to get it from the parent object if value is the object
        price = None
        if isinstance(value, (int, float, Decimal)):
            price = value
        elif value is not None:
            # Value might be the model instance (if source='*') or generic object
            price = getattr(value, self.price_field, None)
        
        if price is None:
            return None

        request = self.context.get('request')
        currency = getattr(request, 'user_currency', 'USD') if request else 'USD'

        try:
            price_dec = Decimal(str(price))
            if currency != 'USD':
                price_dec = CurrencyConversionService.convert_amount(price_dec, 'USD', currency)
            return f"{currency} {price_dec:.0f}"
        except Exception as e:
            logger.error(f"Price formatting failed: {str(e)}")
            return f"{currency} {price}"


class LocalizedPriceSerializer(serializers.Serializer):
    """
    Complete price object with original and localized values.

    Output:
    {
        "original_price": 100.00,
        "original_currency": "USD",
        "localized_price": 12950.00,
        "localized_currency": "KES",
        "formatted_price": "KES 12,950.00",
        "exchange_rate": 129.50
    }
    """

    original_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    original_currency = serializers.CharField(max_length=3, default='USD')
    localized_price = serializers.DecimalField(max_digits=10, decimal_places=2)
    localized_currency = serializers.CharField(max_length=3)
    formatted_price = serializers.CharField()
    exchange_rate = serializers.DecimalField(max_digits=10, decimal_places=4)

    @classmethod
    def from_usd_price(cls, usd_price, request):
        """
        Create localized price object from USD price.

        Args:
            usd_price: Price in USD (Decimal or float)
            request: Django request object with user_currency

        Returns:
            Dict with price information
        """
        if not isinstance(usd_price, Decimal):
            usd_price = Decimal(str(usd_price))

        currency = getattr(request, 'user_currency', 'USD')

        # Get localized pricing
        pricing = CurrencyConversionService.get_localized_price(
            usd_price,
            currency,
            include_original=True
        )

        return {
            'original_price': float(pricing['original_amount']),
            'original_currency': pricing['original_currency'],
            'localized_price': float(pricing['amount']),
            'localized_currency': pricing['currency'],
            'formatted_price': pricing['formatted'],
            'exchange_rate': float(pricing['exchange_rate']),
        }


class CountryField(serializers.Field):
    """
    Returns the user's detected country code.

    Output: String country code (e.g., 'KE', 'NG', 'ZA')
    """

    def to_representation(self, value):
        """Return user's country from request context"""
        request = self.context.get('request')
        if not request:
            return 'ZA'

        return getattr(request, 'user_country', 'ZA')


# Convenience function for adding localized pricing to any serializer
def add_localized_pricing(serializer_class, price_field='cost_usd'):
    """
    Decorator to add automatic price localization to a serializer.

    Usage:
        @add_localized_pricing(price_field='cost_usd')
        class ProgrammeSerializer(serializers.ModelSerializer):
            class Meta:
                model = Programme
                fields = ['id', 'title', 'cost_usd']

    This will automatically add:
    - price: LocalizedPriceField (converted price)
    - currency: CurrencyField (user's currency)
    - formatted_price: FormattedPriceField (formatted string)
    """
    original_init = serializer_class.__init__

    def new_init(self, *args, **kwargs):
        original_init(self, *args, **kwargs)

        # Add localized fields
        self.fields['price'] = LocalizedPriceField(source=price_field)
        self.fields['currency'] = CurrencyField()
        self.fields['formatted_price'] = FormattedPriceField(price_field=price_field)

    serializer_class.__init__ = new_init
    return serializer_class
