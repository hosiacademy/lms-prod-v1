# apps/users/filters.py
"""
Country/region filtering utilities for admin dashboards.
Provides filtering logic based on user role and assigned countries.

Supports multi-country assignments for all admin roles (HR Admin, Payment Admin, Executive Admin).
System Admin (superuser) has unrestricted access to all countries.
"""
from django.db.models import Q
from django.contrib.auth import get_user_model
from apps.localization.models import Country
from apps.payments.models import AdminRole

User = get_user_model()


def get_user_country_filter(user, selected_country_id=None):
    """
    Get a Q filter object based on user's role and country access.
    
    Args:
        user: The authenticated user
        selected_country_id: Optional country ID to filter by (if user has multi-country access)
    
    Returns:
        Q object: Filter to apply to querysets for country-based access control
        
    Usage:
        # For HR Admin with single country
        country_filter = get_user_country_filter(request.user)
        data = SomeModel.objects.filter(country_filter)
        
        # For multi-country admin with specific country selection
        country_filter = get_user_country_filter(request.user, selected_country_id=5)
        
        # For superusers/executive - returns Q() (no filter, all data)
    """
    if not user or not user.is_authenticated:
        return Q(pk__in=[])  # No access for unauthenticated users
    
    # Superusers see all data (no filtering)
    if user.is_superuser:
        return Q()  # Empty Q returns all records
    
    # Get admin role for the user
    admin_roles = user.admin_roles.filter(is_active=True)
    
    if not admin_roles.exists():
        # No admin role - check if they have a personal country assignment
        if hasattr(user, 'country') and user.country:
            return Q(country_id=user.country.id)
        return Q(pk__in=[])  # No country access
    
    # Collect all allowed countries from all admin roles
    allowed_country_ids = set()
    for role in admin_roles:
        countries = role.get_allowed_countries()
        allowed_country_ids.update(countries.values_list('id', flat=True))
    
    if not allowed_country_ids:
        # No countries assigned - assume access to all
        return Q()
    
    # If a specific country is selected, validate it's in allowed list
    if selected_country_id:
        if selected_country_id in allowed_country_ids:
            return Q(country_id=selected_country_id)
        else:
            return Q(pk__in=[])  # Not allowed to access this country
    
    # Filter to all allowed countries
    return Q(country_id__in=allowed_country_ids)


def get_allowed_countries(user, role_type=None):
    """
    Get the list of countries a user is allowed to access.
    
    Args:
        user: The authenticated user
        role_type: Optional role type to filter by ('hr_admin', 'payment_admin', 'executive_admin')
    
    Returns:
        Queryset[Country]: Countries the user can view data for
        
    Usage:
        # Get all countries for all admin roles
        countries = get_allowed_countries(request.user)
        
        # Get countries for specific role
        countries = get_allowed_countries(request.user, role_type='hr_admin')
    """
    if not user or not user.is_authenticated:
        return Country.objects.none()
    
    # Superusers can access all countries
    if user.is_superuser:
        return Country.objects.filter(is_active=True)
    
    # Get admin roles
    admin_roles = user.admin_roles.filter(is_active=True)
    
    if role_type:
        admin_roles = admin_roles.filter(role_type=role_type)
    
    if not admin_roles.exists():
        # No admin role - check personal country assignment
        if hasattr(user, 'country') and user.country:
            return Country.objects.filter(id=user.country.id)
        return Country.objects.none()
    
    # Collect all allowed countries from all admin roles
    allowed_country_ids = set()
    for role in admin_roles:
        countries = role.get_allowed_countries()
        allowed_country_ids.update(countries.values_list('id', flat=True))
    
    if not allowed_country_ids:
        # No specific countries assigned - all active countries
        return Country.objects.filter(is_active=True)
    
    return Country.objects.filter(id__in=allowed_country_ids, is_active=True)


