# apps/users/urls.py

from django.urls import path
from .views import UserListView, UserCreateView, CheckEmailView
from .views_profiles import ThemePreferenceView
from .views_dashboard import (
    DashboardView,
    HrAdminDashboardView,
    PaymentAdminDashboardView,
    ExecutiveDashboardView,
    CountryAccessInfoView,
    CountrySelectionView
)

app_name = 'users'  # Enables reverse('users:user-list') in templates/code

urlpatterns = [
    # Theme preference endpoint
    path('theme/', ThemePreferenceView.as_view(), name='user-theme'),

    # Dashboard endpoints with role-based country filtering
    path('dashboard/', DashboardView.as_view(), name='dashboard'),
    path('dashboard/hr-admin/', HrAdminDashboardView.as_view(), name='dashboard-hr-admin'),
    path('dashboard/payment-admin/', PaymentAdminDashboardView.as_view(), name='dashboard-payment-admin'),
    path('dashboard/executive/', ExecutiveDashboardView.as_view(), name='dashboard-executive'),
    path('dashboard/country-access/', CountryAccessInfoView.as_view(), name='dashboard-country-access'),
    path('dashboard/country-selection/<int:country_id>/', CountrySelectionView.as_view(), name='dashboard-country-selection'),

    # GET: Check if an email already exists (used by enrollment wizard step 3)
    # Example: /api/v1/users/check-email/?email=user@example.com
    path('check-email/', CheckEmailView.as_view(), name='check-email'),

    # GET: Fetch/sync users from AiCerts (search by ?key=email&value=example@domain.com)
    # Example: /api/v1/users/sync/?key=email&value=john@example.com
    path('sync/', UserListView.as_view(), name='user-sync'),

    # POST: Create a new user via AiCerts API and sync to local DB
    # Example: /api/v1/users/create/
    path('create/', UserCreateView.as_view(), name='user-create'),

    # Optional: allow POST to the base users/ endpoint to maps to create for backward compatibility
    path('', UserCreateView.as_view(), name='user-base-create'),
]