# apps/masterclasses/urls.py
from django.urls import path
from . import views

app_name = 'masterclasses'

urlpatterns = [
    # ⚠️ proxy/image/ MUST come before <slug:slug>/ so Django doesn't
    # mistakenly match "proxy" as a slug value.
    path('proxy/image/', views.proxy_aicerts_image, name='proxy-image'),  # AICERTS CORS proxy

    # Standard masterclass views
    path('', views.masterclass_list, name='masterclass-list'),
    path('<slug:slug>/', views.masterclass_detail, name='masterclass-detail'),
]
