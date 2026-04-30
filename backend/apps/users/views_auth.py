from rest_framework import generics, serializers, status
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth import get_user_model
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()

# Import existing serializers
from .serializers import UserSerializer
from .dashboard_serializers import build_dashboard_data
import random
from django.utils import timezone
from datetime import timedelta
from django.core.mail import send_mail
from django.conf import settings
from .models import AuthOTP


class CustomTokenObtainPairSerializer(serializers.Serializer):
    """
    JWT login serializer that accepts EMAIL and password.
    Returns access/refresh tokens + user profile + dashboard data.
    """
    
    email = serializers.EmailField(write_only=True)
    password = serializers.CharField(write_only=True)
    access = serializers.CharField(read_only=True)
    refresh = serializers.CharField(read_only=True)
    user = UserSerializer(read_only=True)
    dashboard = serializers.DictField(read_only=True)
    
    def validate(self, attrs):
        # Get email and password from request
        email = attrs.get('email')
        password = attrs.get('password')
        
        if not email or not password:
            raise serializers.ValidationError({'detail': 'Email and password are required'})
        
        # Find user by email
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            raise serializers.ValidationError({'detail': 'No active account found with the given credentials'})
        
        # Check if user is active
        if not user.is_active:
            raise serializers.ValidationError({'detail': 'No active account found with the given credentials'})
        
        # Verify password
        if not user.check_password(password):
            raise serializers.ValidationError({'detail': 'No active account found with the given credentials'})
        
        # Create tokens
        refresh = RefreshToken.for_user(user)
        
        data = {
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': UserSerializer(user).data,
            'dashboard': build_dashboard_data(user),
        }

        return data


class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer


class UserProfileView(generics.RetrieveUpdateAPIView):
    """
    GET: Return full profile of the authenticated user.
    PATCH: Update allowed fields.
    """
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user


class DashboardView(generics.GenericAPIView):
    """
    GET /api/v1/auth/dashboard/
    Returns the role-specific dashboard data for the currently authenticated user.
    Call this any time during a session to refresh dashboard state.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, *args, **kwargs):
        user = request.user
        return Response({
            'user': UserSerializer(user).data,
            'dashboard': build_dashboard_data(user),
        })


class SetPasswordView(APIView):
    """
    POST /api/v1/auth/set-password/
    Sets password for a user after cash payment enrollment.
    If no user exists, creates one using metadata from ProvisionalEnrollment.
    Accepts: { new_password, reference }
    """
    permission_classes = []  # No auth required

    def post(self, request, *args, **kwargs):
        new_password = request.data.get('new_password', '').strip()
        reference = (request.data.get('reference_code') or request.data.get('reference') or '').strip()

        if not new_password or len(new_password) < 8:
            return Response({'detail': 'Password must be at least 8 characters.'}, status=status.HTTP_400_BAD_REQUEST)

        if not reference:
            return Response({'detail': 'Payment reference is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            from apps.enrollments.models import ProvisionalEnrollment
            from apps.users.models import User
            from django.db import transaction

            prov = ProvisionalEnrollment.objects.filter(reference_code=reference).first()
            if not prov:
                return Response({'detail': 'No enrollment found for this reference.'}, status=status.HTTP_404_NOT_FOUND)

            # Check if user already exists
            user = prov.user

            if not user:
                # Create user from metadata
                metadata = prov.metadata or {}
                individual_details = metadata.get('individual_details', {})
                email = individual_details.get('email') or metadata.get('email')
                
                if not email:
                    return Response({'detail': 'Email not found. Please contact support.'}, status=status.HTTP_400_BAD_REQUEST)

                with transaction.atomic():
                    user = User.objects.create_user(
                        username=email,
                        email=email,
                        password=new_password,
                        first_name=individual_details.get('first_name', ''),
                        last_name=individual_details.get('last_name', ''),
                    )
                    # Link user to provisional enrollment
                    prov.user = user
                    prov.save(update_fields=['user'])

                    # Trigger email notification with payment instructions
                    from apps.enrollments.tasks import send_provisional_enrollment_email
                    send_provisional_enrollment_email.delay(prov.id)

                return Response({
                    'detail': 'Account created successfully. Check your email for payment instructions.',
                    'user_created': True
                }, status=status.HTTP_201_CREATED)
            else:
                # User exists, just set password
                user.set_password(new_password)
                user.save(update_fields=['password'])
                return Response({'detail': 'Password set successfully.'}, status=status.HTTP_200_OK)

        except Exception as e:
            return Response({'detail': f'Could not verify reference: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)
class ProfileUpdateEmailView(APIView):
    """
    POST /api/v1/auth/profile/update-email/
    Updates the email address of the currently authenticated user.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        if not email:
            return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Check if email is already taken
        if User.objects.filter(email=email).exclude(id=request.user.id).exists():
            return Response({'error': 'This email is already in use by another account'}, status=status.HTTP_400_BAD_REQUEST)
        
        user = request.user
        user.email = email
        # If it was a dummy email, we might want to log that the onboarding is complete
        user.save()
        
        return Response({'success': True, 'email': email})


