from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MarketingAssetViewSet, SocialShareEventViewSet

router = DefaultRouter()
router.register(r'assets', MarketingAssetViewSet)
router.register(r'shares', SocialShareEventViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
