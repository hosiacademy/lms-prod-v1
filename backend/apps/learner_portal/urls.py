# apps/learner_portal/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    LearnerProfileViewSet, WishlistViewSet, CourseCartViewSet,
    CourseCatalogViewSet, CourseProviderViewSet,
    CountryViewSet, StateViewSet, CityViewSet,
    get_content_types, get_marketing_analytics, student_dashboard
)
from .views_student_dashboard import complete_student_dashboard

# Create router for API endpoints
router = DefaultRouter()

# Learner portal endpoints
router.register(r'profile', LearnerProfileViewSet, basename='learnerprofile')
router.register(r'wishlist', WishlistViewSet, basename='wishlist')
router.register(r'cart', CourseCartViewSet, basename='coursecart')
router.register(r'catalog', CourseCatalogViewSet, basename='coursecatalog')
router.register(r'providers', CourseProviderViewSet, basename='courseprovider')

# Cascading dropdown endpoints
router.register(r'countries', CountryViewSet, basename='country')
router.register(r'states', StateViewSet, basename='state')
router.register(r'cities', CityViewSet, basename='city')

app_name = 'learner_portal'

urlpatterns = [
    path('', include(router.urls)),
    path('content-types/', get_content_types, name='content-types'),
    path('analytics/marketing/', get_marketing_analytics, name='marketing-analytics'),
    path('dashboard/', student_dashboard, name='student-dashboard'),
    # Comprehensive Student Dashboard - Complete Learning Portal
    path('dashboard/complete/', complete_student_dashboard, name='student-dashboard-complete'),
]
