from django.core.management.base import BaseCommand
from apps.communication.services import ChatRoomService

class Command(BaseCommand):
    help = 'Initialize system-wide chat rooms'

    def handle(self, *args, **options):
        self.stdout.write('Initializing system chat rooms...')
        community, staff = ChatRoomService.ensure_system_rooms()
        self.stdout.write(self.style.SUCCESS(f'Successfully initialized rooms: "{community.name}" and "{staff.name}"'))
