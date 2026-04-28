# backend/apps/payments/urls/__init__.py

from django.urls import path, include
from ..views.payment_views import (
    DetectLocationView,
    ExchangeRatesView,
    VerifyPaymentView,
    PaymentCallbackView,
)
from ..views import InitiatePaymentView, AdminRoleRequestViewSet
from ..views.learnership_payment_views import CalculateLearnershipPaymentPlanView, ValidateLearnershipPaymentView
from ..views.webhook_views import provider_webhook
from ..views.payment_provider_views import GetAvailablePaymentProvidersView, GetProvidersByCategoryView
from ..views.country_views import CountryProvidersView
from ..views.african_banks_views import GetAfricanBanksView, ListAfricanCountriesView
from ..api_views import (
    payment_admin_operations_data,
    payment_admin_marketing_analytics,
    payment_admin_sales_analytics,
    # payment_admin_bulk_sms,
)
from ..admin_views import (
    get_admin_role_assignment,
    get_failed_provisioning_data,
    retry_provisioning,
    mark_provisioning_resolved,
    get_eft_verification_dashboard,
    admin_verify_eft_payment,
    admin_reject_eft_payment,
    get_hr_dashboard_data,
    get_instructor_payroll_data,
    update_instructor_rate,
    get_staff_directory,
)
from ..executive_views import (
    executive_dashboard_analytics,
    executive_financial_insights,
    executive_country_comparison,
)
from ..views.eft_views import (
    initiate_eft_payment,
    submit_bank_details,
    check_eft_status,
    upload_proof_of_payment,
    get_pending_eft_payments,
    verify_eft_payment,
    reject_eft_payment,
    get_eft_statistics,
)
from ..views.on_site_payment_views import (
    create_on_site_enrollment,
    get_on_site_enrollment,
    settle_on_site_payment,
    get_pending_on_site_payments,
)
from ..views.otp_views import (
    SendPaymentOTPView,
    VerifyPaymentOTPView,
    ResendPaymentOTPView,
)
from ..views.contact_otp_views import (
    SendContactOTPView,
    VerifyContactOTPView,
    ResendContactOTPView,
)
from ..coupon_views import ValidateCouponView, RedeemCouponView, ListCouponsView, PublicCouponsView

from ..views.marketing_views import (
    MailingListView,
    MailingListContactView,
    MarketingCampaignView,
    CouponManagementView,
)
from ..views.bulk_sms_views import BulkSMSSendView, UserPhoneListView

