"""
Django settings for lms_project project.
Generated and customized for Hosi Academy LMS monorepo (Django + Flutter).
Africa-focused, culturally resonant, and impact-driven.
Partner integration with AI Certs - courses synced automatically.
Facilitators & Trainers Analytics and Assignment System.
"""
import os
import logging
import mimetypes
from datetime import timedelta
from pathlib import Path
from decouple import Config, RepositoryEnv, Csv

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# Explicitly load .env from the backend directory
env_path = BASE_DIR / '.env'
config = Config(RepositoryEnv(str(env_path)))

# Ensure SVG files are served with the correct MIME type (critical for Flutter Web)
mimetypes.add_type("image/svg+xml", ".svg", True)

logger = logging.getLogger(__name__)

# ==================== CELERY CONFIGURATION ====================
# Must be at the top for proper module loading
# from celery import Celery  # Temporarily disabled due to circular import

# Set the default Django settings module for the Celery app
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')

# ==================== BUILD PATHS ====================
BASE_DIR = Path(__file__).resolve().parent.parent

# ==================== SECURITY & BASIC SETTINGS ====================
SECRET_KEY = config('SECRET_KEY', default='django-insecure-change-me-in-production-please')
DEBUG = config('DEBUG', default=True, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost,127.0.0.1', cast=Csv())

# ==================== URL CONFIGURATION ====================
SITE_URL = config('SITE_URL', default='http://127.0.0.1:8000')
FRONTEND_URL = config('FRONTEND_URL', default='http://localhost:3000')

# ==================== INSTALLED APPS ====================
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    'corsheaders',
    'rest_framework',
    'rest_framework_simplejwt',
    
    'apps.users',
    'core',
    'apps.aicerts_courses',
    'apps.courses',
    'apps.learnerships',
    'apps.payments',
    'apps.communication',
    'apps.notifications',
    'apps.content',
    'apps.appearance',
    'apps.frontend_manage',
    'apps.localization',
    'apps.organizations',
    'apps.analytics',
    'apps.instructors',
    'apps.industry_based_training',
    'apps.masterclasses',
    'apps.learner_portal',
    'apps.bbb_integration',
    'apps.aicerts_integration',
    'apps.enrollments',
    'apps.certificates',
    'apps.marketing',
]

# ==================== MIDDLEWARE ====================
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    # Currency Localization Middleware (MUST be after SessionMiddleware)
    'apps.payments.currency_localization.CurrencyLocalizationMiddleware',
]

# ==================== TEMPLATES & URLS ====================
ROOT_URLCONF = 'lms_project.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [
            BASE_DIR / 'templates',
            BASE_DIR / 'core' / 'templates',
            BASE_DIR / 'apps/instructors/templates',
        ],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'lms_project.wsgi.application'
ASGI_APPLICATION = 'lms_project.asgi.application'

# ==================== DATABASE ====================
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': config('DB_NAME', default='hosiacademylms'),
        'USER': config('DB_USER', default='postgres'),
        'PASSWORD': config('DB_PASSWORD', default='postgres123'),
        'HOST': config('DB_HOST', default='localhost'),
        'PORT': config('DB_PORT', default='5432'),
        'OPTIONS': {
            'options': '-c search_path=public',
            'connect_timeout': 10,
        },
        'CONN_MAX_AGE': 60 if not DEBUG else 0,
    }
}

# ==================== AUTH & INTERNATIONALIZATION ====================
AUTH_USER_MODEL = 'users.User'
AUTHENTICATION_BACKENDS = [
    'apps.users.backends.EmailOrUsernameBackend',
    'django.contrib.auth.backends.ModelBackend',
]

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Africa/Johannesburg'  # SAST
USE_I18N = True
USE_TZ = True

