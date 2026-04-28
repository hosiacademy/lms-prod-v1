# apps/payments/coupon_views.py
from django.utils import timezone
from django.core.cache import cache
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny

_COUNTRY_NAMES = {
    'KE': 'Kenya', 'ZA': 'South Africa', 'ZM': 'Zambia',
    'ZW': 'Zimbabwe', 'NG': 'Nigeria', 'GH': 'Ghana',
    'UG': 'Uganda', 'TZ': 'Tanzania', 'RW': 'Rwanda',
    'ET': 'Ethiopia', 'EG': 'Egypt', 'MA': 'Morocco',
}


def _get_client_ip(request):
    x_forwarded = request.META.get('HTTP_X_FORWARDED_FOR')
    if x_forwarded:
        return x_forwarded.split(',')[0].strip()
    return request.META.get('REMOTE_ADDR')


def _get_country_from_ip(ip):
    """Geolocate an IP address to ISO-2 country code via ipapi.co.
    Returns None if undetermined (fail-open). Results are cached for 1 hour."""
    if not ip or ip in ('127.0.0.1', '::1', 'localhost'):
        return None
    cache_key = f'ip_country_{ip}'
    cached = cache.get(cache_key)
    if cached is not None:
        return cached
    try:
        import requests as req
        r = req.get(f'https://ipapi.co/{ip}/country/', timeout=3)
        if r.status_code == 200:
            country = r.text.strip().upper()
            if len(country) == 2 and country.isalpha():
                cache.set(cache_key, country, 3600)
                return country
    except Exception:
        pass
    return None


