import logging
from django.contrib.auth import get_user_model
from django.db import transaction
from apps.payments.models import AdminRole, AdminCountryAccess
from apps.localization.models import Country

User = get_user_model()
logger = logging.getLogger(__name__)

def setup_admin_tiers_for_role(role_type):
    """
    Ensures both Tier 1 (Universal) and Tier 2 (Country-Specific) 
    administrator accounts exist for a given role type.
    """
    # Tier 1: Universal Admin
    global_email = f"{role_type}_global@hosiacademy.africa"
    _create_admin_account(global_email, role_type, None)
    
    # Tier 2: Country-Specific Admins
    countries = Country.objects.filter(is_active=True)
    for country in countries:
        country_email = f"{role_type}_{country.code.lower()}@hosiacademy.africa"
        _create_admin_account(country_email, role_type, country)

def setup_admin_tiers_for_country(country):
    """
    Ensures country-specific administrator accounts exist for all
    active role types for a given country.
    """
    role_types = [
        'payment_admin', 
        'marketing_admin', 
        'hr_admin', 
        'executive_admin'
    ]
    
    for rt in role_types:
        country_email = f"{rt}_{country.code.lower()}@hosiacademy.africa"
        _create_admin_account(country_email, rt, country)

def _create_admin_account(email, role_type, country=None):
    with transaction.atomic():
        user, created = User.objects.get_or_create(
            email=email,
            defaults={
                'username': email.split('@')[0],
                'first_name': f"{role_type.replace('_', ' ').title()}",
                'last_name': f"{country.name if country else 'Global'}",
                'is_staff': True,
                'role_id': 1, # Admin
                'country': country
            }
        )
        
        if created:
            user.set_password('HosiAdmin2026!')
            user.save()
            logger.info(f"Created admin user: {email}")
        
        # Create AdminRole
        admin_role, r_created = AdminRole.objects.get_or_create(
            user=user,
            role_type=role_type,
            defaults={'is_active': True}
        )
        
        if country:
            # Tier 2: Restrict to single country
            AdminCountryAccess.objects.get_or_create(
                admin_role=admin_role,
                country=country,
                defaults={'is_active': True}
            )
        else:
            # Tier 1: Universal (Ensure no restrictions)
            AdminCountryAccess.objects.filter(admin_role=admin_role).delete()
