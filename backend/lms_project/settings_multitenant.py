"""
Multi-tenant settings configuration
This file shows how to configure Django for multi-tenant database setup
Add these settings to your main settings.py or create separate settings file
"""

import os
from pathlib import Path

# Load environment variables from .env.multitenant
def load_multitenant_env():
    """Load multi-tenant environment configuration"""
    env_path = Path(__file__).resolve().parent.parent / '.env.multitenant'
    if env_path.exists():
        with open(env_path) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#'):
                    key, value = line.split('=', 1)
                    os.environ.setdefault(key.strip(), value.strip())

load_multitenant_env()

# =============================================================================
# MULTI-DATABASE CONFIGURATION
# =============================================================================

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_PRIMARY_NAME', 'hosiacademylms'),
        'USER': os.getenv('DB_PRIMARY_USER', 'postgres'),
        'PASSWORD': os.getenv('DB_PRIMARY_PASSWORD', 'postgres'),
        'HOST': os.getenv('DB_PRIMARY_HOST', 'localhost'),
        'PORT': os.getenv('DB_PRIMARY_PORT', '5432'),
        'OPTIONS': {
            'connect_timeout': int(os.getenv('DB_HEALTH_CHECK_TIMEOUT', 5)),
        },
        'CONN_MAX_AGE': int(os.getenv('DB_PRIMARY_CONN_MAX_AGE', 600)),
    },
    'supabase': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_SECONDARY_NAME', 'postgres'),
        'USER': os.getenv('DB_SECONDARY_USER', 'postgres'),
        'PASSWORD': os.getenv('DB_SECONDARY_PASSWORD', ''),
        'HOST': os.getenv('DB_SECONDARY_HOST', ''),
        'PORT': os.getenv('DB_SECONDARY_PORT', '5432'),
        'OPTIONS': {
            'sslmode': os.getenv('DB_SECONDARY_SSLMODE', 'require'),
            'connect_timeout': int(os.getenv('DB_HEALTH_CHECK_TIMEOUT', 5)),
        },
        'CONN_MAX_AGE': int(os.getenv('DB_SECONDARY_CONN_MAX_AGE', 600)),
    },
}

# Database router for multi-tenant logic
DATABASE_ROUTERS = ['core.database_router.MultiTenantRouter']

# =============================================================================
# MULTI-TENANT SETTINGS
# =============================================================================

# Which database is active
DB_ACTIVE = os.getenv('DB_ACTIVE', 'primary')

# Enable automatic failover
DB_FAILOVER_ENABLED = os.getenv('DB_FAILOVER_ENABLED', 'true').lower() == 'true'

# Health check configuration
DB_HEALTH_CHECK_INTERVAL = int(os.getenv('DB_HEALTH_CHECK_INTERVAL', 30))
DB_HEALTH_CHECK_TIMEOUT = int(os.getenv('DB_HEALTH_CHECK_TIMEOUT', 5))
DB_FAILOVER_THRESHOLD = int(os.getenv('DB_FAILOVER_THRESHOLD', 3))

# Sync configuration
DB_SYNC_ENABLED = os.getenv('DB_SYNC_ENABLED', 'true').lower() == 'true'
DB_SYNC_MODE = os.getenv('DB_SYNC_MODE', 'async')
DB_SYNC_INTERVAL = int(os.getenv('DB_SYNC_INTERVAL', 60))
DB_SYNC_TABLES = os.getenv('DB_SYNC_TABLES', '*').split(',')
DB_SYNC_EXCLUDE_TABLES = os.getenv('DB_SYNC_EXCLUDE_TABLES', 'django_migrations,django_session,django_admin_log').split(',')

# =============================================================================
# SUPABASE CONFIGURATION
# =============================================================================

