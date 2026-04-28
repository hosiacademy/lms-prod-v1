# apps/frontend_manage/views.py
"""
API views for dynamic frontend content.

These endpoints power your Flutter app's homepage, login screen,
branding, themes, and modular sections — all managed from Django admin.

Fully supports real-time updates, Afro-centric messaging,
and cultural relevance without app redeployment.
"""

from rest_framework import viewsets, filters
from rest_framework.permissions import AllowAny
from rest_framework.views import APIView
from rest_framework.response import Response

from .models import AppAppearance, FrontendSetting, HomeContent, GeneralSetting, Theme, LoginPage
from .serializers import (
    AppAppearanceSerializer, FrontendSettingSerializer, 
    HomeContentSerializer, GeneralSettingSerializer, 
    ThemeSerializer, LoginPageSerializer, FrontendConfigSerializer
)


class FrontendSettingViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Public list of active frontend sections (hero, features, CTA, etc.).
    Used to build modular homepage in Flutter.
    """
    queryset = FrontendSetting.objects.filter(status=1).order_by('id')
    serializer_class = FrontendSettingSerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['id', 'section']
    ordering = ['id']


class ThemeViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Public list of available themes.
    Flutter can display theme preview and allow switching (if enabled).
    """
    queryset = Theme.objects.filter(status=True)
    serializer_class = ThemeSerializer
    permission_classes = [AllowAny]

    def get_queryset(self):
        return Theme.objects.filter(status=True)


class FrontendConfigView(APIView):
    """
    GET /api/v1/frontend/config/
    Master endpoint — returns ALL dynamic frontend content in one optimized call.
    Perfect for app startup: load once, cache, and render beautiful Afro-centric UI.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        from .serializers import (
            GeneralSettingSerializer, HomeContentSerializer,
            LoginPageSerializer, FrontendSettingSerializer,
            ThemeSerializer, AppAppearanceSerializer
        )
        
        data = {}
        
        # General settings
        general = GeneralSetting.objects.first()
        if general:
            data['general'] = GeneralSettingSerializer(general).data
        
        # Home content
        home = HomeContent.objects.first()
        if home:
            data['home'] = HomeContentSerializer(home).data
        
        # Login page
        login_page = LoginPage.objects.first()
        if login_page:
            data['login_page'] = LoginPageSerializer(login_page).data
        
        # Frontend sections
        sections = FrontendSetting.objects.filter(status=1).order_by('id')
        data['sections'] = FrontendSettingSerializer(sections, many=True).data
        
        # Themes
        themes = Theme.objects.filter(status=True)
        data['themes'] = ThemeSerializer(themes, many=True).data
        
        # Active theme
        active_theme = Theme.objects.filter(is_active=True, status=True).first()
        if active_theme:
            data['active_theme'] = ThemeSerializer(active_theme).data
        
        # Appearance
        appearance = AppAppearance.objects.first()
        if appearance:
            data['appearance'] = AppAppearanceSerializer(appearance).data
        else:
            # Create default if doesn't exist
            try:
                appearance = AppAppearance.objects.create(
                    primary_color='#1A1A1A',
                    primary_variant='#333333',
                    secondary_color='#0066CC',
                    background_color='#FFFFFF',
                    surface_color='#F5F5F7',
                    text_primary='#1A1A1A',
                    text_secondary='#666666',
                    is_dark_mode=False,
                    font_family='Roboto',
                )
                data['appearance'] = AppAppearanceSerializer(appearance).data
            except:
                data['appearance'] = {
                    'primary_color': '#1A1A1A',
                    'primary_variant': '#333333',
                    'secondary_color': '#0066CC',
                    'background_color': '#FFFFFF',
                    'surface_color': '#F5F5F7',
                    'text_primary': '#1A1A1A',
                    'text_secondary': '#666666',
                    'is_dark_mode': False,
                    'font_family': 'Roboto',
                }
        
        return Response(data)
    
class HomeContentView(APIView):
    """
    GET /api/v1/frontend/home/
    Dedicated endpoint for homepage content.
    Useful if you want to cache separately or load progressively.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        home = HomeContent.objects.first()
        if not home:
            return Response({"message": "Homepage content not configured yet."})
        serializer = HomeContentSerializer(home)
        return Response(serializer.data)


class GeneralSettingView(APIView):
    """
    GET /api/v1/frontend/settings/
    Global site branding and metadata.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        settings = GeneralSetting.objects.first()
        if not settings:
            return Response({"message": "Site settings not configured."})
        serializer = GeneralSettingSerializer(settings)
        return Response(serializer.data)


class LoginPageView(APIView):
    """
    GET /api/v1/frontend/login/
    Custom login page content and slogans.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        login_page = LoginPage.objects.first()
        if not login_page:
            return Response({"message": "Login page not configured."})
        serializer = LoginPageSerializer(login_page)
        return Response(serializer.data)


class AppAppearanceThemeView(APIView):
    """
    GET /api/v1/frontend/theme/
    Compatibility endpoint for Flutter ThemeCubit.
    Returns theme in the format: {'theme': {...}}
    """
    permission_classes = [AllowAny]

    def get(self, request):
        try:
            # Get AppAppearance (primary source)
            appearance = AppAppearance.objects.first()
            if appearance:
                serializer = AppAppearanceSerializer(appearance)
                return Response({
                    'theme': serializer.data,
                    'success': True
                })
        except Exception as e:
            print(f"AppAppearance error: {e}")
        
        # Fallback: Create default theme
        default_theme = {
            'primary_color': '#1A1A1A',
            'primary_variant': '#333333',
            'secondary_color': '#0066CC',
            'background_color': '#FFFFFF',
            'surface_color': '#F5F5F7',
            'text_primary': '#1A1A1A',
            'text_secondary': '#666666',
            'is_dark_mode': False,
            'font_family': 'Roboto',
        }
        
        return Response({
            'theme': default_theme,
            'success': True,
            'note': 'Using default theme (AppAppearance not configured)'
        })