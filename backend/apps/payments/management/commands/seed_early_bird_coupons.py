# apps/payments/management/commands/seed_early_bird_coupons.py
"""
Seed Early Bird Masterclass coupons — one per market.

Each coupon grants 10% off any masterclass enrollment.
The coupon is valid from now until 7 days before the market's masterclass start date.
Country restriction enforces that only users from that market can redeem.

Usage:
    # Create with default validity (adjust valid_until in Django admin afterward):
    python manage.py seed_early_bird_coupons

    # Specify per-market masterclass dates (YYYY-MM-DD) so valid_until is set correctly:
    python manage.py seed_early_bird_coupons \\
        --ke 2026-05-10 --za 2026-05-17 --zw 2026-05-24 --zm 2026-05-31

    # Force-recreate even if coupons already exist:
    python manage.py seed_early_bird_coupons --force
"""
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils import timezone
from django.utils.dateparse import parse_date


class Command(BaseCommand):
    help = 'Create Early Bird 10% masterclass coupons for KE, ZA, ZW, ZM markets'

    def add_arguments(self, parser):
        parser.add_argument('--ke', dest='date_ke', help='Masterclass date in Kenya (YYYY-MM-DD)')
        parser.add_argument('--za', dest='date_za', help='Masterclass date in South Africa (YYYY-MM-DD)')
        parser.add_argument('--zw', dest='date_zw', help='Masterclass date in Zimbabwe (YYYY-MM-DD)')
        parser.add_argument('--zm', dest='date_zm', help='Masterclass date in Zambia (YYYY-MM-DD)')
        parser.add_argument('--force', action='store_true', help='Re-create existing coupons')

    def handle(self, *args, **options):
        from apps.payments.models import CouponCode, CouponDiscountType, CouponPathway, CouponClientType, CouponPromotionType

        now = timezone.now()

        markets = [
            {
                'code': 'EARLYBIRD-KE',
                'country': 'KE',
                'name': 'Early Bird — Kenya Masterclass',
                'date_arg': options.get('date_ke'),
            },
            {
                'code': 'EARLYBIRD-ZA',
                'country': 'ZA',
                'name': 'Early Bird — South Africa Masterclass',
                'date_arg': options.get('date_za'),
            },
            {
                'code': 'EARLYBIRD-ZW',
                'country': 'ZW',
                'name': 'Early Bird — Zimbabwe Masterclass',
                'date_arg': options.get('date_zw'),
            },
            {
                'code': 'EARLYBIRD-ZM',
                'country': 'ZM',
                'name': 'Early Bird — Zambia Masterclass',
                'date_arg': options.get('date_zm'),
            },
        ]

        for m in markets:
            # Compute valid_until: 7 days before masterclass, or 90 days from now as fallback
            if m['date_arg']:
                masterclass_date = parse_date(m['date_arg'])
                if not masterclass_date:
                    self.stderr.write(f"Invalid date '{m['date_arg']}' for {m['country']} — skipping.")
                    continue
                from datetime import datetime
                masterclass_dt = timezone.make_aware(datetime.combine(masterclass_date, datetime.min.time()))
                valid_until = masterclass_dt - timedelta(days=7)
            else:
                valid_until = now + timedelta(days=90)  # fallback — update in admin

            existing = CouponCode.objects.filter(code=m['code']).first()
            if existing and not options['force']:
                self.stdout.write(f"  SKIP  {m['code']} (already exists — use --force to recreate)")
                continue

            if existing and options['force']:
                existing.delete()

            CouponCode.objects.create(
                code=m['code'],
                name=m['name'],
                description=(
                    'Register at least 1 week before the masterclass starts and save 10%. '
                    'This coupon is exclusive to early registrants in your market.'
                ),
                discount_type=CouponDiscountType.PERCENTAGE,
                discount_value=10,
                max_discount_amount=None,
                product_pathway=CouponPathway.MASTERCLASS,
                country_restriction=m['country'],
                client_type=CouponClientType.ALL,
                min_purchase_amount=0,
                usage_limit=None,      # unlimited total redemptions
                per_user_limit=1,      # one use per email
                valid_from=now,
                valid_until=valid_until,
                is_active=True,
                promotion_type=CouponPromotionType.LIMITED_TIME,
                background_color='#172E3D',
                text_color='#F5C842',
                icon='⏰',
                cta_text='Enroll Early & Save 10%',
                priority=90,
                show_on_onboarding=True,
                show_on_home=True,
                show_on_splash=False,
            )

            valid_label = valid_until.strftime('%Y-%m-%d')
            self.stdout.write(self.style.SUCCESS(
                f"  CREATED  {m['code']} ({m['country']}) — valid until {valid_label}"
            ))

        self.stdout.write(self.style.SUCCESS('\nEarly Bird coupons seeded. '
            'Review valid_until dates in Django Admin > Payments > Coupon Codes.'))
