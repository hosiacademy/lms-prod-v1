# apps/communication/socket_events.py
import json
import logging
import uuid
from datetime import datetime
from typing import Dict, Any
from django.contrib.auth import get_user_model
from django.core.cache import cache
from rest_framework_simplejwt.tokens import AccessToken
from asgiref.sync import sync_to_async

# Import from models (NOT socket_models)
from .models import (
    Message, ChatRoom, ChatParticipant, 
    UserPresence, MessageReadReceipt, Notification
)

logger = logging.getLogger(__name__)
User = get_user_model()

# In-memory storage for online users (use Redis in production)
online_users: Dict[str, Dict[str, Any]] = {}

# Helper Functions
async def update_user_presence(user_id, status, socket_id=None):
    """Update user presence in database"""
    try:
        @sync_to_async
        def update_presence():
            user = User.objects.get(id=user_id)
            presence, created = UserPresence.objects.get_or_create(
                user=user,
                defaults={'status': status}
            )
            presence.status = status
            if socket_id:
                presence.socket_id = socket_id
            presence.last_seen = datetime.now()
            presence.save()
            return presence
        
        presence = await update_presence()
        logger.info(f'Updated presence for {user_id}: {status}')
        return presence
    except Exception as e:
        logger.error(f'Error updating presence for {user_id}: {e}')
        return None

async def join_user_chat_rooms(sio, sid, user_id):
    """Join user to their chat rooms"""
    try:
        @sync_to_async
        def get_user_rooms():
            return ChatParticipant.objects.filter(
                user_id=user_id,
                chat_room__is_archived=False
            ).select_related('chat_room')
        
        chat_participants = await get_user_rooms()
        
        for participant in chat_participants:
            room_name = f'chat_{participant.chat_room.id}'
            await sio.enter_room(sid, room_name)
            logger.info(f'User {user_id} joined room {room_name}')
        
        return len(chat_participants)
    except Exception as e:
        logger.error(f'Error joining chat rooms for {user_id}: {e}')
        return 0

async def create_message_from_socket_data(data, user):
    """Create message from socket data"""
    try:
        @sync_to_async
        def save_message():
            # Get receiver from data or determine from chat room
            receiver_id = data.get('receiverId')
            receiver = None
            
            # Get or create chat room
            chat_room = None
            chat_id = data.get('chatId')
            
            if chat_id:
                if chat_id.startswith('chat_'):
                    chat_room_id = chat_id.replace('chat_', '')
                    chat_room = ChatRoom.objects.filter(id=chat_room_id).first()
                    
                    # For direct message rooms, find the other participant
                    if chat_room and chat_room.chat_type == 'one_on_one':
                        participants = chat_room.participants.all()
                        if participants.count() == 2:
                            other_participant = participants.exclude(user=user).first()
                            if other_participant:
                                receiver = other_participant.user
                
                elif chat_id.startswith('direct_'):
                    # Direct message without room - extract receiver ID
                    parts = chat_id.split('_')
                    if len(parts) == 3:
                        user1_id, user2_id = parts[1], parts[2]
                        receiver_id = user2_id if str(user.id) == user1_id else user1_id
                        receiver = User.objects.filter(id=receiver_id).first()
            
            # If receiver not found yet, use receiverId from data
            if not receiver and receiver_id:
                receiver = User.objects.filter(id=receiver_id).first()
            
            if not receiver:
                raise ValueError("No receiver found for message")
            
            # Create message
            message = Message.objects.create(
                sender=user,
                receiver=receiver,
                message=data.get('content', ''),
                message_type=data.get('type', 'text'),
                socket_message_id=data.get('id') or f'msg_{uuid.uuid4().hex[:10]}',
                chat_room=chat_room,
                attachments=data.get('attachments', []),
                metadata=data.get('metadata', {}),
            )
            
            # Handle reply
            reply_to_id = data.get('replyToId')
            if reply_to_id:
                reply_message = Message.objects.filter(
                    socket_message_id=reply_to_id
                ).first()
                if reply_message:
                    message.reply_to = reply_message
                    message.save()
            
            # Update chat room last message if applicable
            if chat_room:
                chat_room.last_message = message
                chat_room.save(update_fields=['last_message', 'updated_at'])
            
            return message.to_socketio_format()
        
        return await save_message()
    except Exception as e:
        logger.error(f'Error creating message: {e}')
        return None

