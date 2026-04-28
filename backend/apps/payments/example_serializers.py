"""
Example Serializers with Automatic Currency Conversion

These examples show how to add automatic price localization to your serializers.
Copy these patterns to your app's serializers.py files.

The middleware (CurrencyDetectionMiddleware) automatically detects the user's
currency from their IP address, and the custom fields convert prices automatically.
"""

from rest_framework import serializers
from apps.learnerships.models import LearnershipProgramme
from apps.masterclasses.models import Masterclass
from apps.industry_based_training.models import Offering
from apps.aicerts_courses.models import AiCertsCourse

# Import the custom fields
from .serializer_fields import (
    LocalizedPriceField,
    CurrencyField,
    FormattedPriceField,
    LocalizedPriceSerializer
)


# ============================================================================
# EXAMPLE 1: Simple Learnership Serializer with Auto-Conversion
# ============================================================================

class LearnershipProgrammeSerializer(serializers.ModelSerializer):
    """
    Learnership serializer with automatic price conversion.

    API Response will show:
    {
        "id": 1,
        "title": "AI+ Marketing Masterclass",
        "cost_usd": 100.00,            # Original USD price (for reference)
        "price": 12950.00,              # Converted to user's currency (KES)
        "currency": "KES",              # User's currency
        "formatted_price": "KES 12,950.00",  # Formatted string
        "duration_weeks": 12,
        ...
    }
    """

    # Original USD price (read from database)
    cost_usd = serializers.DecimalField(max_digits=10, decimal_places=2, read_only=True)

    # Localized price fields (automatically converted)
    price = LocalizedPriceField(source='cost_usd', read_only=True)
    currency = CurrencyField(read_only=True)
    formatted_price = FormattedPriceField(price_field='cost_usd', read_only=True)

    class Meta:
        model = LearnershipProgramme
        fields = [
            'id',
            'title',
            'description',
            'cost_usd',           # Original
            'price',              # Converted
            'currency',           # User's currency
            'formatted_price',    # Formatted
            'duration_weeks',
            'nqf_level',
            'credits',
        ]


# ============================================================================
# EXAMPLE 2: Masterclass Serializer with Detailed Pricing
# ============================================================================

class MasterclassSerializer(serializers.ModelSerializer):
    """
    Masterclass with complete pricing breakdown.

    Includes both simple converted price and detailed pricing object.
    """

    # Simple localized price
    price = LocalizedPriceField(source='price_usd', read_only=True)
    currency = CurrencyField(read_only=True)
    formatted_price = FormattedPriceField(price_field='price_usd', read_only=True)

    # Detailed pricing object with exchange rate
    pricing_details = serializers.SerializerMethodField()

    class Meta:
        model = Masterclass
        fields = [
            'id',
            'title',
            'description',
            'price',              # Just the number
            'currency',           # Just the currency code
            'formatted_price',    # Formatted string
            'pricing_details',    # Complete breakdown
            'duration',
            'instructor',
        ]

    def get_pricing_details(self, obj):
        """
        Returns complete pricing object:
        {
            "original_price": 100.00,
            "original_currency": "USD",
            "localized_price": 12950.00,
            "localized_currency": "KES",
            "formatted_price": "KES 12,950.00",
            "exchange_rate": 129.50
        }
        """
        request = self.context.get('request')
        if not request or not hasattr(obj, 'price_usd'):
            return None

        return LocalizedPriceSerializer.from_usd_price(
            obj.price_usd,
            request
        )


# ============================================================================
# EXAMPLE 3: Industry Training with Optional USD Display
# ============================================================================

class IndustryTrainingSerializer(serializers.ModelSerializer):
    """
    Industry training with option to show original USD price.
    """

    # Original USD price (optional, for transparency)
    price_usd = serializers.DecimalField(
        max_digits=10,
        decimal_places=2,
        read_only=True,
        help_text="Original price in USD (for reference)"
    )

    # Localized price (what user actually pays)
    price = LocalizedPriceField(source='price_usd', read_only=True)
    currency = CurrencyField(read_only=True)
    formatted_price = FormattedPriceField(price_field='price_usd', read_only=True)

    # Show country for context
    user_country = serializers.SerializerMethodField()

    class Meta:
        model = Offering
        fields = [
            'id',
            'name',
            'description',
            'price_usd',          # Original (optional)
            'price',              # Localized
            'currency',           # User's currency
            'formatted_price',    # Formatted
            'user_country',       # User's country
            'industry',
        ]

    def get_user_country(self, obj):
        """Return user's detected country"""
        request = self.context.get('request')
        if not request:
            return None
        return getattr(request, 'user_country', 'ZA')


