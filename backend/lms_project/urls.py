# lms_project/urls.py
from django.contrib import admin
from django.urls import path, include, re_path
from django.conf import settings
from django.conf.urls.static import static
from django.views.generic import TemplateView
from apps.masterclasses.admin import analytics_site, completed_site
from apps.users.views import UserListView
import core.admin  # Your custom admin registrations

urlpatterns = [    
    # Trigger reload
    path('api/v1/courses/masterclasses/', include('apps.masterclasses.urls')),

    # Django Admin
    path("admin/", admin.site.urls),

    # API v1 - Unique prefixes for each app
    path("api/v1/bbb/", include("apps.bbb_integration.urls")),
    path("api/v1/courses/", include("apps.aicerts_courses.urls")),
    path("api/v1/learnerships/", include("apps.learnerships.urls")),
    path("api/v1/users/", include("apps.users.urls")),
    path("api/v1/auth/", include("apps.users.auth_urls")),
    
    # Cash Payment Instructions - PUBLIC (no authentication required)
    path('api/v1/cash-payment-instructions/', include('apps.payments.cash_payment_urls')),
    
    path("api/v1/payments/", include("apps.payments.urls")),
    # Allow enrollments to be accessed via both prefixes for frontend compatibility
    path("api/v1/enrollments/", include("apps.payments.enrollment_urls")),
    # Legacy/provisional enrollments
    path("api/v1/enrollments/legacy/", include("apps.enrollments.urls")),
    path("api/v1/instructors/", include("apps.instructors.urls")),
    path("api/v1/industry-training/", include("apps.industry_based_training.urls")),
    path("api/v1/student-portal/", include("apps.learner_portal.urls")),
    path("api/v1/profiles/", UserListView.as_view(), name='profiles'),

    # Frontend dynamic content & theme/appearance
    path("api/v1/frontend/", include("apps.frontend_manage.urls")),

    # Localization & Country-sensitive features (languages, translations, overrides)
    path("api/v1/localization/", include("apps.localization.urls")),

    # Socket.io Communication API - Real-time chat, messaging, notifications
    path("api/v1/communication/", include("apps.communication.urls")),

    # AICerts Partnership Integration - enrollment sync, SSO redirect, instructor validation
    path("api/v1/aicerts/", include("apps.aicerts_integration.urls")),

    # Custom Masterclasses sections
    path('admin/masterclasses/analytics/', analytics_site.urls, name='masterclasses-analytics'),
    path('admin/masterclasses/completed/', completed_site.urls, name='completed-masterclasses'),
    
    # Catch-all for Flutter frontend SPA routing - serves index.html for all non-API routes
    re_path(r'^(?!(api|admin|static|media)/).*$', TemplateView.as_view(template_name='index.html')),
]

# Serve static & media files during development
if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)