class ValidateCouponView(APIView):
    """
    POST /api/v1/payments/coupons/validate/
    Body: { code, amount, enrollment_type, country, email (optional) }
    Returns discount details without consuming the coupon.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        from .models import CouponCode, CouponRedemption

        code = (request.data.get('code') or '').strip().upper()
        if not code:
            return Response({'valid': False, 'message': 'No code provided.'}, status=400)

        try:
            coupon = CouponCode.objects.get(code=code)
        except CouponCode.DoesNotExist:
            return Response({'valid': False, 'message': 'Invalid coupon code.'}, status=200)

        now = timezone.now()

        if not coupon.is_active:
            return Response({'valid': False, 'message': 'This coupon is no longer active.'})
        if now < coupon.valid_from:
            return Response({'valid': False, 'message': 'This coupon is not yet valid.'})
        if now > coupon.valid_until:
            return Response({'valid': False, 'message': 'This coupon has expired.'})
        if coupon.usage_limit and coupon.times_used >= coupon.usage_limit:
            return Response({'valid': False, 'message': 'This coupon has reached its usage limit.'})

        # Product pathway check
        enrollment_type = request.data.get('enrollment_type', '')
        pathway_map = {
            'masterclass': 'masterclass',
            'industry_training': 'industry_training',
            'aicerts': 'aicerts',
            'custom_selection': 'custom',
            'learnership': 'learnership',
        }
        mapped = pathway_map.get(enrollment_type, enrollment_type)
        # Combined pathway: AICERTS + Custom Selection + Industry Training (excludes masterclass & learnership)
        if coupon.product_pathway == 'aicerts_custom_industry':
            if mapped not in ('aicerts', 'custom', 'industry_training'):
                return Response({'valid': False, 'message': 'This coupon applies to AICERTS, Custom Selection, and Industry Training courses only.'})
        elif coupon.product_pathway != 'all' and coupon.product_pathway != mapped:
            return Response({'valid': False, 'message': f'This coupon is not valid for {enrollment_type} enrollments.'})

        # Country check — server-side IP geo-validation for country-restricted coupons
        if coupon.country_restriction:
            client_ip = _get_client_ip(request)
            ip_country = _get_country_from_ip(client_ip)
            restricted_to = coupon.country_restriction.upper()
            country_name = _COUNTRY_NAMES.get(restricted_to, restricted_to)
            if ip_country and ip_country != restricted_to:
                return Response({'valid': False, 'message': f'This coupon is only valid in {country_name}.'})
            elif not ip_country:
                # IP geo failed — fall back to client-provided country
                country = request.data.get('country', '').upper()
                if country and country != restricted_to:
                    return Response({'valid': False, 'message': f'This coupon is only valid in {country_name}.'})

        # Minimum purchase
        try:
            amount = float(request.data.get('amount', 0))
        except (TypeError, ValueError):
            amount = 0.0
        if amount < float(coupon.min_purchase_amount):
            return Response({'valid': False, 'message': f'Minimum purchase of ${coupon.min_purchase_amount} required.'})

        # Per-user limit
        email = (request.data.get('email') or '').strip().lower()
        if email and coupon.per_user_limit:
            user_uses = CouponRedemption.objects.filter(coupon=coupon, email=email).count()
            if user_uses >= coupon.per_user_limit:
                return Response({'valid': False, 'message': 'You have already used this coupon.'})

        discount_amount = coupon.compute_discount(amount)
        final_amount = max(0.0, amount - discount_amount)

        days_left = (coupon.valid_until - now).days

        return Response({
            'valid': True,
            'coupon_id': coupon.id,
            'code': coupon.code,
            'name': coupon.name,
            'description': coupon.description,
            'discount_type': coupon.discount_type,
            'discount_value': float(coupon.discount_value),
            'max_discount_amount': float(coupon.max_discount_amount) if coupon.max_discount_amount else None,
            'discount_amount': discount_amount,
            'original_amount': amount,
            'final_amount': final_amount,
            'days_remaining': max(0, days_left),
            'message': 'Coupon applied successfully!',
        })


class RedeemCouponView(APIView):
    """
    POST /api/v1/payments/coupons/redeem/
    Called after successful payment to record redemption.
    Body: { code, amount, email, order_id (optional) }
    """
    permission_classes = [AllowAny]

    def post(self, request):
        from .models import CouponCode, CouponRedemption, Order

        code = (request.data.get('code') or '').strip().upper()
        email = (request.data.get('email') or '').strip().lower()
        try:
            amount = float(request.data.get('amount', 0))
        except (TypeError, ValueError):
            amount = 0.0

        if not code or not email:
            return Response({'success': False, 'message': 'Code and email required.'}, status=400)

        try:
            coupon = CouponCode.objects.get(code=code, is_active=True)
        except CouponCode.DoesNotExist:
            return Response({'success': False, 'message': 'Invalid coupon.'}, status=400)

        discount_amount = coupon.compute_discount(amount)
        final_amount = max(0.0, amount - discount_amount)

        order = None
        order_id = request.data.get('order_id')
        if order_id:
            try:
                order = Order.objects.get(id=order_id)
            except Order.DoesNotExist:
                pass

        user = request.user if request.user.is_authenticated else None

        CouponRedemption.objects.create(
            coupon=coupon,
            email=email,
            user=user,
            order=order,
            original_amount=amount,
            discount_amount=discount_amount,
            final_amount=final_amount,
            ip_address=_get_client_ip(request),
        )

        # Increment usage counter
        CouponCode.objects.filter(pk=coupon.pk).update(times_used=coupon.times_used + 1)

        return Response({'success': True, 'discount_amount': discount_amount, 'final_amount': final_amount})


class ListCouponsView(APIView):
    """
    GET /api/v1/payments/coupons/ — admin list (staff only)
    """
    def get(self, request):
        if not request.user.is_staff:
            return Response({'detail': 'Permission denied.'}, status=403)
        from .models import CouponCode
        now = timezone.now()
        qs = CouponCode.objects.all().order_by('-created_at')
        data = []
        for c in qs:
            data.append({
                'id': c.id,
                'code': c.code,
                'name': c.name,
                'discount_type': c.discount_type,
                'discount_value': float(c.discount_value),
                'product_pathway': c.product_pathway,
                'country_restriction': c.country_restriction,
                'times_used': c.times_used,
                'usage_limit': c.usage_limit,
                'valid_from': c.valid_from.isoformat(),
                'valid_until': c.valid_until.isoformat(),
                'is_active': c.is_active,
                'is_currently_valid': c.is_currently_valid,
            })
        return Response(data)


_PATHWAY_LABELS = {
    'all': 'All Courses',
    'masterclass': 'Masterclasses',
    'learnership': 'Learnerships',
    'industry_training': 'Industry Training',
    'aicerts': 'AICERTS Courses',
    'custom': 'Custom Selection',
    'aicerts_custom_industry': 'AICERTS, Custom & Industry Training',
}


class PublicCouponsView(APIView):
    """
    GET /api/v1/payments/coupons/public/?country=ZA
    Returns currently active, public-facing coupons for display on the onboarding page.
    Excludes corporate-only and expired coupons.
    """
    permission_classes = [AllowAny]

    def get(self, request):
        from .models import CouponCode, CouponClientType
        now = timezone.now()
        country = request.query_params.get('country', '').upper()

        qs = CouponCode.objects.filter(
            is_active=True,
            valid_from__lte=now,
            valid_until__gte=now,
        ).exclude(
            client_type=CouponClientType.CORPORATE,
        ).exclude(
            client_type=CouponClientType.PRIVATE,
        ).order_by('valid_until')

        data = []
        for c in qs:
            # Skip country-restricted coupons that don't match the user's country
            if c.country_restriction and country and c.country_restriction != country:
                continue
            # Skip if exhausted
            if c.usage_limit and c.times_used >= c.usage_limit:
                continue

            days_left = (c.valid_until - now).days

            # Build human-readable discount label
            if c.discount_type == 'percentage':
                discount_label = f'{c.discount_value:.0f}% OFF'
            elif c.discount_type == 'fixed':
                discount_label = f'${c.discount_value:.0f} OFF'
            else:
                discount_label = f'{c.discount_value:.0f}% OFF (max ${c.max_discount_amount})'

            pathway_label = _PATHWAY_LABELS.get(c.product_pathway, c.product_pathway)
            country_label = _COUNTRY_NAMES.get(c.country_restriction, c.country_restriction) if c.country_restriction else None

            is_auto_applied = c.product_pathway == 'aicerts_custom_industry'
            # Show the code on the card only for auto-applied promotions;
            # event-specific codes (country-restricted) are sent privately to attendees.
            show_code = is_auto_applied

            # Determine discount_percentage for promo flyer
            discount_pct = None
            if c.discount_type == 'percentage':
                discount_pct = float(c.discount_value)
            elif c.discount_type == 'capped_percentage':
                discount_pct = float(c.discount_value)

            data.append({
                # Coupon strip fields
                'id': c.id,
                'code': c.code,
                'name': c.name,
                'description': c.description,
                'discount_type': c.discount_type,
                'discount_value': float(c.discount_value),
                'discount_label': discount_label,
                'pathway_label': pathway_label,
                'pathway': c.product_pathway,
                'country_label': country_label,
                'days_remaining': max(0, days_left),
                'is_auto_applied': is_auto_applied,
                'show_code': show_code,
                # Promo flyer display fields
                'title': c.name,
                'promotion_type': c.promotion_type,
                'background_color': c.background_color,
                'text_color': c.text_color,
                'icon': c.icon,
                'image_url': c.image_url,
                'discount_percentage': discount_pct,
                'cta_text': c.cta_text,
                'cta_url': c.cta_url,
                'priority': c.priority,
                'show_on_onboarding': c.show_on_onboarding,
                'show_on_home': c.show_on_home,
                'show_on_splash': c.show_on_splash,
                'start_date': c.valid_from.date().isoformat(),
                'end_date': c.valid_until.date().isoformat(),
                'is_currently_active': c.is_currently_valid,
            })
        return Response(data)
