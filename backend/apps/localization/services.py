
from decimal import Decimal

class CurrencyService:
    """
    Service for handling currency conversions and formatting.
    Note: Using hardcoded approximate rates for demonstration.
    In production, this should fetch live rates from an external API or database.
    """

    # Base: USD
    EXCHANGE_RATES = {
        'USD': Decimal('1.0'),
        'ZAR': Decimal('18.5'),  # South Africa
        'NGN': Decimal('1600.0'), # Nigeria
        'KES': Decimal('130.0'), # Kenya
        'GHS': Decimal('15.5'),  # Ghana
        'UGX': Decimal('3700.0'), # Uganda
        'TZS': Decimal('2600.0'), # Tanzania
        'EUR': Decimal('0.92'),  # Eurozone
        'GBP': Decimal('0.79'),  # UK
        'RWF': Decimal('1300.0'), # Rwanda
    }

    COUNTRY_CURRENCY_MAP = {
        'ZA': 'ZAR',
        'NG': 'NGN',
        'KE': 'KES',
        'GH': 'GHS',
        'UG': 'UGX',
        'TZ': 'TZS',
        'RW': 'RWF',
        'GB': 'GBP',
        'US': 'USD',
        # Default to USD for others or map to nearest region
    }

    @classmethod
    def get_currency_for_country(cls, country_code):
        """Get the currency code for a given country code (ISO 2 char)."""
        if not country_code:
            return 'USD'
        return cls.COUNTRY_CURRENCY_MAP.get(country_code.upper(), 'USD')

    @classmethod
    def convert_usd_to_local(cls, usd_amount, country_code):
        """
        Convert USD amount to local currency for a country.
        Returns tuple: (local_amount, currency_code)
        """
        if usd_amount is None:
            return (None, 'USD')

        currency_code = cls.get_currency_for_country(country_code)
        rate = cls.EXCHANGE_RATES.get(currency_code, Decimal('1.0'))
        
        # Ensure usd_amount is Decimal
        if not isinstance(usd_amount, Decimal):
            try:
                usd_amount = Decimal(str(usd_amount))
            except:
                return (None, 'USD')

        local_amount = usd_amount * rate
        return (local_amount, currency_code)
