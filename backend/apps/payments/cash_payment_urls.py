# apps/payments/cash_payment_urls.py
from django.urls import path
from .cash_payment_views import CashPaymentInstructionsView

urlpatterns = [
    path('', CashPaymentInstructionsView.as_view(), name='cash-payment-instructions-public'),
]
