# Management command to create authentication providers
from django.core.management.base import BaseCommand, CommandError
from django.conf import settings
from apps.users.models import AuthenticationProvider


class Command(BaseCommand):
    help = 'Create or update authentication provider configuration'

    def add_arguments(self, parser):
        parser.add_argument(
            '--name',
            type=str,
            required=True,
            help='Provider name (e.g., AICerts, CompTIA, AWS)'
        )
        parser.add_argument(
            '--type',
            type=str,
            required=True,
            choices=['saml', 'oauth', 'ldap', 'local', 'aicerts_sso', 'moodle_sso', 'custom'],
            help='Provider authentication type'
        )
        parser.add_argument(
            '--default',
            action='store_true',
            help='Set as default provider'
        )
        parser.add_argument(
            '--disable',
            action='store_true',
            help='Disable the provider'
        )

    def handle(self, *args, **options):
        provider_name = options['name']
        provider_type = options['type']
        is_default = options['default']
        active = not options['disable']

        # Get configuration from settings if available
        provider_config = {}
        provider_key = provider_name.lower().replace(' ', '')

        if hasattr(settings, 'COURSE_PROVIDERS'):
            course_providers = settings.COURSE_PROVIDERS
            if provider_key in course_providers:
                provider_settings = course_providers[provider_key]
                provider_config = {
                    'base_url': provider_settings.get('base_url', ''),
                    'wstoken': provider_settings.get('wstoken', ''),
                    'secret': provider_settings.get('secret', ''),
                    'api_key': provider_settings.get('api_key', ''),
                    'auth_type': provider_settings.get('auth_type', provider_type),
                    'api_functions': provider_settings.get('api_functions', {}),
                }
                # Remove empty values
                provider_config = {k: v for k, v in provider_config.items() if v}

        # Create or update provider
        provider, created = AuthenticationProvider.objects.update_or_create(
            provider_name=provider_name,
            provider_type=provider_type,
            defaults={
                'config': provider_config,
                'is_default': is_default,
                'auto_provision': True,
                'active': active,
            }
        )

        # If setting as default, unset other defaults
        if is_default:
            AuthenticationProvider.objects.exclude(pk=provider.pk).update(is_default=False)

        action = 'Created' if created else 'Updated'
        self.stdout.write(
            self.style.SUCCESS(
                f'{action} authentication provider: {provider_name} ({provider_type})'
            )
        )

        if not active:
            self.stdout.write(self.style.WARNING(f'Provider is disabled'))
        if is_default:
            self.stdout.write(self.style.SUCCESS(f'Set as default provider'))

        self.stdout.write(f'Provider ID: {provider.id}')
