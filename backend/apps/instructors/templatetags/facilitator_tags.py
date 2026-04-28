# apps/facilitators/templatetags/facilitator_tags.py

from django import template
from django.utils.html import format_html
from django.utils.safestring import mark_safe

register = template.Library()


@register.simple_tag
def performance_badge(rating, band=None):
    """
    Display a performance badge with color coding.
    """
    if not band:
        if rating >= 90:
            band = 'excellent'
            color = '#10B981'
            icon = '🏆'
        elif rating >= 75:
            band = 'good'
            color = '#3B82F6'
            icon = '👍'
        elif rating >= 60:
            band = 'satisfactory'
            color = '#F59E0B'
            icon = '✅'
        elif rating >= 40:
            band = 'needs_improvement'
            color = '#EF4444'
            icon = '⚠️'
        else:
            band = 'poor'
            color = '#DC2626'
            icon = '❌'
    
    return format_html(
        '<span class="performance-badge" style="background-color:{};color:white;'
        'padding:2px 8px;border-radius:12px;font-size:0.85em;font-weight:bold;">'
        '{} {:.1f}%</span>',
        color, icon, rating
    )


@register.filter
def utilization_color(utilization):
    """
    Return color based on utilization percentage.
    """
    if utilization < 70:
        return '#10B981'  # Green - good capacity
    elif utilization < 90:
        return '#F59E0B'  # Amber - moderate capacity
    elif utilization < 100:
        return '#EF4444'  # Red - high utilization
    else:
        return '#DC2626'  # Dark red - over capacity


@register.filter
def assignment_status_badge(status):
    """
    Return colored badge for assignment status.
    """
    colors = {
        'pending': '#F59E0B',
        'assigned': '#3B82F6',
        'ongoing': '#10B981',
        'completed': '#6B7280',
        'cancelled': '#EF4444',
    }
    
    icons = {
        'pending': '⏳',
        'assigned': '📋',
        'ongoing': '▶️',
        'completed': '✅',
        'cancelled': '❌',
    }
    
    color = colors.get(status, '#6B7280')
    icon = icons.get(status, '❓')
    
    return format_html(
        '<span class="status-badge" style="background-color:{};color:white;'
        'padding:2px 8px;border-radius:12px;font-size:0.85em;">'
        '{} {}</span>',
        color, icon, status.title()
    )


@register.simple_tag
def facilitator_avatar(facilitator, size=40):
    """
    Display facilitator avatar with fallback.
    """
    if facilitator.user.photo or facilitator.user.image:
        avatar_url = facilitator.user.photo or facilitator.user.image
        return format_html(
            '<img src="{}" width="{}" height="{}" '
            'style="border-radius:50%;object-fit:cover;" '
            'alt="{}" title="{}">',
            avatar_url, size, size,
            facilitator.user.name or facilitator.user.username,
            facilitator.user.name or facilitator.user.username
        )
    else:
        # Generate initial avatar
        name = facilitator.user.name or facilitator.user.username
        initials = ''.join([n[0].upper() for n in name.split()[:2]])
        bg_color = facilitator.performance_color if hasattr(facilitator, 'performance_color') else '#3B82F6'
        
        return format_html(
            '<div style="width:{}px;height:{}px;border-radius:50%;'
            'background-color:{};color:white;display:flex;'
            'align-items:center;justify-content:center;'
            'font-weight:bold;font-size:{}px;">{}</div>',
            size, size, bg_color, size//2, initials
        )


@register.filter
def format_duration(minutes):
    """
    Format duration in minutes to human readable format.
    """
    if minutes < 60:
        return f"{minutes}m"
    elif minutes < 1440:  # Less than 24 hours
        hours = minutes / 60
        return f"{hours:.1f}h"
    else:
        days = minutes / 1440
        return f"{days:.1f}d"