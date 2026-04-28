# apps/payments/views/otp_views.py
"""
Payment OTP Verification Views
Send and verify OTP before allowing payment initiation
"""

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
from ..models import PaymentOTPVerification

logger = logging.getLogger(__name__)


class SendPaymentOTPView(APIView):
    """
    Send OTP to user's email before payment
    
    POST /api/v1/payments/send-otp/
    {
        "email": "user@example.com",
        "amount": 1000,
        "currency": "ZAR",
        "country": "ZA"
    }
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        try:
            data = request.data
            email = data.get('email', '').strip().lower()
            amount = data.get('amount')
            currency = data.get('currency', 'USD')
            country = data.get('country', 'ZA')
            
            # Validate required fields
            if not email:
                return Response({
                    'error': 'Email is required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            if not amount or float(amount) <= 0:
                return Response({
                    'error': 'Valid amount is required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Generate 6-digit OTP
            otp = str(random.randint(100000, 999999))
            
            # Invalidate any existing OTPs for this email
            PaymentOTPVerification.objects.filter(
                email=email,
                verified=False
            ).update(verified=True, is_valid=False)  # Mark old ones as used
            
            # Create new OTP record
            otp_record = PaymentOTPVerification.objects.create(
                email=email,
                otp=otp,
                amount=amount,
                currency=currency,
                country=country,
                expires_at=timezone.now() + timedelta(minutes=10),  # 10 min expiry
            )
            
            # Send email with OTP
            try:
                send_mail(
                    subject=f'Payment Verification OTP - {amount} {currency}',
                    message=f'''
Hello,

You are about to make a payment of {amount} {currency}.

Your One-Time Password (OTP) is: {otp}

This OTP will expire in 10 minutes.

Do not share this code with anyone.

If you did not request this payment, please ignore this email.

Thank you,
Hosi Academy Payment System
                    ''',
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[email],
                    fail_silently=False,
                )
                
                logger.info(f"Payment OTP sent to {email}")
                
            except Exception as email_error:
                logger.error(f"Failed to send OTP email: {str(email_error)}")
                # Still allow in development if email fails
                if not settings.DEBUG:
                    return Response({
                        'error': 'Failed to send OTP email',
                        'details': str(email_error)
                    }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
            return Response({
                'success': True,
                'message': 'OTP sent successfully',
                'email': email,
                'expires_in': 600,  # 10 minutes in seconds
                'otp_length': 6,
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error sending OTP: {str(e)}")
            return Response({
                'error': f'Failed to send OTP: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class VerifyPaymentOTPView(APIView):
    """
    Verify OTP before allowing payment
    
    POST /api/v1/payments/verify-otp/
    {
        "email": "user@example.com",
        "otp": "123456"
    }
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        try:
            data = request.data
            email = data.get('email', '').strip().lower()
            otp = data.get('otp', '').strip()
            
            # Validate required fields
            if not email or not otp:
                return Response({
                    'error': 'Email and OTP are required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Find valid OTP record
            otp_record = PaymentOTPVerification.objects.filter(
                email=email,
                otp=otp,
                verified=False,
                is_valid=True,
                expires_at__gt=timezone.now()
            ).first()
            
            if not otp_record:
                # Check if OTP expired
                expired_record = PaymentOTPVerification.objects.filter(
                    email=email,
                    otp=otp,
                    verified=False
                ).filter(expires_at__lte=timezone.now()).first()
                
                if expired_record:
                    return Response({
                        'success': False,
                        'error': 'OTP has expired',
                        'error_code': 'OTP_EXPIRED'
                    }, status=status.HTTP_400_BAD_REQUEST)
                
                return Response({
                    'success': False,
                    'error': 'Invalid OTP',
                    'error_code': 'INVALID_OTP'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Mark OTP as verified
            otp_record.verified = True
            otp_record.verified_at = timezone.now()
            otp_record.save()
            
            # Generate payment token (valid for 15 minutes)
            from django.utils.crypto import get_random_string
            payment_token = f"PT-{get_random_string(32).upper()}"
            
            # Store payment token
            otp_record.payment_token = payment_token
            otp_record.save()
            
            logger.info(f"Payment OTP verified for {email}")
            
            return Response({
                'success': True,
                'message': 'OTP verified successfully',
                'payment_token': payment_token,
                'email': email,
                'amount': float(otp_record.amount),
                'currency': otp_record.currency,
                'country': otp_record.country,
                'token_expires_in': 900,  # 15 minutes
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error verifying OTP: {str(e)}")
            return Response({
                'error': f'Failed to verify OTP: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class ResendPaymentOTPView(APIView):
    """
    Resend OTP if user didn't receive it
    
    POST /api/v1/payments/resend-otp/
    {
        "email": "user@example.com"
    }
    """
    permission_classes = [AllowAny]
    
    def post(self, request):
        try:
            data = request.data
            email = data.get('email', '').strip().lower()
            
            if not email:
                return Response({
                    'error': 'Email is required'
                }, status=status.HTTP_400_BAD_REQUEST)
            
            # Check if there's a recent OTP (within 2 minutes)
            recent_otp = PaymentOTPVerification.objects.filter(
                email=email,
                created_at__gt=timezone.now() - timedelta(minutes=2),
                verified=False
            ).first()
            
            if recent_otp:
                return Response({
                    'success': False,
                    'error': 'Please wait before requesting another OTP',
                    'retry_after': 120  # seconds
                }, status=status.HTTP_429_TOO_MANY_REQUESTS)
            
            # Generate new OTP
            otp = str(random.randint(100000, 999999))

            # Fetch last OTP's payment details BEFORE invalidating
            last_otp = PaymentOTPVerification.objects.filter(
                email=email,
                verified=False
            ).order_by('-created_at').first()

            # Invalidate previous OTPs
            PaymentOTPVerification.objects.filter(
                email=email,
                verified=False
            ).update(verified=True, is_valid=False)

            # Create new OTP record, reusing previous payment details
            otp_record = PaymentOTPVerification.objects.create(
                email=email,
                otp=otp,
                amount=last_otp.amount if last_otp else 0,
                currency=last_otp.currency if last_otp else 'USD',
                country=last_otp.country if last_otp else 'ZA',
                expires_at=timezone.now() + timedelta(minutes=10),
            )
            
            # Send email
            try:
                send_mail(
                    subject=f'Payment Verification OTP (Resent) - {otp_record.amount} {otp_record.currency}',
                    message=f'''
Hello,

You requested a new OTP for your payment of {otp_record.amount} {otp_record.currency}.

Your One-Time Password (OTP) is: {otp}

This OTP will expire in 10 minutes.

Do not share this code with anyone.

Thank you,
Hosi Academy Payment System
                    ''',
                    from_email=settings.DEFAULT_FROM_EMAIL,
                    recipient_list=[email],
                    fail_silently=False,
                )
                
                logger.info(f"Payment OTP resent to {email}")
                
            except Exception as email_error:
                logger.error(f"Failed to resend OTP email: {str(email_error)}")
                if not settings.DEBUG:
                    return Response({
                        'error': 'Failed to send OTP email'
                    }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
            
            return Response({
                'success': True,
                'message': 'OTP resent successfully',
                'email': email,
                'expires_in': 600,
            }, status=status.HTTP_200_OK)
            
        except Exception as e:
            logger.error(f"Error resending OTP: {str(e)}")
            return Response({
                'error': f'Failed to resend OTP: {str(e)}'
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