# ==================== STATIC & MEDIA ====================
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']
# Use ManifestStaticFilesStorage but ignore missing source maps for Flutter
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'
# Ignore missing files (like .map files from Flutter)
WHITENOISE_IGNORE_MISSING_FILES = True

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# ==================== REST FRAMEWORK ====================
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.BasicAuthentication',
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',  # ← FIXED: Allows public/unauthenticated access
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer' if DEBUG else 'rest_framework.renderers.JSONRenderer',
    ],
    'DEFAULT_PARSER_CLASSES': [
        'rest_framework.parsers.JSONParser',
        'rest_framework.parsers.FormParser',
        'rest_framework.parsers.MultiPartParser',
    ],
}

# ==================== CORS ====================
CORS_ALLOWED_ORIGINS = config(
    'CORS_ALLOWED_ORIGINS',
    default='http://localhost:3000,http://127.0.0.1:3000,http://localhost:8000,http://127.0.0.1:8000,http://localhost:8001',
    cast=Csv()
)
CORS_ALLOW_CREDENTIALS = True

CORS_ALLOW_HEADERS = [
    'authorization',
    'content-type',
    'user-id',
    'client-type',
    'x-requested-with',
    'socket-io',
    'access-control-allow-origin',
]

CORS_ALLOW_METHODS = [
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'OPTIONS',
]

# ==================== SIMPLE JWT ====================
SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=config('JWT_ACCESS_TOKEN_LIFETIME', default=60, cast=int)),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=config('JWT_REFRESH_TOKEN_LIFETIME', default=1, cast=int)),
    'ROTATE_REFRESH_TOKENS': False,
    'BLACKLIST_AFTER_ROTATION': True,
    'UPDATE_LAST_LOGIN': True,
    'ALGORITHM': 'HS256',
    'SIGNING_KEY': SECRET_KEY,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

# ==================== CELERY SETTINGS ====================
CELERY_BROKER_URL = config('CELERY_BROKER_URL', default='redis://localhost:6379/0')
CELERY_RESULT_BACKEND = config('CELERY_RESULT_BACKEND', default='redis://localhost:6379/0')
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = 'Africa/Johannesburg'  # SAST

# Scheduled tasks (Beat) - autosyncing your AICERTs courses
CELERY_BEAT_SCHEDULE = {
    'daily-raw-aicerts-sync': {
        'task': 'apps.aicerts_courses.tasks.sync_aicerts_courses',
        'schedule': 86400.0,  # Every 24 hours (daily)
        'options': {'expires': 3600},
    },
    'hourly-facilitator-course-sync': {
        'task': 'apps.instructors.tasks.sync_instructors_courses',
        'schedule': 3600.0,  # Every hour
        'options': {'expires': 1800},
    },
    'daily-exchange-rates-fetch': {
        'task': 'apps.payments.tasks.fetch_exchange_rates',
        'schedule': 86400.0,  # Every 24 hours (daily)
        'options': {'expires': 3600},
    },
}

# ==================== INSTRUCTORS CONFIG ====================
INSTRUCTORS_CONFIG = {
    'API_BASE_URL': '/api/v1/instructors/',
    'PERFORMANCE_UPDATE_INTERVAL': 24,
    'AUTO_ASSIGNMENT_ENABLED': config('INSTRUCTORS_AUTO_ASSIGNMENT_ENABLED', default=True, cast=bool),
    'SUGGESTION_ALGORITHM': 'weighted',
    'MIN_RATINGS_FOR_PERFORMANCE': 3,
    'RATING_WEIGHTS': {
        'knowledge': 0.25,
        'communication': 0.20,
        'responsiveness': 0.20,
        'support': 0.20,
        'materials': 0.15,
    },
    'MAX_ASSIGNMENTS_PER_FACILITATOR': 5,
    'ASSIGNMENT_OVERLAP_BUFFER': 7,
    'DEFAULT_ASSIGNMENT_DURATION': 30,
    'SEND_ASSIGNMENT_NOTIFICATIONS': True,
    'SEND_PERFORMANCE_REVIEW_REMINDERS': True,
    'NOTIFICATION_DAYS_BEFORE_REVIEW': 7,
    'ANALYTICS_UPDATE_FREQUENCY': 'daily',
    'KEEP_ANALYTICS_HISTORY': 365,
    'GENERATE_REPORTS': True,
    'SYNC_WITH_AICERTS': True,
    'AICERTS_SYNC_FREQUENCY': 24,
    'ENABLE_ZOOM_INTEGRATION': False,
    'ENABLE_CALENDAR_INTEGRATION': False,
    'DASHBOARD_REFRESH_INTERVAL': 300,
    'SHOW_PERFORMANCE_TRENDS': True,
    'ENABLE_COMPARISON_VIEWS': True,
    'API_RATE_LIMIT': '100/hour',
    'REQUIRE_SSL_FOR_API': not DEBUG,
    'ENABLE_API_KEY_AUTH': True,
    'EXECUTIVE_DASHBOARD_ENABLED': True,
    'EXECUTIVE_DASHBOARD_ROLES': ['admin', 'executive', 'manager'],
    'EXECUTIVE_DASHBOARD_FEATURES': [
        'performance_overview',
        'assignment_analytics',
        'course_utilization',
        'facilitator_comparison',
        'revenue_impact',
    ],
}

