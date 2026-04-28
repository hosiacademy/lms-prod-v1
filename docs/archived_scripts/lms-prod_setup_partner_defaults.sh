#!/bin/bash
# =============================================================================
# SETUP DEFAULT PARTNER PROGRAM DATA
# Run this after deployment to populate commission tiers and benefits
# =============================================================================

cd /home/tk/lms-prod

echo "Setting up default partner program data..."

# Create default commission tiers
docker-compose -p lms-prod exec -T backend python << 'EOF'
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'lms_project.settings')

import django
django.setup()

from apps.referrals.models import CommissionTier, PartnerBenefit

# Create commission tiers
tiers = [
    {
        'tier_code': 'BRONZE',
        'display_name': 'Bronze',
        'description': 'Start earning with your first referrals',
        'min_sales': 0,
        'max_sales': 10,
        'commission_rate': 15.00,
        'color_code': '#CD7F32',
        'display_order': 1,
    },
    {
        'tier_code': 'SILVER',
        'display_name': 'Silver',
        'description': 'Grow your earnings with more sales',
        'min_sales': 11,
        'max_sales': 50,
        'commission_rate': 20.00,
        'color_code': '#C0C0C0',
        'display_order': 2,
    },
    {
        'tier_code': 'GOLD',
        'display_name': 'Gold',
        'description': 'Higher commissions for established partners',
        'min_sales': 51,
        'max_sales': 100,
        'commission_rate': 25.00,
        'color_code': '#FFD700',
        'display_order': 3,
    },
    {
        'tier_code': 'PLATINUM',
        'display_name': 'Platinum',
        'description': 'Top tier with maximum commissions',
        'min_sales': 101,
        'max_sales': None,
        'commission_rate': 30.00,
        'color_code': '#E5E4E2',
        'display_order': 4,
    },
]

for tier_data in tiers:
    CommissionTier.objects.get_or_create(
        tier_code=tier_data['tier_code'],
        defaults=tier_data
    )
    print(f"Created tier: {tier_data['display_name']}")

# Create partner benefits
benefits = [
    {
        'title': 'Generous Commissions',
        'description': 'Earn 15-30% commission on every enrollment through your referral links. The more you promote, the more you earn.',
        'icon_name': 'monetization_on',
        'display_order': 1,
        'is_featured': True,
    },
    {
        'title': 'High Conversion Rates',
        'description': 'Our mobile-first platform, affordable pricing, and in-demand courses mean better conversion for your referrals.',
        'icon_name': 'trending_up',
        'display_order': 2,
        'is_featured': True,
    },
    {
        'title': 'Dedicated Support',
        'description': 'Get marketing materials, sales training, and a dedicated partner success manager to help you grow.',
        'icon_name': 'support_agent',
        'display_order': 3,
        'is_featured': True,
    },
    {
        'title': 'Africa-Wide Impact',
        'description': 'Be part of transforming Africa\'s tech landscape. We support 16+ African countries with localized pricing.',
        'icon_name': 'public',
        'display_order': 4,
        'is_featured': True,
    },
]

for benefit_data in benefits:
    PartnerBenefit.objects.get_or_create(
        title=benefit_data['title'],
        defaults=benefit_data
    )
    print(f"Created benefit: {benefit_data['title']}")

print("\n✅ Default partner program data created successfully!")
EOF

echo ""
echo "Setup complete!"
