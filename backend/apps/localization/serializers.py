# apps/localization/serializers.py
"""
Afro-centric Language & Localization serializers.

* Compact list serializer for Flutter language switcher
* Rich detail serializer for admin tools / debugging
* Full config serializer for initial app load (languages + translations + country overrides)
* Returns accurate country-level flags, official status, speaker estimates, cultural nuances
* Fully compatible with existing Language model (db_table='languages')
"""

from rest_framework import serializers
from django.utils import timezone

from .models import Language, Translation, Country, CountryOverride, State, City, LocalizedPromotion
from apps.frontend_manage.serializers import AppAppearanceSerializer  # For country theme overrides


# ── Language Serializers ──────────────────────────────────────────────────────

class LanguageListSerializer(serializers.ModelSerializer):
    """
    Compact serializer used for public language catalogue (Flutter dropdown/switcher).
    Returns essential fields + Afro-centric metadata (flags, countries, speakers, script).
    """
    flags = serializers.SerializerMethodField()
    countries = serializers.SerializerMethodField()
    speakers = serializers.SerializerMethodField()
    official_status = serializers.SerializerMethodField()
    script = serializers.SerializerMethodField()

    class Meta:
        model = Language
        fields = (
            'id', 'code', 'name', 'native',
            'rtl', 'status', 'json_exist',
            'flags', 'countries', 'speakers',
            'official_status', 'script'
        )

    # ------------------------------------------------------------------
    # Afro-centric data helpers (country-level accuracy)
    # ------------------------------------------------------------------
    def _get_language_data(self, code: str):
        """
        Returns (flags_list, official_countries_str, speakers_str, script_str)
        """
        data = {
            'sw': (
                ['🇹🇿', '🇰🇪', '🇺🇬', '🇨🇩', '🇷🇼'],
                'Tanzania, Kenya, Uganda, DRC, Rwanda (official lingua franca)',
                '150–200 million (L1+L2)',
                'Latin'
            ),
            'ha': (
                ['🇳🇬', '🇳🇪', '🇬🇭'],
                'Nigeria, Niger, Ghana (major regional language)',
                '80–100 million',
                'Latin + Ajami (Arabic script)'
            ),
            'yo': (
                ['🇳🇬', '🇧🇯'],
                'Nigeria, Benin',
                '45–50 million',
                'Latin with diacritics'
            ),
            'ig': (
                ['🇳🇬'],
                'Nigeria',
                '30–40 million',
                'Latin'
            ),
            'am': (
                ['🇪🇹'],
                'Ethiopia (federal working language)',
                '35+ million',
                'Geʽez (ግዕዝ)'
            ),
            'om': (
                ['🇪🇹'],
                'Ethiopia',
                '35+ million',
                'Latin'
            ),
            'ti': (
                ['🇪🇷', '🇪🇹'],
                'Eritrea, Ethiopia',
                '7+ million',
                'Geʽez'
            ),
            'zu': (
                ['🇿🇦'],
                'South Africa (official)',
                '12 million',
                'Latin'
            ),
            'xh': (
                ['🇿🇦'],
                'South Africa (official)',
                '8 million',
                'Latin'
            ),
            'af': (
                ['🇿🇦', '🇳🇦'],
                'South Africa, Namibia',
                '7 million',
                'Latin'
            ),
            'ar': (
                ['🇪🇬', '🇲🇦', '🇩🇿', '🇹🇳', '🇸🇩', '🇱🇾'],
                'North Africa (multiple official countries)',
                '200+ million in Africa',
                'Arabic script (عربي)'
            ),
            'fr': (
                ['🇸🇳', '🇨🇮', '🇨🇲', '🇧🇫', '🇲🇱', '🇳🇪', '🇹🇬'],
                'Francophone West & Central Africa',
                '140+ million in Africa',
                'Latin'
            ),
            'pt': (
                ['🇦🇴', '🇲🇿', '🇬🇼', '🇨🇻', '🇸🇹'],
                'Angola, Mozambique, Guinea-Bissau, Cape Verde, São Tomé',
                '40+ million in Africa',
                'Latin'
            ),
            'rw': (
                ['🇷🇼'],
                'Rwanda (official)',
                '12 million',
                'Latin'
            ),
            'ln': (
                ['🇨🇩', '🇨🇬'],
                'DRC, Congo-Brazzaville',
                '70+ million (L2)',
                'Latin'
            ),
            'ak': (
                ['🇬🇭'],
                'Ghana',
                '20+ million',
                'Latin'
            ),
            'sn': (
                ['🇿🇼', '🇿🇦'],
                'Zimbabwe, South Africa',
                '5+ million',
                'Latin'
            ),
            'so': (
                ['🇸🇴', '🇪🇹'],
                'Somalia, Djibouti',
                '15+ million',
                'Latin'
            ),
            'en': (
                ['🇳🇬', '🇰🇪', '🇿🇦', '🇬🇭', '🇺🇬', '🇿🇼', '🇷🇼'],
                'Official second language in many African countries',
                '400+ million (L2 in Africa)',
                'Latin'
            ),
        }
        return data.get(code.lower()[:2], (['🌍'], 'Regional / Widely spoken', '—', 'Latin'))

    def get_flags(self, obj):
        flags, _, _, _ = self._get_language_data(obj.code)
        return ''.join(flags)

    def get_countries(self, obj):
        _, countries, _, _ = self._get_language_data(obj.code)
        return countries

    def get_speakers(self, obj):
        _, _, speakers, _ = self._get_language_data(obj.code)
        return speakers

    def get_official_status(self, obj):
        _, countries, _, _ = self._get_language_data(obj.code)
        return countries

    def get_script(self, obj):
        _, _, _, script = self._get_language_data(obj.code)
        return script