COURSE_ASSIGNMENT_CONFIG = {
    'ENABLE_BULK_ASSIGNMENT': True,
    'ENABLE_AUTO_SUGGESTIONS': True,
    'SUGGESTION_ALGORITHM': {
        'specialization_weight': 0.4,
        'performance_weight': 0.3,
        'availability_weight': 0.2,
        'experience_weight': 0.1,
    },
    'DEFAULT_INSTRUCTOR_NAME': 'Takawira',  # Default instructor/facilitator name
    'DEFAULT_INSTRUCTOR_EMAIL': 'takawira@hosiacademy.africa',
    'ALLOW_OVERLAPPING_ASSIGNMENTS': False,
    'MAX_WORKLOAD_PERCENTAGE': 150,
    'MINIMUM_RATING_FOR_ASSIGNMENT': 3.0,
    'REQUIRE_CONTRACT_VALIDITY': True,
}

PERFORMANCE_APPRAISAL_CONFIG = {
    'APPRAISAL_CYCLE': 'quarterly',
    'AUTO_SCHEDULE_APPRAISALS': True,
    'APPRAISAL_REMINDER_DAYS': [30, 15, 7, 3, 1],
    'ALLOW_SELF_ASSESSMENT': True,
    'REQUIRE_REVIEWER_APPROVAL': True,
    'ENABLE_360_FEEDBACK': True,
    'COMPETENCY_WEIGHTS': {
        'knowledge_expertise': 0.15,
        'teaching_effectiveness': 0.20,
        'student_engagement': 0.15,
        'content_development': 0.10,
        'assessment_design': 0.10,
        'communication_skills': 0.10,
        'technology_use': 0.05,
        'collaboration': 0.05,
        'professionalism': 0.10,
    },
}

# ==================== SOCKET.IO CONFIGURATION ====================
SOCKETIO_CONFIG = {
    'ENABLED': config('SOCKETIO_ENABLED', default=True, cast=bool),
    'HOST': config('SOCKETIO_HOST', default='0.0.0.0'),
    'PORT': config('SOCKETIO_PORT', default=8001, cast=int),
    'REDIS_URL': config('SOCKETIO_REDIS_URL', default='redis://localhost:6379/1'),
    'CORS_ALLOWED_ORIGINS': config(
        'SOCKETIO_CORS_ORIGINS', 
        default='http://localhost:3000,http://127.0.0.1:3000,http://localhost:8000,http://127.0.0.1:8000,http://localhost:8001,http://127.0.0.1:8001',
        cast=Csv()
    ),
    'PING_TIMEOUT': config('SOCKETIO_PING_TIMEOUT', default=25, cast=int),
    'PING_INTERVAL': config('SOCKETIO_PING_INTERVAL', default=10, cast=int),
    'MAX_HTTP_BUFFER_SIZE': config('SOCKETIO_MAX_BUFFER', default=104857600, cast=int),
    'ASYNC_MODE': config('SOCKETIO_ASYNC_MODE', default='asgi'),
    'LOGGING': config('SOCKETIO_LOGGING', default=DEBUG, cast=bool),
    'JWT_AUTH_ENABLED': config('SOCKETIO_JWT_AUTH', default=True, cast=bool),
    'HEARTBEAT_INTERVAL': config('SOCKETIO_HEARTBEAT', default=15, cast=int),
}

