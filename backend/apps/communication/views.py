# apps/communication/views.py
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.db.models import Q
from .models import (
    Message, ChatRoom, ChatParticipant, 
    UserPresence, Notification
)
from .serializers import (
    MessageSerializer, ChatRoomSerializer,
    UserPresenceSerializer, NotificationSerializer, 
    CreateChatRoomSerializer
)

User = get_user_model()

class ChatRoomViewSet(viewsets.ModelViewSet):
    queryset = ChatRoom.objects.all()
    serializer_class = ChatRoomSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return ChatRoom.objects.filter(
            participants__user=self.request.user
        ).order_by('-updated_at')
    
    @action(detail=False, methods=['post'])
    def create_dm(self, request):
        serializer = CreateChatRoomSerializer(data=request.data)
        if serializer.is_valid():
            other_user_id = serializer.validated_data['user_id']
            other_user = User.objects.get(id=other_user_id)
            
            import uuid
            user_ids = sorted([str(request.user.id), str(other_user_id)])
            room_id = f'direct_{"_".join(user_ids)}'
            
            room, created = ChatRoom.objects.get_or_create(
                id=room_id,
                defaults={
                    'name': f'DM: {request.user.username} & {other_user.username}',
                    'chat_type': 'one_on_one',
                }
            )
            
            ChatParticipant.objects.get_or_create(
                chat_room=room,
                user=request.user,
                defaults={'role': 'member'}
            )
            ChatParticipant.objects.get_or_create(
                chat_room=room,
                user=other_user,
                defaults={'role': 'member'}
            )
            
            return Response(ChatRoomSerializer(room).data, 
                          status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class MessageViewSet(viewsets.ModelViewSet):
    queryset = Message.objects.all()
    serializer_class = MessageSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        chat_room_id = self.request.query_params.get('chat_room')
        if chat_room_id:
            # Only return messages from rooms where the user is a participant
            from .models import ChatParticipant
            is_participant = ChatParticipant.objects.filter(
                chat_room_id=chat_room_id,
                user=self.request.user
            ).exists()
            if is_participant:
                return Message.objects.filter(
                    chat_room_id=chat_room_id,
                    is_deleted=False,
                ).order_by('created_at')
            return Message.objects.none()

        return Message.objects.filter(
            Q(sender=self.request.user) | Q(receiver=self.request.user),
            is_deleted=False,
        ).order_by('-created_at')

    def perform_create(self, serializer):
        """Auto-set sender and handle chat room last_message."""
        chat_room = serializer.validated_data.get('chat_room')
        receiver = serializer.validated_data.get('receiver')
        # If no receiver but chat_room exists, find receiver from room
        if chat_room and not receiver:
            from .models import ChatParticipant
            other = ChatParticipant.objects.filter(
                chat_room=chat_room
            ).exclude(user=self.request.user).select_related('user').first()
            if other:
                receiver = other.user
        msg = serializer.save(sender=self.request.user, receiver=receiver, type=True)
        if chat_room:
            chat_room.last_message = msg
            chat_room.save(update_fields=['last_message', 'updated_at'])
        return msg

    @action(detail=True, methods=['post'])
    def mark_read(self, request, pk=None):
        message = self.get_object()
        if message.receiver == request.user:
            message.seen = True
            message.save()
            return Response({'status': 'marked as read'})
        return Response({'error': 'Not authorized'},
                       status=status.HTTP_403_FORBIDDEN)

    @action(detail=False, methods=['post'])
    def mark_room_read(self, request):
        """Mark all messages in a chat room as read."""
        chat_room_id = request.data.get('chat_room_id')
        if not chat_room_id:
            return Response({'error': 'chat_room_id required'}, status=status.HTTP_400_BAD_REQUEST)
        Message.objects.filter(
            chat_room_id=chat_room_id,
            receiver=request.user,
            seen=False,
        ).update(seen=True)
        return Response({'status': 'ok'})

class UserPresenceViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = UserPresence.objects.all()
    serializer_class = UserPresenceSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    @action(detail=False, methods=['get'])
    def online_users(self, request):
        online = UserPresence.objects.filter(status='online')
        serializer = self.get_serializer(online, many=True)
        return Response(serializer.data)

class NotificationViewSet(viewsets.ModelViewSet):
    queryset = Notification.objects.all()
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Notification.objects.filter(
            user=self.request.user
        ).order_by('-created_at')
    
    @action(detail=False, methods=['post'])
    def mark_all_read(self, request):
        Notification.objects.filter(
            user=request.user,
            is_read=False
        ).update(is_read=True)
        return Response({'status': 'all marked as read'})