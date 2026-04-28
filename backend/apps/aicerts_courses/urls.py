from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AiCertsCourseViewSet, custom_selection_catalog

router = DefaultRouter()
router.register(r'courses', AiCertsCourseViewSet, basename='aicerts-course')

urlpatterns = [
    path('', include(router.urls)),
    path('custom-selection-catalog/', custom_selection_catalog, name='custom-selection-catalog'),
]
