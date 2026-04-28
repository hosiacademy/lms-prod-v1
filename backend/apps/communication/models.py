# apps/communication/models.py
from django.db import models
from django.utils.translation import gettext_lazy as _
from django.contrib.contenttypes.models import ContentType
from django.contrib.contenttypes.fields import GenericForeignKey
from django.utils import timezone
from django.contrib.auth import get_user_model

User = get_user_model()


class Message(models.Model):
    """
    Private and system messaging system with Socket.io integration.
    Supports:
    - 1-on-1 direct messaging (student ↔ instructor, peer ↔ peer)
    - Course-contextual conversations
    - System announcements (type=False)
    - Real-time chat via Socket.io
    """
    # Define constants for course types
    COURSE_TYPE_AICERTS = 'aicerts_courses'
    COURSE_TYPE_LEARNERSHIPS = 'learnerships'
    
    COURSE_TYPE_CHOICES = [
        (COURSE_TYPE_AICERTS, 'AI Certs Course'),
        (COURSE_TYPE_LEARNERSHIPS, 'Learnership'),
    ]

    sender = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='comm_sent_messages',
        verbose_name=_("Sender")
    )
    receiver = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='comm_received_messages',
        verbose_name=_("Receiver")
    )
    
    # Course reference - store app label and model name
    course_app = models.CharField(
        max_length=50,
        choices=COURSE_TYPE_CHOICES,
        blank=True,
        null=True,
        verbose_name=_("Course App"),
        help_text=_("Which app contains this course (aicerts_courses or learnerships)")
    )
    course_model = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("Course Model"),
        help_text=_("Model name (e.g., 'Course', 'Learnership')")
    )
    course_id = models.BigIntegerField(
        blank=True, null=True,
        verbose_name=_("Course ID"),
        help_text=_("ID of the course object")
    )
    
    course_title = models.CharField(
        max_length=255, blank=True, null=True,
        verbose_name=_("Course Title"),
        help_text=_("Human-friendly title of the course, if available")
    )

    message = models.TextField(
        verbose_name=_("Message Content"),
        help_text=_("Supports plain text. Future: rich text, voice notes, attachments")
    )
    
    # Socket.io chat integration fields
    chat_room = models.ForeignKey(
        'ChatRoom',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='messages',
        verbose_name=_("Chat Room"),
        help_text=_("Socket.io chat room reference")
    )
    
    # Message types for Socket.io
    MESSAGE_TYPES = [
        ('text', _('Text')),
        ('image', _('Image')),
        ('file', _('File')),
        ('audio', _('Audio')),
        ('video', _('Video')),
        ('announcement', _('Announcement')),
        ('system', _('System')),
        ('poll', _('Poll')),
    ]
    
    message_type = models.CharField(
        max_length=20,
        choices=MESSAGE_TYPES,
        default='text',
        verbose_name=_("Message Type"),
        help_text=_("Type of message for Socket.io chat")
    )
    
    # Real-time chat fields
    socket_message_id = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        unique=True,
        verbose_name=_("Socket Message ID"),
        help_text=_("Unique ID from Socket.io for real-time syncing")
    )
    
    is_edited = models.BooleanField(
        default=False,
        verbose_name=_("Edited"),
        help_text=_("Has this message been edited?")
    )
    
    is_deleted = models.BooleanField(
        default=False,
        verbose_name=_("Deleted"),
        help_text=_("Is this message deleted?")
    )
    
    reply_to = models.ForeignKey(
        'self',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='replies',
        verbose_name=_("Reply To"),
        help_text=_("Message this is replying to")
    )
    
    attachments = models.JSONField(
        default=list,
        blank=True,
        verbose_name=_("Attachments"),
        help_text=_("JSON array of attachment URLs/metadata")
    )
    
    metadata = models.JSONField(
        default=dict,
        blank=True,
        verbose_name=_("Metadata"),
        help_text=_("Additional message metadata")
    )

    # BBB Session Integration
    bbb_session = models.ForeignKey(
        'bbb_integration.LiveSession',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='chat_messages',
        verbose_name=_("BBB Session"),
        help_text=_("Linked BBB live session for session announcements and reminders")
    )

    type = models.BooleanField(
        default=True,
        verbose_name=_("Message Type"),
        help_text=_("True = Direct user-to-user, False = System announcement/broadcast")
    )

    seen = models.BooleanField(
        default=False,
        verbose_name=_("Seen/Read"),
        help_text=_("Has the receiver read this message?")
    )

    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Sent At"))
    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))

    class Meta:
        db_table = 'communication_message'
        verbose_name = _("Message")
        verbose_name_plural = _("Messages")
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['sender']),
            models.Index(fields=['receiver']),
            models.Index(fields=['course_app', 'course_model', 'course_id']),
            models.Index(fields=['created_at']),
            models.Index(fields=['seen']),
            models.Index(fields=['chat_room', 'created_at']),
            models.Index(fields=['socket_message_id']),
            models.Index(fields=['message_type']),
        ]

    def __str__(self):
        sender_name = self.sender.name or self.sender.username or self.sender.email
        receiver_name = self.receiver.name or self.receiver.username or self.receiver.email
        
        # Get course title
        if self.course_title:
            course_title = f" [{self.course_title}]"
        elif self.course_id and self.course_app and self.course_model:
            course_title = f" [{self.get_course_display_name()}]"
        else:
            course_title = ""
            
        preview = (self.message[:50] + '...') if len(self.message) > 50 else self.message
        
        # Add chat room info if available
        if self.chat_room:
            return f"{sender_name} → {receiver_name}{course_title} ({self.chat_room.name}): {preview}"
        return f"{sender_name} → {receiver_name}{course_title}: {preview}"

    # Helper methods to get course object
    def get_course_object(self):
        """Return the actual course object if it exists"""
        if not self.course_id or not self.course_app or not self.course_model:
            return None
            
        try:
            if self.course_app == self.COURSE_TYPE_AICERTS:
                from apps.aicerts_courses.models import AiCertsCourse
                model_class = AiCertsCourse
            elif self.course_app == self.COURSE_TYPE_LEARNERSHIPS:
                from apps.learnerships.models import Learnership
                model_class = Learnership
            else:
                return None
            
            return model_class.objects.filter(id=self.course_id).first()
            
        except (ImportError, AttributeError):
            return None

    def get_course_display_name(self):
        """Get display name for the course"""
        if self.course_title:
            return self.course_title
            
        course_obj = self.get_course_object()
        if course_obj:
            # Try different possible attribute names for title
            for attr in ['title', 'name', 'fullname', '__str__']:
                if hasattr(course_obj, attr):
                    value = getattr(course_obj, attr)
                    if callable(value):
                        value = value()
                    if value:
                        return str(value)
        return f"Course {self.course_id}"

    def save(self, *args, **kwargs):
        """Auto-populate course_title if not provided"""
        if self.course_id and self.course_app and self.course_model and not self.course_title:
            self.course_title = self.get_course_display_name()
        super().save(*args, **kwargs)

    # Helper properties
    @property
    def is_direct(self):
        return self.type

    @property
    def is_announcement(self):
        return not self.type

    @property
    def is_unread(self):
        return not self.seen

    @property
    def course(self):
        """Property alias for backward compatibility"""
        return self.get_course_object()

    def mark_as_seen(self):
        if not self.seen:
            self.seen = True
            self.save(update_fields=['seen', 'updated_at'])

    @classmethod
    def set_course_reference(cls, course_obj):
        """Helper to extract app/model info from a course object"""
        if hasattr(course_obj, '_meta'):
            app_label = course_obj._meta.app_label
            model_name = course_obj._meta.model_name
            
            # Map app labels to our choices
            if app_label == 'aicerts_courses':
                course_app = cls.COURSE_TYPE_AICERTS
            elif app_label == 'learnerships':
                course_app = cls.COURSE_TYPE_LEARNERSHIPS
            else:
                course_app = app_label
                
            return {
                'course_app': course_app,
                'course_model': model_name,
                'course_id': course_obj.id,
                'course_title': getattr(course_obj, 'title', 
                                      getattr(course_obj, 'name', str(course_obj)))
            }
        return None
    
    # Socket.io integration methods
    def to_socketio_format(self):
        """Convert message to Socket.io format"""
        return {
            'id': self.socket_message_id or f'msg_{self.id}',
            'chatId': self.chat_room.id if self.chat_room else f'direct_{self.sender.id}_{self.receiver.id}',
            'senderId': str(self.sender.id),
            'senderName': self.sender.name or self.sender.username,
            'content': self.message,
            'type': self.message_type,
            'timestamp': self.created_at.isoformat(),
            'isRead': self.seen,
            'isEdited': self.is_edited,
            'isDeleted': self.is_deleted,
            'attachments': self.attachments,
            'replyToId': str(self.reply_to.id) if self.reply_to else None,
            'metadata': {
                'course_app': self.course_app,
                'course_model': self.course_model,
                'course_id': str(self.course_id) if self.course_id else None,
                'course_title': self.course_title,
                'is_direct': self.is_direct,
                'is_announcement': self.is_announcement,
                'original_message_id': str(self.id),
            }
        }
    
    @classmethod
    def from_socketio_data(cls, data, user):
        """Create or update message from Socket.io data"""
        try:
            # Extract chat room info
            chat_id = data.get('chatId')
            chat_room = None
            if chat_id and not chat_id.startswith('direct_'):
                chat_room = ChatRoom.objects.filter(id=chat_id).first()
            
            # For direct messages, find receiver
            receiver = None
            if chat_id and chat_id.startswith('direct_'):
                parts = chat_id.split('_')
                if len(parts) == 3:
                    user1_id, user2_id = parts[1], parts[2]
                    receiver_id = user2_id if str(user.id) == user1_id else user1_id
                    receiver = User.objects.filter(id=receiver_id).first()
            
            # For chat room messages, determine receiver from room
            if chat_room:
                if chat_room.chat_type == 'one_on_one' and chat_room.participants.count() == 2:
                    receiver = chat_room.participants.exclude(user=user).first().user
            
            message_data = {
                'sender': user,
                'receiver': receiver,
                'message': data.get('content', ''),
                'message_type': data.get('type', 'text'),
                'socket_message_id': data.get('id'),
                'attachments': data.get('attachments', []),
                'metadata': data.get('metadata', {}),
                'chat_room': chat_room,
            }
            
            # Extract course info from metadata
            metadata = data.get('metadata', {})
            if metadata:
                message_data.update({
                    'course_app': metadata.get('course_app'),
                    'course_model': metadata.get('course_model'),
                    'course_id': metadata.get('course_id'),
                    'course_title': metadata.get('course_title'),
                })
            
            # Handle reply
            reply_to_id = data.get('replyToId')
            if reply_to_id:
                reply_message = cls.objects.filter(
                    socket_message_id=reply_to_id
                ).first()
                if reply_message:
                    message_data['reply_to'] = reply_message
            
            message, created = cls.objects.update_or_create(
                socket_message_id=data.get('id'),
                defaults=message_data
            )
            
            return message, created
            
        except Exception as e:
            print(f"Error creating message from Socket.io: {e}")
            return None, False


