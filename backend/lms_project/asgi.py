"""
ASGI config for lms_project project.

It exposes the ASGI callable as a module-level variable named ``application``.

For more information on this file, see
https://docs.djangoproject.com/en/6.0/howto/deployment/asgi/
"""

import os
import django
from django.core.asgi import get_asgi_application
import socketio

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

# Initialize Django ASGI application
django_asgi_app = get_asgi_application()

# Optional: Redis adapter for production scaling
client_manager = None
if os.environ.get('ENVIRONMENT') == 'production':
    import socketio.redis_manager
    client_manager = socketio.redis_manager.RedisManager(
        os.environ.get('SOCKETIO_REDIS_URL', 'redis://localhost:6379/1')
    )

# Create ONE instance of Socket.IO server
sio = socketio.AsyncServer(
    async_mode='asgi',
    cors_allowed_origins='*',
    ping_timeout=25,
    ping_interval=10,
    max_http_buffer_size=104857600,  # 100MB
    logger=True,
    engineio_logger=os.environ.get('DEBUG', 'False') == 'True',
    client_manager=client_manager,
)

# Import and register socket events after Django is ready
from apps.communication.socket_events import register_socket_events
register_socket_events(sio)

# Create ASGI app that combines Django and Socket.IO
application = socketio.ASGIApp(sio, django_asgi_app)
