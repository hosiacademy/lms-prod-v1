# apps/localization/views.py
"""
Afro-centric localisation API.

* Public read-only endpoints for language catalogue (Flutter app)
* Admin-only sync endpoint (future-proof for pulling new African language packs)
* Returns country-level data (flags, official status, speaker counts)
* Fully compatible with the Language model & admin UI
"""

from django.utils import timezone
from rest_framework import viewsets, filters, status
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated, IsAdminUser
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Language, Translation, Country, CountryOverride, State, City
from .serializers import (
    LanguageListSerializer,
    LanguageDetailSerializer,
    CountrySerializer,
    StateSerializer,
    CitySerializer,
    CountryOverrideSerializer,
    TranslationSerializer,
    LocalizationConfigSerializer,
)


# ----------------------------------------------------------------------
# Language ViewSet (Public Catalogue)
# ----------------------------------------------------------------------
class LanguageViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Public catalogue of supported languages.
    Flutter uses this to populate language switcher/dropdown.
    Supports Afro-centric metadata (flags, countries, speakers, script).
    """
    queryset = Language.objects.filter(status=1).order_by('name')
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ('name', 'native', 'code')
    ordering_fields = ('name', 'code')
    pagination_class = None

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return LanguageDetailSerializer
        return LanguageListSerializer  # ← Changed to List version


# ----------------------------------------------------------------------
# Country ViewSet (Public Country List)
# ----------------------------------------------------------------------
class CountryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Public list of supported countries.
    Used for country selection in Flutter (e.g., user profile or onboarding).
    """
    queryset = Country.objects.filter(is_active=True).order_by('name')
    serializer_class = CountrySerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ('name', 'code')
    pagination_class = None


# ----------------------------------------------------------------------
# Country Override ViewSet (Read-only for overrides)
# ----------------------------------------------------------------------
class CountryOverrideViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Public read-only view for country-specific overrides.
    Returns greetings, holiday banners, cultural notes, theme tweaks.
    """
    queryset = CountryOverride.objects.all()
    serializer_class = CountryOverrideSerializer
    permission_classes = [AllowAny]
    lookup_field = 'country__code'
    lookup_url_kwarg = 'country_code'

    def get_queryset(self):
        country_code = self.kwargs.get('country_code')
        if country_code:
            return CountryOverride.objects.filter(country__code=country_code.upper())
        return super().get_queryset()


# ----------------------------------------------------------------------
# State & City ViewSets (Cascading Selection)
# ----------------------------------------------------------------------

class StateViewSet(viewsets.ReadOnlyModelViewSet):
    """
    List of states/provinces filtered by country.
    GET /api/v1/localization/states/?country_id=1
    """
    queryset = State.objects.filter(is_active=True).order_by('name')
    serializer_class = StateSerializer
    permission_classes = [AllowAny]
    pagination_class = None

    def get_queryset(self):
        queryset = self.queryset
        country_id = self.request.query_params.get('country_id')
        country_code = self.request.query_params.get('country_code')
        
        if country_id:
            queryset = queryset.filter(country_id=country_id)
        elif country_code:
            queryset = queryset.filter(country__code=country_code.upper())
            
        return queryset


class CityViewSet(viewsets.ReadOnlyModelViewSet):
    """
    List of cities filtered by state.
    GET /api/v1/localization/cities/?state_id=1
    """
    queryset = City.objects.filter(is_active=True).order_by('name')
    serializer_class = CitySerializer
    permission_classes = [AllowAny]
    pagination_class = None

    def get_queryset(self):
        queryset = self.queryset
        state_id = self.request.query_params.get('state_id')
        country_id = self.request.query_params.get('country_id')
        country_code = self.request.query_params.get('country_code')

        if state_id:
            queryset = queryset.filter(state_id=state_id)
        elif country_id:
            queryset = queryset.filter(state__country_id=country_id)
        elif country_code:
            queryset = queryset.filter(state__country__code=country_code.upper())

        return queryset


# ----------------------------------------------------------------------
# Master Localization Config API (One-call for Flutter)
# ----------------------------------------------------------------------
class LocalizationConfigAPIView(APIView):
    """
    GET /api/v1/localization/config/
    Returns COMPLETE localization data in one call.
    
    Query params:
    ?country=ZA  → Country-specific override (greeting, holiday, theme tweaks)
    ?lang=zu     → Translations in isiZulu (default: 'en')
    
    Ideal for Flutter initial load / cache refresh.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        country_code = request.query_params.get('country', 'ZA').upper()
        lang_code = request.query_params.get('lang', 'en').lower()

        # Fetch current override
        current_override = CountryOverride.get_current(country_code)

        # Fetch translations for selected language
        lang = Language.objects.filter(code=lang_code, status=1).first()
        translations = TranslationSerializer(
            lang.translations.all() if lang else Translation.objects.none(),
            many=True
        ).data

        data = {
            'languages': LanguageListSerializer(  # ← Use ListSerializer here
                Language.objects.filter(status=1).order_by('name'),
                many=True
            ).data,
            'countries': CountrySerializer(
                Country.objects.filter(is_active=True).order_by('name'),
                many=True
            ).data,
            'translations': translations,
            'current_override': CountryOverrideSerializer(current_override).data if current_override else None,
        }

        return Response(data)


