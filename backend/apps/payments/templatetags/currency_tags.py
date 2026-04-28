# apps/payments/templatetags/currency_tags.py
"""
Template tags for currency localization
Usage: {% load currency_tags %}
"""

from django import template
from django.template import Node, TemplateSyntaxError
from decimal import Decimal
from apps.payments.currency_localization import (
    CurrencyLocalizationService,
    PROFESSIONAL_COURSE_PRICE_USD,
    TECHNICAL_COURSE_PRICE_USD,
)

register = template.Library()


@register.simple_tag(takes_context=True)
def localize_price(context, usd_amount):
    """
    Convert USD amount to local currency and format with symbol.
    Usage: {% localize_price 250.00 %}
    """
    request = context.get('request')
    if not request or not hasattr(request, 'currency_context'):
        return f"${usd_amount}"
    
    currency_context = request.currency_context
    return CurrencyLocalizationService.format_price(
        Decimal(str(usd_amount)),
        currency_context['currency']
    )


@register.simple_tag(takes_context=True)
def professional_course_price(context):
    """
    Get localized price for professional AICERTS course.
    Usage: {% professional_course_price %}
    """
    request = context.get('request')
    if not request or not hasattr(request, 'currency_context'):
        return f"${PROFESSIONAL_COURSE_PRICE_USD}"
    
    currency_context = request.currency_context
    price = CurrencyLocalizationService.get_professional_course_price(
        currency_context['currency']
    )
    symbol = currency_context['currency']['currency_symbol']
    return f"{symbol} {price:,.2f}".rstrip('0').rstrip('.')


@register.simple_tag(takes_context=True)
def technical_course_price(context):
    """
    Get localized price for technical AICERTS course.
    Usage: {% technical_course_price %}
    """
    request = context.get('request')
    if not request or not hasattr(request, 'currency_context'):
        return f"${TECHNICAL_COURSE_PRICE_USD}"
    
    currency_context = request.currency_context
    price = CurrencyLocalizationService.get_technical_course_price(
        currency_context['currency']
    )
    symbol = currency_context['currency']['currency_symbol']
    return f"{symbol} {price:,.2f}".rstrip('0').rstrip('.')


@register.simple_tag(takes_context=True)
def get_course_price(context, course):
    """
    Get localized price for any course based on its type.
    Usage: {% get_course_price course %}
    """
    request = context.get('request')
    if not request or not hasattr(request, 'currency_context'):
        if hasattr(course, 'price_individual') and course.price_individual:
            return f"${course.price_individual}"
        return f"${PROFESSIONAL_COURSE_PRICE_USD}"
    
    currency_context = request.currency_context
    price = CurrencyLocalizationService.get_course_price(
        course,
        currency_context['currency']
    )
    symbol = currency_context['currency']['currency_symbol']
    return f"{symbol} {price:,.2f}".rstrip('0').rstrip('.')


@register.simple_tag(takes_context=True)
def currency_info(context):
    """
    Get current currency context.
    Usage: {% currency_info as currency %}
    """
    request = context.get('request')
    if not request or not hasattr(request, 'currency_context'):
        return {
            'code': 'USD',
            'symbol': '$',
            'name': 'US Dollar',
            'rate': 1.0,
            'is_usd': True,
        }
    
    ctx = request.currency_context
    curr = ctx['currency']
    return {
        'code': curr['currency_code'],
        'symbol': curr['currency_symbol'],
        'name': curr['currency_name'],
        'rate': curr['exchange_rate'],
        'is_usd': curr['is_usd'],
        'country_code': curr.get('country_code', ''),
    }


@register.inclusion_tag('payments/partials/currency_display.html', takes_context=True)
def display_price(context, usd_amount, label=None):
    """
    Display price in local currency with optional label.
    Usage: {% display_price 250.00 "Enrollment Fee" %}
    """
    request = context.get('request')
    if not request or not hasattr(request, 'currency_context'):
        localized = f"${usd_amount}"
        symbol = '$'
        code = 'USD'
    else:
        currency_context = request.currency_context
        localized = CurrencyLocalizationService.format_price(
            Decimal(str(usd_amount)),
            currency_context['currency']
        )
        symbol = currency_context['currency']['currency_symbol']
        code = currency_context['currency']['currency_code']
    
    return {
        'label': label,
        'price': localized,
        'symbol': symbol,
        'currency_code': code,
        'usd_amount': usd_amount,
    }
