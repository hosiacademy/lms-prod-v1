# apps/frontend_manage/management/commands/seed_comprehensive_themes.py

from django.core.management.base import BaseCommand
from apps.frontend_manage.models import AppAppearance, ThemePreset


class Command(BaseCommand):
    help = 'Seed comprehensive theme presets matching current app design'

    def handle(self, *args, **options):
        self.stdout.write(self.style.SUCCESS('Seeding comprehensive theme presets...'))

        # Create Global Dark Mode Appearance (matching current app)
        global_dark, created = AppAppearance.objects.get_or_create(
            user=None,  # Global theme
            defaults={
                # Brand colors
                'primary_color': '#0693E3',  # Vivid Cyan Blue
                'primary_variant': '#8ED1FC',  # Pale Cyan Blue
                'secondary_color': '#9B51E0',  # Vivid Purple
                'accent_color': '#00D084',  # Vivid Green Cyan

                # Semantic colors
                'error_color': '#CF2E2E',  # Vivid Red
                'warning_color': '#FCB900',  # Luminous Vivid Amber
                'success_color': '#00D084',  # Vivid Green Cyan
                'info_color': '#0693E3',  # Same as primary

                # Background colors
                'background_color': '#0D1117',  # GitHub Dark Background
                'surface_color': '#161B22',  # GitHub Dark Surface
                'surface_variant': '#21262D',  # Slightly lighter

                # Text colors
                'text_primary': '#E6F0FF',  # Light Blue Tint
                'text_secondary': '#C9D1D9',  # Muted Gray Blue
                'text_tertiary': '#8B949E',  # Dim Gray

                # "On" colors
                'on_primary': '#FFFFFF',
                'on_surface': '#E6F0FF',
                'on_background': '#E6F0FF',
                'on_error': '#FFFFFF',
                'on_warning': '#000000',
                'on_success': '#FFFFFF',

                # Border/outline colors
                'outline_color': '#30363D',
                'outline_variant': '#21262D',
                'divider_color': '#30363D',

                # Shadow
                'shadow_color': '#000000',
                'shadow_opacity': 0.15,

                # Component colors
                'card_color': '#161B22',
                'app_bar_color': '#161B22',
                'bottom_nav_color': '#161B22',
                'fab_color': '#0693E3',

                # Mode
                'is_dark_mode': True,

                # Design tokens
                'shadow_preset': 'natural',
                'spacing_preset': 's40',
                'font_size_preset': 'medium',
                'font_family': 'Roboto',
                'font_family_secondary': 'Open Sans',
                'font_size_multiplier': 1.0,
                'border_radius': 'medium',
                'button_style': 'rounded',
            }
        )

        if created:
            self.stdout.write(self.style.SUCCESS('[OK] Created global dark mode theme'))
        else:
            self.stdout.write(self.style.WARNING('[EXISTS] Global dark mode theme already exists'))

        # Create Comprehensive Dark Mode Preset
        dark_preset, created = ThemePreset.objects.get_or_create(
            name='GitHub Dark Pro',
            defaults={
                'preset_type': 'wp_dark',
                'description': 'Professional dark theme matching GitHub design with rich colors',
                'primary_color': '#0693E3',
                'primary_variant': '#8ED1FC',
                'secondary_color': '#9B51E0',
                'accent_color': '#00D084',
                'background_color': '#0D1117',
                'text_primary': '#E6F0FF',
                'shadow_type': 'natural',
                'spacing_scale': 's40',
                'font_size': 'medium',
                'is_recommended': True,
                'sort_order': 1,
            }
        )

        if created:
            self.stdout.write(self.style.SUCCESS('[OK] Created GitHub Dark Pro preset'))
        else:
            self.stdout.write(self.style.WARNING('[EXISTS] GitHub Dark Pro preset already exists'))

        # Create Professional Light Mode Preset
        light_preset, created = ThemePreset.objects.get_or_create(
            name='Professional Light',
            defaults={
                'preset_type': 'wp_professional',
                'description': 'Clean professional light theme',
                'primary_color': '#0693E3',
                'primary_variant': '#8ED1FC',
                'secondary_color': '#9B51E0',
                'accent_color': '#00D084',
                'background_color': '#F9FCFF',
                'text_primary': '#000000',
                'shadow_type': 'natural',
                'spacing_scale': 's40',
                'font_size': 'medium',
                'is_recommended': False,
                'sort_order': 2,
            }
        )

        if created:
            self.stdout.write(self.style.SUCCESS('[OK] Created Professional Light preset'))
        else:
            self.stdout.write(self.style.WARNING('[EXISTS] Professional Light preset already exists'))

        # Create Vibrant Dark Preset
        vibrant_dark, created = ThemePreset.objects.get_or_create(
            name='Vibrant Dark',
            defaults={
                'preset_type': 'custom',
                'description': 'Dark theme with vibrant accent colors',
                'primary_color': '#9B51E0',  # Vivid Purple
                'primary_variant': '#F78DA7',  # Pale Pink
                'secondary_color': '#00D084',  # Vivid Green Cyan
                'accent_color': '#FCB900',  # Luminous Vivid Amber
                'background_color': '#0D1117',
                'text_primary': '#E6F0FF',
                'shadow_type': 'deep',
                'spacing_scale': 's40',
                'font_size': 'medium',
                'is_recommended': False,
                'sort_order': 3,
            }
        )

        if created:
            self.stdout.write(self.style.SUCCESS('[OK] Created Vibrant Dark preset'))
        else:
            self.stdout.write(self.style.WARNING('[EXISTS] Vibrant Dark preset already exists'))

        # Create Ocean Blue Preset
        ocean_blue, created = ThemePreset.objects.get_or_create(
            name='Ocean Blue',
            defaults={
                'preset_type': 'custom',
                'description': 'Calming ocean-inspired theme',
                'primary_color': '#0693E3',  # Vivid Cyan Blue
                'primary_variant': '#8ED1FC',  # Pale Cyan Blue
                'secondary_color': '#7BDCB5',  # Light Green Cyan
                'accent_color': '#00D084',  # Vivid Green Cyan
                'background_color': '#0D1117',
                'text_primary': '#E6F0FF',
                'shadow_type': 'natural',
                'spacing_scale': 's40',
                'font_size': 'medium',
                'is_recommended': False,
                'sort_order': 4,
            }
        )

        if created:
            self.stdout.write(self.style.SUCCESS('[OK] Created Ocean Blue preset'))
        else:
            self.stdout.write(self.style.WARNING('[EXISTS] Ocean Blue preset already exists'))

        self.stdout.write(self.style.SUCCESS('\n✅ Theme seeding complete!'))
        self.stdout.write(self.style.SUCCESS(f'Total presets: {ThemePreset.objects.count()}'))
        self.stdout.write(self.style.SUCCESS(f'Global appearance configured: {"Yes" if AppAppearance.objects.filter(user=None).exists() else "No"}'))
