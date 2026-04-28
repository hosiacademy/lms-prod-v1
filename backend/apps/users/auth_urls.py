from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView
from .views_auth import (
    CustomTokenObtainPairView, UserProfileView, DashboardView, 
    SetPasswordView, ProfileUpdateEmailView, ReactivateAccountView,
    SendAuthOTPView, OTPLoginView
)

urlpatterns = [
    path('login/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('otp/send/', SendAuthOTPView.as_view(), name='otp_send'),
    path('otp/login/', OTPLoginView.as_view(), name='otp_login'),
    path('refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('profile/', UserProfileView.as_view(), name='user_profile'),
    path('profile/update-email/', ProfileUpdateEmailView.as_view(), name='update_email'),
    path('reactivate/', ReactivateAccountView.as_view(), name='reactivate_account'),
    path('dashboard/', DashboardView.as_view(), name='user_dashboard'),
    path('set-password/', SetPasswordView.as_view(), name='set_password'),
]
