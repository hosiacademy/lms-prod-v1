# apps/content/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    PageViewSet, TestimonialViewSet,
    SponsorViewSet, FrontPageViewSet,
    ContentConfigView
)

app_name = 'content'

router = DefaultRouter()
router.register(r'pages', PageViewSet, basename='page')
router.register(r'testimonials', TestimonialViewSet, basename='testimonial')
router.register(r'sponsors', SponsorViewSet, basename='sponsor')
router.register(r'front-pages', FrontPageViewSet, basename='frontpage')

urlpatterns = [
    path('', include(router.urls)),
    path('config/', ContentConfigView.as_view(), name='content-config'),
]