# Socket.io frontend URL
SOCKETIO_FRONTEND_URL = config('SOCKETIO_FRONTEND_URL', default='http://localhost:3000')

# ==================== LOGGING ====================
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console'],
            'level': 'INFO',
            'propagate': True,
        },
        'apps.instructors': {
            'handlers': ['console'],
            'level': 'DEBUG' if DEBUG else 'INFO',
            'propagate': False,
        },
        'apps.payments': {
            'handlers': ['console'],
            'level': 'DEBUG' if DEBUG else 'INFO',
            'propagate': False,
        },
    },
}

# AICerts Global Settings (Flat structure used by integration services)
AICERTS_COURSE_API_BASE_URL = config('AICERTS_COURSE_API_BASE_URL', default='https://www.aicerts.ai/wp-json/aicerts-api/v1')
AICERTS_SSO_BASE_URL = config('AICERTS_SSO_BASE_URL', default='https://learn.aicerts.io/webservice/rest/server.php')
AICERTS_WSTOKEN = config('AICERTS_WSTOKEN', default='')
AICERTS_PARTNER_ID = config('AICERTS_PARTNER_ID', default='')
AICERTS_REST_FORMAT = config('AICERTS_REST_FORMAT', default='json')
AICERTS_SECRET_KEY = config('AICERTS_SECRET_KEY', default='')
AICERTS_REQUEST_TIMEOUT = config('AICERTS_REQUEST_TIMEOUT', default=30, cast=int)
AICERTS_STUDENT_ROLE_ID = config('AICERTS_STUDENT_ROLE_ID', default=5, cast=int)
AICERTS_AUTO_CREATE_USERS = config('AICERTS_AUTO_CREATE_USERS', default=False, cast=bool)

# ==================== AICERTS API CONFIG ====================
AICERTS_CONFIG = {
    'BASE_URL': AICERTS_COURSE_API_BASE_URL,
    'COURSES_ENDPOINT': '/courses',
    'COURSE_DETAIL_ENDPOINT': '/course/{id}',
    'API_TIMEOUT': AICERTS_REQUEST_TIMEOUT,
    'MAX_RETRIES': config('AICERTS_MAX_RETRIES', default=3, cast=int),
    'RETRY_DELAY': config('AICERTS_RETRY_DELAY', default=1, cast=int),
    'PER_PAGE': config('AICERTS_PER_PAGE', default=100, cast=int),
    'ENABLE_AUTO_SYNC': config('AICERTS_ENABLE_AUTO_SYNC', default=True, cast=bool),
    'SYNC_ON_STARTUP': config('AICERTS_SYNC_ON_STARTUP', default=False, cast=bool),
    'FILTER_SELF_PACED': config('AICERTS_FILTER_SELF_PACED', default=True, cast=bool),
    'INDUSTRY_MAPPING_ENABLED': config('AICERTS_INDUSTRY_MAPPING_ENABLED', default=True, cast=bool),
}

