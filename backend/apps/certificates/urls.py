from django.urls import path, include
from rest_framework.routers import DefaultRouter
from . import views

router = DefaultRouter()
router.register(r'', views.CertificateViewSet, basename='certificate')

urlpatterns = [
    path('verify/<str:verification_code>/', views.verify_certificate, name='verify-certificate'),
    path('', include(router.urls)),
]
