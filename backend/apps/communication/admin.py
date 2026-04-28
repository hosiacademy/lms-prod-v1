# apps/communication/admin.py
from django.contrib import admin
from .models import (
    Message, ChatRoom, ChatParticipant, 
    UserPresence, MessageReadReceipt, Notification
)

@admin.register(ChatRoom)
class ChatRoomAdmin(admin.ModelAdmin):
    list_display = ('id', 'name', 'chat_type', 'course_title', 'created_at', 'participant_count')
    list_filter = ('chat_type', 'course_app', 'created_at')
    search_fields = ('name', 'description', 'course_title')
    readonly_fields = ('id', 'created_at', 'updated_at')
    
    def participant_count(self, obj):
        return obj.participants.count()
    participant_count.short_description = 'Participants'

@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ('id', 'short_message', 'sender', 'receiver', 'message_type', 'chat_room', 'created_at', 'seen')
    list_filter = ('message_type', 'seen', 'created_at', 'chat_room')
    search_fields = ('message', 'sender__username', 'receiver__username')
    readonly_fields = ('created_at', 'updated_at', 'socket_message_id')
    
    def short_message(self, obj):
        return obj.message[:50] + '...' if len(obj.message) > 50 else obj.message
    short_message.short_description = 'Message'

@admin.register(UserPresence)
class UserPresenceAdmin(admin.ModelAdmin):
    list_display = ('user', 'status', 'last_seen', 'is_online')
    list_filter = ('status', 'last_seen')
    search_fields = ('user__username', 'user__email')
    readonly_fields = ('last_seen',)
    
    def is_online(self, obj):
        return obj.status == 'online'
    is_online.boolean = True
    is_online.short_description = 'Online'

@admin.register(ChatParticipant)
class ChatParticipantAdmin(admin.ModelAdmin):
    list_display = ('user', 'chat_room', 'role', 'joined_at', 'last_read_at')
    list_filter = ('role', 'joined_at')
    search_fields = ('user__username', 'chat_room__name')

@admin.register(Notification)
class NotificationAdmin(admin.ModelAdmin):
    list_display = ('user', 'title', 'notification_type', 'is_read', 'created_at')
    list_filter = ('notification_type', 'is_read', 'created_at')
    search_fields = ('title', 'message', 'user__username')

@admin.register(MessageReadReceipt)
class MessageReadReceiptAdmin(admin.ModelAdmin):
    list_display = ('user', 'message', 'read_at')
    list_filter = ('read_at',)
    search_fields = ('user__username', 'message__message')