# Industry mapping
INDUSTRY_MAPPING = {
    'Healthcare': ['healthcare', 'health', 'doctor', 'medical', 'pharma', 'nurse'],
    'Mining': ['mining'],
    'Real Estate': ['real estate'],
    'Telecommunications': ['telecommunications', 'telecom'],
    'Finance': ['finance', 'banking', 'accounting', 'investment'],
    'Legal': ['legal', 'law', 'attorney', 'compliance'],
    'Sustainability': ['sustainability', 'environment', 'green'],
    'AI Agent': ['agent', 'automation', 'bot'],
    'Data & Robotics': ['data', 'robotics', 'machine learning', 'ai'],
    'Cloud Computing': ['cloud', 'aws', 'azure', 'google cloud'],
    'Software Development': ['development', 'developer', 'vibe coder', 'programming', 'coding'],
    'AI Ethics': ['ethics', 'responsible ai'],
    'Project Management': ['project management', 'project manager', 'program director', 'scrum'],
    'Product Management': ['product manager', 'product owner'],
    'Education': ['educator', 'learning', 'teacher', 'training'],
    'Executive': ['executive', 'chief', 'officer', 'ceo', 'cto', 'cfo'],
    'Supply Chain': ['supply chain', 'logistics', 'inventory'],
    'Marketing': ['marketing', 'digital marketing', 'seo', 'social media'],
    'Sales': ['sales', 'business development', 'bd'],
    'Customer Service': ['customer service', 'support', 'helpdesk'],
    'Human Resources': ['human resources', 'hr', 'recruitment', 'talent'],
    'Research': ['researcher', 'scientist', 'r&d'],
    'Government': ['government', 'policy maker', 'public sector'],
    'Security': ['security', 'hacker', 'network', 'compliance', 'cybersecurity'],
    'Audio': ['audio', 'sound', 'music'],
    'General AI': [],
}

# ==================== EMAIL CONFIGURATION ====================
# Allow overriding EMAIL_BACKEND from .env (e.g. for testing actual emails in dev)
# Default behavior: Console in DEBUG, SMTP in production
DEFAULT_EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend' if DEBUG else 'django.core.mail.backends.smtp.EmailBackend'
EMAIL_BACKEND = config('EMAIL_BACKEND', default=DEFAULT_EMAIL_BACKEND)

EMAIL_HOST = config('EMAIL_HOST', default='smtp.gmail.com')
EMAIL_PORT = config('EMAIL_PORT', default=587, cast=int)
EMAIL_USE_TLS = config('EMAIL_USE_TLS', default=True, cast=bool)
EMAIL_HOST_USER = config('EMAIL_HOST_USER', default='')
EMAIL_HOST_PASSWORD = config('EMAIL_HOST_PASSWORD', default='')
DEFAULT_FROM_EMAIL = config('DEFAULT_FROM_EMAIL', default='Hosi Academy <noreply@hosiacademy.com>')

# ==================== TWILIO SMS CONFIGURATION ====================
# For payment success SMS notifications
TWILIO_ACCOUNT_SID = config('TWILIO_ACCOUNT_SID', default='')
TWILIO_AUTH_TOKEN = config('TWILIO_AUTH_TOKEN', default='')
TWILIO_PHONE_NUMBER = config('TWILIO_PHONE_NUMBER', default='')
TWILIO_WHATSAPP_NUMBER = config('TWILIO_WHATSAPP_NUMBER', default='')

# ==================== ENVIRONMENT ====================
# Must be defined before Sentry initialization
try:
    ENVIRONMENT = config('ENVIRONMENT', default='development')
except Exception as e:
    logger.warning(f"Failed to load ENVIRONMENT from config: {e}. Defaulting to 'development'")
    ENVIRONMENT = os.environ.get('ENVIRONMENT', 'development')

# ==================== SECURITY (PRODUCTION) ====================
if not DEBUG:
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
    SECURE_SSL_REDIRECT = False
else:
    CORS_ALLOW_ALL_ORIGINS = True
    CORS_ALLOW_CREDENTIALS = True

# ==================== FILE UPLOAD & MEDIA ====================
FILE_UPLOAD_MAX_MEMORY_SIZE = 10485760  # 10MB
DATA_UPLOAD_MAX_MEMORY_SIZE = 10485760

INSTRUCTOR_MEDIA_ROOT = MEDIA_ROOT / 'instructors'
INSTRUCTOR_MEDIA_URL = MEDIA_URL + 'instructors/'

# Create logs directory
log_dir = BASE_DIR / 'logs'
if not os.path.exists(log_dir):
    os.makedirs(log_dir)

# ==================== ENVIRONMENT INFO ====================
# ENVIRONMENT already defined above for Sentry initialization