# ============================================================================
# EXAMPLE 4: AICerts Course (Minimal)
# ============================================================================

class AICertsCourseSerializer(serializers.ModelSerializer):
    """
    AICerts course with just the essentials.

    Most minimal implementation - just shows converted price.
    """

    # Only show localized price and currency
    price = LocalizedPriceField(source='price_usd', read_only=True)
    currency = CurrencyField(read_only=True)

    class Meta:
        model = AiCertsCourse
        fields = [
            'id',
            'title',
            'shortname',
            'price',        # Automatically converted
            'currency',     # User's currency
        ]


# ============================================================================
# EXAMPLE 5: List View with Formatted Prices
# ============================================================================

class ProgrammeListSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer for list views.

    Only includes formatted price string (most compact).
    """

    # Just the formatted price for display
    price_display = FormattedPriceField(price_field='cost_usd', read_only=True)

    class Meta:
        model = LearnershipProgramme
        fields = [
            'id',
            'title',
            'price_display',  # "KES 12,950.00"
            'duration_weeks',
            'thumbnail',
        ]


# ============================================================================
# EXAMPLE 6: Enrollment Serializer with Payment Amount
# ============================================================================

class EnrollmentWithPricingSerializer(serializers.Serializer):
    """
    Enrollment with localized payment amount.

    Use this when creating enrollments to show the amount user will pay.
    """

    programme_id = serializers.IntegerField()
    programme_title = serializers.CharField()
    programme_type = serializers.CharField()

    # Payment amount in user's currency
    payment_amount = LocalizedPriceField(source='enrollment_fee')
    payment_currency = CurrencyField()
    formatted_payment = FormattedPriceField(price_field='enrollment_fee')

    learner_name = serializers.CharField()
    learner_email = serializers.EmailField()


# ============================================================================
# Usage Instructions
# ============================================================================

"""
HOW TO USE IN YOUR VIEWS:

1. NO CHANGES NEEDED IN VIEWS!
   The middleware handles everything automatically.

2. Example View:

    from rest_framework import viewsets
    from .serializers import LearnershipProgrammeSerializer

    class LearnershipViewSet(viewsets.ModelViewSet):
        queryset = LearnershipProgramme.objects.all()
        serializer_class = LearnershipProgrammeSerializer

        # That's it! Prices are automatically converted!

3. Example API Response:

    GET /api/learnerships/1/
    User from Kenya (IP: 105.xxx.xxx.xxx)

    Response:
    {
        "id": 1,
        "title": "AI+ Marketing Masterclass",
        "cost_usd": 100.00,
        "price": 12950.00,        # Converted to KES
        "currency": "KES",
        "formatted_price": "KES 12,950.00",
        ...
    }

    GET /api/learnerships/1/
    User from Nigeria (IP: 197.xxx.xxx.xxx)

    Response:
    {
        "id": 1,
        "title": "AI+ Marketing Masterclass",
        "cost_usd": 100.00,
        "price": 77500.00,        # Converted to NGN
        "currency": "NGN",
        "formatted_price": "NGN 77,500.00",
        ...
    }

4. Override Currency (Optional):

    GET /api/learnerships/1/?currency=USD

    Response:
    {
        ...
        "price": 100.00,          # Stays in USD
        "currency": "USD",
        "formatted_price": "$100.00",
        ...
    }

5. Frontend Usage:

    // Fetch with automatic conversion
    fetch('/api/learnerships/1/')
      .then(res => res.json())
      .then(data => {
        console.log(data.formatted_price);  // "KES 12,950.00"
        console.log(data.currency);          // "KES"
        console.log(data.price);             // 12950.00
      });

    // Force specific currency
    fetch('/api/learnerships/1/?currency=USD')
      .then(res => res.json())
      .then(data => {
        console.log(data.formatted_price);  // "$100.00"
      });

MIGRATION GUIDE:

To add automatic conversion to existing serializers:

1. Import the fields:
   from apps.payments.serializer_fields import LocalizedPriceField, CurrencyField

2. Add to your serializer:
   price = LocalizedPriceField(source='cost_usd', read_only=True)
   currency = CurrencyField(read_only=True)

3. Done! No view changes needed.
"""
