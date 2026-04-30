"""
Test settings for LMS project.
Inherits from main settings but overrides for faster, isolated testing.
"""
from .settings import *  # noqa

# Override settings for testing
DEBUG = True
TESTING = True

# Use in-memory SQLite for faster tests
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': ':memory:',
    }
}

# Faster password hashing for tests
PASSWORD_HASHERS = [
    'django.contrib.auth.hashers.MD5PasswordHasher',
]

# Disable migrations for faster test database creation
class DisableMigrations:
    def __contains__(self, item):
        return True

    def __getitem__(self, item):
        return None


# Comment this out if you need to test migrations
# MIGRATION_MODULES = DisableMigrations()

# Use console email backend for tests
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

# Disable Celery for tests (run synchronously)
CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = True

# Disable Redis requirement for tests
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
    }
}



# Simplified logging for tests
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
        },
    },
    'root': {
        'handlers': ['console'],
        'level': 'WARNING',
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'WARNING',
            'propagate': False,
        },
    },
}

# Disable CORS restrictions in tests
CORS_ALLOW_ALL_ORIGINS = True

# Use test payment provider credentials (sandbox)
PAYMENT_SANDBOX_MODE = True
FLUTTERWAVE_PUBLIC_KEY = 'FLWPUBK_TEST-test'
FLUTTERWAVE_SECRET_KEY = 'FLWSECK_TEST-test'
PAYSTACK_PUBLIC_KEY = 'pk_test_test'
PAYSTACK_SECRET_KEY = 'sk_test_test'

# Fast static files storage for tests
STATICFILES_STORAGE = 'django.contrib.staticfiles.storage.StaticFilesStorage'

# Disable whitenoise for tests
MIDDLEWARE = [m for m in MIDDLEWARE if 'whitenoise' not in m.lower()]

# Allow weak SECRET_KEY for tests
SECRET_KEY = 'test-secret-key-for-testing-only-do-not-use-in-production'

# Allow any host in tests
ALLOWED_HOSTS = ['*']

# Disable security features for easier testing
SESSION_COOKIE_SECURE = False
CSRF_COOKIE_SECURE = False
SECURE_SSL_REDIRECT = False

