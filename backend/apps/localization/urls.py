# apps/localization/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    LanguageViewSet,
    CountryViewSet,
    StateViewSet,
    CityViewSet,
    CountryOverrideViewSet,
    LocalizationConfigAPIView,
    LanguageSyncView,
    GreetingAPIView,
    PromotionListView,
)

app_name = 'localization'

router = DefaultRouter()
router.register(r'languages', LanguageViewSet, basename='language')
router.register(r'countries', CountryViewSet, basename='country')
router.register(r'states', StateViewSet, basename='state')
router.register(r'cities', CityViewSet, basename='city')
router.register(r'overrides', CountryOverrideViewSet, basename='override')

urlpatterns = [
    path('', include(router.urls)),
    path('config/', LocalizationConfigAPIView.as_view(), name='localization-config'),
    path('sync/', LanguageSyncView.as_view(), name='language-sync'),
    path('greeting/', GreetingAPIView.as_view(), name='greeting'),
    path('promotions/', PromotionListView.as_view(), name='promotions'),
]
