# apps/communication/management/commands/run_socketio.py
from django.core.management.base import BaseCommand
import uvicorn
import asyncio
import sys
import os
from pathlib import Path

# Add project root to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent.parent))

class Command(BaseCommand):
    help = 'Run Socket.IO server for real-time chat'
    
    def add_arguments(self, parser):
        parser.add_argument(
            '--host',
            type=str,
            default='0.0.0.0',
            help='Host to run the server on'
        )
        parser.add_argument(
            '--port',
            type=int,
            default=8001,
            help='Port to run the server on'
        )
        parser.add_argument(
            '--workers',
            type=int,
            default=1,
            help='Number of worker processes'
        )
    
    def handle(self, *args, **options):
        host = options['host']
        port = options['port']
        workers = options['workers']
        
        self.stdout.write(
            self.style.SUCCESS(
                f'Starting Socket.IO server on {host}:{port} with {workers} worker(s)'
            )
        )
        
        # Import and run the Socket.IO server
        from apps.communication.socket_server import app
        
        uvicorn.run(
            app,
            host=host,
            port=port,
            workers=workers,
            log_level='info'
        )