class ChatRoom(models.Model):
    """
    Socket.io chat room for real-time conversations
    """
    CHAT_TYPES = [
        ('one_on_one', _('Direct Message')),
        ('group', _('Group Chat')),
        ('course', _('Course Discussion')),
        ('community', _('Community')),
        ('announcement', _('Announcements')),
        ('support', _('Support')),
    ]
    
    id = models.CharField(max_length=100, primary_key=True)
    name = models.CharField(max_length=200, verbose_name=_("Room Name"))
    description = models.TextField(blank=True, null=True, verbose_name=_("Description"))
    chat_type = models.CharField(max_length=20, choices=CHAT_TYPES, default='group', verbose_name=_("Chat Type"))
    
    # Course reference (for course discussions)
    course_app = models.CharField(
        max_length=50,
        choices=Message.COURSE_TYPE_CHOICES,
        blank=True,
        null=True,
        verbose_name=_("Course App")
    )
    course_model = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("Course Model")
    )
    course_id = models.BigIntegerField(
        blank=True, null=True,
        verbose_name=_("Course ID")
    )
    course_title = models.CharField(
        max_length=255, blank=True, null=True,
        verbose_name=_("Course Title")
    )
    
    created_at = models.DateTimeField(default=timezone.now, verbose_name=_("Created At"))
    updated_at = models.DateTimeField(auto_now=True, verbose_name=_("Updated At"))
    is_archived = models.BooleanField(default=False, verbose_name=_("Archived"))
    is_muted = models.BooleanField(default=False, verbose_name=_("Muted"))
    settings = models.JSONField(default=dict, blank=True, verbose_name=_("Settings"))
    
    # Last message for quick reference
    last_message = models.ForeignKey(
        Message,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='last_in_room',
        verbose_name=_("Last Message")
    )

    # BBB Session Integration - Store upcoming session info
    upcoming_bbb_session = models.ForeignKey(
        'bbb_integration.LiveSession',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='chat_rooms',
        verbose_name=_("Upcoming BBB Session"),
        help_text=_("Next scheduled BBB session for this course")
    )
    bbb_session_info = models.JSONField(
        default=dict,
        blank=True,
        verbose_name=_("BBB Session Info"),
        help_text=_("Cached BBB session data for quick display")
    )

    class Meta:
        db_table = 'communication_chatroom'
        verbose_name = _("Chat Room")
        verbose_name_plural = _("Chat Rooms")
        ordering = ['-updated_at']
        indexes = [
            models.Index(fields=['course_app', 'course_model', 'course_id']),
            models.Index(fields=['chat_type']),
            models.Index(fields=['created_at']),
        ]
    
    def __str__(self):
        if self.course_title:
            return f"{self.name} ({self.course_title})"
        return self.name
    
    def get_course_object(self):
        """Return the actual course object if it exists"""
        if not self.course_id or not self.course_app or not self.course_model:
            return None
            
        try:
            if self.course_app == Message.COURSE_TYPE_AICERTS:
                from apps.aicerts_courses.models import AiCertsCourse
                model_class = AiCertsCourse
            elif self.course_app == Message.COURSE_TYPE_LEARNERSHIPS:
                from apps.learnerships.models import Learnership
                model_class = Learnership
            else:
                return None
            
            return model_class.objects.filter(id=self.course_id).first()
            
        except (ImportError, AttributeError):
            return None
    
    @property
    def course(self):
        """Property alias for backward compatibility"""
        return self.get_course_object()
    
    def get_participants(self):
        """Get all participants in this room"""
        return User.objects.filter(
            id__in=self.participants.values_list('user_id', flat=True)
        )
    
    def add_participant(self, user, role='member'):
        """Add a participant to the chat room"""
        ChatParticipant.objects.get_or_create(
            chat_room=self,
            user=user,
            defaults={'role': role}
        )
    
    def remove_participant(self, user):
        """Remove a participant from the chat room"""
        ChatParticipant.objects.filter(chat_room=self, user=user).delete()
    
    def update_last_message(self, message):
        """Update the last message reference"""
        self.last_message = message
        self.save(update_fields=['last_message', 'updated_at'])
    
    def to_socketio_format(self):
        """Convert chat room to Socket.io format"""
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'type': self.chat_type,
            'courseId': str(self.course_id) if self.course_id else None,
            'courseTitle': self.course_title,
            'createdAt': self.created_at.isoformat(),
            'updatedAt': self.updated_at.isoformat(),
            'lastMessage': self.last_message.to_socketio_format() if self.last_message else None,
            'participantCount': self.participants.count(),
            'unreadCount': self.get_unread_count(),
            'settings': self.settings,
        }
    
    def get_unread_count(self):
        """Get count of unread messages for a specific user (placeholder)"""
        # This would need user context to calculate properly
        return 0


