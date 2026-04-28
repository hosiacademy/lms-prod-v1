from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'lessons', views.VideoLessonViewSet, basename='video-lesson')

urlpatterns = [
    path('', include(router.urls)),
]
