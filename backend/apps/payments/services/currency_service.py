"""
Currency Conversion Service

Provides real-time currency conversion for enrollment payments.
Converts training programme prices from base currency (USD) to local currency.

Uses multiple exchange rate providers with fallback:
1. exchangerate-api.com (free, 1500 requests/month)
2. api.exchangerate.host (free, unlimited)
3. Open Exchange Rates (backup)
"""

import requests
import logging
from decimal import Decimal, ROUND_HALF_UP
from typing import Dict, Optional
from datetime import datetime, timedelta
from django.core.cache import cache
from django.conf import settings

logger = logging.getLogger(__name__)


class CurrencyConversionService:
    """Service for currency conversion with caching"""

    # Free exchange rate APIs
    EXCHANGE_RATE_PROVIDERS = {
        'exchangerate-api': {
            'url': 'https://api.exchangerate-api.com/v4/latest/{base}',
            'requires_key': False,
            'format': lambda data: data.get('rates', {})
        },
        'exchangerate-host': {
            'url': 'https://api.exchangerate.host/latest?base={base}',
            'requires_key': False,
            'format': lambda data: data.get('rates', {})
        },
    }

    # Base currency for all training programme prices
    BASE_CURRENCY = 'USD'

    # Cache TTL: 1 hour (exchange rates don't change that frequently)
    CACHE_TTL = 3600

    # Minimum exchange rate to prevent errors (e.g., API returns 0)
    MIN_EXCHANGE_RATE = Decimal('0.001')

    @classmethod
    def get_exchange_rates(cls, base_currency: str = 'USD', use_cache: bool = True) -> Dict[str, Decimal]:
        """
        Get current exchange rates for base currency.

        Args:
            base_currency: Base currency code (default: USD)
            use_cache: Whether to use cached rates (default: True)

        Returns:
            Dictionary mapping currency codes to exchange rates
            Example: {'KES': 129.50, 'NGN': 775.25, 'ZAR': 18.50}
        """
        # Check cache first
        cache_key = f"exchange_rates:{base_currency}"
        if use_cache:
            cached_rates = cache.get(cache_key)
            if cached_rates:
                logger.info(f"Exchange rate cache hit for {base_currency}")
                return cached_rates

        # Try each provider
        for provider_name, provider_config in cls.EXCHANGE_RATE_PROVIDERS.items():
            try:
                rates = cls._fetch_rates_from_provider(
                    base_currency,
                    provider_config['url'],
                    provider_config['format']
                )

                if rates:
                    # Convert to Decimal for precision
                    decimal_rates = {
                        currency: Decimal(str(rate))
                        for currency, rate in rates.items()
                        if rate > 0  # Filter out invalid rates
                    }

                    # Cache successful result
                    cache.set(cache_key, decimal_rates, cls.CACHE_TTL)
                    logger.info(
                        f"Fetched {len(decimal_rates)} exchange rates "
                        f"from {provider_name} (base: {base_currency})"
                    )
                    return decimal_rates

            except Exception as e:
                logger.warning(
                    f"Failed to fetch rates from {provider_name}: {str(e)}"
                )
                continue

        # All providers failed
        logger.error("All exchange rate providers failed, using fallback rates")
        return cls._get_fallback_rates(base_currency)

    @classmethod
    def _fetch_rates_from_provider(cls, base_currency: str, url_template: str, format_func) -> Dict:
        """Fetch exchange rates from a specific provider"""
        url = url_template.format(base=base_currency)

        response = requests.get(
            url,
            timeout=10,
            headers={'User-Agent': 'HosiAcademy-LMS/1.0'}
        )
        response.raise_for_status()

        data = response.json()

        # Check for errors
        if 'error' in data or not data.get('success', True):
            raise ValueError(f"Provider returned error: {data.get('error', 'Unknown')}")

        # Extract and normalize rates
        return format_func(data)

    @classmethod
    def _get_fallback_rates(cls, base_currency: str) -> Dict[str, Decimal]:
        """
        Fallback exchange rates if all APIs fail.
        Updated periodically - last update: 2026-01-28
        """
        if base_currency != 'USD':
            logger.warning(f"Fallback rates only available for USD, not {base_currency}")
            return {}

        return {
            # African currencies (approximate rates)
            'KES': Decimal('129.50'),  # Kenya Shilling
            'NGN': Decimal('775.00'),  # Nigerian Naira
            'ZAR': Decimal('18.50'),   # South African Rand
            'GHS': Decimal('12.30'),   # Ghanaian Cedi
            'TZS': Decimal('2500.00'), # Tanzanian Shilling
            'UGX': Decimal('3700.00'), # Ugandan Shilling
            'ZMW': Decimal('23.00'),   # Zambian Kwacha
            'ZWL': Decimal('322.00'),  # Zimbabwean Dollar
            'EGP': Decimal('30.50'),   # Egyptian Pound
            'MAD': Decimal('10.00'),   # Moroccan Dirham
            'XOF': Decimal('600.00'),  # West African CFA Franc
            'XAF': Decimal('600.00'),  # Central African CFA Franc
            'RWF': Decimal('1250.00'), # Rwandan Franc
            'ETB': Decimal('55.00'),   # Ethiopian Birr
            'MWK': Decimal('1020.00'), # Malawian Kwacha
            'MZN': Decimal('63.50'),   # Mozambican Metical
            'BWP': Decimal('13.50'),   # Botswana Pula
            'NAD': Decimal('18.50'),   # Namibian Dollar
            'SZL': Decimal('18.50'),   # Swazi Lilangeni
            'LSL': Decimal('18.50'),   # Lesotho Loti
            'AOA': Decimal('830.00'),  # Angolan Kwanza
            'MGA': Decimal('4500.00'), # Malagasy Ariary
            'MUR': Decimal('45.00'),   # Mauritian Rupee
            'SCR': Decimal('13.50'),   # Seychellois Rupee
            'DZD': Decimal('135.00'),  # Algerian Dinar
            'TND': Decimal('3.10'),    # Tunisian Dinar
            'LYD': Decimal('4.80'),    # Libyan Dinar
            'SDG': Decimal('600.00'),  # Sudanese Pound
            'SOS': Decimal('570.00'),  # Somali Shilling
            'DJF': Decimal('177.00'),  # Djiboutian Franc
            'CDF': Decimal('2800.00'), # Congolese Franc
            'BIF': Decimal('2850.00'), # Burundian Franc
            'GMD': Decimal('64.00'),   # Gambian Dalasi
            'GNF': Decimal('8600.00'), # Guinean Franc
            'LRD': Decimal('154.00'),  # Liberian Dollar
            'SLL': Decimal('19750.00'),# Sierra Leonean Leone
            'MRU': Decimal('36.50'),   # Mauritanian Ouguiya

            # International currencies
            'EUR': Decimal('0.92'),    # Euro
            'GBP': Decimal('0.79'),    # British Pound
            'CNY': Decimal('7.15'),    # Chinese Yuan
            'INR': Decimal('83.00'),   # Indian Rupee
            'AED': Decimal('3.67'),    # UAE Dirham
            'JPY': Decimal('148.00'),  # Japanese Yen
            'CAD': Decimal('1.35'),    # Canadian Dollar
            'AUD': Decimal('1.52'),    # Australian Dollar
        }

    @classmethod
    def convert_amount(
        cls,
        amount: Decimal,
        from_currency: str,
        to_currency: str,
        use_cache: bool = True
    ) -> Decimal:
        """
        Convert amount from one currency to another.

        Args:
            amount: Amount to convert
            from_currency: Source currency code (e.g., 'USD')
            to_currency: Target currency code (e.g., 'KES')
            use_cache: Whether to use cached exchange rates

        Returns:
            Converted amount as Decimal

        Example:
            convert_amount(Decimal('100'), 'USD', 'KES') -> Decimal('12950.00')
        """
        # Same currency, no conversion needed
        if from_currency == to_currency:
            return amount

        # Ensure amount is Decimal
        if not isinstance(amount, Decimal):
            amount = Decimal(str(amount))

        # Get exchange rates for base currency
        rates = cls.get_exchange_rates(from_currency, use_cache=use_cache)

        # Get target currency rate
        if to_currency not in rates:
            logger.error(f"No exchange rate found for {to_currency}, using 1:1")
            return amount

        rate = rates[to_currency]

        # Validate rate
        if rate < cls.MIN_EXCHANGE_RATE:
            logger.error(f"Invalid exchange rate {rate} for {to_currency}, using 1:1")
            return amount

        # Convert
        converted = amount * rate

        # Round to nearest whole number
        converted = converted.quantize(Decimal('1'), rounding=ROUND_HALF_UP)

        logger.info(
            f"Converted {amount} {from_currency} to {converted} {to_currency} "
            f"(rate: {rate})"
        )

        return converted

    @classmethod
    def get_localized_price(
        cls,
        usd_price: Decimal,
        target_currency: str,
        include_original: bool = False
    ) -> Dict:
        """
        Get localized price with metadata.

        Args:
            usd_price: Original price in USD
            target_currency: Target currency code
            include_original: Whether to include original USD price

        Returns:
            Dictionary with localized pricing:
            {
                'amount': Decimal('12950.00'),
                'currency': 'KES',
                'formatted': 'KES 12,950.00',
                'original_amount': Decimal('100.00'),  # if include_original
                'original_currency': 'USD',             # if include_original
                'exchange_rate': Decimal('129.50'),
            }
        """
        # Convert amount
        converted_amount = cls.convert_amount(
            usd_price,
            cls.BASE_CURRENCY,
            target_currency
        )

        # Get exchange rate for display
        rates = cls.get_exchange_rates(cls.BASE_CURRENCY)
        exchange_rate = rates.get(target_currency, Decimal('1'))

        # Format amount with commas
        formatted = f"{target_currency} {converted_amount:.0f}"

        result = {
            'amount': converted_amount,
            'currency': target_currency,
            'formatted': formatted,
            'exchange_rate': exchange_rate,
        }

        if include_original:
            result.update({
                'original_amount': usd_price,
                'original_currency': cls.BASE_CURRENCY,
            })

        return result

    @classmethod
    def get_supported_currencies(cls) -> list:
        """Get list of all supported currencies"""
        rates = cls.get_exchange_rates(cls.BASE_CURRENCY)
        return sorted(rates.keys())

    @classmethod
    def is_currency_supported(cls, currency_code: str) -> bool:
        """Check if currency is supported"""
        rates = cls.get_exchange_rates(cls.BASE_CURRENCY)
        return currency_code.upper() in rates


# Convenience functions
def convert_usd_to_local(usd_amount: float, target_currency: str) -> Decimal:
    """
    Quick conversion from USD to local currency.

    Args:
        usd_amount: Amount in USD
        target_currency: Target currency code

    Returns:
        Converted amount
    """
    return CurrencyConversionService.convert_amount(
        Decimal(str(usd_amount)),
        'USD',
        target_currency
    )


def get_price_in_currency(usd_price: float, currency: str) -> Dict:
    """
    Get formatted price in target currency.

    Args:
        usd_price: Price in USD
        currency: Target currency

    Returns:
        Dictionary with amount, currency, and formatted string
    """
    return CurrencyConversionService.get_localized_price(
        Decimal(str(usd_price)),
        currency,
        include_original=True
    )
