# apps/communication/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    ChatRoomViewSet, MessageViewSet,
    UserPresenceViewSet, NotificationViewSet
)

router = DefaultRouter()
router.register(r'chat-rooms', ChatRoomViewSet, basename='chatroom')
router.register(r'messages', MessageViewSet, basename='message')
router.register(r'presence', UserPresenceViewSet, basename='presence')
router.register(r'notifications', NotificationViewSet, basename='notification')

urlpatterns = [
    path('api/', include(router.urls)),
    # Optional: Add WebSocket connection endpoint
    # path('ws/', views.socket_connect, name='socket-connect'),
]