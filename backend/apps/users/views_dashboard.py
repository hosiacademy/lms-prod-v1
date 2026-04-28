# apps/users/views_dashboard.py
"""
Dashboard views with role-based country/region filtering.
Provides dashboard data endpoints for different user roles.
Supports multi-country assignments for all admin roles.
System Admin (superuser) has unrestricted access.
"""
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from rest_framework.views import APIView
from rest_framework.response import Response
from django.contrib.auth import get_user_model
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_protect

from apps.users.dashboard_serializers import build_dashboard_data
from apps.users.permissions import (
    IsAdminUser, IsHrAdmin, IsPaymentAdmin, 
    IsExecutiveAdmin, IsSystemAdmin, CanSelectCountry
)
from apps.users.filters import (
    get_dashboard_country_context, 
    get_allowed_countries,
    can_user_access_country
)
from apps.payments.models import AdminRole

User = get_user_model()


@method_decorator(csrf_protect, name='dispatch')
class DashboardView(APIView):
    """
    Main dashboard endpoint with role-based country filtering.
    
    GET /api/v1/dashboard/
    
    Returns dashboard data based on user role:
    - System Admin (superuser): All data, all countries (unrestricted)
    - HR Admin: Data filtered by assigned countries
    - Payment Admin: Data filtered by assigned countries
    - Executive Admin: Data filtered by assigned countries
    
    Query Parameters:
    - country: Optional country ID to filter by (for multi-country admins)
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        
        # Optional: Allow country selection for multi-country admins
        country_param = request.query_params.get('country', None)
        selected_country_id = None
        
        if country_param:
            try:
                selected_country_id = int(country_param)
                
                # Validate user has access to selected country
                if not can_user_access_country(user, selected_country_id):
                    return Response(
                        {'error': 'You do not have access to view data for this country'},
                        status=status.HTTP_403_FORBIDDEN
                    )
            except (ValueError, TypeError):
                return Response(
                    {'error': 'Invalid country ID'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Build dashboard data with automatic country filtering
        try:
            dashboard_data = build_dashboard_data(user, request, selected_country_id)
            
            # Add country context for frontend display
            country_context = get_dashboard_country_context(user, selected_country_id)
            dashboard_data['country_context'] = country_context
            
            # Add user role information
            dashboard_data['user_role'] = self._get_user_role_info(user)
            
            return Response(dashboard_data)
            
        except Exception as e:
            return Response(
                {'error': f'Failed to load dashboard data: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
    
    def _get_user_role_info(self, user):
        """Get comprehensive role information for the user"""
        role_info = {
            'role_id': user.role_id,
            'role_name': self._get_role_name(user.role_id),
            'is_superuser': user.is_superuser,
            'is_system_admin': user.is_superuser,
            'is_hr_admin': AdminRole.is_hr_admin(user),
            'is_payment_admin': AdminRole.is_payment_admin(user),
            'is_executive_admin': AdminRole.is_executive_admin(user),
        }
        
        # Add country access info
        if not user.is_superuser:
            allowed_countries = get_allowed_countries(user)
            role_info['allowed_countries_count'] = allowed_countries.count()
            role_info['is_multi_country_admin'] = allowed_countries.count() > 1
            
            # Get countries for each role
            for role_type in ['hr_admin', 'payment_admin', 'executive_admin']:
                role_countries = get_allowed_countries(user, role_type)
                role_info[f'{role_type}_countries'] = list(
                    role_countries.values('id', 'name', 'code')
                )
        
        return role_info
    
    def _get_role_name(self, role_id):
        """Get human-readable role name from role_id"""
        role_names = {
            1: 'Admin',
            2: 'Instructor',
            3: 'Student',
        }
        return role_names.get(role_id, 'Unknown')


@method_decorator(csrf_protect, name='dispatch')
class HrAdminDashboardView(APIView):
    """
    HR Admin-specific dashboard endpoint.
    Requires HR Admin role.
    
    GET /api/v1/dashboard/hr-admin/
    
    Returns dashboard data filtered by HR Admin's assigned countries.
    Supports multi-country HR Admins with optional country selection.
    
    Query Parameters:
    - country: Optional country ID to filter by (for multi-country HR Admins)
    """
    permission_classes = [IsAuthenticated, IsHrAdmin]
    
    def get(self, request):
        user = request.user
        
        # Optional country selection
        country_param = request.query_params.get('country', None)
        selected_country_id = None
        
        if country_param:
            try:
                selected_country_id = int(country_param)
                if not can_user_access_country(user, selected_country_id):
                    return Response(
                        {'error': 'You do not have access to view data for this country'},
                        status=status.HTTP_403_FORBIDDEN
                    )
            except (ValueError, TypeError):
                return Response(
                    {'error': 'Invalid country ID'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        try:
            dashboard_data = build_dashboard_data(user, request, selected_country_id)
            
            # Add detailed country context
            country_context = get_dashboard_country_context(user, selected_country_id)
            dashboard_data['country_context'] = country_context
            
            # Add HR Admin specific role info
            hr_role = AdminRole.get_admin_role(user, 'hr_admin')
            dashboard_data['user_role'] = {
                'role_id': user.role_id,
                'role_name': 'HR Admin',
                'is_hr_admin': True,
                'assigned_countries': list(get_allowed_countries(user, 'hr_admin').values('id', 'name', 'code')),
                'selected_country_id': selected_country_id,
            }
            
            if hr_role:
                dashboard_data['user_role']['has_country_restrictions'] = (
                    hr_role.country_accesses.filter(is_active=True).exists()
                )
            
            return Response(dashboard_data)
            
        except Exception as e:
            return Response(
                {'error': f'Failed to load HR Admin dashboard data: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


@method_decorator(csrf_protect, name='dispatch')
class PaymentAdminDashboardView(APIView):
    """
    Payment Admin-specific dashboard endpoint.
    Requires Payment Admin role.
    
    GET /api/v1/dashboard/payment-admin/
    
    Returns dashboard data filtered by Payment Admin's assigned countries.
    Supports multi-country Payment Admins with optional country selection.
    
    Query Parameters:
    - country: Optional country ID to filter by (for multi-country Payment Admins)
    """
    permission_classes = [IsAuthenticated, IsPaymentAdmin]
    
    def get(self, request):
        user = request.user
        
        # Optional country selection
        country_param = request.query_params.get('country', None)
        selected_country_id = None
        
        if country_param:
            try:
                selected_country_id = int(country_param)
                if not can_user_access_country(user, selected_country_id):
                    return Response(
                        {'error': 'You do not have access to view data for this country'},
                        status=status.HTTP_403_FORBIDDEN
                    )
            except (ValueError, TypeError):
                return Response(
                    {'error': 'Invalid country ID'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        try:
            dashboard_data = build_dashboard_data(user, request, selected_country_id)
            
            # Add detailed country context
            country_context = get_dashboard_country_context(user, selected_country_id)
            dashboard_data['country_context'] = country_context
            
            # Add Payment Admin specific role info
            payment_role = AdminRole.get_admin_role(user, 'payment_admin')
            dashboard_data['user_role'] = {
                'role_id': user.role_id,
                'role_name': 'Payment Admin',
                'is_payment_admin': True,
                'assigned_countries': list(get_allowed_countries(user, 'payment_admin').values('id', 'name', 'code')),
                'selected_country_id': selected_country_id,
            }
            
            if payment_role:
                dashboard_data['user_role']['has_country_restrictions'] = (
                    payment_role.country_accesses.filter(is_active=True).exists()
                )
            
            return Response(dashboard_data)
            
        except Exception as e:
            return Response(
                {'error': f'Failed to load Payment Admin dashboard data: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


@method_decorator(csrf_protect, name='dispatch')
class ExecutiveDashboardView(APIView):
    """
    Executive Admin dashboard endpoint.
    Requires Executive Admin role or superuser.
    
    GET /api/v1/dashboard/executive/
    
    Returns system-wide dashboard data.
    Executive Admins may have country restrictions if assigned.
    System Admin (superuser) has unrestricted access to all countries.
    
    Query Parameters:
    - country: Optional country ID to filter by
    """
    permission_classes = [IsAuthenticated, IsExecutiveAdmin | IsSystemAdmin]
    
    def get(self, request):
        user = request.user
        
        # Optional country selection
        country_param = request.query_params.get('country', None)
        selected_country_id = None
        
        if country_param:
            try:
                selected_country_id = int(country_param)
                if not user.is_superuser and not can_user_access_country(user, selected_country_id):
                    return Response(
                        {'error': 'You do not have access to view data for this country'},
                        status=status.HTTP_403_FORBIDDEN
                    )
            except (ValueError, TypeError):
                return Response(
                    {'error': 'Invalid country ID'},
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        try:
            dashboard_data = build_dashboard_data(user, request, selected_country_id)
            
            # Executive admins may have country restrictions
            # System admins (superusers) can see all countries
            if user.is_superuser:
                dashboard_data['country_context'] = {
                    'restricted': False,
                    'can_view_all_countries': True,
                    'is_system_admin': True,
                    'available_countries': list(
                        get_allowed_countries(user).values('id', 'name', 'code')
                    )
                }
            else:
                dashboard_data['country_context'] = get_dashboard_country_context(user, selected_country_id)
            
            dashboard_data['user_role'] = {
                'role_id': user.role_id,
                'role_name': 'System Admin' if user.is_superuser else 'Executive Admin',
                'is_executive_admin': AdminRole.is_executive_admin(user),
                'is_superuser': user.is_superuser,
                'is_system_admin': user.is_superuser,
                'assigned_countries': list(
                    get_allowed_countries(user, 'executive_admin').values('id', 'name', 'code')
                ) if not user.is_superuser else [],
                'selected_country_id': selected_country_id,
            }
            
            return Response(dashboard_data)
            
        except Exception as e:
            return Response(
                {'error': f'Failed to load executive dashboard data: {str(e)}'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )


@method_decorator(csrf_protect, name='dispatch')
class CountryAccessInfoView(APIView):
    """
    Get country access information for the current user.
    Useful for frontend to determine what countries the user can view.
    
    GET /api/v1/dashboard/country-access/
    
    Returns:
    - Country access context
    - List of allowed countries
    - Countries per admin role
    - User's personal country (if any)
    """
    permission_classes = [IsAuthenticated]
    
    def get(self, request):
        user = request.user
        country_context = get_dashboard_country_context(user)
        allowed_countries = get_allowed_countries(user)
        
        response_data = {
            'country_access': country_context,
            'allowed_countries': list(allowed_countries.values('id', 'name', 'code')),
            'user_country': {
                'id': user.country.id if hasattr(user, 'country') and user.country else None,
                'name': user.country.name if hasattr(user, 'country') and user.country else None,
                'code': user.country.code if hasattr(user, 'country') and user.country else None,
            } if hasattr(user, 'country') and user.country else None,
        }
        
        # Add countries per role (for non-superusers)
        if not user.is_superuser:
            response_data['role_countries'] = {}
            for role_type in ['hr_admin', 'payment_admin', 'executive_admin']:
                role_countries = get_allowed_countries(user, role_type)
                if role_countries.exists():
                    response_data['role_countries'][role_type] = list(
                        role_countries.values('id', 'name', 'code')
                    )
        
        return Response(response_data)


@method_decorator(csrf_protect, name='dispatch')
class CountrySelectionView(APIView):
    """
    Validate and get info for a specific country selection.
    Used when multi-country admins want to switch between countries.
    
    GET /api/v1/dashboard/country-selection/<country_id>/
    
    Returns country info if user has access, 403 otherwise.
    """
    permission_classes = [IsAuthenticated, CanSelectCountry]
    
    def get(self, request, country_id):
        user = request.user
        
        try:
            country_id = int(country_id)
        except (ValueError, TypeError):
            return Response(
                {'error': 'Invalid country ID'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Check access
        if not can_user_access_country(user, country_id):
            return Response(
                {'error': 'You do not have access to this country'},
                status=status.HTTP_403_FORBIDDEN
            )
        
        # Get country info
        from apps.localization.models import Country
        country = Country.objects.filter(id=country_id, is_active=True).first()
        
        if not country:
            return Response(
                {'error': 'Country not found or inactive'},
                status=status.HTTP_404_NOT_FOUND
            )
        
        return Response({
            'country': {
                'id': country.id,
                'name': country.name,
                'code': country.code,
                'native': country.native,
            },
            'has_access': True,
            'selected': True
        })