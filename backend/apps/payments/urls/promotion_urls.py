from django.urls import path
from ..promotion_views import PublicPromotionListView

urlpatterns = [
    path('promotions/public/', PublicPromotionListView.as_view(), name='public-promotions'),
]