urlpatterns = [
    # Marketing Admin Endpoints
    path('admin/mailing-lists/', MailingListView.as_view(), name='admin-mailing-lists'),
    path('admin/mailing-lists/<int:list_id>/contacts/', MailingListContactView.as_view(), name='admin-mailing-list-contacts'),
    path('admin/marketing/campaigns/', MarketingCampaignView.as_view(), name='admin-marketing-campaigns'),
    path('admin/marketing/promotions/', CouponManagementView.as_view(), name='admin-marketing-promotions'),
    # Payment Method Selection & Routing (NEW)
    # Unified payment flow for card (SmatPay only), EFT, and cash payments
    path(
        'methods/',
        include('apps.payments.urls.payment_methods_urls'),
    ),

    # Payment Verification (FIX: Add missing verify endpoint)
    path(
        'verify/<str:transaction_id>/',
        VerifyPaymentView.as_view(),
        name='verify-payment',
    ),

    # Payment Callback
    path(
        'callback/<str:transaction_id>/',
        PaymentCallbackView.as_view(),
        name='payment-callback',
    ),

    # Enrollments endpoint (FIX: Include at root so /api/v1/payments/enrollments/ works)
    # The router in enrollment_urls.py registers 'enrollments/', so including at '' makes it
    # accessible at /api/v1/payments/enrollments/
    path(
        '',
        include('apps.payments.enrollment_urls'),
    ),

    # African Banks Database (NEW)
    path(
        'african-banks/',
        GetAfricanBanksView.as_view(),
        name='african-banks',
    ),
    path(
        'african-countries/',
        ListAfricanCountriesView.as_view(),
        name='african-countries',
    ),

    # Payment Initiation
    path(
        'initiate/',
        InitiatePaymentView.as_view(),
        name='initiate-payment',
    ),

    # Get Available Payment Providers (with country detection)
    path(
        'providers/',
        GetAvailablePaymentProvidersView.as_view(),
        name='available-providers',
    ),

    # Get Providers by Payment Category
    path(
        'providers-by-category/',
        GetProvidersByCategoryView.as_view(),
        name='providers-by-category',
    ),

    # Get Providers by Country (alternative endpoint)
    path(
        'providers-list/',
        CountryProvidersView.as_view(),
        name='providers-list',
    ),

    # Webhooks
    path(
        'webhooks/<str:provider_code>/',
        provider_webhook,
        name='provider-webhook',
    ),

    # IP-based Currency Detection
    path(
        'detect-location/',
        DetectLocationView.as_view(),
        name='detect-location',
    ),

    # Exchange Rates
    path(
        'exchange-rates/',
        ExchangeRatesView.as_view(),
        name='exchange-rates',
    ),

    # Admin Role Assignment (used by all admin portals to get allowed countries)
    path(
        'admin/role-assignment/',
        get_admin_role_assignment,
        name='admin-role-assignment',
    ),

    # Payment Admin Dashboard APIs
    path(
        'admin/operations/data/',
        payment_admin_operations_data,
        name='payment-admin-operations-data',
    ),
    path(
        'admin/marketing/analytics/',
        payment_admin_marketing_analytics,
        name='payment-admin-marketing-analytics',
    ),
    path(
        'admin/sales/analytics/',
        payment_admin_sales_analytics,
        name='payment-admin-sales-analytics',
    ),

    # HR Admin Dashboard APIs
    path(
        'admin/hr/dashboard/',
        get_hr_dashboard_data,
        name='hr-dashboard',
    ),
    path(
        'admin/hr/instructors/',
        get_instructor_payroll_data,
        name='instructor-payroll',
    ),
    path(
        'admin/hr/instructors/<int:user_id>/update-rate/',
        update_instructor_rate,
        name='update-instructor-rate',
    ),

    # Executive Dashboard APIs
    path(
        'admin/executive/dashboard/',
        executive_dashboard_analytics,
        name='executive-dashboard-analytics',
    ),
    path(
        'admin/executive/financial-insights/',
        executive_financial_insights,
        name='executive-financial-insights',
    ),
    path(
        'admin/executive/country-comparison/',
        executive_country_comparison,
        name='executive-country-comparison',
    ),


    # Failed Provisioning Admin APIs
    path(
        'admin/failed-provisioning/',
        get_failed_provisioning_data,
        name='failed-provisioning-data',
    ),
    path(
        'admin/failed-provisioning/<str:transaction_id>/retry/',
        retry_provisioning,
        name='retry-provisioning',
    ),
    path(
        'admin/failed-provisioning/<str:transaction_id>/mark-resolved/',
        mark_provisioning_resolved,
        name='mark-provisioning-resolved',
    ),

    # EFT/Bank Transfer Endpoints
    path(
        'eft/initiate/',
        initiate_eft_payment,
        name='initiate-eft-payment',
    ),
    path(
        'eft/submit-bank-details/',
        submit_bank_details,
        name='submit-bank-details',
    ),
    path(
        'eft/status/<str:reference>/',
        check_eft_status,
        name='check-eft-status',
    ),
    path(
        'eft/upload-pop/<str:reference>/',
        upload_proof_of_payment,
        name='upload-proof-of-payment',
    ),
    
    # EFT Admin Endpoints
    path(
        'eft/admin/pending/',
        get_pending_eft_payments,
        name='get-pending-eft-payments',
    ),
    path(
        'eft/admin/verify/',
        verify_eft_payment,
        name='verify-eft-payment',
    ),
    path(
        'eft/admin/reject/',
        reject_eft_payment,
        name='reject-eft-payment',
    ),
    path(
        'eft/admin/statistics/',
        get_eft_statistics,
        name='get-eft-statistics',
    ),
    
    # EFT Admin Verification (Admin Views)
    path(
        'admin/eft/dashboard/',
        get_eft_verification_dashboard,
        name='eft-verification-dashboard',
    ),
    path(
        'admin/eft/verify/<str:reference>/',
        admin_verify_eft_payment,
        name='admin-verify-eft',
    ),
    path(
        'admin/eft/reject/<str:reference>/',
        admin_reject_eft_payment,
        name='admin-reject-eft',
    ),

    # On-Site / Cash Payment Endpoints
    path(
        'on-site/create/',
        create_on_site_enrollment,
        name='create-on-site-enrollment',
    ),
    path(
        'on-site/<str:reference_code>/',
        get_on_site_enrollment,
        name='get-on-site-enrollment',
    ),
    path(
        'on-site/<str:reference_code>/settle/',
        settle_on_site_payment,
        name='settle-on-site-payment',
    ),
    path(
        'on-site/admin/pending/',
        get_pending_on_site_payments,
        name='get-pending-on-site-payments',
    ),
    
    # Learnership Payment Calculation
    path(
        'calculate-learnership-plan/',
        CalculateLearnershipPaymentPlanView.as_view(),
        name='calculate-learnership-payment-plan',
    ),
    path(
        'validate-learnership-payment/',
        ValidateLearnershipPaymentView.as_view(),
        name='validate-learnership-payment',
    ),

    # Payment OTP Verification Endpoints
    path(
        'send-otp/',
        SendPaymentOTPView.as_view(),
        name='send-payment-otp',
    ),
    path(
        'verify-otp/',
        VerifyPaymentOTPView.as_view(),
        name='verify-payment-otp',
    ),
    path(
        'resend-otp/',
        ResendPaymentOTPView.as_view(),
        name='resend-payment-otp',
    ),

    # Contact Verification OTP (enrollment form email + phone verification)
    path('contact-otp/send/', SendContactOTPView.as_view(), name='send-contact-otp'),
    path('contact-otp/verify/', VerifyContactOTPView.as_view(), name='verify-contact-otp'),
    path('contact-otp/resend/', ResendContactOTPView.as_view(), name='verify-contact-otp'),

    # Coupon / Promo Code Endpoints
    path('coupons/public/', PublicCouponsView.as_view(), name='coupon-public'),
    path('coupons/validate/', ValidateCouponView.as_view(), name='coupon-validate'),

    # Bulk SMS Campaign Endpoints
    path('admin/bulk-sms/send/', BulkSMSSendView.as_view(), name='bulk-sms-send'),
    path('bulk-sms/user-phones/', UserPhoneListView.as_view(), name='user-phone-list'),

    # Staff Directory (Chat DM People Search)
    path('admin/staff-directory/', get_staff_directory, name='admin-staff-directory'),

    # Quotation System Endpoints
    path('quotations/', include('apps.payments.urls.quotation_urls')),
]

from rest_framework.routers import DefaultRouter
router = DefaultRouter()
router.register(r'admin-role-requests', AdminRoleRequestViewSet, basename='admin-role-request')

urlpatterns += [
    path('', include(router.urls)),
]

__all__ = ['urlpatterns']
