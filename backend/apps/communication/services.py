"""
Chat Room Service
Auto-creates and manages 1-on-1 chat rooms between instructors and students
"""

from django.db import transaction
from django.contrib.auth import get_user_model
from apps.communication.models import ChatRoom, ChatParticipant

User = get_user_model()


class ChatRoomService:
    """Service for managing instructor-student chat rooms"""

    @staticmethod
    @transaction.atomic
    def get_or_create_instructor_student_chat(instructor, student):
        """
        Get or create a 1-on-1 chat room between instructor and student

        Args:
            instructor: User instance (instructor/facilitator)
            student: User instance (student)

        Returns:
            ChatRoom instance
        """
        # Check if chat room already exists - both users must be participants
        existing_rooms = ChatRoom.objects.filter(
            participants__user=instructor,
            chat_type='one_on_one'
        ).filter(
            participants__user=student
        )
        existing_room = existing_rooms.first()

        if existing_room:
            return existing_room

        # Create new chat room
        room = ChatRoom.objects.create(
            id=f'direct_{instructor.id}_{student.id}',
            chat_type='one_on_one',
            name=f'{instructor.first_name} {instructor.last_name} & {student.first_name} {student.last_name}',
        )

        # Add participants
        ChatParticipant.objects.create(
            chat_room=room,
            user=instructor,
            role='instructor'
        )

        ChatParticipant.objects.create(
            chat_room=room,
            user=student,
            role='student'
        )

        return room

    @staticmethod
    @transaction.atomic
    def ensure_chat_rooms_for_instructor(instructor, students):
        """
        Ensure chat rooms exist between instructor and all their students

        Args:
            instructor: User instance (instructor/facilitator)
            students: QuerySet or list of User instances (students)

        Returns:
            Number of chat rooms created
        """
        created_count = 0
        
        for student in students:
            try:
                ChatRoomService.get_or_create_instructor_student_chat(
                    instructor=instructor,
                    student=student
                )
                created_count += 1
            except Exception as e:
                print(f"Failed to create chat room for {student.email}: {e}")
        
        return created_count

    @staticmethod
    @transaction.atomic
    def ensure_chat_rooms_for_course(instructor, course, course_type='course'):
        """
        Ensure chat rooms exist between instructor and all students enrolled in a course

        Args:
            instructor: User instance (instructor/facilitator)
            course: Course instance
            course_type: Type of course ('course', 'learnership', 'masterclass')

        Returns:
            Number of chat rooms created
        """
        from apps.payments.models import Enrollment
        from django.contrib.contenttypes.models import ContentType

        try:
            # Get all enrolled students
            ctype = ContentType.objects.get_for_model(course.__class__)
            enrollments = Enrollment.objects.filter(
                content_type=ctype,
                object_id=course.id,
                status='enrolled'
            ).select_related('user')

            students = [e.user for e in enrollments]

            return ChatRoomService.ensure_chat_rooms_for_instructor(
                instructor=instructor,
                students=students
            )
        except Exception as e:
            print(f"Failed to ensure chat rooms for course {course.id}: {e}")
            return 0

    @staticmethod
    def get_instructor_chat_rooms(instructor):
        """
        Get all chat rooms for an instructor with their students

        Args:
            instructor: User instance

        Returns:
            QuerySet of ChatRoom instances
        """
        return ChatRoom.objects.filter(
            participants__user=instructor,
            chat_type='one_on_one'
        ).prefetch_related(
            'participants__user',
            'last_message'
        )

    @staticmethod
    def get_student_chat_rooms(student):
        """
        Get all chat rooms for a student with their instructors

        Args:
            student: User instance

        Returns:
            QuerySet of ChatRoom instances
        """
        return ChatRoom.objects.filter(
            participants__user=student,
            chat_type='one_on_one'
        ).prefetch_related(
            'participants__user',
            'last_message'
        )

    @staticmethod
    def get_chat_messages_with_user(user, other_user):
        """
        Get chat room and messages between two users

        Args:
            user: User instance
            other_user: User instance

        Returns:
            Tuple of (ChatRoom, messages)
        """
        room = ChatRoom.objects.filter(
            participants__user=user,
            chat_type='one_on_one'
        ).filter(
            participants__user=other_user
        ).first()

        if not room:
            return None, []

        messages = room.messages.select_related(
            'sender',
            'receiver'
        ).order_by('created_at')

        return room, messages
