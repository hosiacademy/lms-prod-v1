"""
Management command: populate_aicerts_prices
Sets a default USD price on all AiCertsCourses that currently have NULL or 0 price.
Price tiers are based on category to make things realistic.
Run with: python manage.py populate_aicerts_prices
"""
from django.core.management.base import BaseCommand
from apps.aicerts_courses.models import AiCertsCourse
from decimal import Decimal


# Category-based pricing tiers (USD)
CATEGORY_PRICE_MAP = {
    'learnership': Decimal('299.00'),
    'masterclass': Decimal('199.00'),
    'package':     Decimal('499.00'),
}
DEFAULT_PRICE = Decimal('149.00')  # Standard AICERTS individual certification


class Command(BaseCommand):
    help = 'Populate default USD prices for AiCertsCourses that have NULL price'

    def add_arguments(self, parser):
        parser.add_argument(
            '--force',
            action='store_true',
            help='Overwrite prices even if already set',
        )
        parser.add_argument(
            '--price',
            type=float,
            default=None,
            help='Override default price (USD)',
        )

    def handle(self, *args, **options):
        force = options['force']
        override_price = Decimal(str(options['price'])) if options['price'] else None

        qs = AiCertsCourse.objects.all()
        if not force:
            qs = qs.filter(price_individual__isnull=True)

        count = qs.count()
        if count == 0:
            self.stdout.write(self.style.SUCCESS('All courses already have prices set.'))
            return

        self.stdout.write(f'Setting prices for {count} courses...')

        updated = 0
        for course in qs:
            if override_price:
                price = override_price
            elif course.is_in_package:
                price = CATEGORY_PRICE_MAP['package']
            else:
                # Detect from category
                category = (course.category_name or '').lower()
                if 'masterclass' in category:
                    price = CATEGORY_PRICE_MAP['masterclass']
                elif 'learnership' in category:
                    price = CATEGORY_PRICE_MAP['learnership']
                else:
                    price = DEFAULT_PRICE

            course.price_individual = price
            course.save(update_fields=['price_individual'])
            updated += 1
            self.stdout.write(f'  [{updated}/{count}] {course.title[:60]} -> USD {price}')

        self.stdout.write(self.style.SUCCESS(f'\nDone. Set prices for {updated} courses.'))
