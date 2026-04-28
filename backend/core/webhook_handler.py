"""
Webhook handler for Supabase real-time sync
Receives webhook events from Supabase and syncs to Docker PostgreSQL
"""

import json
import logging
import hmac
import hashlib
from datetime import datetime
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
import os

logger = logging.getLogger(__name__)


def verify_webhook_signature(request) -> bool:
    """Verify webhook signature from Supabase"""
    webhook_secret = os.getenv('WEBHOOK_SECRET', '')
    
    if not webhook_secret:
        logger.warning("WEBHOOK_SECRET not configured, skipping signature verification")
        return True
    
    signature = request.headers.get('X-Supabase-Signature', '')
    body = request.body
    
    expected_sig = hmac.new(
        webhook_secret.encode(),
        body,
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(signature, expected_sig)


@csrf_exempt
def supabase_webhook(request):
    """
    Receive webhook events from Supabase
    Syncs changes to Docker PostgreSQL
    """
    if request.method != 'POST':
        return JsonResponse({'error': 'Method not allowed'}, status=405)
    
    # Verify signature
    if not verify_webhook_signature(request):
        logger.warning("Invalid webhook signature")
        return JsonResponse({'error': 'Invalid signature'}, status=401)
    
    try:
        payload = json.loads(request.body)
        event_type = payload.get('type')
        table = payload.get('table')
        record = payload.get('record')
        old_record = payload.get('old_record')
        
        logger.info(f"Webhook received: {event_type} on {table}")
        
        # Import sync service here to avoid circular imports
        from core.db_sync_service import get_sync_service
        sync_service = get_sync_service()
        
        # Handle different event types
        if event_type == 'INSERT':
            _handle_insert(table, record, sync_service)
        elif event_type == 'UPDATE':
            _handle_update(table, record, old_record, sync_service)
        elif event_type == 'DELETE':
            _handle_delete(table, old_record, sync_service)
        
        return JsonResponse({'status': 'received'})
    
    except json.JSONDecodeError:
        logger.error("Invalid JSON in webhook payload")
        return JsonResponse({'error': 'Invalid JSON'}, status=400)
    except Exception as e:
        logger.error(f"Webhook error: {e}")
        return JsonResponse({'error': str(e)}, status=500)


def _handle_insert(table: str, record: dict, sync_service):
    """Handle INSERT event from Supabase"""
    try:
        from django.db import connections
        conn = connections['default']
        
        with conn.cursor() as cursor:
            # Build INSERT query
            columns = ', '.join(record.keys())
            placeholders = ', '.join(['%s'] * len(record))
            query = f"INSERT INTO {table} ({columns}) VALUES ({placeholders})"
            
            cursor.execute(query, list(record.values()))
            conn.commit()
            
            logger.debug(f"Inserted {len(record)} fields into {table}")
    except Exception as e:
        logger.error(f"Failed to handle INSERT: {e}")
        raise


def _handle_update(table: str, record: dict, old_record: dict, sync_service):
    """Handle UPDATE event from Supabase"""
    try:
        from django.db import connections
        conn = connections['default']
        
        with conn.cursor() as cursor:
            # Find primary key from old_record
            pk_data = {k: v for k, v in old_record.items() if k == 'id'}
            
            if not pk_data:
                logger.warning(f"No primary key found for UPDATE on {table}")
                return
            
            # Build UPDATE query
            set_clause = ', '.join([f"{k}=%s" for k in record.keys()])
            where_clause = ' AND '.join([f"{k}=%s" for k in pk_data.keys()])
            
            query = f"UPDATE {table} SET {set_clause} WHERE {where_clause}"
            values = list(record.values()) + list(pk_data.values())
            
            cursor.execute(query, values)
            conn.commit()
            
            logger.debug(f"Updated {table} id={pk_data.get('id')}")
    except Exception as e:
        logger.error(f"Failed to handle UPDATE: {e}")
        raise


def _handle_delete(table: str, old_record: dict, sync_service):
    """Handle DELETE event from Supabase"""
    try:
        from django.db import connections
        conn = connections['default']
        
        with conn.cursor() as cursor:
            # Find primary key
            pk_data = {k: v for k, v in old_record.items() if k == 'id'}
            
            if not pk_data:
                logger.warning(f"No primary key found for DELETE on {table}")
                return
            
            # Build DELETE query
            where_clause = ' AND '.join([f"{k}=%s" for k in pk_data.keys()])
            query = f"DELETE FROM {table} WHERE {where_clause}"
            
            cursor.execute(query, list(pk_data.values()))
            conn.commit()
            
            logger.debug(f"Deleted from {table} id={pk_data.get('id')}")
    except Exception as e:
        logger.error(f"Failed to handle DELETE: {e}")
        raise


def health_check(request):
    """Health check endpoint for sync service"""
    try:
        from django.db import connections
        from core.db_sync_service import get_sync_service
        from core.database_router import DatabaseHealthChecker
        
        sync_service = get_sync_service()
        
        # Check both databases
        primary_health = DatabaseHealthChecker.is_healthy('default')
        secondary_health = DatabaseHealthChecker.is_healthy('supabase')
        
        # Get sync status
        sync_status = sync_service.verify_sync_status()
        
        health = {
            'status': 'healthy' if (primary_health or secondary_health) else 'unhealthy',
            'primary_db': 'healthy' if primary_health else 'unhealthy',
            'secondary_db': 'healthy' if secondary_health else 'unhealthy',
            'sync_status': sync_status,
            'timestamp': datetime.now().isoformat(),
            'conflicts': len(sync_service.conflict_log)
        }
        
        return JsonResponse(health)
    except Exception as e:
        logger.error(f"Health check error: {e}")
        return JsonResponse({'status': 'error', 'error': str(e)}, status=500)
