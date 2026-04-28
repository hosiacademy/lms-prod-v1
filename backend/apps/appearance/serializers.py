# apps/appearance/serializers.py
"""
Serializers for visual appearance and theming.

Powers dynamic Afro-centric themes, color palettes,
typography, and branding in the Flutter app.

All data is database-driven — instant updates from admin,
no app redeployment needed.
"""

from rest_framework import serializers

from .models import Theme


class ThemeSerializer(serializers.ModelSerializer):
    """
    Full theme details – used for admin preview and internal tools.
    """
    is_current = serializers.SerializerMethodField()

    class Meta:
        model = Theme
        fields = (
            'id', 'name', 'title', 'image', 'version',
            'folder_path', 'live_link', 'description',
            'is_active', 'status', 'tags', 'is_current'
        )
        read_only_fields = ('is_current',)

    def get_is_current(self, obj):
        """True if this is the currently active theme."""
        return obj.is_active


class ActiveThemeSerializer(serializers.ModelSerializer):
    """
    Lightweight serializer for the currently active theme.
    Primary payload sent to Flutter on app startup.
    """
    class Meta:
        model = Theme
        fields = (
            'id', 'name', 'title', 'image',
            'folder_path', 'description', 'tags'
        )


class AppearanceConfigSerializer(serializers.Serializer):
    """
    Master appearance configuration endpoint.
    Returns the active theme + any global overrides.
    Ideal for initial app load and theme caching.
    """
    active_theme = ActiveThemeSerializer(read_only=True)
    themes = ThemeSerializer(many=True, read_only=True)
    # Future: global color/typography overrides
    # primary_color = serializers.CharField(read_only=True)
    # font_family = serializers.CharField(read_only=True)

    def to_representation(self, instance):
        active = Theme.objects.filter(is_active=True).first()
        all_themes = Theme.objects.filter(status=True)

        return {
            'active_theme': active,
            'themes': all_themes,
            'updated_at': active.updated_at.isoformat() if active else None,
            'message': "Afro-centric theme loaded. Empowering African learners with beauty and pride."
        }