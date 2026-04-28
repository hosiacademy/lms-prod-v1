# apps/aicerts_integration/urls.py
"""
URL Configuration for AICERTs Partnership Integration
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

app_name = 'aicerts_integration'

router = DefaultRouter()
router.register(r'enrollments', views.AICertsEnrollmentViewSet, basename='enrollment')
router.register(r'instructor-designations', views.AICertsInstructorDesignationViewSet, basename='instructor-designation')
router.register(r'sync-logs', views.AICertsSyncLogViewSet, basename='sync-log')

urlpatterns = [
    # SSO redirect endpoint
    path('sso/redirect/', views.SSORedirectView.as_view(), name='sso-redirect'),

    # Instructor validation endpoint
    path('instructor/validate/', views.InstructorValidationView.as_view(), name='instructor-validate'),

    # Include router URLs
    path('', include(router.urls)),
]
