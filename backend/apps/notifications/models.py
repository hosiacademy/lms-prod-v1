from django.db import models
from django.utils.translation import gettext_lazy as _


class Notification(models.Model):
    """
    User notifications system.
    Supports notifications related to both AICerts courses and Learnerships.
    """
    # Define constants for course types (matching communication app)
    COURSE_TYPE_AICERTS = 'aicerts_courses'
    COURSE_TYPE_LEARNERSHIPS = 'learnerships'
    
    COURSE_TYPE_CHOICES = [
        (COURSE_TYPE_AICERTS, 'AI Certs Course'),
        (COURSE_TYPE_LEARNERSHIPS, 'Learnership'),
    ]

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

    user = models.ForeignKey(
        'users.User', 
        on_delete=models.CASCADE, 
        verbose_name=_("User"),
        help_text=_("User receiving the notification")
    )
    
    author = models.ForeignKey(
        'users.User', 
        on_delete=models.CASCADE, 
        related_name='authored_notifications',
        blank=True, 
        null=True,
        verbose_name=_("Author"),
        help_text=_("User who triggered the notification")
    )
    
    message_id = models.IntegerField(
        blank=True, 
        null=True,
        verbose_name=_("Message ID"),
        help_text=_("Related message ID from communication app")
    )
    
    course_comment = models.IntegerField(
        blank=True, 
        null=True,
        verbose_name=_("Course Comment ID"),
        help_text=_("ID of a course comment")
    )
    
    course_review = models.IntegerField(
        blank=True, 
        null=True,
        verbose_name=_("Course Review ID"),
        help_text=_("ID of a course review")
    )
    
    course_enrolled = models.IntegerField(
        blank=True, 
        null=True,
        verbose_name=_("Course Enrollment ID"),
        help_text=_("ID of a course enrollment")
    )
    
    status = models.BooleanField(
        default=False,
        verbose_name=_("Read Status"),
        help_text=_("True = read, False = unread")
    )
    
    notification_type = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("Notification Type"),
        help_text=_("Type of notification: comment, review, enrollment, message, etc.")
    )
    
    title = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        verbose_name=_("Notification Title")
    )
    
    content = models.TextField(
        blank=True,
        null=True,
        verbose_name=_("Notification Content"),
        help_text=_("Full notification message/content")
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Created At")
    )
    
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_("Updated At")
    )

    class Meta:
        db_table = 'notifications'
        verbose_name = _("Notification")
        verbose_name_plural = _("Notifications")
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['course_app', 'course_model', 'course_id']),
            models.Index(fields=['created_at']),
            models.Index(fields=['notification_type']),
        ]

    def __str__(self):
        user_str = self.user.username if self.user else "Unknown"
        if self.title:
            return f"{self.title} - {user_str}"
        return f"Notification #{self.id} - {user_str}"

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

    @property
    def course(self):
        """Property alias for backward compatibility"""
        return self.get_course_object()

    def get_course_display_name(self):
        """Get display name for the course"""
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

    def mark_as_read(self):
        """Mark notification as read"""
        if not self.status:
            self.status = True
            self.save(update_fields=['status', 'updated_at'])

    def mark_as_unread(self):
        """Mark notification as unread"""
        if self.status:
            self.status = False
            self.save(update_fields=['status', 'updated_at'])

    @property
    def is_read(self):
        return self.status

    @property
    def is_unread(self):
        return not self.status

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
                'course_id': course_obj.id
            }
        return None


