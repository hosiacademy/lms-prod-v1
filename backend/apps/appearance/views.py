# apps/appearance/views.py
"""
API views for dynamic visual appearance and theming.

These endpoints power your Flutter app's visual identity:
- Active theme loading
- Available theme catalogue
- Instant updates from admin without redeploy

Fully supports Afro-centric themes celebrating African heritage,
innovation, and unity.
"""

from rest_framework import viewsets, permissions
from rest_framework.views import APIView
from rest_framework.response import Response

from .models import Theme
from .serializers import (
    ThemeSerializer,
    ActiveThemeSerializer,
    AppearanceConfigSerializer
)


class ThemeViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Public read-only list of all available themes.
    Used by:
    - Flutter theme preview (future switcher)
    - Admin theme management
    """
    queryset = Theme.objects.filter(status=True).order_by('-is_active', 'title')
    serializer_class = ThemeSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        """
        Prioritize active theme first, then others.
        """
        return Theme.objects.filter(status=True).order_by('-is_active', 'title')


class AppearanceConfigView(APIView):
    """
    GET /api/v1/appearance/config/

    Primary endpoint for Flutter app startup.
    Returns the currently active theme + list of available themes.

    Optimized for caching (ETag / Cache-Control can be added later).
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        serializer = AppearanceConfigSerializer(instance=None)
        return Response(serializer.data)


class ActiveThemeView(APIView):
    """
    GET /api/v1/appearance/active/

    Lightweight endpoint — only the current active theme.
    Useful for quick checks or when caching the full config separately.
    """
    permission_classes = [permissions.AllowAny]

    def get(self, request):
        active_theme = Theme.objects.filter(is_active=True).first()
        if not active_theme:
            return Response({
                "message": "No active theme configured yet. Using default fallback.",
                "active_theme": None
            })
        serializer = ActiveThemeSerializer(active_theme)
        return Response({
            "active_theme": serializer.data,
            "updated_at": active_theme.updated_at.isoformat()
        })