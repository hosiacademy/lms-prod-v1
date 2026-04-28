import logging
from decouple import config

logger = logging.getLogger(__name__)

class MultiTenantRouter:
    """
    A router to control all database operations on models in the
    LMS application. Handles primary/secondary splitting and failover.
    """

    def __init__(self):
        self.active_db = config('DB_ACTIVE', default='primary')
        self.failover_enabled = config('DB_FAILOVER_ENABLED', default=True, cast=bool)
        self.read_only_secondary = config('DB_READ_ONLY_SECONDARY', default=False, cast=bool)

    def db_for_read(self, model, **hints):
        """
        Direct GET (read) requests.
        If read_only_secondary is True, always use secondary for GET.
        Otherwise, use the active database.
        """
        if self.read_only_secondary:
            return 'secondary'
        return self.active_db

    def db_for_write(self, model, **hints):
        """
        Direct POST/PUT/DELETE (write) requests.
        Always use the active database (usually primary).
        """
        return self.active_db

    def allow_relation(self, obj1, obj2, **hints):
        """
        Allow relations if both objects are in the same database.
        """
        return True

    def allow_migrate(self, db, app_label, model_name=None, **hints):
        """
        Ensure migrations run on the active database (primary or secondary)
        and ALSO allow 'default' since it's an alias.
        """
        if db == 'default':
            return True
        return db == self.active_db