def filter_queryset_by_user_country(user, queryset, country_field='country_id', selected_country_id=None):
    """
    Filter a queryset based on user's role and country access.
    
    Args:
        user: The authenticated user
        queryset: The queryset to filter
        country_field: The field name on the queryset model that stores country reference.
                      Default is 'country_id'. Can also be 'country', 'user__country_id', etc.
        selected_country_id: Optional specific country to filter by
    
    Returns:
        QuerySet: Filtered queryset
    
    Usage:
        # Basic usage with default country_id field
        enrollments = filter_queryset_by_user_country(
            request.user, 
            Enrollment.objects.all()
        )
        
        # With specific country selection (for multi-country admins)
        data = filter_queryset_by_user_country(
            request.user,
            MyModel.objects.all(),
            selected_country_id=5
        )
        
        # With custom country field name
        users = filter_queryset_by_user_country(
            request.user,
            User.objects.all(),
            country_field='country_id'
        )
    """
    if not user or not user.is_authenticated:
        return queryset.none()
    
    # Superusers see all data
    if user.is_superuser:
        return queryset
    
    # Get country filter
    country_filter = get_user_country_filter(user, selected_country_id)
    
    # Apply filter
    if country_filter and 'country_id__in' in str(country_filter):
        # Extract country IDs from filter
        country_ids = country_filter.children[0][1] if country_filter.children else []
        filter_kwargs = {country_field: country_ids}
        return queryset.filter(**filter_kwargs)
    elif country_filter and 'country_id' in str(country_filter):
        # Single country filter
        country_id = country_filter.children[0][1] if country_filter.children else None
        if country_id:
            filter_kwargs = {country_field: country_id}
            return queryset.filter(**filter_kwargs)
    
    # Empty Q or no country field match - return all
    return queryset


def get_dashboard_country_context(user, selected_country_id=None):
    """
    Get country context information for dashboard display.
    
    Args:
        user: The authenticated user
        selected_country_id: Optional selected country ID
    
    Returns:
        dict: Country context with keys:
            - 'restricted': bool - Whether the view is country-restricted
            - 'country_id': int|None - The selected country ID if applicable
            - 'country_name': str|None - The selected country name if applicable
            - 'can_view_all': bool - Whether user can view all countries
            - 'allowed_countries': list - List of allowed countries
            - 'is_multi_country': bool - Whether user has access to multiple countries
    """
    if not user or not user.is_authenticated:
        return {
            'restricted': True,
            'country_id': None,
            'country_name': None,
            'can_view_all': False,
            'allowed_countries': [],
            'is_multi_country': False
        }
    
    # Superusers can view all
    if user.is_superuser:
        all_countries = list(Country.objects.filter(is_active=True).values('id', 'name', 'code'))
        return {
            'restricted': False,
            'country_id': selected_country_id,
            'country_name': None,
            'can_view_all': True,
            'allowed_countries': all_countries,
            'is_multi_country': True,
            'is_superuser': True
        }
    
    # Get allowed countries
    allowed_countries = get_allowed_countries(user)
    allowed_countries_list = list(allowed_countries.values('id', 'name', 'code'))
    is_multi_country = len(allowed_countries_list) > 1
    
    # Check if restricted to specific countries
    admin_roles = user.admin_roles.filter(is_active=True)
    has_specific_assignments = any(
        role.country_accesses.filter(is_active=True).exists() 
        for role in admin_roles
    )
    
    # Get selected country info
    selected_country_name = None
    if selected_country_id:
        selected_country = allowed_countries.filter(id=selected_country_id).first()
        if selected_country:
            selected_country_name = selected_country.name
    
    return {
        'restricted': has_specific_assignments,
        'country_id': selected_country_id,
        'country_name': selected_country_name,
        'can_view_all': not has_specific_assignments,
        'allowed_countries': allowed_countries_list,
        'is_multi_country': is_multi_country,
        'has_country_assignment': has_specific_assignments
    }


def can_user_access_country(user, country_id):
    """
    Check if a user can access data for a specific country.
    
    Args:
        user: The authenticated user
        country_id: The country ID to check access for
    
    Returns:
        bool: True if user can access the country, False otherwise
    """
    if not user or not user.is_authenticated:
        return False
    
    # Superusers can access all countries
    if user.is_superuser:
        return True
    
    # Get allowed countries
    allowed_countries = get_allowed_countries(user)
    return allowed_countries.filter(id=country_id).exists()


def get_user_primary_country(user):
    """
    Get the user's primary country for dashboard display.
    For multi-country admins, returns the first country in their assignment.
    
    Args:
        user: The authenticated user
    
    Returns:
        Country|None: The primary country or None
    """
    if not user or not user.is_authenticated:
        return None
    
    # Superusers don't have a primary country
    if user.is_superuser:
        return None
    
    # Get allowed countries
    allowed_countries = get_allowed_countries(user)
    return allowed_countries.first()


def get_admin_role_countries(user, role_type):
    """
    Get countries for a specific admin role type.
    
    Args:
        user: The authenticated user
        role_type: The role type ('hr_admin', 'payment_admin', 'executive_admin')
    
    Returns:
        Queryset[Country]: Countries for the specific role
    """
    if not user or not user.is_authenticated:
        return Country.objects.none()
    
    if user.is_superuser:
        return Country.objects.filter(is_active=True)
    
    # Get specific admin role
    admin_role = AdminRole.get_admin_role(user, role_type)
    if not admin_role:
        return Country.objects.none()
    
    return admin_role.get_allowed_countries()
