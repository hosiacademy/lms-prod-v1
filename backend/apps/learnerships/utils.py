# apps/learnerships/utils.py

import requests
from django.core.cache import cache
from django.conf import settings
from decimal import Decimal
import logging

logger = logging.getLogger(__name__)

# Free ExchangeRate-API (get your free key at https://www.exchangerate-api.com/)
EXCHANGE_RATE_API_KEY = getattr(settings, 'EXCHANGE_RATE_API_KEY', 'YOUR_FREE_API_KEY_HERE')
EXCHANGE_RATE_API_URL = f'https://v6.exchangerate-api.com/v6/{EXCHANGE_RATE_API_KEY}/latest/USD'


def get_exchange_rates():
    """
    Get all exchange rates from USD with 24-hour caching.
    Returns dict of currency_code: rate
    """
    cache_key = 'exchange_rates_usd'
    rates = cache.get(cache_key)
    
    if rates is not None:
        return rates
    
    try:
        response = requests.get(EXCHANGE_RATE_API_URL, timeout=10)
        response.raise_for_status()
        data = response.json()
        
        if data.get('result') == 'success':
            rates = data.get('conversion_rates', {})
            # Cache for 24 hours (86400 seconds)
            cache.set(cache_key, rates, 86400)
            logger.info(f"Exchange rates cached successfully. {len(rates)} currencies.")
            return rates
        else:
            logger.error(f"Exchange rate API error: {data.get('error-type')}")
            return {}
    except requests.RequestException as e:
        logger.error(f"Failed to fetch exchange rates: {e}")
        return {}


def get_exchange_rate(from_currency, to_currency):
    """
    Get exchange rate between two currencies.
    Uses USD as base currency.
    """
    if from_currency == to_currency:
        return Decimal('1.0')
    
    rates = get_exchange_rates()
    
    if not rates:
        # Fallback to static rates if API fails
        return get_fallback_rate(from_currency, to_currency)
    
    try:
        if from_currency == 'USD':
            rate = rates.get(to_currency, 1.0)
        elif to_currency == 'USD':
            rate = 1.0 / rates.get(from_currency, 1.0)
        else:
            # Convert via USD: from -> USD -> to
            usd_from = 1.0 / rates.get(from_currency, 1.0)
            usd_to = rates.get(to_currency, 1.0)
            rate = usd_from * usd_to
        
        return Decimal(str(rate))
    except (KeyError, ZeroDivisionError, ValueError) as e:
        logger.error(f"Error calculating exchange rate {from_currency} -> {to_currency}: {e}")
        return Decimal('1.0')


def convert_currency(amount, from_currency, to_currency):
    """
    Convert amount from one currency to another.
    
    Args:
        amount: Decimal or float amount to convert
        from_currency: Source currency code (e.g., 'USD')
        to_currency: Target currency code (e.g., 'ZAR')
    
    Returns:
        Decimal: Converted amount
    """
    if isinstance(amount, (int, float)):
        amount = Decimal(str(amount))
    
    rate = get_exchange_rate(from_currency, to_currency)
    return amount * rate


def get_fallback_rate(from_currency, to_currency):
    """
    Static fallback exchange rates (updated manually as needed).
    Used when API is unavailable.
    Rates as of January 2026 (approximate).
    """
    # Rates from USD to other currencies
    FALLBACK_RATES = {
        'ZAR': 18.5,   # South African Rand
        'KES': 125.0,  # Kenyan Shilling
        'NGN': 1450.0, # Nigerian Naira
        'GHS': 12.5,   # Ghanaian Cedi
        'UGX': 3700.0, # Ugandan Shilling
        'TZS': 2500.0, # Tanzanian Shilling
        'ZMW': 22.0,   # Zambian Kwacha
        'MWK': 1650.0, # Malawian Kwacha
        'BWP': 13.5,   # Botswana Pula
        'ETB': 55.0,   # Ethiopian Birr
        'RWF': 1300.0, # Rwandan Franc
        'EGP': 48.0,   # Egyptian Pound
        'MAD': 10.0,   # Moroccan Dirham
        'XAF': 600.0,  # Central African CFA Franc
        'XOF': 600.0,  # West African CFA Franc
    }
    
    if from_currency == 'USD':
        return Decimal(str(FALLBACK_RATES.get(to_currency, 1.0)))
    elif to_currency == 'USD':
        return Decimal('1.0') / Decimal(str(FALLBACK_RATES.get(from_currency, 1.0)))
    else:
        # Convert via USD
        usd_from = Decimal('1.0') / Decimal(str(FALLBACK_RATES.get(from_currency, 1.0)))
        usd_to = Decimal(str(FALLBACK_RATES.get(to_currency, 1.0)))
        return usd_from * usd_to
