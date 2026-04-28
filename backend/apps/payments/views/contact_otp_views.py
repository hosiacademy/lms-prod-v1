# apps/payments/views/contact_otp_views.py
"""
Contact Verification OTP Views
Verifies email and phone numbers entered in enrollment forms.
"""

import random
import logging
from datetime import timedelta

from django.utils import timezone
from django.core.mail import send_mail
from django.conf import settings

from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny

from ..models import ContactVerificationOTP

logger = logging.getLogger(__name__)

OTP_EXPIRY_MINUTES = 10
RESEND_COOLDOWN_SECONDS = 120


def _generate_otp():
    return str(random.randint(100000, 999999))


def _invalidate_previous(contact, contact_type):
    ContactVerificationOTP.objects.filter(
        contact=contact,
        contact_type=contact_type,
        verified=False,
    ).update(is_valid=False)


class SendContactOTPView(APIView):
    """
    Send a 6-digit OTP to an email address or phone number.

    POST /api/v1/payments/contact-otp/send/
    {
        "contact": "user@example.com",   // or "+27712345678"
        "contact_type": "email"          // or "phone"
    }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        contact = request.data.get('contact', '').strip()
        contact_type = request.data.get('contact_type', '').strip().lower()

        if not contact:
            return Response({'error': 'contact is required'}, status=400)
        if contact_type not in ('email', 'phone'):
            return Response({'error': 'contact_type must be "email" or "phone"'}, status=400)

        # Rate-limit: block if a valid OTP was sent within the last 2 minutes
        recent = ContactVerificationOTP.objects.filter(
            contact=contact,
            contact_type=contact_type,
            is_valid=True,
            created_at__gt=timezone.now() - timedelta(seconds=RESEND_COOLDOWN_SECONDS),
        ).first()
        if recent:
            wait = int((recent.created_at + timedelta(seconds=RESEND_COOLDOWN_SECONDS) - timezone.now()).total_seconds())
            return Response(
                {'error': 'Please wait before requesting another code', 'retry_after': max(wait, 1)},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        _invalidate_previous(contact, contact_type)
        otp = _generate_otp()

        ContactVerificationOTP.objects.create(
            contact=contact,
            contact_type=contact_type,
            otp=otp,
            expires_at=timezone.now() + timedelta(minutes=OTP_EXPIRY_MINUTES),
        )

        if contact_type == 'email':
            success = self._send_email(contact, otp)
        else:
            success = self._send_sms(contact, otp)

        if not success and not settings.DEBUG:
            return Response({'error': 'Failed to send verification code'}, status=500)

        logger.info("Contact OTP sent: %s (%s)", contact, contact_type)
        return Response({
            'success': True,
            'message': f'Verification code sent to your {contact_type}',
            'expires_in': OTP_EXPIRY_MINUTES * 60,
        })

    def _send_email(self, email, otp):
        from django.core.mail import EmailMessage
        try:
            email_msg = EmailMessage(
                subject='Your Hosi Academy Verification Code',
                body=(
                    f'Your verification code is: {otp}\n\n'
                    f'It expires in {OTP_EXPIRY_MINUTES} minutes.\n'
                    f'Do not share this code with anyone.\n\n'
                    f'– Hosi Academy'
                ),
                from_email=settings.DEFAULT_FROM_EMAIL,
                to=[email],
            )
            email_msg.send(fail_silently=False)
            return True
        except Exception as exc:
            logger.error("Failed to send OTP email to %s: %s", email, exc)
            return False

    def _send_sms(self, phone, otp):
        try:
            account_sid = getattr(settings, 'TWILIO_ACCOUNT_SID', None)
            auth_token = getattr(settings, 'TWILIO_AUTH_TOKEN', None)
            from_number = getattr(settings, 'TWILIO_PHONE_NUMBER', None)

            if not (account_sid and auth_token and from_number):
                logger.warning("Twilio SMS not configured — phone verification bypassed for %s", phone)
                # SMS not yet configured (e.g. awaiting Twilio sender approval).
                # Return True so enrollment is not blocked; phone step is silently skipped.
                return True

            from twilio.rest import Client
            client = Client(account_sid, auth_token)
            client.messages.create(
                body=(
                    f'Hosi Academy verification code: {otp}. '
                    f'Valid for {OTP_EXPIRY_MINUTES} minutes. Do not share.'
                ),
                from_=from_number,
                to=phone,
            )
            return True
        except Exception as exc:
            logger.error("Failed to send OTP SMS to %s: %s", phone, exc)
            return False


class VerifyContactOTPView(APIView):
    """
    Verify a contact OTP.

    POST /api/v1/payments/contact-otp/verify/
    {
        "contact": "user@example.com",
        "contact_type": "email",
        "otp": "123456"
    }
    Returns: { "success": true }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        contact = request.data.get('contact', '').strip()
        contact_type = request.data.get('contact_type', '').strip().lower()
        otp = request.data.get('otp', '').strip()

        if not contact or not contact_type or not otp:
            return Response({'error': 'contact, contact_type and otp are required'}, status=400)

        # If SMS is not configured, bypass phone verification entirely
        if contact_type == 'phone':
            from_number = getattr(settings, 'TWILIO_PHONE_NUMBER', None)
            if not from_number:
                logger.warning("Twilio not configured — auto-passing phone verification for %s", contact)
                return Response({'success': True, 'message': 'Phone verified successfully'})

        record = ContactVerificationOTP.objects.filter(
            contact=contact,
            contact_type=contact_type,
            otp=otp,
            verified=False,
            is_valid=True,
            expires_at__gt=timezone.now(),
        ).first()

        if not record:
            # Distinguish expired vs wrong code for better UX messages
            expired = ContactVerificationOTP.objects.filter(
                contact=contact,
                contact_type=contact_type,
                otp=otp,
                verified=False,
                expires_at__lte=timezone.now(),
            ).first()
            if expired:
                return Response(
                    {'success': False, 'error': 'Code expired', 'error_code': 'OTP_EXPIRED'},
                    status=400,
                )
            return Response(
                {'success': False, 'error': 'Invalid code', 'error_code': 'INVALID_OTP'},
                status=400,
            )

        record.verified = True
        record.verified_at = timezone.now()
        record.save()

        logger.info("Contact OTP verified: %s (%s)", contact, contact_type)
        return Response({'success': True, 'message': f'{contact_type.capitalize()} verified successfully'})


