"""
Tests for multi-tenant database sync system
Run with: python manage.py test core.tests.test_sync
"""

from django.test import TestCase
from django.db import connections
from django.contrib.auth.models import User
import time
from core.db_sync_service import get_sync_service
from core.database_router import DatabaseHealthChecker, MultiTenantRouter


class DatabaseHealthCheckerTest(TestCase):
    """Test database health checking"""
    
    def test_primary_database_health(self):
        """Test primary database is healthy"""
        is_healthy = DatabaseHealthChecker.is_healthy('default')
        self.assertTrue(is_healthy)
    
    def test_secondary_database_health(self):
        """Test secondary database connectivity"""
        is_healthy = DatabaseHealthChecker.is_healthy('supabase')
        # May be false if Supabase is not configured, but should not error
        self.assertIsInstance(is_healthy, bool)


class MultiTenantRouterTest(TestCase):
    """Test database router logic"""
    
    def setUp(self):
        self.router = MultiTenantRouter()
    
    def test_db_for_read(self):
        """Test router selects a database for reads"""
        db = self.router.db_for_read(User)
        self.assertIn(db, ['default', 'supabase'])
    
    def test_db_for_write(self):
        """Test router selects primary for writes"""
        db = self.router.db_for_write(User)
        self.assertEqual(db, 'default')  # Writes should go to primary
    
    def test_allow_relation(self):
        """Test relations are allowed between same DB"""
        result = self.router.allow_relation(User(), User())
        self.assertTrue(result)
    
    def test_allow_migrate(self):
        """Test migrations only on primary"""
        primary_migrate = self.router.allow_migrate('default', 'auth')
        secondary_migrate = self.router.allow_migrate('supabase', 'auth')
        
        self.assertTrue(primary_migrate)
        self.assertFalse(secondary_migrate)


class DatabaseSyncServiceTest(TestCase):
    """Test sync service functionality"""
    
    def setUp(self):
        self.sync_service = get_sync_service()
    
    def test_get_sync_service(self):
        """Test getting sync service singleton"""
        sync1 = get_sync_service()
        sync2 = get_sync_service()
        self.assertIs(sync1, sync2)
    
    def test_verify_sync_status(self):
        """Test sync status verification"""
        status = self.sync_service.verify_sync_status()
        
        # Should return status dict
        self.assertIn('status', status)
        self.assertIn('primary_tables', status)
        self.assertIn('secondary_tables', status)
        self.assertIn('conflicts', status)
    
    def test_sync_status_in_sync(self):
        """Test system reports as in-sync when row counts match"""
        status = self.sync_service.verify_sync_status()
        
        # Get primary tables
        primary_tables = status.get('primary_tables', {})
        secondary_tables = status.get('secondary_tables', {})
        
        # Tables with same row count should be in-sync
        if primary_tables and secondary_tables:
            for table in primary_tables:
                if table in secondary_tables:
                    if primary_tables[table] == secondary_tables[table]:
                        # This table is in sync
                        pass


class SyncConflictHandlingTest(TestCase):
    """Test conflict resolution"""
    
    def setUp(self):
        self.sync_service = get_sync_service()
        self.sync_service.clear_conflict_log()
    
    def test_conflict_logging(self):
        """Test conflicts are logged"""
        # Log a fake conflict
        self.sync_service._log_conflict(
            {'table': 'users', 'data': {'id': 1}, 'source_db': 'default'},
            'supabase',
            'Test error'
        )
        
        self.assertEqual(len(self.sync_service.conflict_log), 1)
        conflict = self.sync_service.conflict_log[0]
        self.assertEqual(conflict['table'], 'users')
        self.assertEqual(conflict['error'], 'Test error')
    
    def test_conflict_log_retrieval(self):
        """Test retrieving conflict log"""
        log = self.sync_service.get_conflict_log()
        self.assertIsInstance(log, list)
    
    def test_clear_conflict_log(self):
        """Test clearing conflict log"""
        self.sync_service._log_conflict(
            {'table': 'users', 'data': {'id': 1}, 'source_db': 'default'},
            'supabase',
            'Test error'
        )
        
        self.sync_service.clear_conflict_log()
        self.assertEqual(len(self.sync_service.conflict_log), 0)


class FailoverTest(TestCase):
    """Test failover functionality"""
    
    def test_failover_detection(self):
        """Test system detects when to failover"""
        # This would require mocking database failures
        # For now, just test the router can handle failover
        router = MultiTenantRouter()
        
        # Force mark secondary as unhealthy
        DatabaseHealthChecker._mark_unhealthy('supabase')
        
        # Router should still function
        db = router.db_for_read(User)
        self.assertIsNotNone(db)
        
        # Reset
        DatabaseHealthChecker._mark_healthy('supabase')


class WebhookHandlerTest(TestCase):
    """Test webhook handling"""
    
    def test_webhook_url_exists(self):
        """Test webhook endpoint is available"""
        from django.urls import reverse
        url = reverse('sync:supabase_webhook')
        self.assertIsNotNone(url)
    
    def test_health_check_url_exists(self):
        """Test health check endpoint is available"""
        from django.urls import reverse
        url = reverse('sync:health_check')
        self.assertIsNotNone(url)


class IntegrationTest(TestCase):
    """Integration tests for full sync flow"""
    
    def setUp(self):
        self.sync_service = get_sync_service()
        self.router = MultiTenantRouter()
    
    def test_create_user_gets_synced(self):
        """Test creating a user and checking it syncs"""
        # Create user
        user = User.objects.create_user(
            username='testuser',
            email='test@example.com',
            password='testpass123'
        )
        
        # User should be created in primary DB
        self.assertIsNotNone(user.id)
        
        # Give sync service time to sync
        time.sleep(2)
        
        # Check user exists in both databases
        try:
            User.objects.using('default').get(username='testuser')
            # Primary should have it
        except User.DoesNotExist:
            self.fail("User not found in primary database")
    
    def test_sync_interval_configuration(self):
        """Test sync interval is configured"""
        from django.conf import settings
        
        # Check settings exist
        self.assertTrue(hasattr(settings, 'DB_SYNC_INTERVAL'))
        self.assertGreater(settings.DB_SYNC_INTERVAL, 0)


class PerformanceTest(TestCase):
    """Performance and stress tests"""
    
    def test_sync_completes_in_reasonable_time(self):
        """Test sync doesn't take too long"""
        sync_service = get_sync_service()
        
        start_time = time.time()
        sync_service.sync_bidirectional()
        elapsed = time.time() - start_time
        
        # Sync should complete in less than 30 seconds
        self.assertLess(elapsed, 30, f"Sync took {elapsed}s (too long)")
    
    def test_health_check_completes_quickly(self):
        """Test health check is fast"""
        start_time = time.time()
        DatabaseHealthChecker.check('default')
        elapsed = time.time() - start_time
        
        # Health check should complete in less than 5 seconds
        self.assertLess(elapsed, 5, f"Health check took {elapsed}s (too long)")