if DEBUG:
    print(f"\n{'='*60}")
    print(f"Environment: {ENVIRONMENT}")
    print(f"Debug: {DEBUG}")
    print(f"Instructors Module: ENABLED")
    print(f"Auto Assignment: {INSTRUCTORS_CONFIG['AUTO_ASSIGNMENT_ENABLED']}")
    print(f"AICerts Sync: {AICERTS_CONFIG['ENABLE_AUTO_SYNC']}")
    print(f"Socket.io Enabled: {SOCKETIO_CONFIG['ENABLED']}")
    print(f"Socket.io Port: {SOCKETIO_CONFIG['PORT']}")
    print(f"{'='*60}\n")

# ==================== PAYMENT PROVIDER CONFIGURATIONS ====================
# Flutterwave
FLUTTERWAVE_PUBLIC_KEY = config('FLUTTERWAVE_PUBLIC_KEY', default='')
FLUTTERWAVE_SECRET_KEY = config('FLUTTERWAVE_SECRET_KEY', default='')
FLUTTERWAVE_WEBHOOK_SECRET = config('FLUTTERWAVE_WEBHOOK_SECRET', default='')
FLUTTERWAVE_ENCRYPTION_KEY = config('FLUTTERWAVE_ENCRYPTION_KEY', default='')
FLUTTERWAVE_SANDBOX = config('FLUTTERWAVE_SANDBOX', default=True, cast=bool)
# Flutterwave OAuth 2.0 Credentials
FLUTTERWAVE_CLIENT_ID = config('FLUTTERWAVE_CLIENT_ID', default='')
FLUTTERWAVE_CLIENT_SECRET = config('FLUTTERWAVE_CLIENT_SECRET', default='')

# Paystack
PAYSTACK_PUBLIC_KEY = config('PAYSTACK_PUBLIC_KEY', default='')
PAYSTACK_SECRET_KEY = config('PAYSTACK_SECRET_KEY', default='')
PAYSTACK_WEBHOOK_SECRET = config('PAYSTACK_WEBHOOK_SECRET', default='')
PAYSTACK_SANDBOX = config('PAYSTACK_SANDBOX', default=True, cast=bool)

# Yoco
YOCO_PUBLIC_KEY = config('YOCO_PUBLIC_KEY', default='')
YOCO_SECRET_KEY = config('YOCO_SECRET_KEY', default='')
YOCO_SANDBOX = config('YOCO_SANDBOX', default=True, cast=bool)

# Paynow (Zimbabwe)
PAYNOW_INTEGRATION_ID = config('PAYNOW_INTEGRATION_ID', default='')
PAYNOW_INTEGRATION_KEY = config('PAYNOW_INTEGRATION_KEY', default='')
PAYNOW_SANDBOX = config('PAYNOW_SANDBOX', default=True, cast=bool)

# SmatPay (Zimbabwe)
SMATPAY_MERCHANT_ID = config('SMATPAY_MERCHANT_ID', default='')
SMATPAY_MERCHANT_API_KEY = config('SMATPAY_API_KEY', default='3X0NgDdl4J3xlcaQ9SHRz')
SMATPAY_MERCHANT_KEY = config('SMATPAY_MERCHANT_KEY', default='')
SMATPAY_PROFILE_ID = config('SMATPAY_PROFILE_ID', default='')

# M-Pesa (Kenya)
MPESA_CONSUMER_KEY = config('MPESA_CONSUMER_KEY', default='')
MPESA_CONSUMER_SECRET = config('MPESA_CONSUMER_SECRET', default='')
MPESA_PASSKEY = config('MPESA_PASSKEY', default='')
MPESA_ENVIRONMENT = config('MPESA_ENVIRONMENT', default='sandbox')
MPESA_BUSINESS_SHORTCODE = config('MPESA_BUSINESS_SHORTCODE', default='174379')
MPESA_INITIATOR_NAME = config('MPESA_INITIATOR_NAME', default='testapi')
MPESA_SECURITY_CREDENTIAL = config('MPESA_SECURITY_CREDENTIAL', default='')
MPESA_CALLBACK_URL = config('MPESA_CALLBACK_URL', default='')
MPESA_SANDBOX = config('MPESA_SANDBOX', default=True, cast=bool)

