# backend/apps/payments/urls/payment_methods_urls.py
"""
URL configuration for payment method selection and routing.
"""

from django.urls import path
from ..views.payment_methods_views import (
    AvailablePaymentMethodsView,
    PaymentMethodValidationView,
    PaymentRoutingView,
    CountryPaymentConfigView,
    SmatPayCardGatewayInfoView,
    get_payment_methods_for_training,
    get_all_supported_countries,
)

app_name = 'payment_methods'

urlpatterns = [
    # Get available payment methods for country and training type
    path(
        'methods/',
        AvailablePaymentMethodsView.as_view(),
        name='available-methods'
    ),
    
    # Validate payment method
    path(
        'validate-method/',
        PaymentMethodValidationView.as_view(),
        name='validate-method'
    ),
    
    # Get payment routing info
    path(
        'routing/',
        PaymentRoutingView.as_view(),
        name='routing'
    ),
    
    # Get full country configuration
    path(
        'country-config/',
        CountryPaymentConfigView.as_view(),
        name='country-config'
    ),
    
    # Get SmatPay card gateway info
    path(
        'smatpay-info/',
        SmatPayCardGatewayInfoView.as_view(),
        name='smatpay-info'
    ),
    
    # Convenience endpoints
    path(
        'methods-for-training/',
        get_payment_methods_for_training,
        name='methods-for-training'
    ),
    
    path(
        'supported-countries/',
        get_all_supported_countries,
        name='supported-countries'
    ),
]
