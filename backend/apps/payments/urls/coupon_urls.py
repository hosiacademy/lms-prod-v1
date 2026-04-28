from django.urls import path
from ..coupon_views import PublicCouponListView, ValidateCouponView

urlpatterns = [
    path('coupons/public/', PublicCouponListView.as_view(), name='public-coupons'),
    path('coupons/validate/', ValidateCouponView.as_view(), name='validate-coupon'),
]
