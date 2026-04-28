# apps/frontend_manage/urls.py

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    AppAppearanceThemeView,
    FrontendSettingViewSet, ThemeViewSet,
    FrontendConfigView, HomeContentView,
    GeneralSettingView, LoginPageView
)

app_name = 'frontend_manage'

# Router for model-based endpoints
router = DefaultRouter()
router.register(r'sections', FrontendSettingViewSet, basename='frontend-section')
router.register(r'themes', ThemeViewSet, basename='theme')

urlpatterns = [
    # Include router paths
    path('', include(router.urls)),

    # Master composite endpoint — recommended primary call
    path('config/', FrontendConfigView.as_view(), name='frontend-config'),

    # Individual dedicated endpoints (optional, for granular loading/caching)
    path('home/', HomeContentView.as_view(), name='home-content'),
    path('settings/', GeneralSettingView.as_view(), name='general-settings'),
    path('login/', LoginPageView.as_view(), name='login-page'),
    path('theme/', AppAppearanceThemeView.as_view(), name='current-theme'),
]