class LanguageDetailSerializer(LanguageListSerializer):
    """
    Rich detail serializer – used for admin preview or internal tools.
    Includes full timestamps and translation status.
    """
    created_at = serializers.DateTimeField(read_only=True)
    updated_at = serializers.DateTimeField(read_only=True)

    class Meta(LanguageListSerializer.Meta):
        fields = LanguageListSerializer.Meta.fields + ('created_at', 'updated_at')


# ── Country & Override Serializers ─────────────────────────────────────────────

class CountrySerializer(serializers.ModelSerializer):
    class Meta:
        model = Country
        fields = ('id', 'code', 'name', 'is_active', 'phone_code')


class StateSerializer(serializers.ModelSerializer):
    country_name = serializers.CharField(source='country.name', read_only=True)

    class Meta:
        model = State
        fields = ('id', 'country', 'country_name', 'name', 'code', 'is_active')


class CitySerializer(serializers.ModelSerializer):
    state_name = serializers.CharField(source='state.name', read_only=True)
    country_name = serializers.CharField(source='state.country.name', read_only=True)

    class Meta:
        model = City
        fields = ('id', 'state', 'state_name', 'country_name', 'name', 'is_active', 'population')


class CountryOverrideSerializer(serializers.ModelSerializer):
    appearance = AppAppearanceSerializer(required=False, read_only=True)
    default_language = LanguageListSerializer(required=False, read_only=True)

    class Meta:
        model = CountryOverride
        fields = (
            'id', 'country', 'appearance', 'greeting_message',
            'holiday_banner_url', 'holiday_date', 'cultural_note',
            'default_language', 'is_default'
        )


class TranslationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Translation
        fields = ('key', 'value', 'description')


# ── Promotion Serializer ───────────────────────────────────────────────────────

class PromotionSerializer(serializers.ModelSerializer):
    """
    Public serializer for active localized promotions.
    Used by Flutter onboarding page to show animated promo flyers.
    """
    is_currently_active = serializers.SerializerMethodField()
    days_remaining = serializers.SerializerMethodField()

    class Meta:
        model = LocalizedPromotion
        fields = (
            'id', 'title', 'native_title', 'description', 'native_description',
            'promotion_type', 'image_url', 'background_color', 'text_color', 'icon',
            'discount_percentage', 'cta_text', 'cta_url',
            'start_date', 'end_date', 'priority',
            'show_on_splash', 'show_on_home', 'show_on_onboarding',
            'is_currently_active', 'days_remaining',
        )

    def get_is_currently_active(self, obj):
        today = timezone.now().date()
        return obj.is_active and obj.start_date <= today <= obj.end_date

    def get_days_remaining(self, obj):
        today = timezone.now().date()
        if obj.end_date >= today:
            return (obj.end_date - today).days
        return 0


# ── Master Serializer for Full Localization Config ─────────────────────────────

class LocalizationConfigSerializer(serializers.Serializer):
    """
    Master serializer for complete localization data.
    Ideal for Flutter initial load / cache refresh.
    
    Returns:
    - All active languages
    - Translations for current language
    - All countries
    - Current country override (greeting, holiday, theme tweaks)
    
    Use ?country=ZA&lang=zu for specific overrides.
    """
    languages = LanguageListSerializer(many=True, read_only=True)
    translations = serializers.SerializerMethodField()
    countries = CountrySerializer(many=True, read_only=True)
    current_override = CountryOverrideSerializer(read_only=True)

    def get_translations(self, instance):
        """Return translations for current language (or default)"""
        request = self.context.get('request')
        lang_code = request.query_params.get('lang', 'en') if request else 'en'
        lang = Language.objects.filter(code=lang_code, status=1).first()
        
        if lang:
            return TranslationSerializer(lang.translations.all(), many=True).data
        return []

    def to_representation(self, instance=None):
        request = self.context.get('request')
        country_code = request.query_params.get('country', 'ZA') if request else 'ZA'
        
        data = {
            'languages': Language.objects.filter(status=1).order_by('name'),
            'countries': Country.objects.filter(is_active=True).order_by('name'),
            'current_override': CountryOverride.get_current(country_code),
        }
        return super().to_representation(data)