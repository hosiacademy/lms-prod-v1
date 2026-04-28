# apps/analytics/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    PlatformAnalyticsViewSet, 
    CourseAnalyticsViewSet, 
    LearnershipAnalyticsViewSet, 
    UserProgressViewSet
)

router = DefaultRouter()
router.register(r'platform-analytics', PlatformAnalyticsViewSet, basename='platform-analytics')
router.register(r'course-analytics', CourseAnalyticsViewSet, basename='course-analytics')
router.register(r'learnership-analytics', LearnershipAnalyticsViewSet, basename='learnership-analytics')
router.register(r'user-progress', UserProgressViewSet, basename='user-progress')

urlpatterns = [
    path('', include(router.urls)),
]
