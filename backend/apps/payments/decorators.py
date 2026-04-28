# apps/payments/decorators.py
from functools import wraps
from django.http import JsonResponse
from apps.payments.models import AdminRole


def require_payment_admin(view_func):
    """Decorator to require payment admin role"""
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        if not request.user.is_authenticated:
            return JsonResponse({'error': 'Authentication required'}, status=401)

        if not AdminRole.is_payment_admin(request.user):
            return JsonResponse({'error': 'Payment Admin access required'}, status=403)

        return view_func(request, *args, **kwargs)
    return wrapper


def require_hr_admin(view_func):
    """Decorator to require HR admin role"""
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        if not request.user.is_authenticated:
            return JsonResponse({'error': 'Authentication required'}, status=401)

        if not AdminRole.is_hr_admin(request.user):
            return JsonResponse({'error': 'HR Admin access required'}, status=403)

        return view_func(request, *args, **kwargs)
    return wrapper


def require_executive_admin(view_func):
    """Decorator to require executive admin role"""
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        if not request.user.is_authenticated:
            return JsonResponse({'error': 'Authentication required'}, status=401)

        if not AdminRole.is_executive_admin(request.user):
            return JsonResponse({'error': 'Executive Admin access required'}, status=403)

        return view_func(request, *args, **kwargs)
    return wrapper
