# core/templatetags/admin_custom.py
from django import template
from django.contrib.admin import AdminSite
from django.apps import apps

register = template.Library()

@register.simple_tag
def get_app_list():
    """Custom app list grouping for the sidebar"""
    app_dict = {}
    for model, model_admin in AdminSite._registry.items():
        app_label = model._meta.app_label
        if app_label not in app_dict:
            app_name = apps.get_app_config(app_label).verbose_name
            app_dict[app_label] = {
                'name': app_name,
                'models': []
            }
        
        model_dict = {
            'name': model._meta.verbose_name_plural,
            'admin_url': model_admin.get_changelist_url(),
            'add_url': model_admin.get_add_url(),
        }
        app_dict[app_label]['models'].append(model_dict)
    
    return sorted(app_dict.items(), key=lambda x: x[1]['name'])