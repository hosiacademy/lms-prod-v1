# apps/communication/serializers.py
from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import (
    Message, ChatRoom, ChatParticipant,
    UserPresence, Notification
)

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'first_name', 'last_name')

class BBBSessionInfoSerializer(serializers.Serializer):
    """Serializer for BBB session info cached in ChatRoom"""
    id = serializers.IntegerField(read_only=True)
    title = serializers.CharField(read_only=True)
    scheduled_start = serializers.DateTimeField(read_only=True)
    scheduled_end = serializers.DateTimeField(read_only=True)
    instructor_name = serializers.CharField(read_only=True)
    is_live_now = serializers.BooleanField(read_only=True)
    is_upcoming = serializers.BooleanField(read_only=True)

class ChatRoomSerializer(serializers.ModelSerializer):
    participants = UserSerializer(many=True, read_only=True)
    last_message = serializers.SerializerMethodField()
    unread_count = serializers.SerializerMethodField()
    upcoming_bbb_session = serializers.SerializerMethodField()
    bbb_session_info = BBBSessionInfoSerializer(read_only=True)

    class Meta:
        model = ChatRoom
        fields = ('id', 'name', 'description', 'chat_type',
                 'course_app', 'course_model', 'course_id', 'course_title',
                 'participants', 'last_message', 'unread_count',
                 'created_at', 'updated_at', 'is_archived',
                 'upcoming_bbb_session', 'bbb_session_info')

    def get_last_message(self, obj):
        if obj.last_message:
            return MessageSerializer(obj.last_message).data
        return None

    def get_unread_count(self, obj):
        request = self.context.get('request')
        if request and request.user:
            return Message.objects.filter(
                chat_room=obj,
                seen=False,
                receiver=request.user
            ).count()
        return 0

    def get_upcoming_bbb_session(self, obj):
        """Return upcoming BBB session info if exists"""
        if obj.upcoming_bbb_session:
            return {
                'id': obj.upcoming_bbb_session.id,
                'title': obj.upcoming_bbb_session.title,
                'scheduled_start': obj.upcoming_bbb_session.scheduled_start,
                'scheduled_end': obj.upcoming_bbb_session.scheduled_end,
                'status': obj.upcoming_bbb_session.status,
                'is_live_now': obj.upcoming_bbb_session.is_live_now,
                'is_upcoming': obj.upcoming_bbb_session.is_upcoming,
            }
        return None

# ADD THIS MISSING SERIALIZER
class ChatParticipantSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    chat_room = ChatRoomSerializer(read_only=True)
    
    class Meta:
        model = ChatParticipant
        fields = ('id', 'user', 'chat_room', 'role', 'joined_at', 
                 'last_read_at', 'is_muted', 'notifications_enabled')

class MessageSerializer(serializers.ModelSerializer):
    sender = UserSerializer(read_only=True)
    receiver = UserSerializer(read_only=True)
    receiver_id = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.all(), source='receiver', write_only=True, required=False
    )
    reply_to = serializers.PrimaryKeyRelatedField(
        queryset=Message.objects.all(),
        required=False, allow_null=True,
    )
    bbb_session = serializers.SerializerMethodField()

    class Meta:
        model = Message
        fields = ('id', 'socket_message_id', 'sender', 'receiver', 'receiver_id',
                 'chat_room', 'message', 'message_type', 'attachments',
                 'metadata', 'reply_to', 'is_edited', 'is_deleted',
                 'course_app', 'course_model', 'course_id', 'course_title',
                 'type', 'seen', 'bbb_session', 'created_at', 'updated_at')
        read_only_fields = ('socket_message_id', 'created_at', 'updated_at')

    def get_bbb_session(self, obj):
        """Return BBB session info if message is linked to a session"""
        if obj.bbb_session:
            return {
                'id': obj.bbb_session.id,
                'title': obj.bbb_session.title,
                'scheduled_start': obj.bbb_session.scheduled_start,
                'scheduled_end': obj.bbb_session.scheduled_end,
                'status': obj.bbb_session.status,
                'is_live_now': obj.bbb_session.is_live_now,
                'is_upcoming': obj.bbb_session.is_upcoming,
            }
        return None

class UserPresenceSerializer(serializers.ModelSerializer):
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = UserPresence
        fields = ('user', 'status', 'last_seen', 'custom_status')

class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = ('id', 'user', 'notification_type', 'title', 
                 'message', 'is_read', 'related_message', 
                 'metadata', 'created_at')

class CreateChatRoomSerializer(serializers.Serializer):
    user_id = serializers.IntegerField(required=True)
    room_name = serializers.CharField(required=False, allow_blank=True)