# Vodacom M-Pesa (Tanzania, Mozambique, DRC, Lesotho)
VODACOM_MPESA_SANDBOX = config('VODACOM_MPESA_SANDBOX', default=True, cast=bool)
VODACOM_MPESA_TZ_CONSUMER_KEY = config('VODACOM_MPESA_TZ_CONSUMER_KEY', default='')
VODACOM_MPESA_TZ_CONSUMER_SECRET = config('VODACOM_MPESA_TZ_CONSUMER_SECRET', default='')
VODACOM_MPESA_TZ_SHORTCODE = config('VODACOM_MPESA_TZ_SHORTCODE', default='174379')
VODACOM_MPESA_TZ_PASSKEY = config('VODACOM_MPESA_TZ_PASSKEY', default='')
VODACOM_MPESA_TZ_INITIATOR_NAME = config('VODACOM_MPESA_TZ_INITIATOR_NAME', default='testapi')
VODACOM_MPESA_TZ_SECURITY_CREDENTIAL = config('VODACOM_MPESA_TZ_SECURITY_CREDENTIAL', default='')
VODACOM_MPESA_TZ_CALLBACK_URL = config('VODACOM_MPESA_TZ_CALLBACK_URL', default='')
# Mozambique
VODACOM_MPESA_MZ_CONSUMER_KEY = config('VODACOM_MPESA_MZ_CONSUMER_KEY', default='')
VODACOM_MPESA_MZ_CONSUMER_SECRET = config('VODACOM_MPESA_MZ_CONSUMER_SECRET', default='')
VODACOM_MPESA_MZ_SHORTCODE = config('VODACOM_MPESA_MZ_SHORTCODE', default='174379')
VODACOM_MPESA_MZ_PASSKEY = config('VODACOM_MPESA_MZ_PASSKEY', default='')
VODACOM_MPESA_MZ_CALLBACK_URL = config('VODACOM_MPESA_MZ_CALLBACK_URL', default='')
# DRC
VODACOM_MPESA_CD_CONSUMER_KEY = config('VODACOM_MPESA_CD_CONSUMER_KEY', default='')
VODACOM_MPESA_CD_CONSUMER_SECRET = config('VODACOM_MPESA_CD_CONSUMER_SECRET', default='')
VODACOM_MPESA_CD_SHORTCODE = config('VODACOM_MPESA_CD_SHORTCODE', default='174379')
VODACOM_MPESA_CD_PASSKEY = config('VODACOM_MPESA_CD_PASSKEY', default='')
VODACOM_MPESA_CD_CALLBACK_URL = config('VODACOM_MPESA_CD_CALLBACK_URL', default='')
# Lesotho
VODACOM_MPESA_LS_CONSUMER_KEY = config('VODACOM_MPESA_LS_CONSUMER_KEY', default='')
VODACOM_MPESA_LS_CONSUMER_SECRET = config('VODACOM_MPESA_LS_CONSUMER_SECRET', default='')
VODACOM_MPESA_LS_SHORTCODE = config('VODACOM_MPESA_LS_SHORTCODE', default='174379')
VODACOM_MPESA_LS_PASSKEY = config('VODACOM_MPESA_LS_PASSKEY', default='')
VODACOM_MPESA_LS_CALLBACK_URL = config('VODACOM_MPESA_LS_CALLBACK_URL', default='')

# Vodafone Cash (Egypt)
VODAFONE_CASH_SANDBOX = config('VODAFONE_CASH_SANDBOX', default=True, cast=bool)
VODAFONE_CASH_CLIENT_ID = config('VODAFONE_CASH_CLIENT_ID', default='')
VODAFONE_CASH_CLIENT_SECRET = config('VODAFONE_CASH_CLIENT_SECRET', default='')
VODAFONE_CASH_MERCHANT_ID = config('VODAFONE_CASH_MERCHANT_ID', default='')
VODAFONE_CASH_CALLBACK_URL = config('VODAFONE_CASH_CALLBACK_URL', default='')