async def broadcast_message(message_data, sid):
    """Broadcast message to appropriate rooms"""
    try:
        # Import sio here to avoid circular imports
        from apps.communication.socket_server import sio
        
        chat_id = message_data.get('chatId')
        sender_id = message_data.get('senderId')
        
        if not chat_id:
            return
        
        # Broadcast to chat room
        if chat_id.startswith('chat_'):
            await sio.emit('message_received', {
                'message': message_data,
                'timestamp': datetime.now().isoformat(),
            }, room=chat_id, skip_sid=sid)
        elif chat_id.startswith('direct_'):
            # For direct messages, send to both users
            parts = chat_id.split('_')
            if len(parts) == 3:
                user1_id, user2_id = parts[1], parts[2]
                # Send to both participants
                await sio.emit('private_message', {
                    'message': message_data,
                    'timestamp': datetime.now().isoformat(),
                }, room=f'user_{user1_id}')
                await sio.emit('private_message', {
                    'message': message_data,
                    'timestamp': datetime.now().isoformat(),
                }, room=f'user_{user2_id}')
        
        # Create notification for receiver
        @sync_to_async
        def create_notification():
            receiver_id = message_data.get('receiverId')
            if receiver_id:
                receiver = User.objects.filter(id=receiver_id).first()
                if receiver:
                    Notification.objects.create(
                        user=receiver,
                        notification_type='message',
                        title='New Message',
                        message=f"New message from {message_data.get('senderName', 'User')}",
                        metadata=message_data
                    )
        
        await create_notification()
        
    except Exception as e:
        logger.error(f'Error broadcasting message: {e}')

async def get_user_chat_rooms(user_id):
    """Get user's chat rooms"""
    try:
        @sync_to_async
        def fetch_rooms():
            rooms = ChatRoom.objects.filter(
                participants__user_id=user_id,
                is_archived=False
            ).order_by('-updated_at')
            
            return [room.to_socketio_format() for room in rooms]
        
        return await fetch_rooms()
    except Exception as e:
        logger.error(f'Error getting chat rooms for {user_id}: {e}')
        return []

async def mark_messages_read(user_id, message_id, chat_id):
    """Mark messages as read"""
    try:
        @sync_to_async
        def mark_read():
            # Mark specific message as read
            if message_id:
                message = Message.objects.filter(
                    id=message_id,
                    receiver_id=user_id
                ).first()
                if message:
                    message.seen = True
                    message.save(update_fields=['seen', 'updated_at'])
                    
                    # Create read receipt
                    MessageReadReceipt.objects.create(
                        message=message,
                        user_id=user_id,
                        read_at=datetime.now()
                    )
                    return True
            
            # Mark all unread messages in chat as read
            elif chat_id:
                chat_room_id = chat_id.replace('chat_', '')
                messages = Message.objects.filter(
                    chat_room_id=chat_room_id,
                    receiver_id=user_id,
                    seen=False
                )
                
                for message in messages:
                    message.seen = True
                    message.save(update_fields=['seen', 'updated_at'])
                    
                    MessageReadReceipt.objects.create(
                        message=message,
                        user_id=user_id,
                        read_at=datetime.now()
                    )
                
                return True
            
            return False
        
        return await mark_read()
    except Exception as e:
        logger.error(f'Error marking messages as read: {e}')
        return False

