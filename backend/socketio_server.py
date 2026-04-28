import os
import django
import socketio

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')
django.setup()

from django.conf import settings

# Create Socket.IO server with CORS enabled
sio = socketio.AsyncServer(
    async_mode='asgi',
    cors_allowed_origins='*',  # Allow all origins (production-ready with nginx proxy)
    allow_upgrades=True,
    transports=['websocket', 'polling'],
)

# Create ASGI application
app = socketio.ASGIApp(sio)

# Event handlers
@sio.event
async def connect(sid, environ, auth):
    """Handle client connection"""
    print(f'✅ Client connected: {sid}')
    print(f'   Auth: {auth}')
    return True

@sio.event
async def disconnect(sid):
    """Handle client disconnection"""
    print(f'❌ Client disconnected: {sid}')

@sio.event
async def join_room(sid, data):
    """Handle room join request"""
    room = data.get('room')
    if room:
        await sio.enter_room(sid, room)
        print(f'📍 Client {sid} joined room: {room}')
        return {'status': 'success', 'room': room}
    return {'status': 'error', 'message': 'No room specified'}

@sio.event
async def leave_room(sid, data):
    """Handle room leave request"""
    room = data.get('room')
    if room:
        await sio.leave_room(sid, room)
        print(f'📍 Client {sid} left room: {room}')
        return {'status': 'success', 'room': room}
    return {'status': 'error', 'message': 'No room specified'}

@sio.event
async def message(sid, data):
    """Handle chat message"""
    room = data.get('room')
    message = data.get('message')
    
    if room and message:
        # Broadcast message to room
        await sio.emit('message', data, room=room)
        print(f'💬 Message sent to room {room}: {message[:50]}...')
        return {'status': 'success'}
    
    return {'status': 'error', 'message': 'Missing room or message'}

@sio.event
async def typing_start(sid, data):
    """Handle typing indicator start"""
    room = data.get('room')
    if room:
        data['isTyping'] = True
        await sio.emit('user_typing', data, room=room)
        return {'status': 'success'}
    return {'status': 'error', 'message': 'No room specified'}

@sio.event
async def typing_stop(sid, data):
    """Handle typing indicator stop"""
    room = data.get('room')
    if room:
        data['isTyping'] = False
        await sio.emit('user_typing', data, room=room)
        return {'status': 'success'}
    return {'status': 'error', 'message': 'No room specified'}

@sio.event
async def presence_online(sid, data):
    """Handle user online presence"""
    user_id = data.get('userId')
    if user_id:
        await sio.emit('user_online', data, broadcast=True)
        return {'status': 'success'}
    return {'status': 'error', 'message': 'No userId specified'}

@sio.event
async def presence_offline(sid, data):
    """Handle user offline presence"""
    user_id = data.get('userId')
    if user_id:
        await sio.emit('user_offline', data, broadcast=True)
        return {'status': 'success'}
    return {'status': 'error', 'message': 'No userId specified'}

# Run server
if __name__ == '__main__':
    import uvicorn
    host = os.getenv('SOCKETIO_HOST', '0.0.0.0')
    port = int(os.getenv('SOCKETIO_PORT', 8001))
    
    print(f'🚀 Starting Socket.IO server on {host}:{port}')
    print(f'   CORS enabled for all origins')
    
    uvicorn.run(app, host=host, port=port)
