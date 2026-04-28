# apps/users/permissions.py
"""
Role-based permissions with country/region filtering for admin dashboards.
Supports multi-country assignments for all admin roles.
System Admin (superuser) has unrestricted access.
"""
from rest_framework import permissions
from apps.payments.models import AdminRole
from apps.localization.models import Country
from apps.users.filters import can_user_access_country, get_allowed_countries


class IsHrAdmin(permissions.BasePermission):
    """
    Permission class to check if user has HR Admin role.
    Superusers automatically have access.
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.is_superuser:
            return True
        return AdminRole.is_hr_admin(request.user)


class IsPaymentAdmin(permissions.BasePermission):
    """Permission class to check if user has Payment Admin role."""
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.is_superuser:
            return True
        return AdminRole.is_payment_admin(request.user)


class IsExecutiveAdmin(permissions.BasePermission):
    """Permission class to check if user has Executive Admin role."""
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.is_superuser:
            return True
        return AdminRole.is_executive_admin(request.user)


class IsSystemAdmin(permissions.BasePermission):
    """
    Permission class for System Admin (superuser) only.
    This is the highest level of access with no restrictions.
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        return request.user.is_superuser


class IsAdminUser(permissions.BasePermission):
    """
    Permission class for general admin access.
    Checks for any active admin role (HR, Payment, Executive) or superuser status.
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        if request.user.is_superuser:
            return True
        # Check if user has any active admin role
        return AdminRole.objects.filter(
            user=request.user,
            is_active=True,
            role_type__in=['payment_admin', 'hr_admin', 'executive_admin']
        ).exists()


class CanAccessCountryData(permissions.BasePermission):
    """
    Permission class to ensure admins can only access data for their assigned countries.
    Superusers (System Admin) can access all countries.
    
    Usage:
        - For list views: Filters queryset automatically
        - For detail views: Checks if the object's country matches user's allowed countries
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        # System Admin (superuser) can access all countries
        if request.user.is_superuser:
            return True
        
        # Admin users must have at least one country they can access
        allowed_countries = get_allowed_countries(request.user)
        return allowed_countries.exists()
    
    def has_object_permission(self, request, view, obj):
        if not request.user or not request.user.is_authenticated:
            return False
        
        # System Admin (superuser) can access all objects
        if request.user.is_superuser:
            return True
        
        # Try to get country from object (common patterns)
        obj_country_id = None
        if hasattr(obj, 'country_id'):
            obj_country_id = obj.country_id
        elif hasattr(obj, 'country') and obj.country:
            obj_country_id = obj.country.id
        
        if obj_country_id is None:
            # Object has no country - allow access (not country-restricted)
            return True
        
        # Check if user can access this country
        return can_user_access_country(request.user, obj_country_id)


class HasCountryAccess(permissions.BasePermission):
    """
    Permission class to check if user has access to a specific country.
    Requires 'country_id' in view kwargs or request query params.
    
    Usage:
        # In URL: /api/v1/data/?country=5
        # Or in view kwargs: {'country_id': 5}
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        # System Admin (superuser) can access all countries
        if request.user.is_superuser:
            return True
        
        # Get country ID from kwargs or query params
        country_id = view.kwargs.get('country_id') or request.query_params.get('country_id')
        
        if not country_id:
            return False
        
        return can_user_access_country(request.user, int(country_id))


class IsMultiCountryAdmin(permissions.BasePermission):
    """
    Permission class to check if user has access to multiple countries.
    Useful for views that require country selection.
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        # System Admin (superuser) always qualifies
        if request.user.is_superuser:
            return True
        
        # Check if user has access to more than one country
        allowed_countries = get_allowed_countries(request.user)
        return allowed_countries.count() > 1


class CanSelectCountry(permissions.BasePermission):
    """
    Permission class to check if user can select a specific country for viewing.
    Used when user has multi-country access and wants to filter by one country.
    """
    def has_permission(self, request, view):
        if not request.user or not request.user.is_authenticated:
            return False
        
        # System Admin (superuser) can select any country
        if request.user.is_superuser:
            return True
        
        # Get selected country from query params
        country_id = request.query_params.get('country')
        
        if not country_id:
            # No country selected - allow (will show all allowed countries)
            return True
        
        # Check if user can access the selected country
        return can_user_access_country(request.user, int(country_id))