# ----------------------------------------------------------------------
# Promotions API (delegates to unified CouponCode — promotions ARE coupons)
# ----------------------------------------------------------------------
class PromotionListView(APIView):
    """
    GET /api/v1/localization/promotions/
    Returns active promotions for display as animated flyers on the onboarding page.

    Promotions and coupons are unified: every promotion is a CouponCode with
    display fields (background_color, icon, cta_text, etc.).  A promotion can be
    global (country_restriction blank) or localised (specific countries M2M).

    Query params:
    ?country=ZA           → filter by country code
    ?placement=onboarding → onboarding|home|splash (default: onboarding)

    Response shape is backward-compatible with the old LocalizedPromotion serializer
    so the Flutter PromoFlyerWidget works without changes.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        from apps.payments.models import CouponCode, CouponClientType
        now = timezone.now()
        today = now.date()
        country_code = request.query_params.get('country', '').upper().strip()
        placement = request.query_params.get('placement', 'onboarding').lower().strip()

        qs = CouponCode.objects.filter(
            is_active=True,
            valid_from__lte=now,
            valid_until__gte=now,
        ).exclude(
            client_type=CouponClientType.CORPORATE,
        ).exclude(
            client_type=CouponClientType.PRIVATE,
        )

        # Filter by placement flag
        if placement == 'home':
            qs = qs.filter(show_on_home=True)
        elif placement == 'splash':
            qs = qs.filter(show_on_splash=True)
        else:
            qs = qs.filter(show_on_onboarding=True)

        # Filter by country: match M2M countries or country_restriction or global (both blank)
        if country_code:
            country_obj = Country.objects.filter(code=country_code, is_active=True).first()
            if country_obj:
                # Include: global promos (no countries M2M + no country_restriction)
                # + promos targeting this country via M2M
                # + promos with matching country_restriction
                from django.db.models import Q
                qs = qs.filter(
                    Q(countries=country_obj) |
                    Q(countries__isnull=True, country_restriction='') |
                    Q(country_restriction=country_code)
                ).distinct()

        qs = qs.order_by('-priority', '-valid_until')

        data = []
        for c in qs:
            if c.usage_limit and c.times_used >= c.usage_limit:
                continue

            days_left = (c.valid_until - now).days
            discount_pct = None
            if c.discount_type in ('percentage', 'capped_percentage'):
                discount_pct = float(c.discount_value)

            # Backward-compatible shape for Flutter Promotion.fromJson
            data.append({
                'id': c.id,
                'title': c.name,
                'description': c.description,
                'promotion_type': c.promotion_type,
                'image_url': c.image_url or None,
                'background_color': c.background_color,
                'text_color': c.text_color,
                'icon': c.icon,
                'discount_percentage': discount_pct,
                'cta_text': c.cta_text,
                'cta_url': c.cta_url or None,
                'start_date': c.valid_from.date().isoformat(),
                'end_date': c.valid_until.date().isoformat(),
                'priority': c.priority,
                'show_on_onboarding': c.show_on_onboarding,
                'is_currently_active': True,
                'days_remaining': max(0, days_left),
                # Bonus: include coupon code for promo flyer CTA
                'code': c.code,
            })

        return Response(data)


# ----------------------------------------------------------------------
# Admin-only Sync Endpoint (Future-proof)
# ----------------------------------------------------------------------
class LanguageSyncView(APIView):
    """
    POST /api/v1/localization/sync/
    Admin-only placeholder for future language-pack sync (e.g., from CDN/repo).
    Returns current DB state for debugging.
    """
    permission_classes = [IsAdminUser]

    def post(self, request):
        # Future: Implement real sync (download JSON packs, update Language/Translation rows)
        stats = {
            'total_languages': Language.objects.count(),
            'active_languages': Language.objects.filter(status=1).count(),
            'with_translations': Language.objects.filter(json_exist=1).count(),
            'total_countries': Country.objects.count(),
            'total_overrides': CountryOverride.objects.count(),
            'synced_at': timezone.now().isoformat(),
        }

        return Response({
            "message": "Language & localization catalogue is up-to-date (no external sync implemented yet).",
            "stats": stats,
            "sample_languages": LanguageListSerializer(  # ← Use ListSerializer
                Language.objects.filter(status=1)[:5],
                many=True
            ).data
        }, status=status.HTTP_200_OK)


# ----------------------------------------------------------------------
# African Country Greeting API (IP + country-sensitive localisation)
# ----------------------------------------------------------------------

AFRICAN_GREETINGS = {
    # East Africa
    'KE': {'country': 'Kenya', 'flag': '🇰🇪',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Kiswahili', 'greeting': 'Karibu!'}},
    'TZ': {'country': 'Tanzania', 'flag': '🇹🇿',
           'official': {'lang': 'Kiswahili', 'greeting': 'Karibu!'},
           'local': {'lang': 'Kiswahili', 'greeting': 'Karibu sana!'}},
    'UG': {'country': 'Uganda', 'flag': '🇺🇬',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Luganda', 'greeting': 'Tukusanyukidde!'}},
    'RW': {'country': 'Rwanda', 'flag': '🇷🇼',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Kinyarwanda', 'greeting': 'Murakaza neza!'}},
    'BI': {'country': 'Burundi', 'flag': '🇧🇮',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Kirundi', 'greeting': 'Ikaze!'}},
    'ET': {'country': 'Ethiopia', 'flag': '🇪🇹',
           'official': {'lang': 'Amharic', 'greeting': 'እንኳን ደህና መጡ!'},
           'local': {'lang': 'Afaan Oromo', 'greeting': 'Baga nagaan dhuftan!'}},
    'SO': {'country': 'Somalia', 'flag': '🇸🇴',
           'official': {'lang': 'Somali', 'greeting': 'Soo dhowow!'},
           'local': {'lang': 'Somali', 'greeting': 'Soo dhowow!'}},
    'DJ': {'country': 'Djibouti', 'flag': '🇩🇯',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Somali', 'greeting': 'Soo dhowow!'}},
    'ER': {'country': 'Eritrea', 'flag': '🇪🇷',
           'official': {'lang': 'Tigrinya', 'greeting': 'ብደሓን መጻእኩም!'},
           'local': {'lang': 'Tigrinya', 'greeting': 'ሰላም!'}},
    # West Africa
    'NG': {'country': 'Nigeria', 'flag': '🇳🇬',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Hausa', 'greeting': 'Sannu da zuwa!'}},
    'GH': {'country': 'Ghana', 'flag': '🇬🇭',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Twi', 'greeting': 'Akwaaba!'}},
    'SN': {'country': 'Senegal', 'flag': '🇸🇳',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Wolof', 'greeting': 'Dalal ak jamm!'}},
    'CI': {'country': "Côte d'Ivoire", 'flag': '🇨🇮',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Dioula', 'greeting': 'I bɛ sɔrɔ!'}},
    'ML': {'country': 'Mali', 'flag': '🇲🇱',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Bambara', 'greeting': 'I ni tɛ!'}},
    'BF': {'country': 'Burkina Faso', 'flag': '🇧🇫',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Mooré', 'greeting': 'Yaa soore!'}},
    'NE': {'country': 'Niger', 'flag': '🇳🇪',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Hausa', 'greeting': 'Sannu!'}},
    'GN': {'country': 'Guinea', 'flag': '🇬🇳',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Pular', 'greeting': 'Jëkkër!'}},
    'TG': {'country': 'Togo', 'flag': '🇹🇬',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Ewe', 'greeting': 'Woezon!'}},
    'BJ': {'country': 'Benin', 'flag': '🇧🇯',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Fon', 'greeting': 'Akpédo!'}},
    'LR': {'country': 'Liberia', 'flag': '🇱🇷',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Kpelle', 'greeting': 'I kaa tɔɔ!'}},
    'SL': {'country': 'Sierra Leone', 'flag': '🇸🇱',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Krio', 'greeting': 'Wellcam!'}},
    'GM': {'country': 'Gambia', 'flag': '🇬🇲',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Mandinka', 'greeting': 'I be gnaa!'}},
    'GW': {'country': 'Guinea-Bissau', 'flag': '🇬🇼',
           'official': {'lang': 'Portuguese', 'greeting': 'Bem-vindo!'},
           'local': {'lang': 'Crioulo', 'greeting': 'Ben-bindu!'}},
    'CV': {'country': 'Cape Verde', 'flag': '🇨🇻',
           'official': {'lang': 'Portuguese', 'greeting': 'Bem-vindo!'},
           'local': {'lang': 'Cabo Verdiano', 'greeting': 'Bem-bindu!'}},
    'MR': {'country': 'Mauritania', 'flag': '🇲🇷',
           'official': {'lang': 'Arabic', 'greeting': 'أهلاً وسهلاً!'},
           'local': {'lang': 'Hassaniya', 'greeting': 'Marhba!'}},
    # Central Africa
    'CM': {'country': 'Cameroon', 'flag': '🇨🇲',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Fulfulde', 'greeting': 'Jam tan!'}},
    'CD': {'country': 'DR Congo', 'flag': '🇨🇩',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Lingala', 'greeting': 'Boyei malamu!'}},
    'CG': {'country': 'Congo', 'flag': '🇨🇬',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Lingala', 'greeting': 'Boyei malamu!'}},
    'CF': {'country': 'Central African Republic', 'flag': '🇨🇫',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Sango', 'greeting': 'Bara lo!'}},
    'GA': {'country': 'Gabon', 'flag': '🇬🇦',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Fang', 'greeting': 'Akiba!'}},
    'GQ': {'country': 'Equatorial Guinea', 'flag': '🇬🇶',
           'official': {'lang': 'Spanish', 'greeting': '¡Bienvenido!'},
           'local': {'lang': 'Fang', 'greeting': 'Akiba!'}},
    'ST': {'country': 'São Tomé and Príncipe', 'flag': '🇸🇹',
           'official': {'lang': 'Portuguese', 'greeting': 'Bem-vindo!'},
           'local': {'lang': 'Forro', 'greeting': 'Bem-vindô!'}},
    'TD': {'country': 'Chad', 'flag': '🇹🇩',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Chadian Arabic', 'greeting': 'Marhaba!'}},
    # Southern Africa
    'ZA': {'country': 'South Africa', 'flag': '🇿🇦',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Zulu', 'greeting': 'Sawubona!'}},
    'ZW': {'country': 'Zimbabwe', 'flag': '🇿🇼',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Shona', 'greeting': 'Mauya!'}},
    'ZM': {'country': 'Zambia', 'flag': '🇿🇲',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Nyanja', 'greeting': 'Takulandirani!'}},
    'BW': {'country': 'Botswana', 'flag': '🇧🇼',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Setswana', 'greeting': 'Re a go amogela!'}},
    'NA': {'country': 'Namibia', 'flag': '🇳🇦',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Oshiwambo', 'greeting': 'Onkene omwa hala!'}},
    'LS': {'country': 'Lesotho', 'flag': '🇱🇸',
           'official': {'lang': 'Sesotho', 'greeting': 'Amohelehile!'},
           'local': {'lang': 'Sesotho', 'greeting': 'Lumela!'}},
    'SZ': {'country': 'Eswatini', 'flag': '🇸🇿',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Swati', 'greeting': 'Siyakwamukela!'}},
    'MZ': {'country': 'Mozambique', 'flag': '🇲🇿',
           'official': {'lang': 'Portuguese', 'greeting': 'Bem-vindo!'},
           'local': {'lang': 'Makua', 'greeting': 'Mpshakame!'}},
    'MW': {'country': 'Malawi', 'flag': '🇲🇼',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Chichewa', 'greeting': 'Mwanakwathu!'}},
    'AO': {'country': 'Angola', 'flag': '🇦🇴',
           'official': {'lang': 'Portuguese', 'greeting': 'Bem-vindo!'},
           'local': {'lang': 'Umbundu', 'greeting': 'Kwasoko!'}},
    # North Africa
    'EG': {'country': 'Egypt', 'flag': '🇪🇬',
           'official': {'lang': 'Arabic', 'greeting': 'أهلاً وسهلاً!'},
           'local': {'lang': 'Masri', 'greeting': 'Ahlan!'}},
    'MA': {'country': 'Morocco', 'flag': '🇲🇦',
           'official': {'lang': 'Arabic', 'greeting': 'مرحباً بكم!'},
           'local': {'lang': 'Darija', 'greeting': 'Merhba!'}},
    'DZ': {'country': 'Algeria', 'flag': '🇩🇿',
           'official': {'lang': 'Arabic', 'greeting': 'أهلاً وسهلاً!'},
           'local': {'lang': 'Tamazight', 'greeting': 'Azul!'}},
    'TN': {'country': 'Tunisia', 'flag': '🇹🇳',
           'official': {'lang': 'Arabic', 'greeting': 'أهلاً وسهلاً!'},
           'local': {'lang': 'Tunisian Arabic', 'greeting': 'Sbiha lekhir!'}},
    'LY': {'country': 'Libya', 'flag': '🇱🇾',
           'official': {'lang': 'Arabic', 'greeting': 'أهلاً وسهلاً!'},
           'local': {'lang': 'Libyan Arabic', 'greeting': 'Ahlan!'}},
    'SD': {'country': 'Sudan', 'flag': '🇸🇩',
           'official': {'lang': 'Arabic', 'greeting': 'أهلاً وسهلاً!'},
           'local': {'lang': 'Sudanese Arabic', 'greeting': 'Ahlan wa sahlan!'}},
    'SS': {'country': 'South Sudan', 'flag': '🇸🇸',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Dinka', 'greeting': 'Aciek!'}},
    # Indian Ocean Islands
    'MG': {'country': 'Madagascar', 'flag': '🇲🇬',
           'official': {'lang': 'French', 'greeting': 'Bienvenue!'},
           'local': {'lang': 'Malagasy', 'greeting': 'Tongasoa!'}},
    'MU': {'country': 'Mauritius', 'flag': '🇲🇺',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Mauritian Creole', 'greeting': 'Bonzour!'}},
    'KM': {'country': 'Comoros', 'flag': '🇰🇲',
           'official': {'lang': 'Arabic', 'greeting': 'أهلاً!'},
           'local': {'lang': 'Comorian', 'greeting': 'Karibu!'}},
    'SC': {'country': 'Seychelles', 'flag': '🇸🇨',
           'official': {'lang': 'English', 'greeting': 'Welcome!'},
           'local': {'lang': 'Seychellois Creole', 'greeting': 'Byenveni!'}},
}


class GreetingAPIView(APIView):
    """
    GET /api/v1/localization/greeting/?country=KE
    Returns bilingual greeting for the given African country code.
    Official language greeting + most popular local language greeting.
    Fallback: English/Kiswahili if country not found.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        country_code = request.query_params.get('country', '').upper().strip()
        data = AFRICAN_GREETINGS.get(country_code, AFRICAN_GREETINGS.get('DEFAULT', {
            'country': 'Africa', 'flag': '🌍',
            'official': {'lang': 'English', 'greeting': 'Welcome!'},
            'local': {'lang': 'Kiswahili', 'greeting': 'Karibu!'},
        }))
        return Response({
            'country_code': country_code or 'UNKNOWN',
            'country_name': data.get('country', 'Africa'),
            'flag': data.get('flag', '🌍'),
            'official_language': data['official']['lang'],
            'official_greeting': data['official']['greeting'],
            'local_language': data['local']['lang'],
            'local_greeting': data['local']['greeting'],
        })