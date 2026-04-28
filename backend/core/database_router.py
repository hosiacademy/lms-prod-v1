"""
Multi-tenant Database Router
Handles routing of database operations to appropriate databases based on tenant context.
"""

import logging
from django.conf import settings
from django.core.cache import cache

logger = logging.getLogger(__name__)


class DatabaseHealthChecker:
    """
    Checks and tracks database health status using cache.
    """
    HEALTH_CACHE_KEY = "db_health_{}"
    TIMEOUT = 60  # 1 minute

    @classmethod
    def is_healthy(cls, db_alias):
        """Check if a database is currently marked as healthy"""
        # Check cache first
        status = cache.get(cls.HEALTH_CACHE_KEY.format(db_alias))
        if status is not None:
            return status

        # If not in cache, perform a quick check
        return cls.check(db_alias)

    @classmethod
    def check(cls, db_alias):
        """Perform a connection check and update cache"""
        from django.db import connections
        from django.db.utils import OperationalError
        
        try:
            connection = connections[db_alias]
            connection.ensure_connection()
            with connection.cursor() as cursor:
                cursor.execute("SELECT 1")
            
            cls._mark_healthy(db_alias)
            return True
        except (OperationalError, Exception) as e:
            logger.error(f"Database health check failed for '{db_alias}': {str(e)}")
            cls._mark_unhealthy(db_alias)
            return False

    @classmethod
    def _mark_healthy(cls, db_alias):
        """Mark database as healthy in cache"""
        cache.set(cls.HEALTH_CACHE_KEY.format(db_alias), True, cls.TIMEOUT)

    @classmethod
    def _mark_unhealthy(cls, db_alias):
        """Mark database as unhealthy in cache"""
        cache.set(cls.HEALTH_CACHE_KEY.format(db_alias), False, cls.TIMEOUT)


class MultiTenantRouter:
    """
    A router to control all database operations on models for different tenants.
    """

    def db_for_read(self, model, **hints):
        """
        Route read operations to the appropriate tenant database.
        """
        if self._is_tenant_model(model):
            db = self._get_tenant_db(**hints)
            if db:
                return db
        return settings.DEFAULT_DB_ALIAS

    def db_for_write(self, model, **hints):
        """
        Route write operations to the appropriate tenant database.
        """
        if self._is_tenant_model(model):
            db = self._get_tenant_db(**hints)
            if db:
                return db
        return settings.DEFAULT_DB_ALIAS

    def allow_relation(self, obj1, obj2, **hints):
        """
        Allow relations if both models are tenant-aware or both are not.
        """
        if self._is_tenant_model(obj1.__class__) and self._is_tenant_model(obj2.__class__):
            return True
        if not self._is_tenant_model(obj1.__class__) and not self._is_tenant_model(obj2.__class__):
            return True
        return None

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        """
        Make sure migrations are applied to all necessary databases.
        """
        if app_label in settings.TENANT_APPS:
            # Migrate tenant apps to all tenant databases
            if hasattr(settings, 'TENANT_DATABASES') and db in settings.TENANT_DATABASES:
                return True
            # Also allow migration to default database for initial setup
            if db == settings.DEFAULT_DB_ALIAS:
                return True
            return False
        # For non-tenant apps, only migrate to default database
        return db == settings.DEFAULT_DB_ALIAS

    @staticmethod
    def _is_tenant_model(model):
        """
        Check if a model is tenant-aware (has tenant_id field or is in TENANT_APPS).
        """
        if hasattr(model, '_meta'):
            app_label = model._meta.app_label
            if app_label in getattr(settings, 'TENANT_APPS', []):
                return True
            # Check if model has tenant_id field
            try:
                model._meta.get_field('tenant_id')
                return True
            except Exception:
                pass
        return False

    @staticmethod
    def _get_tenant_db(**hints):
        """
        Determine which database to use based on hints and tenant context.
        """
        # Check if tenant_id is provided in hints
        if 'tenant_id' in hints:
            tenant_id = hints['tenant_id']
            return MultiTenantRouter._get_db_for_tenant(tenant_id)

        # Try to get tenant from cache (set by middleware)
        from django.core.threadlocals import get_current_request
        try:
            request = get_current_request()
            if hasattr(request, 'tenant_id') and request.tenant_id:
                return MultiTenantRouter._get_db_for_tenant(request.tenant_id)
        except Exception:
            pass

        return None

    @staticmethod
    def _get_db_for_tenant(tenant_id):
        """
        Get the database alias for a specific tenant.
        """
        if not tenant_id:
            return None

        # Check cache first
        cache_key = f"tenant_db_{tenant_id}"
        db_alias = cache.get(cache_key)
        if db_alias:
            return db_alias

        # Get from settings
        if hasattr(settings, 'TENANT_DATABASES'):
            db_alias = settings.TENANT_DATABASES.get(tenant_id)
            if db_alias:
                # Cache for 1 hour
                cache.set(cache_key, db_alias, 3600)
                return db_alias

        return None


class TenantAwareQuerySet:
    """
    Mixin for querysets that need tenant awareness.
    """

    def for_tenant(self, tenant_id):
        """
        Filter queryset for a specific tenant.
        """
        if hasattr(self.model, 'tenant_id'):
            return self.filter(tenant_id=tenant_id)
        return self

    def all_tenants(self):
        """
        Get all objects across all tenants (use with caution).
        """
        return self.all().using(settings.DEFAULT_DB_ALIAS)


class TenantAwareManager:
    """
    Mixin for managers that need tenant awareness.
    """

    def for_tenant(self, tenant_id):
        """
        Get queryset for a specific tenant.
        """
        qs = self.get_queryset()
        if hasattr(self.model, 'tenant_id'):
            return qs.filter(tenant_id=tenant_id)
        return qs

    def all_tenants(self):
        """
        Get all objects across all tenants (use with caution).
        """
        return self.get_queryset().all().using(settings.DEFAULT_DB_ALIAS)