# Stripe
STRIPE_PUBLIC_KEY = config('STRIPE_PUBLIC_KEY', default='')
STRIPE_SECRET_KEY = config('STRIPE_SECRET_KEY', default='')
STRIPE_WEBHOOK_SECRET = config('STRIPE_WEBHOOK_SECRET', default='')
STRIPE_SANDBOX = config('STRIPE_SANDBOX', default=True, cast=bool)

# PayPal
PAYPAL_CLIENT_ID = config('PAYPAL_CLIENT_ID', default='')
PAYPAL_CLIENT_SECRET = config('PAYPAL_CLIENT_SECRET', default='')
PAYPAL_MODE = config('PAYPAL_MODE', default='sandbox')

# Ozow (Instant EFT - South Africa)
OZOW_SITE_CODE = config('OZOW_SITE_CODE', default='')
OZOW_PRIVATE_KEY = config('OZOW_PRIVATE_KEY', default='')
OZOW_API_KEY = config('OZOW_API_KEY', default='')
OZOW_SANDBOX = config('OZOW_SANDBOX', default=True, cast=bool)

# PayFast (South Africa - supports EFT)
PAYFAST_MERCHANT_ID = config('PAYFAST_MERCHANT_ID', default='')
PAYFAST_MERCHANT_KEY = config('PAYFAST_MERCHANT_KEY', default='')
PAYFAST_PASSPHRASE = config('PAYFAST_PASSPHRASE', default='')
PAYFAST_SANDBOX = config('PAYFAST_SANDBOX', default=True, cast=bool)

# Company Bank Details (for EFT/Bank Transfer payments)
COMPANY_BANK_NAME = config('COMPANY_BANK_NAME', default='FNB Business')
COMPANY_ACCOUNT_NUMBER = config('COMPANY_ACCOUNT_NUMBER', default='123456789')
COMPANY_ACCOUNT_NAME = config('COMPANY_ACCOUNT_NAME', default='HosiTech LMS (Pty) Ltd')
COMPANY_BRANCH_CODE = config('COMPANY_BRANCH_CODE', default='250655')
COMPANY_ACCOUNT_TYPE = config('COMPANY_ACCOUNT_TYPE', default='Current Account')
COMPANY_BANK_ADDRESS = config('COMPANY_BANK_ADDRESS', default='')
COMPANY_SWIFT_CODE = config('COMPANY_SWIFT_CODE', default='FIRNZAJJ')
# ==================== GEOLOCATION ====================
# GeoIP2 database path for IP-based country detection
# Download GeoLite2 database from: https://dev.maxmind.com/geoip/geolite2-free-geolocation-data
# Or use: wget https://git.io/GeoLite2-Country.mmdb
GEOIP_PATH = config('GEOIP_PATH', default=os.path.join(BASE_DIR, 'GeoLite2-Country.mmdb'))
GEOIP_ENABLED = config('GEOIP_ENABLED', default='True', cast=bool)  # ENABLED for proper country detection

# Default country for fallback (when IP detection fails)
DEFAULT_COUNTRY_CODE = config('DEFAULT_COUNTRY_CODE', default='ZA')  # Changed to South Africa

# African countries list for payment provider filtering
AFRICAN_COUNTRY_CODES = [
    'ZW', 'KE', 'NG', 'ZA', 'GH', 'EG', 'TZ', 'UG', 'ET', 'RW',
    'ZM', 'SN', 'CI', 'CM', 'MA', 'DZ', 'TN', 'MZ', 'BW', 'NA',
    'AO', 'MW', 'BJ', 'BF', 'ML', 'NE', 'TG', 'GA', 'CG', 'CD',
    'TD', 'CF', 'GN', 'SL', 'LR', 'MR', 'GM', 'GW', 'CV', 'ST',
    'GQ', 'DJ', 'SO', 'ER', 'SS', 'SD', 'LY', 'EH'
]