# Event Handlers
def register_socket_events(sio):
    """Register all Socket.IO event handlers"""
    
    @sio.event
    async def connect(sid, environ, auth=None):
        """Handle new Socket.IO connections with Django authentication"""
        try:
            # Extract authentication headers or from auth dict
            token = None
            client_type = environ.get('HTTP_CLIENT_TYPE', 'unknown')
            
            if auth and isinstance(auth, dict) and auth.get('token'):
                token = auth.get('token')
            else:
                auth_header = environ.get('HTTP_AUTHORIZATION', '')
                if auth_header.startswith('Bearer '):
                    token = auth_header.split('Bearer ')[1]
            
            logger.info(f'Connection attempt from {sid}: client={client_type}')
            
            if not token:
                logger.warning(f'No token provided for {sid}')
                await sio.disconnect(sid)
                return False
            
            # Verify JWT token
            try:
                access_token = AccessToken(token)
                user_id = str(access_token['user_id'])
                
                # Get user from database
                @sync_to_async
                def get_user():
                    return User.objects.get(id=user_id)
                
                user = await get_user()
                
            except Exception as auth_error:
                logger.error(f'Authentication failed for {sid}: {auth_error}')
                await sio.disconnect(sid)
                return False
            
            # Save user session
            await sio.save_session(sid, {
                'user_id': user_id,
                'username': user.username,
                'email': user.email,
                'authenticated': True,
                'connected_at': datetime.now().isoformat(),
                'client_type': client_type,
                'role': user.role if hasattr(user, 'role') else 'learner',
            })
            
            # Update user presence
            await update_user_presence(user_id, 'online', sid)
            
            # Join user's personal room
            await sio.enter_room(sid, f'user_{user_id}')
            
            # Join user's chat rooms
            await join_user_chat_rooms(sio, sid, user_id)
            
            # Broadcast user online status
            await sio.emit('user_online', {
                'userId': user_id,
                'username': user.username,
                'role': user.role if hasattr(user, 'role') else 'learner',
                'timestamp': datetime.now().isoformat(),
            }, skip_sid=sid)
            
            # Send welcome message
            await sio.emit('welcome', {
                'message': f'Welcome {user.username}!',
                'userId': user_id,
                'timestamp': datetime.now().isoformat(),
            }, to=sid)
            
            logger.info(f'User {user.username} ({user_id}) connected with sid {sid}')
            return True
            
        except Exception as e:
            logger.error(f'Connect error for {sid}: {e}')
            await sio.disconnect(sid)
            return False
    
    @sio.event
    async def disconnect(sid):
        """Handle user disconnection"""
        try:
            session = await sio.get_session(sid)
            user_id = session.get('user_id')
            
            if user_id:
                # Update user presence to offline
                await update_user_presence(user_id, 'offline')
                
                # Broadcast user offline status
                await sio.emit('user_offline', {
                    'userId': user_id,
                    'username': session.get('username'),
                    'timestamp': datetime.now().isoformat(),
                })
                
                logger.info(f'User {session.get("username")} ({user_id}) disconnected')
                
        except Exception as e:
            logger.error(f'Disconnect error for {sid}: {e}')
    
    @sio.event
    async def join_room(sid, data):
        """Join a specific room"""
        session = await sio.get_session(sid)
        user_id = session.get('user_id')
        
        if not user_id:
            return
        
        room_id = data.get('roomId')
        if room_id:
            await sio.enter_room(sid, f'chat_{room_id}')
            await sio.emit('room_joined', {
                'roomId': room_id,
                'userId': user_id,
                'timestamp': datetime.now().isoformat(),
            }, to=sid)
    
    @sio.event
    async def leave_room(sid, data):
        """Leave a specific room"""
        session = await sio.get_session(sid)
        user_id = session.get('user_id')
        
        if not user_id:
            return
        
        room_id = data.get('roomId')
        if room_id:
            await sio.leave_room(sid, f'chat_{room_id}')
            await sio.emit('room_left', {
                'roomId': room_id,
                'userId': user_id,
                'timestamp': datetime.now().isoformat(),
            }, to=sid)
    
    @sio.event
    async def send_message(sid, data):
        """Send a chat message"""
        try:
            session = await sio.get_session(sid)
            user_id = session.get('user_id')
            
            if not user_id:
                await sio.emit('error', {
                    'message': 'Not authenticated',
                    'code': 'AUTH_ERROR',
                }, to=sid)
                return
            
            # Get user
            @sync_to_async
            def get_user():
                return User.objects.get(id=user_id)
            
            user = await get_user()
            
            # Create message
            message_data = await create_message_from_socket_data(data, user)
            
            if not message_data:
                await sio.emit('error', {
                    'message': 'Failed to create message',
                    'code': 'MESSAGE_CREATE_ERROR',
                }, to=sid)
                return
            
            # Broadcast the message
            await broadcast_message(message_data, sid)
            
            # Send acknowledgment
            await sio.emit('message_sent', {
                'success': True,
                'message': message_data,
                'timestamp': datetime.now().isoformat(),
            }, to=sid)
            
            logger.info(f'Message sent by {user_id} in chat {data.get("chatId")}')
            
        except Exception as e:
            logger.error(f'Error sending message: {e}')
            await sio.emit('error', {
                'message': str(e),
                'code': 'SERVER_ERROR',
            }, to=sid)
    
    @sio.event
    async def update_presence(sid, data):
        """Update user presence status"""
        session = await sio.get_session(sid)
        user_id = session.get('user_id')
        
        if not user_id:
            return
        
        status = data.get('status', 'online')
        custom_status = data.get('customStatus')
        
        # Update user presence
        presence = await update_user_presence(user_id, status, sid)
        if presence and custom_status:
            presence.custom_status = custom_status
            await sync_to_async(presence.save)()
        
        # Broadcast presence update
        await sio.emit('user_presence', {
            'userId': user_id,
            'status': status,
            'customStatus': custom_status,
            'timestamp': datetime.now().isoformat(),
            'username': session.get('username'),
            'role': session.get('role', 'learner'),
        }, skip_sid=sid)
        
        logger.info(f'User {user_id} presence updated to {status}')
    
    @sio.event
    async def typing(sid, data):
        """Handle typing indicators"""
        session = await sio.get_session(sid)
        user_id = session.get('user_id')
        
        if not user_id:
            return
        
        chat_id = data.get('chatId')
        if not chat_id:
            return
        
        typing_data = {
            'userId': user_id,
            'chatId': chat_id,
            'isTyping': data.get('isTyping', False),
            'timestamp': datetime.now().isoformat(),
            'username': session.get('username'),
        }
        
        # Broadcast to chat room (excluding sender)
        await sio.emit('typing_indicator', typing_data, 
                       room=f'chat_{chat_id}', 
                       skip_sid=sid)
    
    @sio.event
    async def mark_as_read(sid, data):
        """Mark messages as read"""
        session = await sio.get_session(sid)
        user_id = session.get('user_id')
        
        if not user_id:
            return
        
        message_id = data.get('messageId')
        chat_id = data.get('chatId')
        
        success = await mark_messages_read(user_id, message_id, chat_id)
        
        if success and chat_id:
            # Broadcast read receipt
            await sio.emit('messages_read', {
                'userId': user_id,
                'chatId': chat_id,
                'timestamp': datetime.now().isoformat(),
                'username': session.get('username'),
            }, room=f'chat_{chat_id}')
    
    @sio.event
    async def get_chat_rooms(sid, data):
        """Get user's chat rooms"""
        session = await sio.get_session(sid)
        user_id = session.get('user_id')
        
        if not user_id:
            return
        
        chat_rooms = await get_user_chat_rooms(user_id)
        
        await sio.emit('chat_rooms_list', {
            'rooms': chat_rooms,
            'timestamp': datetime.now().isoformat(),
        }, to=sid)
    
    @sio.event
    async def get_online_users(sid, data):
        """Get online users"""
        try:
            @sync_to_async
            def fetch_online_users():
                return list(UserPresence.objects.filter(
                    status='online'
                ).select_related('user').values(
                    'user_id',
                    'user__username',
                    'user__email',
                    'status',
                    'last_seen',
                    'custom_status'
                ))
            
            online_users_list = await fetch_online_users()
            
            await sio.emit('online_users', {
                'users': online_users_list,
                'timestamp': datetime.now().isoformat(),
            }, to=sid)
        except Exception as e:
            logger.error(f'Error getting online users: {e}')