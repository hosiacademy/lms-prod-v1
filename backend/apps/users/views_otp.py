# apps/users/views_otp.py
import random
import logging
from datetime import timedelta
from django.utils import timezone
from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from django.core.mail import send_mail
from django.conf import settings
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken

from apps.payments.models import ContactVerificationOTP
from .serializers import UserSerializer
from .dashboard_serializers import build_dashboard_data

User = get_user_model()
logger = logging.getLogger(__name__)

class SendLoginOTPView(APIView):
    """
    Send OTP to user's email for login
    POST /api/v1/auth/otp/send/
    { "email": "user@example.com" }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        if not email:
            return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)

        # Check if user exists
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({
                'error': 'No account found with this email',
                'error_code': 'USER_NOT_FOUND'
            }, status=status.HTTP_404_NOT_FOUND)

        if not user.is_active:
            return Response({'error': 'Account is deactivated'}, status=status.HTTP_403_FORBIDDEN)

        # Generate 6-digit OTP
        otp = str(random.randint(100000, 999999))

        # Invalidate old OTPs
        ContactVerificationOTP.objects.filter(
            contact=email,
            contact_type='email',
            verified=False
        ).update(is_valid=False)

        # Create OTP record
        ContactVerificationOTP.objects.create(
            contact=email,
            contact_type='email',
            otp=otp,
            expires_at=timezone.now() + timedelta(minutes=10)
        )
        
        if settings.DEBUG:
            print(f"\n[DEBUG] OTP for {email}: {otp}\n")
            logger.info(f"OTP for {email}: {otp}")

        # Send email using optimized method
        from django.core.mail import EmailMessage
        try:
            email_msg = EmailMessage(
                subject='Login Verification Code - Hosi Academy',
                body=f'Your login verification code is: {otp}\n\nThis code will expire in 10 minutes.',
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[email],
            )
            email_msg.send(fail_silently=False)
        except Exception as e:
            logger.error(f"Failed to send login OTP to {email}: {str(e)}")
            if not settings.DEBUG:
                return Response({'error': 'Failed to send verification email'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        return Response({
            'success': True,
            'message': 'OTP sent successfully',
            'email': email
        })

class LoginWithOTPView(APIView):
    """
    Verify OTP and log in the user
    POST /api/v1/auth/otp/login/
    { "email": "user@example.com", "otp": "123456" }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        otp = request.data.get('otp', '').strip()

        if not email or not otp:
            return Response({'error': 'Email and OTP are required'}, status=status.HTTP_400_BAD_REQUEST)

        # Verify OTP
        otp_record = ContactVerificationOTP.objects.filter(
            contact=email,
            contact_type='email',
            otp=otp,
            verified=False,
            is_valid=True,
            expires_at__gt=timezone.now()
        ).first()

        if not otp_record:
            return Response({
                'error': 'Invalid or expired OTP',
                'error_code': 'INVALID_OTP'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Mark as verified
        otp_record.verified = True
        otp_record.verified_at = timezone.now()
        otp_record.save()

        # Get user and generate tokens
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'error': 'User no longer exists'}, status=status.HTTP_404_NOT_FOUND)

        refresh = RefreshToken.for_user(user)

        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': UserSerializer(user).data,
            'dashboard': build_dashboard_data(user),
        }, status=status.HTTP_200_OK)
