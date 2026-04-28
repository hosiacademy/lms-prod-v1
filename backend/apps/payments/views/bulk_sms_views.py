"""
Bulk SMS Campaign Views — Admin only
Sends SMS via Twilio HosiAcademy messaging service (MG17481cdaf787ad333c48f42eec53e005)
Supported countries: ZA (+27), KE (+254), ZW (+263), ZM (+260)
"""
import logging
import re
from django.contrib.auth import get_user_model
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException
from django.conf import settings

User = get_user_model()
logger = logging.getLogger(__name__)

MESSAGING_SERVICE_SID = 'MG17481cdaf787ad333c48f42eec53e005'
ALLOWED_PREFIXES = ('+27', '+254', '+263', '+260')
MAX_NUMBERS = 500


def _normalize_number(raw: str) -> str:
    """Normalize a phone number to E.164 format."""
    # Strip whitespace, dashes, parentheses, spaces
    n = re.sub(r'[\s\-\(\)]', '', raw.strip())
    # 00XX → +XX
    if n.startswith('00'):
        n = '+' + n[2:]
    return n


def _is_admin(user) -> bool:
    if user.is_staff or user.is_superuser:
        return True
    role = getattr(user, 'role', None)
    if role and hasattr(role, 'name'):
        role = role.name
    return str(role) in ('payment_admin', 'executive_admin', 'hr_admin')


class BulkSMSSendView(APIView):
    """
    POST /api/v1/payments/admin/bulk-sms/send/
    {
        "message": "Your message here",
        "numbers": ["+27821234567", ...],      // manually entered or from CSV
        "user_ids": [1, 2, 3, ...]             // LMS user IDs — phones pulled from DB
    }
    Returns per-number results with sent/failed/skipped counts.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)

        message = request.data.get('message', '').strip()
        raw_numbers = list(request.data.get('numbers', []))
        user_ids = request.data.get('user_ids', [])

        if not message:
            return Response({'error': 'Message text is required'}, status=400)
        if len(message) > 1600:
            return Response({'error': 'Message exceeds 1600 characters'}, status=400)

        # Resolve user IDs → phone numbers
        if user_ids:
            users = User.objects.filter(id__in=user_ids).exclude(
                phone__isnull=True).exclude(phone='')
            for u in users:
                if u.phone not in raw_numbers:
                    raw_numbers.append(u.phone)

        if not raw_numbers:
            return Response({'error': 'No phone numbers provided'}, status=400)
        if len(raw_numbers) > MAX_NUMBERS:
            return Response(
                {'error': f'Maximum {MAX_NUMBERS} numbers per campaign'}, status=400)

        # Init Twilio client
        account_sid = getattr(settings, 'TWILIO_ACCOUNT_SID', None)
        auth_token = getattr(settings, 'TWILIO_AUTH_TOKEN', None)
        if not (account_sid and auth_token):
            return Response({'error': 'Twilio credentials not configured'}, status=500)

        try:
            client = Client(account_sid, auth_token)
        except Exception as e:
            return Response({'error': f'Twilio init failed: {e}'}, status=500)

        sent, failed, skipped = [], [], []

        for raw in raw_numbers:
            number = _normalize_number(str(raw))

            if not number.startswith('+'):
                skipped.append({'number': raw, 'reason': 'Missing country code'})
                continue

            if not number.startswith(ALLOWED_PREFIXES):
                skipped.append({
                    'number': number,
                    'reason': 'Country not supported — ZA/KE/ZW/ZM only'
                })
                continue

            try:
                msg = client.messages.create(
                    body=message,
                    messaging_service_sid=MESSAGING_SERVICE_SID,
                    to=number,
                )
                sent.append({'number': number, 'sid': msg.sid, 'status': msg.status})
                logger.info('Bulk SMS sent to %s SID=%s', number, msg.sid)

            except TwilioRestException as e:
                failed.append({'number': number, 'error': e.msg})
                logger.warning('Bulk SMS failed for %s: %s', number, e.msg)
            except Exception as e:
                failed.append({'number': number, 'error': str(e)})
                logger.error('Bulk SMS unexpected error for %s: %s', number, e)

        logger.info(
            'Bulk SMS campaign by %s: sent=%d failed=%d skipped=%d',
            request.user.email, len(sent), len(failed), len(skipped)
        )

        return Response({
            'success': True,
            'summary': {
                'total': len(raw_numbers),
                'sent': len(sent),
                'failed': len(failed),
                'skipped': len(skipped),
            },
            'details': {
                'sent': sent,
                'failed': failed,
                'skipped': skipped,
            },
        })


class UserPhoneListView(APIView):
    """
    GET /api/v1/payments/admin/bulk-sms/users/
    Returns LMS users who have a phone number on file.
    Query params:
      ?search=<name|email>
      ?country=ZA|KE|ZW|ZM
    """
    permission_classes = [IsAuthenticated]

    COUNTRY_PREFIXES = {
        'ZA': '+27',
        'KE': '+254',
        'ZW': '+263',
        'ZM': '+260',
    }

    def get(self, request):
        if not _is_admin(request.user):
            return Response({'error': 'Admin access required'}, status=403)

        qs = User.objects.exclude(phone__isnull=True).exclude(
            phone='').order_by('first_name', 'last_name')

        search = request.query_params.get('search', '').strip()
        if search:
            from django.db.models import Q
            qs = qs.filter(
                Q(first_name__icontains=search) |
                Q(last_name__icontains=search) |
                Q(email__icontains=search) |
                Q(phone__icontains=search)
            )

        country = request.query_params.get('country', '').strip().upper()
        if country and country in self.COUNTRY_PREFIXES:
            prefix = self.COUNTRY_PREFIXES[country]
            qs = qs.filter(phone__startswith=prefix)

        users = []
        for u in qs[:500]:
            users.append({
                'id': u.id,
                'name': (u.get_full_name() or u.username).strip(),
                'email': u.email or '',
                'phone': u.phone or '',
            })

        return Response({'users': users, 'total': len(users)})
