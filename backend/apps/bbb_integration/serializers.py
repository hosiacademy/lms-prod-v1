"""
BigBlueButton API Serializers
Serializers for REST API endpoints
"""

from rest_framework import serializers
from .models import LiveSession, SessionRecording, SessionAttendance, BBBServer, SessionInvitation


class InstructorSerializer(serializers.Serializer):
    """Nested serializer for instructor information"""
    id = serializers.IntegerField()
    email = serializers.EmailField()
    first_name = serializers.CharField()
    last_name = serializers.CharField()
    full_name = serializers.SerializerMethodField()

    def get_full_name(self, obj):
        """Get instructor full name"""
        return obj.get_full_name() if hasattr(obj, 'get_full_name') else f"{obj.first_name} {obj.last_name}"


class BBBServerSerializer(serializers.ModelSerializer):
    """BBB Server information"""
    load_percentage = serializers.ReadOnlyField()

    class Meta:
        model = BBBServer
        fields = ['id', 'name', 'api_url', 'is_active', 'current_load', 'max_load', 'load_percentage']
        read_only_fields = ['id', 'current_load', 'load_percentage']


class LiveSessionSerializer(serializers.ModelSerializer):
    """
    Full live session serializer for GET requests
    Includes all session details with nested relationships
    """
    instructor = InstructorSerializer(read_only=True)
    bbb_server = BBBServerSerializer(read_only=True)
    duration_minutes = serializers.ReadOnlyField()
    is_upcoming = serializers.ReadOnlyField()
    is_live_now = serializers.ReadOnlyField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    attendee_count = serializers.SerializerMethodField()
    recording_count = serializers.SerializerMethodField()

    class Meta:
        model = LiveSession
        fields = [
            'id',
            'session_id',
            'meeting_id',
            'course_id',
            'course_type',
            'phase_id',
            'cohort_info',
            'instructor',
            'title',
            'description',
            'scheduled_start',
            'scheduled_end',
            'actual_start',
            'actual_end',
            'status',
            'status_display',
            'bbb_server',
            'record',
            'auto_start_recording',
            'allow_start_stop_recording',
            'max_participants',
            'has_recording',
            'welcome_message',
            'logout_url',
            'duration_minutes',
            'is_upcoming',
            'is_live_now',
            'attendee_count',
            'recording_count',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'session_id',
            'meeting_id',
            'moderator_password',
            'attendee_password',
            'actual_start',
            'actual_end',
            'has_recording',
            'created_at',
            'updated_at',
        ]

    def get_attendee_count(self, obj):
        """Get number of attendees"""
        return obj.attendances.count()

    def get_recording_count(self, obj):
        """Get number of recordings"""
        return obj.recordings.count()


class LiveSessionCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating live sessions.
    Supports learnership phase context and cohort metadata.
    """
    course_title = serializers.SerializerMethodField(read_only=True)
    enrolled_students = serializers.SerializerMethodField(read_only=True)
    student_count = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = LiveSession
        fields = [
            'course_id',
            'course_type',
            'phase_id',
            'cohort_info',
            'title',
            'description',
            'scheduled_start',
            'scheduled_end',
            'record',
            'auto_start_recording',
            'allow_start_stop_recording',
            'max_participants',
            'welcome_message',
            'logout_url',
            # Read-only fields for display
            'course_title',
            'enrolled_students',
            'student_count',
        ]

    def get_course_title(self, obj):
        """Get course title based on course type"""
        # Will be used in response, not during creation
        return None

    def get_enrolled_students(self, obj):
        """Get list of enrolled students"""
        return []

    def get_student_count(self, obj):
        """Get count of enrolled students"""
        return 0

    def validate(self, data):
        """Validate session creation data"""
        # Validate scheduled times
        if data['scheduled_start'] >= data['scheduled_end']:
            raise serializers.ValidationError({
                'scheduled_end': 'Scheduled end time must be after start time'
            })

        # Validate course type
        valid_course_types = ['course', 'masterclass', 'learnership', 'industry_training']
        if data.get('course_type') not in valid_course_types:
            raise serializers.ValidationError({
                'course_type': f'Course type must be one of: {", ".join(valid_course_types)}'
            })

        # Validate max participants
        if data.get('max_participants', 0) < 1:
            raise serializers.ValidationError({
                'max_participants': 'Max participants must be at least 1'
            })

        return data

    def create(self, validated_data):
        """Create session with auto-selected BBB server"""
        from .services import BBBService

        # Select best available BBB server
        try:
            bbb_service = BBBService()
            validated_data['bbb_server'] = bbb_service.server
        except ValueError as e:
            raise serializers.ValidationError({'bbb_server': str(e)})

        # Instructor will be set by the view (perform_create)
        return super().create(validated_data)


class SessionRecordingSerializer(serializers.ModelSerializer):
    """
    Session recording serializer
    Includes playback information and metadata
    """
    session_title = serializers.CharField(source='session.title', read_only=True)
    session_id = serializers.CharField(source='session.session_id', read_only=True)
    instructor_name = serializers.SerializerMethodField()
    size_mb = serializers.ReadOnlyField()

    class Meta:
        model = SessionRecording
        fields = [
            'id',
            'record_id',
            'session',
            'session_id',
            'session_title',
            'instructor_name',
            'name',
            'published',
            'start_time',
            'end_time',
            'duration_minutes',
            'playback_url',
            'playback_format',
            'size_bytes',
            'size_mb',
            'thumbnail_url',
            'metadata',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'record_id',
            'session',
            'start_time',
            'end_time',
            'duration_minutes',
            'playback_url',
            'playback_format',
            'size_bytes',
            'thumbnail_url',
            'created_at',
            'updated_at',
        ]

    def get_instructor_name(self, obj):
        """Get instructor full name"""
        instructor = obj.session.instructor
        return instructor.get_full_name() if hasattr(instructor, 'get_full_name') else instructor.email


class SessionAttendanceSerializer(serializers.ModelSerializer):
    """
    Session attendance serializer
    Tracks who joined sessions and for how long
    """
    user_email = serializers.EmailField(source='user.email', read_only=True)
    user_name = serializers.SerializerMethodField()
    session_title = serializers.CharField(source='session.title', read_only=True)
    role = serializers.SerializerMethodField()
    status = serializers.SerializerMethodField()

    class Meta:
        model = SessionAttendance
        fields = [
            'id',
            'session',
            'session_title',
            'user',
            'user_email',
            'user_name',
            'joined_at',
            'left_at',
            'duration_minutes',
            'joined_as_moderator',
            'role',
            'status',
        ]
        read_only_fields = [
            'id',
            'session',
            'user',
            'joined_at',
            'left_at',
            'duration_minutes',
        ]

    def get_user_name(self, obj):
        """Get user full name"""
        return obj.user.get_full_name() if hasattr(obj.user, 'get_full_name') else obj.user.email

    def get_role(self, obj):
        """Get user role in session"""
        return 'Moderator' if obj.joined_as_moderator else 'Attendee'

    def get_status(self, obj):
        """Get attendance status"""
        return 'Left' if obj.left_at else 'Active'


class SessionStartSerializer(serializers.Serializer):
    """Serializer for session start response"""
    message = serializers.CharField()
    session_id = serializers.CharField()
    meeting_id = serializers.CharField()
    join_url = serializers.URLField()
    status = serializers.CharField()


class SessionEndSerializer(serializers.Serializer):
    """Serializer for session end response"""
    message = serializers.CharField()
    session_id = serializers.CharField()
    status = serializers.CharField()
    has_recording = serializers.BooleanField()


class SessionJoinSerializer(serializers.Serializer):
    """Serializer for session join response"""
    join_url = serializers.URLField()
    session_id = serializers.CharField()
    role = serializers.CharField()


class SessionInvitationSerializer(serializers.ModelSerializer):
    """Serializer for session invitations"""
    session_title = serializers.CharField(source='session.title', read_only=True)
    session_start = serializers.DateTimeField(source='session.scheduled_start', read_only=True)
    instructor_name = serializers.SerializerMethodField()
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = SessionInvitation
        fields = [
            'id',
            'session',
            'session_title',
            'session_start',
            'instructor_name',
            'email',
            'student_name',
            'status',
            'status_display',
            'invitation_token',
            'sent_at',
            'opened_at',
            'joined_at',
            'chat_invitation_sent',
            'chat_invitation_accepted',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'id',
            'invitation_token',
            'sent_at',
            'opened_at',
            'joined_at',
        ]

    def get_instructor_name(self, obj):
        """Get instructor full name"""
        instructor = obj.session.instructor
        return instructor.get_full_name() if hasattr(instructor, 'get_full_name') else instructor.email


class StudentInviteSerializer(serializers.Serializer):
    """Serializer for inviting a student to a session"""
    email = serializers.EmailField()
    name = serializers.CharField(max_length=255)
    send_chat_invite = serializers.BooleanField(default=True, required=False)


class BulkStudentInviteSerializer(serializers.Serializer):
    """Serializer for bulk inviting students"""
    students = serializers.ListField(
        child=serializers.DictField(),
        allow_empty=False,
    )
    send_chat_invite = serializers.BooleanField(default=True, required=False)

    def validate(self, data):
        """Validate student data"""
        students = data.get('students', [])
        for i, student in enumerate(students):
            if 'email' not in student:
                raise serializers.ValidationError({
                    'students': f'Student {i + 1} is missing email address'
                })
            if 'name' not in student:
                raise serializers.ValidationError({
                    'students': f'Student {i + 1} is missing name'
                })
        return data