class ChatParticipant(models.Model):
    """
    Users participating in chat rooms
    """
    ROLE_CHOICES = [
        ('admin', _('Admin')),
        ('moderator', _('Moderator')),
        ('member', _('Member')),
        ('instructor', _('Instructor')),
        ('facilitator', _('Facilitator')),
        ('learner', _('Learner')),
    ]
    
    chat_room = models.ForeignKey(
        ChatRoom,
        on_delete=models.CASCADE,
        related_name='participants',
        verbose_name=_("Chat Room")
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        verbose_name=_("User")
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='member', verbose_name=_("Role"))
    joined_at = models.DateTimeField(default=timezone.now, verbose_name=_("Joined At"))
    last_read_at = models.DateTimeField(default=timezone.now, verbose_name=_("Last Read At"))
    is_muted = models.BooleanField(default=False, verbose_name=_("Muted"))
    notifications_enabled = models.BooleanField(default=True, verbose_name=_("Notifications Enabled"))
    
    class Meta:
        db_table = 'communication_chatparticipant'
        verbose_name = _("Chat Participant")
        verbose_name_plural = _("Chat Participants")
        unique_together = ['chat_room', 'user']
        indexes = [
            models.Index(fields=['user', 'chat_room']),
        ]
    
    def __str__(self):
        return f"{self.user.username} in {self.chat_room.name}"
    
    def update_last_read(self):
        """Update when user last read messages in this room"""
        self.last_read_at = timezone.now()
        self.save(update_fields=['last_read_at'])


