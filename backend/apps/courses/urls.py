# apps/courses/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import CourseProviderViewSet

router = DefaultRouter()
router.register(r'providers', CourseProviderViewSet, basename='course-provider')

urlpatterns = [
    path('', include(router.urls)),
]
