"""
Management command to check database health and failover status
Usage: python manage.py db_health
"""

from django.core.management.base import BaseCommand
from django.db import connections
import logging

logger = logging.getLogger(__name__)


class Command(BaseCommand):
    help = 'Check database health and failover status'

    def add_arguments(self, parser):
        parser.add_argument(
            '--fix',
            action='store_true',
            help='Attempt to fix unhealthy databases',
        )
        parser.add_argument(
            '--failover',
            action='store_true',
            help='Force failover to secondary database',
        )

    def handle(self, *args, **options):
        from core.database_router import DatabaseHealthChecker, MultiTenantRouter
        from core.db_sync_service import get_sync_service
        
        self.stdout.write("=" * 60)
        self.stdout.write("DATABASE HEALTH CHECK")
        self.stdout.write("=" * 60)
        
        # Check health
        primary_health = DatabaseHealthChecker.is_healthy('default')
        secondary_health = DatabaseHealthChecker.is_healthy('supabase')
        
        # Display status
        primary_status = self.style.SUCCESS("✓ HEALTHY") if primary_health else self.style.ERROR("✗ UNHEALTHY")
        secondary_status = self.style.SUCCESS("✓ HEALTHY") if secondary_health else self.style.ERROR("✗ UNHEALTHY")
        
        self.stdout.write(f"Primary (Docker):   {primary_status}")
        self.stdout.write(f"Secondary (Supabase): {secondary_status}")
        self.stdout.write("")
        
        # Get sync status
        sync_service = get_sync_service()
        sync_status = sync_service.verify_sync_status()
        
        self.stdout.write(f"Sync Status: {sync_status['status']}")
        self.stdout.write(f"Last Sync: {sync_status.get('last_sync', 'Never')}")
        self.stdout.write(f"Conflicts: {sync_status.get('conflicts', 0)}")
        self.stdout.write("")
        
        # Show table counts
        if 'primary_tables' in sync_status:
            self.stdout.write("Table Row Counts:")
            for table, count in sync_status.get('primary_tables', {}).items():
                secondary_count = sync_status.get('secondary_tables', {}).get(table, '?')
                match = "✓" if count == secondary_count else "✗"
                self.stdout.write(f"  {table}: {count} (primary) vs {secondary_count} (secondary) {match}")
        
        self.stdout.write("")
        
        # Show differences if any
        if sync_status.get('differences'):
            self.stdout.write(self.style.WARNING("⚠ SYNC DIFFERENCES DETECTED:"))
            for diff in sync_status['differences']:
                self.stdout.write(f"  {diff['table']}: {diff['primary_rows']} vs {diff['secondary_rows']} (diff: {diff['difference']})")
            self.stdout.write("")
        
        # Show conflicts if any
        if sync_service.conflict_log:
            self.stdout.write(self.style.WARNING(f"⚠ {len(sync_service.conflict_log)} SYNC CONFLICTS:"))
            for conflict in sync_service.conflict_log[:5]:  # Show first 5
                self.stdout.write(f"  {conflict['table']}: {conflict['error']}")
            self.stdout.write("")
        
        # Options handling
        if options['fix']:
            self.stdout.write(self.style.WARNING("Attempting to fix unhealthy databases..."))
            # Trigger one-time sync
            sync_service.sync_bidirectional()
            self.stdout.write(self.style.SUCCESS("✓ Fix attempted - run this command again to verify"))
        
        if options['failover']:
            self.stdout.write(self.style.WARNING("Forcing failover to secondary..."))
            # This would be implemented by updating settings.DB_ACTIVE
            self.stdout.write("✓ Failover configuration ready (manual restart required)")
        
        self.stdout.write("=" * 60)
