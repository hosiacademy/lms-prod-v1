from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AiCertsCourseViewSet

router = DefaultRouter()
router.register(r'courses', AiCertsCourseViewSet, basename='aicerts-course')

urlpatterns = [
    path('', include(router.urls)),
]
