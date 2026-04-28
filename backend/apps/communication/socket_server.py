# apps/communication/socket_server.py
import socketio
import asyncio
import logging
from django.conf import settings
from .socket_events import register_socket_events

logger = logging.getLogger(__name__)

# Create Socket.IO server with CORS enabled for development
sio = socketio.AsyncServer(
    async_mode='asgi',
    cors_allowed_origins=[
        'http://localhost:3000',  # React dev server
        'http://127.0.0.1:3000',
        'http://localhost:8000',  # Django dev server
        'http://127.0.0.1:8000',
        settings.FRONTEND_URL,    # From settings
    ],
    logger=True,
    engineio_logger=settings.DEBUG,
    ping_timeout=60,
    ping_interval=25,
)

# Register all event handlers
register_socket_events(sio)

# Create ASGI app
app = socketio.ASGIApp(sio)

# Optional: Add middleware for logging
@sio.event
async def connect_error(sid, data):
    logger.error(f'Connect error for {sid}: {data}')

@sio.event
async def disconnect_error(sid, data):
    logger.error(f'Disconnect error for {sid}: {data}')

if __name__ == '__main__':
    import uvicorn
    print(f"Starting Socket.IO server on port 8001...")
    print(f"CORS allowed origins: {sio.cors_allowed_origins}")
    uvicorn.run(
        app, 
        host='0.0.0.0', 
        port=8001,
        log_level='info'
    )