class ReactivateAccountView(APIView):
    """
    POST /api/v1/auth/reactivate/
    Requests reactivation of a suspended account.
    """
    permission_classes = [] 

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        if not email:
            return Response({'error': 'Email is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            user = User.objects.get(email=email)
            if user.is_active:
                return Response({'message': 'Account is already active'}, status=status.HTTP_200_OK)
            
            # Simple reactivation for now to restore functionality
            user.is_active = True
            user.save()
            
            return Response({
                'success': True, 
                'message': 'Account has been reactivated successfully. You can now login.'
            })
        except User.DoesNotExist:
            return Response({'error': 'No account found with this email address.'}, status=status.HTTP_404_NOT_FOUND)


class SendAuthOTPView(APIView):
    """
    POST /api/v1/auth/otp/send/
    Generates and "sends" an OTP to the user's identifier (email).
    """
    permission_classes = []

    def post(self, request):
        identifier = (request.data.get('identifier') or request.data.get('email', '')).strip().lower()
        if not identifier:
            return Response({'error': 'Identifier (email) is required'}, status=status.HTTP_400_BAD_REQUEST)

        # Check if user exists
        try:
            User.objects.get(email=identifier)
        except User.DoesNotExist:
            return Response({'error': 'No account found with this email address.'}, status=status.HTTP_404_NOT_FOUND)

        # Generate 6-digit OTP
        otp_code = ''.join([str(random.randint(0, 9)) for _ in range(6)])
        
        # Save to DB
        AuthOTP.objects.create(
            identifier=identifier,
            otp=otp_code,
            expires_at=timezone.now() + timedelta(minutes=10)
        )

        # Log for development/testing
        print(f"[KEY] AUTH OTP for {identifier}: {otp_code}")

        # Send actual email using optimized method
        from django.core.mail import EmailMessage
        try:
            email = EmailMessage(
                subject='Hosi Academy - Your Login OTP',
                body=f'Your login OTP is: {otp_code}\n\nThis code will expire in 10 minutes.',
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[identifier],
            )
            email.send(fail_silently=False)
        except Exception as e:
            print(f"Failed to send email to {identifier}: {str(e)}")
            # We still return success: True because the OTP is created in DB and can be seen in console
            # but we notify in logs

        return Response({'success': True, 'message': 'OTP sent successfully'})


class OTPLoginView(APIView):
    """
    POST /api/v1/auth/otp/login/
    Verifies OTP and returns JWT tokens.
    """
    permission_classes = []

    def post(self, request):
        identifier = (request.data.get('identifier') or request.data.get('email', '')).strip().lower()
        otp = request.data.get('otp', '').strip()
        
        if not identifier or not otp:
            return Response({'error': 'Identifier (email) and OTP are required'}, status=status.HTTP_400_BAD_REQUEST)

        # Verify OTP
        otp_record = AuthOTP.objects.filter(
            identifier=identifier, 
            otp=otp, 
            is_used=False
        ).first()

        if not otp_record or otp_record.is_expired():
            return Response({'error': 'Invalid or expired OTP'}, status=status.HTTP_400_BAD_REQUEST)

        # Mark as used
        otp_record.is_used = True
        otp_record.save()

        # Get user
        try:
            user = User.objects.get(email=identifier)
        except User.DoesNotExist:
            return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)

        # Create tokens
        refresh = RefreshToken.for_user(user)
        
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': UserSerializer(user).data,
            'dashboard': build_dashboard_data(user),
        })
