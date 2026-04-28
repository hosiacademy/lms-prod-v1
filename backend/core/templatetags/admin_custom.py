# core/templatetags/admin_custom.py
from django import template
from django.contrib import admin

register = template.Library()

@register.simple_tag(takes_context=True)
def get_app_list(context):
    """
    Get the app list for the sidebar.
    This is a minimal implementation to prevent import errors.
    """
    request = context.get('request')
    if not request:
        return []
    
    try:
        return admin.site.get_app_list(request)
    except Exception as e:
        print(f"Error getting app list: {e}")
        return []

# Optional: Additional template tags if needed
@register.simple_tag
def get_current_app(context):
    """Get current app name from URL"""
    request = context.get('request')
    if not request:
        return ''
    
    path = request.path
    if '/admin/' in path:
        parts = path.split('/')
        if len(parts) > 2:
            return parts[2]  # app name after /admin/
    return ''