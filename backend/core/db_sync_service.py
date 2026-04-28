"""
Bidirectional Database Sync Service
Syncs changes between Docker PostgreSQL (Primary) and Supabase (Secondary)
Handles conflicts and maintains data consistency
"""

import json
import logging
import threading
import time
from datetime import datetime
from typing import Dict, List, Optional, Any
from django.db import connection, connections
from django.core.management.base import CommandError
import psycopg2
from psycopg2 import sql

logger = logging.getLogger(__name__)


class DatabaseSyncService:
    """
    Manages bidirectional sync between primary (Docker) and secondary (Supabase) databases
    """
    
    def __init__(self, primary_db='default', secondary_db='supabase'):
        self.primary_db = primary_db
        self.secondary_db = secondary_db
        self.sync_enabled = True
        self.last_sync = {}
        self.conflict_log = []
        
    def start_sync_daemon(self):
        """Start background sync thread"""
        sync_thread = threading.Thread(target=self._sync_loop, daemon=True)
        sync_thread.start()
        logger.info("Database sync daemon started")
        return sync_thread
    
    def _sync_loop(self):
        """Continuous sync loop"""
        import os
        from django.conf import settings
        
        sync_interval = int(os.getenv('DB_SYNC_INTERVAL', 60))
        
        while self.sync_enabled:
            try:
                self.sync_bidirectional()
                time.sleep(sync_interval)
            except Exception as e:
                logger.error(f"Sync error: {e}")
                time.sleep(sync_interval)
    
    def sync_bidirectional(self):
        """
        Perform bidirectional sync:
        1. Get changes from primary since last sync
        2. Get changes from secondary since last sync
        3. Merge changes, handle conflicts
        4. Apply to both databases
        """
        try:
            # Get changes from both databases
            primary_changes = self._get_changes(self.primary_db)
            secondary_changes = self._get_changes(self.secondary_db)
            
            # Merge and apply
            self._apply_changes(primary_changes, self.secondary_db, 'primary')
            self._apply_changes(secondary_changes, self.primary_db, 'secondary')
            
            # Update sync timestamp
            self.last_sync['bidirectional'] = datetime.now()
            logger.debug(f"Bidirectional sync completed: {len(primary_changes)} primary, {len(secondary_changes)} secondary")
            
        except Exception as e:
            logger.error(f"Bidirectional sync failed: {e}")
            raise
    
    def _get_changes(self, db_alias: str) -> List[Dict[str, Any]]:
        """
        Get changes from database since last sync
        Returns list of change dictionaries
        """
        import os
        from django.conf import settings
        
        exclude_tables = os.getenv('DB_SYNC_EXCLUDE_TABLES', 'django_migrations,django_session,django_admin_log').split(',')
        
        try:
            conn = connections[db_alias]
            with conn.cursor() as cursor:
                # Get list of tables to sync
                cursor.execute("""
                    SELECT table_name FROM information_schema.tables 
                    WHERE table_schema='public' AND table_type='BASE TABLE'
                """)
                tables = [row[0] for row in cursor.fetchall()]
                tables = [t for t in tables if t not in exclude_tables]
                
                changes = []
                for table in tables:
                    table_changes = self._get_table_changes(cursor, table, db_alias)
                    changes.extend(table_changes)
                
                return changes
        except Exception as e:
            logger.error(f"Failed to get changes from {db_alias}: {e}")
            return []
    
    def _get_table_changes(self, cursor, table: str, db_alias: str) -> List[Dict]:
        """Get changes for a specific table"""
        changes = []
        
        try:
            # Check if table has change tracking columns
            cursor.execute(f"""
                SELECT column_name FROM information_schema.columns 
                WHERE table_name='{table}' AND column_name IN ('updated_at', 'modified_at', 'changed_at')
            """)
            
            timestamp_col = None
            if cursor.fetchone():
                timestamp_col = cursor.fetchone()[0]
            
            if timestamp_col:
                # Get recently changed rows
                last_sync_time = self.last_sync.get(f'{db_alias}_{table}', '1970-01-01')
                cursor.execute(sql.SQL("""
                    SELECT * FROM {} WHERE {} > %s
                """).format(sql.Identifier(table), sql.Identifier(timestamp_col)),
                [last_sync_time])
                
                # Convert to dictionaries
                columns = [desc[0] for desc in cursor.description]
                for row in cursor.fetchall():
                    changes.append({
                        'table': table,
                        'data': dict(zip(columns, row)),
                        'source_db': db_alias,
                        'timestamp': datetime.now()
                    })
                
                self.last_sync[f'{db_alias}_{table}'] = datetime.now()
        except Exception as e:
            logger.warning(f"Could not get changes for {table}: {e}")
        
        return changes
    
    def _apply_changes(self, changes: List[Dict], target_db: str, source_db: str):
        """Apply changes to target database"""
        if not changes:
            return
        
        try:
            conn = connections[target_db]
            with conn.cursor() as cursor:
                for change in changes:
                    try:
                        self._upsert_record(cursor, change, target_db)
                        conn.commit()
                    except Exception as e:
                        logger.warning(f"Could not apply change from {source_db}: {e}")
                        self._log_conflict(change, target_db, str(e))
                        conn.rollback()
        except Exception as e:
            logger.error(f"Failed to apply changes to {target_db}: {e}")
    
    def _upsert_record(self, cursor, change: Dict, target_db: str):
        """Insert or update record (UPSERT)"""
        table = change['table']
        data = change['data']
        
        # Find primary key
        cursor.execute(f"""
            SELECT a.attname FROM pg_index i
            JOIN pg_attribute a ON a.attrelid = i.indrelid
            AND a.attnum = ANY(i.indkey)
            WHERE i.indrelname = '{table}_pkey'
        """)
        
        pk_cols = [row[0] for row in cursor.fetchall()]
        
        if not pk_cols:
            # Fallback to 'id' if no PK found
            pk_cols = ['id']
        
        # Build UPSERT query
        set_clause = ', '.join([f"{k}=%s" for k in data.keys() if k not in pk_cols])
        pk_clause = ' AND '.join([f"{k}=%s" for k in pk_cols])
        
        values = [data[k] for k in data.keys() if k not in pk_cols]
        values.extend([data[k] for k in pk_cols])
        
        query = f"""
            UPDATE {table} SET {set_clause} WHERE {pk_clause};
            INSERT INTO {table} ({', '.join(data.keys())})
            SELECT {', '.join(['%s'] * len(data))}
            WHERE NOT EXISTS (SELECT 1 FROM {table} WHERE {pk_clause});
        """
        
        try:
            cursor.execute(query, values + list(data.values()) + values)
        except Exception as e:
            # If query fails, try simple insert
            cursor.execute(
                f"INSERT INTO {table} ({', '.join(data.keys())}) VALUES ({', '.join(['%s'] * len(data))})",
                list(data.values())
            )
    
    def _log_conflict(self, change: Dict, target_db: str, error: str):
        """Log sync conflicts"""
        conflict = {
            'table': change['table'],
            'source_db': change['source_db'],
            'target_db': target_db,
            'error': error,
            'timestamp': datetime.now().isoformat(),
            'data': change['data']
        }
        self.conflict_log.append(conflict)
        logger.warning(f"Sync conflict logged: {conflict}")
    
    def get_conflict_log(self) -> List[Dict]:
        """Get list of sync conflicts"""
        return self.conflict_log
    
    def clear_conflict_log(self):
        """Clear conflict log"""
        self.conflict_log = []
    
    def verify_sync_status(self) -> Dict[str, Any]:
        """Verify that both databases are in sync"""
        try:
            primary_conn = connections[self.primary_db]
            secondary_conn = connections[self.secondary_db]
            
            stats = {
                'status': 'in-sync',
                'primary_tables': self._get_table_count(primary_conn),
                'secondary_tables': self._get_table_count(secondary_conn),
                'conflicts': len(self.conflict_log),
                'last_sync': self.last_sync.get('bidirectional'),
                'timestamp': datetime.now().isoformat()
            }
            
            # Compare row counts
            differences = self._compare_table_counts(primary_conn, secondary_conn)
            if differences:
                stats['status'] = 'out-of-sync'
                stats['differences'] = differences
            
            return stats
        except Exception as e:
            logger.error(f"Failed to verify sync status: {e}")
            return {'status': 'error', 'error': str(e)}
    
    def _get_table_count(self, conn) -> Dict[str, int]:
        """Get row count for each table"""
        counts = {}
        try:
            with conn.cursor() as cursor:
                cursor.execute("""
                    SELECT table_name FROM information_schema.tables 
                    WHERE table_schema='public' AND table_type='BASE TABLE'
                """)
                
                for table_row in cursor.fetchall():
                    table = table_row[0]
                    cursor.execute(f"SELECT COUNT(*) FROM {table}")
                    counts[table] = cursor.fetchone()[0]
        except Exception as e:
            logger.warning(f"Could not get table counts: {e}")
        
        return counts
    
    def _compare_table_counts(self, primary_conn, secondary_conn) -> List[Dict]:
        """Compare row counts between databases"""
        differences = []
        
        try:
            primary_counts = self._get_table_count(primary_conn)
            secondary_counts = self._get_table_count(secondary_conn)
            
            all_tables = set(primary_counts.keys()) | set(secondary_counts.keys())
            
            for table in all_tables:
                p_count = primary_counts.get(table, 0)
                s_count = secondary_counts.get(table, 0)
                
                if p_count != s_count:
                    differences.append({
                        'table': table,
                        'primary_rows': p_count,
                        'secondary_rows': s_count,
                        'difference': abs(p_count - s_count)
                    })
        except Exception as e:
            logger.warning(f"Could not compare table counts: {e}")
        
        return differences
    
    def force_sync_table(self, table: str, direction: str = 'bidirectional'):
        """Force sync a specific table"""
        try:
            if direction in ['bidirectional', 'primary_to_secondary']:
                changes = self._get_table_changes(
                    connections[self.primary_db].cursor(),
                    table,
                    self.primary_db
                )
                self._apply_changes(changes, self.secondary_db, self.primary_db)
                logger.info(f"Synced {table} from primary to secondary")
            
            if direction in ['bidirectional', 'secondary_to_primary']:
                changes = self._get_table_changes(
                    connections[self.secondary_db].cursor(),
                    table,
                    self.secondary_db
                )
                self._apply_changes(changes, self.primary_db, self.secondary_db)
                logger.info(f"Synced {table} from secondary to primary")
        except Exception as e:
            logger.error(f"Failed to force sync {table}: {e}")
            raise


# Global sync service instance
_sync_service = None


def get_sync_service():
    """Get or create global sync service"""
    global _sync_service
    if _sync_service is None:
        _sync_service = DatabaseSyncService()
    return _sync_service
