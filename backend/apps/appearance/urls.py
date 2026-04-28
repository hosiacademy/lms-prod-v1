# apps/appearance/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ThemeViewSet, AppearanceConfigView, ActiveThemeView

app_name = 'appearance'

router = DefaultRouter()
router.register(r'themes', ThemeViewSet, basename='theme')

urlpatterns = [
    # Include router
    path('', include(router.urls)),

    # Primary config endpoint — recommended main call
    path('config/', AppearanceConfigView.as_view(), name='appearance-config'),

    # Lightweight active theme only
    path('active/', ActiveThemeView.as_view(), name='active-theme'),
]