SUPABASE_URL = os.getenv('SUPABASE_URL', 'https://zdfdazvblpblhafnkwrm.supabase.co')
SUPABASE_PUBLISHABLE_KEY = os.getenv('SUPABASE_PUBLISHABLE_KEY', 'sb_publishable_txRJ3GCbWn-_eBT_R9NBXg_uuHcO8ZD')
SUPABASE_SERVICE_ROLE_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY', '')
SUPABASE_PROJECT_ID = os.getenv('SUPABASE_PROJECT_ID', '')
SUPABASE_JWT_SECRET = os.getenv('SUPABASE_JWT_SECRET', '')

# =============================================================================
# MIDDLEWARE (Add these to your MIDDLEWARE list)
# =============================================================================

SYNC_MIDDLEWARE = [
    'core.sync_middleware.MultiTenantSyncMiddleware',
    'core.sync_middleware.DatabaseHealthCheckMiddleware',
    'core.sync_middleware.FailoverMiddleware',
]

# Add to your existing MIDDLEWARE:
# MIDDLEWARE = [
#     ...
#     'core.sync_middleware.MultiTenantSyncMiddleware',
#     'core.sync_middleware.DatabaseHealthCheckMiddleware',
#     'core.sync_middleware.FailoverMiddleware',
#     ...
# ]

# =============================================================================
# LOGGING CONFIGURATION
# =============================================================================

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'sync': {
            'level': os.getenv('DB_SYNC_LOG_LEVEL', 'INFO'),
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': 'logs/db_sync.log',
            'maxBytes': 1024 * 1024 * 10,  # 10MB
            'backupCount': 5,
            'formatter': 'verbose',
        },
        'failover': {
            'level': os.getenv('DB_FAILOVER_LOG_LEVEL', 'INFO'),
            'class': 'logging.handlers.RotatingFileHandler',
            'filename': 'logs/db_failover.log',
            'maxBytes': 1024 * 1024 * 10,  # 10MB
            'backupCount': 5,
            'formatter': 'verbose',
        },
    },
    'loggers': {
        'core.db_sync_service': {
            'handlers': ['sync'],
            'level': os.getenv('DB_SYNC_LOG_LEVEL', 'INFO'),
            'propagate': False,
        },
        'core.database_router': {
            'handlers': ['failover'],
            'level': os.getenv('DB_FAILOVER_LOG_LEVEL', 'INFO'),
            'propagate': False,
        },
    },
}

# =============================================================================
# WEBHOOK CONFIGURATION
# =============================================================================

WEBHOOK_SECRET = os.getenv('WEBHOOK_SECRET', 'your-secret-key-change-this')
WEBHOOK_PORT = int(os.getenv('WEBHOOK_PORT', 8002))
SUPABASE_WEBHOOK_URL = os.getenv('SUPABASE_WEBHOOK_URL', 'http://backend:8000/api/webhooks/supabase/')

print("""
=============================================================================
MULTI-TENANT DATABASE CONFIGURATION LOADED
=============================================================================
Primary Database: {primary_host}:{primary_port}/{primary_name}
Secondary Database (Supabase): {secondary_host}:{secondary_port}/{secondary_name}
Failover Enabled: {failover}
Sync Enabled: {sync}
Sync Mode: {sync_mode}
Sync Interval: {sync_interval}s
=============================================================================
""".format(
    primary_host=os.getenv('DB_PRIMARY_HOST', 'localhost'),
    primary_port=os.getenv('DB_PRIMARY_PORT', '5432'),
    primary_name=os.getenv('DB_PRIMARY_NAME', 'hosiacademylms'),
    secondary_host=os.getenv('DB_SECONDARY_HOST', 'N/A'),
    secondary_port=os.getenv('DB_SECONDARY_PORT', '5432'),
    secondary_name=os.getenv('DB_SECONDARY_NAME', 'postgres'),
    failover=DB_FAILOVER_ENABLED,
    sync=DB_SYNC_ENABLED,
    sync_mode=DB_SYNC_MODE,
    sync_interval=DB_SYNC_INTERVAL,
))
