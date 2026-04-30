from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import MarketingAssetViewSet, SocialShareEventViewSet, MarketingLeadViewSet, WishlistViewSet

router = DefaultRouter()
router.register(r'assets', MarketingAssetViewSet)
router.register(r'shares', SocialShareEventViewSet)
router.register(r'leads', MarketingLeadViewSet)
router.register(r'wishlist', WishlistViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
