# apps/facilitators/context_processors.py

def facilitator_context(request):
    """
    Context processor to add facilitator-related context to templates.
    """
    context = {}
    
    if hasattr(request, 'user') and request.user.is_authenticated:
        # Add facilitator profile if exists
        if hasattr(request.user, 'facilitator_profile'):
            context['facilitator_profile'] = request.user.facilitator_profile
            context['is_facilitator'] = True
            
            # Add performance metrics
            context['facilitator_performance'] = {
                'rating': request.user.facilitator_profile.overall_rating,
                'band': request.user.facilitator_profile.performance_band,
                'color': request.user.facilitator_profile.performance_color,
            }
        else:
            context['is_facilitator'] = False
        
        # Check if user has executive privileges
        if request.user.is_superuser or request.user.role_id == 1:
            context['is_executive'] = True
        else:
            context['is_executive'] = False
    
    # Add module configuration
    from django.conf import settings
    if hasattr(settings, 'FACILITATORS_CONFIG'):
        context['facilitators_config'] = settings.FACILITATORS_CONFIG
    
    return context