class UserPresence(models.Model):
    """
    Track user online status for Socket.io
    """
    STATUS_CHOICES = [
        ('online', _('Online')),
        ('offline', _('Offline')),
        ('away', _('Away')),
        ('busy', _('Busy')),
        ('invisible', _('Invisible')),
    ]
    
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        primary_key=True,
        verbose_name=_("User")
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='offline',
        verbose_name=_("Status")
    )
    last_seen = models.DateTimeField(default=timezone.now, verbose_name=_("Last Seen"))
    socket_id = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        verbose_name=_("Socket ID")
    )
    device_info = models.JSONField(
        default=dict,
        blank=True,
        verbose_name=_("Device Info")
    )
    custom_status = models.CharField(
        max_length=100,
        blank=True,
        null=True,
        verbose_name=_("Custom Status")
    )
    
    class Meta:
        db_table = 'communication_userpresence'
        verbose_name = _("User Presence")
        verbose_name_plural = _("User Presences")
    
    def __str__(self):
        return f"{self.user.username}: {self.status}"
    
    def is_online(self):
        return self.status == 'online'
    
    def update_last_seen(self):
        """Update last seen timestamp"""
        self.last_seen = timezone.now()
        self.save(update_fields=['last_seen'])
    
    def to_socketio_format(self):
        """Convert presence to Socket.io format"""
        return {
            'userId': str(self.user.id),
            'username': self.user.username,
            'status': self.status,
            'lastSeen': self.last_seen.isoformat(),
            'customStatus': self.custom_status,
        }


