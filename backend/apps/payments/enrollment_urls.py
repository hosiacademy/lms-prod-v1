# apps/payments/enrollment_urls.py
"""
URL patterns for enrollment endpoints.
"""

from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .enrollment_views import (
    EnrollmentViewSet,
    BulkEnrollmentViewSet,
    get_enrollment_form_config,
    quick_enroll,
    FinalizeEnrollmentView
)
from .cash_payment_views import CashPaymentInstructionsView

# Create routers
router = DefaultRouter()
router.register(r'enrollments', EnrollmentViewSet, basename='enrollment')
router.register(r'bulk-enrollments', BulkEnrollmentViewSet, basename='bulk-enrollment')

urlpatterns = [
    # ViewSet routes
    path('', include(router.urls)),

    # Enrollment form configuration
    path(
        'enrollment-config/<str:enrollment_type>/<int:item_id>/',
        get_enrollment_form_config,
        name='enrollment-form-config'
    ),

    # Quick enroll (one-step)
    path(
        'quick-enroll/<str:enrollment_type>/<int:item_id>/',
        quick_enroll,
        name='quick-enroll'
    ),

    # Finalize Enrollment (Post-Payment)
    path(
        'finalize/',
        FinalizeEnrollmentView.as_view(),
        name='finalize-enrollment'
    ),

    # Cash Payment Instructions
    path(
        'cash-payment-instructions/',
        CashPaymentInstructionsView.as_view(),
        name='cash-payment-instructions'
    ),

    # Provisional Enrollment (Legacy/Cash/Manual)
    path(
        '',
        include('apps.enrollments.urls'),
    ),
]
