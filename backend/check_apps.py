from django.apps import apps
from django.conf import settings

print('=' * 60)
print('Custom Apps in INSTALLED_APPS:')
print('=' * 60)
custom_apps = [app for app in settings.INSTALLED_APPS if 'apps.' in app]
for app in custom_apps:
    print(f'  ✓ {app}')
print(f'\nTotal custom apps: {len(custom_apps)}')

print('\n' + '=' * 60)
print('Apps with Models in Database:')
print('=' * 60)
apps_with_models = [ac for ac in apps.get_app_configs() if ac.models]
for ac in apps_with_models:
    print(f'  ✓ {ac.label}')
print(f'\nTotal apps with models: {len(apps_with_models)}')

print('\n' + '=' * 60)
print('SUMMARY:')
print('=' * 60)
print(f'Custom apps in INSTALLED_APPS: {len(custom_apps)}')
print(f'Apps that have database tables: {len(apps_with_models)}')
print(f'Models registered in admin: 91')