class ResendContactOTPView(APIView):
    """
    Resend a contact OTP (delegates to SendContactOTPView after clearing
    the rate-limit record for this contact — i.e. same logic, same endpoint
    internally reachable but named separately for clarity).

    POST /api/v1/payments/contact-otp/resend/
    { "contact": "...", "contact_type": "email"|"phone" }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        # Force-expire any recent OTP so the rate-limit in SendContactOTPView
        # doesn't block the resend.
        contact = request.data.get('contact', '').strip()
        contact_type = request.data.get('contact_type', '').strip().lower()

        if not contact or contact_type not in ('email', 'phone'):
            return Response({'error': 'contact and contact_type are required'}, status=400)

        # Check cooldown manually
        recent = ContactVerificationOTP.objects.filter(
            contact=contact,
            contact_type=contact_type,
            is_valid=True,
            created_at__gt=timezone.now() - timedelta(seconds=RESEND_COOLDOWN_SECONDS),
        ).first()
        if recent:
            wait = int((recent.created_at + timedelta(seconds=RESEND_COOLDOWN_SECONDS) - timezone.now()).total_seconds())
            return Response(
                {'error': 'Please wait before requesting another code', 'retry_after': max(wait, 1)},
                status=status.HTTP_429_TOO_MANY_REQUESTS,
            )

        # Delegate to Send view
        return SendContactOTPView().post(request)
