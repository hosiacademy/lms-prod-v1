"""
Pricing Views with Automatic Currency Conversion

Provides endpoints for getting localized pricing based on user's IP address.
Training programme amounts are automatically converted from USD to local currency.
"""

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.contrib.contenttypes.models import ContentType
from django.shortcuts import get_object_or_404
from decimal import Decimal
import logging

from .services.geolocation_service import GeolocationService, get_country_and_currency_from_request
from .services.currency_service import CurrencyConversionService
from apps.learnerships.models import LearnershipProgramme
from apps.masterclasses.models import Masterclass
from apps.industry_based_training.models import Offering
from apps.aicerts_courses.models import AiCertsCourse

logger = logging.getLogger(__name__)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_localized_pricing(request, content_type, object_id):
    """
    Get localized pricing for a training programme based on user's IP address.

    Automatically detects:
    - User's country from IP address
    - Local currency for that country
    - Converts USD price to local currency

    URL Parameters:
        content_type: Type of content ('learnership', 'masterclass', 'industry_training', 'aicerts')
        object_id: ID of the training programme

    Query Parameters:
        country (optional): Override automatic country detection
        currency (optional): Override automatic currency detection

    Returns:
        {
            "programme": {
                "id": 123,
                "title": "AI+ Marketing Masterclass",
                "type": "masterclass"
            },
            "pricing": {
                "original_price": 100.00,
                "original_currency": "USD",
                "localized_price": 12950.00,
                "localized_currency": "KES",
                "formatted_price": "KES 12,950.00",
                "exchange_rate": 129.50
            },
            "location": {
                "country_code": "KE",
                "country_name": "Kenya",
                "city": "Nairobi",
                "currency": "KES",
                "detection_method": "ip_geolocation|user_profile|explicit"
            },
            "payment_providers": [
                {"code": "mpesa", "name": "M-Pesa", "supported": true},
                {"code": "flutterwave", "name": "Flutterwave", "supported": true}
            ]
        }
    """
    try:
        # 1. Get the training programme
        programme, programme_data = _get_programme_details(content_type, object_id)
        if not programme:
            return Response(
                {"error": f"Programme not found: {content_type} #{object_id}"},
                status=status.HTTP_404_NOT_FOUND
            )

        # 2. Get original USD price
        usd_price = programme_data.get('price_usd')
        if not usd_price:
            return Response(
                {"error": "Programme does not have a USD price set"},
                status=status.HTTP_400_BAD_REQUEST
            )

        # 3. Detect user's location and currency
        country, currency, detection_method, location_data = _detect_location_and_currency(request)

        logger.info(
            f"Pricing request for {content_type}#{object_id}: "
            f"{usd_price} USD -> {currency} (country: {country}, method: {detection_method})"
        )

        # 4. Convert to local currency
        localized_pricing = CurrencyConversionService.get_localized_price(
            Decimal(str(usd_price)),
            currency,
            include_original=True
        )

        # 5. Get available payment providers for this country
        payment_providers = _get_payment_providers(country, localized_pricing['amount'], currency)

        # 6. Build response
        response_data = {
            "programme": programme_data,
            "pricing": {
                "original_price": float(localized_pricing['original_amount']),
                "original_currency": localized_pricing['original_currency'],
                "localized_price": float(localized_pricing['amount']),
                "localized_currency": localized_pricing['currency'],
                "formatted_price": localized_pricing['formatted'],
                "exchange_rate": float(localized_pricing['exchange_rate']),
            },
            "location": {
                **location_data,
                "detection_method": detection_method
            },
            "payment_providers": payment_providers
        }

        return Response(response_data, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"Error getting localized pricing: {str(e)}", exc_info=True)
        return Response(
            {"error": f"Failed to get localized pricing: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([AllowAny])
def get_exchange_rates(request):
    """
    Get current exchange rates for all supported currencies.

    Query Parameters:
        base (optional): Base currency (default: USD)

    Returns:
        {
            "base_currency": "USD",
            "rates": {
                "KES": 129.50,
                "NGN": 775.00,
                "ZAR": 18.50,
                ...
            },
            "last_updated": "2026-01-28T10:30:00Z"
        }
    """
    try:
        base_currency = request.GET.get('base', 'USD').upper()

        rates = CurrencyConversionService.get_exchange_rates(base_currency)

        # Convert Decimal to float for JSON serialization
        rates_dict = {
            currency: float(rate)
            for currency, rate in rates.items()
        }

        return Response({
            "base_currency": base_currency,
            "rates": rates_dict,
            "supported_currencies": len(rates_dict),
            "last_updated": None,  # TODO: Track last update timestamp
        }, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"Error getting exchange rates: {str(e)}")
        return Response(
            {"error": f"Failed to get exchange rates: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['GET'])
@permission_classes([AllowAny])
def detect_location(request):
    """
    Detect user's location from IP address.

    Returns:
        {
            "country_code": "KE",
            "country_name": "Kenya",
            "city": "Nairobi",
            "region": "Nairobi County",
            "currency": "KES",
            "timezone": "Africa/Nairobi",
            "continent": "AF",
            "ip_address": "105.xxx.xxx.xxx"  # Partially masked
        }
    """
    try:
        # Get location from IP
        location_data = GeolocationService.get_location_from_request(request)

        # Get IP address (partially masked for privacy)
        ip_address = GeolocationService.get_client_ip(request)
        if ip_address:
            ip_parts = ip_address.split('.')
            if len(ip_parts) == 4:
                # Mask last two octets
                ip_address = f"{ip_parts[0]}.{ip_parts[1]}.xxx.xxx"

        return Response({
            **location_data,
            "ip_address": ip_address
        }, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"Error detecting location: {str(e)}")
        return Response(
            {"error": f"Failed to detect location: {str(e)}"},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


# Helper functions

def _get_programme_details(content_type, object_id):
    """Get training programme details based on content type"""
    try:
        if content_type == 'learnership':
            programme = get_object_or_404(LearnershipProgramme, id=object_id)
            return programme, {
                "id": programme.id,
                "title": programme.title,
                "type": "learnership",
                "price_usd": programme.cost_usd,
                "duration_weeks": programme.duration_weeks,
                "nqf_level": programme.nqf_level,
            }

        elif content_type == 'masterclass':
            programme = get_object_or_404(Masterclass, id=object_id)
            return programme, {
                "id": programme.id,
                "title": programme.title,
                "type": "masterclass",
                "price_usd": getattr(programme, 'price_usd', None) or getattr(programme, 'price', 0),
                "duration": programme.duration,
            }

        elif content_type == 'industry_training':
            programme = get_object_or_404(Offering, id=object_id)
            return programme, {
                "id": programme.id,
                "title": programme.name,  # Offering uses 'name' field instead of 'title'
                "type": "industry_training",
                "price_usd": getattr(programme, 'price_usd', None) or 0,
                "industry": programme.industry.name if programme.industry else None,
            }

        elif content_type == 'aicerts':
            programme = get_object_or_404(AiCertsCourse, id=object_id)
            return programme, {
                "id": programme.id,
                "title": programme.title,
                "type": "aicerts_course",
                "price_usd": getattr(programme, 'price_usd', None) or 0,
            }

        else:
            return None, None

    except Exception as e:
        logger.error(f"Error getting programme details: {str(e)}")
        return None, None


def _detect_location_and_currency(request):
    """Detect user's location and currency"""
    # Check for explicit parameters
    explicit_country = request.GET.get('country')
    explicit_currency = request.GET.get('currency')

    if explicit_country and explicit_currency:
        # User explicitly provided both
        location_data = {"country_code": explicit_country.upper()}
        return explicit_country.upper(), explicit_currency.upper(), "explicit", location_data

    # Get location from IP
    location_data = GeolocationService.get_location_from_request(request)
    country = location_data['country_code']

    # Determine currency
    if explicit_currency:
        currency = explicit_currency.upper()
        detection_method = "explicit_currency"
    else:
        currency = GeolocationService.get_currency_from_country(country)
        detection_method = "ip_geolocation"

    # Check if user is authenticated and has profile country
    if request.user and request.user.is_authenticated:
        if hasattr(request.user, 'country') and request.user.country:
            if not explicit_country:
                country = request.user.country if isinstance(request.user.country, str) else request.user.country.code
                detection_method = "user_profile"

    return country, currency, detection_method, location_data


def _get_payment_providers(country, amount, currency):
    """Get available payment providers for country"""
    try:
        from .services.payment_service import PaymentService

        providers = PaymentService.get_available_providers(
            country=country,
            amount=float(amount),
            currency=currency
        )

        return [
            {
                "code": p.get('provider_code'),
                "name": p.get('provider_name'),
                "supported": p.get('is_integrated', False),
                "methods": p.get('methods', []),
            }
            for p in providers
        ]

    except Exception as e:
        logger.warning(f"Could not fetch payment providers: {str(e)}")
        return []