class MessageReadReceipt(models.Model):
    """
    Track when users read messages
    """
    message = models.ForeignKey(
        Message,
        on_delete=models.CASCADE,
        verbose_name=_("Message")
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        verbose_name=_("User")
    )
    read_at = models.DateTimeField(default=timezone.now, verbose_name=_("Read At"))
    
    class Meta:
        db_table = 'communication_messagereadreceipt'
        verbose_name = _("Message Read Receipt")
        verbose_name_plural = _("Message Read Receipts")
        unique_together = ['message', 'user']
        indexes = [
            models.Index(fields=['message', 'user']),
            models.Index(fields=['read_at']),
        ]
    
    def __str__(self):
        return f"{self.user.username} read message {self.message.id}"


class Notification(models.Model):
    """
    System notifications (extends existing notifications app)
    """
    NOTIFICATION_TYPES = [
        ('message', _('New Message')),
        ('announcement', _('Announcement')),
        ('course_update', _('Course Update')),
        ('assignment', _('Assignment')),
        ('grade', _('Grade')),
        ('system', _('System')),
    ]
    
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='notifications',
        verbose_name=_("User")
    )
    notification_type = models.CharField(
        max_length=20,
        choices=NOTIFICATION_TYPES,
        default='system',
        verbose_name=_("Notification Type")
    )
    title = models.CharField(max_length=200, verbose_name=_("Title"))
    message = models.TextField(verbose_name=_("Message"))
    is_read = models.BooleanField(default=False, verbose_name=_("Read"))
    related_message = models.ForeignKey(
        Message,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        verbose_name=_("Related Message")
    )
    metadata = models.JSONField(default=dict, blank=True, verbose_name=_("Metadata"))
    created_at = models.DateTimeField(auto_now_add=True, verbose_name=_("Created At"))
    
    class Meta:
        db_table = 'communication_notification'
        verbose_name = _("Notification")
        verbose_name_plural = _("Notifications")
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'is_read']),
            models.Index(fields=['created_at']),
            models.Index(fields=['notification_type']),
        ]
    
    def __str__(self):
        return f"{self.user.username}: {self.title}"
    
    def mark_as_read(self):
        if not self.is_read:
            self.is_read = True
            self.save(update_fields=['is_read'])
    
    def to_socketio_format(self):
        """Convert notification to Socket.io format"""
        return {
            'id': str(self.id),
            'type': self.notification_type,
            'title': self.title,
            'message': self.message,
            'isRead': self.is_read,
            'createdAt': self.created_at.isoformat(),
            'metadata': self.metadata,
        }