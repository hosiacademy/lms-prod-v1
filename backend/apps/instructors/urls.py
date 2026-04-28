# apps/instructors/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter

from . import views
from .views_instructor_application import (
    InstructorApplicationViewSet,
    InstructorStatusViewSet,
    InstructorAnalyticsViewSet
)
from .views_hours_claims import (
    InstructorHoursClaimViewSet,
    InstructorOvertimeViewSet
)

from apps.payments.admin_views import get_executive_analytics

router = DefaultRouter()
router.register(r'profiles', views.InstructorViewSet, basename='instructor-profile')
router.register(r'assignments', views.CourseAssignmentViewSet, basename='course-assignment')
router.register(r'ratings', views.InstructorRatingViewSet, basename='instructor-rating')
router.register(r'analytics', views.AnalyticsViewSet, basename='instructor-analytics')

# Instructor Application URLs
app_router = DefaultRouter()
app_router.register(r'applications', InstructorApplicationViewSet, basename='instructor-application')
app_router.register(r'instructor-status', InstructorStatusViewSet, basename='instructor-status')
app_router.register(r'instructor-analytics', InstructorAnalyticsViewSet, basename='instructor-analytics')
app_router.register(r'hours-claims', InstructorHoursClaimViewSet, basename='instructor-hours-claim')
app_router.register(r'overtime', InstructorOvertimeViewSet, basename='instructor-overtime')

urlpatterns = [
    path('analytics/executive-insights/', get_executive_analytics, name='executive-insights'),
    path('', include(router.urls)),
    path('', include(app_router.urls)),
]