class ActivityLog(models.Model):
    """
    System activity logging for auditing and debugging.
    Compatible with both course systems.
    """
    log_name = models.CharField(
        max_length=191, 
        blank=True, 
        null=True,
        verbose_name=_("Log Name"),
        help_text=_("Category or name for this log entry")
    )
    
    description = models.TextField(
        verbose_name=_("Description"),
        help_text=_("Detailed description of the activity")
    )
    
    # Subject reference (what the activity is about)
    subject_app = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("Subject App"),
        help_text=_("App containing the subject (e.g., aicerts_courses, learnerships, users)")
    )
    subject_model = models.CharField(
        max_length=191, 
        blank=True, 
        null=True,
        verbose_name=_("Subject Model"),
        help_text=_("Model name of the subject")
    )
    subject_id = models.BigIntegerField(
        blank=True, 
        null=True,
        verbose_name=_("Subject ID"),
        help_text=_("ID of the subject object")
    )
    
    # Causer reference (who caused the activity)
    causer_app = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        verbose_name=_("Causer App"),
        help_text=_("App containing the causer (usually 'users')")
    )
    causer_model = models.CharField(
        max_length=191, 
        blank=True, 
        null=True,
        verbose_name=_("Causer Model"),
        help_text=_("Model name of the causer")
    )
    causer_id = models.BigIntegerField(
        blank=True, 
        null=True,
        verbose_name=_("Causer ID"),
        help_text=_("ID of the causer object (usually User ID)")
    )
    
    properties = models.JSONField(
        blank=True, 
        null=True,
        verbose_name=_("Properties"),
        help_text=_("Additional properties/metadata in JSON format")
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Created At")
    )
    
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_("Updated At")
    )

    class Meta:
        db_table = 'activity_log'
        verbose_name = _("Activity Log")
        verbose_name_plural = _("Activity Logs")
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['log_name']),
            models.Index(fields=['subject_app', 'subject_model', 'subject_id']),
            models.Index(fields=['causer_app', 'causer_model', 'causer_id']),
            models.Index(fields=['created_at']),
        ]

    def __str__(self):
        return f"{self.log_name or 'Activity'} - {self.description[:50]}..."

    def get_subject_object(self):
        """Get the subject object if references are available"""
        if not self.subject_id or not self.subject_app or not self.subject_model:
            return None
        
        try:
            from django.apps import apps
            model_class = apps.get_model(self.subject_app, self.subject_model)
            return model_class.objects.filter(id=self.subject_id).first()
        except (LookupError, ImportError):
            return None

    def get_causer_object(self):
        """Get the causer object if references are available"""
        if not self.causer_id or not self.causer_app or not self.causer_model:
            return None
        
        try:
            from django.apps import apps
            model_class = apps.get_model(self.causer_app, self.causer_model)
            return model_class.objects.filter(id=self.causer_id).first()
        except (LookupError, ImportError):
            return None


class Message(models.Model):
    """
    OBSOLETE: This model conflicts with the communication.Message model.
    Kept for backward compatibility during migration.
    Consider removing this model after migrating data.
    """
    sender = models.ForeignKey(
        'users.User', 
        on_delete=models.CASCADE, 
        blank=True, 
        null=True,
        verbose_name=_("Sender"),
        help_text=_("Message sender")
    )
    
    # Note: 'reciever' is misspelled in the original schema
    reciever = models.ForeignKey(
        'users.User', 
        on_delete=models.CASCADE, 
        related_name='legacy_received_messages',  # Changed to avoid conflict
        blank=True, 
        null=True,
        verbose_name=_("Receiver"),
        help_text=_("Message receiver")
    )
    
    message = models.TextField(
        verbose_name=_("Message Content")
    )
    
    type = models.BooleanField(
        default=True,
        verbose_name=_("Message Type"),
        help_text=_("True = user message, False = system message")
    )
    
    seen = models.BooleanField(
        default=False,
        verbose_name=_("Seen Status")
    )
    
    created_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Created At")
    )
    
    updated_at = models.DateTimeField(
        auto_now=True,
        verbose_name=_("Updated At")
    )

    class Meta:
        db_table = 'messages'
        verbose_name = _("Legacy Message")
        verbose_name_plural = _("Legacy Messages")
        ordering = ['-created_at']

    def __str__(self):
        sender_name = self.sender.username if self.sender else "Unknown"
        receiver_name = self.reciever.username if self.reciever else "Unknown"
        preview = self.message[:50] + '...' if len(self.message) > 50 else self.message
        return f"{sender_name} → {receiver_name}: {preview}"