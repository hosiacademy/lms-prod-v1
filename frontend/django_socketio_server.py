# socketio_server.py (Django backend)
import os
import socketio
from django.core.asgi import get_asgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'your_project.settings')

django_asgi_app = get_asgi_application()

# Create Socket.IO server
sio = socketio.AsyncServer(
    async_mode='asgi',
    cors_allowed_origins=[
        'http://localhost:3000',      # Flutter web dev
        'http://localhost:5555',      # Flutter mobile dev
        'http://192.168.1.100:8000',  # Your dev server
        'https://your-domain.com',    # Production
    ],
    ping_timeout=25,
    ping_interval=10,
)

# Mount Socket.IO app
app = socketio.ASGIApp(sio, django_asgi_app)

# Connection event
@sio.event
async def connect(sid, environ):
    print(f'Client connected: {sid}')
    # You can authenticate here using Django auth
    auth_token = environ.get('HTTP_AUTHORIZATION', '').replace('Bearer ', '')
    user_id = environ.get('HTTP_USER_ID')
    
    if not auth_token or not user_id:
        await sio.disconnect(sid)
        return False
    
    # Validate token with Django
    # from django.contrib.auth.models import User
    # ... authentication logic ...
    
    await sio.save_session(sid, {'user_id': user_id, 'authenticated': True})
    await sio.emit('welcome', {'message': 'Connected to Hosi Academy Chat'}, to=sid)
    return True

@sio.event
async def disconnect(sid):
    print(f'Client disconnected: {sid}')

@sio.event
async def join_user(sid, data):
    session = await sio.get_session(sid)
    user_id = session.get('user_id')
    
    # Join user's personal room
    await sio.enter_room(sid, f'user_{user_id}')
    
    # Join course rooms based on user's enrollments
    # ... logic to join course rooms ...

@sio.event
async def send_message(sid, data):
    session = await sio.get_session(sid)
    user_id = session.get('user_id')
    
    # Save message to database
    # ... Django ORM logic ...
    
    # Broadcast to room
    await sio.emit('new_message', data, room=data['chatId'])
    
    # Send acknowledgment
    await sio.emit('message_sent', {'success': True, 'message': data}, to=sid)

@sio.event
async def update_presence(sid, data):
    session = await sio.get_session(sid)
    user_id = session.get('user_id')
    
    # Update presence in database
    # ... Django ORM logic ...
    
    # Broadcast to relevant rooms
    await sio.emit('user_presence', {
        'userId': user_id,
        'status': data['status'],
        'timestamp': data['timestamp'],
    }, skip_sid=sid)

@sio.event
async def typing(sid, data):
    await sio.emit('typing_indicator', data, room=data['chatId'], skip_sid=sid)

# Run with: uvicorn socketio_server:app --host 0.0.0.0 --port 8000
