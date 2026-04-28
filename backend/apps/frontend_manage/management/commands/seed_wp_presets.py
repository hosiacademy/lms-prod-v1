# apps/frontend_manage/management/commands/seed_wp_presets.py
from django.core.management.base import BaseCommand
from frontend_manage.models import ThemePreset, AppAppearance

class Command(BaseCommand):
    help = 'Seed WordPress theme presets and apply default appearance'
    
    def add_arguments(self, parser):
        parser.add_argument(
            '--reset',
            action='store_true',
            help='Reset all presets to default values (will delete existing presets)',
        )
        parser.add_argument(
            '--apply-default',
            action='store_true',
            help='Apply WordPress Default preset to global appearance',
        )
    
    def handle(self, *args, **options):
        reset = options['reset']
        apply_default = options['apply_default']
        
        if reset:
            self.stdout.write("Resetting all theme presets...")
            ThemePreset.objects.all().delete()
            self.stdout.write(self.style.WARNING("All existing presets deleted."))
        
        presets = self.get_wordpress_presets()
        
        created_count = 0
        updated_count = 0
        
        for preset_data in presets:
            preset, created = ThemePreset.objects.update_or_create(
                name=preset_data['name'],
                defaults=preset_data
            )
            
            if created:
                created_count += 1
                self.stdout.write(f"Created preset: {preset.name}")
            else:
                updated_count += 1
                self.stdout.write(f"Updated preset: {preset.name}")
        
        # Ensure only one preset is active (WordPress Default)
        active_presets = ThemePreset.objects.filter(is_active=True)
        if active_presets.count() > 1:
            # Deactivate all except WordPress Default
            ThemePreset.objects.filter(
                is_active=True
            ).exclude(
                name='WordPress Default'
            ).update(is_active=False)
            self.stdout.write(self.style.WARNING("Deactivated extra active presets, keeping only WordPress Default as active."))
        
        # Apply WordPress Default to global appearance if requested
        if apply_default:
            self.apply_wordpress_default()
        
        self.stdout.write(self.style.SUCCESS(
            f'Successfully seeded WordPress theme presets: '
            f'{created_count} created, {updated_count} updated'
        ))
    
    def get_wordpress_presets(self):
        """Return complete WordPress theme presets with design tokens"""
        return [
            {
                'name': 'WordPress Default',
                'preset_type': 'wp_default',
                'description': 'Standard WordPress color scheme with Vivid Cyan Blue',
                'primary_color': '#0693E3',
                'primary_variant': '#8ED1FC',
                'secondary_color': '#9B51E0',
                'accent_color': '#00D084',
                'background_color': '#FFFFFF',
                'text_primary': '#000000',
                'shadow_type': 'natural',
                'spacing_scale': 's40',
                'font_size': 'medium',
                'thumbnail_url': 'https://via.placeholder.com/300x200/0693E3/FFFFFF?text=WordPress+Default',
                'is_active': True,
                'is_recommended': True,
                'sort_order': 1,
            },
            {
                'name': 'WordPress Vivid',
                'preset_type': 'wp_vivid',
                'description': 'Bright and energetic orange/red theme',
                'primary_color': '#FF6900',
                'primary_variant': '#FCB900',
                'secondary_color': '#CF2E2E',
                'accent_color': '#F78DA7',
                'background_color': '#FFFFFF',
                'text_primary': '#000000',
                'shadow_type': 'sharp',
                'spacing_scale': 's40',
                'font_size': 'medium',
                'thumbnail_url': 'https://via.placeholder.com/300x200/FF6900/FFFFFF?text=WordPress+Vivid',
                'is_active': False,
                'is_recommended': False,
                'sort_order': 2,
            },
            {
                'name': 'WordPress Pastel',
                'preset_type': 'wp_pastel',
                'description': 'Soft pastel colors for a gentle, friendly look',
                'primary_color': '#8ED1FC',
                'primary_variant': '#F78DA7',
                'secondary_color': '#7BDCB5',
                'accent_color': '#FCB900',
                'background_color': '#FFFFFF',
                'text_primary': '#000000',
                'shadow_type': 'natural',
                'spacing_scale': 's40',
                'font_size': 'medium',
                'thumbnail_url': 'https://via.placeholder.com/300x200/8ED1FC/000000?text=WordPress+Pastel',
                'is_active': False,
                'is_recommended': False,
                'sort_order': 3,
            },
            {
                'name': 'WordPress Dark',
                'preset_type': 'wp_dark',
                'description': 'Dark mode with vibrant accents for reduced eye strain',
                'primary_color': '#0693E3',
                'primary_variant': '#8ED1FC',
                'secondary_color': '#9B51E0',
                'accent_color': '#00D084',
                'background_color': '#121212',
                'text_primary': '#FFFFFF',
                'shadow_type': 'deep',
                'spacing_scale': 's40',
                'font_size': 'medium',
                'thumbnail_url': 'https://via.placeholder.com/300x200/121212/FFFFFF?text=WordPress+Dark',
                'is_active': False,
                'is_recommended': True,
                'sort_order': 4,
            },
            {
                'name': 'WordPress Professional',
                'preset_type': 'wp_professional',
                'description': 'Professional blue/purple theme for business and education',
                'primary_color': '#0693E3',
                'primary_variant': '#8ED1FC',
                'secondary_color': '#9B51E0',
                'accent_color': '#00D084',
                'background_color': '#FFFFFF',
                'text_primary': '#1A1A1A',
                'shadow_type': 'natural',
                'spacing_scale': 's50',
                'font_size': 'medium',
                'thumbnail_url': 'https://via.placeholder.com/300x200/0693E3/FFFFFF?text=WordPress+Professional',
                'is_active': False,
                'is_recommended': True,
                'sort_order': 5,
            },
            {
                'name': 'WordPress Energetic',
                'preset_type': 'wp_energetic',
                'description': 'Energetic amber/orange theme for action and motivation',
                'primary_color': '#FCB900',
                'primary_variant': '#FF6900',
                'secondary_color': '#CF2E2E',
                'accent_color': '#9B51E0',
                'background_color': '#FFFFFF',
                'text_primary': '#000000',
                'shadow_type': 'sharp',
                'spacing_scale': 's40',
                'font_size': 'medium',
                'thumbnail_url': 'https://via.placeholder.com/300x200/FCB900/000000?text=WordPress+Energetic',
                'is_active': False,
                'is_recommended': False,
                'sort_order': 6,
            },
            {
                'name': 'WordPress Nature',
                'preset_type': 'wp_nature',
                'description': 'Natural green/cyan theme for environmental and wellness platforms',
                'primary_color': '#00D084',
                'primary_variant': '#7BDCB5',
                'secondary_color': '#0693E3',
                'accent_color': '#FCB900',
                'background_color': '#FFFFFF',
                'text_primary': '#000000',
                'shadow_type': 'natural',
                'spacing_scale': 's40',
                'font_size': 'medium',
                'thumbnail_url': 'https://via.placeholder.com/300x200/00D084/FFFFFF?text=WordPress+Nature',
                'is_active': False,
                'is_recommended': False,
                'sort_order': 7,
            },
            {
                'name': 'Afro-Centric Pan-African',
                'preset_type': 'custom',
                'description': 'Pan-African colors (red, black, green, gold) celebrating African heritage',
                'primary_color': '#E31B23',  # Red
                'primary_variant': '#000000',  # Black
                'secondary_color': '#008751',  # Green
                'accent_color': '#FCD116',  # Gold/Yellow
                'background_color': '#FFFFFF',
                'text_primary': '#000000',
                'shadow_type': 'natural',
                'spacing_scale': 's40',
                'font_size': 'medium',
                'thumbnail_url': 'https://via.placeholder.com/300x200/E31B23/FFFFFF?text=Pan-African',
                'is_active': False,
                'is_recommended': True,
                'sort_order': 8,
            },
            {
                'name': 'African Sunset',
                'preset_type': 'custom',
                'description': 'Warm sunset colors inspired by African landscapes',
                'primary_color': '#FF6B35',  # Orange
                'primary_variant': '#FFA500',  # Light Orange
                'secondary_color': '#8B4513',  # Saddle Brown
                'accent_color': '#FFD700',  # Gold
                'background_color': '#FFF5E1',  # Light Cream
                'text_primary': '#333333',
                'shadow_type': 'natural',
                'spacing_scale': 's40',
                'font_size': 'medium',
                'thumbnail_url': 'https://via.placeholder.com/300x200/FF6B35/FFFFFF?text=African+Sunset',
                'is_active': False,
                'is_recommended': False,
                'sort_order': 9,
            },
            {
                'name': 'Savanna Earth',
                'preset_type': 'custom',
                'description': 'Earth tones inspired by African savannas and wildlife',
                'primary_color': '#8B4513',  # Saddle Brown
                'primary_variant': '#D2691E',  # Chocolate
                'secondary_color': '#228B22',  # Forest Green
                'accent_color': '#DAA520',  # Goldenrod
                'background_color': '#F5F5DC',  # Beige
                'text_primary': '#333333',
                'shadow_type': 'natural',
                'spacing_scale': 's40',
                'font_size': 'medium',
                'thumbnail_url': 'https://via.placeholder.com/300x200/8B4513/FFFFFF?text=Savanna+Earth',
                'is_active': False,
                'is_recommended': False,
                'sort_order': 10,
            },
        ]
    
    def apply_wordpress_default(self):
        """Apply WordPress Default preset to global appearance"""
        try:
            # Get or create global appearance
            appearance, created = AppAppearance.objects.get_or_create(user=None)
            
            # Get WordPress Default preset
            default_preset = ThemePreset.objects.filter(
                name='WordPress Default',
                preset_type='wp_default'
            ).first()
            
            if default_preset:
                # Apply the preset
                default_preset.apply_to_appearance(appearance)
                
                # Set additional WordPress design tokens
                appearance.shadow_preset = 'natural'
                appearance.spacing_preset = 's40'
                appearance.font_size_preset = 'medium'
                appearance.border_radius = 'medium'
                appearance.button_style = 'rounded'
                appearance.font_family = 'Roboto'
                appearance.font_family_secondary = 'Open Sans'
                appearance.font_size_multiplier = 1.0
                appearance.is_dark_mode = False
                
                # Set error, warning, success colors from WordPress palette
                appearance.error_color = '#CF2E2E'
                appearance.warning_color = '#FCB900'
                appearance.success_color = '#00D084'
                appearance.text_secondary = '#666666'
                appearance.text_tertiary = '#ABB8C3'
                appearance.surface_color = '#F5F5F7'
                
                appearance.save()
                
                self.stdout.write(self.style.SUCCESS(
                    'Applied WordPress Default preset to global appearance'
                ))
            else:
                self.stdout.write(self.style.ERROR(
                    'WordPress Default preset not found. Please seed presets first.'
                ))
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(
                f'Error applying WordPress Default: {str(e)}'
            ))


# Create a separate command for appearance setup
class SetupAppearanceCommand(BaseCommand):
    help = 'Setup initial appearance with WordPress defaults'
    
    def handle(self, *args, **options):
        # Seed presets first
        seed_command = Command()
        seed_command.handle(reset=False, apply_default=True)
        
        # Create default AppAppearance if it doesn't exist
        appearance, created = AppAppearance.objects.get_or_create(user=None)
        if created:
            self.stdout.write(self.style.SUCCESS('Created default global appearance'))
        
        self.stdout.write(self.style.SUCCESS('Appearance setup complete'))