# apps/payments/services/geolocation_service.py
"""
IP-based Geolocation Service for African Countries
Uses ip-api.com for accurate IP geolocation - STABLE & RELIABLE
"""
import logging
import requests
from typing import Dict, Any

logger = logging.getLogger(__name__)


class GeolocationService:
    """
    Service for detecting user's country from IP address
    Uses ip-api.com for accurate geolocation
    """

    @staticmethod
    def get_location_from_request(request) -> Dict[str, Any]:
        """Get location from request IP using ip-api.com"""
        try:
            ip = GeolocationService.get_client_ip(request)

            # Use ip-api.com (free, accurate, no API key required)
            response = requests.get(
                f'http://ip-api.com/json/{ip}',
                timeout=5
            )

            if response.status_code == 200:
                data = response.json()
                if data.get('status') == 'success':
                    country_code = data.get('countryCode', 'ZA')
                    country_name = data.get('country', 'South Africa')
                    city = data.get('city', '')
                    region = data.get('regionName', '')

                    # Get currency for country
                    currency = GeolocationService.get_currency_from_country(country_code)

                    return {
                        'country_code': country_code.upper(),
                        'country_name': country_name,
                        'city': city,
                        'region': region,
                        'currency': currency.upper(),
                        'timezone': data.get('timezone', 'Africa/Johannesburg'),
                    }
        except Exception as e:
            logger.error(f"ip-api.com lookup failed: {e}")

        # Fallback to South Africa (ZAR)
        return {
            'country_code': 'ZA',
            'country_name': 'South Africa',
            'city': '',
            'region': '',
            'currency': 'ZAR',
            'timezone': 'Africa/Johannesburg',
        }

    @staticmethod
    def get_country_from_ip(ip: str) -> str:
        """Get country code from IP address using ip-api.com"""
        try:
            response = requests.get(
                f'http://ip-api.com/json/{ip}',
                timeout=5
            )

            if response.status_code == 200:
                data = response.json()
                if data.get('status') == 'success':
                    return data.get('countryCode', 'ZA').upper()
        except Exception as e:
            logger.error(f"ip-api.com lookup failed for IP {ip}: {e}")

        # Fallback to South Africa
        return 'ZA'

    @staticmethod
    def get_client_ip(request) -> str:
        """Extract client IP from request"""
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            return x_forwarded_for.split(',')[0].strip()
        return request.META.get('REMOTE_ADDR', '')

    @staticmethod
    def get_currency_from_country(country_code: str) -> str:
        """Map country code to currency - STABLE MAPPING"""
        currency_map = {
            'ZA': 'ZAR',  # South Africa - Rand
            'ZW': 'USD',  # Zimbabwe - US Dollar
            'KE': 'KES',  # Kenya - Kenyan Shilling
            'NG': 'NGN',  # Nigeria - Naira
            'GH': 'GHS',  # Ghana - Cedi
            'EG': 'EGP',  # Egypt - Egyptian Pound
            'TZ': 'TZS',  # Tanzania - Tanzanian Shilling
            'UG': 'UGX',  # Uganda - Ugandan Shilling
            'ET': 'ETB',  # Ethiopia - Birr
            'RW': 'RWF',  # Rwanda - Rwandan Franc
            'ZM': 'ZMW',  # Zambia - Zambian Kwacha
            'SN': 'XOF',  # Senegal - CFA Franc
            'CI': 'XOF',  # Côte d'Ivoire - CFA Franc
            'CM': 'XAF',  # Cameroon - CFA Franc
            'MA': 'MAD',  # Morocco - Dirham
            'DZ': 'DZD',  # Algeria - Algerian Dinar
            'TN': 'TND',  # Tunisia - Tunisian Dinar
            'MZ': 'MZN',  # Mozambique - Metical
            'BW': 'BWP',  # Botswana - Pula
            'NA': 'NAD',  # Namibia - Namibian Dollar
            'AO': 'AOA',  # Angola - Kwanza
            'MW': 'MWK',  # Malawi - Kwacha
            'US': 'USD',  # USA - Dollar
            'GB': 'GBP',  # UK - Pound
            'EU': 'EUR',  # Europe - Euro
        }
        return currency_map.get(country_code.upper(), 'USD')


# Singleton instance for backward compatibility
geo_location_service = GeolocationService()
